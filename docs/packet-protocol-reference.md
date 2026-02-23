# Packet Protocol Reference

The MuMain client communicates with OpenMU servers via a .NET Native AOT bridge. This document covers packet framing, field types, encryption, and the C++/C# boundary contracts.

For the network layer architecture, see [Architecture: ClientLibrary](architecture-clientlibrary.md). For cross-platform interop changes, see [CROSS_PLATFORM_PLAN.md](CROSS_PLATFORM_PLAN.md) Phase 8.

**Section navigation:**

| Section | Lines | Content |
|---------|-------|---------|
| [Architecture Overview](#architecture-overview) | ~15 | High-level diagram, key stats |
| [Packet Framing](#packet-framing) | ~15 | Length-prefixed format |
| [Field Type Mapping](#field-type-mapping) | ~20 | XML→C++→C# type table |
| [Encryption](#encryption) | ~30 | SimpleModulus + XOR3, login credentials |
| [C++/C# Boundary Contracts](#cc-boundary-contracts) | ~55 | Function signatures, marshaling rules, memory safety |
| [Code Generation Pipeline](#code-generation-pipeline) | ~30 | XSLT transforms, XML source, generated file sizes |
| [Connection Lifecycle](#connection-lifecycle) | ~20 | Connect/Send/Receive/Disconnect |
| [Cross-Platform Issues](#cross-platform-issues) | ~10 | wchar_t, DLL loading, marshaling |

---

## Architecture Overview

```
OpenMU Server (TCP/IP, Encrypted)
         ↕
    ClientLibrary (.NET 10, Native AOT)
         ↕ function pointers ([UnmanagedCallersOnly])
    PacketFunctions_*.cpp (C++ handlers)
         ↕
    MuMain Game Client (C++20)
```

- **213+ exported functions** bridge C++ and .NET
- **4 XSLT transforms** generate C++ and C# bindings at build time
- **Single monolithic DLL** loaded at game startup — no .NET runtime dependency

---

## Packet Framing

Packets use a length-prefixed frame format:

| Offset | Field | Type | Size | Notes |
|--------|-------|------|------|-------|
| 0 | Length | `uint16_t` LE | 2 bytes | Inclusive (includes the 2-byte header) |
| 2 | Type | `byte` | 1 byte | Packet discriminator |
| 3+ | Payload | Variable | N bytes | Field-specific data |

`SetPacketSize()` sets the length field before transmission.

---

## Field Type Mapping

| XML Type | C++ Type | C# Type | Notes |
|----------|----------|---------|-------|
| `Byte` | `BYTE` | `byte` | Single unsigned byte |
| `Boolean` | `BYTE` | `byte` → `bool` | Marshaled as 0/1 |
| `ShortLittleEndian` | `uint16_t` | `ushort` | 2-byte LE |
| `IntegerLittleEndian` | `uint32_t` | `uint` | 4-byte LE |
| `LongLittleEndian` | `uint64_t` | `ulong` | 8-byte LE |
| `Float` | `float` | `float` | IEEE 754 |
| `Double` | `double` | `double` | IEEE 754 |
| `String` | `const wchar_t*` | `IntPtr` → `string` | UTF-16LE at boundary |
| `Binary` | `const BYTE*, uint32_t` | `byte*, uint` | Pointer + length pair |
| `Enum` | `uint32_t` | Enum type | Namespace-qualified |
| `Structure[]` | `Span<...>` | `Span<...>` | Variable-length arrays |

**String and Binary types** use companion length parameters in C++ (suffix `ByteLength`).

---

## Server Protocols

| Server | Packets | Encryption | Purpose |
|--------|---------|------------|---------|
| **ClientToServer** | ~200+ | SimpleModulus + XOR3 (auth) | Main game server |
| **ChatServer** | ~20 | XOR3 (tokens/messages) | Chat rooms |
| **ConnectServer** | ~10 | None | Server list, auth tokens |

---

## Encryption

### Two-Layer Encryption

1. **SimpleModulus** (transport layer): Applied to all bytes before transmission on encrypted connections
2. **XOR3** (field-level): Applied to sensitive fields (credentials, chat tokens) with a 3-byte key (`FC CF AB`)

### Connection Establishment

```csharp
// isEncrypted = 1 for game server, 0 for connect server
var encryptor = isEncrypted ?
    new PipelinedXor32Encryptor(
        new PipelinedSimpleModulusEncryptor(output, DefaultClientKey).Writer)
    : null;
```

### Login Credential Encryption

```csharp
Span<byte> usernameBytes = stackalloc byte[10];
Span<byte> passwordBytes = stackalloc byte[20];
Encoding.UTF8.GetBytes(usernameStr, usernameBytes);
Encoding.UTF8.GetBytes(passwordStr, passwordBytes);
Xor3Encryptor.Encrypt(usernameBytes);
Xor3Encryptor.Encrypt(passwordBytes);
```

---

## C++/C# Boundary Contracts

### Function Signature Pattern

**C++ declaration** (`PacketFunctions_ClientToServer.h`):
```cpp
void SendPing(uint32_t tickCount, uint16_t attackSpeed);
void SendPublicChatMessage(const wchar_t* character, const wchar_t* message);
void SendLoginLongPassword(const BYTE* username, uint32_t usernameByteLength,
                           const BYTE* password, uint32_t passwordByteLength,
                           uint32_t tickCount, const BYTE* clientVersion,
                           uint32_t clientVersionByteLength, ...);
```

**C++ binding** (`PacketBindings_ClientToServer.h`):
```cpp
typedef void(CORECLR_DELEGATE_CALLTYPE* SendPing)(int32_t, uint32_t, uint16_t);
inline SendPing dotnet_SendPing =
    reinterpret_cast<SendPing>(symLoad(munique_client_library_handle, "SendPing"));
```

**C# export** (`ConnectionManager.ClientToServerFunctions.cs`):
```csharp
[UnmanagedCallersOnly(EntryPoint = "SendPing")]
public static void SendPing(int handle, uint tickCount, ushort attackSpeed)
{
    if (!Connections.TryGetValue(handle, out var connection)) return;
    connection.CreateAndSend(pipeWriter => {
        var length = PingRef.Length;
        var packet = new PingRef(pipeWriter.GetSpan(length)[..length]);
        packet.TickCount = tickCount;
        packet.AttackSpeed = attackSpeed;
        return length;
    });
}
```

### Marshaling Rules

| Data | C++ → .NET | Notes |
|------|-----------|-------|
| Numeric | Direct pass-through | Matching sizes guaranteed |
| String | `const wchar_t*` → `Marshal.PtrToStringAuto()` | Copies immediately; C++ owns lifetime |
| Binary | `const BYTE*, uint32_t` → `new Span<byte>(ptr, len)` | Split across two parameters |
| Boolean | `BYTE` (0/1) → explicit `== 1` check | |
| Handle | `int32_t` → dictionary lookup | 1-based counter |

### Memory Safety

- **String ownership:** C++ caller owns `wchar_t*` lifetime. C# copies immediately via `Marshal.PtrToStringAuto()`.
- **Packet buffers:** C# owns allocated buffers via `pipeWriter.GetSpan(length)`.
- **No callbacks for packet handling:** .NET exports are called FROM C++; receive path uses registered callback with raw `(handle, length, byte* data)`.

---

## Code Generation Pipeline

### XSLT Transforms

| XSLT File | Output | Purpose |
|-----------|--------|---------|
| `GenerateExtensionsDotNet.xslt` | `ConnectionManager.*Functions.cs` | C# [UnmanagedCallersOnly] methods |
| `GenerateFunctionsHeader.xslt` | `PacketFunctions_*.h` | C++ declarations |
| `GenerateFunctions.xslt` | `PacketFunctions_*.cpp` | C++ stub implementations |
| `GenerateBindingsHeader.xslt` | `PacketBindings_*.h` | C++ typedefs + function pointer loaders |

Shared type mapping in `Common.xslt`.

### XML Source

All from NuGet package `MUnique.OpenMU.Network.Packets` v0.9.8:
- `ClientToServerPackets.xml` (~200+ packets)
- `ChatServerPackets.xml` (~20 packets)
- `ConnectServerPackets.xml` (~10 packets)

### Generated File Sizes

| File | Size | Lines |
|------|------|-------|
| `ConnectionManager.ClientToServerFunctions.cs` | ~257 KB | ~6,700 |
| `PacketFunctions_ClientToServer.h` | ~110 KB | ~2,500 |
| `PacketBindings_ClientToServer.h` | ~53 KB | ~1,500 |
| `PacketFunctions_ClientToServer.cpp` | ~100 KB | ~2,400 |

---

## Connection Lifecycle

1. **Connect** (`ConnectionManager_Connect`): Create TCP socket → set up encryption pipeline → register `onPacketReceived`/`onDisconnected` callbacks → return handle
2. **Send** (`ConnectionManager_Send`): Retrieve connection by handle → set packet size → send through encryption pipeline
3. **Receive** (automatic): Read from socket → decrypt → invoke C++ callback with `(handle, length, byte* data)`
4. **Disconnect** (`ConnectionManager_Disconnect`): Close socket → remove from `Connections` dictionary

### Global Reference

```cpp
extern Connection* SocketClient;  // WSclient.h

SocketClient->ToGameServer()->SendMove(x, y);
SocketClient->ToChatServer()->SendWhisper(target, message);
SocketClient->ToConnectServer()->SendLogin(account, password);
```

---

## Packet Categories

| Category | Examples |
|----------|---------|
| Auth | `LoginLongPassword`, `LoginShortPassword`, `Login075` |
| Movement | `WalkRequest` (direction byte array) |
| Combat | `AttackRequest` (target ID, attack type) |
| Items | `PickupItemRequest`, `DropItemRequest`, `ItemMoveRequest` |
| Chat | `PublicChatMessage`, `WhisperMessage` |
| NPC | `TalkToNpcRequest`, `BuyItemFromNpcRequest` |
| Guild/Siege | Castle siege registration, taxation |
| System | `Ping` (heartbeat), `ChecksumResponse` (anti-cheat) |

Multiple packet variants exist for client compatibility: `Login075`, `PickupItemRequest075`, `EnterGateRequest075`.

---

## Cross-Platform Issues

| Issue | Current (Windows) | Required (Linux/macOS) | Phase |
|-------|-------------------|----------------------|-------|
| `wchar_t` at boundary | 2 bytes (UTF-16) | `char16_t` (4-byte wchar_t) | 5 / 5.6 |
| DLL loading | `LoadLibrary()` | `dlopen()` for `.so`/`.dylib` | 8 / 8.2 |
| String marshaling | `Marshal.PtrToStringAuto()` | Platform-specific encoding | 8 / 8.3 |
| Runtime identifier | `win-x64` | `linux-x64`, `osx-arm64` | 8 / 8.1 |

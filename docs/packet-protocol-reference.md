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
| [Cross-Platform Considerations](#cross-platform-considerations) | ~55 | MU_C16, SIOF, packet queue, library loading |

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

- **206 packet binding function pointers** bridge C++ and .NET (191 ClientToServer + 6 ChatServer + 9 ConnectServer), plus 4 connection management functions
- **4 XSLT transforms** generate C++ and C# bindings at build time
- **.NET 10 Native AOT** compiled to a platform-specific shared library (`.dll`/`.so`/`.dylib`) — no .NET runtime dependency
- **`ResolvePacketBindings()`** re-resolves all 206 function pointers post-load to handle Static Initialization Order Fiasco (SIOF) on non-Windows platforms

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
| `String` | `const char16_t*` | `IntPtr` → `string` | UTF-16LE via `MU_C16()` / `Marshal.PtrToStringUni()` |
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
void SendPublicChatMessage(const wchar_t* character, const wchar_t* message);  // wchar_t* in wrapper; MU_C16() converts to char16_t* at call site
void SendLoginLongPassword(const BYTE* username, uint32_t usernameByteLength,
                           const BYTE* password, uint32_t passwordByteLength,
                           uint32_t tickCount, const BYTE* clientVersion,
                           uint32_t clientVersionByteLength, ...);
```

**C++ binding** (`PacketBindings_ClientToServer.h`):
```cpp
typedef void(CORECLR_DELEGATE_CALLTYPE* SendPing)(int32_t, uint32_t, uint16_t);
inline SendPing dotnet_SendPing =
    reinterpret_cast<SendPing>(mu::platform::GetSymbol(munique_client_library_handle, "SendPing"));
```

> **SIOF note:** These `inline` variables are initialized at static init time. On non-Windows platforms the library handle may not be loaded yet, leaving pointers null. `ResolvePacketBindings()` (called from `MuMain()` after static init) re-resolves all 206 bindings via `ReResolve()` to fix this.

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
| String | `const char16_t*` → `Marshal.PtrToStringUni()` | Always UTF-16LE; C++ converts via `MU_C16()` |
| Binary | `const BYTE*, uint32_t` → `new Span<byte>(ptr, len)` | Split across two parameters |
| Boolean | `BYTE` (0/1) → explicit `== 1` check | |
| Handle | `int32_t` → dictionary lookup | 1-based counter |

### Memory Safety

- **String ownership:** C++ caller owns the string lifetime. On macOS/Linux, `MU_C16()` produces a temporary `std::u16string` that lives for the full call expression. C# copies immediately via `Marshal.PtrToStringUni()`.
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
3. **Receive** (automatic): Read from socket → decrypt → invoke C++ callback with `(handle, length, byte* data)`. On SDL3 platforms, the callback queues the packet for main-thread processing via `DrainPacketQueue()` (see [Cross-Platform Considerations](#cross-platform-considerations)).
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

## Cross-Platform Considerations

All issues below are **resolved** as of April 2026. The network layer is fully functional on Windows, Linux, and macOS.

### String Marshalling (`MU_C16`)

`wchar_t` is 2 bytes on Windows but 4 bytes on macOS/Linux. The `MU_C16()` macro (defined in `PlatformCompat.h`) provides a consistent `const char16_t*` at the C++/.NET boundary:

```cpp
// Windows/MinGW (sizeof(wchar_t)==2): zero-cost reinterpret_cast
#define MU_C16(s) reinterpret_cast<const char16_t*>(s)

// macOS/Linux (sizeof(wchar_t)==4): transcode via mu_wchar_to_char16
#define MU_C16(s) mu_wchar_to_char16(s).c_str()
```

On the C# side, all string parameters use `Marshal.PtrToStringUni()` (not `PtrToStringAuto()`) to guarantee UTF-16LE decoding regardless of platform.

### Library Loading

The .NET Native AOT shared library is loaded via `mu::platform::Load()` which wraps `LoadLibrary()` on Windows and `dlopen()` on Linux/macOS. Symbol resolution uses `mu::platform::GetSymbol()` (wrapping `GetProcAddress`/`dlsym`). The library path is set at compile time via `MU_DOTNET_LIB_DIR` and `MU_DOTNET_LIB_EXT` CMake defines, producing platform-correct extensions (`.dll`, `.so`, `.dylib`).

### Static Initialization Order Fiasco (SIOF)

The 206 packet binding function pointers are declared as `inline` variables in `PacketBindings_*.h`, initialized via `mu::platform::GetSymbol()` at static init time. On non-Windows platforms, the library handle may not be initialized yet when these run, leaving pointers null.

**Fix:** `ResolvePacketBindings()` is called from `MuMain()` after all static initialization completes. It uses a `ReResolve()` template that checks each pointer and re-resolves it if null:

```cpp
template <typename FnPtr>
void ReResolve(FnPtr& var, const char* name)
{
    if (!var && munique_client_library_handle)
        var = reinterpret_cast<FnPtr>(mu::platform::GetSymbol(munique_client_library_handle, name));
}
```

All 206 bindings (191 ClientToServer + 6 ChatServer + 9 ConnectServer) are covered.

### Packet Queue (SDL3 Platforms)

On Windows, incoming packets are dispatched to the game loop via `PostMessage(WM_RECEIVE_BUFFER)`. On SDL3 platforms (Linux/macOS), `PostMessage` is a no-op, so packets are instead pushed into a thread-safe `std::queue<std::unique_ptr<PacketInfo>>` protected by `std::mutex`. The main game loop calls `DrainPacketQueue()` each frame to move all queued packets to a local batch (minimizing lock contention with the .NET I/O thread) and process them sequentially.

```
.NET receive thread → s_packetQueue (mutex-protected) → DrainPacketQueue() → ProcessPacketCallback()
```

Key files:
- `Connection.cpp` — library loading, `ResolvePacketBindings()`, connection lifecycle
- `WSclient.cpp` — `DrainPacketQueue()`, `s_packetQueue`, packet processing
- `PlatformCompat.h` — `MU_C16()`, `mu::platform::Load()`/`GetSymbol()`
- `MuMain.cpp` — calls `ResolvePacketBindings()` and `DrainPacketQueue()` in game loop

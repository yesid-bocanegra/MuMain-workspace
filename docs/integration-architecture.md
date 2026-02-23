# Integration Architecture

## Overview

MuMain is a multi-part project with 4 components that communicate through code generation pipelines and runtime interop bridges.

```
┌─────────────────────────────────────────────────────────────┐
│                    MuMain-workspace                          │
│                                                              │
│  ┌──────────────────────┐     ┌───────────────────────┐     │
│  │  ConstantsReplacer   │     │ MUnique.OpenMU.Network│     │
│  │  (.NET 8, WinForms)  │     │ .Packets v0.9.8       │     │
│  │                      │     │ (NuGet package)        │     │
│  │  XSLT Transforms ────┼─────┤ XML Packet Defs       │     │
│  └──────────┬───────────┘     └───────────┬───────────┘     │
│             │ Generates                    │ Generates       │
│             ▼                              ▼                 │
│  ┌──────────────────────┐     ┌───────────────────────┐     │
│  │  MuMain C++ Client   │◄───►│  ClientLibrary        │     │
│  │  (C++20, Win32)      │     │  (.NET 10, Native AOT)│     │
│  │                      │     │                        │     │
│  │  PacketBindings_*.h  │     │  ConnectionManager.cs  │     │
│  │  PacketFunctions_*.h │     │  *Functions.cs         │     │
│  │  Connection.h/cpp    │     │  ConnectionWrapper.cs  │     │
│  │                      │     │                        │     │
│  │  ┌────────────────┐  │     └───────────────────────┘     │
│  │  │  MuEditor      │  │              ▲                     │
│  │  │  (ImGui, #ifdef)│  │              │ Native AOT DLL     │
│  │  │  Same process   │  │              │ (MUnique.Client.   │
│  │  └────────────────┘  │              │  Library.dll)       │
│  └──────────────────────┘──────────────┘                     │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  docs/ (Planning & Architecture)                      │   │
│  │  CROSS_PLATFORM_PLAN.md, CROSS_PLATFORM_DECISIONS.md  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Integration Points

### 1. C++ ↔ .NET Native AOT Bridge

**Direction:** Bidirectional
**Mechanism:** Native AOT DLL loaded via `dlopen`/`LoadLibrary` with function pointer delegates

**From C++ to .NET:**
- `Connection.h` loads `MUnique.Client.Library.dll` at runtime
- Resolves function pointers via `coreclr_delegates.h`
- Calls .NET methods for: connection management, packet sending, encryption

**From .NET to C++:**
- .NET exports callback delegates that C++ registers
- Packet receive handlers invoke C++ functions: `PacketFunctions_ClientToServer.cpp`
- Packet data marshaled as raw byte buffers

**Data Format:**
- Strings: `wchar_t*` (2-byte on Windows) at the C++ boundary, UTF-16LE in .NET
- Packets: Raw byte arrays with length-prefixed headers
- Numerics: Direct pass-through (matching sizes)

**Key Files:**
| File | Role |
|------|------|
| `src/source/Dotnet/Connection.h/cpp` | DLL loading, delegate resolution |
| `src/source/Dotnet/PacketBindings_*.h` | C++ packet structure definitions |
| `src/source/Dotnet/PacketFunctions_*.h/cpp` | C++ packet handler implementations |
| `ClientLibrary/ConnectionManager.cs` | .NET connection lifecycle |
| `ClientLibrary/ConnectionWrapper.cs` | .NET connection utilities |
| `src/dependencies/netcore/includes/coreclr_delegates.h` | .NET hosting API |

### 2. XSLT Code Generation Pipeline

**Direction:** One-way (XML → C++ and C#)
**Mechanism:** XSLT transforms at build time

**Source:** `MUnique.OpenMU.Network.Packets` NuGet package (v0.9.8) provides XML packet definitions for 3 server types:
- `ClientToServerPackets.xml` — Game server protocol
- `ChatServerPackets.xml` — Chat server protocol
- `ConnectServerPackets.xml` — Connection server protocol

**Transforms (4 XSLT files in ClientLibrary/):**

| Transform | Input | Output | Language |
|-----------|-------|--------|----------|
| `GenerateExtensionsDotNet.xslt` | *Packets.xml | `ConnectionManager.*Functions.cs` | C# |
| `GenerateFunctionsHeader.xslt` | *Packets.xml | `PacketFunctions_*.h` | C++ |
| `GenerateFunctions.xslt` | *Packets.xml | `PacketFunctions_*.cpp` | C++ |
| `GenerateBindingsHeader.xslt` | *Packets.xml | `PacketBindings_*.h` | C++ |

**Trigger:** Visual Studio PreBuild event (skipped in CI via `'$(ci)'!='true'` condition)

**Generated File Sizes:**
- `PacketBindings_ClientToServer.h` — 53 KB (largest packet structure header)
- `PacketFunctions_ClientToServer.h` — 110 KB
- `ConnectionManager.ClientToServerFunctions.cs` — 257 KB (largest generated C# file)

### 3. MuEditor ↔ MuMain (Same-Process)

**Direction:** Bidirectional (direct memory access)
**Mechanism:** `#ifdef _EDITOR` conditional compilation, same address space

- Editor reads/writes game state directly (items, skills, characters)
- Console output redirected from `wprintf` → ImGui via macros in `stdafx.h`
- Input blocking: `MuInputBlockerCore` prevents game input when hovering editor UI
- Editor lifecycle managed by `MuEditorCore` singleton, initialized in `Winmain.cpp`

### 4. CMake Build Integration

**Direction:** Build system orchestration
**Mechanism:** CMake custom commands and targets

```
CMakeLists.txt
├── Main target (C++ executable)
│   ├── GLOB_RECURSE source/*.cpp
│   ├── GLOB_RECURSE MuEditor/*.cpp (if ENABLE_EDITOR)
│   └── Links: Win32 libs, OpenGL, GLEW, turbojpeg, wzAudio, ImGui
│
├── ClientLibrary target (custom command)
│   ├── dotnet publish → Native AOT DLL
│   ├── Auto-detects dotnet.exe (Windows) or dotnet (Linux)
│   ├── WSL path translation via wslpath
│   └── Copies DLL to executable directory
│
└── ConstantsReplacer target (custom command)
    └── dotnet build → WinForms executable
```

## Data Flow

### Network Packet Flow

```
OpenMU Server
    │
    │ TCP (encrypted)
    ▼
ClientLibrary (.NET)
    │ ConnectionManager receives raw bytes
    │ Deserializes using MUnique.OpenMU.Network.Packets
    │ Invokes registered C++ callback delegates
    ▼
MuMain C++ (PacketFunctions_*.cpp)
    │ Processes game state updates
    │ Updates CHARACTER, ITEM, OBJECT globals
    ▼
Rendering Pipeline
    │ SceneManager dispatches to active scene
    │ OpenGL immediate mode rendering
    ▼
Display
```

### Code Generation Flow

```
MUnique.OpenMU.Network.Packets (NuGet)
    │ XML packet definitions
    ▼
XSLT Transforms (4 files)
    │
    ├──→ C++ Headers: PacketBindings_*.h (struct definitions)
    ├──→ C++ Sources: PacketFunctions_*.h/cpp (handler implementations)
    └──→ C# Sources: ConnectionManager.*Functions.cs (extension methods)
```

## Cross-Platform Migration Impact

The planned SDL3/SDL_gpu migration (see `CROSS_PLATFORM_PLAN.md`) affects integration at:

1. **C++/.NET boundary**: `wchar_t` changes from 2-byte (Windows) to 4-byte (Linux/macOS) — requires `char16_t` at interop boundary
2. **DLL loading**: `LoadLibrary` → `dlopen`, `.dll` → `.so`/`.dylib`
3. **MuEditor backends**: `imgui_impl_win32` → `imgui_impl_sdl3`, `imgui_impl_opengl2` → `imgui_impl_sdlgpu3`
4. **Build system**: New CMake presets for `linux-x64`, `macos-arm64`, `macos-x64`

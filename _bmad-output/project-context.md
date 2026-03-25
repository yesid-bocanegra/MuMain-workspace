---
project_name: 'MuMain-workspace'
user_name: 'Paco'
date: '2026-02-26'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'code_quality', 'workflow_rules', 'critical_rules']
status: 'complete'
rule_count: 47
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

### Core
- **C++20** — `CMAKE_CXX_STANDARD 20`, extensions OFF, CMake 3.25+, Ninja generator
- **.NET 10 Native AOT** — `net10.0`, `PublishAot=true` (ClientLibrary network bridge)
- **XSLT code generation** — packet binding headers from XML definitions

### Compilers / Toolchains
- **MinGW-w64 i686** — CI cross-compile (Linux → Windows x86 `.exe`)
- **MSVC** — Windows native (x86 + x64 presets via `CMakePresets.json`)
- **macOS** — quality gates only; cannot compile game (Win32 APIs)

### Key Dependencies
| Dependency | Version | Notes |
|---|---|---|
| OpenGL 1.x + GLEW | vendored headers | Immediate mode rendering |
| libturbojpeg | 3.1.3 | Built from source or static `.a` |
| wzAudio | vendored | Pre-built `.lib`/`.dll` |
| imgui | submodule | Editor builds only (`ENABLE_EDITOR`) |
| Catch2 | 3.7.1 | FetchContent, opt-in (`BUILD_TESTING=ON`) |
| MUnique.OpenMU.Network.Packets | 0.9.8 | NuGet, .NET layer |

### Quality Tooling
| Tool | Version/Config | Scope |
|---|---|---|
| clang-format | 21.1.8 (pinned in CI) | Allman braces, 4-space, 120 col |
| clang-tidy | warnings-as-errors | Project headers only (`source/.*`) |
| cppcheck | warning,performance,portability | `win32W` platform, skips ThirdParty/ |
| StyleCop | 1.2.0-beta.435 | .NET layer |
| VSTHRD analyzers | 17.11.20 | VSTHRD103 as error |

### Critical Version Constraints
- C++20 features available — use `std::filesystem`, `std::chrono`, structured bindings
- .NET requires Windows `dotnet.exe` (WSL uses `/mnt/c/.../dotnet.exe` interop) — without it game compiles but cannot connect to servers
- clang-format version **must** match CI (21.1.8) or formatting checks fail

## Critical Implementation Rules

### C++ Language Rules

**Naming (Legacy Coexistence — follow existing patterns when modifying legacy code):**
- Classes: `C` prefix (`CMapManager`, `CErrorReport`), `CNewUI*` for UI classes
- Members: `m_` + Hungarian hint (`m_byState`, `m_wLevel`, `m_dwTickCount`, `m_pNewUIMng`, `m_szName`)
- Functions: PascalCase (`GetTimeElapsed()`, `RenderBackground()`)
- Constants/macros: `UPPER_SNAKE_CASE` (`MAX_CHAT_SIZE`, `SAFE_DELETE`)
- Hungarian prefixes: `by`=BYTE, `w`=WORD, `dw`=DWORD, `sz`=string, `p`=pointer, `n`/`i`=int, `f`=float, `b`=bool
- Feature flags: author-initials prefix (`ASG_ADD_GENS_SYSTEM`, `KJH_PBG_ADD_INGAMESHOP_SYSTEM`)
- File prefixes: `Zzz` (core systems), `NewUI` (UI), `GM` (maps), `CS` (events/network), `w_` (gameplay)

**Modern C++ (mandatory in new code):**
- `std::unique_ptr` — no raw `new`/`delete`
- `nullptr` — never `NULL`
- `std::chrono::steady_clock` — never `timeGetTime()` or `GetTickCount()`
- `std::filesystem::path` — never backslash path literals
- `[[nodiscard]]` on new fallible functions
- `#pragma once` only (no `#ifndef` guards)

**Error Handling:**
- Return codes (`bool`/`int`) — caller checks and propagates
- No exceptions in game loop — only at startup/init, JSON parsing, third-party boundaries
- `assert()` for programmer invariants only — never on network/file/user data

**Memory:**
- Legacy `SAFE_DELETE(p)`, `SAFE_DELETE_ARRAY(p)`, `SAFE_RELEASE(p)` — do not introduce new instances
- New code: `std::unique_ptr<T>`, `std::shared_ptr<T>` sparingly
- `SmartPointer(classname)` macro → `typedef std::shared_ptr<classname> classnamePtr`

**Includes & PCH:**
- Flat by directory: `#include "ErrorReport.h"` not `#include "Core/ErrorReport.h"`
- PCH `stdafx.h` reused via `target_precompile_headers(REUSE_FROM MUCore)`
- `SortIncludes: Never` — preserve existing include order

**Logging (use correct mechanism):**
| Mechanism | When | Output |
|---|---|---|
| `g_ErrorReport.Write(L"fmt", ...)` | Asset failures, network state, diagnostics | `MuError.log` |
| `g_ConsoleDebug->Write(MCD_RECEIVE, L"fmt", ...)` | Packet debug, live dev | In-game console (debug only) |
| **Dead — do not use:** | `wprintf`, `__TraceF()`, `DebugAngel`, `ExecutionLog` | — |

### Framework & Architecture Rules

**Game Loop:**
- Monolithic single-threaded render + update cycle in `WinMain()`
- No ECS — traditional OOP with global singletons
- Singletons: `GetInstance()` (new) or `Singleton<T>` CRTP base (old)
- Namespaces: `SEASON3B::` (legacy), lowercase (new code)

**CMake Module Targets:**
| Target | Role | Dependencies |
|---|---|---|
| `MUCommon` | INTERFACE — propagates includes, C++20, defines | — |
| `MUCore` | Foundation | No game dependencies |
| `MUProtocol` | Crypto/packet encoding | Core only |
| `MUData` | Game data loading/localization | Core |
| `MURenderFX` | Effects, models, textures, OpenGL | Core |
| `MUAudio` | Sound system | Core |
| `MUThirdParty` | External code | Core |
| `MUPlatform` | Platform abstraction (empty — pre-migration) | Core |
| `MUGame` | Network, World, Gameplay, UI, Scenes, Dotnet | All above |
| `Main` | Entry point only | MUGame |

**Feature Flag System (`Defined_Global.h`):**
- Author-initials prefix: `ASG_`, `KJH_`, `PBG_`, `PJH_`, `KWAK_`, `LDK_`
- Hierarchical: parent `#define` → child `#ifdef` blocks
- Disabled flags: `//^#define FLAG_NAME` — keep the comment, don't delete
- CMake-injected: `_LANGUAGE_ENG`, `UNICODE`, `_DEBUG`/`NDEBUG`, `_EDITOR`, `_USE_32BIT_TIME_T`

**.NET Native AOT Integration:**
- Built at CMake configure time via `add_custom_command`
- C++ loads `.dll` via function pointers from `Dotnet/Connection.h`
- **NEVER hand-edit** generated files in `src/source/Dotnet/`: `PacketBindings_*.h`, `PacketFunctions_*.h/.cpp`
- WSL interop: `wslpath -w` converts paths for `dotnet.exe`

**i18n / Translation:**
- `GAME_TEXT("key")` — always available, game UI strings
- `EDITOR_TEXT("key")` — `_EDITOR` builds only
- `META_TEXT("key", "fallback")` — `_EDITOR` builds only
- Translation files: `src/bin/Translations/{locale}/game.json` (key-value JSON)

### Testing Rules

**Framework:** Catch2 v3.7.1 (FetchContent, opt-in `-DBUILD_TESTING=ON`, target `MuTests`, CTest runner)

**Current State:** Minimal — 1 test file (`tests/core/test_timer.cpp`). Coverage threshold = 0, growing incrementally.

**Organization:** `tests/{module}/test_{name}.cpp` mirroring `src/source/{Module}/`

**Rules:**
- New features should include tests when practical
- Tests must not depend on Win32 APIs — test logic, not platform
- Use Catch2 `REQUIRE` / `CHECK` macros, `TEST_CASE` / `SECTION` structure
- No mocking framework — keep tests simple, focused on pure logic

### Code Quality & Style Rules

**Formatting (`.clang-format` — enforced in CI):**
- Allman braces (opening brace on its own line)
- 4-space indent, no tabs, 120-column limit
- Pointer alignment: left (`int* p` not `int *p`)
- Short `if`/loops on single line: **never**
- Short functions on single line: only if empty body
- Include sorting: **disabled** — preserve existing order
- Encoding: UTF-8, LF line endings

**clang-tidy (warnings = errors):**
- Enabled: `bugprone-*`, `modernize-use-nullptr`, `modernize-use-override`, `modernize-use-using`, `modernize-make-unique`, `performance-*`, `readability-redundant-smartptr-get`, `readability-container-size-empty`, `misc-unused-using-decls`
- `WarningsAsErrors: '*'`
- Only project headers: `HeaderFilterRegex: 'source/.*'`

**cppcheck:**
- Enables: `warning,performance,portability` | Platform: `win32W` | Standard: `c++20`
- Global suppressions: `missingInclude`, `unmatchedSuppression`, `unusedFunction`
- `ThirdParty/` excluded entirely
- Inline `// cppcheck-suppress` for known false positives

**CI Quality Gate (every push/PR):**
1. clang-format check + cppcheck on **changed files only** (skips `ThirdParty/`, `Dotnet/`)
2. MinGW cross-compile build
3. semantic-release (main branch only, after 1+2 pass)

**.NET Quality:**
- StyleCop enforced, `VSTHRD103` as error (no `.Wait()`/`.Result` in async), `SA1309` disabled

### Development Workflow Rules

**Commits (Conventional Commits → semantic-release):**
- Format: `type(scope): description`
- Types: `feat`, `fix`, `refactor`, `docs`, `build`, `chore`, `test`, `perf`
- Scopes: `render`, `network`, `ui`, `input`, `audio`, `build`, `editor`, `i18n`, `codegen`
- Examples: `feat(ui): add inventory sorting`, `fix(network): handle disconnect during character select`

**Branch Naming:** `feature/`, `fix/`, `refactor/`

**Build by OS:**
| OS | Capability | Command |
|---|---|---|
| macOS | Quality gates only | `./ctl check` |
| Linux/WSL | Full build + quality | MinGW cross-compile + `./ctl check` |
| Windows | Full build (MSVC) | `cmake --preset windows-x64` |

**Pre-push Hooks:**
- Installed at workspace root + MuMain submodule
- Runs `./paw check` → `./ctl check` (format-check + lint)
- Blocks pushes that fail quality gates

**Workspace Structure:**
- MuMain is a **git submodule** — commits inside `MuMain/`, workspace references submodule commit
- CI workflows live inside `MuMain/.github/workflows/`, not at workspace level

### Critical Don't-Miss Rules

**Banned Win32 APIs (SDL3 cross-platform migration in progress):**
| Category | BANNED | Replacement |
|---|---|---|
| Windowing | `CreateWindowEx`, `wglCreateContext`, `SwapBuffers` | `SDL_CreateWindow()`, SDL3 GPU |
| Input | `GetAsyncKeyState` | `g_platformInput->IsKeyDown()` |
| File I/O | `_wfopen`, `CreateFile`/`WriteFile` | `mu_wfopen` shim, `std::ofstream`/`std::filesystem` |
| Timing | `timeGetTime()`, `GetTickCount()` | `PlatformCompat.h` shim → `std::chrono::steady_clock` |
| Audio | `DirectSoundCreate`, `IDirectSound*` | miniaudio `ma_engine` (Phase 3, not yet done) |
| String | `MessageBoxW` | `PlatformCompat.h` shim → `SDL_ShowSimpleMessageBox` |
| Threading | `_beginthreadex`, `WaitForSingleObject` | `std::thread` + `std::future` |

**Hard Rules:**
- No `#ifdef _WIN32` in game logic — only in platform abstraction headers (`PlatformCompat.h`, `PlatformTypes.h`)
- No backslash path literals — forward slashes only
- No `wchar_t` in new serialization — `char` + UTF-8
- No raw `new`/`delete` — `std::unique_ptr`
- CI (MinGW) build must pass on all changes

**Generated Files — NEVER EDIT:**
- `src/source/Dotnet/PacketBindings_*.h`
- `src/source/Dotnet/PacketFunctions_*.h` / `.cpp`
- XSLT-generated from XML packet definitions in `ClientLibrary/`

**Anti-Patterns:**
- No new `SAFE_DELETE` / `SAFE_DELETE_ARRAY` — use smart pointers
- No `NULL` — use `nullptr`
- No new `wprintf` logging — use `g_ErrorReport` or `g_ConsoleDebug`
- No exceptions in the game loop
- No include sorting (clang-format `SortIncludes: Never`)
- No `#ifndef` header guards — `#pragma once` only

**Prohibited Code Patterns (cross-platform — grep-verifiable):**

| Pattern | Where prohibited | Correct fix |
|---------|-----------------|-------------|
| `#ifdef _WIN32` wrapping call sites or function bodies | Any file outside `Platform/`, `ThirdParty/`, `Audio/DSwaveIO*` | Add type stub to `PlatformCompat.h` non-Windows section; or CMake-exclude the whole TU with `if(NOT WIN32)` |
| `#ifdef _WIN32` added to game logic headers (networking, gameplay, UI) | Any `.h`/`.cpp` in game module directories | PlatformCompat.h stub for the missing type; the call site is NEVER touched |

**Verification grep (must return empty after any cross-platform compilation fix):**
```bash
grep -rn "#ifdef _WIN32" MuMain/src/source/ --include="*.cpp" --include="*.h" \
  | grep -v "/Platform/" | grep -v "/ThirdParty/" | grep -v "Audio/DSwaveIO"
```
If this grep returns any matches: the fix was applied at the wrong location. Trace the undeclared identifier back to the header that defines it and add a stub there instead.

**Fix Decision Tree (when a macOS/Linux build error occurs in game logic):**
1. Read the error: `error: unknown type name 'FOO'` or `error: use of undeclared identifier 'bar'`
2. Find which Windows header defines `FOO`/`bar` (e.g., `<wininet.h>`, `<mmsystem.h>`, `<wingdi.h>`)
3. Add a no-op stub to `PlatformCompat.h` in the `#else // !_WIN32` section
4. Do NOT touch the call site — the call site is correct; it just needs the type to be available

**Security:**
- Never trust network packet data — validate before use
- Never `assert()` on external data (network, files, user input)
- Prefer `std::wstring` / `snprintf` over legacy `wcscpy`/`sprintf` in new code

---

## Usage Guidelines

**For AI Agents:**
- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Cross-reference with `docs/development-standards.md` for full details

**For Humans:**
- Keep this file lean and focused on agent needs
- Update when technology stack or patterns change
- Review quarterly for outdated rules
- Remove rules that become obvious over time

Last Updated: 2026-02-26

# Development Standards

Standards for contributing to MuMain during the SDL3 cross-platform migration. Cross-platform readiness is the primary focus — developers should be able to look up any Win32 API and find its portable replacement.

For implementation details, see [CROSS_PLATFORM_PLAN.md](CROSS_PLATFORM_PLAN.md). For rationale and research, see [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md).

---

## 1. Cross-Platform Readiness

### Banned Win32 API Table

Do not introduce new calls to these APIs. Use the listed replacements. The Phase/Session column links to the migration plan session where each replacement is implemented.

#### Windowing & Graphics

| Banned API | Replacement | Phase/Session | Notes |
|------------|-------------|---------------|-------|
| `CreateWindowEx` / `RegisterClass` | `SDL_CreateWindow()` | 1 / 1.2 | Wrapped in `IPlatformWindow` |
| `ShowWindow` / `UpdateWindow` | `SDL_ShowWindow()` | 1 / 1.2 | |
| `GetDC` / `ReleaseDC` | SDL3 manages context | 1 / 1.2 | |
| `wglCreateContext` / `wglMakeCurrent` | `SDL_GL_CreateContext()` → `SDL_CreateGPUDevice()` | 1 / 1.7, 2 / 2.9 | GL context is scaffolding; SDL_gpu is final target |
| `wglGetProcAddress` | Removed (no GL extensions used) | 1 / 1.7 | |
| `wglSwapIntervalEXT` | `SDL_GL_SetSwapInterval()` | 1 / 1.7 | |
| `SwapBuffers` | `SDL_GL_SwapWindow()` → `SDL_SubmitGPUCommandBuffer` | 1 / 1.7, 2 / 2.9 | |
| `ChoosePixelFormat` / `SetPixelFormat` | `SDL_GL_SetAttribute()` | 1 / 1.7 | |
| `glBegin` / `glEnd` / `glVertex*` | `MuRenderer` API (vertex buffers) | 2 / 2.3–2.7 | 111 call sites across 14 files |
| `glPushMatrix` / `glPopMatrix` / `glTranslatef` | `MatrixStack` utility | 2 / 2.4 | |
| `GetSystemMetrics` | `SDL_GetCurrentDisplayMode()` | 5 / 5.4 | |

#### Input

| Banned API | Replacement | Phase/Session | Notes |
|------------|-------------|---------------|-------|
| `GetAsyncKeyState` | `g_platformInput->IsKeyDown()` | 1 / 1.6 | 104 calls across 8 files |
| `SetCapture` / `ReleaseCapture` | `SDL_CaptureMouse()` | 1 / 1.3 | |
| `ShowCursor` | `SDL_ShowCursor()` / `SDL_HideCursor()` | 1 / 1.3 | |
| `OpenClipboard` / `GetClipboardData` / `CloseClipboard` | `SDL_GetClipboardText()` | 6 / 6.1 | 3 calls in `UIControls.cpp` |
| `CreateWindowW(L"edit", ...)` (edit control) | `SDL_StartTextInput()` / `SDL_StopTextInput()` | 6 / 6.1 | |
| `WM_CHAR` handling | `SDL_EVENT_TEXT_INPUT` | 6 / 6.3 | |

#### File I/O

| Banned API | Replacement | Phase/Session | Notes |
|------------|-------------|---------------|-------|
| `_wfopen` / `_wfopen_s` | `mu_wfopen` shim (auto-normalizes `\` → `/`, case-insensitive fallback) | 0 / 0.3 | 60 calls across 28 files; drop-in via `#define` |
| `CreateFile` / `WriteFile` / `ReadFile` | `std::ofstream` / `std::ifstream` / `std::filesystem` | 5 / 5.7 | GameShop FileDownloader files |
| `GetFileAttributes` / `CreateDirectory` / `DeleteFile` | `std::filesystem::exists()` / `create_directories()` / `remove()` | 5 / 5.7 | |
| `GetModuleFileName` | `/proc/self/exe` (Linux), `_NSGetExecutablePath` (macOS) | 5 / 5.4 | 9 calls across 5 files |
| `GetPrivateProfileInt` / `WritePrivateProfileString` | Portable INI parser (`IniFile.h`) | 5 / 5.1 | |

#### Timing

| Banned API | Replacement | Phase/Session | Notes |
|------------|-------------|---------------|-------|
| `timeGetTime()` | `PlatformCompat.h` shim → `std::chrono::steady_clock` | 0 / 0.3 | 105+ calls, 30 files; zero call-site changes |
| `GetTickCount()` | `PlatformCompat.h` shim → `std::chrono::steady_clock` | 0 / 0.3 | |
| `timeBeginPeriod` / `timeEndPeriod` | No-op on Linux/macOS | 5 / 5.4 | |
| `SetTimer` / `KillTimer` | `std::chrono` checks in main loop | 5 / 5.4 | 20 calls, 10 files |

#### Audio

| Banned API | Replacement | Phase/Session | Notes |
|------------|-------------|---------------|-------|
| `DirectSoundCreate` / `IDirectSound*` | miniaudio `ma_engine` + `ma_sound` | 3 / 3.1–3.2 | Behind `IPlatformAudio` interface |
| `wzAudioCreate` / `wzAudioPlay` / `wzAudioStop` | miniaudio `ma_sound` streaming | 3 / 3.3 | Only 7/18 functions used, all in `Winmain.cpp` |
| `PlaySound` (Win32) | `g_platformAudio->PlaySound()` | 3 / 3.2 | |

#### Network / HTTP

| Banned API | Replacement | Phase/Session | Notes |
|------------|-------------|---------------|-------|
| `InternetOpen` / `InternetConnect` | cpp-httplib or libcurl behind `IPlatformHTTP` | 5 / 5.7 | GameShop FileDownloader |
| `HttpOpenRequest` / `HttpSendRequest` | `IPlatformHTTP::Download()` | 5 / 5.7 | |
| `FtpOpenFile` / `FtpFindFirstFile` | libcurl (if FTP needed) | 5 / 5.7 | |
| `URLDownloadToFile` | `IPlatformHTTP::Download()` | 5 / 5.7 | Banner images in `BannerInfo.cpp` |
| `InternetReadFile` / `HttpQueryInfo` | Handled by HTTP library | 5 / 5.7 | |

#### String / Memory

| Banned API | Replacement | Phase/Session | Notes |
|------------|-------------|---------------|-------|
| `MessageBoxW` / `MessageBox` | `PlatformCompat.h` shim → `SDL_ShowSimpleMessageBox` | 0 / 0.3 | 181 calls, 27 files; drop-in via `#define` |
| `sprintf_s` / `wcscpy_s` / `strcpy_s` | `std::snprintf()` or `std::format()` (C++20) | 9 / 9.2 | 14 calls across 8 files |
| `_snprintf` | `std::snprintf()` | 9 / 9.2 | |
| `RtlSecureZeroMemory` | `PlatformCompat.h` shim → `explicit_bzero` | 0 / 0.3 | |
| `GetTextExtentPoint32` | `g_platformFont->MeasureText()` | 4 / 4.3 | |
| `CreateFont` (GDI) | `g_platformFont->CreateFont()` via FreeType | 4 / 4.4 | |

#### System

| Banned API | Replacement | Phase/Session | Notes |
|------------|-------------|---------------|-------|
| `ShellExecute(url)` | `xdg-open` (Linux), `open` (macOS) | 5 / 5.4 | 2 calls, 2 files |
| `GetProcessTimes` | `/proc/self/stat` (Linux), `getrusage` (macOS) | 5 / 5.3 | |
| `CryptProtectData` / `CryptUnprotectData` | AES-256 with platform key source | 5 / 5.2 | DPAPI replacement |
| `_beginthreadex` / `WaitForSingleObject` | `std::thread` + `std::future` | 5 / 5.4, 5.7 | 8 calls total |
| Registry APIs (`RegOpenKey`, etc.) | File-based config | 0 / 0.6 | Wrapped in `#ifdef _WIN32` |

### Platform Abstraction Interfaces

All new platform-dependent code **must** go through these interfaces (defined in Phase 1, Session 1.1):

| Interface | Responsibility | Example Methods |
|-----------|---------------|-----------------|
| `IPlatformWindow` | Window lifecycle, GL/GPU context, event loop | `Create`, `SwapBuffers`, `PollEvents`, `SetFullscreen` |
| `IPlatformInput` | Keyboard, mouse, gamepad state | `IsKeyDown`, `GetMousePosition`, `SetMousePosition` |
| `IPlatformAudio` | Sound effects, music, 3D spatialization | `LoadSound`, `PlaySound`, `Set3DPosition`, `PlayMusic` |
| `IPlatformFont` | Text rendering and measurement | `CreateFont`, `RenderText`, `MeasureText` |
| `IPlatformConfig` | Settings persistence, credential encryption | `ReadInt`, `WriteString`, `EncryptString` |
| `IPlatformHTTP` | File downloads (HTTP/FTP) | `Download`, `DownloadToMemory` |
| `PlatformSystem` (namespace) | OS utilities | `OpenURL`, `GetCpuUsage`, `GetExecutablePath` |

**Rule:** Do not add `#ifdef _WIN32` in game logic files. Platform conditionals belong exclusively in platform abstraction headers (`PlatformCompat.h`, `PlatformTypes.h`) and platform backend implementations (`Platform/Win32/`, `Platform/SDL/`).

### wchar_t Portability

`wchar_t` is 2 bytes on Windows and 4 bytes on Linux/macOS. The codebase has 2,089 occurrences across 349 files.

**Rules for new code:**
- Use `char` + UTF-8 internally
- Convert to/from `wchar_t` only at system boundaries
- Never assume `sizeof(wchar_t) == 2`
- For C# interop: use `char16_t` on non-Windows (C# always marshals UTF-16)
- For `.bmd` binary files: use `ImportChar16ToWchar()` from `StringConvert.h` when reading 2-byte text fields
- All MU Online text is BMP (Basic Multilingual Plane) — `char16_t` ↔ `wchar_t` casts are safe

### Path Handling

- Use forward slashes (`/`) in all new code
- Use `std::filesystem::path` for path manipulation
- No backslash literals (`L"Data\\Local\\"`) in new code — the `mu_wfopen` shim auto-normalizes ~2,050 existing backslash paths
- No case-sensitivity assumptions — Linux filesystems are case-sensitive

### Platform Portability Checklist

Use this checklist for every PR. Extractable for `.github/PULL_REQUEST_TEMPLATE.md`:

- [ ] No new Win32 API calls introduced (check against [banned API table](#banned-win32-api-table))
- [ ] No backslash path literals
- [ ] No `wchar_t` in new serialization or storage code
- [ ] No platform conditionals (`#ifdef _WIN32`) in game logic (only in platform abstraction layer)
- [ ] No `NULL` — use `nullptr`
- [ ] No raw `new`/`delete` — use smart pointers or RAII
- [ ] No unguarded `#pragma` — wrap in `#ifdef _MSC_VER`
- [ ] No case-sensitivity assumptions in file paths
- [ ] No edits to generated files (see [Generated Code](#4-generated-code))
- [ ] No hardcoded user-facing strings (use [i18n system](#5-translation--i18n))
- [ ] CI (MinGW) build passes
- [ ] Windows build invariant maintained

---

## 2. C++ Conventions

### Naming

Existing patterns (maintain in touched files):

| Element | Convention | Example |
|---------|-----------|---------|
| Functions / methods | PascalCase | `RenderBitmap()`, `GetCharacterPosition()` |
| Member variables | `m_` prefix + Hungarian hint | `m_byState`, `m_wLevel`, `m_dwTickCount`, `m_szName`, `m_pItem` |
| Local variables | camelCase or Hungarian | `byIndex`, `dwCurrentTime` |
| UI classes | `CNewUI*` prefix | `CNewUIMyInventory`, `CNewUIBuffWindow` |
| Singletons | `GetInstance()` | `GameConfig::GetInstance()`, `Translator::GetInstance()` |
| Namespaces | `SEASON3B` (legacy), lowercase (new) | `SEASON3B::`, `i18n::` |
| Constants / macros | UPPER_SNAKE_CASE | `MAX_CHANNEL`, `SAFE_DELETE` |
| Feature flags | Author prefix + UPPER_SNAKE | `ASG_ADD_GENS_SYSTEM`, `PJH_ADD_PANDA_PET` |

Hungarian prefixes in use: `by` (BYTE), `w` (WORD), `dw` (DWORD), `sz` (string/char array), `p` (pointer), `n`/`i` (int), `f` (float), `b` (bool).

**New code:** Follow the same naming conventions for consistency. Use `m_` for members, PascalCase for functions.

### Formatting

Per `.editorconfig`:

- **Indentation:** 4 spaces (no tabs)
- **Encoding:** UTF-8
- **Line endings:** LF (`\n`)
- **Brace style:** Allman (opening brace on its own line)
- **Trailing whitespace:** Trimmed
- **Final newline:** Required

### Memory Management

**Existing code** uses `SAFE_DELETE` / `SAFE_DELETE_ARRAY` macros and manual `new`/`delete`. Do not introduce new instances of these patterns.

**New code:**
- `std::unique_ptr` for single-owner resources
- `std::shared_ptr` only when shared ownership is genuinely needed
- RAII wrappers for system handles
- No raw `new`/`delete`

### Error Handling

- Return codes are the existing pattern — continue using them in touched files
- No exceptions in the game loop (performance-critical path)
- Use `assert()` for programmer errors in debug builds
- Log errors via the existing logging system (`ErrorReport`)

### Modern C++ (New Code)

- `std::chrono` for all timing (not `timeGetTime()`)
- `std::filesystem` for path operations
- Range-based `for` loops over index-based where applicable
- `auto` where the type is obvious from context
- `constexpr` over `#define` for typed constants
- `nullptr` instead of `NULL`
- `enum class` for new enumerations
- `[[nodiscard]]` on functions where ignoring the return value is likely a bug

### Feature Flags

All compile-time feature flags live in `Defined_Global.h`.

- Prefix with author initials: `ASG_`, `KJH_`, `PBG_`, `PJH_`
- Document hierarchical dependencies (parent `#ifdef` enables child flags)
- Debug-only features wrap in `#ifdef _DEBUG`
- Commented-out flags (e.g., `//^#define PBG_ADD_CHARACTERSLOT`) indicate intentionally disabled features — do not delete them

### Precompiled Headers

`stdafx.h` is the PCH for all source files (691 files).

- New headers **must** be includable without `stdafx.h` — use forward declarations and explicit `#include` directives
- Do not add project headers to `stdafx.h` — it is for system/library includes only
- Wrap `#pragma warning` directives in `#ifdef _MSC_VER`
- The 26 warning suppressions in `stdafx.h` are intentional technical debt — do not add more without documenting the rationale

---

## 3. C# / .NET Conventions

StyleCop handles most enforcement. These are the project-specific decisions.

### Style

- **Namespaces:** File-scoped, rooted at `MUnique.Client.Library`
- **Documentation:** XML doc comments required on public API (`documentExposedElements: true`, `documentInterfaces: true` in `stylecop.json`)
- **Company header:** `MUnique`, MIT license

### Analyzer Configuration

From `.editorconfig`:

| Rule | Severity | Rationale |
|------|----------|-----------|
| SA1309 (field names shouldn't begin with underscore) | **None** | Project uses `_fieldName` convention |
| SA1516 (elements separated by blank line) | **None** | Overly strict for dense interop code |
| SA1615 (return value documentation) | **Suggestion** | Encouraged but not enforced |
| VSTHRD103 (call async in async) | **Error** | No `Task.Result` or `.Wait()` in async contexts |
| VSTHRD111 (ConfigureAwait) | **Warning** | Use `ConfigureAwait(false)` in library code |

### Interop

- `[UnmanagedCallersOnly]` for all Native AOT exported functions
- `unsafe` code only in the marshaling layer (`ConnectionWrapper.cs`)
- Document all function pointer signatures with XML doc comments
- Native AOT publish produces `.dll` (Windows), `.so` (Linux), `.dylib` (macOS)

### Performance

- Zero-allocation patterns in hot paths (see `ConnectionWrapper.cs`)
- `Span<byte>` / `Memory<byte>` over `byte[]` for buffer operations
- Pool buffers where possible — avoid allocating in packet handlers
- `stackalloc` for small, fixed-size temporary buffers

---

## 4. Generated Code

These files are auto-generated by XSLT transforms from XML packet definitions. **Do not edit them manually.**

### C++ Generated Files

Located in `src/source/Dotnet/`:

| File | Generated By |
|------|-------------|
| `PacketBindings_ChatServer.h` | `GenerateFunctionsHeader.xslt` |
| `PacketBindings_ClientToServer.h` | `GenerateFunctionsHeader.xslt` |
| `PacketBindings_ConnectServer.h` | `GenerateFunctionsHeader.xslt` |
| `PacketFunctions_ChatServer.h` / `.cpp` | `GenerateFunctions.xslt` / `GenerateFunctionsHeader.xslt` |
| `PacketFunctions_ClientToServer.h` / `.cpp` | `GenerateFunctions.xslt` / `GenerateFunctionsHeader.xslt` |
| `PacketFunctions_ConnectServer.h` / `.cpp` | `GenerateFunctions.xslt` / `GenerateFunctionsHeader.xslt` |
| `PacketFunctions_Custom.h` / `.cpp` | `GenerateFunctions.xslt` / `GenerateFunctionsHeader.xslt` |

### Regeneration

1. Modify the XML packet definitions in `ClientLibrary/`
2. Run the XSLT transforms (via the ConstantsReplacer tool or build pipeline)
3. Commit regenerated output **separately** from manual changes (preserves clean diffs)

### Identification

Generated files have header comments marking them as auto-generated. If you see `// <auto-generated>` or similar, do not edit.

---

## 5. Translation / i18n

All user-facing strings must go through the i18n system (`src/source/Translation/i18n.h`).

### Macros

| Macro | Domain | Availability |
|-------|--------|-------------|
| `GAME_TEXT("key")` | Game | Always (debug + release) |
| `EDITOR_TEXT("key")` | Editor | `_EDITOR` builds only |
| `META_TEXT("key", "fallback")` | Metadata | `_EDITOR` builds only |

### Translation Domains

| Domain | Build | Purpose |
|--------|-------|---------|
| `Game` | All builds | Player-facing UI text, messages, tooltips |
| `Editor` | `_EDITOR` only | Debug editor labels, tool names |
| `Metadata` | `_EDITOR` only | Internal data labels |

### Locale Files

- Location: `src/bin/Translations/{locale}/game.json`
- Format: Simple JSON key-value pairs
- Fallback cascade: translation found → fallback parameter → key itself
- Available locales discovered at runtime via directory scan

### Rules

- Never hardcode user-facing strings — use `GAME_TEXT("key")`
- Add new keys to the English locale file first
- Keys should be descriptive: `"inventory.full"` not `"msg_042"`

---

## 6. Git & CI Workflow

### Branch Naming

- `feature/` — new functionality
- `fix/` — bug fixes
- `refactor/` — code restructuring without behavior change

### Commit Messages

- Imperative mood: "Add input mapping" not "Added input mapping"
- Reference issue numbers where applicable
- Separate generated file commits from manual changes

### Pull Requests

- Include the [platform portability checklist](#platform-portability-checklist) items
- CI (MinGW cross-compile) must pass — this is the build invariant from the [cross-platform plan](CROSS_PLATFORM_PLAN.md)
- Keep PRs focused — one concern per PR

### CI Pipeline

- **MinGW build** (`.github/workflows/mingw-build.yml`): Ubuntu cross-compile to Windows x86, validates all PRs
- Dependency caching (libjpeg-turbo) with versioned cache keys
- Ninja generator for parallel compilation
- Artifact upload with `if-no-files-found: error` (fail-fast)

---

## 7. Build System

### CMake Presets

Use the presets defined in `CMakePresets.json`. Do not pass raw CMake flags on the command line.

Current presets:
- `windows-x64` — MSVC x64
- `mingw-x86` — MinGW-w64 cross-compile (CI)

Planned presets (Phase 0, Session 0.7):
- `linux-x64` — Ninja Multi-Config
- `macos-arm64` / `macos-x64` — Ninja Multi-Config

### Dependencies

- **Vendored:** `src/dependencies/` (git submodules) — libjpeg-turbo, GLEW, etc.
- **Future vendored:** miniaudio (single header)
- **Package-managed:** vcpkg or FetchContent for SDL3, FreeType

### Adding New Dependencies

1. Prefer header-only or single-file libraries (lower build complexity)
2. Document the decision in [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md) with rationale and rejected alternatives
3. Ensure the library builds on Windows, Linux, and macOS
4. Add to `vcpkg.json` or vendor in `src/dependencies/`

---

## 8. Transition Period Guidance

The codebase has 691 C++ source files with decades of accumulated patterns. These rules govern the migration period.

### Legacy Code Policy

- **Legacy patterns are permitted in untouched files.** Do not refactor files you are not otherwise modifying.
- **Boy scout rule applies to touched files:** Improve code you touch, but make improvements in **separate commits** from functional changes (preserves `git blame` usefulness).
- **No bulk reformatting PRs.** Formatting changes across many files create merge conflicts and obscure real changes.
- **Prioritize cross-platform compliance over style modernization.** Replacing a banned Win32 API is higher priority than converting `NULL` to `nullptr` in the same file.

### Migration Safety Rules

From the [cross-platform plan](CROSS_PLATFORM_PLAN.md):

1. **Never modify Windows behavior and add Linux behavior in the same session.** One change type per session.
2. **Each session leaves the Windows x64 build compilable.** This is the invariant — verified by CI.
3. **Use `#ifdef` wrappers in platform headers** (`PlatformCompat.h`, `PlatformTypes.h`), not scattered `#ifdef` at individual call sites.
4. **Git branch before each session.** The branch is the rollback boundary.
5. **Additive sessions before substitutive sessions.** Create new files before modifying existing ones.

---

## Related Documents

- [Cross-Platform Implementation Plan](CROSS_PLATFORM_PLAN.md) — 10-phase, 58-session migration roadmap
- [Cross-Platform Decisions](CROSS_PLATFORM_DECISIONS.md) — Research, library decisions, issue register
- [Development Guide](development-guide.md) — Build, run, test, environment setup
- [Integration Architecture](integration-architecture.md) — C++/.NET bridge, packet pipeline
- [Translation System](../MuMain/TRANSLATION_SYSTEM_INTEGRATION.md) — Full i18n architecture documentation

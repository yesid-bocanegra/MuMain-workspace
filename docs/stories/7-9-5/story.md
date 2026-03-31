# Story 7.9.5: Eliminate All Cross-Platform Stubs — Real SDL3 Implementations

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.9 - macOS Game Loop & Win32 Render Path Migration |
| Story ID | 7.9.5 |
| Story Points | 21 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-PLAT-COMPAT-KILLSTUBS |
| FRs Covered | All stub functions across the Platform layer replaced with real cross-platform implementations — game must run with full feature parity on macOS, Linux, and Windows |
| Prerequisites | 7-9-3 (done), 7-9-4 (done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Replace all stubs across Platform/ layer with real SDL3/POSIX/C++ implementations; refactor GDI text rendering to cross-platform font system; implement clipboard via SDL3; eliminate all no-op stubs, fake compat-headers, and placeholder globals |
| project-docs | documentation | Story artifacts |

---

## Background

Stubs are spread across the entire Platform layer — not just one file. The game compiles on all platforms but **does not run** — `OpenFont()` fails because GDI stubs return nullptr, `WebzenScene` returns early every frame, and zero draw calls reach the screen.

This is not a stub problem — it is a **missing implementation** problem. Every one of these functions existed because the game needed it on Windows. The game still needs it on macOS and Linux.

### Offending Files

| File | Stubs | Description |
|------|-------|-------------|
| `Platform/PlatformCompat.h` | 183 | Inline Win32 API stubs (GDI, window, clipboard, IME, registry, OpenGL, etc.) |
| `Platform/compat-headers/crtdbg.h` | 3 | CRT debug macros (`_ASSERTE`, `_CrtSetReportMode`, `_CrtSetReportFile`) |
| `Platform/compat-headers/dpapi.h` | ~2 | Windows Data Protection API — empty |
| `Platform/compat-headers/imm.h` | ~5 | IME constants and macros only |
| `Platform/compat-headers/io.h` | ~3 | Low-level I/O redirects |
| `Platform/compat-headers/process.h` | 1 | `_getpid` wrapper |
| `Platform/compat-headers/tlhelp32.h` | 2 | Tool Help Library empty structs |
| `Platform/compat-headers/GL/gl.h` | ~1 | OpenGL header redirect |
| `Platform/compat-headers/GL/glu.h` | ~1 | GLU header stub |
| `Platform/win32/Win32Window.cpp` | 3 | No-op stubs for Destroy, SetFullscreen, SetMouseGrab |
| `Platform/win32/Win32EventLoop.cpp` | 1 | Message pump delegation stub |
| `Platform/PlatformLibrary.cpp` | 5 | Error-handling nullptr returns |
| `Platform/PlatformGlobalStubs.cpp` | ~10 | Stub global variables for compilation |
| `Platform/GroundTruthCapture.cpp` | 2 | Debug/testing stubs |
| `Platform/PlatformCrypto.cpp` | 1 | Crypto nullptr return |
| `Audio/MiniAudioBackend.cpp` | 3 | Status return stubs |

### Constraint

**NO STUBS. NO MOCKS. NO SILENT FAILURES.** Every function must have a real implementation that provides the same functionality as the Win32 original. The game must build AND run with all features working on all platforms.

---

## Story

**[VS-0] [Flow:E]**

**As a** game client developer,
**I want** every function in PlatformCompat.h to have a real cross-platform implementation,
**so that** the game runs with full feature parity on macOS, Linux, and Windows — no silent failures, no missing functionality.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** PlatformCompat.h contains zero functions that return nullptr, FALSE, or 0 as a stub. Every function either has a real implementation or is provably dead code (deleted with evidence).
- [ ] **AC-2:** `OpenFont()` succeeds on SDL3 — `CUIRenderTextOriginal::Create()` initializes a usable pixel buffer and font rendering context. Text renders visibly on screen.
- [ ] **AC-3:** `GetTextExtentPoint32()` returns accurate glyph measurements (not fixed 8px/char). Text wrapping, tooltips, and UI layout work correctly.
- [ ] **AC-4:** `TextOut()` rasterizes text into the font buffer. All in-game text (chat, menus, tooltips, item names) renders correctly on SDL3.
- [ ] **AC-5:** Clipboard operations (`OpenClipboard`, `GetClipboardData`, `GlobalLock`, `CloseClipboard`) use `SDL_GetClipboardText()` and work correctly for paste operations.
- [ ] **AC-6:** `WebzenScene` completes successfully on SDL3 — loads fonts, displays title screen with progress bar, loads all game data, transitions to `LOG_IN_SCENE`.
- [ ] **AC-7:** All 183 functions audited. Each one is either: (a) replaced with a real implementation, (b) confirmed dead code and deleted, or (c) a type conversion/string utility that already works (not a stub).

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (naming, logging, PascalCase, `m_` prefix, `#pragma once`)
- [ ] **AC-STD-2:** Testing Requirements — Catch2 tests for font system, clipboard, text measurement
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — format-check + cppcheck + build)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 profiles, fixtures)

---

## Stub Inventory (183 functions)

### Category 1: Already Real Implementations (NOT stubs — verify only)

These functions already have real cross-platform implementations. Verify they work, do not touch unless broken:

- `mu_get_app_dir()` — uses `std::filesystem`, real implementation
- `mu_wchar_to_utf8()` — real UTF conversion
- `mu_wfopen()` / `mu_wfopen_s()` — real file I/O
- `mu_SecureZeroMemory()` — real memset
- `MultiByteToWideChar()` / `WideCharToMultiByte()` — real conversion using mbstowcs/wcstombs
- `wcsncpy_s()` / `wcstok_s()` / `wcscpy_s()` / `wcscat_s()` — real safe string functions
- `_wsplitpath()` — real path splitting
- `Sleep()` — real via `SDL_Delay` or `usleep`
- `timeGetTime()` / `GetTickCount()` / `GetTickCount64()` — real via `std::chrono`
- `GetCurrentDirectory()` — real via `std::filesystem`
- `GetLocalTime()` — real via `localtime`
- `ExitProcess()` — real via `exit()`
- `mu_get_process_cpu_times()` — real via platform APIs
- `mu_console_*` functions — real ANSI terminal implementations
- `mu_wchar_to_char16()` / `mu_char16_to_wchar()` — real conversions
- `mu_itow()` / `mu_mbclen()` / `mu_wcsupr()` / `mu_vswprintf()` / `mu_swprintf_s()` — real implementations
- `IntersectRect()` / `SetRect()` — real rect math
- `MessageBoxW()` — real via `SDL_ShowSimpleMessageBox`
- `MuSdlUtf8NextChar()` — real UTF-8 parsing
- `MuClipboardIsNumericOnly()` — real implementation
- `ShowCursor()` / `SetCursorPos()` — real via SDL3
- `GetDoubleClickTime()` — real (returns 500ms)
- `GetCursorPos()` / `ScreenToClient()` — real via SDL3
- `GetCurrentThreadId()` / `GetCurrentProcessId()` — real via POSIX

### Category 2: GDI Text Rendering — MUST IMPLEMENT (11 functions)

These are the **critical path** — the game cannot render text without them.

| Function | Implementation Strategy |
|----------|------------------------|
| `CreateDIBSection()` | Allocate real pixel buffer (calloc) from BITMAPINFO dimensions. Return buffer as HBITMAP handle. |
| `CreateCompatibleDC()` | Create a lightweight struct holding font/bitmap state. Return as HDC. |
| `SelectObject()` | Store bitmap/font references in the DC struct. |
| `DeleteDC()` | Free the DC struct. |
| `DeleteObject()` | Free the associated resource (bitmap buffer or font data). |
| `TextOut()` | **Implement bitmap font rasterizer** — blit pre-loaded glyph bitmaps from `BITMAP_FONT` texture into the font buffer. The game already loads `FontInput.tga` and `FontTest.tga` as bitmap fonts. |
| `SetTextColor()` | Store color in DC struct for use by TextOut. |
| `SetBkColor()` | Store background color in DC struct. |
| `SetBkMode()` | Store transparent/opaque mode. |
| `GetTextExtentPoint32()` | **Implement real glyph measurement** — use the bitmap font glyph widths from the loaded font texture, not fixed 8px/char. |
| `CreateFont()` | Create font descriptor struct with size/weight/family. Return as HFONT handle. |

### Category 3: Window/Edit Control — Replace or Verify Dead (15 functions)

| Function | Strategy |
|----------|----------|
| `CreateWindowW()` | SDL3 text input uses `SDL_EVENT_TEXT_INPUT` not Win32 edit controls. Verify all callers are guarded by nullptr checks on `m_hEditWnd`. If so, return nullptr is correct (not a stub — intentional "no Win32 edit control"). |
| `DestroyWindow()` | Same — verify dead on SDL3 path. |
| `SetFocus()` / `GetFocus()` | Map to SDL3 focus management or verify dead. |
| `SendMessage()` / `SendMessageW()` | Map EM_* messages to SDL3 equivalents or verify dead. |
| `PostMessage()` / `PostMessageW()` | Same. |
| `SetWindowTextW()` / `GetWindowText()` | Same. |
| `GetWindowRect()` | Return actual window rect via `SDL_GetWindowPosition`/`SDL_GetWindowSize`. |
| `SetWindowPos()` | Map to `SDL_SetWindowPosition`/`SDL_SetWindowSize`. |
| `SetWindowLongPtrW()` / `GetWindowLongPtrW()` | Verify dead or map to SDL3 equivalent. |
| `CallWindowProcW()` | Verify dead (Win32 subclassing). |
| `GetCaretPos()` | Map to text cursor position from SDL3 text input. |

### Category 4: Clipboard — MUST IMPLEMENT (5 functions)

| Function | Implementation |
|----------|---------------|
| `OpenClipboard()` | Return TRUE (SDL3 doesn't need explicit open). |
| `GetClipboardData()` | Call `SDL_GetClipboardText()`, convert to wchar_t, return. |
| `GlobalLock()` | Return the data pointer directly. |
| `GlobalUnlock()` | No-op (SDL_free handles cleanup). |
| `CloseClipboard()` | Free the SDL clipboard text. |

### Category 5: IME — Verify SDL3 Handles (9 functions)

SDL3 handles IME natively via `SDL_EVENT_TEXT_INPUT` and `SDL_EVENT_TEXT_EDITING`. These functions are called but the results are unused because the SDL3 text input path bypasses Win32 IME. Verify each caller and either:
- Delete the call site if it's dead code on SDL3
- Keep as intentional no-op with comment explaining SDL3 handles this

### Category 6: OpenGL/WGL — MUST DELETE (10 functions)

SDL3 GPU replaces all OpenGL context management. These are dead code:
`wglCreateContext`, `wglMakeCurrent`, `wglDeleteContext`, `wglGetProcAddress` (2 overloads), `wglGetCurrentDC`, `SwapBuffers`, `ChoosePixelFormat`, `SetPixelFormat`, `DescribePixelFormat`, `gluPerspective`, `gluOrtho2D`, `gluLookAt`, `GetDeviceCaps`

Delete the stubs. If any caller exists, it should be behind `#ifdef _WIN32` or already migrated.

### Category 7: Window Management — Verify Dead or Implement (20+ functions)

SDL3 window management replaces all of these. Verify each is either:
- Already dead (SDL3 path doesn't use it)
- Or needs SDL3 mapping

Includes: `RegisterClass`, `CreateWindowEx`, `AdjustWindowRect`, `ShowWindow`, `UpdateWindow`, `FindWindow`, `SetCapture`, `ReleaseCapture`, `GetStockObject`, `GetSystemMetrics`, `SetForegroundWindow`, `SystemParametersInfo`, `EnumDisplaySettings`, `ChangeDisplaySettings`, `LoadIcon`, `LoadCursor`, `DefWindowProc`, `GetActiveWindow`, `IsWindowVisible`, `EnumChildWindows`, `DrawMenuBar`, `DeleteMenu`, `RemoveMenu`, `GetSystemMenu`, `PostQuitMessage`, `timeBeginPeriod`, `timeEndPeriod`, `SetTimer`, `KillTimer`, `GetScrollPos`, `SetScrollPos`

### Category 8: Console — Already Implemented

`mu_console_init`, `mu_set_console_title`, `mu_set_console_text_color`, `mu_get_console_size`, `mu_console_clear`, `mu_console_set_cursor_position` — these are real ANSI implementations. Verify only.

### Category 9: File/Registry/System — Verify Dead (15+ functions)

Registry: `RegOpenKeyEx`, `RegQueryValueEx`, `RegSetValueEx`, `RegCreateKeyEx`, `RegCloseKey`, `RegDeleteKey`, `RegDeleteValue` — game uses `config.ini` not registry. Verify dead and delete.

File: `CreateFile`, `ReadFile`, `GetFileSize`, `CloseHandle` — game uses `fopen`/`std::ifstream`. Verify dead and delete.

Version: `GetFileVersionInfoSize`, `GetFileVersionInfo`, `VerQueryValue` — verify dead and delete.

Other: `GetCommandLineW`, `GetModuleFileName`, `ShellExecute`, `BeginPaint`, `EndPaint`, `PeekMessage`, `TranslateMessage`, `DispatchMessage` — SDL3 event loop replaces message pump. Verify dead and delete.

Debug: `OutputDebugString`, `OutputDebugStringA`, `IsBadReadPtr`, `IsBadWritePtr`, `GetLastError`, `SetLastError`, `AllocConsole`, `FreeConsole`, `GetStdHandle`, `SetConsoleMode` — implement or verify dead.

---

## Tasks / Subtasks

- [ ] Task 1: Audit all 183 functions — classify each as IMPLEMENT/DELETE/ALREADY_REAL (AC: 7)
  - [ ] 1.1: Run the game, log every stub function that gets called with a trace macro
  - [ ] 1.2: For each called stub, document the call chain
  - [ ] 1.3: For each uncalled stub, verify it's truly dead (grep + call graph)
- [ ] Task 2: Implement GDI text rendering system (AC: 2, 3, 4)
  - [ ] 2.1: Implement `CreateDIBSection` — allocate pixel buffer from BITMAPINFO
  - [ ] 2.2: Implement `CreateCompatibleDC` — create lightweight DC struct
  - [ ] 2.3: Implement `SelectObject` / `DeleteDC` / `DeleteObject`
  - [ ] 2.4: Implement `TextOut` — bitmap font rasterizer using loaded glyph textures
  - [ ] 2.5: Implement `GetTextExtentPoint32` — real glyph measurement from font data
  - [ ] 2.6: Implement `CreateFont` — font descriptor creation
  - [ ] 2.7: Implement `SetTextColor` / `SetBkColor` / `SetBkMode`
  - [ ] 2.8: Write Catch2 tests for text measurement and rasterization
- [ ] Task 3: Implement clipboard via SDL3 (AC: 5)
  - [ ] 3.1: Replace `OpenClipboard`/`GetClipboardData`/`GlobalLock`/`GlobalUnlock`/`CloseClipboard` with `SDL_GetClipboardText()`
  - [ ] 3.2: Write Catch2 tests for clipboard
- [ ] Task 4: Delete dead OpenGL/WGL stubs (AC: 7)
  - [ ] 4.1: Verify no callers exist outside `#ifdef _WIN32`
  - [ ] 4.2: Delete all 14 WGL/GLU stubs
- [ ] Task 5: Delete dead registry/file/system stubs (AC: 7)
  - [ ] 5.1: Verify no callers
  - [ ] 5.2: Delete all registry stubs (7 functions)
  - [ ] 5.3: Delete all dead file I/O stubs (4 functions)
  - [ ] 5.4: Delete all dead version info stubs (3 functions)
  - [ ] 5.5: Delete dead message pump stubs (3 functions)
- [ ] Task 6: Resolve window/edit control stubs (AC: 7)
  - [ ] 6.1: For each window management stub, verify dead or implement via SDL3
  - [ ] 6.2: For edit control stubs (SendMessage EM_*), verify SDL3 text input path handles it
- [ ] Task 7: Resolve IME stubs (AC: 7)
  - [ ] 7.1: Verify SDL3 text input handles all IME cases
  - [ ] 7.2: Delete dead IME calls or document why no-op is correct (SDL3 handles it)
- [ ] Task 8: WebzenScene integration test (AC: 6)
  - [ ] 8.1: Run game, verify WebzenScene completes (fonts load, title screen renders, data loads)
  - [ ] 8.2: Verify scene transitions to LOG_IN_SCENE
  - [ ] 8.3: Verify text renders in login UI
- [ ] Task 9: Quality gate (AC: STD-13)
  - [ ] 9.1: `./ctl check` passes
  - [ ] 9.2: All existing tests pass

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 | Text rendering, measurement, clipboard | Font buffer allocation, glyph metrics, text rasterization, clipboard read |
| Integration | Manual + visual | WebzenScene completes | Title screen renders, progress bar visible, scene transitions |

---

## Dev Notes

### Critical Path

The game blocks at `WebzenScene → OpenFont() → CUIRenderTextOriginal::Create()`. Fix the GDI text rendering category (Task 2) first — everything else depends on fonts loading.

### Text Rendering Architecture

The original Win32 text system works like this:
1. `CreateDIBSection` allocates a pixel buffer (WindowWidth × WindowHeight × 24bpp)
2. `CreateCompatibleDC` creates a Windows device context
3. `SelectObject` binds the bitmap and font to the DC
4. `TextOut` renders text via GDI into the pixel buffer
5. `WriteText` / `UploadText` uploads the buffer as an OpenGL texture

On SDL3, replace steps 1-4 with a software bitmap font rasterizer that reads from the already-loaded `BITMAP_FONT` texture (`FontInput.tga`). The buffer → texture upload (step 5) already works via `MuRenderer`.

### The Font Textures

The game loads these bitmap font textures in `OpenFont()`:
- `Interface/FontInput.tga` → `BITMAP_FONT` — main game font (glyph atlas)
- `Interface/FontTest.tga` → `BITMAP_FONT + 1` — alternate font
- `Interface/Hit.tga` → `BITMAP_FONT_HIT` — damage numbers

These are pre-rendered glyph atlases. `TextOut()` should blit from these instead of using Win32 GDI text rendering.

### File List

| Action | File |
|--------|------|
| MODIFY | `MuMain/src/source/Platform/PlatformCompat.h` |
| CREATE | `MuMain/src/source/Platform/CrossPlatformGDI.cpp` (real implementations for GDI text, clipboard) |
| CREATE | `MuMain/src/source/Platform/CrossPlatformGDI.h` (declarations) |
| CREATE | `MuMain/tests/platform/test_platformcompat_no_stubs_7_9_5.cpp` |
| MODIFY | `MuMain/src/source/ThirdParty/UIControls.cpp` (if text rendering path needs adjustment) |

### References

- [Source: MuMain/src/source/Platform/PlatformCompat.h — 2771 lines, 183 inline functions]
- [Source: MuMain/src/source/ThirdParty/UIControls.cpp — CUIRenderTextOriginal::Create/RenderText]
- [Source: MuMain/src/source/Data/ZzzOpenData.cpp — OpenFont()]
- [Source: MuMain/src/source/Scenes/WebzenScene.cpp — WebzenScene loading sequence]
- [Source: docs/development-standards.md §1 — Banned Win32 API table]
- [Source: _bmad-output/project-context.md — Critical Implementation Rules]

---

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List

# Story 7.9.5: Eliminate All Cross-Platform Stubs — Real SDL3 Implementations

Status: ready-for-dev (rescoped 2026-04-25 — see Rescope Note below)

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.9 - macOS Game Loop & Win32 Render Path Migration |
| Story ID | 7.9.5 |
| Story Points | 8 (rescoped from 21 — most original scope absorbed by 7-9-8 + 7-9-10) |
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

## Rescope Note (2026-04-25)

The original premise — *"the game compiles on all platforms but does not run"* — is obsolete. The game has been running end-to-end on macOS since 2026-04-11 and on Linux since the SDL3 input/render thread closed. The "must-implement" categories (GDI text rendering, clipboard, font system) were absorbed by sibling stories that took priority once the game became playable:

| Original AC | Resolved By | Evidence |
|---|---|---|
| AC-2 (`OpenFont()` succeeds) | **7-9-8** *adopt-sdl-ttf-font-rendering* (done) | `TTF_CreateGPUTextEngine` in `MuRendererSDLGpu`; `CUIRenderTextSDLTtf` replaces `CUIRenderTextOriginal` on the SDL3 path |
| AC-3 (`GetTextExtentPoint32()` accurate) | **7-9-8 + 7-9-10** (done) | Text measurement flows through `TTF_GetStringSize` inside `CUIRenderTextSDLTtf::lpTextSize` |
| AC-4 (`TextOut()` rasterizes) | **7-9-10** *sdl-ttf-text-input-rendering* (done) | `dc085d27` deleted `WriteText`/`UploadText`/`InputBoxTexture` — net −367 in `UIControls.cpp` |
| AC-5 (Clipboard) | **already implemented** | `SDL_GetClipboardText()` wired at `Platform/PlatformCompat.h:1010` |
| AC-6 (`WebzenScene` completes) | satisfied | Game runs end-to-end on macOS (2026-04-11) and Linux; downstream stories 7-9-7 → 7-9-13 all shipped against a running game |
| AC-7 (audit 183 functions) | replaced by new AC-1 | Tighter measurement: 40 `return nullptr/0/FALSE` lines in `PlatformCompat.h`, not 183 functions; Categories 1, 2, 4, 8 of the original Stub Inventory are now resolved |

What remains is **dead-code removal**, not implementation. The story now closes when the SDL3 path stops referencing Win32-shaped stubs at all and `PlatformCompat.h` shrinks.

---

## Functional Acceptance Criteria

- [ ] **AC-1: Stub classification.** Every remaining `return nullptr`, `return NULL`, `return FALSE`, or `return 0;` line in `Platform/PlatformCompat.h` (40 lines as of 2026-04-25) is classified inline by a comment of the form `// CLASSIFIED: <real|dead-win32|deleted-with-callers> — <one-line reason>`. No unclassified stubs may remain.
- [ ] **AC-2: GDI text-rendering removal.** `CreateDIBSection`, `CreateCompatibleDC`, `SelectObject`, `DeleteDC`, `DeleteObject`, `TextOut`, `SetTextColor`, `SetBkColor`, `SetBkMode`, `GetTextExtentPoint32`, `CreateFont` are deleted from `PlatformCompat.h` (and their implementation files). `grep -rn "<func>" src/source/` returns zero non-`#ifdef _WIN32` callers before deletion. `CUIRenderTextOriginal` either deleted entirely or its remaining call sites confirmed Win32-only.
- [ ] **AC-3: OpenGL/WGL stub removal.** `wglCreateContext`, `wglMakeCurrent`, `wglDeleteContext`, `wglGetProcAddress` (both overloads), `wglGetCurrentDC`, `SwapBuffers`, `ChoosePixelFormat`, `SetPixelFormat`, `DescribePixelFormat`, `gluPerspective`, `gluOrtho2D`, `gluLookAt`, `GetDeviceCaps` are deleted. SDL3 GPU owns context management (already enforced by 7-9-6).
- [ ] **AC-4: Registry / version-info / file-handle stub removal.** `RegOpenKeyEx`, `RegQueryValueEx`, `RegSetValueEx`, `RegCreateKeyEx`, `RegCloseKey`, `RegDeleteKey`, `RegDeleteValue`, `CreateFile`, `ReadFile`, `GetFileSize`, `CloseHandle`, `GetFileVersionInfoSize`, `GetFileVersionInfo`, `VerQueryValue` are deleted. The game uses `config.ini` + `std::filesystem` + `std::ifstream` exclusively.
- [ ] **AC-5: Win32 message-pump / window-class stub removal.** `RegisterClass`, `CreateWindowEx`, `AdjustWindowRect`, `ShowWindow`, `UpdateWindow`, `FindWindow`, `LoadIcon`, `LoadCursor`, `DefWindowProc`, `BeginPaint`, `EndPaint`, `PeekMessage`, `TranslateMessage`, `DispatchMessage`, `PostQuitMessage`, `timeBeginPeriod`, `timeEndPeriod`, `SetTimer`, `KillTimer`, `GetCommandLineW`, `GetModuleFileName`, `ShellExecute` are deleted. SDL3 event loop replaces the message pump (already enforced by 7-9-1, 7-9-3).
- [ ] **AC-6: Edit-control / IME stub resolution.** Each `SendMessage`/`PostMessage`/`SetWindowText`/`GetWindowText`/`SetFocus`/`GetFocus`/`SetCaretPos`/`GetCaretPos`/IME function is either deleted at the call site or kept as a documented intentional no-op with a comment explaining why SDL3 owns the behavior (`SDL_EVENT_TEXT_INPUT` / `SDL_EVENT_TEXT_EDITING` for text entry; `SDL_StartTextInput` / `SDL_StopTextInput` for IME activation).
- [ ] **AC-7: Smoke test + measurement.** `./ctl check` passes. Game launches on macOS, Linux, Windows; reaches login screen; logs in; renders chat. Final stub count documented in story Closing Notes: `grep -cE "return (nullptr|NULL|FALSE|0);" src/source/Platform/PlatformCompat.h` recorded as a hard lower bound — must be lower than 40 and every survivor must carry an AC-1 classification comment.

### Out of scope (split into sibling stories — see Splits section below)

- Implementing new functionality — this is a *deletion* story. Sibling stories handle each cross-platform implementation that has live callers.
- Touching `CUIRenderTextOriginal` callers on Windows (Win32 path is being deleted entirely by 7-9-14).

---

## Splits (created 2026-04-25 after full per-line audit)

The original AC-1 ("classify every line") was performed inline. The audit surfaced 5 distinct categories of work; this story now scopes only Category B (confirmed-dead deletions), and the rest are tracked as siblings:

| Sibling | Title | Pts | Scope |
|---|---|---|---|
| **7-9-14** | [Delete Vestigial Win32 Platform Backend](../7-9-14-delete-win32-backend/story.md) | 5 | Delete `Platform/win32/*` (5 files, 241 LOC), `Resources/Windows/resource.rc`, `regkey.h`, MuPlatform Win32 path. Verify `MuPlatform.cpp` is SDL3-unconditional on Windows. |
| **7-9-15** | [Cross-Platform Fatal-Exit Helper](../7-9-15-cross-platform-fatal-exit/story.md) | 8 | Replace 60+ `SendMessage(g_hWnd, WM_DESTROY)` and `::PostMessage(g_hWnd, WM_CLOSE/WM_DESTROY)` cross-platform call sites with `mu::platform::FatalExit(reason)`. Resolves Category C silent-failure on every error path. |
| **7-9-16** | [Cross-Platform IME via SDL3](../7-9-16-cross-platform-ime/story.md) | 5 | Replace `ImmGetContext`/`ImmGetCompositionWindow`/etc. (12 call sites) with `SDL_StartTextInput` + `SDL_SetTextInputArea` + `SDL_EVENT_TEXT_EDITING`. Implements the TODO at `UIControls.cpp:3657`. |
| **7-9-17** | [Cross-Platform Timer](../7-9-17-cross-platform-timer/story.md) | 3 | Replace 4 `SetTimer(g_hWnd, ...)` / `KillTimer(g_hWnd, ...)` call sites (chat reconnect, slide-help tooltip, buff expiration) with extended `CTimer2` callback support. |
| **7-9-18** | [Cross-Platform Point-Fixes](../7-9-18-cross-platform-point-fixes/story.md) | 2 | `GetCurrentDirectory` → `std::filesystem::current_path()`; `ShellExecute` → `SDL_OpenURL`; `IsBadReadPtr` → plain nullptr check. |
| **7-9-19** | [Strip All Conditional-Compilation Axes](../7-9-19-strip-conditional-compilation/story.md) | 5 | Final unification — strip `#ifdef _WIN32` and `#ifdef MU_ENABLE_SDL3` axes across 30+ files. Single unconditional path. Runs after 7-9-5/14/15/16/17/18 land. |

**Total combined:** 7 stories (7-9-5 + 6 siblings), ~31 points.

**Sequencing:** 7-9-5 (this story, deletion-only) can run first or in parallel with 7-9-15/16/17/18. 7-9-14 must run *after* 7-9-15/16/17/18 land (so Category C call sites are gone before the Win32 backend is deleted). 7-9-19 must run *last* (it strips the scaffolding that the earlier stories need to coexist).

**This story (7-9-5) is NOW the Category B mechanical deletion only:** ~25 confirmed-zero-caller stub declarations dropped from `PlatformCompat.h`. No silent-failure risk; siblings handle the dangerous cases.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (naming, logging, PascalCase, `m_` prefix, `#pragma once`)
- [ ] **AC-STD-2:** Testing Requirements — smoke test on macOS, Linux, Windows confirms game launches → login → chat after stub deletion. No new Catch2 unit tests required (this is a deletion story; covered by existing render/clipboard tests landed under 7-9-8 + 7-9-10).
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

- [ ] Task 1: Inventory remaining stubs (new AC-1)
  - [ ] 1.1: Re-run `grep -nE "return (nullptr|NULL|FALSE|0);" src/source/Platform/PlatformCompat.h` and capture the current line count + line numbers (baseline 40 as of 2026-04-25)
  - [ ] 1.2: For each line, walk the function — `grep -rn "<function_name>" src/source/` to map active call sites
  - [ ] 1.3: Classify each as `real` (returns sentinel for documented condition), `dead-win32` (only reachable behind `#ifdef _WIN32`), or `deleted-with-callers` (delete the call site too)
- [x] ~~Task 2: Implement GDI text rendering system~~ — **superseded by 7-9-8 + 7-9-10** (SDL_ttf migration; GDI declarations now eligible for deletion in new AC-2)
- [x] ~~Task 3: Implement clipboard via SDL3~~ — **already implemented** at `PlatformCompat.h:1010` (verify-only under new AC-1)
- [ ] Task 4: Delete dead OpenGL/WGL stubs (new AC-3)
  - [ ] 4.1: `grep -rn "wglCreateContext\|wglMakeCurrent\|wglDeleteContext\|SwapBuffers\|ChoosePixelFormat\|gluPerspective" src/source/` returns zero non-`#ifdef _WIN32` callers
  - [ ] 4.2: Delete declarations + implementations for all 13 WGL/GLU stubs
- [ ] Task 5: Delete dead registry/file/system stubs (new AC-4)
  - [ ] 5.1: Verify no callers (registry: 7 fns; file I/O: 4 fns; version info: 3 fns)
  - [ ] 5.2: Delete declarations + implementations
- [ ] Task 6: Delete dead Win32 message-pump / window-class stubs (new AC-5)
  - [ ] 6.1: Verify no callers (`PeekMessage`, `DispatchMessage`, `RegisterClass`, `DefWindowProc`, etc.)
  - [ ] 6.2: Delete declarations + implementations
- [ ] Task 7: Resolve edit-control / IME stubs (new AC-6)
  - [ ] 7.1: For each `SendMessage`/`PostMessage`/`SetFocus`/IME function, verify SDL3 path covers it
  - [ ] 7.2: Delete dead call sites OR add intentional-no-op comment with SDL3 reason
- [x] ~~Task 8: WebzenScene integration test~~ — **satisfied by ongoing playable state** (verified 2026-04-11; downstream stories 7-9-7..7-9-13 all shipped against running game)
- [ ] Task 9: Inline classification comments for surviving stubs (new AC-1)
  - [ ] 9.1: Annotate every remaining `return nullptr/0/FALSE` line in `PlatformCompat.h` with a `// CLASSIFIED:` comment
  - [ ] 9.2: Final stub-line count recorded in story Closing Notes (must be < 40)
- [ ] Task 10: Quality gate + smoke test (AC: STD-13, new AC-7)
  - [ ] 10.1: `./ctl check` passes
  - [ ] 10.2: Game launches, reaches login, renders chat on macOS + Linux + Windows

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

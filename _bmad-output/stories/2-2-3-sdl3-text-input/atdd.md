# ATDD Checklist — Story 2.2.3: SDL3 Text Input Migration

**Story Key:** 2-2-3-sdl3-text-input
**Story Type:** infrastructure
**Flow Code:** VS1-SDL-INPUT-TEXT
**Date Generated:** 2026-03-06
**Phase:** RED (all test files created; implementation pending)

---

## AC-to-Test Mapping

| AC | Description (summary) | Test File | Test Name | Status |
|----|------------------------|-----------|-----------|--------|
| AC-1 | SDL_EVENT_TEXT_INPUT replaces WM_CHAR | `test_platform_text_input.cpp` | `AC-1 [VS1-SDL-INPUT-TEXT]: SDL text input globals exist and can be set` | RED |
| AC-1 | Concatenation of multiple events per frame | `test_platform_text_input.cpp` | `AC-1 [VS1-SDL-INPUT-TEXT]: SDL text input concatenation — multiple events per frame` | RED |
| AC-2 | Typed chars appear in text buffer (ASCII) | `test_platform_text_input.cpp` | `AC-2 [VS1-SDL-INPUT-TEXT]: SDL text buffer append — ASCII character added to buffer` | RED |
| AC-2 | Max length enforced — no overflow | `test_platform_text_input.cpp` | `AC-2 [VS1-SDL-INPUT-TEXT]: SDL text buffer max length enforcement — no overflow` | RED |
| AC-2 | NUMBERONLY filters non-digits | `test_platform_text_input.cpp` | `AC-2 [VS1-SDL-INPUT-TEXT]: NUMBERONLY option filters non-digit characters` | RED |
| AC-3 | ASCII decodes correctly | `test_platform_text_input.cpp` | `AC-3 [VS1-SDL-INPUT-TEXT]: MuSdlUtf8NextChar decodes ASCII character correctly` | RED |
| AC-3 | 2-byte UTF-8 (é, ü, ñ) decodes correctly | `test_platform_text_input.cpp` | `AC-3 [VS1-SDL-INPUT-TEXT]: MuSdlUtf8NextChar decodes 2-byte UTF-8 sequence correctly` | RED |
| AC-3 | 3-byte UTF-8 (€, あ) decodes correctly | `test_platform_text_input.cpp` | `AC-3 [VS1-SDL-INPUT-TEXT]: MuSdlUtf8NextChar decodes 3-byte UTF-8 sequence correctly` | RED |
| AC-3 | Malformed UTF-8 returns null/safe value | `test_platform_text_input.cpp` | `AC-3 [VS1-SDL-INPUT-TEXT]: MuSdlUtf8NextChar handles malformed UTF-8 sequences` | RED |
| AC-4 | Backspace removes last char | `test_platform_text_input.cpp` | `AC-4 [VS1-SDL-INPUT-TEXT]: Backspace removes last character from SDL text buffer` | RED |
| AC-STD-11 | Flow code in SDLEventLoop.cpp | `test_ac_std11_flow_code_2_2_3.cmake` | `2.2.3-AC-STD-11:flow-code-text-input` | RED |
| AC-STD-3 | No raw IME calls outside Platform/ | `test_ac_std3_no_raw_imm.cmake` | `2.2.3-AC-STD-3:no-raw-imm-apis` | RED |

---

## Implementation Checklist

### PCC Compliance

- [ ] No prohibited libraries used (raw `new`/`delete`, `NULL`, `wprintf`, `#ifdef _WIN32` in game logic)
- [ ] Testing framework: Catch2 v3.7.1 via FetchContent — no other test framework introduced
- [ ] All new code uses `#pragma once` (no `#ifndef` guards)
- [ ] All new code uses `nullptr` (not `NULL`)
- [ ] All new code uses `std::unique_ptr` for heap allocation (no raw `new`/`delete`)
- [ ] No `#ifdef _WIN32` in game logic files — only in `Platform/` abstraction layer and `ThirdParty/` (exception)
- [ ] Flow code `VS1-SDL-INPUT-TEXT` appears in `SDLEventLoop.cpp`, test names, and story artifacts
- [ ] All error logging via `g_ErrorReport.Write()` with `MU_ERR_TEXT_*` prefix and flow code

### AC-1: SDL_EVENT_TEXT_INPUT Handler in SDLEventLoop

- [ ] `g_szSDLTextInput[32]` global defined in `SDLKeyboardState.cpp` (inside `#ifdef MU_ENABLE_SDL3`)
- [ ] `g_bSDLTextInputReady` global defined in `SDLKeyboardState.cpp` (inside `#ifdef MU_ENABLE_SDL3`)
- [ ] `extern char g_szSDLTextInput[32]` declared in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [ ] `extern bool g_bSDLTextInputReady` declared in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [ ] `SDL_EVENT_TEXT_INPUT` case added to `switch (event.type)` in `SDLEventLoop::PollEvents()`
- [ ] Per-frame reset of `g_szSDLTextInput[0] = '\0'` and `g_bSDLTextInputReady = false` at start of `PollEvents()`
- [ ] Concatenation guard: `if (existing + incoming < sizeof(g_szSDLTextInput))` prevents overflow
- [ ] Flow code `VS1-SDL-INPUT-TEXT` present as comment in `SDLEventLoop.cpp` SDL_EVENT_TEXT_INPUT handler

### AC-2: CUITextInputBox Text Buffer (m_szSDLText)

- [ ] `wchar_t m_szSDLText[MAX_CHAT_SIZE]` member added to `CUITextInputBox` in `UIControls.h`
- [ ] `int m_iSDLTextLen` member added to `CUITextInputBox` in `UIControls.h`
- [ ] `int m_iSDLMaxLength` member added to `CUITextInputBox` in `UIControls.h`
- [ ] `bool m_bBackspaceHeld` member added to `CUITextInputBox` in `UIControls.h`
- [ ] `CUITextInputBox::DoAction()` reads `g_szSDLTextInput` when `g_bSDLTextInputReady` is true
- [ ] Backspace handled in `DoAction()` via `GetAsyncKeyState(VK_BACK)` with `m_bBackspaceHeld` edge detection
- [ ] `CUITextInputBox::GetText()` uses `m_szSDLText` on non-Windows (`#else` branch)
- [ ] `CUITextInputBox::SetText()` uses `m_szSDLText` on non-Windows (`#else` branch)
- [ ] `CUITextInputBox::SetTextLimit()` stores limit in `m_iSDLMaxLength` on all paths

### AC-3: MuSdlUtf8NextChar UTF-8 Decoder

- [ ] `MuSdlUtf8NextChar(const char*& src)` inline function added to `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [ ] ASCII decode correct (0x00-0x7F range, advances src by 1)
- [ ] 2-byte decode correct (0xC0-0xDF lead, advances src by 2)
- [ ] 3-byte decode correct (0xE0-0xEF lead, advances src by 3)
- [ ] Malformed sequences return `L'\0'` and advance src (no infinite loop)
- [ ] Surrogate range (0xD800-0xDFFF) and >0xFFFF codepoints return `L'?'`
- [ ] Flow code `VS1-SDL-INPUT-TEXT` comment present in `MuSdlUtf8NextChar` declaration

### AC-4: Backspace, Delete, Home, End, Arrow Keys

- [ ] Backspace handled via `GetAsyncKeyState(VK_BACK)` in `DoAction()` — removes last char from `m_szSDLText`
- [ ] `m_bBackspaceHeld` edge detection prevents auto-repeat consuming multiple chars per hold
- [ ] Delete, Home, End, arrows handled via existing `g_sdl3KeyboardState` shim from story 2.2.1 — no new code needed (verify)

### AC-5: SDL_StartTextInput / SDL_StopTextInput Lifecycle

- [ ] `MuStartTextInput()` declared in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [ ] `MuStopTextInput()` declared in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [ ] `MuStartTextInput()` implemented in `SDLKeyboardState.cpp` — calls `SDL_StartTextInput(pWnd)` with SDL_Window* from `mu::MuPlatform::GetNativeWindow()`
- [ ] `MuStopTextInput()` implemented in `SDLKeyboardState.cpp` — calls `SDL_StopTextInput(pWnd)`
- [ ] `MuStartTextInput()` logs start via `g_ErrorReport.Write(L"[VS1-SDL-INPUT-TEXT] SDL_StartTextInput activated\r\n")`
- [ ] `MuStartTextInput()` logs failure via `g_ErrorReport.Write(L"MU_ERR_TEXT_START_FAILED [VS1-SDL-INPUT-TEXT]: no SDL window available\r\n")` when window is null
- [ ] `CUITextInputBox::GiveFocus()` calls `MuStartTextInput()` on SDL3 path (`#elif defined(MU_ENABLE_SDL3)`)
- [ ] `CUITextInputBox::SetState(UISTATE_HIDE)` calls `MuStopTextInput()` on SDL3 path
- [ ] `mu::MuPlatform::GetNativeWindow()` static method exists and returns `SDL_Window*` via `SDLWindow::GetNativeHandle()`

### AC-STD-2: PlatformCompat.h Stubs (Win32 GDI / IME / Clipboard / Window)

- [ ] `GetTextExtentPoint32` stub added to `PlatformCompat.h` (non-Windows, outside `MU_ENABLE_SDL3` guard)
- [ ] `lstrlen` shim added to `PlatformCompat.h` (as alias to `wcslen`)
- [ ] IME type aliases (`HIMC`, `IME_CMODE_ALPHANUMERIC`, etc.) added to `PlatformCompat.h`
- [ ] `ImmGetContext`, `ImmGetConversionStatus`, `ImmSetConversionStatus`, `ImmReleaseContext` no-op stubs added
- [ ] `WM_IME_CONTROL`, `IMC_SETCOMPOSITIONWINDOW`, `SendMessage`, `PostMessage`, `EM_SETSEL` stubs added
- [ ] `SetFocus`, `GetFocus` stubs returning sentinel non-null HWND added
- [ ] `SW_HIDE`, `SW_SHOW`, `ShowWindow` stub added
- [ ] `WNDPROC`, `GWLP_WNDPROC`, `GWLP_USERDATA`, `LONG_PTR`, `SetWindowLongPtrW`, `GetWindowLongPtrW`, `CallWindowProcW` stubs added
- [ ] `WS_CHILD`, `WS_VISIBLE`, `WS_VSCROLL`, `ES_*`, `HMENU`, `CreateWindowW` stub (returns nullptr) added
- [ ] GDI stubs: `HBITMAP`, `HGDIOBJ`, `BITMAPINFOHEADER`, `BITMAPINFO`, `RGBQUAD`, `DeleteDC`, `DeleteObject`, `CreateCompatibleDC`, `CreateDIBSection`, `SelectObject` added
- [ ] Clipboard stubs: `HGLOBAL`, `CF_TEXT`, `OpenClipboard`, `GetClipboardData`, `GlobalLock`, `GlobalUnlock`, `CloseClipboard` added
- [ ] `WM_CHAR`, `WM_SYSKEYDOWN`, `WM_IME_COMPOSITION`, `WM_IME_STARTCOMPOSITION`, `WM_IME_ENDCOMPOSITION`, `WM_IME_NOTIFY` constants added
- [ ] `COMPOSITIONFORM` struct and `CFS_POINT` added to `PlatformCompat.h`
- [ ] `UINT` typedef verified in `PlatformTypes.h` (add `using UINT = unsigned int;` if missing)

### AC-STD-2 (clipboard SDL3 path)

- [ ] `MuClipboardIsNumericOnly()` inline function added to `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [ ] `UIControls.cpp` `ClipboardCheck` call site in `EditWndProc` wrapped with `#ifdef _WIN32` / `#elif defined(MU_ENABLE_SDL3)` guard

### AC-STD-3: No Raw IME APIs Outside Platform/ and ThirdParty/

- [ ] `ImmGetContext`, `ImmSetConversionStatus`, `ImmReleaseContext` only in `Platform/` (as stubs) and `ThirdParty/` (behind `#ifdef _WIN32`)
- [ ] `ZzzInterface.cpp:263` `SendMessage(..., WM_IME_CONTROL, ...)` compiles via no-op stub — no source change needed (verify)
- [ ] CMake test `2.2.3-AC-STD-3:no-raw-imm-apis` passes

### AC-STD-3 HaveFocus and Focus Tracking

- [ ] `bool m_bSDLHasFocus` member added to `CUITextInputBox` in `UIControls.h`
- [ ] `CUITextInputBox::HaveFocus()` returns `m_bSDLHasFocus ? TRUE : FALSE` on non-Windows
- [ ] `m_bSDLHasFocus = true` set in `GiveFocus()` SDL3 branch
- [ ] `m_bSDLHasFocus = false` set in `SetState(UISTATE_HIDE)` SDL3 branch
- [ ] `SetIMEPosition()` body wrapped in `#ifdef _WIN32` guard (SDL3: IME positioning handled by SDL3 internally)

### AC-STD-11: Flow Code

- [ ] Flow code `VS1-SDL-INPUT-TEXT` present in `SDLEventLoop.cpp`
- [ ] Flow code `VS1-SDL-INPUT-TEXT` present in `SDLKeyboardState.cpp` (`g_szSDLTextInput` comment)
- [ ] Flow code `VS1-SDL-INPUT-TEXT` present in `PlatformCompat.h` (`MuSdlUtf8NextChar` comment)
- [ ] Flow code `VS1-SDL-INPUT-TEXT` present in all TEST_CASE names in `test_platform_text_input.cpp`
- [ ] Flow code `VS1-SDL-INPUT-TEXT` present in `atdd.md` (this file)
- [ ] CMake test `2.2.3-AC-STD-11:flow-code-text-input` passes

### AC-STD-13: Quality Gate

- [ ] `./ctl check` passes on macOS (clang-format + cppcheck)
- [ ] MinGW CI build passes — all SDL3 code inside `#ifdef MU_ENABLE_SDL3`; all Win32 stubs inside `#else // !_WIN32`
- [ ] No cppcheck warnings in new Platform/ files
- [ ] clang-format clean (Allman braces, 4-space indent, 120-col limit)

### Test Infrastructure

- [ ] `test_platform_text_input.cpp` added to `MuTests` target in `MuMain/tests/CMakeLists.txt`
- [ ] `test_ac_std11_flow_code_2_2_3.cmake` registered as `2.2.3-AC-STD-11:flow-code-text-input` CTest
- [ ] `test_ac_std3_no_raw_imm.cmake` registered as `2.2.3-AC-STD-3:no-raw-imm-apis` CTest
- [ ] All Catch2 tests in `test_platform_text_input.cpp` compile with `BUILD_TESTING=ON`
- [ ] All Catch2 tests compile and are skipped (no code) when `MU_ENABLE_SDL3=OFF` (CI Strategy B)

---

## Test Files Created (RED Phase)

| File | Type | Phase |
|------|------|-------|
| `MuMain/tests/platform/test_platform_text_input.cpp` | Catch2 unit tests | RED |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_2_3.cmake` | CMake script-mode test | RED |
| `MuMain/tests/platform/test_ac_std3_no_raw_imm.cmake` | CMake script-mode test | RED |

**CMakeLists.txt registrations:**
- `MuMain/tests/CMakeLists.txt` — `platform/test_platform_text_input.cpp` added to `MuTests`
- `MuMain/tests/platform/CMakeLists.txt` — two new `add_test()` entries registered

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries | None introduced |
| Testing framework | Catch2 v3.7.1 (correct) |
| Test patterns | GIVEN/WHEN/THEN, AC-N: prefix in test names |
| Coverage target | Platform module (UTF-8 decode, text buffer logic) |
| Playwright (E2E) | N/A — infrastructure story |
| Bruno (API) | N/A — infrastructure story (no HTTP endpoints) |
| MU_ENABLE_SDL3 guard | All SDL3 tests inside `#ifdef MU_ENABLE_SDL3` |
| Flow code | VS1-SDL-INPUT-TEXT in all artifacts |
| Forbidden patterns | No `new`/`delete`, no `NULL`, no Win32 in game logic |

---

## Manual Validation (Deferred — blocked until EPIC-4 rendering migration)

- Chat typing on macOS arm64 and Linux x64 with correct Unicode characters
- Special characters (é, ü, ñ) on non-US keyboard layouts
- Backspace, arrow keys, Home/End in chat and login password fields
- IME overlay does not appear when no text field is active

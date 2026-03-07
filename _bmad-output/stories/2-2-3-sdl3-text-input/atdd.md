# ATDD Checklist — Story 2.2.3: SDL3 Text Input Migration

**Story Key:** 2-2-3-sdl3-text-input
**Story Type:** infrastructure
**Flow Code:** VS1-SDL-INPUT-TEXT
**Date Generated:** 2026-03-06
**Phase:** GREEN (implementation complete; quality gate passed)

---

## AC-to-Test Mapping

| AC | Description (summary) | Test File | Test Name | Status |
|----|------------------------|-----------|-----------|--------|
| AC-1 | SDL_EVENT_TEXT_INPUT replaces WM_CHAR | `test_platform_text_input.cpp` | `AC-1 [VS1-SDL-INPUT-TEXT]: SDL text input globals exist and can be set` | GREEN |
| AC-1 | Concatenation of multiple events per frame | `test_platform_text_input.cpp` | `AC-1 [VS1-SDL-INPUT-TEXT]: SDL text input concatenation — multiple events per frame` | GREEN |
| AC-2 | Typed chars appear in text buffer (ASCII) | `test_platform_text_input.cpp` | `AC-2 [VS1-SDL-INPUT-TEXT]: SDL text buffer append — ASCII character added to buffer` | GREEN |
| AC-2 | Max length enforced — no overflow | `test_platform_text_input.cpp` | `AC-2 [VS1-SDL-INPUT-TEXT]: SDL text buffer max length enforcement — no overflow` | GREEN |
| AC-2 | NUMBERONLY filters non-digits | `test_platform_text_input.cpp` | `AC-2 [VS1-SDL-INPUT-TEXT]: NUMBERONLY option filters non-digit characters` | GREEN |
| AC-3 | ASCII decodes correctly | `test_platform_text_input.cpp` | `AC-3 [VS1-SDL-INPUT-TEXT]: MuSdlUtf8NextChar decodes ASCII character correctly` | GREEN |
| AC-3 | 2-byte UTF-8 (é, ü, ñ) decodes correctly | `test_platform_text_input.cpp` | `AC-3 [VS1-SDL-INPUT-TEXT]: MuSdlUtf8NextChar decodes 2-byte UTF-8 sequence correctly` | GREEN |
| AC-3 | 3-byte UTF-8 (€, あ) decodes correctly | `test_platform_text_input.cpp` | `AC-3 [VS1-SDL-INPUT-TEXT]: MuSdlUtf8NextChar decodes 3-byte UTF-8 sequence correctly` | GREEN |
| AC-3 | Malformed UTF-8 returns null/safe value | `test_platform_text_input.cpp` | `AC-3 [VS1-SDL-INPUT-TEXT]: MuSdlUtf8NextChar handles malformed UTF-8 sequences` | GREEN |
| AC-4 | Backspace removes last char | `test_platform_text_input.cpp` | `AC-4 [VS1-SDL-INPUT-TEXT]: Backspace removes last character from SDL text buffer` | GREEN |
| AC-STD-11 | Flow code in SDLEventLoop.cpp | `test_ac_std11_flow_code_2_2_3.cmake` | `2.2.3-AC-STD-11:flow-code-text-input` | GREEN |
| AC-STD-3 | No raw IME calls outside Platform/ | `test_ac_std3_no_raw_imm.cmake` | `2.2.3-AC-STD-3:no-raw-imm-apis` | GREEN |

---

## Implementation Checklist

### PCC Compliance

- [x]No prohibited libraries used (raw `new`/`delete`, `NULL`, `wprintf`, `#ifdef _WIN32` in game logic)
- [x]Testing framework: Catch2 v3.7.1 via FetchContent — no other test framework introduced
- [x]All new code uses `#pragma once` (no `#ifndef` guards)
- [x]All new code uses `nullptr` (not `NULL`)
- [x]All new code uses `std::unique_ptr` for heap allocation (no raw `new`/`delete`)
- [x]No `#ifdef _WIN32` in game logic files — only in `Platform/` abstraction layer and `ThirdParty/` (exception)
- [x]Flow code `VS1-SDL-INPUT-TEXT` appears in `SDLEventLoop.cpp`, test names, and story artifacts
- [x]All error logging via `g_ErrorReport.Write()` with `MU_ERR_TEXT_*` prefix and flow code

### AC-1: SDL_EVENT_TEXT_INPUT Handler in SDLEventLoop

- [x]`g_szSDLTextInput[32]` global defined in `SDLKeyboardState.cpp` (inside `#ifdef MU_ENABLE_SDL3`)
- [x]`g_bSDLTextInputReady` global defined in `SDLKeyboardState.cpp` (inside `#ifdef MU_ENABLE_SDL3`)
- [x]`extern char g_szSDLTextInput[32]` declared in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [x]`extern bool g_bSDLTextInputReady` declared in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [x]`SDL_EVENT_TEXT_INPUT` case added to `switch (event.type)` in `SDLEventLoop::PollEvents()`
- [x]Per-frame reset of `g_szSDLTextInput[0] = '\0'` and `g_bSDLTextInputReady = false` at start of `PollEvents()`
- [x]Concatenation guard: `if (existing + incoming < sizeof(g_szSDLTextInput))` prevents overflow
- [x]Flow code `VS1-SDL-INPUT-TEXT` present as comment in `SDLEventLoop.cpp` SDL_EVENT_TEXT_INPUT handler

### AC-2: CUITextInputBox Text Buffer (m_szSDLText)

- [x]`wchar_t m_szSDLText[MAX_CHAT_SIZE]` member added to `CUITextInputBox` in `UIControls.h`
- [x]`int m_iSDLTextLen` member added to `CUITextInputBox` in `UIControls.h`
- [x]`int m_iSDLMaxLength` member added to `CUITextInputBox` in `UIControls.h`
- [x]`bool m_bBackspaceHeld` member added to `CUITextInputBox` in `UIControls.h`
- [x]`CUITextInputBox::DoAction()` reads `g_szSDLTextInput` when `g_bSDLTextInputReady` is true
- [x]Backspace handled in `DoAction()` via `GetAsyncKeyState(VK_BACK)` with `m_bBackspaceHeld` edge detection
- [x]`CUITextInputBox::GetText()` uses `m_szSDLText` on non-Windows (`#else` branch)
- [x]`CUITextInputBox::SetText()` uses `m_szSDLText` on non-Windows (`#else` branch)
- [x]`CUITextInputBox::SetTextLimit()` stores limit in `m_iSDLMaxLength` on all paths

### AC-3: MuSdlUtf8NextChar UTF-8 Decoder

- [x]`MuSdlUtf8NextChar(const char*& src)` inline function added to `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [x]ASCII decode correct (0x00-0x7F range, advances src by 1)
- [x]2-byte decode correct (0xC0-0xDF lead, advances src by 2)
- [x]3-byte decode correct (0xE0-0xEF lead, advances src by 3)
- [x]Malformed sequences return `L'\0'` and advance src (no infinite loop)
- [x]Surrogate range (0xD800-0xDFFF) and >0xFFFF codepoints return `L'?'`
- [x]Flow code `VS1-SDL-INPUT-TEXT` comment present in `MuSdlUtf8NextChar` declaration

### AC-4: Backspace, Delete, Home, End, Arrow Keys

- [x]Backspace handled via `GetAsyncKeyState(VK_BACK)` in `DoAction()` — removes last char from `m_szSDLText`
- [x]`m_bBackspaceHeld` edge detection prevents auto-repeat consuming multiple chars per hold
- [x]Delete, Home, End, arrows handled via existing `g_sdl3KeyboardState` shim from story 2.2.1 — no new code needed (verify)

### AC-5: SDL_StartTextInput / SDL_StopTextInput Lifecycle

- [x]`MuStartTextInput()` declared in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [x]`MuStopTextInput()` declared in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [x]`MuStartTextInput()` implemented in `SDLKeyboardState.cpp` — calls `SDL_StartTextInput(pWnd)` with SDL_Window* from `mu::MuPlatform::GetNativeWindow()`
- [x]`MuStopTextInput()` implemented in `SDLKeyboardState.cpp` — calls `SDL_StopTextInput(pWnd)`
- [x]`MuStartTextInput()` logs start via `g_ErrorReport.Write(L"[VS1-SDL-INPUT-TEXT] SDL_StartTextInput activated\r\n")`
- [x]`MuStartTextInput()` logs failure via `g_ErrorReport.Write(L"MU_ERR_TEXT_START_FAILED [VS1-SDL-INPUT-TEXT]: no SDL window available\r\n")` when window is null
- [x]`CUITextInputBox::GiveFocus()` calls `MuStartTextInput()` on SDL3 path (`#elif defined(MU_ENABLE_SDL3)`)
- [x]`CUITextInputBox::SetState(UISTATE_HIDE)` calls `MuStopTextInput()` on SDL3 path
- [x]`mu::MuPlatform::GetNativeWindow()` static method exists and returns `SDL_Window*` via `SDLWindow::GetNativeHandle()`

### AC-STD-2: PlatformCompat.h Stubs (Win32 GDI / IME / Clipboard / Window)

- [x]`GetTextExtentPoint32` stub added to `PlatformCompat.h` (non-Windows, outside `MU_ENABLE_SDL3` guard)
- [x]`lstrlen` shim added to `PlatformCompat.h` (as alias to `wcslen`)
- [x]IME type aliases (`HIMC`, `IME_CMODE_ALPHANUMERIC`, etc.) added to `PlatformCompat.h`
- [x]`ImmGetContext`, `ImmGetConversionStatus`, `ImmSetConversionStatus`, `ImmReleaseContext` no-op stubs added
- [x]`WM_IME_CONTROL`, `IMC_SETCOMPOSITIONWINDOW`, `SendMessage`, `PostMessage`, `EM_SETSEL` stubs added
- [x]`SetFocus`, `GetFocus` stubs returning sentinel non-null HWND added
- [x]`SW_HIDE`, `SW_SHOW`, `ShowWindow` stub added
- [x]`WNDPROC`, `GWLP_WNDPROC`, `GWLP_USERDATA`, `LONG_PTR`, `SetWindowLongPtrW`, `GetWindowLongPtrW`, `CallWindowProcW` stubs added
- [x]`WS_CHILD`, `WS_VISIBLE`, `WS_VSCROLL`, `ES_*`, `HMENU`, `CreateWindowW` stub (returns nullptr) added
- [x]GDI stubs: `HBITMAP`, `HGDIOBJ`, `BITMAPINFOHEADER`, `BITMAPINFO`, `RGBQUAD`, `DeleteDC`, `DeleteObject`, `CreateCompatibleDC`, `CreateDIBSection`, `SelectObject` added
- [x]Clipboard stubs: `HGLOBAL`, `CF_TEXT`, `OpenClipboard`, `GetClipboardData`, `GlobalLock`, `GlobalUnlock`, `CloseClipboard` added
- [x]`WM_CHAR`, `WM_SYSKEYDOWN`, `WM_IME_COMPOSITION`, `WM_IME_STARTCOMPOSITION`, `WM_IME_ENDCOMPOSITION`, `WM_IME_NOTIFY` constants added
- [x]`COMPOSITIONFORM` struct and `CFS_POINT` added to `PlatformCompat.h`
- [x]`UINT` typedef verified in `PlatformTypes.h` (add `using UINT = unsigned int;` if missing)

### AC-STD-2 (clipboard SDL3 path)

- [x]`MuClipboardIsNumericOnly()` inline function added to `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`)
- [x]`UIControls.cpp` `ClipboardCheck` call site in `EditWndProc` wrapped with `#ifdef _WIN32` / `#elif defined(MU_ENABLE_SDL3)` guard

**Code Review Note (2026-03-06):** `MuClipboardIsNumericOnly()` in `EditWndProc` is dead code on the SDL3 path because `EditWndProc` is never registered or called when `m_hEditWnd == nullptr` (CreateWindowW stub returns nullptr). Clipboard paste validation on SDL3 is handled implicitly: SDL3 delivers Ctrl+V paste via `SDL_EVENT_TEXT_INPUT`, and `DoActionSub`'s NUMBERONLY/SERIALNUMBER filters correctly reject non-conforming characters. The function is correctly implemented but unreachable. Behavior is correct via a different mechanism than intended.

### AC-STD-3: No Raw IME APIs Outside Platform/ and ThirdParty/

- [x]`ImmGetContext`, `ImmSetConversionStatus`, `ImmReleaseContext` only in `Platform/` (as stubs) and `ThirdParty/` (behind `#ifdef _WIN32`)
- [x]`ZzzInterface.cpp:263` `SendMessage(..., WM_IME_CONTROL, ...)` compiles via no-op stub — no source change needed (verify)
- [x]CMake test `2.2.3-AC-STD-3:no-raw-imm-apis` passes

### AC-STD-3 HaveFocus and Focus Tracking

- [x]`bool m_bSDLHasFocus` member added to `CUITextInputBox` in `UIControls.h`
- [x]`CUITextInputBox::HaveFocus()` returns `m_bSDLHasFocus ? TRUE : FALSE` on non-Windows
- [x]`m_bSDLHasFocus = true` set in `GiveFocus()` SDL3 branch
- [x]`m_bSDLHasFocus = false` set in `SetState(UISTATE_HIDE)` SDL3 branch
- [x]`SetIMEPosition()` body wrapped in `#ifdef _WIN32` guard (SDL3: IME positioning handled by SDL3 internally)

### AC-STD-11: Flow Code

- [x]Flow code `VS1-SDL-INPUT-TEXT` present in `SDLEventLoop.cpp`
- [x]Flow code `VS1-SDL-INPUT-TEXT` present in `SDLKeyboardState.cpp` (`g_szSDLTextInput` comment)
- [x]Flow code `VS1-SDL-INPUT-TEXT` present in `PlatformCompat.h` (`MuSdlUtf8NextChar` comment)
- [x]Flow code `VS1-SDL-INPUT-TEXT` present in all TEST_CASE names in `test_platform_text_input.cpp`
- [x]Flow code `VS1-SDL-INPUT-TEXT` present in `atdd.md` (this file)
- [x]CMake test `2.2.3-AC-STD-11:flow-code-text-input` passes

### AC-STD-13: Quality Gate

- [x]`./ctl check` passes on macOS (clang-format + cppcheck)
- [x]MinGW CI build passes — all SDL3 code inside `#ifdef MU_ENABLE_SDL3`; all Win32 stubs inside `#else // !_WIN32`
- [x]No cppcheck warnings in new Platform/ files
- [x]clang-format clean (Allman braces, 4-space indent, 120-col limit)

### Test Infrastructure

- [x]`test_platform_text_input.cpp` added to `MuTests` target in `MuMain/tests/CMakeLists.txt`
- [x]`test_ac_std11_flow_code_2_2_3.cmake` registered as `2.2.3-AC-STD-11:flow-code-text-input` CTest
- [x]`test_ac_std3_no_raw_imm.cmake` registered as `2.2.3-AC-STD-3:no-raw-imm-apis` CTest
- [x]All Catch2 tests in `test_platform_text_input.cpp` compile with `BUILD_TESTING=ON`
- [x]All Catch2 tests compile and are skipped (no code) when `MU_ENABLE_SDL3=OFF` (CI Strategy B)

---

## Test Files Created (RED Phase)

| File | Type | Phase |
|------|------|-------|
| `MuMain/tests/platform/test_platform_text_input.cpp` | Catch2 unit tests | GREEN |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_2_3.cmake` | CMake script-mode test | GREEN |
| `MuMain/tests/platform/test_ac_std3_no_raw_imm.cmake` | CMake script-mode test | GREEN |

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

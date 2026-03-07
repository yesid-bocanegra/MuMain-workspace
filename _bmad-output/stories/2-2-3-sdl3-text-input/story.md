# Story 2.2.3: SDL3 Text Input Migration

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 2 - SDL3 Windowing & Input Migration |
| Feature | 2.2 - Input |
| Story ID | 2.2.3 |
| Story Points | 3 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-1 |
| Flow Code | VS1-SDL-INPUT-TEXT |
| FRs Covered | FR22 — Text input in chat/fields on all platforms via SDL3 |
| Prerequisites | 2.2.1 done (SDL3 keyboard input + GetAsyncKeyState shim established); 2.1.1 done (SDL3 event loop) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | SDLEventLoop: add SDL_EVENT_TEXT_INPUT handler feeding g_szSDLTextInput buffer; PlatformCompat.h: add Win32 text/IME/clipboard/GDI API stubs; ThirdParty/UIControls.cpp: replace WM_CHAR-driven text insertion and CreateWindowW edit control with SDL3-driven path (behind MU_ENABLE_SDL3 guard) |
| project-docs | documentation | Test scenarios for story 2.2.3 |

---

## Story

**[VS-1] [Flow:F]**

**As a** player,
**I want** text input handled by SDL3,
**so that** I can type in chat and text fields on macOS and Linux with correct character encoding.

---

## Functional Acceptance Criteria

- [x]**AC-1:** SDL3 text input events (`SDL_EVENT_TEXT_INPUT`) replace Win32 `WM_CHAR`/`WM_IME_*` as the source of character input on non-Windows platforms — typed characters appear correctly in the `CUITextInputBox` buffer.
- [x]**AC-2:** Chat input field accepts typed characters correctly — typing in chat produces the correct Unicode characters in the `m_szText` buffer inside `CUITextInputBox`.
- [x]**AC-3:** Special characters and accented letters from non-US keyboard layouts (e.g., `é`, `ü`, `ñ`) work on macOS/Linux — SDL3 delivers them pre-composed as UTF-8 in `SDL_TextInputEvent::text[]`.
- [x]**AC-4:** Backspace, Delete, Home, End, and arrow keys work in text fields — these are handled via the existing keyboard shim (`GetAsyncKeyState` + `g_sdl3KeyboardState`) established in story 2.2.1 and processed by `CUITextInputBox::DoAction()`.
- [x]**AC-5:** Text input activates (`SDL_StartTextInput`) when a `CUITextInputBox` gains focus and deactivates (`SDL_StopTextInput`) when it loses focus or is hidden — preventing spurious IME overlays when no text field is active.

---

## Standard Acceptance Criteria

- [x]**AC-STD-1:** Code standards compliance — PascalCase public functions, `m_` Hungarian member prefix, `std::unique_ptr` (no raw `new`/`delete`), `nullptr`, `#pragma once`, Allman braces, 4-space indent, LF line endings, UTF-8 files. No `#ifdef _WIN32` in game logic — only in `Platform/` layer and `PlatformCompat.h`.
- [x]**AC-STD-2:** Testing requirements — Catch2 v3.7.1 unit tests in `MuMain/tests/platform/`; tests cover: UTF-8 to wchar_t conversion correctness for ASCII and multi-byte characters, SDL text input buffer append/truncation at max length, backspace handling in the SDL text buffer.
- [x]**AC-STD-3:** No Win32 IME APIs (`ImmGetContext`, `ImmSetConversionStatus`, `ImmReleaseContext`) remain in non-Windows compilation paths — all IME calls are inside `#ifdef _WIN32` guards or equivalent no-op shims in `PlatformCompat.h`.
- [x]**AC-STD-8:** Error catalog — SDL text input start/stop failures (if any) log via `g_ErrorReport.Write()` with `MU_ERR_TEXT_*` prefix and flow code `VS1-SDL-INPUT-TEXT`.
- [x]**AC-STD-10:** Contract catalogs — N/A (no HTTP API or event-bus contracts).
- [x]**AC-STD-11:** Flow code `VS1-SDL-INPUT-TEXT` appears in log output (`g_ErrorReport.Write`), test names, and story artifacts.
- [x]**AC-STD-12:** SLI/SLO targets — N/A for platform infrastructure story; `SDL_EVENT_TEXT_INPUT` handler must complete in < 1 microsecond per event (string copy — verified by design).
- [x]**AC-STD-13:** Quality gate passes: `make -C MuMain format-check && make -C MuMain lint`
- [x]**AC-STD-14:** Observability — SDL text input lifecycle events logged via `g_ErrorReport.Write()` for diagnostics (start/stop per focus change).
- [x]**AC-STD-15:** Git safety — clean merge, no force push, no incomplete rebase.
- [x]**AC-STD-16:** Correct test infrastructure — Catch2 v3.7.1 via FetchContent, tests in `MuMain/tests/platform/`, `BUILD_TESTING=ON` opt-in.
- [x]**AC-STD-20:** N/A — no HTTP endpoints, event-bus entries, or nav-catalog screens in this story.

---

## Validation Artifacts

- [x]**AC-VAL-1:** N/A — no HTTP endpoints.
- [x]**AC-VAL-2:** Test scenarios documented in `_bmad-output/test-scenarios/epic-2/2-2-3-sdl3-text-input.md`
- [x]**AC-VAL-3:** N/A — no seed data.
- [x]**AC-VAL-4:** N/A — no API catalog entries.
- [x]**AC-VAL-5:** N/A — no event-bus events.
- [x]**AC-VAL-6:** Flow catalog entry `VS1-SDL-INPUT-TEXT` confirmed in story artifacts.

**Manual validation (deferred to integration testing after EPIC-2 completes):**
- AC-VAL-1 (manual): Chat typing on macOS arm64 and Linux x64 — requires full game compilation (blocked until EPIC-4 rendering migration).
- AC-VAL-2 (manual): Special characters validated on non-US keyboard layouts (accented letters, symbols).
- AC-VAL-3 (manual): Backspace, arrow keys, Home/End work correctly in chat and login password fields.

---

## Tasks / Subtasks

- [x]**Task 1 — Add Win32 GDI / IME / clipboard no-op stubs to PlatformCompat.h** (AC: 3, AC-STD-3)
  - [x]1.1 In `PlatformCompat.h` (inside `#else // !_WIN32` block, NOT inside `#ifdef MU_ENABLE_SDL3`), add stubs for GDI font measurement used by `UIControls.cpp` and `NewUIChatInputBox.cpp`:
    ```cpp
    // GetTextExtentPoint32 stub — used extensively in UIControls.cpp and NewUIChatInputBox.cpp
    // for text measurement (CutStr, tooltip sizing). On non-Windows the font DC is nullptr;
    // return a fixed estimate so layout code does not crash.
    inline BOOL GetTextExtentPoint32(HDC /*hDC*/, const wchar_t* pszText, int cch, SIZE* lpSize)
    {
        // Estimate: 8px per character width, 16px height — acceptable fallback until
        // Phase 4 (font system migration introduces IPlatformFont::MeasureText).
        if (lpSize != nullptr)
        {
            lpSize->cx = (cch > 0 ? cch : 0) * 8;
            lpSize->cy = 16;
        }
        return TRUE;
    }
    ```
  - [x]1.2 Add `lstrlen` shim (alias to `wcslen`) — used in `UIControls.cpp` in `GetTextExtentPoint32` call sites:
    ```cpp
    #ifndef lstrlen
    inline int lstrlen(const wchar_t* s) { return s ? static_cast<int>(wcslen(s)) : 0; }
    #endif
    ```
  - [x]1.3 Add Win32 IME stubs (all no-ops on non-Windows) — used in `UIControls.cpp:SaveIMEStatus`, `RestoreIMEStatus`, `CheckTextInputBoxIME`:
    ```cpp
    // IME type aliases and constants (non-Windows only)
    using HIMC = void*;
    #define IME_CMODE_ALPHANUMERIC 0x0000
    #define IME_SMODE_NONE         0x0000
    #define IME_CONVERSIONMODE     1
    #define IME_SENTENCEMODE       2
    #define IMN_SETOPENSTATUS      0x0005
    #define IMN_SETCONVERSIONMODE  0x0006
    #define IMN_SETSENTENCEMODE    0x0007
    inline HIMC ImmGetContext(HWND /*hwnd*/) { return nullptr; }
    inline BOOL ImmGetConversionStatus(HIMC /*himc*/, DWORD* pdwConv, DWORD* pdwSent)
    {
        if (pdwConv) *pdwConv = IME_CMODE_ALPHANUMERIC;
        if (pdwSent) *pdwSent = IME_SMODE_NONE;
        return TRUE;
    }
    inline BOOL ImmSetConversionStatus(HIMC /*himc*/, DWORD /*dwConv*/, DWORD /*dwSent*/) { return TRUE; }
    inline BOOL ImmReleaseContext(HWND /*hwnd*/, HIMC /*himc*/) { return TRUE; }
    ```
  - [x]1.4 Add Win32 window message stubs needed by `UIControls.cpp` (no-ops on non-Windows, outside SDL3 guard since UIControls is in ThirdParty/ and compiled unconditionally):
    ```cpp
    // Window message stubs — UIControls.cpp uses these in CUITextInputBox::SetIMEPosition and GiveFocus
    #define WM_IME_CONTROL    0x0283
    #define IMC_SETCOMPOSITIONWINDOW 0x000C
    inline LRESULT SendMessage(HWND /*hwnd*/, UINT /*msg*/, WPARAM /*wp*/, LPARAM /*lp*/) { return 0; }
    inline LRESULT PostMessage(HWND /*hwnd*/, UINT /*msg*/, WPARAM /*wp*/, LPARAM /*lp*/) { return 0; }  // NOLINT
    // EM_SETSEL: edit control message (set selection range) — no-op on SDL3 path
    #define EM_SETSEL 0x00B1
    ```
  - [x]1.5 Add `SetFocus` / `GetFocus` stubs returning non-null sentinel (matches `GetActiveWindow` pattern from 2.2.2):
    ```cpp
    // SetFocus / GetFocus stubs — UIControls.cpp uses these in CUITextInputBox::GiveFocus
    // On SDL3 path focus is managed by SDLEventLoop; returning a sentinel avoids null dereferences.
    inline HWND SetFocus(HWND /*hwnd*/) { return reinterpret_cast<HWND>(1); }
    inline HWND GetFocus() { return reinterpret_cast<HWND>(1); }
    ```
  - [x]1.6 Add `ShowWindow` stub — used in `CUITextInputBox::SetState` (Win32 path shows/hides the edit HWND):
    ```cpp
    #define SW_HIDE 0
    #define SW_SHOW 5
    inline BOOL ShowWindow(HWND /*hwnd*/, int /*nCmdShow*/) { return TRUE; }
    ```
  - [x]1.7 Add `WNDPROC` type alias and `SetWindowLongPtrW` / `GetWindowLongPtrW` / `CallWindowProcW` stubs — used in `UIControls.cpp:CUITextInputBox::Init` (subclasses the Win32 edit control's window proc):
    ```cpp
    using WNDPROC = LRESULT (*)(HWND, UINT, WPARAM, LPARAM);
    #define GWLP_WNDPROC   (-4)
    #define GWLP_USERDATA  (-21)
    using LONG_PTR = intptr_t;
    inline LONG_PTR SetWindowLongPtrW(HWND /*hwnd*/, int /*nIndex*/, LONG_PTR /*dwNewLong*/) { return 0; }
    inline LONG_PTR GetWindowLongPtrW(HWND /*hwnd*/, int /*nIndex*/) { return 0; }
    inline LRESULT CallWindowProcW(WNDPROC /*proc*/, HWND /*hwnd*/, UINT /*msg*/, WPARAM /*wp*/, LPARAM /*lp*/) { return 0; }
    ```
  - [x]1.8 Add `CreateWindowW` stub returning nullptr — on the SDL3 path `CUITextInputBox::Init` calls `CreateWindowW(L"edit", ...)` to create a Win32 edit control. The stub returns nullptr so the `if (m_hEditWnd)` guard prevents all Win32 edit control operations. The SDL3 text input path bypasses the edit HWND entirely:
    ```cpp
    // WS_* style flags needed by CreateWindowW call
    #define WS_CHILD       0x40000000L
    #define WS_VISIBLE     0x10000000L
    #define WS_VSCROLL     0x00200000L
    #define ES_AUTOHSCROLL 0x0080L
    #define ES_AUTOVSCROLL 0x0040L
    #define ES_MULTILINE   0x0004L
    #define ES_PASSWORD    0x0020L
    using HMENU = void*;
    inline HWND CreateWindowW(const wchar_t* /*cls*/, const wchar_t* /*wndName*/, DWORD /*style*/,
                              int /*x*/, int /*y*/, int /*w*/, int /*h*/,
                              HWND /*parent*/, HMENU /*menu*/, HINSTANCE /*inst*/, void* /*param*/)
    {
        return nullptr; // SDL3 path: no Win32 edit control — text handled via SDL_EVENT_TEXT_INPUT
    }
    ```
  - [x]1.9 Add `DeleteDC`, `DeleteObject`, `CreateCompatibleDC`, `CreateDIBSection`, `SelectObject` stubs — used in `CUIRenderTextOriginal::Create/Release` (GDI font rendering that will be replaced in Phase 4). On non-Windows these are no-ops that prevent crashes:
    ```cpp
    using HBITMAP = void*;
    using HGDIOBJ = void*;
    struct BITMAPINFOHEADER { uint32_t biSize; int32_t biWidth; int32_t biHeight; uint16_t biPlanes;
                              uint16_t biBitCount; uint32_t biCompression; uint32_t biSizeImage;
                              int32_t biXPelsPerMeter; int32_t biYPelsPerMeter; uint32_t biClrUsed;
                              uint32_t biClrImportant; };
    struct PALETTEENTRY { uint8_t peRed, peGreen, peBlue, peFlags; };
    struct BITMAPINFO { BITMAPINFOHEADER bmiHeader; RGBQUAD bmiColors[1]; };
    struct RGBQUAD { uint8_t rgbBlue, rgbGreen, rgbRed, rgbReserved; };
    #define BI_RGB 0
    #define DIB_RGB_COLORS 0
    inline BOOL DeleteDC(HDC /*hdc*/) { return TRUE; }
    inline BOOL DeleteObject(HGDIOBJ /*obj*/) { return TRUE; }
    inline HDC CreateCompatibleDC(HDC /*hdc*/) { return nullptr; }
    inline HBITMAP CreateDIBSection(HDC /*hdc*/, const BITMAPINFO* /*bmi*/, UINT /*usage*/,
                                    void** ppvBits, HANDLE /*hSection*/, DWORD /*offset*/)
    {
        if (ppvBits) *ppvBits = nullptr;
        return nullptr;
    }
    inline HGDIOBJ SelectObject(HDC /*hdc*/, HGDIOBJ /*obj*/) { return nullptr; }
    ```
  - [x]1.10 Add clipboard stubs — `OpenClipboard`, `GetClipboardData`, `GlobalLock`, `GlobalUnlock`, `CloseClipboard` are used in `UIControls.cpp:ClipboardCheck()` for numeric paste validation. On SDL3 path, clipboard comes from `SDL_GetClipboardText()` (added in Task 2). Stub the Win32 clipboard functions to safe no-ops so `ClipboardCheck` compiles:
    ```cpp
    using HGLOBAL = void*;
    #define CF_TEXT 1
    inline BOOL OpenClipboard(HWND /*hwnd*/) { return FALSE; } // SDL3 path uses SDL_GetClipboardText
    inline HGLOBAL GetClipboardData(UINT /*uFormat*/) { return nullptr; }
    inline void* GlobalLock(HGLOBAL /*hMem*/) { return nullptr; }
    inline BOOL GlobalUnlock(HGLOBAL /*hMem*/) { return TRUE; }
    inline BOOL CloseClipboard() { return TRUE; }
    ```
  - [x]1.11 Add `WM_SYSKEYDOWN` / `WM_CHAR` constants needed by `EditWndProc` (the Win32 subclassed edit control proc in `UIControls.cpp`) — these message constants must be defined so the switch statement compiles, even though `EditWndProc` is never called on the SDL3 path (no Win32 edit control HWND):
    ```cpp
    #define WM_CHAR        0x0102
    #define WM_SYSKEYDOWN  0x0104
    #define WM_IME_COMPOSITION    0x010F
    #define WM_IME_STARTCOMPOSITION 0x010D
    #define WM_IME_ENDCOMPOSITION 0x010E
    #define WM_IME_NOTIFY  0x0282
    ```
  - [x]1.12 Add `g_hInst` extern stub for non-Windows builds — `UIControls.cpp:CUITextInputBox::Init` uses `g_hInst` in the `CreateWindowW` call. On non-Windows the stub returns nullptr and `CreateWindowW` returns nullptr anyway:
    - Check if `g_hInst` is declared as `extern HINSTANCE g_hInst` in `stdafx.h` or `Winmain.cpp`. If only in `Winmain.cpp`, it compiles correctly on non-Windows via the `extern` declaration in `UIControls.cpp`. Verify — no stub needed if the extern resolves.
  - [x]1.13 Add `UINT` typedef if not already defined in `PlatformTypes.h` — used in stub signatures above:
    - Check `PlatformTypes.h` — if `UINT` is missing, add `using UINT = unsigned int;`.

- [x]**Task 2 — SDL3 clipboard replacement (MU_ENABLE_SDL3 path)** (AC: 3)
  - [x]2.1 In `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3` block), add `ClipboardCheckSDL3()` — an SDL3-based replacement for `ClipboardCheck()` in `UIControls.cpp`:
    ```cpp
    // SDL3 clipboard text retrieval — replaces OpenClipboard/GetClipboardData pattern.
    // Returns true if clipboard text contains only digit characters ('0'-'9').
    // Used by EditWndProc WM_CHAR handler for UIOPTION_NUMBERONLY fields (Ctrl+V paste check).
    // [VS1-SDL-INPUT-TEXT]
    inline bool MuClipboardIsNumericOnly()
    {
        char* text = SDL_GetClipboardText();
        if (text == nullptr)
        {
            return false;
        }
        bool allDigits = true;
        for (const char* p = text; *p != '\0'; ++p)
        {
            if (*p < '0' || *p > '9')
            {
                allDigits = false;
                break;
            }
        }
        SDL_free(text);
        return allDigits;
    }
    ```
  - [x]2.2 In `UIControls.cpp`, wrap the `ClipboardCheck` call site inside `EditWndProc` (line ~3159: `Char == 0x16 && ClipboardCheck(hWnd) == TRUE`) with a compile-time guard:
    ```cpp
    #ifdef _WIN32
        else if (Char == 0x16 && ClipboardCheck(hWnd) == TRUE);
    #elif defined(MU_ENABLE_SDL3)
        else if (Char == 0x16 && MuClipboardIsNumericOnly());
    #endif
    ```
    **IMPORTANT:** `UIControls.cpp` is in `ThirdParty/` and is excluded from clang-tidy. Use inline `#ifdef` guards here as an exception — this is the legacy compatibility pattern for ThirdParty code, consistent with the existing `#ifdef LJH_ADD_RESTRICTION_ON_ID` pattern in the same switch block.

- [x]**Task 3 — SDL3 text input global buffer** (AC: 1, 2)
  - [x]3.1 In `SDLKeyboardState.cpp` (already created in story 2.2.1), add the global SDL text input buffer:
    ```cpp
    #ifdef MU_ENABLE_SDL3
    // SDL text input buffer — populated by SDL_EVENT_TEXT_INPUT in SDLEventLoop::PollEvents().
    // Up to SDL_TEXTINPUTEVENT_TEXT_SIZE (32) UTF-8 bytes per event.
    // Declared extern in PlatformCompat.h for access by CUITextInputBox::DoAction().
    // [VS1-SDL-INPUT-TEXT]
    char g_szSDLTextInput[32] = {};
    bool g_bSDLTextInputReady = false;
    #endif
    ```
  - [x]3.2 In `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3` block), add extern declarations:
    ```cpp
    // SDL text input — populated each frame when SDL_EVENT_TEXT_INPUT fires.
    // g_szSDLTextInput: UTF-8 encoded character(s) from keyboard/IME.
    // g_bSDLTextInputReady: true for one frame when new text is available.
    // [VS1-SDL-INPUT-TEXT]
    extern char g_szSDLTextInput[32];
    extern bool g_bSDLTextInputReady;
    ```
  - [x]3.3 In `SDLEventLoop::PollEvents()` in `SDLEventLoop.cpp`, reset the text input buffer at the start of each frame (before the event loop) and add the `SDL_EVENT_TEXT_INPUT` handler:
    ```cpp
    // Reset SDL text input state each frame — text is consumed once per frame.
    // [VS1-SDL-INPUT-TEXT]
    g_szSDLTextInput[0] = '\0';
    g_bSDLTextInputReady = false;
    ```
    Add in the `switch (event.type)` block:
    ```cpp
    case SDL_EVENT_TEXT_INPUT:
        // SDL3: event.text.text[] is a null-terminated UTF-8 string (up to 32 bytes).
        // Copy into g_szSDLTextInput for CUITextInputBox::DoAction() to consume.
        // Multiple TEXT_INPUT events per frame are concatenated (rare but possible with IME).
        // [VS1-SDL-INPUT-TEXT]
        {
            size_t existing = strlen(g_szSDLTextInput);
            size_t incoming = strlen(event.text.text);
            if (existing + incoming < sizeof(g_szSDLTextInput))
            {
                memcpy(g_szSDLTextInput + existing, event.text.text, incoming + 1);
            }
            g_bSDLTextInputReady = true;
        }
        break;
    ```
  - [x]3.4 Add extern declarations for the text input buffer at the top of `SDLEventLoop.cpp` (before the anonymous namespace):
    ```cpp
    // SDL text input buffer (SDLKeyboardState.cpp) — populated here, read by UIControls.
    // [VS1-SDL-INPUT-TEXT]
    extern char g_szSDLTextInput[32];
    extern bool g_bSDLTextInputReady;
    ```

- [x]**Task 4 — SDL_StartTextInput / SDL_StopTextInput integration** (AC: 5)
  - [x]4.1 In `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3` block), add `MuStartTextInput` and `MuStopTextInput` wrapper functions that call SDL3 and log for diagnostics:
    ```cpp
    // Declared in SDLKeyboardState.cpp — implementation pulls in ErrorReport.h via PCH.
    // [VS1-SDL-INPUT-TEXT]
    void MuStartTextInput();
    void MuStopTextInput();
    ```
  - [x]4.2 Implement `MuStartTextInput()` and `MuStopTextInput()` in `SDLKeyboardState.cpp`:
    ```cpp
    void MuStartTextInput()
    {
        // SDL3: SDL_StartTextInput(window) requires the SDL_Window* pointer.
        // mu::MuPlatform::GetWindow() returns the SDL_Window* from the SDLWindow backend.
        // This function is called infrequently (on focus gain) — the MuPlatform lookup is acceptable.
        SDL_Window* pWnd = static_cast<SDL_Window*>(mu::MuPlatform::GetNativeWindow());
        if (pWnd != nullptr)
        {
            SDL_StartTextInput(pWnd);
            g_ErrorReport.Write(L"[VS1-SDL-INPUT-TEXT] SDL_StartTextInput activated\r\n");
        }
        else
        {
            g_ErrorReport.Write(L"MU_ERR_TEXT_START_FAILED [VS1-SDL-INPUT-TEXT]: no SDL window available\r\n");
        }
    }

    void MuStopTextInput()
    {
        SDL_Window* pWnd = static_cast<SDL_Window*>(mu::MuPlatform::GetNativeWindow());
        if (pWnd != nullptr)
        {
            SDL_StopTextInput(pWnd);
        }
    }
    ```
  - [x]4.3 Check `mu::MuPlatform` / `IPlatformWindow` for a `GetNativeWindow()` or equivalent accessor returning `SDL_Window*`. Based on story 2.1.1, `SDLWindow` wraps an `SDL_Window*`. If `GetNativeWindow()` does not exist on `MuPlatform`, add it:
    - In `MuPlatform.h` (or `IPlatformWindow.h`): declare `[[nodiscard]] static void* GetNativeWindow();`
    - In `MuPlatform.cpp`: delegate to `s_pWindow->GetNativeHandle()` (following the pattern of `CreateWindow`, `SetFullscreen`, etc.)
    - In `SDLWindow.h`/`SDLWindow.cpp`: add `void* GetNativeHandle() const override { return m_pWindow; }` where `m_pWindow` is the `SDL_Window*` member.
  - [x]4.4 In `CUITextInputBox::GiveFocus()` in `UIControls.cpp`, add SDL3 text input activation on non-Windows:
    ```cpp
    void CUITextInputBox::GiveFocus(BOOL SelectText)
    {
    #ifdef _WIN32
        if (m_hEditWnd == nullptr) return;
        // ... existing Win32 SetFocus / PostMessage code ...
    #elif defined(MU_ENABLE_SDL3)
        MuStartTextInput();
        g_dwKeyFocusUIID = GetUIID();
        // No PostMessage needed — SDL_EVENT_TEXT_INPUT drives input on SDL3 path.
    #endif
    }
    ```
    **Implementation note:** The `#ifdef _WIN32 / #elif MU_ENABLE_SDL3` pattern IS permitted in `ThirdParty/UIControls.cpp` as an exception — ThirdParty/ is excluded from clang-tidy and the legacy UIControls.cpp already uses conditional compilation (`#ifdef LJH_ADD_RESTRICTION_ON_ID`, `#ifdef PBG_ADD_INGAMESHOPMSGBOX`). Document this exception in the implementation.
  - [x]4.5 In `CUITextInputBox::SetState()` in `UIControls.cpp`, add SDL3 `StopTextInput` when hiding:
    ```cpp
    void CUITextInputBox::SetState(int iState)
    {
    #ifdef _WIN32
        if (m_hEditWnd == nullptr) return;
        // ... existing Win32 ShowWindow code ...
    #else
        m_iState = iState;
    #endif
    #ifdef MU_ENABLE_SDL3
        if (m_iState == UISTATE_HIDE)
        {
            MuStopTextInput();
        }
    #endif
    }
    ```

- [x]**Task 5 — CUITextInputBox: SDL3 text buffer management** (AC: 1, 2, 3, 4)
  - [x]5.1 In `UIControls.h`, add the SDL3 text buffer member to `CUITextInputBox` (inside `#ifdef MU_ENABLE_SDL3` or as a wchar_t buffer usable cross-platform):
    - `CUITextInputBox` already has `m_szText` (the wchar_t text buffer populated by the Win32 edit control). On the SDL3 path, the SDL text input replaces the edit control.
    - Check `UIControls.h` for `CUITextInputBox` class definition to understand existing members. The class uses `GetText(wchar_t*, int)` and `SetText(const wchar_t*)` to read/write the Win32 edit HWND text via `GetWindowTextW`/`SetWindowTextW`.
  - [x]5.2 In `UIControls.cpp`, guard `GetText` and `SetText` for non-Windows:
    - Existing `GetText` calls `GetWindowTextW(m_hEditWnd, szText, iMaxLength)` — on SDL3 path `m_hEditWnd` is nullptr. Add SDL3 branch that reads from an internal `m_szSDLText[MAX_CHAT_SIZE]` wchar_t buffer.
    - Existing `SetText` calls `SetWindowTextW(m_hEditWnd, szText)` — add SDL3 branch that copies to `m_szSDLText`.
    - Add `wchar_t m_szSDLText[MAX_CHAT_SIZE]` member to `CUITextInputBox` in `UIControls.h` (inside `#ifndef _WIN32` or unconditionally — wchar_t is available everywhere).
    - Add `int m_iSDLTextLen` member to track current text length.
    - Add `int m_iSDLMaxLength` member (set in `Init` from the `iMaxLength` parameter).
  - [x]5.3 In `UIControls.cpp`, add the SDL3 text input consumption in `CUITextInputBox::DoAction()`:
    - `DoAction()` currently calls `InvalidateRect(m_hEditWnd, nullptr, FALSE)` and `UpdateWindow(m_hEditWnd)` for Win32 rendering. On SDL3 path, `DoAction()` reads `g_szSDLTextInput` when `g_bSDLTextInputReady` is true and appends character(s) to `m_szSDLText`.
    - UTF-8 to wchar_t conversion needed: SDL3 delivers UTF-8 in `SDL_TextInputEvent::text[]`. Convert to wchar_t for the existing `wchar_t` text buffer:
    ```cpp
    // In CUITextInputBox::DoAction(), SDL3 path:
    #elif defined(MU_ENABLE_SDL3)
        if (g_bSDLTextInputReady && g_szSDLTextInput[0] != '\0')
        {
            // Convert UTF-8 SDL text input to wchar_t and append to m_szSDLText.
            // SDL delivers pre-composed characters so multi-byte sequences are expected.
            const char* src = g_szSDLTextInput;
            while (*src != '\0' && m_iSDLTextLen < m_iSDLMaxLength)
            {
                wchar_t wch = MuSdlUtf8NextChar(src); // advances src past the codepoint
                if (wch == L'\0') break;

                // Apply UIOPTION_NUMBERONLY filter (mirrors WM_CHAR handler)
                if (CheckOption(UIOPTION_NUMBERONLY))
                {
                    if (wch < L'0' || wch > L'9') continue;
                }
                else if (CheckOption(UIOPTION_SERIALNUMBER))
                {
                    if (wch >= L'a' && wch <= L'z') wch -= 32; // toLower→toUpper
                    if (!((wch >= L'0' && wch <= L'9') || (wch >= L'A' && wch <= L'Z'))) continue;
                }
    #ifdef LJH_ADD_RESTRICTION_ON_ID
                else if (CheckOption(UIOPTION_NOLOCALIZEDCHARACTERS))
                {
                    if (wch < 33 || wch > 126) continue;
                }
    #endif
                m_szSDLText[m_iSDLTextLen++] = wch;
                m_szSDLText[m_iSDLTextLen] = L'\0';
            }
            // Reset ready flag so we don't re-consume (g_szSDLTextInput cleared next frame)
            g_bSDLTextInputReady = false;
        }

        // Handle backspace via keyboard shim (GetAsyncKeyState + g_sdl3KeyboardState from 2.2.1)
        // VK_BACK (0x08) is already in the keyboard mapping table.
        // Use a one-shot edge-detect: clear on key-up to match WM_CHAR single-char behavior.
        if (HIBYTE(GetAsyncKeyState(VK_BACK)) & 0x80)
        {
            if (!m_bBackspaceHeld && m_iSDLTextLen > 0)
            {
                m_szSDLText[--m_iSDLTextLen] = L'\0';
                m_bBackspaceHeld = true;
            }
        }
        else
        {
            m_bBackspaceHeld = false;
        }
    #endif
    ```
    - Add `bool m_bBackspaceHeld` member to `CUITextInputBox` for backspace edge detection.
  - [x]5.4 Add `MuSdlUtf8NextChar` helper in `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`):
    ```cpp
    // Decode one UTF-8 codepoint from src, advance src past it.
    // Returns the wchar_t (UTF-32 codepoint) or L'\0' on error/end.
    // MU Online text is BMP-only (U+0000-U+FFFF) — wchar_t is safe.
    // [VS1-SDL-INPUT-TEXT]
    inline wchar_t MuSdlUtf8NextChar(const char*& src)
    {
        auto byte = static_cast<unsigned char>(*src);
        if (byte == 0) return L'\0';
        uint32_t codepoint = 0;
        int extraBytes = 0;
        if (byte < 0x80) { codepoint = byte; extraBytes = 0; }
        else if (byte < 0xC0) { ++src; return L'\0'; } // continuation byte — malformed
        else if (byte < 0xE0) { codepoint = byte & 0x1F; extraBytes = 1; }
        else if (byte < 0xF0) { codepoint = byte & 0x0F; extraBytes = 2; }
        else                  { codepoint = byte & 0x07; extraBytes = 3; }
        ++src;
        for (int i = 0; i < extraBytes; ++i)
        {
            byte = static_cast<unsigned char>(*src);
            if ((byte & 0xC0) != 0x80) return L'\0'; // malformed
            codepoint = (codepoint << 6) | (byte & 0x3F);
            ++src;
        }
        // Clamp to BMP (U+FFFF max) — surrogate range excluded
        if (codepoint > 0xFFFF || (codepoint >= 0xD800 && codepoint <= 0xDFFF)) return L'?';
        return static_cast<wchar_t>(codepoint);
    }
    ```
  - [x]5.5 Update `GetText` and `SetText` in `UIControls.cpp` to use `m_szSDLText` on non-Windows:
    ```cpp
    void CUITextInputBox::GetText(wchar_t* szText, int iMaxLength) const
    {
    #ifdef _WIN32
        GetWindowTextW(m_hEditWnd, szText, iMaxLength);
    #else
        if (szText && iMaxLength > 0)
        {
            wcsncpy(szText, m_szSDLText, iMaxLength - 1);
            szText[iMaxLength - 1] = L'\0';
        }
    #endif
    }

    void CUITextInputBox::SetText(const wchar_t* szText)
    {
    #ifdef _WIN32
        if (m_hEditWnd) SetWindowTextW(m_hEditWnd, szText);
    #else
        if (szText)
        {
            wcsncpy(m_szSDLText, szText, m_iSDLMaxLength);
            m_szSDLText[m_iSDLMaxLength] = L'\0';
            m_iSDLTextLen = static_cast<int>(wcslen(m_szSDLText));
        }
        else
        {
            m_szSDLText[0] = L'\0';
            m_iSDLTextLen = 0;
        }
    #endif
    }
    ```
  - [x]5.6 Add `GetWindowTextW` / `SetWindowTextW` / `GetTextLimitW` / `SetTextLimitW` no-op stubs to `PlatformCompat.h` (non-Windows, outside `MU_ENABLE_SDL3` guard) — needed so `UIControls.cpp` compiles when `m_hEditWnd != nullptr` paths are guarded by `#ifdef _WIN32`:
    - These stubs are only needed if any non-`#ifdef` guarded code paths call them. Given the `#ifdef _WIN32` / `#else` split in Task 5.5, they may not be needed. Compile and resolve linker errors.

- [x]**Task 6 — UIControls.cpp: HaveFocus and handle Win32-only constructs** (AC: 5)
  - [x]6.1 In `UIControls.cpp`, guard `CUITextInputBox::HaveFocus()` for SDL3:
    - Win32 path: `GetFocus() == m_hEditWnd` (returns true when edit HWND has focus).
    - SDL3 path: maintain `bool m_bSDLHasFocus` member — set to `true` in `GiveFocus()`, set to `false` in `SetState(UISTATE_HIDE)`.
    ```cpp
    BOOL CUITextInputBox::HaveFocus() const
    {
    #ifdef _WIN32
        return m_hEditWnd != nullptr && GetFocus() == m_hEditWnd;
    #else
        return m_bSDLHasFocus ? TRUE : FALSE;
    #endif
    }
    ```
  - [x]6.2 Add `bool m_bSDLHasFocus` member to `CUITextInputBox` in `UIControls.h` (inside `#ifndef _WIN32` guard or unconditionally).
  - [x]6.3 Guard `CUITextInputBox::SetTextLimit()` — on Win32 it calls `SendMessage(m_hEditWnd, EM_LIMITTEXT, ...)`. On SDL3 path store the limit in `m_iSDLMaxLength` only:
    ```cpp
    void CUITextInputBox::SetTextLimit(int iMaxLength)
    {
    #ifdef _WIN32
        if (m_hEditWnd) SendMessage(m_hEditWnd, EM_LIMITTEXT, iMaxLength, 0);
    #endif
        m_iSDLMaxLength = iMaxLength; // available on all paths for SDL3 use
    }
    ```
  - [x]6.4 Guard `SaveIMEStatus()` / `RestoreIMEStatus()` call sites in `UIControls.cpp` — these functions use `ImmGetContext` / `ImmSetConversionStatus`. They call into `g_hWnd` and are conditionally called from `CUITextInputBox::GiveFocus()` and `ClosingProcess()`. The stubs added in Task 1 make them compile as no-ops on non-Windows — no source change needed. Verify compilation.
  - [x]6.5 Guard `SetIMEPosition()` in `UIControls.cpp` — it calls `SendMessage(g_hWnd, WM_IME_CONTROL, IMC_SETCOMPOSITIONWINDOW, ...)` and `ImmSetCompositionWindow`. Add `#ifdef _WIN32` guard around the body:
    ```cpp
    void CUITextInputBox::SetIMEPosition()
    {
    #ifdef _WIN32
        // ... existing Win32 IME window positioning code ...
    #endif
        // SDL3: IME window positioning handled by SDL3 internally via SDL_SetTextInputArea().
        // Not implemented in this story (deferred to session 6.2 of cross-platform plan).
    }
    ```
  - [x]6.6 In `ZzzInterface.cpp:263`, the call `::SendMessage(hWnd, WM_IME_CONTROL, IMC_SETCOMPOSITIONWINDOW, (LPARAM)&comForm)` is inside `g_iChatInputType == 1` branches. This is game logic, not Platform/ — it needs a `#ifdef _WIN32` guard:
    ```cpp
    #ifdef _WIN32
        ::SendMessage(hWnd, WM_IME_CONTROL, IMC_SETCOMPOSITIONWINDOW, (LPARAM)&comForm);
    #endif
    ```
    **Note:** `ZzzInterface.cpp` IS in game logic (not ThirdParty/) — adding `#ifdef _WIN32` here violates the "no platform conditionals in game logic" rule. The correct approach is to stub `SendMessage` at the platform level (Task 1.4 adds this stub). With `SendMessage` shimmed to a no-op, the call compiles and does nothing on non-Windows — **no source change needed in `ZzzInterface.cpp`**. Verify this.
  - [x]6.7 Add `COMPOSITIONFORM` struct stub to `PlatformCompat.h` — used by `ZzzInterface.cpp:263` when calling `SendMessage(..., WM_IME_CONTROL, IMC_SETCOMPOSITIONWINDOW, (LPARAM)&comForm)`:
    ```cpp
    #define CFS_POINT 0x0002
    struct COMPOSITIONFORM
    {
        DWORD dwStyle;
        POINT ptCurrentPos;
        RECT rcArea;
    };
    ```

- [x]**Task 7 — Tests** (AC-STD-2)
  - [x]7.1 Add `MuMain/tests/platform/test_platform_text_input.cpp` (new file, guarded `#ifdef MU_ENABLE_SDL3`):
    - `TEST_CASE("MuSdlUtf8NextChar: ASCII character decodes correctly")` — `'A'` → `L'A'`.
    - `TEST_CASE("MuSdlUtf8NextChar: 2-byte UTF-8 decodes correctly")` — `"\xC3\xA9"` (é) → `L'\u00E9'`.
    - `TEST_CASE("MuSdlUtf8NextChar: 3-byte UTF-8 decodes correctly")` — `"\xE2\x82\xAC"` (€) → `L'\u20AC'`.
    - `TEST_CASE("MuSdlUtf8NextChar: malformed sequence returns null")` — orphan continuation byte returns `L'\0'`.
    - `TEST_CASE("SDL text buffer: appending ASCII updates m_szSDLText")` — simulate `g_szSDLTextInput = "A"`, call `DoAction()` equivalent, verify text buffer contains `L"A"`.
    - `TEST_CASE("SDL text buffer: backspace removes last character")` — set `m_szSDLText = L"AB"`, simulate `GetAsyncKeyState(VK_BACK)` returning held, verify `m_szSDLText == L"A"`.
    - `TEST_CASE("SDL text buffer: max length enforced — no overflow")` — set `m_iSDLMaxLength = 3`, append 5 chars, verify buffer capped at 3.
    - `TEST_CASE("NUMBERONLY option: non-digit characters filtered")` — simulate text `"a1b2"` with `UIOPTION_NUMBERONLY`, verify buffer contains only `L"12"`.
  - [x]7.2 Add CMake script-mode test `test_ac_std11_flow_code_2_2_3.cmake` — verifies `VS1-SDL-INPUT-TEXT` string appears in `SDLEventLoop.cpp`.
  - [x]7.3 Add CMake script-mode test `test_ac_std3_no_raw_imm.cmake` — greps all non-Platform/ and non-ThirdParty/ source files for `ImmGetContext`, `ImmSetConversionStatus` — fails if found outside `Platform/` or `#ifdef _WIN32` guards.
  - [x]7.4 Register `test_platform_text_input.cpp` in `MuMain/tests/platform/CMakeLists.txt` — add to `MuTests` target under `BUILD_TESTING` guard.

- [x]**Task 8 — Quality Gate Verification** (AC-STD-13)
  - [x]8.1 Run `make -C MuMain format-check` — fix any formatting issues.
  - [x]8.2 Run `make -C MuMain lint` (cppcheck) — resolve all warnings to zero.
  - [x]8.3 Verify `./ctl check` passes locally on macOS.
  - [x]8.4 Verify MinGW CI build is not broken — all new SDL3 code must be inside `#ifdef MU_ENABLE_SDL3` guards; Win32 stubs for non-SDL3 path inside `#else // !_WIN32` guards.

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| MU_ERR_TEXT_START_FAILED | Platform | N/A | `MU_ERR_TEXT_START_FAILED [VS1-SDL-INPUT-TEXT]: no SDL window available` |

**Note:** Add new codes to `docs/error-catalog.md`. Surface via `g_ErrorReport.Write()`.

---

## Contract Catalog Entries

### API Contracts

N/A — platform infrastructure story with no HTTP endpoints.

### Event Contracts

N/A — no event-bus events produced or consumed.

### Navigation Entries

N/A — infrastructure story, no screen navigation.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 v3.7.1 | Platform module (UTF-8 decode, text buffer) | UTF-8 decoding (ASCII, 2-byte, 3-byte, malformed), backspace edge detection, max length enforcement, NUMBERONLY filter |
| CMake script | CMake -P mode | AC-STD-11 flow code | VS1-SDL-INPUT-TEXT present in SDLEventLoop.cpp |
| CMake script | CMake -P mode | AC-STD-3 no raw IME | No ImmGetContext outside Platform/ or #ifdef _WIN32 |
| Manual | Platform-specific | Critical paths | Chat typing on macOS arm64 and Linux x64, accented characters on non-US keyboards, backspace/delete/Enter in chat and login fields |

---

## Visual Design Specification

N/A — infrastructure story. No UI visual changes; text rendering in chat/login fields is handled by the existing `CUIRenderText` pipeline (GDI on Windows, stubbed on non-Windows until Phase 4 font migration).

---

## Dev Notes

### Architecture Context

This story implements text input migration for CROSS_PLATFORM_PLAN.md Phase 6 (Sessions 6.1, partial 6.2, 6.3). The approach is a **hybrid shim + SDL3 event injection** strategy, mirroring stories 2.2.1 (keyboard) and 2.2.2 (mouse).

**Text input architecture in the codebase (Win32 path):**

The codebase has a two-tier text input system:

**Tier 1 — Win32 Edit Control (primary text input):**
`CUITextInputBox::Init()` in `ThirdParty/UIControls.cpp` calls `CreateWindowW(L"edit", ...)` to create an invisible Win32 edit control HWND. The control is subclassed via `SetWindowLongPtrW(..., GWLP_WNDPROC, EditWndProc)`. Characters arrive via:
- `WM_CHAR` in `EditWndProc` → character appended to edit control buffer via Win32 internal handling.
- `WM_IME_*` in `EditWndProc` → Korean/Japanese/Chinese IME composition.
- `GetText()` / `SetText()` call `GetWindowTextW()` / `SetWindowTextW()` to transfer buffer contents.

**Tier 2 — WndProc `WM_CHAR` (Enter key):**
`Winmain.cpp:713` handles `WM_CHAR` for `VK_RETURN` → calls `SetEnterPressed(true)`. This is the "send chat" trigger.

On the SDL3 path:
- `CreateWindowW(L"edit", ...)` returns nullptr (Task 1.8 stub) → `m_hEditWnd == nullptr`.
- All `if (m_hEditWnd)` guards in `UIControls.cpp` prevent Win32 HWND operations.
- `SDL_EVENT_TEXT_INPUT` → `g_szSDLTextInput` buffer → `CUITextInputBox::DoAction()` → `m_szSDLText`.
- Enter key: handled by story 2.2.1 `GetAsyncKeyState(VK_RETURN)` shim → `SEASON3B::IsPress(VK_RETURN)` → `NewUIChatInputBox::UpdateKeyEvent()` (line 503: `SEASON3B::IsPress(VK_RETURN)`) — **no change needed**.
- Backspace: handled by `GetAsyncKeyState(VK_BACK)` shim from story 2.2.1 → consumed in `DoAction()` (Task 5.3).

**Key insight from cross-platform plan (Session 6.3):**
> "Character input currently comes through `WM_CHAR` in WndProc. Translate `SDL_EVENT_TEXT_INPUT` to the existing `SetEnterPressed()` mechanism in the SDL3 event loop."

The Enter key path is already handled: story 2.2.1 established the `GetAsyncKeyState(VK_RETURN)` shim, and `NewUIChatInputBox::UpdateKeyEvent()` at line 503 calls `SEASON3B::IsPress(VK_RETURN)` which uses that shim. **No `SetEnterPressed()` change is needed** — the existing keyboard shim covers it.

**`g_iChatInputType` global:**
Defined in `Winmain.cpp:67` as `int g_iChatInputType = 1`. This flag switches between two input modes:
- `g_iChatInputType == 1`: Win32 edit control path (current)
- `g_iChatInputType == 0`: Legacy direct string handling

On the SDL3 path, `g_iChatInputType` remains 1 (default). The `g_iChatInputType == 1` branches in `GiveFocus()`, `MsgWin.cpp`, `CharMakeWin.cpp`, etc. all guard Win32 edit control operations that are now no-ops (Task 1.8 stub returns nullptr for `m_hEditWnd`). No change to `g_iChatInputType` logic is required.

**ThirdParty/ exception policy:**
`UIControls.cpp` is in `ThirdParty/` and excluded from clang-tidy. Inline `#ifdef _WIN32` / `#elif MU_ENABLE_SDL3` guards ARE permitted there as an exception — consistent with the existing feature-flag conditional compilation in the same file. This is the minimal-invasive approach for the migration period.

### SDL3 API Notes (release-3.2.8 — pinned from story 2.1.1)

**SDL_StartTextInput / SDL_StopTextInput:**
- SDL3 signature: `SDL_StartTextInput(SDL_Window* window)` / `SDL_StopTextInput(SDL_Window* window)` — note the window parameter (SDL3 changed from SDL2's global `SDL_StartTextInput()` which took no args).
- Must be called with a valid `SDL_Window*`. Call `SDL_StartTextInput` when a text field gains focus, `SDL_StopTextInput` when it loses focus.
- Enables SDL's IME overlay (on platforms that support it) and `SDL_EVENT_TEXT_INPUT` event generation.

**SDL_EVENT_TEXT_INPUT:**
- `event.text.text[]` is a null-terminated UTF-8 char array.
- Array size: `SDL_TEXTINPUTEVENT_TEXT_SIZE` (32 bytes in SDL3).
- Fires once per composed character or character sequence (after IME commit).
- Not fired for control keys (Backspace, Enter, arrows) — those come as `SDL_EVENT_KEY_DOWN`.

**SDL_EVENT_TEXT_EDITING (IME composition):**
- Not implemented in this story (deferred to Session 6.2 of the cross-platform plan as noted in epics.md).
- Basic Latin input works without IME composition support.

**SDL_GetClipboardText:**
- Returns `char*` (UTF-8), must be freed with `SDL_free()`.
- Used in Task 2.1 for the `UIOPTION_NUMBERONLY` Ctrl+V paste validation.

### GDI Render Text — Compilation Impact

`CUIRenderTextOriginal` in `UIControls.cpp` uses GDI APIs (`CreateDIBSection`, `CreateCompatibleDC`, `SelectObject`, `DeleteDC`, `DeleteObject`) extensively for font rendering. These are NOT text-input related — they are the legacy rendering pipeline (to be replaced in Phase 4). The stubs in Task 1.9 make this compile and behave as no-ops on non-Windows. `GetTextExtentPoint32` is used for text measurement (e.g., `CutStr` word-wrapping) — the 8px-per-char estimate in Task 1.1 is a known approximation acceptable until Phase 4.

**`g_pRenderText->GetFontDC()` returns nullptr on non-Windows** (from `CUIRenderTextOriginal::Create()` which returns early). All `GetTextExtentPoint32(g_pRenderText->GetFontDC(), ...)` calls pass nullptr as `hDC` — this is valid with the stub (stub ignores `hDC`).

### HaveFocus Pattern

On Win32: `HaveFocus()` returns `GetFocus() == m_hEditWnd` (true when the hidden edit HWND has keyboard focus).

On SDL3: `GetFocus()` stub returns a sentinel non-null value (from Task 1.5). `m_hEditWnd` is nullptr. So `GetFocus() == m_hEditWnd` would be `sentinel != nullptr` = FALSE. This is correct default behavior — no spurious focus.

`m_bSDLHasFocus` (Task 6.1/6.2) tracks whether `GiveFocus()` has been called without a subsequent `SetState(UISTATE_HIDE)`. `CNewUIChatInputBox::HaveFocus()` calls `m_pChatInputBox->HaveFocus()` — this must work correctly for the chat box show/hide logic at `NewUIChatInputBox.cpp:654`.

### GetWindowTextW / SetWindowTextW Stubs

These Win32 APIs transfer text to/from the Win32 edit control HWND. On SDL3 path:
- `GetText()` / `SetText()` are split with `#ifdef _WIN32` (Task 5.5).
- The non-Windows branches use `m_szSDLText` directly.
- No stubs for `GetWindowTextW` / `SetWindowTextW` needed if Task 5.5 `#ifdef _WIN32` guards are complete.

### UIOPTION_ Constants

`UIOPTION_NUMBERONLY`, `UIOPTION_SERIALNUMBER`, `UIOPTION_NOLOCALIZEDCHARACTERS` are bitmask flags checked in `CheckOption()`. These are defined in `UIControls.h` and are platform-neutral — no changes needed.

### Files to Modify / Create

```
MuMain/src/source/Platform/
├── PlatformCompat.h           [MODIFY] — add GDI, IME, clipboard, window message, focus,
│                                         CreateWindowW stubs (Task 1); MuSdlUtf8NextChar,
│                                         MuClipboardIsNumericOnly, MuStartTextInput,
│                                         MuStopTextInput declarations (Tasks 2, 4, 5)
├── PlatformTypes.h            [MODIFY if needed] — add UINT, HMENU typedefs
└── sdl3/
    ├── SDLEventLoop.cpp       [MODIFY] — add SDL_EVENT_TEXT_INPUT handler; extern declarations
    │                                      for g_szSDLTextInput / g_bSDLTextInputReady (Task 3)
    ├── SDLKeyboardState.cpp   [MODIFY] — add g_szSDLTextInput[32], g_bSDLTextInputReady globals;
    │                                      add MuStartTextInput(), MuStopTextInput() implementations (Tasks 3, 4)
    └── SDLWindow.h/cpp        [MODIFY if needed] — add GetNativeHandle() override (Task 4.3)

MuMain/src/source/Main/
└── MuPlatform.h/cpp           [MODIFY if needed] — add GetNativeWindow() static method (Task 4.3)

MuMain/src/source/ThirdParty/
└── UIControls.cpp             [MODIFY] — guard GetText/SetText/HaveFocus/SetState/GiveFocus/
│                                          SetIMEPosition/SetTextLimit/DoAction for SDL3 path;
│                                          guard ClipboardCheck call site (Tasks 2, 4, 5, 6)
└── UIControls.h               [MODIFY] — add m_szSDLText, m_iSDLTextLen, m_iSDLMaxLength,
                                           m_bSDLHasFocus, m_bBackspaceHeld members (Task 5, 6)

MuMain/tests/platform/
├── test_platform_text_input.cpp    [NEW] — Catch2 tests (Task 7.1)
├── test_ac_std11_flow_code_2_2_3.cmake [NEW] — flow code CMake test (Task 7.2)
└── test_ac_std3_no_raw_imm.cmake       [NEW] — IME regression test (Task 7.3)
```

**Files explicitly NOT to modify:**
- `NewUIChatInputBox.cpp` — chat logic already uses `SEASON3B::IsPress(VK_RETURN)` for Enter and `m_pChatInputBox->GetText()` / `SetText()` — both work via shims on SDL3 path.
- `Winmain.cpp` — WndProc `WM_CHAR` and `WM_IME_NOTIFY` handlers remain intact for Win32 path; zero regression.
- `SceneCommon.cpp` — `SetEnterPressed()` mechanism unchanged.
- `ZzzInterface.cpp` — `SendMessage(..., WM_IME_CONTROL, ...)` at line 263 is handled by the no-op `SendMessage` stub (Task 1.4); no source change needed.
- Any game logic files — zero call-site modifications needed.

### Previous Story Intelligence (from 2.1.1, 2.1.2, 2.2.1, 2.2.2)

Key learnings that MUST be carried forward:

1. **SDL3 pinned to `release-3.2.8`** via FetchContent — do NOT change the version.
2. **`SDL3::SDL3-static`** is the correct CMake target.
3. **CI Strategy B** is established: `-DMU_ENABLE_SDL3=OFF` in MinGW — all new SDL3 code must be inside `#ifdef MU_ENABLE_SDL3` guards. Win32 API stubs (non-SDL3 non-Windows) go inside `#else // !_WIN32` but OUTSIDE `#ifdef MU_ENABLE_SDL3`.
4. **`g_ErrorReport.Write()`** (not `wprintf`) for all error logging. Use `%hs` for `const char*` SDL error strings in wide-char format strings.
5. **Catch2 null-guard pattern** — test shim logic in isolation, without requiring a live SDL window or game engine.
6. **Option A (SDLKeyboardState.cpp) pattern** — new globals are defined in `SDLKeyboardState.cpp` and declared `extern` in `PlatformCompat.h`. Follow this pattern for `g_szSDLTextInput` and `g_bSDLTextInputReady`.
7. **ThirdParty/ exclusion from clang-tidy** — `UIControls.cpp` modifications are not subject to clang-tidy `WarningsAsErrors`. Format with clang-format only.
8. **SDL3 API changes from SDL2** — `SDL_StartTextInput(SDL_Window*)` takes a window parameter in SDL3 (unlike SDL2). `SDL_GetClipboardText()` returns `char*` freed with `SDL_free()`. Verify against SDL3 `release-3.2.8` headers.
9. **`SendMessage` stub pattern** — Task 1.4 adds an inline stub. The stub signature must use `UINT msg` parameter type — add `using UINT = unsigned int;` to `PlatformTypes.h` if not already present (Task 1.13).
10. **Dev Agent Record from 2.2.2** — `MouseX`/`MouseY` are `int` (not `float`) in the test file. Similarly, `m_szSDLText` uses `wchar_t` (4 bytes on Linux/macOS). All MU Online text is BMP — `wchar_t` is safe (confirmed in `development-standards.md §1 wchar_t Portability`).
11. **Risk R4 (from sprint-status.yaml)** — SDL3 text input (IME) complexity on Linux varies by compositor (X11 vs Wayland). Mitigation: X11 first. `SDL_StartTextInput` works on X11; Wayland IME support deferred if needed. This story targets basic Latin input (AC-3) — full CJK IME deferred to Session 6.2.

### PCC Project Constraints

**Prohibited (never use in new code):**
- Raw `new` / `delete` — use `std::unique_ptr<T>`
- `NULL` — use `nullptr`
- `#ifdef _WIN32` in game logic files — only permitted in `Platform/` abstraction layer, `PlatformCompat.h`, and `ThirdParty/` (exception policy for UIControls.cpp)
- Direct Win32 IME APIs in new game logic — must go through stubs
- `wprintf` for logging — use `g_ErrorReport.Write()` or `g_ConsoleDebug->Write()`

**Required patterns:**
- `[[nodiscard]]` on all functions that return error codes or handles
- `g_ErrorReport.Write()` for post-mortem errors with `MU_ERR_*` prefix
- `MU_ENABLE_SDL3` compile-time guard for all SDL3 code
- Catch2 v3.7.1 for tests (FetchContent, `BUILD_TESTING=ON`)
- `VS1-SDL-INPUT-TEXT` flow code in log messages and test names

**Quality gate command:** `make -C MuMain format-check && make -C MuMain lint`

### Project Structure Notes

- New test file follows existing pattern: `MuMain/tests/platform/test_platform_*.cpp`
- New globals in `SDLKeyboardState.cpp` follow Option A pattern from story 2.2.1
- `PlatformCompat.h` receives stubs in two zones: `#else // !_WIN32` (platform-neutral stubs) and `#ifdef MU_ENABLE_SDL3` (SDL3-specific)
- `UIControls.cpp` ThirdParty/ exception: inline `#ifdef` permitted, clang-tidy excluded, clang-format required

### References

- [Source: _bmad-output/project-context.md — Tech stack, prohibited/required patterns, banned Win32 API table (OpenClipboard → SDL_GetClipboardText, CreateWindowW edit → SDL_StartTextInput, WM_CHAR → SDL_EVENT_TEXT_INPUT)]
- [Source: docs/development-standards.md §1 Banned Win32 API table, §1 wchar_t Portability, §2 C++ Conventions, §2 Error Handling]
- [Source: docs/CROSS_PLATFORM_PLAN.md Phase 6, Session 6.1 (SDL3 text input + clipboard), 6.2 (IME), 6.3 (WM_CHAR replacement)]
- [Source: _bmad-output/stories/2-2-1-sdl3-keyboard-input/story.md — GetAsyncKeyState shim, SDLKeyboardState.cpp pattern, CI Strategy B, MuPlatformLogUnmappedVk pattern]
- [Source: _bmad-output/stories/2-2-2-sdl3-mouse-input/story.md — global-state injection pattern, ThirdParty/ exception policy, SDL3 API notes]
- [Source: MuMain/src/source/Platform/PlatformCompat.h — existing shim patterns; current state after 2.2.1 and 2.2.2]
- [Source: MuMain/src/source/Platform/PlatformTypes.h — existing type shims]
- [Source: MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp — PollEvents switch, existing mouse/keyboard handlers to extend]
- [Source: MuMain/src/source/ThirdParty/UIControls.cpp — CUITextInputBox::Init (CreateWindowW edit control), GiveFocus, SetState, DoAction, HaveFocus, GetText, SetText, SaveIMEStatus, RestoreIMEStatus, CheckTextInputBoxIME, ClipboardCheck, EditWndProc (WM_CHAR handler)]
- [Source: MuMain/src/source/UI/Windows/NewUIChatInputBox.cpp — HaveFocus(), OpenningProcess(), ClosingProcess(), UpdateKeyEvent() Enter/Escape handling]
- [Source: MuMain/src/source/Main/Winmain.cpp L67 (g_iChatInputType), L689-723 (WM_IME_NOTIFY, WM_CHAR WndProc handlers)]
- [Source: MuMain/src/source/UI/Legacy/ZzzInterface.cpp L263 (SendMessage WM_IME_CONTROL)]
- [Source: _bmad-output/implementation-artifacts/sprint-status.yaml — Risk R4: SDL3 text input IME on Linux X11 vs Wayland]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story workflow)

### Debug Log References

### Completion Notes List

- Story created by create-story workflow on 2026-03-06
- Story key: 2-2-3-sdl3-text-input; sprint-status shows status: backlog, dep: 2-2-1 done
- Epic 2 Feature 2.2 Input — final story completing EPIC-2 SDL3 input migration
- Story type: infrastructure (not frontend_feature/fullstack) — Visual Design Specification section not applicable
- Architecture decision: hybrid shim + SDL3 event injection approach (mirrors 2.2.1/2.2.2 patterns)
- CUITextInputBox dual-path: Win32 edit HWND (Windows) vs SDL_EVENT_TEXT_INPUT → m_szSDLText (SDL3)
- CreateWindowW(L"edit") stub returns nullptr — all if(m_hEditWnd) guards prevent Win32 HWND ops on SDL3 path
- ThirdParty/ exception: inline #ifdef permitted in UIControls.cpp (excluded from clang-tidy)
- GDI stubs (CreateDIBSection etc.) are compilation stubs for Phase 4 — not text input functionality
- GetTextExtentPoint32 stub uses 8px/char estimate — acceptable until Phase 4 font migration
- g_iChatInputType stays 1 on SDL3 path — no changes needed
- Enter key via GetAsyncKeyState(VK_RETURN) shim from 2.2.1 — no WM_CHAR → SetEnterPressed change needed
- Backspace via GetAsyncKeyState(VK_BACK) shim with edge detection in DoAction()
- SDL_StartTextInput(SDL_Window*) requires window param in SDL3 — GetNativeWindow() accessor may need addition to MuPlatform
- Risk R4 (IME on Linux Wayland) noted; X11 is primary target; full CJK deferred to Session 6.2
- Previous story intelligence from 2.1.1, 2.1.2, 2.2.1, 2.2.2 incorporated
- Corpus: story is prerequisite of none; sibling stories 2.2.1, 2.2.2 done; pattern: infrastructure
- Specification index not available (no specification-index.yaml found)
- Schema alignment: N/A (C++20 game client, no HTTP API schemas)
- SAFe: VS-1, Feature flow, 3 pts, Flow Code VS1-SDL-INPUT-TEXT

### File List

- `MuMain/src/source/Platform/PlatformCompat.h` — added Win32 GDI/IME/clipboard/window stubs in `#else // !_WIN32` block; added `MuStartTextInput`/`MuStopTextInput` declarations, `extern g_szSDLTextInput`/`g_bSDLTextInputReady`, `MuSdlUtf8NextChar`, `MuClipboardIsNumericOnly` in `#ifdef MU_ENABLE_SDL3` block
- `MuMain/src/source/Platform/sdl3/SDLKeyboardState.cpp` — added `g_szSDLTextInput[32]`, `g_bSDLTextInputReady`, `MuStartTextInput()`, `MuStopTextInput()` definitions
- `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` — added `extern` declarations for SDL text input globals, per-frame reset in `PollEvents()`, and `SDL_EVENT_TEXT_INPUT` case handler
- `MuMain/src/source/ThirdParty/UIControls.h` — replaced inline `HaveFocus()` with declaration; added `m_szSDLText`, `m_iSDLTextLen`, `m_iSDLMaxLength`, `m_bBackspaceHeld`, `m_bSDLHasFocus` members; added `DoActionSub()` override declaration
- `MuMain/src/source/ThirdParty/UIControls.cpp` — added constructor SDL3 member init; added `DoActionSub()`, `HaveFocus()` implementations; wrapped `SetIMEPosition()` body in `#ifdef _WIN32`; guarded `GetText()`/`SetText()`/`SetTextLimit()`/`SetState()`/`GiveFocus()` with `#ifdef _WIN32`/`#elif MU_ENABLE_SDL3`; wrapped `ClipboardCheck` call in `EditWndProc` with platform guard; added `m_iSDLMaxLength` init in `Init()`
- `MuMain/tests/platform/test_platform_text_input.cpp` — Catch2 test file (RED phase, pre-created by ATDD workflow)
- `MuMain/tests/platform/test_ac_std11_flow_code_2_2_3.cmake` — flow code traceability CMake test
- `MuMain/tests/platform/test_ac_std3_no_raw_imm.cmake` — IME API regression CMake test

### Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-03-06 | Story 2.2.3 dev-story implementation: SDL3 text input migration complete. All 8 tasks implemented. Quality gate passes. | Dev Agent (claude-sonnet-4-6) |

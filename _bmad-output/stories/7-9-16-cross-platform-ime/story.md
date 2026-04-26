# Story 7-9-16: Cross-Platform IME via SDL3

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-16 |
| **Title** | Cross-Platform IME Support via SDL3 SetTextInputArea + TEXT_EDITING |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-1 (Core Experience) |
| **Flow Type** | Feature |
| **Flow Code** | VS1-INPUT-IME-SDL3 |
| **Story Points** | 5 |
| **Dependencies** | 7-9-9 (sdl3-text-input-forms, done), 7-9-10 (sdl-ttf-text-input-rendering, done) |
| **Status** | ready-for-dev |

---

## User Story

**As a** Korean / Japanese / Chinese player using the game's text input boxes (chat, login, character name, guild name),
**I want** IME composition (input-method-editor preview, candidate window positioning, commit) to work correctly on macOS, Linux, and Windows,
**So that** I can type in my native language without the game silently dropping IME state or rendering the candidate window in the wrong location.

---

## Background

### Problem

The original game implements IME composition window positioning via Win32 IMM API (`ImmGetContext`, `ImmGetCompositionWindow`, `ImmSetCompositionWindow`, `ImmGetCompositionString`, `ImmReleaseContext`). On the SDL3 path these are stubs in `Platform/PlatformCompat.h:540-578,1710` that return `nullptr`/`FALSE`. **IME composition is silently broken on macOS and Linux** — basic English typing works (SDL3's `SDL_EVENT_TEXT_INPUT` covers it) but composition for CJK languages does not.

The block at `UIControls.cpp:3624-3656` documents this explicitly:

```cpp
#ifdef _WIN32
    // ... 30 lines of Win32 IMM positioning code ...
#endif
    // SDL3: IME window positioning handled by SDL3 internally via SDL_SetTextInputArea().
    // Not implemented in this story (deferred to Session 6.2 of cross-platform plan).
```

This is the deferred work.

### Call sites in scope

**Unguarded (cross-platform code calling Win32 stubs — silent feature loss):**

| Site | File:Line | Purpose |
|---|---|---|
| Guild create | `UI/Legacy/ZzzInterface.cpp:273` | `ImmGetContext` for composition setup |
| Guild rename | `UI/Legacy/ZzzInterface.cpp:288` | Same |
| Login form | `UI/Legacy/ZzzInterface.cpp:311` | Same |
| Character delete confirm | `UI/Legacy/ZzzInterface.cpp:361` | Same |
| Character creation | `Scenes/CharacterScene.cpp:125` | `ImmGetContext` for character-name IME |

**Guarded by `#ifdef _WIN32` (legitimate Windows-only code that must be rewritten as cross-platform):**

| Site | File:Line | Purpose |
|---|---|---|
| `CUITextInputBox::SetCompositionWindow` | `ThirdParty/UIControls.cpp:3624-3656` | Position composition window relative to caret |
| `CUITextInputBox::GetCompositionString` | `ThirdParty/UIControls.cpp:3232-...` | Retrieve composing text |
| Other UIControls IME blocks | `ThirdParty/UIControls.cpp:3240,3256,3278,3638,4272,4366` | Composition state queries |

### Target API

SDL3 provides:

- `SDL_StartTextInput(SDL_Window*)` / `SDL_StopTextInput(SDL_Window*)` — toggle IME activation
- `SDL_SetTextInputArea(SDL_Window*, const SDL_Rect*, int cursor)` — position the candidate/composition window
- `SDL_EVENT_TEXT_EDITING` — composition-in-progress preview text
- `SDL_EVENT_TEXT_INPUT` — committed text (already wired in `SDLEventLoop.cpp` for English path)

The CUITextInputBox already has `m_bSDLHasFocus` and `m_szSDLText`; this story adds composition-state members and routes SDL3 IME events through them.

---

## Functional Acceptance Criteria

- [ ] **AC-1: Composition area set on focus.** When a `CUITextInputBox` gains focus, it calls `SDL_SetTextInputArea(g_pSDLWindow, &caretRect, 0)` with a rect that matches the current caret position in pixel coordinates. Verify by checking that the composition candidate window appears anchored to the caret on macOS/Linux/Windows (not in a corner or off-screen).
- [ ] **AC-2: Composition preview rendered.** While IME is composing, `SDL_EVENT_TEXT_EDITING` events are routed to the focused `CUITextInputBox` and the composition string is rendered (with underline / different color, matching the original Win32 behavior) in the input box.
- [ ] **AC-3: Commit on TEXT_INPUT.** When `SDL_EVENT_TEXT_INPUT` fires, the committed text is appended to `m_szSDLText` and the composition preview is cleared.
- [ ] **AC-4: Win32 IMM call sites deleted.** All `ImmGetContext`, `ImmReleaseContext`, `ImmGetCompositionWindow`, `ImmSetCompositionWindow`, `ImmGetCompositionString`, `ImmGetDefaultIMEWnd` call sites are deleted (both unguarded and inside `#ifdef _WIN32` blocks). The `#ifdef _WIN32` blocks at `UIControls.cpp:3624-3656`, `:3232-...`, `:3638`, etc. are removed entirely; the SDL3 path becomes unconditional.
- [ ] **AC-5: PlatformCompat.h IME stubs deleted.** `ImmGetContext`, `ImmReleaseContext`, `ImmGetCompositionWindow`, `ImmSetCompositionWindow`, `ImmGetCompositionString`, `ImmGetDefaultIMEWnd` declarations and stub bodies removed from `PlatformCompat.h`. Plus the `Platform/compat-headers/imm.h` shim is removed.
- [ ] **AC-6: Manual integration test on each platform.** Tester types `"안녕하세요"` (Korean) into login username field on macOS, Linux, Windows. Composition preview renders inline; final commit appears as expected. Repeat with Japanese (`"こんにちは"`) and Simplified Chinese (`"你好"`).

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance
- [ ] **AC-STD-2:** Catch2 unit tests for IME state machine (composition start → editing events → commit). Manual cross-platform validation for visual placement.
- [ ] **AC-STD-13:** Quality Gate passes
- [ ] **AC-STD-15:** Git Safety

---

## Tasks / Subtasks

- [ ] Task 1: Wire `SDL_SetTextInputArea` on focus (AC: 1)
  - [ ] 1.1: Add `CUITextInputBox::SyncCompositionRect()` that computes pixel-coord caret rect and calls `SDL_SetTextInputArea`
  - [ ] 1.2: Call from focus-gain path in `CUITextInputBox::Update()` or focus-event handler
- [ ] Task 2: Route TEXT_EDITING events (AC: 2)
  - [ ] 2.1: Add `m_szCompositionText` + `m_iCompositionCursorPos` members
  - [ ] 2.2: Handle `SDL_EVENT_TEXT_EDITING` in `SDLEventLoop.cpp` — find focused input box, write composition string
  - [ ] 2.3: Render composition preview in `CUITextInputBox::Render()` with underline/color distinction
- [ ] Task 3: Commit on TEXT_INPUT (AC: 3)
  - [ ] 3.1: Existing `SDL_EVENT_TEXT_INPUT` handler clears `m_szCompositionText` after appending to `m_szSDLText`
- [ ] Task 4: Delete Win32 IMM call sites (AC: 4)
  - [ ] 4.1: Delete unguarded callers in `ZzzInterface.cpp:273,288,311,361` and `CharacterScene.cpp:125`
  - [ ] 4.2: Delete all `#ifdef _WIN32 ... #endif` blocks in `UIControls.cpp` that contain IMM calls (lines 3232-..., 3624-3656, 3638, 4272, 4366)
- [ ] Task 5: Delete PlatformCompat.h IME stubs (AC: 5)
  - [ ] 5.1: Remove declarations + bodies from `PlatformCompat.h:540-578,1710`
  - [ ] 5.2: Remove `Platform/compat-headers/imm.h` (now unused)
- [ ] Task 6: Cross-platform manual test (AC: 6)
  - [ ] 6.1: Korean IME on macOS, Linux, Windows
  - [ ] 6.2: Japanese IME on macOS, Linux, Windows
  - [ ] 6.3: Simplified Chinese IME on macOS, Linux, Windows

---

## Dev Notes

### Why this is feature work, not deletion

Unlike most of 7-9-5's siblings (which delete dead/redundant code), this story implements net-new SDL3 functionality that the project has been deferring. The TODO comment at `UIControls.cpp:3657` ("deferred to Session 6.2 of cross-platform plan") becomes resolved.

### Out of scope

- IME activation gating (`g_bIMEBlock` global) — that's a separate concern about *when* IME is allowed to compose; this story is about *where/how*.
- Per-language fallback fonts — SDL_ttf font selection for CJK is owned by 7-9-8.

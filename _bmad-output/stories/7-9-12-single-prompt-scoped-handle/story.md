# Story 7-9-12: Scoped Acquisition Handle for Single Prompt Input Box

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-12 |
| **Title** | Scoped Acquisition Handle for Single Prompt Input Box |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-1 (Core Experience) |
| **Flow Type** | Refactor |
| **Flow Code** | VS1-INPUT-PROMPT-RAII |
| **Story Points** | 3 |
| **Dependencies** | 7-9-11 (`Configure` + `InputBoxConfig`) |
| **Status** | ready-for-dev |

---

## User Story

**As a** developer adding a new modal text prompt to the game client,
**I want** a scoped acquisition handle that takes the single-prompt input box, configures it, and releases it automatically,
**So that** I cannot forget to reset state between users of the shared singleton and cannot leak focus, caret, or stale text into the next consumer of the slot.

---

## Background

### Problem

`g_pSingleTextInputBox` and `g_pSinglePasswdInputBox` (`MuMain.cpp:69-70`) are process-wide singletons reused by login, delete-character confirm, MU helper, guild master, in-game shop, and every other modal text prompt. Story 7-9-11 gives every `CUITextInputBox` a `Configure(const InputBoxConfig&)` method that eliminates the multi-line init ritual. But for the **singletons specifically**, a second, orthogonal class of bug remains: ownership across modal transitions.

Recurring bug family:

- **Text leakage** — `CMsgWin::InitResidentNumInput` has a defensive `SetText(NULL)` because the previous prompt's text would otherwise render in the field (`MsgWin.cpp:527-530`).
- **Focus leakage** — `CMsgWin::ManageCancelClick` has to explicitly `SetText(NULL) + SetState(UISTATE_HIDE)` on a cancelled prompt because otherwise `IsAnyInputBoxFocused()` keeps the singleton focused and in-game hotkeys stay suppressed (`MsgWin.cpp:500-506`).
- **Two-singleton choice** — `g_pSingleTextInputBox` vs. `g_pSinglePasswdInputBox` differ only by the password flag. Every caller picks the right one manually. 7-9-11 adds runtime `SetIsPassword(bool)`, making this separation unnecessary.

`Configure()` alone does not solve these — it fixes initialization, not teardown.

### Target Pattern

```cpp
{
    auto prompt = SinglePrompt::Acquire({
        .size      = { 70, 14 },
        .pos       = { ptOrigin.x + 38, ptOrigin.y },
        .textLimit = 20,
        .password  = true,            // runtime toggle — no two-singleton choice
    });

    // ...prompt is driven per-frame by the window holding the handle...
    std::wstring entered = prompt.Text();

}   // destructor: Reset() the singleton, release focus
```

Callers cannot forget a reset because there is no multi-step teardown to forget. The handle's destructor is the single point of truth.

---

## Acceptance Criteria

### AC-1: Single active prompt invariant enforced
- Only one `SinglePrompt` handle may be alive at a time.
- Acquiring a second handle while the first is live asserts loudly in debug (log + assertion) and gracefully releases the prior handle in release (prior destructor semantics run).
- **Testable:** unit test — acquire once, attempt second acquisition, verify debug-assert fires and release build does not leak focus.

### AC-2: Acquisition applies a known-clean baseline then the config
- On acquire: `Reset()` on the underlying singleton, then `Configure(cfg)`. No blending with prior state.
- **Testable:** unit test — pre-dirty the singleton (`SetText(L"leftover")`, `SetOption(UIOPTION_NUMBERONLY)`), acquire a new handle with no options in the config, verify the box is empty and option is `UIOPTION_NULL`.

### AC-3: Destruction restores the singleton to hidden, empty, unfocused
- When the handle goes out of scope, the singleton: state = `UISTATE_HIDE`, text = empty, option = `UIOPTION_NULL`, focus released (so `IsAnyInputBoxFocused()` no longer reports it).
- **Testable:** unit test — acquire, type text, let handle destruct, verify `GetState() == UISTATE_HIDE`, `GetText()` empty, `IsAnyInputBoxFocused()` false.

### AC-4: `Config::password` replaces the dual-singleton pattern
- `InputBoxConfig::password` from 7-9-11 drives masking per acquisition, not per allocation.
- `g_pSingleTextInputBox` and `g_pSinglePasswdInputBox` collapse into a single internal `std::unique_ptr<CUITextInputBox>` owned by the `SinglePrompt` module.
- **Testable:** unit test — acquire with `password=true`, verify `IsPassword()` true; release; acquire with `password=false`, verify `IsPassword()` false; underlying object identity is the same.

### AC-5: Text snapshot API survives early destruction
- `prompt.Text()` returns the current text without side-effects. A caller may capture `prompt.Text()` into a `std::wstring` and safely use it after the handle destructs.
- **Testable:** unit test — acquire, set text via mock input, capture into wstring, destruct handle, verify wstring still holds the value.

### AC-6: All singleton call sites migrated
- Every file currently using `g_pSingleTextInputBox` or `g_pSinglePasswdInputBox` uses `SinglePrompt` instead.
- The `extern` declarations in `UIControls.h` are deleted.
- The two globals and their `new`/`SAFE_DELETE` blocks in `MuMain.cpp` are deleted.
- **Testable:** grep for `g_pSingleTextInputBox` / `g_pSinglePasswdInputBox` returns zero hits.

### AC-7: Handle is movable, not copyable
- `SinglePrompt(SinglePrompt&&)` and `operator=(SinglePrompt&&)` transfer ownership.
- Copy constructor and copy-assignment are deleted — a single active handle is the invariant.
- **Testable:** compile-time test — `static_assert(!std::is_copy_constructible_v<SinglePrompt>)` passes.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project naming conventions (PascalCase functions, m_ members)
- [ ] **AC-STD-NFR-1:** Quality gate passes (`./ctl check` — format + lint)
- [ ] **AC-STD-2:** Unit tests cover AC-1 through AC-7
- [ ] **AC-STD-3:** No raw `new` / `delete` — use `std::unique_ptr` for the internal box

---

## Technical Notes

### New Type

```cpp
// UIControls.h (or SinglePrompt.h next to it)
class SinglePrompt {
public:
    [[nodiscard]] static SinglePrompt Acquire(const InputBoxConfig& cfg);

    SinglePrompt(SinglePrompt&&) noexcept;
    SinglePrompt& operator=(SinglePrompt&&) noexcept;
    SinglePrompt(const SinglePrompt&) = delete;
    SinglePrompt& operator=(const SinglePrompt&) = delete;
    ~SinglePrompt();

    [[nodiscard]] std::wstring Text() const;
    void                       SetText(const std::wstring& text);
    void                       GiveFocus();
    [[nodiscard]] bool         IsFocused() const;
    void                       Render();                      // per-frame render
    void                       UpdateWhileActive(double dt);  // per-frame SDL text capture

private:
    SinglePrompt();
    bool m_owning = false;  // transferred on move
};

// Module-private (in UIControls.cpp or SinglePrompt.cpp):
// - static std::unique_ptr<CUITextInputBox> s_promptBox;
// - static bool s_acquired;
```

### Migration Examples

**Before (`MsgWin.cpp:521-532` + `:496-506` cancel teardown):**
```cpp
// Init
if (g_iChatInputType == 1) {
    g_pSinglePasswdInputBox->SetState(UISTATE_NORMAL);
    g_pSinglePasswdInputBox->SetOption(UIOPTION_NULL);
    g_pSinglePasswdInputBox->SetBackColor(0, 0, 0, 0);
    g_pSinglePasswdInputBox->SetTextLimit(20);
    g_pSinglePasswdInputBox->SetText(NULL);
    g_pSinglePasswdInputBox->GiveFocus();
}
// ...
// Cancel teardown
if (m_nMsgCode == MESSAGE_DELETE_CHARACTER_RESIDENT && g_iChatInputType == 1 &&
    g_pSinglePasswdInputBox != nullptr) {
    g_pSinglePasswdInputBox->SetText(NULL);
    g_pSinglePasswdInputBox->SetState(UISTATE_HIDE);
}
```

**After** (post 7-9-11 `Configure` and this story's `SinglePrompt`):
```cpp
// CMsgWin holds a std::optional<SinglePrompt> m_prompt member.
if (g_iChatInputType == 1) {
    m_prompt = SinglePrompt::Acquire({
        .pos       = { int((m_sprInput.GetXPos() + 10) / g_fScreenRate_x),
                       int((m_sprInput.GetYPos() + 8)  / g_fScreenRate_y) },
        .textLimit = 20,
        .password  = true,
    });
    m_prompt->GiveFocus();
}
// Cancel teardown: just reset the optional.
m_prompt.reset();
```

The ~7 lines of init + ~5 lines of cancel teardown collapse to one `Acquire` and one `reset`. The compiler guarantees the teardown runs even on exceptions or early returns.

### Call Sites To Migrate (11 files)

Same list as 7-9-11 *singleton* row — after 7-9-11 these sites already use `Configure` against the raw globals. This story rewrites them to use `SinglePrompt::Acquire(cfg)` instead, and deletes the globals entirely.

### Risks

- `CMsgWin` and other windows currently hold raw references to the singleton and expect it to stay alive for the whole modal. Migrating to `std::optional<SinglePrompt>` member requires the window to own the handle for the modal lifetime. If the window object outlives the prompt (e.g. hidden but not destroyed), the optional is reset on hide.
- `IsAnyInputBoxFocused()` continues to walk the class-level `s_pFocusedInputBox`. The handle's destructor must invoke the path that clears that pointer (currently `SetState(UISTATE_HIDE)` via `Reset()`).
- Single-active invariant: if two windows try to open modals at once, the second acquisition must win loudly. A design choice: assert (helps catch UI bugs) vs. queue (preserves UX). Recommend assert + log in debug, last-writer-wins in release.

---

## Out of Scope

- Multi-prompt (simultaneous text prompts) — game UI is modal, not needed.
- Per-window input boxes owned by e.g. `CUILetterWriteWindow` — not singletons, already scoped to their window's lifetime, covered by 7-9-11.
- Replacing `CUITextInputBox` internals.

---

## Dev Notes

### Implementation Approach

1. Create `SinglePrompt.h` / `SinglePrompt.cpp` (or inline in `UIControls.*`). File-static `std::unique_ptr<CUITextInputBox> s_promptBox` + `bool s_acquired`.
2. In `MuMain.cpp` startup, call `SinglePrompt::InitSingleton(g_hWnd)` which does the single `new CUITextInputBox + Init(hWnd, 200, 14, MAX_TEXT_LENGTH, FALSE)`. Replace the current two separate init blocks.
3. `Acquire()` asserts `!s_acquired`, calls `Reset()` + `Configure(cfg)` on the box, sets `s_acquired = true`, returns a `SinglePrompt` with `m_owning = true`.
4. Destructor: if `m_owning`, call `Reset()` on the box, set `s_acquired = false`.
5. Migrate the 11 sites one at a time. After each, verify `./ctl check`. Only delete `g_pSingleTextInputBox` / `g_pSinglePasswdInputBox` and their `new`/`SAFE_DELETE` lines when the last site is migrated.
6. Delete the two externs from `UIControls.h` (added in MuMain `4a67bd68`) as the final step of AC-6.

### PCC Project Constraints

- No raw `new`/`delete` — `std::unique_ptr` for the underlying box
- `[[nodiscard]]` on `Acquire`, `Text`, `IsFocused`
- Quality gate: `./ctl check`

### References

- [Story 7-9-11: Configure + InputBoxConfig](../7-9-11-input-box-configure-struct/story.md) — prerequisite
- [Story 7-9-9: Text input forms](../7-9-9-sdl3-text-input-forms/story.md)
- [Story 7-9-10: SDL_ttf input rendering](../7-9-10-sdl-ttf-text-input-rendering/story.md)
- MuMain `4a67bd68` — `Reset()` + centralized externs (the baseline this story builds on)
- MuMain `8f886cb1` — `WriteText` OOB fix (same singleton-reuse bug family)

---

## Dev Agent Record

### Implementation Plan
_(to be filled during dev-story)_

### Debug Log
_(to be filled during dev-story)_

### Completion Notes
_(to be filled during dev-story)_

---

## File List

| File | Status | Change |
|------|--------|--------|
| `ThirdParty/UIControls.h` | MODIFY | Add `SinglePrompt` class; delete `g_pSingleTextInputBox`/`g_pSinglePasswdInputBox` externs |
| `ThirdParty/UIControls.cpp` | MODIFY | Add `SinglePrompt` implementation + file-static `std::unique_ptr<CUITextInputBox>` |
| `Main/MuMain.cpp` | MODIFY | Delete both globals + init + `SAFE_DELETE`; call `SinglePrompt::InitSingleton(g_hWnd)` at startup and `Shutdown()` at teardown |
| `Scenes/LoginScene.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `Scenes/SceneCore.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `Scenes/CharacterScene.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `UI/Legacy/MsgWin.cpp` | MODIFY | Migrate to `SinglePrompt`; delete cancel-path teardown block |
| `UI/Legacy/CharMakeWin.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `UI/Legacy/ZzzInterface.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `UI/Legacy/UIGuildMaster.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `UI/Legacy/UIPopup.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `UI/Legacy/UIWindows.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `Gameplay/Items/ZzzInventory.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `Network/WSclient.cpp` | MODIFY | Migrate to `SinglePrompt` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-04-19 | Story created as the second half of the original 7-9-11 split. 7-9-11 covers the Configure refactor applicable to every input box; this story covers the singleton-specific RAII handle that builds on it. |

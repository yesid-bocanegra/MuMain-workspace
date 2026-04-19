# Story 7-9-11: Scoped Acquisition Handle for Single Prompt Input Box

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-11 |
| **Title** | Scoped Acquisition Handle for Single Prompt Input Box |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-1 (Core Experience) |
| **Flow Type** | Refactor |
| **Flow Code** | VS1-INPUT-PROMPT-RAII |
| **Story Points** | 5 |
| **Dependencies** | 7-9-9 (text input forms) ✓, 7-9-10 (SDL_ttf input rendering) |
| **Status** | ready-for-dev |

---

## User Story

**As a** developer adding a new modal text prompt to the game client,
**I want** a scoped acquisition handle that takes the single-prompt input box, configures it, and releases it automatically,
**So that** I cannot forget to reset state between users of the shared singleton and cannot leak focus, caret, or stale text into the next consumer of the slot.

---

## Background

### Problem

`g_pSingleTextInputBox` and `g_pSinglePasswdInputBox` (`MuMain.cpp:69-70`) are process-wide singletons reused by login, delete-character confirm, MU helper, guild master, in-game shop, and every other modal text prompt. Each feature mutates the singleton in place — position, text limit, back color, option flags, text — and is individually responsible for clearing that state when done.

This has produced a recurring bug family:

- **Text leakage** — `CMsgWin::InitResidentNumInput` now has a defensive `SetText(NULL)` with an inline comment explaining that the previous prompt's text would otherwise render in the field (`MsgWin.cpp:527-530`).
- **Focus leakage** — `CMsgWin::ManageCancelClick` has to explicitly `SetText(NULL) + SetState(UISTATE_HIDE)` on the cancelled prompt because otherwise `IsAnyInputBoxFocused()` keeps the singleton focused and in-game hotkeys stay suppressed (`MsgWin.cpp:500-506`).
- **Option leakage** — a prompt that last ran with `UIOPTION_NUMBERONLY` would silently reject letters on the next consumer if that consumer forgets `SetOption(UIOPTION_NULL)`.
- **Two-singleton choice** — `g_pSingleTextInputBox` vs. `g_pSinglePasswdInputBox` differ only by the password flag passed to `Init`. Every caller picks the right one manually; a third mode (email, CJK-disallow, clipboard-sealed) would add a third global.

### Current Pattern (to be replaced)

Every caller that acquires the singleton follows roughly this shape:

```cpp
g_pSinglePasswdInputBox->SetState(UISTATE_NORMAL);
g_pSinglePasswdInputBox->SetOption(UIOPTION_NULL);
g_pSinglePasswdInputBox->SetBackColor(0, 0, 0, 0);
g_pSinglePasswdInputBox->SetTextLimit(20);
g_pSinglePasswdInputBox->SetText(NULL);
g_pSinglePasswdInputBox->SetPosition(x, y);
g_pSinglePasswdInputBox->GiveFocus();

// ...user types, then:

g_pSinglePasswdInputBox->GetText(buf);
g_pSinglePasswdInputBox->SetText(NULL);
g_pSinglePasswdInputBox->SetState(UISTATE_HIDE);
```

Seven-line ritual on entry, three-line ritual on exit, repeated across 11 call sites. Stories 7-9-9 and 7-9-12 (the debug-break fix on 2026-04-19) both had a contributing root cause in "caller forgot step N."

### Target Pattern

```cpp
{
    auto prompt = SinglePrompt::Acquire({
        .kind       = SinglePrompt::Kind::Password,
        .pos        = { x, y },     // design-unit coordinates
        .textLimit  = 20,
        .backColor  = { 0, 0, 0, 0 },
    });

    // ...driven by UpdateWhileActive / Render, consumed at OK/Cancel:
    std::wstring entered = prompt.Text();

}   // destructor hides, clears, releases focus
```

Callers cannot forget a reset because there is no multi-step ritual to forget. The handle's destructor is the single point of truth for teardown.

---

## Acceptance Criteria

### AC-1: Single active prompt invariant enforced
- Only one `SinglePrompt` handle may be alive at a time.
- Acquiring a second handle while the first is live is a bug that must surface loudly in debug (log + assertion), and gracefully release the prior handle in release (prior destructor semantics run).
- **Testable:** unit test — acquire once, attempt second acquisition, verify debug-assert fires and release build does not leak focus.

### AC-2: Acquisition applies a known-clean baseline
- Before configuration is applied, the underlying input box is reset to a baseline: empty text, `UIOPTION_NULL`, default colors, `UISTATE_NORMAL`, no focus from a prior session.
- **Testable:** unit test — pre-dirty the singleton (`SetText(L"leftover")`, `SetOption(UIOPTION_NUMBERONLY)`), acquire a new handle with no text configured, verify the box is empty and option is `UIOPTION_NULL`.

### AC-3: Destruction restores the singleton to hidden, empty, unfocused
- When the handle goes out of scope, the singleton: state = `UISTATE_HIDE`, text = empty, option = `UIOPTION_NULL`, focus released (so `IsAnyInputBoxFocused()` no longer reports it).
- **Testable:** unit test — acquire, type text, let handle destruct, verify `GetState() == UISTATE_HIDE`, `GetText()` empty, `IsAnyInputBoxFocused()` false.

### AC-4: `Kind::Password` replaces the dual-singleton pattern
- `g_pSingleTextInputBox` and `g_pSinglePasswdInputBox` collapse into a single internal object driven by `SinglePrompt::Kind { Text, Password }`.
- Password masking (`*` glyphs) is enabled/disabled per acquisition, not per allocation.
- **Testable:** unit test — acquire with `Kind::Password`, verify `IsPassword()` true; release; acquire with `Kind::Text`, verify `IsPassword()` false; the object identity of the underlying box is the same.

### AC-5: Text snapshot API survives early destruction
- `prompt.Text()` returns the current text without side-effects. A caller may capture `prompt.Text()` into a `std::wstring` and safely use it after the handle destructs.
- **Testable:** unit test — acquire, set text via mock input, capture into wstring, destruct handle, verify wstring still holds the value.

### AC-6: All 11 existing call sites migrated
- Every file currently containing `extern CUITextInputBox* g_pSingleTextInputBox;` or `extern CUITextInputBox* g_pSinglePasswdInputBox;` uses `SinglePrompt` instead.
- The `extern` declarations are deleted.
- `g_pSingleTextInputBox` and `g_pSinglePasswdInputBox` are deleted from `MuMain.cpp`.
- **Testable:** grep for `g_pSingleTextInputBox` / `g_pSinglePasswdInputBox` returns zero hits.

### AC-7: DPI is handled at the boundary, not at the call site
- `SinglePrompt::Config::pos` is specified in design units (640×480 space). The handle applies `g_fScreenRate_x/y` internally before calling `SetPosition`.
- No call site contains `int((...x) / g_fScreenRate_x)`-style inverse-scale math.
- **Testable:** unit test — configure with design-unit `{100, 50}` at `g_fScreenRate_x = 1.6`, verify the underlying `SetPosition` is called with the expected physical-pixel coords.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project naming conventions (PascalCase functions, m_ members)
- [ ] **AC-STD-NFR-1:** Quality gate passes (`./ctl check` — format + lint)
- [ ] **AC-STD-2:** Unit tests cover AC-1 through AC-7
- [ ] **AC-STD-3:** No raw `new` / `delete` for the underlying input box lifecycle — use `std::unique_ptr`

---

## Technical Notes

### New Types

```cpp
// UIControls.h (or a new SinglePrompt.h next to it)
class SinglePrompt {
public:
    enum class Kind { Text, Password };

    struct Config {
        Kind                    kind        = Kind::Text;
        POINT                   pos         = { 0, 0 };     // design units
        int                     textLimit   = 20;
        COLORREF                backColor   = RGB(0, 0, 0);
        BYTE                    backAlpha   = 0;
        DWORD                   option      = UIOPTION_NULL;
        HFONT                   font        = nullptr;      // nullptr = g_hFixFont default
    };

    [[nodiscard]] static SinglePrompt Acquire(const Config& cfg);

    SinglePrompt(SinglePrompt&&) noexcept;
    SinglePrompt& operator=(SinglePrompt&&) noexcept;
    SinglePrompt(const SinglePrompt&) = delete;
    SinglePrompt& operator=(const SinglePrompt&) = delete;
    ~SinglePrompt();

    [[nodiscard]] std::wstring Text() const;
    void                       SetText(const std::wstring& text);
    void                       GiveFocus();
    [[nodiscard]] bool         IsFocused() const;
    void                       Render();                    // drives per-frame rendering
    void                       UpdateWhileActive(double dt);// drives SDL text input capture

private:
    SinglePrompt();
    struct Impl;
    std::unique_ptr<Impl>      m_impl;
};
```

### Migration Examples

**Before (`MsgWin.cpp:521-532`):**
```cpp
if (g_iChatInputType == 1) {
    g_pSinglePasswdInputBox->SetState(UISTATE_NORMAL);
    g_pSinglePasswdInputBox->SetOption(UIOPTION_NULL);
    g_pSinglePasswdInputBox->SetBackColor(0, 0, 0, 0);
    g_pSinglePasswdInputBox->SetTextLimit(20);
    g_pSinglePasswdInputBox->SetText(NULL);
    g_pSinglePasswdInputBox->GiveFocus();
}
```

**After:**
```cpp
if (g_iChatInputType == 1) {
    m_prompt = SinglePrompt::Acquire({
        .kind      = SinglePrompt::Kind::Password,
        .pos       = { int((m_sprInput.GetXPos() + 10) / g_fScreenRate_x),
                       int((m_sprInput.GetYPos() + 8)  / g_fScreenRate_y) },
        .textLimit = 20,
    });
    m_prompt.GiveFocus();
}
```

On cancel, the `CMsgWin` destructor or an explicit `m_prompt = {};` reassignment triggers the singleton teardown — no seven-line ritual.

### Call Sites To Migrate (11 files)

| File | Line(s) | Variant |
|------|---------|---------|
| `Gameplay/Items/ZzzInventory.cpp` | 56 | Text |
| `Network/WSclient.cpp` | 87 | Text |
| `Scenes/LoginScene.cpp` | 38, 113-115 | Password |
| `Scenes/SceneCore.cpp` | 33-34 | both |
| `Scenes/CharacterScene.cpp` | 41 | Password |
| `UI/Legacy/UIPopup.cpp` | 12 | Text |
| `UI/Legacy/UIWindows.cpp` | 26 | Text |
| `UI/Legacy/MsgWin.cpp` | 28, 95-96, 157-159, 260, 502-505, 523-531, 539-541 | Password |
| `UI/Legacy/CharMakeWin.cpp` | 130 | Text |
| `UI/Legacy/ZzzInterface.cpp` | 58-59, 245-247 | both |
| `UI/Legacy/UIGuildMaster.cpp` | 19 | Text |

### What This Depends On

Story 7-9-12 (A + B — `CUITextInputBox::Reset()` + header-level externs) is a prerequisite checkpoint. This story builds on those: `Reset()` becomes the primitive the handle's destructor calls, and deleting the externs is the final cleanup step AC-6 enforces.

### Risks

- `CMsgWin` et al. currently hold raw references to the singleton as a member. Migrating to hold `SinglePrompt` as a member requires ownership to match the modal lifetime. If the window object outlives the modal interaction, the prompt needs to be a `std::optional<SinglePrompt>` that is populated and reset explicitly.
- `CUIMng` focus tracking (`IsAnyInputBoxFocused`) reads a global — it needs to continue working. The handle's destructor must call whatever function releases the global focus flag.

---

## Out of Scope

- Multi-prompt (simultaneous text prompts). Game UI is modal; this is not needed.
- Per-window input boxes owned by e.g. `CUILetterWriteWindow` (not singletons — already scoped).
- Replacing `CUITextInputBox` internals. This story only changes ownership / lifecycle; the input box class itself is unchanged beyond the `Reset()` method from 7-9-12.

---

## Dev Notes

### Implementation Approach

1. Add `SinglePrompt` class + implementation in `UIControls.h` / `UIControls.cpp` (or split into `SinglePrompt.h/.cpp`).
2. Internally hold a single `std::unique_ptr<CUITextInputBox>` as a file-static; `Kind` switches the password flag via `SetIsPassword()` (new trivial setter) rather than re-creating the box.
3. Implement `Acquire` as a factory that: checks no other handle is live (`s_isAcquired` flag), calls `Reset()` on the underlying box, applies `Config`, returns the handle.
4. Destructor: if `m_impl != nullptr`, call `Reset()` on the box, clear `s_isAcquired`.
5. Migrate call sites one at a time, verify build + quality gate after each file.
6. Delete the `extern` decls and the globals from `MuMain.cpp` only when all 11 sites are migrated.

### PCC Project Constraints

- No raw `new`/`delete` — use `std::unique_ptr`
- `[[nodiscard]]` on `Acquire`, `Text`, `IsFocused`
- No `#ifdef _WIN32` in game logic
- Quality gate: `./ctl check`

### References

- [Story 7-9-9: Text input forms](../7-9-9-sdl3-text-input-forms/story.md)
- [Story 7-9-10: SDL_ttf input rendering](../7-9-10-sdl-ttf-text-input-rendering/story.md)
- Commit 8f886cb1 (MuMain) — `CUITextInputBox::WriteText` bounds fix, same family of singleton-leakage bugs.
- `MuMain/src/source/Main/MuMain.cpp:69-70, 527-530, 637-638` — current singleton declaration, init, teardown

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
| `ThirdParty/UIControls.h` | MODIFY | Add `SinglePrompt` class declaration; remove `g_pSingleTextInputBox`/`g_pSinglePasswdInputBox` externs (added in 7-9-12) |
| `ThirdParty/UIControls.cpp` | MODIFY | Add `SinglePrompt` implementation + file-static `std::unique_ptr<CUITextInputBox>` |
| `Main/MuMain.cpp` | MODIFY | Delete the two globals + init + teardown; add one-line `SinglePrompt::InitSingleton()` at startup, `Shutdown()` at teardown |
| `Scenes/LoginScene.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `Scenes/SceneCore.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `Scenes/CharacterScene.cpp` | MODIFY | Migrate to `SinglePrompt` |
| `UI/Legacy/MsgWin.cpp` | MODIFY | Migrate to `SinglePrompt`; delete 7-line ritual + cancel-path teardown block |
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
| 2026-04-19 | Story created after CUITextInputBox::WriteText OOB fix (MuMain 8f886cb1) — diagnosed singleton-reuse pattern as ongoing bug source |

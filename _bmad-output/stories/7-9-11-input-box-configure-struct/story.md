# Story 7-9-11: Unified `CUITextInputBox::Configure` + Config Struct

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-11 |
| **Title** | Unified `CUITextInputBox::Configure` + `InputBoxConfig` Struct |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-1 (Core Experience) |
| **Flow Type** | Refactor |
| **Flow Code** | VS1-INPUT-CONFIG-STRUCT |
| **Story Points** | 5 |
| **Dependencies** | 7-9-9 (text input forms) ✓, 7-9-10 (SDL_ttf input rendering) |
| **Status** | ready-for-dev |

---

## User Story

**As a** developer wiring a `CUITextInputBox` (singleton or window-owned member),
**I want** a single `Configure(const InputBoxConfig&)` call that applies every initial setting atomically,
**So that** I cannot forget, reorder, or duplicate any of the 5+ setters today's init rituals require — and every call site (singleton prompts, per-window input boxes, chat boxes, shop notes) uses the same typed config.

---

## Background

### Problem

Every site that creates or reuses a `CUITextInputBox` hand-writes a 4–8 line init ritual mixing option bits, sizes, colors, text limits, fonts, and positions. A partial list:

| Site | Init ritual |
|------|-------------|
| `UIPopup.cpp:507-513` | `SetState` + `SetOption` + `SetBackColor` + `SetTextLimit` + `SetSize` + `SetPosition` + `GiveFocus` |
| `CharMakeWin.cpp:250-254` | `SetState` + `SetOption` + `SetBackColor` + `SetTextLimit` + `GiveFocus` (position separate at 220) |
| `UIGuildMaster.cpp:349-355` | Same 6 calls, different values |
| `MsgWin.cpp:523-531` | Same 6 calls + `SetText(NULL)` defensive clear |
| `NewUIMuHelper.cpp:442-470` | Per-box: `Init` + `SetPosition` + `SetTextColor` + `SetBackColor` + `SetFont` + `SetState` + `SetOption` + `SetText` |
| `NewUIGuildMakeWindow.cpp:~180` | `SetOption(UIOPTION_NOLOCALIZEDCHARACTERS)` + others |
| `UIWindows.cpp:1290, 2571-2593, 5079` | `CUILetterWriteWindow` MailTo/Title/Text boxes, each with its own ritual |

The rituals differ in which lines they include and in what order — which is how the `Reset()` partial-state leak family got in: someone forgot `SetText(NULL)`, someone forgot `SetOption(UIOPTION_NULL)`, someone reordered `SetState` vs. `GiveFocus`. The type system does not help.

Additionally, every `SetPosition` call at these sites performs its own `g_fScreenRate_x` / `g_fScreenRate_y` inverse-scale math — the same pattern that bit us in the `CUITextInputBox::WriteText` one-pixel OOB fix (MuMain `8f886cb1`).

### What This Story Changes

Introduce a typed config struct:

```cpp
struct InputBoxConfig {
    SIZE        size            = { 0, 0 };            // design units (640×480 space)
    POINT       pos             = { 0, 0 };            // design units; Configure applies DPI
    int         textLimit       = MAX_TEXT_LENGTH;
    DWORD       options         = UIOPTION_NULL;       // caller composes bits freely
    bool        password        = false;
    COLORREF    textColor       = RGB(0, 0, 0);
    BYTE        textAlpha       = 255;
    COLORREF    backColor       = RGB(0, 0, 0);
    BYTE        backAlpha       = 0;
    COLORREF    selectBackColor = RGB(255, 255, 255);
    BYTE        selectBackAlpha = 255;
    HFONT       font            = nullptr;             // nullptr = keep current font
    int         state           = UISTATE_NORMAL;
};

class CUITextInputBox {
public:
    // ...existing API...
    void Configure(const InputBoxConfig& cfg);
    void SetIsPassword(bool bIsPassword);              // new runtime toggle (was Init-only)
};
```

`Configure` applies every setting in the correct internal order (resize-before-position, option-before-state, font-before-text-limit), centralizing the knowledge of "what order to set things in" that is currently tribal.

### What This Story Does NOT Change

- The underlying setters (`SetOption`, `SetBackColor`, `SetTextLimit`, etc.) stay — `Configure` calls them. Callers may still use individual setters for incremental changes after initial configuration.
- The singleton wrappers (`g_pSingleTextInputBox`, `g_pSinglePasswdInputBox`) stay. Story 7-9-12 builds the RAII handle on top.
- Password masking lifecycle: today it's constructor-only (`Init(..., bIsPassword)`). This story adds a runtime setter `SetIsPassword(bool)` that `Configure` uses — required so that one underlying box can serve both text and password prompts (precondition for 7-9-12 singleton collapse).

---

## Acceptance Criteria

### AC-1: `Configure` applies every field deterministically
- Given an `InputBoxConfig` with all fields set to non-default values, one call to `Configure` results in a box whose `GetOption`, `GetTextLimit`, `IsPassword`, stored colors, font, and state all match.
- Successive `Configure` calls with different configs fully replace the prior configuration — no blending.
- **Testable:** unit test — apply `ConfigA`, verify state; apply `ConfigB`, verify state matches ConfigB, not a merge.

### AC-2: Order-insensitivity bugs are eliminated
- `Configure` internally orders operations so that: sizing runs before positioning, options run before state (so `UIOPTION_PAINTBACK` is live when `UISTATE_NORMAL` triggers the first render), font runs before text limit (so SDL_ttf metrics are valid).
- Callers do not need to know or preserve this order.
- **Testable:** unit test — construct a `Configure` call where fields are populated in config-struct declaration order; verify each internal setter invocation order by mocking or instrumenting.

### AC-3: DPI scaling happens at the boundary
- `InputBoxConfig::pos` and `InputBoxConfig::size` are specified in **design units** (the 640×480 coordinate space).
- `Configure` internally multiplies by `g_fScreenRate_x/y` before calling `SetPosition`/`SetSize`.
- No call site contains `int((... x) / g_fScreenRate_x)` inverse-scale math after migration.
- **Testable:** unit test — configure with `pos = { 100, 50 }` at `g_fScreenRate_x = 1.6`, verify `SetPosition` receives physical-pixel coords.

### AC-4: Password toggle works at runtime
- `SetIsPassword(bool)` exists and changes masking on subsequent renders.
- A box configured with `password=true`, then re-configured with `password=false`, displays its text in plain on the next render.
- **Testable:** unit test — `SetText(L"secret")` with password=true, verify mask; switch to password=false, verify plain text.

### AC-5: All 15+ init rituals are migrated to `Configure`
- Every site that currently does a multi-line `Set*` ritual on a `CUITextInputBox` instance (singleton or member) is replaced by one `Configure` call with an `InputBoxConfig`.
- Sites that only touch one setter incrementally (e.g. `SetText` as user types) are untouched.
- Post-migration grep count of multi-line init rituals drops by at least 90%.
- **Testable:** grep audit — `grep -cE "SetOption\(|SetTextLimit\(|SetBackColor\("` in game UI sources drops significantly; each remaining occurrence is justified (runtime state change, not init).

### AC-6: `Configure` composes with `Reset`
- Given a box mid-session, calling `Reset()` then `Configure(cfg)` yields exactly the state of `Configure` on a freshly constructed box.
- **Testable:** unit test — pre-dirty a box, `Reset`, `Configure(cfgA)`; compare to a fresh box after `Configure(cfgA)`; state must match.

### AC-7: No regressions in existing prompts
- Login username/password still types, masks, submits.
- MU Helper numeric delay fields still reject non-digits.
- Guild Make still rejects localized characters (`UIOPTION_NOLOCALIZEDCHARACTERS`).
- CUILetterWriteWindow still paints its background (`UIOPTION_PAINTBACK`).
- **Testable:** manual smoke test on macOS + existing integration tests pass.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project naming conventions (PascalCase functions, m_ members)
- [ ] **AC-STD-NFR-1:** Quality gate passes (`./ctl check` — format + lint)
- [ ] **AC-STD-2:** Unit tests cover AC-1 through AC-6
- [ ] **AC-STD-3:** No raw `new` / `delete`

---

## Technical Notes

### Design Decision: Struct Fields, Not Preset Enum

An earlier draft proposed `enum class Kind { Text, Password }` as the primary knob. That is wrong:

- Call sites combine `UIOPTION_NUMBERONLY | UIOPTION_ENTERIMECHKOFF` (`UIControls.cpp:4745`) — bitwise composition, not enum selection.
- `UIOPTION_NOLOCALIZEDCHARACTERS` is a **protocol-correctness requirement** for guild names (fixed-width Latin-1 on the wire), not a UX preset.
- Numeric inputs appear in both non-password (MU Helper delays) and password-masked (delete-character resident code) contexts — an enum would flatten a genuinely orthogonal axis.

Keep the config as independent fields that mirror the underlying setter surface. If common combinations emerge, add static factory helpers like `InputBoxConfig::ChatLine(...)` without baking them into the type system.

### Migration Examples

**Before (`NewUIMuHelper.cpp:442-450`):**
```cpp
m_DistanceTimeInput.Init(g_hWnd, 17, 15, MAX_NUMBER_DIGITS, false);
m_DistanceTimeInput.SetPosition(m_Pos.x + 142, m_Pos.y + 140);
m_DistanceTimeInput.SetTextColor(255, 0, 0, 0);
m_DistanceTimeInput.SetBackColor(255, 255, 255, 255);
m_DistanceTimeInput.SetFont(g_hFont);
m_DistanceTimeInput.SetState(UISTATE_NORMAL);
m_DistanceTimeInput.SetOption(UIOPTION_NUMBERONLY);
m_DistanceTimeInput.SetText(wsInitText);
```

**After:**
```cpp
m_DistanceTimeInput.Init(g_hWnd, 17, 15, MAX_NUMBER_DIGITS, false);
m_DistanceTimeInput.Configure({
    .size      = { 17, 15 },
    .pos       = { m_Pos.x + 142, m_Pos.y + 140 },
    .textLimit = MAX_NUMBER_DIGITS,
    .options   = UIOPTION_NUMBERONLY,
    .textColor = RGB(0, 0, 0),      .textAlpha = 255,
    .backColor = RGB(255, 255, 255), .backAlpha = 255,
    .font      = g_hFont,
});
m_DistanceTimeInput.SetText(wsInitText);
```

**Before (`UIGuildMaster.cpp:349-355`):**
```cpp
g_pSingleTextInputBox->SetState(UISTATE_NORMAL);
g_pSingleTextInputBox->SetOption(UIOPTION_NULL);
g_pSingleTextInputBox->SetBackColor(0, 0, 0, 0);
g_pSingleTextInputBox->SetTextLimit(8);
g_pSingleTextInputBox->SetSize(70, 14);
g_pSingleTextInputBox->SetPosition(ptOrigin.x + 38, ptOrigin.y);
g_pSingleTextInputBox->GiveFocus();
```

**After:**
```cpp
g_pSingleTextInputBox->Configure({
    .size      = { 70, 14 },
    .pos       = { ptOrigin.x + 38, ptOrigin.y },
    .textLimit = 8,
});
g_pSingleTextInputBox->GiveFocus();
```

### Call Sites To Migrate

Singleton sites (will be migrated again under 7-9-12 to the RAII handle; `Configure` is the interim step):
- `UIPopup.cpp`, `MsgWin.cpp`, `CharMakeWin.cpp`, `UIGuildMaster.cpp`, `ZzzInterface.cpp`, `SceneCore.cpp`, `LoginScene.cpp`, `CharacterScene.cpp`, `UIWindows.cpp`, `ZzzInventory.cpp`, `WSclient.cpp`

Window-owned member sites:
- `NewUIMuHelper.cpp` — 5 boxes (DistanceTime, Skill2Delay, Skill3Delay, Item, BuffTime)
- `UIWindows.cpp` — `CUILetterWriteWindow` (MailTo, Title, Text), `CUIChatInputBox`, others
- `NewUIGuildMakeWindow.cpp` — `m_EditBox`
- `MsgBoxIGSSendGift.cpp` — `m_IDInputBox`, `m_MessageInputBox`
- `MsgBoxIGSGiftStorageItemInfo.cpp` — `m_MessageInputBox`

Total estimate: ~25 `Configure` call sites replacing ~150 individual `Set*` lines.

### Risks

- Designated initializer syntax (`.size = {...}`) requires C++20. Project is on C++20 per CLAUDE.md, so OK.
- `SetIsPassword(bool)` toggling mid-session may expose state in the SDL3 rendering path that the constructor-only flag hid. Test by configuring password=true, typing, re-configuring password=false, verify text reveals.
- `Init(hWnd, w, h, limit, isPassword)` currently owns initial allocation. `Configure` sits after `Init`; it does not replace construction. Callers must still `Init` once per instance.

---

## Out of Scope

- Singleton-lifecycle invariants (single active prompt, RAII drop) — covered by story 7-9-12.
- SDL_ttf rendering changes — covered by 7-9-10.
- Adding new `UIOPTION_*` bits.
- Replacing `CUITextInputBox` with a new class.

---

## Dev Notes

### Implementation Approach

1. Add `InputBoxConfig` struct in `UIControls.h` near the `CUITextInputBox` class declaration.
2. Add `CUITextInputBox::Configure(const InputBoxConfig& cfg)` method. Body calls existing setters in fixed order: `SetFont` → `SetSize` → `SetPosition` (with DPI scale) → `SetIsPassword` → `SetTextLimit` → `SetOption` → `SetTextColor` → `SetBackColor` → `SetSelectBackColor` → `SetState`.
3. Add `SetIsPassword(bool)` setter flipping `m_bPasswordInput` and clearing relevant cached state.
4. Migrate call sites one cluster at a time (singletons first, then MU Helper, then letter-write, etc.); verify `./ctl check` after each cluster.
5. Audit grep for `SetOption(` / `SetBackColor(` call counts before and after to confirm the ritual-density drop AC-5 requires.

### PCC Project Constraints

- C++20 designated initializers required (already in use elsewhere)
- `[[nodiscard]]` not meaningful on `Configure` (void, side-effecting)
- Quality gate: `./ctl check`

### References

- [Story 7-9-9: Text input forms](../7-9-9-sdl3-text-input-forms/story.md)
- [Story 7-9-10: SDL_ttf input rendering](../7-9-10-sdl-ttf-text-input-rendering/story.md)
- [Story 7-9-12: SinglePrompt scoped handle](../7-9-12-single-prompt-scoped-handle/story.md) — depends on this story
- MuMain `4a67bd68` — added `Reset()` + centralized externs (the baseline this story builds on)
- MuMain `8f886cb1` — `WriteText` OOB fix; same DPI-math class of bug this story eliminates at init sites

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
| `ThirdParty/UIControls.h` | MODIFY | Add `InputBoxConfig` struct; declare `Configure()` and `SetIsPassword()` on `CUITextInputBox` |
| `ThirdParty/UIControls.cpp` | MODIFY | Implement `Configure()` + `SetIsPassword()`; apply DPI scaling internally |
| `UI/Windows/Character/NewUIMuHelper.cpp` | MODIFY | Migrate 5 input-box init rituals to `Configure` |
| `UI/Legacy/UIWindows.cpp` | MODIFY | Migrate `CUILetterWriteWindow`, `CUIChatInputBox`, others to `Configure` |
| `UI/Windows/Social/NewUIGuildMakeWindow.cpp` | MODIFY | Migrate `m_EditBox` init to `Configure` |
| `GameShop/MsgBoxIGSSendGift.cpp` | MODIFY | Migrate ID + message inputs |
| `GameShop/MsgBoxIGSGiftStorageItemInfo.cpp` | MODIFY | Migrate message input |
| `UI/Legacy/UIPopup.cpp` | MODIFY | Migrate singleton init ritual |
| `UI/Legacy/MsgWin.cpp` | MODIFY | Migrate delete-character prompt init |
| `UI/Legacy/CharMakeWin.cpp` | MODIFY | Migrate character-name prompt init |
| `UI/Legacy/UIGuildMaster.cpp` | MODIFY | Migrate guild input init |
| `UI/Legacy/ZzzInterface.cpp` | MODIFY | Migrate chat input + others |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-04-19 | Story created after design review of the original 7-9-11 split the RAII-handle work (now 7-9-12) from the broader Configure refactor — Configure applies to every CUITextInputBox site, the RAII handle applies only to the singletons |

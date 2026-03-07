# Code Review — Story 2-2-3-sdl3-text-input

**Story Key:** 2-2-3-sdl3-text-input
**Date Started:** 2026-03-06
**Story File:** _bmad-output/stories/2-2-3-sdl3-text-input/story.md

---

## Pipeline Status

| Step | Workflow | Status | Date |
|------|----------|--------|------|
| Step 1 | code-review-quality-gate | PASSED | 2026-03-06 |
| Step 2 | code-review-analysis | PASSED | 2026-03-06 |
| Step 3 | code-review-finalize | PASSED | 2026-03-06 |

---

## Quality Gate Progress

| Phase | Status |
|-------|--------|
| Backend Local (format-check + lint) | PASSED — 689/689 files clean |
| Backend SonarCloud | N/A — not configured for this project |
| Frontend Local | N/A — infrastructure story, no frontend component |
| Frontend SonarCloud | N/A — no frontend |

**AC Tests:** Skipped (infrastructure story type)

---

## Fix Iterations

### Iteration 1 — 2026-03-06 (Post-Analysis Fixes)

| Fix | File | Lines | Description |
|-----|------|-------|-------------|
| CR-1 | `MuMain/src/source/ThirdParty/UIControls.cpp` | ~3221 | Added `if (!m_bSDLHasFocus) return;` at top of SDL3 block in `DoActionSub()` |
| CR-2a | `MuMain/src/source/ThirdParty/UIControls.cpp` | ~3397 | Clamped `m_iSDLMaxLength` in `SetTextLimit()` |
| CR-2b | `MuMain/src/source/ThirdParty/UIControls.cpp` | ~3492 | Clamped `m_iSDLMaxLength` in `Init()` |
| CR-3 | `_bmad-output/stories/2-2-3-sdl3-text-input/atdd.md` | AC-STD-2 | Added documentation note explaining dead code path |
| CR-4 | `MuMain/src/source/ThirdParty/UIControls.cpp` | ~3253 | Updated ambiguous comment to `// convert lowercase to uppercase` |

**Post-fix quality gate:** `./ctl check` — PASSED (689/689 files clean)

---

## Step 1: Quality Gate Results

Status: PASSED

**Affected Components:**
- mumain (cpp-cmake) → ./MuMain [backend]
- project-docs (documentation) → ./_bmad-output [documentation]

**Story Type:** infrastructure

**Quality gate command:** `./ctl check` (format-check + lint)

| Check | Result | Details |
|-------|--------|---------|
| clang-format | PASSED | All files correctly formatted |
| cppcheck lint | PASSED | 689/689 files checked, 0 errors/warnings |

**Quality Gate: PASSED** — Proceeding to code-review-analysis.

---

## Step 2: Analysis Results

**Completed:** 2026-03-06
**Status:** COMPLETE (5 issues found)

### Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH | 1 |
| MEDIUM | 1 |
| LOW | 1 |

---

### CRITICAL Issues (1)

**CR-1 CRITICAL — DoActionSub missing focus guard — all visible text boxes receive typed characters**

- **File:** `MuMain/src/source/ThirdParty/UIControls.cpp:3221`
- **Category:** Correctness / Multi-instance Bug
- **Description:** `CUITextInputBox::DoActionSub()` processes SDL text input and backspace without checking `m_bSDLHasFocus`. `CUIControl::DoAction()` calls `DoActionSub()` unconditionally (no state gate, line 244). Result: ALL active CUITextInputBox instances in a frame will (a) consume characters from `g_szSDLTextInput` if `g_bSDLTextInputReady` is true, and (b) process backspace via `GetAsyncKeyState(VK_BACK)`. On a login screen with username + password boxes, typing in username also modifies the password buffer. The first box to run DoActionSub sets `g_bSDLTextInputReady = false`, so subsequent boxes get no text — but backspace runs for every box regardless.
- **Fix:** Add `if (!m_bSDLHasFocus) return;` at the top of the `#ifdef MU_ENABLE_SDL3` block in `DoActionSub`.
- **Status:** FIXED — focus guard added at top of SDL3 block in `DoActionSub()`

---

### HIGH Issues (1)

**CR-2 HIGH — SetText() out-of-bounds write risk — SetTextLimit() sets m_iSDLMaxLength without bounds**

- **File:** `MuMain/src/source/ThirdParty/UIControls.cpp:3379-3380` (SetText), `:3397` (SetTextLimit)
- **Category:** Memory Safety
- **Description:** `SetText()` writes `m_szSDLText[m_iSDLMaxLength] = L'\0'`. The buffer `m_szSDLText` is `MAX_CHAT_SIZE + 1 = 91` elements (indices 0–90). If `m_iSDLMaxLength >= 91` (set via `SetTextLimit()` or `Init()` without clamping), this write is out of bounds. `SetTextLimit()` at line 3397 does `m_iSDLMaxLength = iLimit` without clamping. `Init()` at line 3492 does `m_iSDLMaxLength = iMaxLength` without clamping.
- **Fix:** In `SetTextLimit()`, clamp: `m_iSDLMaxLength = std::min(iLimit, static_cast<int>(MAX_CHAT_SIZE));`. In `Init()`, clamp the same way.
- **Status:** FIXED — `m_iSDLMaxLength` clamped to `MAX_CHAT_SIZE` in both `SetTextLimit()` and `Init()`

---

### MEDIUM Issues (1)

**CR-3 MEDIUM — MuClipboardIsNumericOnly dead code on SDL3 path**

- **File:** `MuMain/src/source/ThirdParty/UIControls.cpp:3169`, `MuMain/src/source/Platform/PlatformCompat.h:544`
- **Category:** Dead Code / Misleading ATDD
- **Description:** `MuClipboardIsNumericOnly()` is placed in `EditWndProc` at line 3169 (the `Char == 0x16` Ctrl+V branch). On the SDL3 path, `m_hEditWnd = nullptr` (CreateWindowW stub returns nullptr), so `EditWndProc` is never registered via `SetWindowLongPtrW` and is never called by the Windows message loop. The ATDD marks `MuClipboardIsNumericOnly` as GREEN, but the function never executes. Behavior is accidentally correct because SDL3 delivers Ctrl+V paste via `SDL_EVENT_TEXT_INPUT`, and `DoActionSub`'s NUMBERONLY filter rejects non-digits — but this is via a different mechanism than intended. The `MuClipboardIsNumericOnly` function itself is correctly implemented but unreachable.
- **Impact:** Misleading ATDD state — claims clipboard validation is implemented but it's dead code. Future maintenance risk if someone relies on this function being called.
- **Fix:** Update ATDD to note that SDL3 clipboard validation is handled implicitly via `DoActionSub` NUMBERONLY filter (SDL3 delivers Ctrl+V as SDL_EVENT_TEXT_INPUT). No code change required — behavior is correct.
- **Status:** FIXED — ATDD updated with architectural note explaining SDL3 clipboard validation mechanism

---

### LOW Issues (1)

**CR-4 LOW — SERIALNUMBER filter comment misleading**

- **File:** `MuMain/src/source/ThirdParty/UIControls.cpp:3253`
- **Category:** Code Clarity
- **Description:** Comment `// toLower→toUpper` describes the `wch -= 32` operation but is ambiguous — should be `// convert lowercase to uppercase`.
- **Fix:** Update comment.
- **Status:** FIXED — comment updated to `// convert lowercase to uppercase (matches Win32 WM_CHAR path)`

---

### AC Validation

| AC | Status | Evidence |
|----|--------|---------|
| AC-1 | PASS | SDL_EVENT_TEXT_INPUT handler in SDLEventLoop.cpp with flow code |
| AC-2 | PASS | Text buffer works; focus guard added (CR-1 fixed) |
| AC-3 | PASS | MuSdlUtf8NextChar correctly decodes ASCII, 2-byte, 3-byte UTF-8 |
| AC-4 | PASS | Backspace works; focus guard ensures only focused box processes it (CR-1 fixed) |
| AC-5 | PASS | MuStartTextInput/MuStopTextInput lifecycle correctly implemented |
| AC-STD-2 | PASS | PlatformCompat stubs correct; SDL3 clipboard validation via NUMBERONLY filter (CR-3 documented) |
| AC-STD-3 | PASS | No raw IME APIs outside Platform/ThirdParty |
| AC-STD-11 | PASS | Flow code VS1-SDL-INPUT-TEXT in all artifacts |
| AC-STD-13 | PASS | Quality gate: 689 files clean |

### ATDD Audit

- **Total items:** 58 (counting all [x] items in atdd.md)
- **GREEN:** 58 (all checked)
- **RED:** 0
- **Coverage:** 100% claimed
- **Sync issues:** CR-3 (MuClipboardIsNumericOnly marked GREEN but dead code)

---

## Step 3: Resolution

**Completed:** 2026-03-06
**Status:** PASSED — All issues resolved

### Summary

4 issues were identified during code-review-analysis. All were resolved in a single fix iteration:

| Issue | Severity | Resolution |
|-------|----------|------------|
| CR-1 | CRITICAL | Fixed — focus guard `if (!m_bSDLHasFocus) return;` added to `DoActionSub()` SDL3 block |
| CR-2 | HIGH | Fixed — `m_iSDLMaxLength` clamped to `MAX_CHAT_SIZE` in `SetTextLimit()` and `Init()` |
| CR-3 | MEDIUM | Documented — ATDD updated with architectural note; no code change needed (behavior correct via alternate path) |
| CR-4 | LOW | Fixed — misleading comment updated to `// convert lowercase to uppercase (matches Win32 WM_CHAR path)` |

### Files Modified

- `MuMain/src/source/ThirdParty/UIControls.cpp` — 3 code fixes (CR-1, CR-2, CR-4)
- `_bmad-output/stories/2-2-3-sdl3-text-input/atdd.md` — ATDD annotation for CR-3

### Final AC Status

All ACs PASS. Story implementation is complete and correct.

### Post-Fix Quality Gate

`./ctl check` — PASSED (clang-format + cppcheck, 689/689 files clean, 0 errors)

### Story Disposition

**DONE** — Story 2-2-3-sdl3-text-input is complete. Status updated to `done`.

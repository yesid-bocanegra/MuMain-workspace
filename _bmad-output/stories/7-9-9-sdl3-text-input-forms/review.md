# Code Review — Story 7-9-9: SDL3 Text Input Forms

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-9 |
| **Reviewer** | Adversarial Code Review (AI) |
| **Date** | 2026-04-08 |
| **Files Reviewed** | 7 (6 production + 1 test) |
| **Diff Size** | +56 / -11 lines |

---

## Quality Gate

**Status:** Pending — run by pipeline (CODE_REVIEW_QG step)

Pre-run results provided: lint PASS, build PASS, coverage N/A.

---

## Findings

### Finding 1: Dangling `s_pFocusedInputBox` after box destruction

| Field | Value |
|-------|-------|
| **Severity** | HIGH |
| **File** | `src/source/ThirdParty/UIControls.cpp` |
| **Lines** | 3843-3848 (definition), 3311-3334 (destructor) |
| **AC** | AC-1 |

**Description:** `GiveFocus()` uses a `static CUITextInputBox* s_pFocusedInputBox` to track the currently focused input box. When a `CUITextInputBox` is destroyed (e.g., `SAFE_DELETE(g_pSinglePasswdInputBox)` at MuMain.cpp:631), the static pointer is NOT cleared. If `GiveFocus()` is called on another box after the destruction, line 3846 dereferences the dangling pointer (`s_pFocusedInputBox->m_bSDLHasFocus = false`) — undefined behavior.

**Impact:** During shutdown, `SAFE_DELETE` destroys both global input boxes. If any login-window input box calls `GiveFocus()` after that point (unlikely but possible in destruction ordering), the program crashes or corrupts memory. More concerning: if any CUITextInputBox is destroyed during gameplay (window close/recreate), the static pointer silently dangles.

**Suggested Fix:** Clear `s_pFocusedInputBox` in the destructor:
```cpp
CUITextInputBox::~CUITextInputBox()
{
    // Clear static focus tracker if we're the focused box [7-9-9]
    // (s_pFocusedInputBox is function-local static in GiveFocus — need a class-level static instead)
    ...
}
```
Alternatively, promote `s_pFocusedInputBox` from function-local to class-level static so the destructor can clear it.

---

### Finding 2: `s_pFocusedInputBox` not cleared when box is hidden via `SetState(UISTATE_HIDE)`

| Field | Value |
|-------|-------|
| **Severity** | MEDIUM |
| **File** | `src/source/ThirdParty/UIControls.cpp` |
| **Lines** | 3800-3807 (`SetState`), 3843-3848 (`GiveFocus`) |
| **AC** | AC-1 |

**Description:** `SetState(UISTATE_HIDE)` at line 3803 clears `m_bSDLHasFocus = false` and calls `MuStopTextInput()`, but does NOT clear `s_pFocusedInputBox`. This creates an inconsistency: the static pointer still references a box whose focus was externally cleared. When a different box later calls `GiveFocus()`, line 3846 will set `m_bSDLHasFocus = false` on the hidden box — benign but logically wrong. The hidden box's focus flag is already false, so no functional impact, but the stale reference makes the state machine harder to reason about.

**Impact:** Low functional risk (no crash, no visible bug), but increases maintenance burden and makes future focus logic changes error-prone.

**Suggested Fix:** In `SetState(UISTATE_HIDE)`, also clear `s_pFocusedInputBox` if it points to `this`. Requires promoting the static to class scope (see Finding 1).

---

### Finding 3: Residual diagnostic `fprintf(stderr)` in Render path

| Field | Value |
|-------|-------|
| **Severity** | MEDIUM |
| **File** | `src/source/ThirdParty/UIControls.cpp` |
| **Lines** | 4057-4066 |
| **AC** | N/A (pre-existing, but in modified function) |

**Description:** The Render function still contains a periodic `fprintf(stderr, "[INPUT FOCUSED]...")` diagnostic that fires every ~300 frames (~5 seconds) for the focused input box. The GiveFocus `fprintf` was correctly removed in this story's diff, but the Render diagnostic was left in. This outputs to stderr in production, which on macOS/Linux can flood the terminal or log files.

**Impact:** Performance noise and log pollution in production. The project convention says "no `wprintf` in new code" and prefers `g_ErrorReport.Write()` / `g_ConsoleDebug->Write()` for logging.

**Suggested Fix:** Remove the diagnostic block (lines 4057-4066) or convert to `g_ConsoleDebug->Write()` guarded by a debug flag.

---

### Finding 4: Vacuous `assert` immediately after `new`

| Field | Value |
|-------|-------|
| **Severity** | LOW |
| **File** | `src/source/Main/MuMain.cpp` |
| **Lines** | 523-524 |
| **AC** | AC-4 |

**Description:** `assert(g_pSingleTextInputBox != nullptr)` and `assert(g_pSinglePasswdInputBox != nullptr)` appear immediately after `new CUITextInputBox`. Standard C++ `new` never returns `nullptr` — it throws `std::bad_alloc` on failure (or terminates if exceptions are disabled). These asserts are vacuous: they can never trigger because the pointer is guaranteed non-null after a successful `new`.

**Impact:** No runtime risk. Gives false impression of validation. A reader might assume these protect against nullptr, but they're dead code.

**Suggested Fix:** Remove both asserts. If null-safety is desired, use `std::make_unique` and store as `std::unique_ptr` (per project convention: "std::unique_ptr, no raw new/delete"). Alternatively, add a comment explaining these are documentation-only assertions.

---

### Finding 5: Raw `new`/`SAFE_DELETE` instead of `std::unique_ptr`

| Field | Value |
|-------|-------|
| **Severity** | LOW |
| **File** | `src/source/Main/MuMain.cpp` |
| **Lines** | 513, 518 (new), 631-632 (SAFE_DELETE) |
| **AC** | AC-4 |

**Description:** The global input boxes use raw `new CUITextInputBox` and `SAFE_DELETE()` macro for cleanup. The project convention (CLAUDE.md) specifies: "New code: `std::unique_ptr` (no raw `new`/`delete`)". While the existing declarations at line 67-68 (`CUITextInputBox* g_pSingleTextInputBox = nullptr`) match legacy patterns, new initialization code should follow the modern convention.

**Impact:** No runtime risk. Convention non-compliance. If cleanup is skipped due to early exit or exception, the allocations leak.

**Suggested Fix:** Refactoring to `std::unique_ptr` requires changing the global declarations (which are used across multiple TUs), so this is a larger refactor than appropriate for this story. Accept as tech debt; document for future cleanup.

---

### Finding 6: Tests simulate logic inline rather than exercising actual implementation

| Field | Value |
|-------|-------|
| **Severity** | MEDIUM |
| **File** | `tests/platform/test_text_input_forms_7_9_9.cpp` |
| **Lines** | 49-146 (AC-1), 179-237 (AC-3), 292-372 (AC-5) |
| **AC** | AC-1, AC-3, AC-5 |

**Description:** All 4 executable tests (AC-1: 2 tests, AC-3: 1 test, AC-5: 1 test) use local variables to simulate the logic pattern rather than calling the actual `GiveFocus()`, `DoActionSub()`, or `GetAsyncKeyState()` functions. For example, AC-1 test at line 59: `if (!m_bSDLHasFocus) { m_bSDLHasFocus = true; ++giveFocusCallCount; }` — this is a reimplementation of the guard, not a call to `CUITextInputBox::GiveFocus()`.

If the actual implementation diverges from the pattern simulated in tests (e.g., someone changes the guard condition), the tests still pass — they test their own copy, not the real code.

**Impact:** False confidence in test coverage. Tests verify the intent/pattern but not the actual code path. This is a known limitation of the project's test infrastructure (can't easily link game classes into test binaries due to heavyweight dependencies).

**Suggested Fix:** This is acceptable for now given the project's test infrastructure constraints, but should be documented as a known limitation. Consider extracting the guard logic into a testable free function in a future story.

---

## ATDD Coverage

| AC | Checklist Status | Test Status | Accurate? |
|----|-----------------|-------------|-----------|
| AC-1 | All items `[x]` | 2 TEST_CASEs pass (24 assertions) | Yes |
| AC-2 | All items `[x]` | SKIP (Win32 GDI) | Yes |
| AC-3 | All items `[x]` | 1 TEST_CASE (3 sections) + 1 SKIP | Yes |
| AC-4 | All items `[x]` | 2 SKIPs (requires game init) | Yes |
| AC-5 | All items `[x]` | 1 TEST_CASE (4 sections) pass | Yes |
| AC-6 | All items `[x]` | SKIP (same code path as AC-3) | Yes |

**ATDD Checklist Accuracy:** All checklist items are accurately marked. No phantom completions detected. The 5 SKIP tests correctly reflect items that require integration testing infrastructure not available in unit tests.

**Note:** 7 checklist items were marked `[x]` by the completeness-gate step with deferred-to-integration annotations. These represent manual verification tasks, not automated test coverage.

---

## Summary

| Severity | Count | Description |
|----------|-------|-------------|
| BLOCKER | 0 | — |
| HIGH | 1 | Dangling `s_pFocusedInputBox` on box destruction |
| MEDIUM | 3 | Stale static on hide, residual fprintf, inline test simulation |
| LOW | 2 | Vacuous assert, raw new/delete convention |
| **Total** | **6** | |

**Overall Assessment:** The implementation correctly addresses all 4 bugs specified in the story. The code changes are minimal and focused. The HIGH finding (dangling static pointer) is the only one with real crash potential, though the window of vulnerability is narrow (shutdown or window recreation). The MEDIUM findings are quality/maintenance concerns with no immediate runtime risk.

**Recommendation:** Fix the HIGH finding before merging. The MEDIUM and LOW findings can be addressed in the code-review-finalize step or deferred as tech debt.

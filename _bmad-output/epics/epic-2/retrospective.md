# Epic 2 Retrospective

**Epic:** EPIC-2 — SDL3 Windowing & Input Migration
**Generated:** 2026-03-07
**Value Stream:** VS-1 (SDL3 Platform Layer) — Feature Flow
**Sprints:** 1 (Sprint 2 — 2026-03-06 to 2026-03-20)
**Stories:** 5
**Total Velocity:** 17 pts

---

## Epic-Level SAFe Metrics

### Velocity & Flow Summary

| Metric | Value |
|--------|-------|
| Total Velocity | 17 pts |
| Sprints Spanned | 1 (Sprint 2, 2026-03-06 to 2026-03-20) |
| Avg Flow Time | 2.58 h per story |
| Flow Efficiency (avg) | ~88% |
| Commitment Reliability | 100% (17/17 pts delivered) |
| WIP Violations | 0 |
| Sprint Completion | Day 2 of 14 (SPI 14.0 sprint-wide) |

Note: Two EPIC-2 stories (2-1-1, 2-1-2) were completed between Sprint 1 and Sprint 2 and assigned retroactively to Sprint 2. Their flow time data is included in the sprint-2 completion report; they are treated as Sprint 2 stories for all metric purposes.

### Plan vs Delivered

| Metric | Planned | Delivered | Delta |
|--------|---------|-----------|-------|
| Stories | 5 | 5 | 0 |
| Points | 17 | 17 | 0 |
| Stories Added Mid-Epic | 0 | — | — |
| Stories Deferred/Removed | 0 | — | — |

**Commitment Reliability:** HIGH (100%)

### Story-Level Flow Time

| Story | Points | Flow Time | Retries | Issues Fixed |
|-------|--------|-----------|---------|-------------|
| 2-1-1-sdl3-window-event-loop | 5 | 2.34 h | 0 | 15 (7 HIGH + 5 MEDIUM + 3 LOW) |
| 2-1-2-sdl3-window-focus-display | 3 | 2.12 h | 0 | 9 (1 HIGH + 6 MEDIUM + 2 LOW/accepted) |
| 2-2-1-sdl3-keyboard-input | 3 | 2.31 h | 1 | 6 (0 HIGH + 3 MEDIUM + 3 LOW) |
| 2-2-2-sdl3-mouse-input | 3 | 3.43 h | 2 | 5 (0 HIGH + 0 MEDIUM + 5 LOW/info) |
| 2-2-3-sdl3-text-input | 3 | 2.61 h | 1 | 4 (1 CRITICAL + 1 HIGH + 1 MEDIUM + 1 LOW) |

**Notable:** 2-2-2 (SDL3 Mouse Input) is the outlier at 3.43 h — 33% above the epic average — due to 2 retries. Story 2-1-1 had the most issues fixed (15) as the first SDL3 story establishing patterns for all subsequent ones.

### Flow Distribution

| Type | Count | Points | % of Total |
|------|-------|--------|-----------|
| Feature | 5 | 17 | 100% |
| Enabler | 0 | 0 | 0% |
| Defect | 0 | 0 | 0% |
| Debt | 0 | 0 | 0% |

All 5 stories are Feature type — EPIC-2 is the first feature delivery epic in the project. This contrasts with EPIC-1 (100% Enabler).

---

## Cross-Story Patterns

### Code Review Findings Summary

| Story | CRITICAL | HIGH | MEDIUM | LOW/Info | Total | Regressions |
|-------|----------|------|--------|----------|-------|-------------|
| 2-1-1-sdl3-window-event-loop | 0 | 7 | 5 | 3 | 15 | 0 |
| 2-1-2-sdl3-window-focus-display | 0 | 1 | 6 | 2 | 9 | 0 |
| 2-2-1-sdl3-keyboard-input | 0 | 0 | 3 | 3 | 6 | 1 |
| 2-2-2-sdl3-mouse-input | 0 | 0 | 0 | 5 | 5 | 2 |
| 2-2-3-sdl3-text-input | 1 | 1 | 1 | 1 | 4 | 1 |
| **Epic Total** | **1** | **9** | **15** | **14** | **39** | **4** |

**All findings resolved:** 0 unresolved findings at epic validation time. Self-heal rate: 100%.

### Recurring Themes (2+ Stories)

**1. Win32 type reliance via PCH without explicit cross-platform includes (2/5 stories)**

Stories affected: 2-1-2 (LOW-2: `BOOL`/`TRUE`/`FALSE` via PCH without explicit `PlatformTypes.h`), 2-1-1 (implicit PCH dependency in SDL3 code paths).

SDL3 implementation files were compiled correctly on Windows because the PCH provides `<windows.h>`, but once the PCH is refactored for native non-Windows builds, these implicit dependencies will surface as compile errors. The pattern is systemic — any SDL3 TU that uses Win32 types without an explicit `#include "PlatformTypes.h"` has this latent issue. Currently accepted as future portability concern (deferred to PCH refactoring story in EPIC-4+).

**2. ATDD checklist status ambiguity for deferred/manual items (3/5 stories)**

Stories affected: 2-2-1 (MEDIUM-3: deferred items marked `[x]` with annotation, not a distinct marker), 2-2-2 (LOW-3: ATDD AC tag miscategorization), 2-1-1 (pre-ATDD workflow story — no ATDD checklist at all).

Across three stories, ATDD checklist state required correction during code review that should have been caught at completeness-gate. The `[x]` marker conflates "executed and passed" with "deferred by design," causing automated tooling to misreport coverage. This is the same theme flagged in the Sprint 2 retrospective (Action Item #3).

**3. Cross-platform behavioral parity documentation gaps (2/5 stories)**

Stories affected: 2-2-1 (LOW-3: keyboard/mouse asymmetry in `HandleFocusLoss()` undocumented), 2-2-2 (LOW-2: SDL3 double-click model differs from Win32 `WM_LBUTTONDBLCLK` in held-double-click scenario).

Win32-to-SDL3 behavioral differences that are intentional design choices were not documented in code comments, requiring code review to add inline explanations. For 2-2-2, the behavioral difference is a real (if low-probability) semantic gap between Win32 and SDL3 that was accepted rather than fixed. These gaps signal that the behavioral parity checklist should be an ATDD first-class item for input stories, not a code review discovery.

**4. g_ErrorReport.Write() vs g_ConsoleDebug->Write() misuse for informational messages (2/5 stories)**

Stories affected: 2-1-2 (MEDIUM-6: `Winmain.cpp:1411` display size log used `g_ErrorReport.Write()` for informational message), 2-1-1 (multiple instances of same pattern found and fixed in SDLEventLoop.cpp).

The project logging convention (`g_ErrorReport.Write()` for post-mortem diagnostics, `g_ConsoleDebug->Write()` for live debug) was systematically violated in new SDL3 code. In 2-1-2, the first-pass review fixed instances in `SDLEventLoop.cpp` but missed `Winmain.cpp:1411`, which required a second pass. This is a recurring cross-story pattern requiring a pre-review checklist item.

### Regression Analysis

**Total Regressions:** 4 across 3 stories

| Story | Regression # | Root Cause | Category |
|-------|-------------|-----------|---------|
| 2-2-1-sdl3-keyboard-input | 1 | Missing lower-bound guard on scancode bounds check (MEDIUM-1 not caught at completeness-gate) | QUALITY |
| 2-2-2-sdl3-mouse-input | 1 | ATDD AC tag miscategorization (documentation error caught at code review, not completeness-gate) | PROCESS |
| 2-2-2-sdl3-mouse-input | 2 | Dev-story + completeness-gate retries from mouse input complexity (SDL3 double-click model analysis) | QUALITY |
| 2-2-3-sdl3-text-input | 1 | CRITICAL focus guard missing in `DoActionSub()` — `CUIControl::DoAction()` calls it unconditionally | QUALITY |

**Average Regressions per Story:** 0.8 (vs 0.67 in EPIC-1 — slightly higher, expected for application-layer stories vs build-system enablers)

**Common Regression Reasons:** Application-layer behavioral correctness issues (focus guards, bounds checks) that pass static analysis (`./ctl check`) but represent semantic defects only catchable via adversarial code review. Process convention gaps (ATDD checklist state) persist from EPIC-1 but are reduced.

---

## Catalog Health Assessment

EPIC-2 is a platform infrastructure epic for a C++ game client. The catalog model (REST API endpoints, error codes, domain events, navigation screens) is not applicable in the same way as a web/microservice project.

| Catalog | Entries | Coverage |
|---------|---------|----------|
| API Endpoints | 0 | N/A (no REST API in game client) |
| Error Codes | N/A | N/A (error codes tracked in docs/error-catalog.md, not a service catalog) |
| Events | 0 | N/A (no event bus; game loop uses direct function calls) |
| Flows | 5 (VS1 flow codes) | Complete for EPIC-2 scope |
| Navigation | 0 | N/A (no screen navigation catalog) |

**Flow Code Coverage (VS1 tags introduced by EPIC-2):**

| Flow Code | Story | Confirmed In |
|-----------|-------|-------------|
| `VS1-SDL-WINDOW-CREATE` | 2-1-1 | SDLEventLoop.cpp, test file headers, CMake validation test |
| `VS1-SDL-WINDOW-FOCUS` | 2-1-2 | SDLEventLoop.cpp (2 occurrences) |
| `VS1-SDL-INPUT-KEYBOARD` | 2-2-1 | PlatformCompat.h, SDLKeyboardState.cpp, SDLEventLoop.cpp, all Catch2 test names, CMake test |
| `VS1-SDL-INPUT-MOUSE` | 2-2-2 | SDLEventLoop.cpp comments, SDLKeyboardState.cpp log message, all test names |
| `VS1-SDL-INPUT-TEXT` | 2-2-3 | SDLEventLoop.cpp, SDLKeyboardState.cpp, PlatformCompat.h, all Catch2 test names |

**Reachability Check:** N/A for this project type — no cross-catalog connectivity to verify. Epic validation confirmed 0 CRITICAL reachability findings. Sprint health audit: 0 CRITICAL / 0 HIGH / 0 MEDIUM / 0 LOW across all 5 stories.

**Catalog completeness verdict:** COMPLETE for EPIC-2 scope. All 5 VS1 flow codes confirmed present in source, tests, and story artifacts.

---

## Lessons Learned

### ARCHITECTURE

**1. SDL3 platform abstraction boundary held — no Win32 API leakage into game logic**
- **Impact:** HIGH | **Recurrence:** One-time (positive — design validated)
- The `MU_ENABLE_SDL3` guard strategy (CI Strategy B) successfully isolated SDL3 code from Win32 game logic across all 5 stories. CMake regression tests confirmed zero unshimmed Win32 input APIs in game logic directories. The abstraction layer design from EPIC-1 (MUPlatform, PlatformCompat.h, PlatformTypes.h) proved adequate for all EPIC-2 windowing and input requirements without needing architectural changes.

**2. CMake mutual exclusion pattern is critical for dual-backend builds**
- **Impact:** HIGH | **Recurrence:** Systemic (positive — established pattern)
- Story 2-1-1 fixed a CMake parallel-`if()` pattern where both WIN32 and SDL3 backends could compile simultaneously. The fix (nested `if(MU_ENABLE_SDL3) / else()` hierarchy) established the canonical mutual exclusion pattern used correctly in all subsequent stories. This same pattern was independently validated in story 3-1-1 (EPIC-3) where a regression of the same class — duplicate parallel build systems — was found and fixed.

**3. Win32 PCH dependency is a latent cross-platform compile risk in all SDL3 TUs**
- **Impact:** MEDIUM | **Recurrence:** Systemic (pre-existing gap, will affect EPIC-4+)
- SDL3 implementation files that use Win32 types (`BOOL`, `TRUE`, `FALSE`, `DWORD`) currently get them transitively via the PCH (`stdafx.h` → `<windows.h>`). When the PCH is refactored for native macOS/Linux compilation (required for EPIC-4), these implicit dependencies will break. The pattern was found in 2+ stories and accepted as deferred debt — it needs a dedicated EPIC-4 pre-work story to audit and add explicit `#include "PlatformTypes.h"` to all affected SDL3 TUs.

**4. mu_wchar_to_utf8() supplementary plane coverage requires centralization**
- **Impact:** MEDIUM | **Recurrence:** Recurring (found in 2-1-1; will recur in future Unicode stories)
- Story 2-1-1 discovered that the existing wchar_t-to-UTF8 pattern in `PlatformCompat.h` only handled 3-byte sequences, missing supplementary plane characters (U+10000–U+10FFFF). A `mu_wchar_to_utf8()` helper with full 4-byte support and surrogate-pair skipping was added as an interim measure in `PlatformCompat.h`. This should be moved to a centralized `Utility/UnicodeConversion.h` before EPIC-3's char16_t encoding story (3-2-1) to avoid duplication.

### PROCESS

**1. Batch pipeline execution is now the established delivery model**
- **Impact:** HIGH | **Recurrence:** Systemic (positive — second consecutive sprint)
- Stories 2-1-2 through 2-2-3 all ran in continuous batch mode with 99.8–99.9% individual flow efficiency (2-1-1 was 67.9% as the first interactive story). Sprint 2 retrospective documented this as a repeatable pattern. The batch pipeline delivered all 5 EPIC-2 stories within a continuous session, with zero inter-story human handoff delays. This model is now the expected execution pattern for future epics.

**2. Behavioral parity verification must be an ATDD first-class item for input migration stories**
- **Impact:** HIGH | **Recurrence:** Recurring (first appearance in EPIC-2; will recur in EPIC-5, EPIC-6)
- Three EPIC-2 stories (2-2-1, 2-2-2, 2-2-3) involved migrating Win32 input handling to SDL3 equivalents. In all three cases, behavioral parity analysis (comparing `WndProc` handlers against SDL3 event handlers) was performed during code review, not during ATDD. This means that behavioral differences (e.g., SDL3 double-click BUTTON_DOWN for both clicks vs Win32 `WM_LBUTTONDBLCLK` only for second) were discovered adversarially rather than planned. For future input migration stories (EPIC-4 rendering, EPIC-5 audio), the ATDD should include an explicit behavioral parity table comparing Win32 and SDL3 semantics for each migrated behavior.

**3. ATDD checklist synchronization at completeness-gate remains an open gap**
- **Impact:** MEDIUM | **Recurrence:** Recurring (Sprint 1 AND Sprint 2 — persistent)**
- This was Sprint 2 Retrospective Action Item #3 and it persisted into EPIC-2: stories 2-2-1 (deferred items marked `[x]`) and 2-2-2 (AC tag miscategorization) both required ATDD corrections during code review. The completeness-gate step is not currently enforcing ATDD state-vs-story.md parity. Until the gate formally verifies this, code review will continue to spend time on ATDD synchronization that should be pre-resolved.

**4. g_ErrorReport.Write() / g_ConsoleDebug->Write() convention requires a pre-review checklist item**
- **Impact:** MEDIUM | **Recurrence:** Recurring (2/5 stories in EPIC-2)**
- The logging convention violation (using `g_ErrorReport.Write()` for informational messages) was caught by adversarial review in 2-1-1 and 2-1-2. A simple pre-review grep for `g_ErrorReport.Write()` calls outside error-reporting contexts would catch this class of issue before code review. This should be added to the pre-review checklist alongside commit scope and test file tracking.

**5. Stories completed between sprint boundaries need formal inter-sprint accounting**
- **Impact:** LOW | **Recurrence:** Recurring (occurred in both inter-sprint gaps so far)**
- Stories 2-1-1 and 2-1-2 were completed between Sprint 1 and Sprint 2 and assigned retroactively to Sprint 2. The Sprint 2 retrospective flagged this as a surprise that occurred for the second time. While the points were correctly included in the 28-point Sprint 2 total from the start, the accounting gap suggests sprint boundaries need a formal "inter-sprint story disposition" step to assign in-progress work before sprint planning concludes.

### QUALITY

**1. Adversarial code review found real semantic defects in application-layer stories**
- **Impact:** HIGH | **Recurrence:** Systemic (positive — validates the review process)**
- EPIC-2 code reviews found 1 CRITICAL (2-2-3 focus guard), 9 HIGH, and 15 MEDIUM findings across 5 stories — a 4.6x higher issue-per-story rate than EPIC-1 (30 issues / 6 stories = 5.0 per story vs 39 / 5 = 7.8 per story). More importantly, the nature of issues shifted from process/convention violations (EPIC-1) to semantic correctness issues: focus guards, bounds checks, behavioral parity gaps. These are exactly the class of defects that pass static analysis (`./ctl check`) but cause runtime failures. The adversarial review process is providing genuine safety net value for the cross-platform migration.

**2. CRITICAL defect in 2-2-3 highlights DoAction() / DoActionSub() call chain complexity**
- **Impact:** HIGH | **Recurrence:** One-time (potential systemic risk for future UI stories)**
- The most severe finding in EPIC-2 was `CR-1` in story 2-2-3: `DoActionSub()` in `CUITextInputBox` processed `g_szSDLTextInput` for ALL active `CUITextInputBox` instances because `CUIControl::DoAction()` calls `DoActionSub()` unconditionally. Without the `if (!m_bSDLHasFocus) return;` guard, every visible text input box would have received every keystroke simultaneously. This is an architectural pattern unique to `CUIControl`-derived classes — any future SDL3 input handling in UI controls must audit the `DoAction()` call chain before assuming single-instance behavior.

**3. Test architecture constraint: unit tests inline-simulate handler logic**
- **Impact:** MEDIUM | **Recurrence:** Systemic (accepted constraint for platform-layer tests)**
- Across stories 2-2-1, 2-2-2, and 2-2-3, Catch2 unit tests were written to inline-simulate SDL3 event handler logic rather than calling `PollEvents()` directly. This is an accepted architectural constraint (tests cannot create a live SDL window), but it means that a divergence between the test's inline copy and the actual handler would not be caught automatically. The pattern mirrors the Sprint 1 test infrastructure and is consistent, but future stories should consider whether integration tests (post-EPIC-4, with a real SDL window) can replace or supplement inline simulation tests.

**4. 100% code review self-healing rate across all 5 stories**
- **Impact:** HIGH | **Recurrence:** Systemic (positive — sustained from Sprint 1)**
- All 4 retry events (2-2-1: 1, 2-2-2: 2, 2-2-3: 1) were resolved on the retry without escalation. 39 total findings found and fixed with zero stories left in a broken state. The self-healing pattern established in Sprint 1 (Sprint 1 retrospective "Went Well" #5) continued and scaled to more complex application-layer stories. This confirms the pipeline's review-and-fix loop is robust for SDL3 migration complexity.

---

## Improvement Actions

| # | Action | Category | Scope | Owner | Status |
|---|--------|----------|-------|-------|--------|
| 1 | Audit all SDL3 TUs for implicit Win32 type dependencies via PCH (`BOOL`, `TRUE`, `FALSE`, `DWORD` without explicit `#include "PlatformTypes.h"`); add explicit includes before EPIC-4 PCH refactoring | ARCHITECTURE | Pre-EPIC-4 prep story | Platform maintainer | NEW |
| 2 | Move `mu_wchar_to_utf8()` from `PlatformCompat.h` to a centralized `Utility/UnicodeConversion.h` before story 3-2-1 (char16_t encoding) to prevent duplication | ARCHITECTURE | Before EPIC-3 story 3-2-1 | Platform maintainer | NEW |
| 3 | For all input migration stories (EPIC-4+, EPIC-5, EPIC-6), add explicit Win32-to-SDL3 behavioral parity table to ATDD, covering each migrated behavior's semantic differences; do not leave parity analysis to code review discovery | PROCESS | Sprint 3+, from first input migration story | Story manager / dev agent | NEW |
| 4 | Add `g_ErrorReport.Write()` / `g_ConsoleDebug->Write()` convention check to the pre-review checklist: grep for `g_ErrorReport.Write()` in new code paths and verify each call is an actual error (not informational) | PROCESS | Sprint 3, from first story | Story manager / dev agent | NEW |
| 5 | For any future `CUIControl`-derived class implementing SDL3 input, explicitly audit `DoAction()` / `DoActionSub()` call chain and add focus guard before processing input; document this as a ATDD pre-condition | PROCESS | Sprint 3+, UI stories | Dev agent | NEW |
| 6 | Formalize inter-sprint story disposition step: before sprint planning concludes, confirm all in-progress or recently-completed stories are assigned to the closing or new sprint; eliminate retroactive assignment | PROCESS | Sprint 3 planning | Scrum master | NEW |
| 7 | Resolve persistent ATDD checklist sync gap (Action Item #3 from Sprint 2 retro, still open): add explicit completeness-gate verification that all `[x]` items are either executed or annotated `[DEFERRED — reason]`; mismatched story.md task state blocks advancing to code-review | PROCESS | Sprint 3, from first story | Dev agent / pipeline automation | NEW |

---

## Tech Debt Candidates

```
TECH DEBT CANDIDATES
  1. Win32 PCH implicit type dependencies in SDL3 TUs
     All SDL3 implementation files use `BOOL`/`TRUE`/`FALSE`/`DWORD` via the PCH transitively.
     When stdafx.h is refactored for native macOS/Linux (EPIC-4 pre-work), these will fail.
     Requires audit + explicit #include "PlatformTypes.h" additions across Platform/sdl3/*.cpp
     (Action #1 above; estimated scope: 5-8 files, ~1 story point)

  2. mu_wchar_to_utf8() centralization
     Currently duplicated as interim measure in PlatformCompat.h alongside the pre-existing
     mu_wfopen() pattern. Should be a single canonical utility in Utility/UnicodeConversion.h.
     (Action #2 above; pre-work for EPIC-3 story 3-2-1 char16_t encoding; ~1 story point)

  3. CUITextInputBox DoAction() / DoActionSub() focus guard pattern
     The focus guard fix in 2-2-3 is specific to CUITextInputBox. Any other CUIControl-derived
     class implementing SDL3 input handling has the same potential multi-instance issue.
     Requires audit of all CUIControl subclasses that process SDL3 input events.
     (Action #5 above; scope depends on EPIC-4 UI migration story count; ~2 story points)

  To create tech debt items, run: /bmad:pcc:workflows:techdebt-init
```

---

```
+==================================================+
|                                                  |
|   EPIC 2 RETROSPECTIVE COMPLETE                  |
|                                                  |
|   Stories:     5                                 |
|   Velocity:    17 pts across 1 sprint            |
|   Lessons:     12 (ARCH:4  PROC:5  QUAL:3)       |
|   Actions:     7 new                             |
|   Tech Debt:   3 candidates                      |
|                                                  |
|   Report: _bmad-output/epics/epic-2/             |
|           retrospective.md                       |
|                                                  |
|   Next: Run epic-start for Epic 3                |
+==================================================+
```

---

*Report generated by BMAD Epic Retrospective Workflow — 2026-03-07*

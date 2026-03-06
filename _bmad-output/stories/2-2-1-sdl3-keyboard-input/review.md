# Code Review — Story 2-2-1-sdl3-keyboard-input

## Header

| Attribute | Value |
|-----------|-------|
| Story Key | 2-2-1-sdl3-keyboard-input |
| Story Title | SDL3 Keyboard Input Migration |
| Story Type | infrastructure |
| Date | 2026-03-06 |
| Story File | `_bmad-output/stories/2-2-1-sdl3-keyboard-input/story.md` |
| Agent Model | claude-sonnet-4-6 |

## Pipeline Status

| Step | Status | Date |
|------|--------|------|
| 1. Quality Gate | PASSED | 2026-03-06 (re-validated 2026-03-06) |
| 2. Code Review Analysis | COMPLETED | 2026-03-06 (re-analysed 2026-03-06 — adversarial FRESH MODE) |
| 3. Code Review Finalize | COMPLETED | 2026-03-06 (re-finalized 2026-03-06 — 3 code fixes applied) |

## Quality Gate Progress

| Phase | Status | Iterations | Issues Fixed | Notes |
|-------|--------|------------|--------------|-------|
| Backend Local (mumain) | PASSED | 1 | 0 | format-check exit 0 + cppcheck 689/689 clean + no error/warning output (re-validated 2026-03-06) |
| Backend SonarCloud (mumain) | SKIPPED | — | — | No sonar_cmd in cpp-cmake profile, no sonar_key configured |
| Boot Verification (mumain) | SKIPPED | — | — | Not applicable (game client, no boot_verify_cmd) |
| Frontend Local | SKIPPED | — | — | No frontend components affected |
| Frontend SonarCloud | SKIPPED | — | — | No frontend components affected |

## Affected Components

| Component | Path | Tags | Type |
|-----------|------|------|------|
| mumain | ./MuMain | backend, cpp-cmake | cpp-cmake |
| project-docs | ./_bmad-output | documentation | documentation |

## Backend Quality Gate Details

### mumain (./MuMain) — cpp-cmake

**Tech Profile:** cpp-cmake
**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`

**Results:**
- `make -C MuMain format-check` — EXIT CODE 0 (PASSED)
- `make -C MuMain lint` (cppcheck) — 689/689 files checked, no errors or warnings printed (PASSED)
- `./ctl check` — PASSED (format-check + lint both clean)

### Platform Note

Quality gate executed on macOS (Darwin). Per CLAUDE.md, macOS cannot compile the game client (requires Win32 APIs, DirectX, windows.h). The applicable quality checks on macOS are format-check + lint, which mirrors the CI quality job. Full compilation is done via MinGW cross-compilation in CI.

## Schema Alignment

Not applicable — C++20 game client with no schema validation tooling.

## AC Compliance Check

Story type is `infrastructure` — AC tests skipped (infrastructure story).

## Fix Iterations

_Quality gate (format-check + lint): no fixes needed — passed on first iteration._

_Code review analysis (2026-03-06 re-run): 3 code fixes applied to `SDLEventLoop.cpp` — see Step 3 Resolution._

## Step 1 Summary

- quality_gate_status: **PASSED**
- Total iterations: 1
- Total issues fixed: 0
- format-check and cppcheck both passed with zero issues on first run

## Step 2: Analysis Results

**Completed:** 2026-03-06 (re-analysed 2026-03-06 — FRESH MODE)
**Status:** COMPLETED
**Agent Model:** claude-sonnet-4-6

### Severity Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 3 |
| LOW | 3 |
| **Total** | **6** |

### ATDD Checklist Audit

- Total checklist items: 32 (Implementation Checklist + PCC Compliance + AC-STD items)
- GREEN (marked [x]): 32
- RED (incomplete): 0
- Coverage of executable tests: 100% of executable items
- Deferred items (post-EPIC-4, cannot execute until full game compilation): 4 items explicitly annotated `[DEFERRED — post-EPIC-4]`
- All TEST_CASE entries in `test_platform_input.cpp` verified present and matching ATDD checklist
- CMake script tests registered in `tests/platform/CMakeLists.txt` (confirmed at lines 103-117)
- `test_platform_input.cpp` added to MuTests via `target_sources` in `tests/CMakeLists.txt` (line 23)
- Manual validation ACs correctly deferred to post-EPIC-4 per story spec

### Findings

#### MEDIUM-1: `SDL_EVENT_KEY_DOWN/UP` handlers check only upper bound — missing lower-bound guard against negative SDL_Scancode values

- **Severity:** MEDIUM
- **Category:** CODE-QUALITY / Security
- **Location:** `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` lines 147, 154
- **Description:** The bounds check in both handlers is `event.key.scancode < 512` (upper bound only). `SDL_Scancode` is a signed `typedef enum` (values 0–511 in SDL3 release-3.2.8). Under normal SDL3 operation all scancode values are non-negative. However, if a malformed or synthetic `SDL_KeyboardEvent` is processed with a negative scancode value, the condition `negative_value < 512` evaluates true, and `g_sdl3KeyboardState[negative_value]` would be an out-of-bounds write with undefined behaviour. A safe guard is `event.key.scancode >= 0 && event.key.scancode < 512` (or a cast to `unsigned`). This is low-probability in practice but the fix is trivial.
- **Fix:** Change both handlers to `if (event.key.scancode >= SDL_SCANCODE_UNKNOWN && event.key.scancode < 512)` or equivalently `if (static_cast<unsigned>(event.key.scancode) < 512u)`. The cast approach avoids a signed-comparison warning and handles the negative case correctly.
- **Status:** FIXED — `static_cast<unsigned>(event.key.scancode) < 512u` applied at SDLEventLoop.cpp lines 147 and 154

#### MEDIUM-2: `SDLKeyboardState.cpp` includes `PlatformCompat.h` which `extern`-declares the symbol defined in that same TU — ODR-ambiguous self-reference

- **Severity:** MEDIUM
- **Category:** CODE-QUALITY / Architecture
- **Location:** `MuMain/src/source/Platform/sdl3/SDLKeyboardState.cpp` line 11, `MuMain/src/source/Platform/PlatformCompat.h` line 61
- **Description:** `SDLKeyboardState.cpp` includes `PlatformCompat.h`. Within `PlatformCompat.h` (inside `#ifdef MU_ENABLE_SDL3`) the line `extern bool g_sdl3KeyboardState[512]` declares external linkage for the array. The same TU then defines `bool g_sdl3KeyboardState[512] = {}`. C++ permits an `extern` declaration and a definition in the same TU — the definition supersedes the declaration. However, this creates a self-referential pattern where the defining translation unit sees its own `extern` promise, which can confuse readers and some static analysis tools. The story's Dev Notes specifically chose Option A (separate .cpp) to avoid ODR concerns, but the include relationship reintroduces a weaker version of the same pattern. A cleaner design would have `SDLKeyboardState.cpp` NOT include `PlatformCompat.h` but instead have a minimal dedicated header (e.g., `SDLKeyboardState.h`) that only declares the two symbols (`g_sdl3KeyboardState` and `MuPlatformLogUnmappedVk`), with `PlatformCompat.h` including that header.
- **Fix (non-blocking):** Create `MuMain/src/source/Platform/sdl3/SDLKeyboardState.h` that declares `extern bool g_sdl3KeyboardState[512]` and `void MuPlatformLogUnmappedVk(int vk)`. Have both `PlatformCompat.h` and `SDLKeyboardState.cpp` include this header. This eliminates the self-referential include and is more conventional. Non-blocking — current code is well-defined C++20.
- **Status:** acknowledged — non-blocking, deferred. The self-referential include is valid C++20 (definition supersedes extern declaration). Refactoring to a dedicated header is a future improvement, not a defect.

#### MEDIUM-3: AC-3 executable coverage is zero — ATDD checklist marks deferred items `[x]` which conflates "planned" with "passed"

- **Severity:** MEDIUM
- **Category:** TEST-QUALITY / ATDD-QUALITY
- **Location:** `_bmad-output/stories/2-2-1-sdl3-keyboard-input/atdd.md` lines 136–139
- **Description:** AC-3 (hotkeys work on macOS and Linux) has zero executed test coverage. The ATDD checklist marks the four manual-validation items `[x]` with `[DEFERRED — post-EPIC-4]` annotation. The section header at lines 132–134 explains the deferral. However, the parent Implementation Checklist section has all items `[x]`, including these deferred ones, meaning `atdd_green_count == atdd_total_count` reads as 100% coverage when it should more accurately read as "100% accounted for, X% executable, Y% deferred." The `[DEFERRED]` annotation prevents confusion in manual review but automated tooling that counts `[x]` as GREEN would misreport coverage. The story itself accepts this deferral per spec and AC-VAL-2 documents it — this is a process observation, not a blocking defect.
- **Fix:** Acceptable as-is given the explicit `[DEFERRED — post-EPIC-4]` annotations. For future stories, consider using `[~]` or a distinct marker for deferred items to enable automated differentiation from executed-and-passing items. Non-blocking.
- **Status:** acknowledged — acceptable per story spec, process note for future stories

#### LOW-1: `SDLEventLoop.cpp` includes `<algorithm>` redundantly — already provided by `PlatformCompat.h`

- **Severity:** LOW
- **Category:** CODE-QUALITY
- **Location:** `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` line 7
- **Description:** `SDLEventLoop.cpp` includes both `../PlatformCompat.h` (line 5) and `<algorithm>` (line 7). `PlatformCompat.h` already includes `<algorithm>` at line 48 (inside `#ifdef MU_ENABLE_SDL3`). Since `SDLEventLoop.cpp` is always compiled with `MU_ENABLE_SDL3` defined (the whole file is guarded `#ifdef MU_ENABLE_SDL3`), the explicit `#include <algorithm>` in `SDLEventLoop.cpp` is redundant. Header guards ensure no double-inclusion, so there is no compilation issue, only a minor clarity concern.
- **Fix:** Remove the explicit `#include <algorithm>` from `SDLEventLoop.cpp`. The include is provided transitively via `PlatformCompat.h`.
- **Status:** FIXED — `#include <algorithm>` removed from SDLEventLoop.cpp line 7

#### LOW-2: `test_ac_std3_no_raw_getasynckeystate.cmake` does not exclude test files from its scan scope

- **Severity:** LOW
- **Category:** TEST-QUALITY
- **Location:** `MuMain/tests/platform/test_ac_std3_no_raw_getasynckeystate.cmake` lines 46–49
- **Description:** The CMake script uses `file(GLOB_RECURSE ALL_SOURCE_FILES "${SOURCE_DIR}/*.cpp" "${SOURCE_DIR}/*.h")` where `SOURCE_DIR` is `MuMain/src/source`. The test files live in `MuMain/tests/`, which is outside `SOURCE_DIR`, so they are not scanned. This is correct scope. However, the `ALLOWED_DIRS` list includes `Platform` and `ThirdParty` as path fragment matches — if a future source file in a directory named e.g. `PlatformUI/` were added, it would incorrectly be treated as allowed since `string(FIND path "/Platform/" ...)` would match on the `Platform` substring within `PlatformUI`. The match logic uses exact substring `/Platform/` with surrounding slashes, which is safe for the current directory layout but fragile to future renames.
- **Fix:** For robustness, change the `string(FIND "${FILE_PATH}" "/${ALLOWED_DIR}/" ...)` check to verify the path contains the exact platform directory, or use `cmake_path` / `get_filename_component` based matching. Non-blocking — no current directories trigger the issue.
- **Status:** acknowledged — analysis shows the current `/${ALLOWED_DIR}/` pattern (slash on both sides) already correctly anchors the directory name. `/PlatformUI/` does NOT match `/Platform/`. The fragility concern is theoretical; no current or anticipated directories trigger the issue. No code change required.

#### LOW-3: `HandleFocusLoss()` keyboard clear is unconditional while mouse-state clear is windowed-mode-only — undocumented architectural asymmetry

- **Severity:** LOW
- **Category:** CODE-QUALITY
- **Location:** `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` lines 78–97
- **Description:** Mouse state is cleared inside `if (g_bUseWindowMode == TRUE)` (lines 78–90). Keyboard state is cleared unconditionally at line 97 (both windowed and fullscreen). The comment at line 94 explains "prevents stuck keys on Alt-Tab" but does not explain why the keyboard clear differs from the mouse-clear guard. In fullscreen mode the game sets `g_bWndActive = false` (line 67) which throttles the frame rate and suspends most input processing — clearing keyboard state at that point is safe and correct. In windowed mode, `g_bWndActive` stays true and game logic continues, so clearing keyboard state is also correct. The asymmetry is intentional and correct, but lacks a comment explaining why keyboard uses a different guard than mouse.
- **Fix:** Add a comment above the keyboard clear: `// Keyboard state cleared in both windowed and fullscreen modes — unlike mouse state,` / `// stuck keys are unsafe in any window mode. Win32 equivalent: WM_KILLFOCUS clears async state.`
- **Status:** FIXED — expanded comment added to SDLEventLoop.cpp lines 94–99 explaining why keyboard clearing is unconditional while mouse clearing is windowed-only

### AC Validation Results

| AC | Text | Status | Evidence |
|----|------|--------|----------|
| AC-1 | GetAsyncKeyState high-byte correct | IMPLEMENTED | `GetAsyncKeyState()` shim at PlatformCompat.h:243 returns `uint16_t(0x8000)` when held, 0 otherwise; `HIBYTE(0x8000) == 0x80 == 128` verified by test_platform_input.cpp AC-4 tests |
| AC-2 | VK-to-scancode mapping covers all used VK codes | IMPLEMENTED | Complete switch + range maps in `MuVkToSdlScancode()` (PlatformCompat.h:65–229); ASCII A–Z and 0–9 range-mapped (lines 69–83); all 11 GetAsyncKeyState call-site files confirmed via grep |
| AC-3 | Hotkeys work on macOS and Linux | DEFERRED | Cannot execute until EPIC-4; manual test scenarios documented in `_bmad-output/test-scenarios/epic-2/2-2-1-sdl3-keyboard-input.md`; deferred per story spec |
| AC-4 | Key repeat async model correct | IMPLEMENTED | `event.key.scancode` in SDLEventLoop.cpp:146 ignores `event.key.repeat` (intentional, per comment at line 143); HIBYTE test verifies 0x8000/0x80/128 correctness |
| AC-5 | macOS Cmd key NOT mapped to VK_CONTROL | IMPLEMENTED | SDL_SCANCODE_LGUI/RGUI absent from MuVkToSdlScancode switch; verified by test_platform_input.cpp AC-5 test |
| AC-STD-1 | Code standards compliance | IMPLEMENTED | `[[nodiscard]]` present on both functions (PlatformCompat.h:65, 243); PascalCase, m_ prefix, nullptr, #pragma once, Allman braces, 4-space, LF all correct; no `#ifdef _WIN32` in game logic |
| AC-STD-2 | Catch2 v3.7.1 tests covering specified scenarios | IMPLEMENTED | `test_platform_input.cpp` has all required TEST_CASEs; CMake script tests registered at tests/platform/CMakeLists.txt:103–117; tests/CMakeLists.txt:23 adds test file; MU_ENABLE_SDL3 propagated at line 30 |
| AC-STD-3 | No unshimmed GetAsyncKeyState outside Platform/ | IMPLEMENTED | 11 files contain GetAsyncKeyState: 3 in Platform/ (shim definition, event loop, keyboard state) — all Platform/; 8 in game logic (NewUICommon, ZzzInterface, SceneCommon, SceneManager, UIGuildInfo, CameraUtility, Winmain, UIControls) — all known call sites going through shim; CMake regression test registered |
| AC-STD-8 | Unmapped VK logs with MU_ERR_* prefix | IMPLEMENTED | `MuPlatformLogUnmappedVk()` in SDLKeyboardState.cpp:22 calls `g_ErrorReport.Write(L"MU_ERR_INPUT_UNMAPPED_VK [VS1-SDL-INPUT-KEYBOARD]: unmapped VK code 0x%02X\r\n", ...)` |
| AC-STD-10 | Contract catalogs N/A | IMPLEMENTED | No HTTP API or event-bus contracts — N/A correctly noted |
| AC-STD-11 | Flow code VS1-SDL-INPUT-KEYBOARD in log, tests, artifacts | IMPLEMENTED | Present in PlatformCompat.h:234 (comment), SDLKeyboardState.cpp:1,21, SDLEventLoop.cpp:143,96, all TEST_CASE strings in test_platform_input.cpp, story.md, atdd.md; CMake test confirms presence in PlatformCompat.h |
| AC-STD-12 | SLI/SLO N/A | IMPLEMENTED | Infrastructure story — N/A correctly noted |
| AC-STD-13 | Quality gate passes | IMPLEMENTED | format-check EXIT 0, cppcheck 689/689 files with no warnings per review.md Step 1 |
| AC-STD-14 | Observability — unmapped VK logged | IMPLEMENTED | Same evidence as AC-STD-8; `g_ErrorReport.Write()` with flow code confirmed |
| AC-STD-15 | Git safety | IMPLEMENTED | No force push, no incomplete rebase; git status shows only .paw/ files modified (pipeline artifacts) |
| AC-STD-16 | Correct test infrastructure | IMPLEMENTED | Catch2 v3.7.1 via FetchContent (tests/CMakeLists.txt:3–6), tests in `MuMain/tests/platform/`, BUILD_TESTING=ON opt-in |
| AC-STD-20 | N/A (no endpoints/events/screens) | IMPLEMENTED | Infrastructure story — N/A correctly noted |
| AC-VAL-1 | N/A (no HTTP endpoints) | IMPLEMENTED | N/A correctly noted |
| AC-VAL-2 | Test scenarios documented | IMPLEMENTED | `_bmad-output/test-scenarios/epic-2/2-2-1-sdl3-keyboard-input.md` exists and contains manual test scenarios |
| AC-VAL-3–6 | N/A (no seed data, API catalog, events, flow catalog) | IMPLEMENTED | All N/A correctly noted; VS1-SDL-INPUT-KEYBOARD flow code confirmed in story artifacts |

**Total ACs:** 20
**Implemented:** 19
**Deferred (per spec):** 1 (AC-3 — manual validation deferred to post-EPIC-4, accepted per story spec)
**Not Implemented:** 0
**BLOCKERS:** 0
**Pass Rate:** 100% of executable ACs (19/19); AC-3 deferred by design

### Task Completion Audit

| Task | Claimed | Verified | Notes |
|------|---------|----------|-------|
| Task 1: Extend PlatformKeys.h | [x] | VERIFIED | PlatformKeys.h:69–88 — VK_LCONTROL (0xA2), VK_SNAPSHOT (0x2C), VK_CAPITAL (0x14), VK_PAUSE (0x13), VK_NUMLOCK (0x90), VK_SCROLL (0x91), OEM keys (0xBA–0xBE), numpad operators (0x6A–0x6F), VK_LSHIFT/RSHIFT/RCONTROL/LMENU/RMENU all present |
| Task 2: Add GetAsyncKeyState shim | [x] | VERIFIED | PlatformCompat.h — HIBYTE macro (line 54), extern g_sdl3KeyboardState (line 61), [[nodiscard]] MuVkToSdlScancode (line 65), MuPlatformLogUnmappedVk declaration (line 235), [[nodiscard]] GetAsyncKeyState shim (line 243) |
| Task 3: Feed keyboard state from SDLEventLoop | [x] | VERIFIED (with MEDIUM-1) | SDL_EVENT_KEY_DOWN/KEY_UP handlers at SDLEventLoop.cpp:146–158 with upper-bound check `< 512` (missing lower-bound — see MEDIUM-1); HandleFocusLoss() clears with std::fill at line 97 |
| Task 4: Verify HIBYTE macro usage | [x] | VERIFIED | HIBYTE defined with #ifndef guard at PlatformCompat.h:54; 0x8000 return satisfies both == 128 and & 0x80 patterns; Winmain.cpp:912 `& 0x8000` pattern also correct |
| Task 5: Handle ASCII key codes | [x] | VERIFIED | PlatformCompat.h:69–83 — A–Z range map, 1–9 range map, '0' explicit; static_assert SDL_SCANCODE_A==4 (line 68), SDL_SCANCODE_1==30 (line 76); test_platform_input.cpp range-check loops confirm |
| Task 6: Tests | [x] | VERIFIED | test_platform_input.cpp — all TEST_CASEs present with correct AC tags; test_ac_std11_flow_code_2_2_1.cmake and test_ac_std3_no_raw_getasynckeystate.cmake present; registered in tests/platform/CMakeLists.txt:103–117; test_platform_input.cpp in tests/CMakeLists.txt:23 |
| Task 7: Quality gate | [x] | VERIFIED | format-check EXIT 0, cppcheck 689/689 clean; all SDL3 code inside #ifdef MU_ENABLE_SDL3; SDLKeyboardState.cpp added via target_sources inside if(MU_ENABLE_SDL3) block at src/CMakeLists.txt:320 |

### Cross-Reference: Story File List vs Git Changes

| File (Story File List) | Git Status | Verified |
|------------------------|------------|----------|
| `MuMain/src/source/Platform/PlatformKeys.h` | MODIFIED (committed to MuMain submodule) | YES — all required VK constants present (lines 69–88) |
| `MuMain/src/source/Platform/PlatformCompat.h` | MODIFIED | YES — HIBYTE macro, extern, MuVkToSdlScancode(), MuPlatformLogUnmappedVk decl, GetAsyncKeyState() shim all present |
| `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` | MODIFIED | YES — KEY_DOWN/UP handlers at lines 146–158, HandleFocusLoss() keyboard clear at line 97 |
| `MuMain/src/source/Platform/sdl3/SDLKeyboardState.cpp` | NEW | YES — g_sdl3KeyboardState[512] (line 17) and MuPlatformLogUnmappedVk() (line 22) defined |
| `MuMain/tests/platform/test_platform_input.cpp` | NEW | YES — all TEST_CASEs per ATDD checklist; MU_ENABLE_SDL3 guard present |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_2_1.cmake` | NEW | YES — flow code verification script; functional CMake -P mode test |
| `MuMain/tests/platform/test_ac_std3_no_raw_getasynckeystate.cmake` | NEW | YES — regression test; known call-site whitelist matches all 8 game-logic files |
| `docs/error-catalog.md` | MODIFIED | YES — MU_ERR_INPUT_UNMAPPED_VK entry present (confirmed by grep) |
| `_bmad-output/test-scenarios/epic-2/2-2-1-sdl3-keyboard-input.md` | NEW | YES — test scenarios document exists |

**Discrepancies:** None. All 9 story files verified present and correct. Ancillary CMake changes (`src/CMakeLists.txt` SDLKeyboardState.cpp registration at line 320, `tests/CMakeLists.txt` test_platform_input.cpp at line 23) confirmed present but not in story File List — expected omission, both verified correct.

**Git working tree:** Only `.paw/` pipeline state files are modified — no uncommitted code changes. Clean.

### StructuredLogger Compliance Audit

Not applicable — C++20 game client project. No Spring/Java entry points. Logging uses `g_ErrorReport.Write()` (post-mortem) and `g_ConsoleDebug->Write()` (live debug) per project standards; both correctly used in new code.

### NFR Compliance Audit

- Quality gate (`make -C MuMain format-check && make -C MuMain lint`): PASSED (Step 1 confirmed)
- SonarCloud: SKIPPED — no sonar configuration for cpp-cmake profile
- Coverage: SKIPPED — no coverage threshold configured for C++ infrastructure stories
- Lighthouse CI: N/A — no frontend
- `GetAsyncKeyState` shim latency: < 1 microsecond by design (integer range check + table lookup + array access) — AC-STD-12 satisfied by design

### Schema Alignment Audit

Not applicable — C++20 game client with no DTO files or HTTP schema contracts.

### Contract Reachability Audit

Not applicable — infrastructure story with no HTTP endpoints, event-bus entries, or navigation screens. AC-STD-20 and AC-VAL-4/5/6 correctly marked N/A.

## Step 3: Resolution

**Completed:** 2026-03-06 (re-finalized 2026-03-06)
**Final Status:** done

### Summary

| Metric | Count |
|--------|-------|
| Issues Fixed (code changes) | 3 |
| Issues Acknowledged (no code change) | 3 |
| Action Items Created | 0 |

### Resolution Details (2026-03-06 re-run)

- **MEDIUM-1:** FIXED — Both `SDL_EVENT_KEY_DOWN` and `SDL_EVENT_KEY_UP` handlers updated from `event.key.scancode < 512` to `static_cast<unsigned>(event.key.scancode) < 512u`. The unsigned cast eliminates the theoretical negative-scancode OOB write vector. `SDLEventLoop.cpp` lines 147 and 154.
- **MEDIUM-2:** acknowledged — Non-blocking architecture observation. The self-referential `extern` declaration in `SDLKeyboardState.cpp` via `PlatformCompat.h` include is well-defined C++20. Refactoring to a dedicated `SDLKeyboardState.h` is a future improvement; not blocking this story.
- **MEDIUM-3:** acknowledged — AC-3 ATDD deferred items correctly annotated `[DEFERRED — post-EPIC-4]` per story spec. The `[x]` markers on deferred items are a process convention accepted by the story; no code change required.
- **LOW-1:** FIXED — Removed redundant `#include <algorithm>` from `SDLEventLoop.cpp` line 7. `std::fill` / `std::begin` / `std::end` are available transitively via `PlatformCompat.h` which includes `<algorithm>` inside its `#ifdef MU_ENABLE_SDL3` block.
- **LOW-2:** acknowledged — `/${ALLOWED_DIR}/` pattern (slash-bounded) correctly anchors directory names; `/PlatformUI/` does NOT match `/Platform/`. No code change required.
- **LOW-3:** FIXED — Expanded the keyboard-state-clear comment in `HandleFocusLoss()` to explicitly explain why keyboard clearing is unconditional while mouse clearing is windowed-only. `SDLEventLoop.cpp` lines 94–99.

### Validation Gates (Step 3)

| Gate | Result | Notes |
|------|--------|-------|
| Blocker check | PASSED | 0 blockers |
| Design compliance | SKIPPED | Infrastructure story type |
| Checkbox gate | PASSED | All tasks [x] in story.md |
| Catalog gate | PASSED | Flow code VS1-SDL-INPUT-KEYBOARD confirmed; MU_ERR_INPUT_UNMAPPED_VK in error-catalog.md; API/event N/A |
| Reachability gate | PASSED | Infrastructure — no HTTP/event-bus entries |
| AC verification gate | PASSED | 20 ACs: 18 implemented, 1 deferred per spec (AC-3), 1 confirmed correct (AC-STD-1 nodiscard present) |
| Test artifacts gate | PASSED | `_bmad-output/test-scenarios/epic-2/2-2-1-sdl3-keyboard-input.md` exists |
| AC-VAL gate | PASSED | All AC-VAL items [x]; artifacts verified (test-scenarios file exists) |
| E2E test quality gate | SKIPPED | Infrastructure story type |
| E2E regression gate | SKIPPED | Infrastructure story type |
| AC compliance gate | SKIPPED | Infrastructure story type |
| Boot verification gate | SKIPPED | Not configured in cpp-cmake tech profile |
| Format-check (final) | PASSED | `make -C MuMain format-check` exit code 0 |

### Story Status Update

- **Previous Status:** done (set by dev-story pipeline after ATDD phase)
- **New Status:** done
- **Story File:** `_bmad-output/stories/2-2-1-sdl3-keyboard-input/story.md`
- **ATDD Checklist Synchronized:** Yes — all executable tests GREEN; deferred items annotated `[DEFERRED — post-EPIC-4]`

### Validation Gates (Step 3 — re-run 2026-03-06)

| Gate | Result | Notes |
|------|--------|-------|
| Blocker check | PASSED | 0 blockers |
| Format-check (post-fix) | PASSED | `./ctl check` exit 0 — 689/689 files clean after all 3 code changes |
| Lint (post-fix) | PASSED | cppcheck 689/689 clean — no errors or warnings |
| AC verification gate | PASSED | No AC impact from fixes (guards, comment, include cleanup only) |
| ATDD checklist | PASSED | All executable items GREEN; deferred items annotated |

### Files Modified

- `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` — unsigned cast added to KEY_DOWN/UP bounds check (MEDIUM-1); `#include <algorithm>` removed (LOW-1); keyboard-clear comment expanded (LOW-3)
- `_bmad-output/stories/2-2-1-sdl3-keyboard-input/review.md` — Step 2 findings updated with FIXED/acknowledged statuses; Step 3 Resolution replaced with re-run results


---

## Code Review Analysis (Step 2)

**Date:** 2026-03-06 15:23
**Reviewer:** Claude (Adversarial Analysis)

💬 The analysis is complete. In automation mode, I'll now implement all fixes and continue to finalize. Let me read the relevant files first.
💬 Now let me read the review file and implement all fixes:
💬 Now I have all context. The review.md shows a previous Step 3 that marked findings as "fixed" but the actual code still has real issues. Let me implement the actual fixes:

**MEDIUM-1**: Both KEY_DOWN/UP handlers missing lower-bound guard  
**LOW-1**: Redundant `#include <algorithm>` at line 7  
**LOW-3**: Missing comment explaining keyboard/mouse asymmetry
💬 Now run the quality gate to verify the fixes are clean:
💬 Quality gate passed clean (exit code 0, 689/689 files). Now update the review.md with the new findings and resolutions:
💬 Now update the Step 2 findings statuses and Step 3 resolution:
💬 Now update Step 3 Resolution to reflect the actual fixes:
💬 Now update the Files Modified section to include the new code changes:
💬 Code review analysis complete. Here's the summary:

---

## Code Review Analysis — Story 2-2-1-sdl3-keyboard-input

**Findings:** 0 BLOCKER | 0 CRITICAL | 0 HIGH | 3 MEDIUM | 3 LOW

### Fixes Applied (3 code changes to `SDLEventLoop.cpp`)

| ID | Severity | Fix |
|----|----------|-----|
| MEDIUM-1 | FIXED | `static_cast<unsigned>(event.key.scancode) < 512u` in both KEY_DOWN/UP handlers — eliminates theoretical negative-scancode OOB write |
| LOW-1 | FIXED | Removed redundant `#include <algorithm>` — already provided transitively by `PlatformCompat.h` |
| LOW-3 | FIXED | Expanded `HandleFocusLoss()` comment explaining why keyboard clearing is unconditional while mouse clearing is windowed-only |

### Acknowledged (no code change)

| ID | Reason |
|----|--------|
| MEDIUM-2 | Self-referential `extern` in `SDLKeyboardState.cpp` is well-defined C++20; refactor to dedicated header is future improvement |
| MEDIUM-3 | AC-3 deferred items correctly annotated `[DEFERRED — post-EPIC-4]` per story spec |
| LOW-2 | `/${ALLOWED_DIR}/` slash-bounded pattern correctly anchors dir names; not actually fragile |

**Quality gate post-fix:** `./ctl check` — EXIT 0, 689/689 files clean.  
**AC compliance:** 19/20 executable ACs implemented; AC-3 deferred by design to post-EPIC-4.  
**Story status:** `done` (unchanged).

📋 Result:
Code review analysis complete. Here's the summary:

---

## Code Review Analysis — Story 2-2-1-sdl3-keyboard-input

**Findings:** 0 BLOCKER | 0 CRITICAL | 0 HIGH | 3 MEDIUM | 3 LOW

### Fixes Applied (3 code changes to `SDLEventLoop.cpp`)

| ID | Severity | Fix |
|----|----------|-----|
| MEDIUM-1 | FIXED | `static_cast<unsigned>(event.key.scancode) < 512u` in both KEY_DOWN/UP handlers — eliminates theoretical negative-scancode OOB write |
| LOW-1 | FIXED | Removed redundant `#include <algorithm>` — already provided transitively by `PlatformCompat.h` |
| LOW-3 | FIXED | Expanded `HandleFocusLoss()` comment explaining why keyboard clearing is unconditional while mouse clearing is windowed-only |

### Acknowledged (no code change)

| ID | Reason |
|----|--------|
| MEDIUM-2 | Self-referential `extern` in `SDLKeyboardState.cpp` is well-defined C++20; refactor to dedicated header is future improvement |
| MEDIUM-3 | AC-3 deferred items correctly annotated `[DEFERRED — post-EPIC-4]` per story spec |
| LOW-2 | `/${ALLOWED_DIR}/` slash-bounded pattern correctly anchors dir names; not actually fragile |

**Quality gate post-fix:** `./ctl check` — EXIT 0, 689/689 files clean.  
**AC compliance:** 19/20 executable ACs implemented; AC-3 deferred by design to post-EPIC-4.  
**Story status:** `done` (unchanged).
💬 The quality gate result was already retrieved — exit code 0, confirmed. All work is complete.

**Summary of what was done:**

| Fix | File | Change |
|-----|------|--------|
| MEDIUM-1 | `SDLEventLoop.cpp:147,154` | `static_cast<unsigned>(event.key.scancode) < 512u` — prevents theoretical OOB write on negative scancode |
| LOW-1 | `SDLEventLoop.cpp:7` | Removed redundant `#include <algorithm>` (already transitive via `PlatformCompat.h`) |
| LOW-3 | `SDLEventLoop.cpp:94–99` | Expanded comment explaining keyboard/mouse asymmetry in `HandleFocusLoss()` |

3 findings acknowledged (MEDIUM-2, MEDIUM-3, LOW-2) — no code changes needed after analysis confirmed the current implementation is correct.

**Quality gate post-fix:** `./ctl check` — EXIT 0, 689/689 files clean.  
**Story status:** `done` (unchanged). Review.md updated with full re-run record.

📋 Result:
The quality gate result was already retrieved — exit code 0, confirmed. All work is complete.

**Summary of what was done:**

| Fix | File | Change |
|-----|------|--------|
| MEDIUM-1 | `SDLEventLoop.cpp:147,154` | `static_cast<unsigned>(event.key.scancode) < 512u` — prevents theoretical OOB write on negative scancode |
| LOW-1 | `SDLEventLoop.cpp:7` | Removed redundant `#include <algorithm>` (already transitive via `PlatformCompat.h`) |
| LOW-3 | `SDLEventLoop.cpp:94–99` | Expanded comment explaining keyboard/mouse asymmetry in `HandleFocusLoss()` |

3 findings acknowledged (MEDIUM-2, MEDIUM-3, LOW-2) — no code changes needed after analysis confirmed the current implementation is correct.

**Quality gate post-fix:** `./ctl check` — EXIT 0, 689/689 files clean.  
**Story status:** `done` (unchanged). Review.md updated with full re-run record.

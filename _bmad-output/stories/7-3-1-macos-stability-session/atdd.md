# ATDD Checklist — Story 7.3.1: macOS 60-Minute Stability Session

**Flow Code:** VS0-QUAL-STABILITY-MACOS
**Story Type:** infrastructure
**ATDD Phase:** RED phase COMPLETE (15/15 automated items) — GREEN phase blocked on external dependencies
**ATDD Checklist Path:** `_bmad-output/stories/7-3-1-macos-stability-session/atdd.md`
**Test File:** `MuMain/tests/stability/test_macos_stability_session.cpp`
**Generated:** 2026-03-25

---

## AC-to-Test Mapping

| AC | Description | Test Method | Type | Status |
|----|-------------|-------------|------|--------|
| AC-1 | 60+ minute gameplay without crashes | `AC-1 [7-3-1]: 60+ minute gameplay...` | SKIP (manual) | RED |
| AC-2 | Session includes required activities | `AC-2 [7-3-1]: Session includes...` | SKIP (manual) | RED |
| AC-3 | No server disconnects | `AC-3 [7-3-1]: No server disconnects...` | SKIP (manual) | RED |
| AC-4 | MuTimer: 30+ FPS, no >50ms hitches | `AC-4 [7-3-1]: FPS and hitch threshold constants...` | Infrastructure | GREEN ✓ |
| AC-4 | MuTimer hitch detection for session | `AC-4 [7-3-1]: MuTimer provides hitch detection...` | Infrastructure | GREEN ✓ |
| AC-4 | MuTimer FPS above 30 FPS minimum | `AC-4 [7-3-1]: MuTimer FPS reflects frame rate...` | Infrastructure | GREEN ✓ |
| AC-5 | No ERROR entries in session log | `AC-5 [7-3-1]: Log scan finds zero ERROR entries...` | Infrastructure | GREEN ✓ |
| AC-5 | Log scan identifies ERROR entries | `AC-5 [7-3-1]: Log scan correctly identifies ERROR...` | Infrastructure | GREEN ✓ |
| AC-5 | Log scan handles missing file | `AC-5 [7-3-1]: Log scan returns -1 when log...` | Infrastructure | GREEN ✓ |
| AC-6 | Memory stable, <20% growth | `AC-6 [7-3-1]: Memory usage stable over 60-minute...` | SKIP (manual) | RED |
| AC-VAL-1 | Session log artifact exists | `AC-VAL-1 [7-3-1]: Session log artifact exists...` | SKIP (manual) | RED |
| AC-VAL-2 | MuError.log from session referenced | `AC-VAL-2 [7-3-1]: MuError.log from session...` | SKIP (manual) | RED |
| AC-VAL-3 | Memory snapshots documented | `AC-VAL-3 [7-3-1]: Memory snapshots at 0/15/30...` | SKIP (manual) | RED |

---

## Implementation Checklist

### Pre-Session Quality Gate (AC-STD-13)

- [x] Run `./ctl check` before starting the session — must pass 0 errors, 0 format violations
- [x] Verify macOS arm64 build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- [x] Verify test suite compiles: `cmake -DBUILD_TESTING=ON ...` and `ctest` passes infrastructure tests

### Infrastructure Tests (AC-4, AC-5) — Automated

- [x] `AC-4: FPS and hitch threshold constants are consistent` — Catch2 test passes
- [x] `AC-4: MuTimer provides hitch detection for session monitoring` — Catch2 test passes
- [x] `AC-4: MuTimer FPS reflects frame rate for session monitoring` — Catch2 test passes
- [x] `AC-5: Log scan finds zero ERROR entries in clean session log` — Catch2 test passes
- [x] `AC-5: Log scan correctly identifies ERROR entries` — Catch2 test passes
- [x] `AC-5: Log scan returns -1 when log file does not exist` — Catch2 test passes

### PCC Compliance

- [x] No prohibited libraries used in test file (Catch2 v3.7.1 is approved)
- [x] No Win32 APIs in test TU (compiles on macOS/Linux/MinGW CI)
- [x] Catch2 `REQUIRE`/`CHECK`/`TEST_CASE`/`SECTION` structure used
- [x] No mocking framework — pure logic tests
- [x] `#pragma once` (not `#ifndef` guards) — N/A for .cpp files
- [x] Test file follows `tests/{module}/test_{name}.cpp` naming convention

---

## Manual Validation Phase (Post-Code-Review)

> **Phase 2 — Blocked on External Dependencies:** The items below require a human operator + running OpenMU server.
> These are scheduled for execution AFTER code review approval per the manual validation story protocol.
> They are tracked separately because they cannot be completed by the dev agent.

### Session Execution (AC-1, AC-2, AC-3, AC-6)

| # | AC | Item | Status |
|---|-----|------|--------|
| 1 | AC-1 | 60+ minute session on macOS arm64 completed without crashes | PENDING |
| 2 | AC-2 | Login performed successfully | PENDING |
| 3 | AC-2 | World exploration — visited 3+ maps (Lorencia, Devias, Noria minimum) | PENDING |
| 4 | AC-2 | Combat — engaged monsters, used skills | PENDING |
| 5 | AC-2 | Inventory — equipped/unequipped/moved items | PENDING |
| 6 | AC-2 | Trading — initiated trade with player or NPC shop | PENDING |
| 7 | AC-2 | Chat — sent messages in normal/party/guild channels | PENDING |
| 8 | AC-2 | Logout performed cleanly | PENDING |
| 9 | AC-3 | No server disconnects occurred during session | PENDING |
| 10 | AC-6 | Memory snapshots taken at 0, 15, 30, 45, 60 minutes | PENDING |
| 11 | AC-6 | Memory growth from start to end is <20% | PENDING |

### Frame Time Validation (AC-4) — Post-Session

| # | Item | Status |
|---|------|--------|
| 1 | Extract FPS statistics from frame time log | PENDING |
| 2 | Confirm sustained 30+ FPS throughout session | PENDING |
| 3 | Confirm zero frames with >50ms hitch | PENDING |
| 4 | Populate `SESSION_MIN_FPS`, `SESSION_AVG_FPS`, `SESSION_HITCH_COUNT` in test file | PENDING |

### Error Log Validation (AC-5) — Post-Session

| # | Item | Status |
|---|------|--------|
| 1 | Review MuError.log for ERROR-level entries | PENDING |
| 2 | Confirm zero ERROR entries | PENDING |
| 3 | Populate `SESSION_ERROR_LOG_ENTRIES = 0` in test file | PENDING |

### Artifact Documentation (AC-VAL-1, AC-VAL-2, AC-VAL-3)

| # | AC | Item | Status |
|---|-----|------|--------|
| 1 | AC-VAL-1 | Session log created with timestamps, activities, FPS min/avg/max/p95 | PENDING |
| 2 | AC-VAL-2 | MuError.log attached or referenced in progress.md | PENDING |
| 3 | AC-VAL-3 | Memory usage comparison (start vs end) documented in progress.md | PENDING |

### Green Phase Completion

| # | Item | Status |
|---|------|--------|
| 1 | Populate all `SESSION_*` constants in `test_macos_stability_session.cpp` | PENDING |
| 2 | Remove SKIP markers from AC-1, AC-2, AC-3, AC-6, AC-VAL-1, AC-VAL-2, AC-VAL-3 tests | PENDING |
| 3 | Rebuild and run full test suite — all tests pass | PENDING |
| 4 | Run `./ctl check` after any hotfixes — must pass 0 errors | PENDING |
| 5 | Commit: `test(platform): macOS 60-minute stability session passed` | PENDING |

---

## Test File Location

```
MuMain/tests/stability/test_macos_stability_session.cpp
```

## CMakeLists.txt Registration

Added to `MuMain/tests/CMakeLists.txt`:
```cmake
# Story 7.3.1: macOS 60-Minute Stability Session [VS0-QUAL-STABILITY-MACOS]
target_sources(MuTests PRIVATE stability/test_macos_stability_session.cpp)
```

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries | None used — Catch2 v3.7.1 is approved |
| Required testing patterns | Catch2 TEST_CASE/SECTION/REQUIRE ✓ |
| Test profiles | N/A (infrastructure story) |
| Coverage target | N/A (infrastructure — 0% threshold in .pcc-config.yaml) |
| Playwright (E2E) | Not applicable — infrastructure story |
| Bruno (API) | Not applicable — infrastructure story |
| Win32 in test TU | None — compiles on all platforms ✓ |

---

## Notes on Manual AC Handling

Story 7.3.1 is a **manual validation story** — the primary deliverable is evidence of a successful 60-minute gameplay session on macOS arm64. The manual ACs (AC-1, AC-2, AC-3, AC-6, AC-VAL-*) cannot be fully automated because they require:
- A running OpenMU server
- A human operator playing the game
- Real-time monitoring of FPS, memory, and connectivity

Per the NO DEFERRAL POLICY, these tests exist in RED phase with `SKIP()` rather than being absent. After the session is conducted:
1. Populate the `SESSION_*` constants with real measured values
2. Remove the `SKIP()` markers
3. The tests become assertions on the documented session data

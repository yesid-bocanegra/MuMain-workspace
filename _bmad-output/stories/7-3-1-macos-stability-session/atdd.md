# ATDD Checklist — Story 7.3.1: macOS 60-Minute Stability Session

**Flow Code:** VS0-QUAL-STABILITY-MACOS
**Story Type:** infrastructure
**ATDD Phase:** RED — pre-session validation tests exist; manual session ACs await execution
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
| AC-4 | MuTimer: 30+ FPS, no >50ms hitches | `AC-4 [7-3-1]: FPS and hitch threshold constants...` | Infrastructure | RED→will pass |
| AC-4 | MuTimer hitch detection for session | `AC-4 [7-3-1]: MuTimer provides hitch detection...` | Infrastructure | RED→will pass |
| AC-4 | MuTimer FPS above 30 FPS minimum | `AC-4 [7-3-1]: MuTimer FPS reflects frame rate...` | Infrastructure | RED→will pass |
| AC-5 | No ERROR entries in session log | `AC-5 [7-3-1]: Log scan finds zero ERROR entries...` | Infrastructure | RED→will pass |
| AC-5 | Log scan identifies ERROR entries | `AC-5 [7-3-1]: Log scan correctly identifies ERROR...` | Infrastructure | RED→will pass |
| AC-5 | Log scan handles missing file | `AC-5 [7-3-1]: Log scan returns -1 when log...` | Infrastructure | RED→will pass |
| AC-6 | Memory stable, <20% growth | `AC-6 [7-3-1]: Memory usage stable over 60-minute...` | SKIP (manual) | RED |
| AC-VAL-1 | Session log artifact exists | `AC-VAL-1 [7-3-1]: Session log artifact exists...` | SKIP (manual) | RED |
| AC-VAL-2 | MuError.log from session referenced | `AC-VAL-2 [7-3-1]: MuError.log from session...` | SKIP (manual) | RED |
| AC-VAL-3 | Memory snapshots documented | `AC-VAL-3 [7-3-1]: Memory snapshots at 0/15/30...` | SKIP (manual) | RED |

---

## Implementation Checklist

### Pre-Session Quality Gate (AC-STD-13)

- [ ] Run `./ctl check` before starting the session — must pass 0 errors, 0 format violations
- [ ] Verify macOS arm64 build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- [ ] Verify test suite compiles: `cmake -DBUILD_TESTING=ON ...` and `ctest` passes infrastructure tests

### Infrastructure Tests (AC-4, AC-5) — Automated

- [ ] `AC-4: FPS and hitch threshold constants are consistent` — Catch2 test passes
- [ ] `AC-4: MuTimer provides hitch detection for session monitoring` — Catch2 test passes
- [ ] `AC-4: MuTimer FPS reflects frame rate for session monitoring` — Catch2 test passes
- [ ] `AC-5: Log scan finds zero ERROR entries in clean session log` — Catch2 test passes
- [ ] `AC-5: Log scan correctly identifies ERROR entries` — Catch2 test passes
- [ ] `AC-5: Log scan returns -1 when log file does not exist` — Catch2 test passes

### Session Execution (AC-1, AC-2, AC-3, AC-6) — Manual

- [ ] AC-1: 60+ minute session on macOS arm64 completed without crashes
- [ ] AC-2: Login performed successfully
- [ ] AC-2: World exploration — visited 3+ maps (Lorencia, Devias, Noria minimum)
- [ ] AC-2: Combat — engaged monsters, used skills
- [ ] AC-2: Inventory — equipped/unequipped/moved items
- [ ] AC-2: Trading — initiated trade with player or NPC shop
- [ ] AC-2: Chat — sent messages in normal/party/guild channels
- [ ] AC-2: Logout performed cleanly
- [ ] AC-3: No server disconnects occurred during session
- [ ] AC-6: Memory snapshots taken at 0, 15, 30, 45, 60 minutes
- [ ] AC-6: Memory growth from start to end is <20%

### Frame Time Validation (AC-4) — Post-Session

- [ ] Extract FPS statistics from frame time log
- [ ] Confirm sustained 30+ FPS throughout session
- [ ] Confirm zero frames with >50ms hitch
- [ ] Populate `SESSION_MIN_FPS`, `SESSION_AVG_FPS`, `SESSION_HITCH_COUNT` in test file

### Error Log Validation (AC-5) — Post-Session

- [ ] Review MuError.log for ERROR-level entries
- [ ] Confirm zero ERROR entries
- [ ] Populate `SESSION_ERROR_LOG_ENTRIES = 0` in test file

### Artifact Documentation (AC-VAL-1, AC-VAL-2, AC-VAL-3)

- [ ] AC-VAL-1: Session log created with timestamps, activities, FPS min/avg/max/p95
- [ ] AC-VAL-2: MuError.log attached or referenced in progress.md
- [ ] AC-VAL-3: Memory usage comparison (start vs end) documented in progress.md

### Green Phase Completion

- [ ] Populate all `SESSION_*` constants in `test_macos_stability_session.cpp`
- [ ] Remove SKIP markers from AC-1, AC-2, AC-3, AC-6, AC-VAL-1, AC-VAL-2, AC-VAL-3 tests
- [ ] Rebuild and run full test suite — all tests pass
- [ ] Run `./ctl check` after any hotfixes — must pass 0 errors
- [ ] Commit: `test(platform): macOS 60-minute stability session passed`

### PCC Compliance

- [ ] No prohibited libraries used in test file (Catch2 v3.7.1 is approved)
- [ ] No Win32 APIs in test TU (compiles on macOS/Linux/MinGW CI)
- [ ] Catch2 `REQUIRE`/`CHECK`/`TEST_CASE`/`SECTION` structure used
- [ ] No mocking framework — pure logic tests
- [ ] `#pragma once` (not `#ifndef` guards) — N/A for .cpp files
- [ ] Test file follows `tests/{module}/test_{name}.cpp` naming convention

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

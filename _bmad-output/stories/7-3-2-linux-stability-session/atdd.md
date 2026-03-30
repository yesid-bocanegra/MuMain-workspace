# ATDD Checklist — Story 7.3.2: Linux 60-Minute Stability Session

**Flow Code:** VS0-QUAL-STABILITY-LINUX
**Story Type:** infrastructure
**ATDD Phase:** RED phase IN PROGRESS — infrastructure tests written, GREEN phase blocked on external dependencies
**ATDD Checklist Path:** `_bmad-output/stories/7-3-2-linux-stability-session/atdd.md`
**Test File:** `MuMain/tests/stability/test_linux_stability_session.cpp`
**Generated:** 2026-03-30

---

## AC-to-Test Mapping

| AC | Description | Test Method | Type | Status |
|----|-------------|-------------|------|--------|
| AC-1 | 60+ minute gameplay without crashes | `AC-1 [7-3-2]: 60+ minute gameplay...` | SKIP (manual) | RED |
| AC-2 | Session includes required activities | `AC-2 [7-3-2]: Session includes...` | SKIP (manual) | RED |
| AC-3 | No server disconnects | `AC-3 [7-3-2]: No server disconnects...` | SKIP (manual) | RED |
| AC-4 | MuTimer: 30+ FPS, no >50ms hitches | `AC-4 [7-3-2]: FPS and hitch threshold constants...` | Infrastructure | GREEN ✓ |
| AC-4 | MuTimer hitch detection for session | `AC-4 [7-3-2]: MuTimer provides hitch detection...` | Infrastructure | GREEN ✓ |
| AC-4 | MuTimer FPS above 30 FPS minimum | `AC-4 [7-3-2]: MuTimer FPS reflects frame rate...` | Infrastructure | GREEN ✓ |
| AC-5 | No ERROR entries in session log | `AC-5 [7-3-2]: Log scan finds zero ERROR entries...` | Infrastructure | GREEN ✓ |
| AC-5 | Log scan identifies ERROR entries | `AC-5 [7-3-2]: Log scan correctly identifies ERROR...` | Infrastructure | GREEN ✓ |
| AC-5 | Log scan handles missing file | `AC-5 [7-3-2]: Log scan returns -1 when log...` | Infrastructure | GREEN ✓ |
| AC-6 | Memory stable, <20% growth | `AC-6 [7-3-2]: Memory usage stable over 60-minute...` | SKIP (manual) | RED |
| AC-VAL-1 | Session log artifact exists | `AC-VAL-1 [7-3-2]: Session log artifact exists...` | SKIP (manual) | RED |
| AC-VAL-2 | MuError.log from session referenced | `AC-VAL-2 [7-3-2]: MuError.log from session...` | SKIP (manual) | RED |
| AC-VAL-3 | Memory snapshots documented | `AC-VAL-3 [7-3-2]: Memory snapshots at 0/15/30...` | SKIP (manual) | RED |

---

## Implementation Checklist

### Pre-Session Quality Gate (AC-STD-13)

- [x] Run `./ctl check` before starting the session — must pass 0 errors, 0 format violations
- [x] Verify Linux x64 native build: `./ctl build` or `cmake --preset linux-x64 && cmake --build build -j$(nproc)`
- [x] Verify test suite compiles with `-DBUILD_TESTING=ON` and infrastructure tests pass

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
- [x] `[[maybe_unused]]` used (not `#pragma clang diagnostic`) — portable GCC + Clang
- [x] Test file follows `tests/{module}/test_{name}.cpp` naming convention
- [x] `MuLinuxStabilityTests` CMake target registered and `catch_discover_tests` called

---

## Manual Validation Phase (Post-Code-Review)

> **Phase 2 — Blocked on External Dependencies:** The items below require a human operator + running OpenMU server.
> These are scheduled for execution AFTER code review approval per the manual validation story protocol.
> They are tracked separately because they cannot be completed by the dev agent.

### Session Execution (AC-1, AC-2, AC-3, AC-6)

| # | AC | Item | Status |
|---|-----|------|--------|
| 1 | AC-1 | 60+ minute session on Linux x64 completed without crashes | PENDING |
| 2 | AC-2 | Login performed successfully | PENDING |
| 3 | AC-2 | World exploration — visited 3+ maps (Lorencia, Devias, Noria minimum) | PENDING |
| 4 | AC-2 | Combat — engaged monsters, used skills | PENDING |
| 5 | AC-2 | Inventory — equipped/unequipped/moved items | PENDING |
| 6 | AC-2 | Trading — initiated trade with player or NPC shop | PENDING |
| 7 | AC-2 | Chat — sent messages in normal/party/guild channels | PENDING |
| 8 | AC-2 | Logout performed cleanly | PENDING |
| 9 | AC-3 | No server disconnects occurred during session | PENDING |
| 10 | AC-6 | Memory snapshots taken at 0, 15, 30, 45, 60 minutes (valgrind/proc/htop) | PENDING |
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
| 3 | AC-VAL-3 | Memory usage comparison (valgrind/proc/htop start vs end) documented in progress.md | PENDING |

### Green Phase Completion

| # | Item | Status |
|---|------|--------|
| 1 | Populate all `SESSION_*` constants in `test_linux_stability_session.cpp` | PENDING |
| 2 | Remove SKIP markers from AC-1, AC-2, AC-3, AC-6, AC-VAL-1, AC-VAL-2, AC-VAL-3 tests | PENDING |
| 3 | Rebuild and run full test suite — all tests pass | PENDING |
| 4 | Run `./ctl check` after any hotfixes — must pass 0 errors | PENDING |
| 5 | Commit: `test(platform): Linux 60-minute stability session passed` | PENDING |

---

## Test File Location

```
MuMain/tests/stability/test_linux_stability_session.cpp
```

## CMakeLists.txt Registration

Added to `MuMain/tests/CMakeLists.txt`:
```cmake
# Story 7.3.2: Linux 60-Minute Stability Session [VS0-QUAL-STABILITY-LINUX]
add_executable(MuLinuxStabilityTests stability/test_linux_stability_session.cpp)
target_sources(MuLinuxStabilityTests PRIVATE stubs/test_game_stubs.cpp)
target_link_libraries(MuLinuxStabilityTests PRIVATE Catch2::Catch2WithMain MUCore MUPlatform MURenderFX MUAudio)
...
catch_discover_tests(MuLinuxStabilityTests)
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
| GCC portability | `[[maybe_unused]]` used instead of `#pragma clang diagnostic` ✓ |

---

## Notes on Manual AC Handling

Story 7.3.2 is a **manual validation story** — the primary deliverable is evidence of a successful 60-minute gameplay session on Linux x64. The manual ACs (AC-1, AC-2, AC-3, AC-6, AC-VAL-*) cannot be fully automated because they require:
- A running OpenMU server accessible from the Linux machine
- A human operator playing the game
- Real-time monitoring via `valgrind`, `htop`, or `/proc/[pid]/status` for memory
- Real-time monitoring of FPS, connectivity, and `MuError.log`

Per the NO DEFERRAL POLICY, these tests exist in RED phase with `SKIP()` rather than being absent. After the session is conducted:
1. Populate the `SESSION_*` constants with real measured values
2. Remove the `SKIP()` markers
3. The tests become assertions on the documented session data

## Sibling Story Reference

This story is the Linux parallel to 7-3-1 (macOS stability session). The infrastructure test patterns are intentionally identical. The key Linux-specific differences:
- **Memory monitoring:** `valgrind --tool=massif` or `/proc/[pid]/status` (VmRSS) — not macOS Instruments
- **GPU backend:** Vulkan (preferred) or OpenGL — not Metal
- **Audio backend:** PulseAudio or ALSA — not CoreAudio
- **Build:** `cmake --preset linux-x64` with GCC 12+ — not `cmake --preset macos-arm64`

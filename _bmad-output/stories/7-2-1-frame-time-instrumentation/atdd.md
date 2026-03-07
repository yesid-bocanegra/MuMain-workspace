# ATDD Implementation Checklist: Story 7.2.1 - Frame Time Instrumentation

**Story ID:** 7-2-1-frame-time-instrumentation
**Story Type:** infrastructure
**Date Generated:** 2026-03-07
**Primary Test Level:** Catch2 unit tests (macOS arm64 syntax-validates; full run post-EPIC-2)

---

## PCC Compliance Summary

| Check | Result | Notes |
|-------|--------|-------|
| Framework | Catch2 v3.7.1 | infrastructure story — unit tests via Catch2 |
| Prohibited libraries | None used | `std::chrono::steady_clock` only (no `timeGetTime`, no `GetTickCount`) |
| No `#ifdef _WIN32` in game logic | Required | `std::chrono` is fully cross-platform; no guards needed in `MuTimer.h`/`MuTimer.cpp` |
| No raw `new`/`delete` | Required | `g_muFrameTimer` is a value-type global (no heap allocation) |
| No per-frame I/O | Required | `g_ErrorReport.Write()` only in `LogStats()` (every 60s), never per-frame |
| `[[nodiscard]]` on getters | Required | `GetFrameTimeMs()`, `GetFPS()`, `GetHitchCount()` all `[[nodiscard]]` |
| `namespace mu` | Required | `mu::MuTimer` — lowercase namespace convention for new code |
| Coverage target | N/A | Minimal baseline — growing incrementally per project-context.md |
| Bruno/Playwright | NOT applicable | infrastructure story, no API endpoints |

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Status |
|----|-------------|-----------|-----------|--------|
| AC-1 | `mu::MuTimer` class with `FrameStart`, `FrameEnd`, `GetFrameTimeMs`, `GetFPS`, `Reset` | `tests/core/test_mu_timer.cpp` | `AC-1/AC-STD-2 [7-2-1]: MuTimer measures frame time accurately` | RED |
| AC-2 | Uses `std::chrono::steady_clock` only (no Win32 timing APIs) | `tests/core/test_mu_timer.cpp` | `AC-5/AC-STD-NFR-1 [7-2-1]: MuTimer per-frame overhead is under 0.1ms` (uses `steady_clock` in test verification path) | RED |
| AC-3 | Periodic hitch logging every 60s (not per-frame) | `tests/core/test_mu_timer.cpp` | `AC-STD-NFR-2 [7-2-1]: MuTimer FrameEnd does not log on every frame` | RED |
| AC-4 | `GetFPS()` returns rolling average over last N frames (default 60) | `tests/core/test_mu_timer.cpp` | `AC-4/AC-STD-2 [7-2-1]: MuTimer GetFPS returns positive value after frames` | RED |
| AC-5 | Per-frame overhead < 0.1ms (stack-only, no heap/I/O) | `tests/core/test_mu_timer.cpp` | `AC-5/AC-STD-NFR-1 [7-2-1]: MuTimer per-frame overhead is under 0.1ms` | RED |
| AC-6 | Integrated into `Winmain.cpp` render loop; `g_muFrameTimer` global | Manual validation (AC-VAL-1) + CMake flow-code test | — | PENDING |
| AC-STD-2 | Catch2 tests: accuracy, hitch detection, FPS average, reset | `tests/core/test_mu_timer.cpp` | All 6 `TEST_CASE` blocks | RED |
| AC-STD-NFR-1 | 1000-frame tight loop overhead < 0.1ms/frame | `tests/core/test_mu_timer.cpp` | `AC-5/AC-STD-NFR-1 [7-2-1]: MuTimer per-frame overhead is under 0.1ms` | RED |
| AC-STD-NFR-2 | No per-frame `g_ErrorReport.Write()` — periodic only | `tests/core/test_mu_timer.cpp` | `AC-STD-NFR-2 [7-2-1]: MuTimer FrameEnd does not log on every frame` | RED |
| AC-VAL-1 | `MuError.log` shows frame time stats after 5-min session | Manual runtime validation (post-integration) | — | PENDING |
| AC-VAL-2 | Catch2 tests pass on macOS arm64 | `./ctl check` syntax-validates; full run post-EPIC-2 | — | PENDING |
| AC-VAL-3 | MinGW cross-compile CI passes | CI pipeline (`MuTimer.cpp` compiles without warnings) | — | PENDING |
| AC-STD-11 | Flow Code `VS0-QUAL-FRAMETIMER` in commit and file headers | CMake flow-code test (pattern from 7.1.1) | — | PENDING |

---

## Implementation Checklist

### Task 1: Create `mu::MuTimer` header (AC-1, AC-2, AC-5)

- [ ] Create `MuMain/src/source/Core/MuTimer.h`
- [ ] Add `#pragma once` guard (no `#ifndef` guards per project standard)
- [ ] Add includes: `<array>`, `<chrono>`, `<cstdint>`, `<limits>` — directly in `MuTimer.h`, NOT in `stdafx.h`
- [ ] Define `namespace mu { class MuTimer { ... }; }` structure
- [ ] Private type alias: `using Clock = std::chrono::steady_clock;`
- [ ] Private type alias: `using TimePoint = std::chrono::time_point<Clock>;`
- [ ] Private `constexpr` constants: `k_hitchThresholdMs = 50.0`, `k_logIntervalS = 60.0`, `k_fpsRingSize = 60`
- [ ] Private members: `m_frameStart`, `m_sessionStart`, `m_lastLogTime` (TimePoint); `m_lastFrameMs`, `m_minFrameMs`, `m_maxFrameMs` (double); `m_frameCount`, `m_hitchCount` (uint64_t); `m_fpsRingBuffer` (`std::array<double, k_fpsRingSize>`); `m_fpsRingIndex` (size_t)
- [ ] Public API: `void FrameStart()`, `void FrameEnd()`, `[[nodiscard]] double GetFrameTimeMs() const`, `[[nodiscard]] double GetFPS() const`, `[[nodiscard]] uint64_t GetHitchCount() const`, `void Reset()`
- [ ] Private method: `void LogStats()`
- [ ] Constructor initializes all members; `m_minFrameMs = std::numeric_limits<double>::max()`, `m_maxFrameMs = 0.0`, ring buffer zeroed

### Task 2: Implement `mu::MuTimer` in `MuTimer.cpp` (AC-1, AC-2, AC-3, AC-4, AC-5)

- [ ] Create `MuMain/src/source/Core/MuTimer.cpp`
- [ ] Includes in order: `#include "stdafx.h"`, `#include "MuTimer.h"`, `#include "ErrorReport.h"`
- [ ] `FrameStart()`: capture `m_frameStart = Clock::now()`
- [ ] `FrameEnd()`: compute `m_lastFrameMs` via `duration<double, std::milli>(Clock::now() - m_frameStart).count()`
- [ ] `FrameEnd()`: update `m_minFrameMs`/`m_maxFrameMs` via `std::min`/`std::max`
- [ ] `FrameEnd()`: increment `m_frameCount`; if `m_lastFrameMs > k_hitchThresholdMs` increment `m_hitchCount`
- [ ] `FrameEnd()`: update FPS ring buffer; advance `m_fpsRingIndex = (m_fpsRingIndex + 1) % k_fpsRingSize`
- [ ] `FrameEnd()`: check periodic log interval (60s); call `LogStats()` and reset `m_lastLogTime` if elapsed
- [ ] `GetFrameTimeMs()`: return `m_lastFrameMs`
- [ ] `GetFPS()`: compute average of non-zero entries in `m_fpsRingBuffer`; return 0.0 if all zero
- [ ] `GetHitchCount()`: return `m_hitchCount`
- [ ] `LogStats()`: compute `sessionElapsedS` and `avgFrameMs`; call `g_ErrorReport.Write(L"PERF: MuTimer ...")` with format `elapsed=%.0fs frames=%llu avg=%.1fms min=%.1fms max=%.1fms hitches=%llu fps=%.1f\r\n`; reset per-interval min/max
- [ ] `Reset()`: reinitialize all members to constructor defaults
- [ ] No `timeGetTime()`, `GetTickCount()`, or any Win32 timing API anywhere in the file
- [ ] No `#ifdef _WIN32` anywhere in the file

### Task 3: Register `MuTimer.cpp` in CMake (AC-1, AC-VAL-3)

- [ ] Check if `MUCore` uses `file(GLOB_RECURSE ... src/source/Core/*.cpp)` or explicit source list
- [ ] If GLOB: no CMake change needed — `MuTimer.cpp` is auto-discovered
- [ ] If explicit: add `src/source/Core/MuTimer.cpp` to `MUCore` target sources
- [ ] Run `./ctl check` to confirm no CMake/format/cppcheck errors

### Task 4: Integrate into `Winmain.cpp` game loop (AC-6)

- [ ] Add `#include "MuTimer.h"` after `#include "ErrorReport.h"` in `Winmain.cpp` (preserve `SortIncludes: Never` order)
- [ ] Declare global instance: `mu::MuTimer g_muFrameTimer;` below `g_ErrorReport` declaration
- [ ] Call `g_muFrameTimer.FrameStart()` at the top of the `if (CheckRenderNextFrame())` block
- [ ] Call `g_muFrameTimer.FrameEnd()` after `g_frameTiming.MarkFrameRendered()` inside the same block
- [ ] Do NOT place `FrameStart()`/`FrameEnd()` around the message pump loop — render frame boundary only
- [ ] Verify `g_pTimer` (CTimer*) is NOT modified — `g_muFrameTimer` is additive only

### Task 5: Catch2 tests (AC-STD-2)

- [x] Created `MuMain/tests/core/test_mu_timer.cpp` with 6 `TEST_CASE` blocks (RED phase)
- [x] `AC-1/AC-STD-2: MuTimer measures frame time accurately` — 50ms sleep, range [40ms, 100ms]
- [x] `AC-STD-2/AC-3: MuTimer detects hitches above 50ms` — 60ms frame, `GetHitchCount() == 1`
- [x] `AC-4/AC-STD-2: MuTimer GetFPS returns positive value after frames` — 10 rapid frames, `GetFPS() > 0`
- [x] `AC-STD-2/AC-1: MuTimer Reset clears all state` — after hitch frame + reset, all stats zero
- [x] `AC-5/AC-STD-NFR-1: MuTimer per-frame overhead is under 0.1ms` — 1000-frame tight loop < 0.1ms/frame
- [x] `AC-STD-NFR-2: MuTimer FrameEnd does not log on every frame` — 5 rapid frames, no crash, no per-frame log
- [x] Registered in `MuMain/tests/CMakeLists.txt` via `target_sources(MuTests PRIVATE core/test_mu_timer.cpp)` with story comment

### Task 6: Quality gate and validation (AC-STD-4, AC-VAL-2, AC-VAL-3)

- [ ] Run `./ctl check` — clang-format check + cppcheck — zero violations required
- [ ] Verify no `timeGetTime()` or `GetTickCount()` in `MuTimer.cpp` (cppcheck portability)
- [ ] Verify `MuTimer.h` compiles on macOS arm64 (`./ctl check` format-validates)
- [ ] Verify CI MinGW cross-compile passes (no warnings under MinGW-w64 i686 with C++20)
- [ ] Commit: `feat(core): add MuTimer frame time instrumentation [VS0-QUAL-FRAMETIMER]`

### Standard Acceptance Criteria

- [ ] AC-STD-1: Code follows project standards — `namespace mu`, `#pragma once`, no `#ifdef _WIN32` in game logic, `std::chrono::steady_clock`, `nullptr`, PascalCase methods, `m_` member prefix
- [x] AC-STD-2: Catch2 tests exist in `MuMain/tests/core/test_mu_timer.cpp` (RED phase, 6 test cases)
- [ ] AC-STD-4: CI quality gate passes — `./ctl check` exits 0 with zero violations
- [ ] AC-STD-6: Conventional commit: `feat(core): add MuTimer frame time instrumentation`
- [ ] AC-STD-11: Flow Code `VS0-QUAL-FRAMETIMER` present in commit message
- [ ] AC-STD-13: Quality gate passes — `./ctl check` clean (clang-format + cppcheck zero violations)
- [ ] AC-STD-15: Git safety — no incomplete rebase, no force push to main
- [ ] AC-STD-20: No API/event/flow catalog entries (infrastructure only — confirmed)

### NFR Acceptance Criteria

- [ ] AC-STD-NFR-1: `FrameStart()` + `FrameEnd()` pair adds < 0.1ms overhead per frame — verified by Catch2 1000-frame tight loop test
- [ ] AC-STD-NFR-2: Periodic log write (every 60s) is the only I/O operation — no per-frame `g_ErrorReport.Write()` or file I/O

### Validation Artifacts

- [ ] AC-VAL-1: `MuError.log` shows frame time statistics after a 5-minute session — format: `PERF: MuTimer — elapsed=300s frames=N avg=Xms min=Yms max=Zms hitches=N fps=F`
- [ ] AC-VAL-2: Catch2 tests pass on macOS arm64 (`./ctl check` syntax-validates; full test run when MUCore compiles post-EPIC-2)
- [ ] AC-VAL-3: CI MinGW cross-compile (Windows x86) build passes — `MuTimer.cpp` compiles without warnings under MinGW-w64 i686

### PCC Compliance

- [ ] No prohibited libraries used — no `timeGetTime()`, `GetTickCount()`, raw `new`/`delete`
- [ ] Required testing patterns followed — Catch2 v3.7.1, `TEST_CASE`/`REQUIRE`, GIVEN/WHEN/THEN structure in comments
- [ ] No `#ifdef _WIN32` in game logic — `std::chrono::steady_clock` is fully portable
- [ ] No backslash path literals in new files
- [ ] `[[nodiscard]]` on all getter functions (`GetFrameTimeMs`, `GetFPS`, `GetHitchCount`)
- [ ] CI MinGW build invariant maintained — `std::chrono::steady_clock` and `std::array` available in MinGW-w64 C++20
- [ ] `namespace mu` used for new class (lowercase namespace convention)
- [ ] `m_` prefix with descriptive suffixes on all member variables

---

## Test Execution Commands

```bash
# Compile Catch2 test on macOS (syntax validation only — Win32 TUs excluded):
# ./ctl check validates clang-format and cppcheck on MuTimer.h/.cpp
./ctl check

# Run all MuTests via CTest (requires BUILD_TESTING=ON and MUCore compiling):
cmake -S MuMain -B build-test -DBUILD_TESTING=ON
cd build-test && ctest -R "7-2-1" --output-on-failure

# Run individual 7.2.1 tests via CTest filter:
ctest -R "mu_timer" --output-on-failure

# MinGW cross-compile (Linux/WSL — full build):
cmake -S MuMain -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=MuMain/cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
cmake --build build-mingw --target MuTests

# Quality gate (macOS + Linux):
./ctl check

# Commit (after implementation complete):
# feat(core): add MuTimer frame time instrumentation [VS0-QUAL-FRAMETIMER]
```

---

## RED Phase Verification

All tests confirmed FAILING (RED) as of 2026-03-07 (pre-implementation — `MuTimer.h` does not exist):

| Test | Result | Error |
|------|--------|-------|
| `AC-1/AC-STD-2 [7-2-1]: MuTimer measures frame time accurately` | FAIL | `MuTimer.h: No such file or directory` |
| `AC-STD-2/AC-3 [7-2-1]: MuTimer detects hitches above 50ms` | FAIL | `MuTimer.h: No such file or directory` |
| `AC-4/AC-STD-2 [7-2-1]: MuTimer GetFPS returns positive value after frames` | FAIL | `MuTimer.h: No such file or directory` |
| `AC-STD-2/AC-1 [7-2-1]: MuTimer Reset clears all state` | FAIL | `MuTimer.h: No such file or directory` |
| `AC-5/AC-STD-NFR-1 [7-2-1]: MuTimer per-frame overhead is under 0.1ms` | FAIL | `MuTimer.h: No such file or directory` |
| `AC-STD-NFR-2 [7-2-1]: MuTimer FrameEnd does not log on every frame` | FAIL | `MuTimer.h: No such file or directory` |

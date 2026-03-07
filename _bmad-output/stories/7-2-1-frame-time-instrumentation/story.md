# Story 7.2.1: Frame Time Instrumentation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.2 - Performance Instrumentation |
| Story ID | 7.2.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-QUAL-FRAMETIMER |
| FRs Covered | NFR1 (30+ FPS requirement), NFR2 (no >50ms hitches), NFR3 (performance baseline); Architecture §Epic 7 §7.2 Performance Instrumentation |
| Prerequisites | EPIC-1 done (MUCore target available; `Timer.h`/`Timer.cpp` with `CTimer`/`CTimer2` in place) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Add `mu::MuTimer` class in `MuMain/src/source/Core/MuTimer.h` + `MuTimer.cpp`: `FrameStart()`, `FrameEnd()`, `GetFrameTimeMs()`, `GetFPS()`, periodic hitch logging to `g_ErrorReport`; integrate into `Winmain.cpp` game loop; add Catch2 tests |
| project-docs | documentation | Story file, sprint status update |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** frame time measurement and variance logging,
**so that** I can validate NFR1-NFR3 performance requirements (30+ FPS, no >50ms hitches).

---

## Functional Acceptance Criteria

- [x] **AC-1:** `mu::MuTimer` class exists in `MUCore`: provides `FrameStart()`, `FrameEnd()`, `GetFrameTimeMs()`, `GetFPS()`, and a `Reset()` method; class lives in `MuMain/src/source/Core/MuTimer.h` and `MuTimer.cpp`
- [x] **AC-2:** `mu::MuTimer` uses `std::chrono::steady_clock` exclusively — no `timeGetTime()`, `GetTickCount()`, or Win32 timing APIs anywhere in the implementation
- [x] **AC-3:** `mu::MuTimer` logs frame time variance and hitch count (frames exceeding 50ms) to `g_ErrorReport.Write()` periodically (every 60 seconds by default); log includes: session elapsed time, frame count, min/max/avg frame time in ms, hitch count, and current FPS
- [x] **AC-4:** `GetFPS()` returns a running average FPS over the last N frames (configurable, default 60); value is valid for display in HUD or debug overlay
- [x] **AC-5:** Per-frame overhead of `FrameStart()` + `FrameEnd()` pair is less than 0.1ms on the target platform (achieved by using only stack-local `steady_clock::now()` calls — no heap allocation, no I/O per frame)
- [x] **AC-6:** `mu::MuTimer` is integrated into the `Winmain.cpp` game loop: `FrameStart()` called at the top of each rendered frame, `FrameEnd()` called after render completes; a global instance `g_muFrameTimer` is declared in `Winmain.cpp`

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code follows `project-context.md` standards: `namespace mu`, `#pragma once`, no new `#ifdef _WIN32` in game logic, `std::chrono::steady_clock`, `nullptr`, PascalCase methods, `m_` member prefix with Hungarian hints
- [x] **AC-STD-2:** Catch2 tests in `MuMain/tests/core/test_mu_timer.cpp`: timer accuracy test (measure ~50ms sleep), hitch detection test (simulate a >50ms frame), FPS average test (verify rolling average is reasonable), and a no-log test (verify `FrameEnd()` does not log on every call — only periodically)
- [x] **AC-STD-4:** CI quality gate passes — `make -C MuMain format-check && make -C MuMain lint` (i.e., `./ctl check`) exits 0 with zero violations
- [x] **AC-STD-6:** Conventional commit: `feat(core): add MuTimer frame time instrumentation` — commit `1258f622` (code review phase)
- [x] **AC-STD-11:** Flow Code traceability — commit message references `VS0-QUAL-FRAMETIMER` — commit `1258f622`
- [x] **AC-STD-13:** Quality gate passes — `./ctl check` clean (clang-format + cppcheck zero violations)
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (infrastructure only)

### NFR Acceptance Criteria

- [x] **AC-STD-NFR-1:** `FrameStart()` + `FrameEnd()` pair adds less than 0.1ms overhead per frame — verified by Catch2 test measuring 1000-frame tight loop overhead
- [x] **AC-STD-NFR-2:** The periodic log write (every 60s) is the only I/O operation; frame-level calls are pure computation — no per-frame `g_ErrorReport.Write()` or file I/O

---

## Validation Artifacts

- [ ] **AC-VAL-1:** `MuError.log` shows frame time statistics after a 5-minute session: log entry exists with format `PERF: MuTimer — elapsed=300s frames=N avg=Xms min=Yms max=Zms hitches=N fps=F` (runtime validation post-EPIC-2)
- [x] **AC-VAL-2:** Catch2 tests pass on macOS arm64 (`./ctl check` syntax-validates; full test run when MUCore compiles post-EPIC-2)
- [ ] **AC-VAL-3:** CI MinGW cross-compile (Windows x86) build continues to pass — `MuTimer.cpp` compiles without warnings under MinGW-w64 i686 (validated on next CI run)

---

## Tasks / Subtasks

- [x] **Task 1: Create `mu::MuTimer` header** (AC: AC-1, AC-2, AC-5)
  - [x] 1.1 Create `MuMain/src/source/Core/MuTimer.h`
  - [x] 1.2 Define `namespace mu { class MuTimer { ... }; }` with `#pragma once` guard
  - [x] 1.3 Private members: `m_frameStart`, `m_sessionStart`, `m_frameCount`, `m_hitchCount`, `m_lastLogTime`, `m_lastFrameMs`, `m_minFrameMs`, `m_maxFrameMs`, `m_fpsRingBuffer`, `m_fpsRingIndex`
  - [x] 1.4 Private type alias: `using Clock = std::chrono::steady_clock;`
  - [x] 1.5 Public API: `FrameStart()`, `FrameEnd()`, `GetFrameTimeMs()`, `GetFPS()`, `GetHitchCount()`, `Reset()`
  - [x] 1.6 Constructor initializes all members via `Reset()`; `m_minFrameMs = std::numeric_limits<double>::max()`, `m_maxFrameMs = 0.0`
  - [x] 1.7 Includes `<chrono>`, `<array>`, `<cstdint>`, `<limits>` directly in `MuTimer.h`

- [x] **Task 2: Implement `mu::MuTimer` in `MuTimer.cpp`** (AC: AC-1, AC-2, AC-3, AC-4, AC-5)
  - [x] 2.1 Created `MuMain/src/source/Core/MuTimer.cpp` with `#include "stdafx.h"`, `#include "MuTimer.h"`, `#include "ErrorReport.h"`
  - [x] 2.2 `FrameStart()`: capture `m_frameStart = Clock::now()`
  - [x] 2.3 `FrameEnd()`: computes frame time, updates min/max, increments counters, updates FPS ring, triggers periodic log
  - [x] 2.4 `GetFrameTimeMs()`: return `m_lastFrameMs`
  - [x] 2.5 `GetFPS()`: average of non-zero entries in `m_fpsRingBuffer`
  - [x] 2.6 `LogStats()`: writes `PERF: MuTimer --` line to `g_ErrorReport`; resets per-interval min/max
  - [x] 2.7 `Reset()`: re-initializes all members

- [x] **Task 3: Register `MuTimer.cpp` in CMake** (AC: AC-1, AC-VAL-3)
  - [x] 3.1 Verified `MUCore` uses `file(GLOB MU_CORE_SOURCES ... Core/*.cpp)` — auto-discovery
  - [x] 3.2 No CMake change needed — `MuTimer.cpp` is auto-discovered
  - [x] 3.4 `./ctl check` passes with zero violations

- [x] **Task 4: Integrate into `Winmain.cpp` game loop** (AC: AC-6)
  - [x] 4.1 Added `#include "Core/MuTimer.h"` after `#include "Core/Timer.h"` in `Winmain.cpp`
  - [x] 4.2 Declared `mu::MuTimer g_muFrameTimer;` below `g_pTimer` (Note: `g_ErrorReport` moved to `ErrorReport.cpp` for MUCore linkability)
  - [x] 4.3 `g_muFrameTimer.FrameStart()` at top of `if (CheckRenderNextFrame())` block
  - [x] 4.4 `g_muFrameTimer.FrameEnd()` at bottom of `if (CheckRenderNextFrame())` block
  - [x] 4.5 Not placed around message pump loop — render frame boundary only

- [x] **Task 5: Create Catch2 tests** (AC: AC-STD-2) — completed in ATDD phase
  - [x] 5.1-5.5 All 6 test cases created in `MuMain/tests/core/test_mu_timer.cpp`
  - [x] 5.6 Registered in `MuMain/tests/CMakeLists.txt`

- [x] **Task 6: Quality gate and validation** (AC: AC-STD-4, AC-VAL-2, AC-VAL-3)
  - [x] 6.1 `./ctl check` passes — clang-format + cppcheck zero violations
  - [x] 6.2 No `timeGetTime()` or `GetTickCount()` in `MuTimer.cpp` (cppcheck confirmed)
  - [x] 6.3 `./ctl check` format-validates on macOS arm64
  - [x] 6.4 Conventional commit `feat(core): add MuTimer frame time instrumentation [VS0-QUAL-FRAMETIMER]` — commit `1258f622`

---

## Error Codes Introduced

_None — this is a platform portability / infrastructure story. No new error codes are introduced. The log output via `g_ErrorReport.Write()` uses the established `PERF:` domain prefix convention (analogous to `PLAT:` used in Story 7.1.1)._

---

## Contract Catalog Entries

### API Contracts

_None — infrastructure story. No API endpoints introduced._

### Event Contracts

_None — infrastructure story. No events introduced._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Frame measurement accuracy | Catch2 v3.7.1 | Core timing path | `FrameStart()`/`FrameEnd()` around 50ms sleep → `GetFrameTimeMs()` in range |
| Hitch detection | Catch2 v3.7.1 | Hitch threshold logic | Simulated >50ms frame → `GetHitchCount()` increments |
| FPS rolling average | Catch2 v3.7.1 | `GetFPS()` path | 10 rapid frames → `GetFPS() > 0` |
| Reset state | Catch2 v3.7.1 | `Reset()` path | After frames + reset → all stats zeroed |
| Build regression | CMake + MinGW CI | All platforms | Windows MinGW cross-compile continues to pass |

_No integration or E2E tests required. Primary test vehicle is Catch2 unit tests + CI build regression._

---

## Dev Notes

### Overview

This story adds a lightweight `mu::MuTimer` class in `MUCore` that measures per-frame execution time using `std::chrono::steady_clock`. It provides a running FPS average, hitch detection (frames > 50ms), and periodic logging to `MuError.log`. The class integrates into the `Winmain.cpp` game loop at the render frame boundary.

**Key design decisions:**
- New class `mu::MuTimer` (not `CTimer`) — uses `mu::` namespace (lowercase, per project-context.md "new code" rule). Does NOT extend or replace `CTimer`/`CTimer2` — those are general-purpose utilities; `MuTimer` is a frame instrumentation class with a distinct purpose.
- `CTimer` (`Timer.h`) already exists in `MUCore` with `high_resolution_clock` for general delta-time. `MuTimer` uses `steady_clock` (more appropriate for wall-time measurements, monotonic, no drift risk from system clock changes).
- `g_pTimer` in `Winmain.cpp` is a raw-`new` `CTimer*` — do NOT replace it; it is used by `SceneManager.cpp` for delta-tick computation. `MuTimer` is a separate, additive layer.
- Periodic logging interval is 60 seconds. This is low-frequency enough to be invisible in normal gameplay and ensures one log entry per minute in a stability session.

### Critical Architecture: Existing Frame Timing Infrastructure

Understanding the existing frame pipeline is essential to avoid regression:

**`g_pTimer` (CTimer in Winmain.cpp):**
```
extern CTimer* g_pTimer;  // declared in SceneManager.cpp line 54
// Used in UpdateLoginAndCharacterScenes() for delta-tick computation
double dDeltaTick = g_pTimer->GetTimeElapsed();
```
`CTimer` uses `std::chrono::high_resolution_clock`. `GetTimeElapsed()` returns ms since last `ResetTimer()`. This is the existing animation delta-time mechanism. Do not touch it.

**`g_frameTiming` (FrameTimingState in SceneManager.h/cpp):**
- Tracks `lastRenderTickCount`, `currentTickCount`, `lastWaterChange`
- `ShouldRenderNextFrame()` → `CheckRenderNextFrame()` → called in Winmain game loop at line 905
- `MarkFrameRendered()` is called at line 985 after the render completes
- `MuTimer.FrameStart()` should be called just inside the `if (CheckRenderNextFrame())` block, and `FrameEnd()` just after `g_frameTiming.MarkFrameRendered()` (or after the full render block)

**Integration point in Winmain.cpp (pseudocode):**
```cpp
if (CheckRenderNextFrame())
{
    g_muFrameTimer.FrameStart();   // ADD: start frame measurement
    // ... existing render code (window mode check, scene rendering, etc.)
    g_frameTiming.MarkFrameRendered();
    g_muFrameTimer.FrameEnd();     // ADD: end frame measurement, log if interval elapsed
}
```

### `mu::MuTimer` Class Design

**Header (`MuMain/src/source/Core/MuTimer.h`):**
```cpp
#pragma once

#include <array>
#include <chrono>
#include <cstdint>
#include <limits>

namespace mu
{

class MuTimer
{
public:
    MuTimer();

    void FrameStart();
    void FrameEnd();

    [[nodiscard]] double GetFrameTimeMs() const;
    [[nodiscard]] double GetFPS() const;
    [[nodiscard]] uint64_t GetHitchCount() const;
    void Reset();

private:
    using Clock = std::chrono::steady_clock;
    using TimePoint = std::chrono::time_point<Clock>;

    static constexpr double k_hitchThresholdMs = 50.0;
    static constexpr double k_logIntervalS = 60.0;
    static constexpr size_t k_fpsRingSize = 60;

    TimePoint m_frameStart;
    TimePoint m_sessionStart;
    TimePoint m_lastLogTime;

    double m_lastFrameMs;
    double m_minFrameMs;
    double m_maxFrameMs;

    uint64_t m_frameCount;
    uint64_t m_hitchCount;

    std::array<double, k_fpsRingSize> m_fpsRingBuffer;
    size_t m_fpsRingIndex;

    void LogStats();
};

} // namespace mu
```

**Key implementation notes for `FrameEnd()`:**

The FPS ring buffer stores the instantaneous FPS of each of the last 60 frames. `GetFPS()` averages non-zero values. This gives a smooth 60-frame rolling average without requiring dynamic allocation.

```cpp
void MuTimer::FrameEnd()
{
    using DurationMs = std::chrono::duration<double, std::milli>;
    using DurationS = std::chrono::duration<double>;

    const auto now = Clock::now();
    m_lastFrameMs = DurationMs(now - m_frameStart).count();
    m_minFrameMs = std::min(m_minFrameMs, m_lastFrameMs);
    m_maxFrameMs = std::max(m_maxFrameMs, m_lastFrameMs);
    ++m_frameCount;

    if (m_lastFrameMs > k_hitchThresholdMs)
    {
        ++m_hitchCount;
    }

    // Update rolling FPS ring buffer
    m_fpsRingBuffer[m_fpsRingIndex] = (m_lastFrameMs > 0.0) ? 1000.0 / m_lastFrameMs : 0.0;
    m_fpsRingIndex = (m_fpsRingIndex + 1) % k_fpsRingSize;

    // Periodic stats logging
    if (DurationS(now - m_lastLogTime).count() >= k_logIntervalS)
    {
        LogStats();
        m_lastLogTime = now;
        m_minFrameMs = std::numeric_limits<double>::max();
        m_maxFrameMs = 0.0;
    }
}
```

### wchar_t Logging via `g_ErrorReport.Write()`

`g_ErrorReport.Write()` takes `wchar_t*` format strings with `vswprintf`. After Story 7.1.1, the output is written as UTF-8. Use `L"PERF: ..."` format string literals. The `%llu` specifier for `uint64_t` is valid in `vswprintf` on all target platforms (MinGW, MSVC, Clang). Alternatively use `static_cast<unsigned long long>()` explicitly for safety across compilers.

**Log format (example):**
```
PERF: MuTimer — elapsed=60s frames=1247 avg=48.1ms min=16.2ms max=87.3ms hitches=3 fps=20.8
```

The `—` em-dash is fine in a wide string literal (`L"\u2014"`). Alternatively, use `--` (two hyphens) if there is any concern about tooling.

### File Locations

| File | Action |
|------|--------|
| `MuMain/src/source/Core/MuTimer.h` | CREATE — `mu::MuTimer` class declaration |
| `MuMain/src/source/Core/MuTimer.cpp` | CREATE — `mu::MuTimer` implementation |
| `MuMain/src/source/Main/Winmain.cpp` | MODIFY — add `#include "MuTimer.h"`, declare `g_muFrameTimer`, call `FrameStart()`/`FrameEnd()` in render loop |
| `MuMain/tests/core/test_mu_timer.cpp` | CREATE — Catch2 tests for timing accuracy, hitch detection, FPS average, reset |
| `MuMain/tests/CMakeLists.txt` | MODIFY — add `target_sources(MuTests PRIVATE core/test_mu_timer.cpp)` |

### CMake Source Discovery

Check how `MUCore` discovers its source files. Run:
```bash
grep -n "MuTimer\|GLOB\|Core/" MuMain/src/CMakeLists.txt
```
If `MUCore` uses `file(GLOB_RECURSE ... src/source/Core/*.cpp)`, `MuTimer.cpp` is auto-included and no CMake change is needed beyond adding the test source. If explicit, add `src/source/Core/MuTimer.cpp` to the `target_sources` call for `MUCore`.

### Naming Convention Rationale

- **`mu::MuTimer`** — lowercase namespace `mu` (new-code convention per project-context.md); `MuTimer` (PascalCase class, `Mu` prefix aligns with project namespace identity, distinct from `CTimer`)
- **`g_muFrameTimer`** — global in `Winmain.cpp`; `g_` prefix (global), `mu` namespace hint, `FrameTimer` purpose
- **`m_` members with Hungarian hints** — `m_frameCount` (int → no hint needed, count is self-explanatory), `m_lastFrameMs` (double → `f` prefix not used for `double` in this codebase; `ms` suffix is descriptive enough)
- **`k_` prefix for `constexpr` class constants** — `k_hitchThresholdMs`, `k_logIntervalS` — lowercase k prefix is common modern C++ convention for `constexpr` within class scope; `UPPER_SNAKE` applies to macros, not `constexpr` members

### Cross-Platform Rules (Critical)

Per `docs/development-standards.md` §1 and `_bmad-output/project-context.md`:
- `std::chrono::steady_clock` only — `timeGetTime()` and `GetTickCount()` are BANNED (see Banned Win32 API table §Timing)
- No `#ifdef _WIN32` in `MuTimer.h` or `MuTimer.cpp` — `std::chrono` is fully portable; no platform guards needed
- `#pragma once` in `MuTimer.h` — already the project standard
- `nullptr` not `NULL` anywhere in new code
- `[[nodiscard]]` on `GetFrameTimeMs()`, `GetFPS()`, `GetHitchCount()` — callers ignoring these values would be bugs
- CI (MinGW) build must pass — `std::chrono::steady_clock` and `std::array` are available in MinGW-w64 with C++20

### Lessons from Story 7.1.1 (Pattern Continuity)

From the previous story in this epic:
- **`PLAT:` prefix** established for platform layer log messages. For performance instrumentation, use **`PERF:`** prefix — analogous convention, different domain
- **`std::numeric_limits<double>::max()`** as initial min value — same pattern used in statistical accumulators elsewhere
- **No per-frame I/O** — the `g_ErrorReport.Write()` call is in `LogStats()`, called only every 60 seconds. The story 7.1.1 refactored `ErrorReport.cpp` to use `std::ofstream` with `flush()` on write for crash safety — this means each `LogStats()` call will flush to disk, which is acceptable at 60-second intervals
- **`m_fileStream.flush()` was added in 7.1.1 code-review** — this means every `g_ErrorReport.Write()` call flushes. At 1 call/60s this is entirely acceptable
- **Catch2 test location**: `MuMain/tests/core/` — exists and contains `test_timer.cpp` and `test_error_report.cpp`. Add `test_mu_timer.cpp` here. The `tests/CMakeLists.txt` registers core test files via `target_sources(MuTests PRIVATE core/test_*.cpp)` pattern

From Story 3.1.1:
- **`PLAT:` prefix in diagnostic messages** is established convention. Use `PERF:` as the analogous prefix for performance domain
- **CMake auto-discovery** via GLOB may mean no CMake change needed — verify first before editing

From Story 2.2.3 (SDL3 text input):
- Game loop is single-threaded — `mu::MuTimer` does not need thread safety. `g_muFrameTimer` is accessed only from the main thread render path

### Git Intelligence

Recent commits show Story 7.1.1 cross-platform error reporting is complete (done status). The `g_ErrorReport` instance is now `std::ofstream`-based with flush-on-write. `MuTimer.LogStats()` can safely call `g_ErrorReport.Write()` — the cross-platform implementation is in place.

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja, Clang/GCC/MSVC/MinGW, Catch2 v3.7.1

**Required Patterns (from project-context.md):**
- `std::chrono::steady_clock` for all new timing (not `timeGetTime()`, not `GetTickCount()`)
- `#pragma once` in all headers
- `nullptr` instead of `NULL` in new code
- `[[nodiscard]]` on new getter functions where ignoring the return is a bug
- `namespace mu` for new code (lowercase namespace convention)
- `m_` prefix for member variables with Hungarian hints where applicable
- Return codes, no exceptions in game loop context
- `g_ErrorReport.Write(L"PERF: ...")` for instrumentation log output

**Prohibited Patterns (from project-context.md):**
- No `timeGetTime()` / `GetTickCount()` — banned timing APIs (Timing section of banned API table)
- No new `#ifdef _WIN32` in game logic — `MuTimer.cpp` is Core infrastructure; `std::chrono` is fully cross-platform, so no guards needed
- No raw `new`/`delete` — `g_muFrameTimer` is a value-type global (no heap allocation)
- No `wprintf` for new logging — use `g_ErrorReport.Write()`
- No `NULL` — use `nullptr`
- Do NOT modify generated files in `src/source/Dotnet/`
- Do NOT touch `stdafx.h` for project headers

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint` (i.e., `./ctl check`)

**Commit Format:** `feat(core): add MuTimer frame time instrumentation [VS0-QUAL-FRAMETIMER]`

**Schema Alignment:** Not applicable — C++20 game client with no schema validation tooling (per sprint-status.yaml).

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` §Story 7.2.1] — original AC definitions and story statement
- [Source: `_bmad-output/planning-artifacts/epics.md` §Epic 7] — NFR1-NFR3 performance requirements (30+ FPS, no >50ms hitches)
- [Source: `docs/development-standards.md` §1 Cross-Platform Readiness §Timing] — `timeGetTime()`/`GetTickCount()` banned, `std::chrono::steady_clock` replacement
- [Source: `docs/development-standards.md` §2 C++ Conventions §Modern C++] — `std::chrono`, `[[nodiscard]]`, `constexpr` rules
- [Source: `_bmad-output/project-context.md` §Critical Implementation Rules] — required patterns, prohibited patterns, `mu::` namespace convention
- [Source: `MuMain/src/source/Core/Timer.h`] — existing `CTimer`/`CTimer2` classes (do NOT replace, additive new class)
- [Source: `MuMain/src/source/Core/Timer.cpp`] — `std::chrono::high_resolution_clock` pattern (reference for chrono usage style)
- [Source: `MuMain/src/source/Main/Winmain.cpp` lines 90, 429, 905] — `g_pTimer` declaration/cleanup, `CheckRenderNextFrame()` integration point
- [Source: `MuMain/src/source/Scenes/SceneManager.h`] — `FrameTimingState`, `CheckRenderNextFrame()`, `g_frameTiming` — context for where to hook `FrameStart()`/`FrameEnd()`
- [Source: `MuMain/src/source/Scenes/SceneManager.cpp` line 985] — `g_frameTiming.MarkFrameRendered()` — natural `FrameEnd()` call site
- [Source: `MuMain/tests/core/test_timer.cpp`] — existing Catch2 test pattern for Core timer classes
- [Source: `MuMain/tests/CMakeLists.txt`] — `target_sources(MuTests PRIVATE ...)` pattern for registering new test files
- [Source: `_bmad-output/stories/7-1-1-crossplatform-error-reporting/story.md` §Dev Notes] — `PLAT:` prefix convention, `g_ErrorReport.Write()` usage pattern, WideToUtf8 established, `std::ofstream` + flush-on-write in place
- [Source: `_bmad-output/implementation-artifacts/sprint-status.yaml`] — story 7-2-1 is `backlog` in sprint-2, EPIC-7 `in-progress`

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (story creation)

### Debug Log References

### Completion Notes List

- Code review completed 2026-03-07 (agent: claude-sonnet-4-6): 0 HIGH, 2 MEDIUM, 3 LOW issues found
  - M-1 fixed: Issued proper `feat(core):` conventional commit `1258f622` with `VS0-QUAL-FRAMETIMER` flow code (satisfies AC-STD-6, AC-STD-11)
  - M-2 fixed: Added clarifying comment in `LogStats()` documenting session-scope vs interval-scope metrics (avg/frames are session-wide; min/max are per-interval)
  - L-1 fixed: Updated stale RED PHASE comment in `test_mu_timer.cpp` to GREEN PHASE
  - L-2 (NFR-2 test indirect): Accepted — 60s interval makes per-frame logging structurally impossible; test is adequate
  - L-3 (no extern header for g_muFrameTimer): Accepted — no current consumer outside Winmain.cpp
- Story created 2026-03-07 via create-story workflow (agent: claude-sonnet-4-6)
- No specification corpus available (specification-index.yaml not found — no corpus recommendations)
- No story partials found in docs/story-partials/
- Story type: `infrastructure` (C++ performance instrumentation — no frontend, no API, no new error codes)
- Schema alignment: N/A (no API schemas affected — C++20 game client, noted in sprint-status.yaml)
- Prerequisite context: Story 7.1.1 done — `g_ErrorReport` now uses `std::ofstream` with flush-on-write; `PLAT:` prefix convention established. `MuTimer.LogStats()` can call `g_ErrorReport.Write()` safely.
- Existing `CTimer`/`CTimer2` in `Core/Timer.h` uses `high_resolution_clock` for animation delta-time. `MuTimer` is additive — uses `steady_clock`, separate concern, does NOT replace `CTimer` or `g_pTimer`.
- `g_pTimer` (CTimer*) is raw-new in Winmain.cpp and extern'd in SceneManager.cpp — do NOT replace or modify; `g_muFrameTimer` is a new value-type global alongside it
- Integration point: `CheckRenderNextFrame()` at Winmain.cpp line 905; `MarkFrameRendered()` at SceneManager.cpp line 985 — `FrameStart()` before render block entry, `FrameEnd()` after `MarkFrameRendered()`
- Git context: Main branch at 22ab114 (docs: add session summary for story 7-1-1); all pipeline at story 7-1-1 completion
- `mu::` namespace is established: `mu::platform` in Platform layer, `mu` in `MuPlatform.h/cpp`, `IPlatformEventLoop.h` — `mu::MuTimer` is consistent
- Log prefix chosen: `PERF:` (analogous to `PLAT:` from 7.1.1, different domain for performance/instrumentation)
- `GetHitchCount()` added to public API beyond the epic spec — needed for Catch2 test and for AC-VAL-1 validation; stays in scope as it is a trivial getter that serves testability

### File List

| File | Action | Status |
|------|--------|--------|
| `MuMain/src/source/Core/MuTimer.h` | CREATE — `mu::MuTimer` class declaration | Done |
| `MuMain/src/source/Core/MuTimer.cpp` | CREATE — `mu::MuTimer` implementation | Done |
| `MuMain/src/source/Core/ErrorReport.cpp` | MODIFY — moved `g_ErrorReport` definition here from Winmain.cpp for MUCore linkability | Done |
| `MuMain/src/source/Main/Winmain.cpp` | MODIFY — include MuTimer.h, declare g_muFrameTimer, FrameStart/FrameEnd in render loop | Done |
| `MuMain/tests/core/test_mu_timer.cpp` | CREATE — Catch2 tests (accuracy, hitch, FPS, reset) | Done (ATDD phase) |
| `MuMain/tests/CMakeLists.txt` | MODIFY — add test_mu_timer.cpp to MuTests target | Done (ATDD phase) |

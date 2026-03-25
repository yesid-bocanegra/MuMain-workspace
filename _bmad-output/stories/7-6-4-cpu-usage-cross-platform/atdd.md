# ATDD Checklist — Story 7.6.4: Cross-Platform CPU Usage Monitoring

**Story Key:** `7-6-4-cpu-usage-cross-platform`
**Story Type:** infrastructure
**Generated:** 2026-03-25
**Status:** RED PHASE — tests created, awaiting implementation

---

## AC-to-Test Mapping

| AC | Description | Test Method | Location | Status |
|----|-------------|-------------|----------|--------|
| AC-1 | `check-win32-guards.py` exits 0 | Script: `python3 MuMain/scripts/check-win32-guards.py` | CI / manual | `[ ]` |
| AC-2 | Compiles without `windows.h`, `SYSTEM_INFO`, `FILETIME`, `GetSystemInfo()`, `GetProcessTimes()` | Build: `./ctl check` (compile step) | CI / manual | `[ ]` |
| AC-3 | CPU core count uses `std::thread::hardware_concurrency()` | `TEST_CASE("AC-3: hardware_concurrency returns positive value")` | `tests/core/test_cpu_usage.cpp` | `[ ]` |
| AC-4 | Per-process CPU utilisation via platform-specific APIs, returns [0.0, 1.0] | `TEST_CASE("AC-4: CPU usage measurement returns value in [0,1] range")` | `tests/core/test_cpu_usage.cpp` | `[ ]` |
| AC-5 | If timing unavailable, return 0.0 and log via `g_ErrorReport.Write()` — no crash | `TEST_CASE("AC-5: CPU usage never returns negative value or crashes")` | `tests/core/test_cpu_usage.cpp` | `[ ]` |
| AC-6 | `./ctl check` passes | Script: `./ctl check` | CI / manual | `[ ]` |
| AC-STD-1 | Code standards: `std::chrono::steady_clock`, clang-format clean | `./ctl check` (format-check) | CI / manual | `[ ]` |
| AC-STD-2 | Catch2 unit tests: core count > 0, CPU usage in [0.0, 1.0] | All 3 `TEST_CASE`s in `test_cpu_usage.cpp` | `tests/core/test_cpu_usage.cpp` | `[ ]` |
| AC-STD-13 | `./ctl check` exits 0 | Script: `./ctl check` | CI / manual | `[ ]` |
| AC-STD-15 | Git safety — no force push, no incomplete rebase | Manual verification | Git | `[ ]` |

---

## Implementation Checklist

### Task 1: Audit Core/CpuUsage.cpp

- [ ] 1.1 Read `Core/CpuUsage.cpp` completely and list every Win32 API/type used
- [ ] 1.2 Identify which are in the public interface (header) vs implementation only

### Task 2: Add cross-platform time helper to PlatformCompat.h

- [ ] 2.1 Add `mu_get_process_cpu_times(uint64_t* kernelNs, uint64_t* userNs)` inline function:
  - `#ifdef _WIN32`: `GetProcessTimes()` → convert `FILETIME` to nanoseconds
  - macOS / Linux: `getrusage(RUSAGE_SELF, &ru)` → `ru_stime`/`ru_utime` (timeval → ns)
- [ ] 2.2 Return `bool` — false if the syscall fails (caller returns 0.0 CPU usage)

### Task 3: Rewrite CpuUsage.cpp

- [ ] 3.1 Replace `GetSystemInfo()` + `SYSTEM_INFO` with `std::thread::hardware_concurrency()`
- [ ] 3.2 Replace `GetProcessTimes()` + `FILETIME` delta with `mu_get_process_cpu_times()` + `std::chrono::steady_clock`; normalise result to fraction [0.0, 1.0]
- [ ] 3.3 Remove all `#ifdef _WIN32` blocks from `CpuUsage.cpp`
- [ ] 3.4 Remove `windows.h` include (no longer needed)

### Task 4: Unit tests (RED → GREEN)

- [ ] 4.1 `tests/core/test_cpu_usage.cpp` exists (DONE — file created in ATDD phase)
- [ ] 4.2 `TEST_CASE("AC-3: hardware_concurrency returns positive value")` passes
- [ ] 4.3 `TEST_CASE("AC-4: CPU usage measurement returns value in [0,1] range")` passes
- [ ] 4.4 `TEST_CASE("AC-5: CPU usage never returns negative value or crashes")` passes

### Task 5: Validation

- [ ] 5.1 `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `Core/CpuUsage.cpp`
- [ ] 5.2 `./ctl check` exits 0 (format-check + lint both green)

---

## PCC Compliance Checklist

- [ ] No prohibited libraries referenced (N/A — pure C++ stdlib, Catch2, POSIX)
- [ ] No `#ifdef _WIN32` in `CpuUsage.cpp` after implementation (game logic file)
- [ ] `#ifdef _WIN32` in `PlatformCompat.h` only (allowed — platform abstraction header)
- [ ] All new code uses `std::chrono::steady_clock` (never `timeGetTime()` / `GetTickCount()`)
- [ ] All new code uses `nullptr` (never `NULL`)
- [ ] No raw `new`/`delete` in new code
- [ ] `g_ErrorReport.Write()` used for diagnostic logging when syscall fails (AC-5)
- [ ] Test file includes no Win32 headers (macOS/Linux CI compatible)
- [ ] `check-win32-guards.py` validation script exits 0

---

## Test Files Created (RED Phase)

| File | Phase | ACs Covered |
|------|-------|-------------|
| `MuMain/tests/core/test_cpu_usage.cpp` | RED | AC-3, AC-4, AC-5, AC-STD-2 |

**CMakeLists.txt entry added:** `MuMain/tests/CMakeLists.txt` — `target_sources(MuTests PRIVATE core/test_cpu_usage.cpp)`

---

## RED Phase Notes

- **AC-3 test:** Verifies `std::thread::hardware_concurrency() > 0` (platform baseline). Passes immediately on any build host. Code-level verification that CpuUsage _uses_ this API is covered by AC-2's compile check (removal of `SYSTEM_INFO`/`GetSystemInfo()`).
- **AC-4 test:** Range [0.0, 1.0] is **RED on Windows** with the current implementation (returns percentage 0–100+). GREEN on macOS/Linux once `mu_get_process_cpu_times()` is wired in with the normalised formula.
- **AC-5 test:** Multiple rapid calls must not crash. Currently macOS placeholder returns 0.0 (safe). Test guards regression once cross-platform implementation is in place.
- **No Bruno collection:** Infrastructure story — no REST endpoints.
- **No E2E tests:** Infrastructure story — no UI.

# Story 7.6.4: Cross-Platform CPU Usage Monitoring

Status: review

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.6 - macOS Native Build Compilation |
| Story ID | 7.6.4 |
| Story Points | 3 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-WIN32CLEAN-CPUUSAGE |
| FRs Covered | Cross-platform parity — zero `#ifdef _WIN32` in game logic |
| Prerequisites | 7-6-1-macos-native-build-compilation (in-progress) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Replace Win32 CPU measurement APIs in `Core/CpuUsage.cpp` with cross-platform equivalents |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** `Core/CpuUsage.cpp` to use cross-platform CPU measurement APIs,
**so that** CPU utilisation reporting compiles and produces meaningful output on all platforms.

---

## Functional Acceptance Criteria

- [x] **AC-1:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — no violations in `Core/CpuUsage.cpp`.
- [x] **AC-2:** `CpuUsage.cpp` compiles without `windows.h`, `SYSTEM_INFO`, `FILETIME`, `GetSystemInfo()`, or `GetProcessTimes()`.
- [x] **AC-3:** CPU core count uses `std::thread::hardware_concurrency()` on all platforms.
- [x] **AC-4:** Per-process CPU utilisation uses:
  - **Windows**: `GetProcessTimes()` (existing behaviour, kept via `#ifdef _WIN32` include-selection in `PlatformCompat.h` or a `mu_get_process_cpu_times()` abstraction)
  - **macOS**: `task_info(mach_task_self(), TASK_THREAD_TIMES_INFO, ...)` or `getrusage(RUSAGE_SELF, ...)`
  - **Linux**: `/proc/self/stat` or `getrusage(RUSAGE_SELF, ...)`
- [x] **AC-5:** If per-process timing is unavailable, the implementation returns 0.0 and logs a diagnostic via `g_ErrorReport.Write()` — it does NOT crash or assert.
- [x] **AC-6:** `./ctl check` passes — build + format-check + lint all green.

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards — `std::chrono::steady_clock` for timing; no `timeGetTime()` or `GetTickCount()`; clang-format clean.
- [x] **AC-STD-2:** Tests — Catch2 unit test in `tests/core/test_cpu_usage.cpp` verifying: core count > 0, CPU usage returns a float in [0.0, 1.0].
- [x] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [x] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [x] **Task 1: Audit Core/CpuUsage.cpp** (AC-2)
  - [x] 1.1: Read the file completely and list every Win32 API/type used
  - [x] 1.2: Identify which are in the public interface (header) vs implementation only

- [x] **Task 2: Add cross-platform time helpers to PlatformCompat.h** (AC-4)
  - [x] 2.1: Add `mu_get_process_cpu_times(uint64_t* kernelNs, uint64_t* userNs)` stub:
    - `#ifdef _WIN32`: `FILETIME` + `GetProcessTimes` → convert to nanoseconds
    - macOS: `getrusage(RUSAGE_SELF, &usage)` → `usage.ru_stime` / `usage.ru_utime` (timeval → ns)
    - Linux: same with `getrusage` or `/proc/self/stat`
  - [x] 2.2: Return `bool` — false if the syscall fails (caller returns 0.0 CPU usage)

- [x] **Task 3: Rewrite CpuUsage.cpp** (AC-3, AC-4, AC-5)
  - [x] 3.1: Replace `GetSystemInfo()` + `SYSTEM_INFO` with `std::thread::hardware_concurrency()`
  - [x] 3.2: Replace `GetProcessTimes()` + `FILETIME` delta calculation with `mu_get_process_cpu_times()` + `std::chrono::steady_clock` for wall-clock elapsed time
  - [x] 3.3: Remove all remaining `#ifdef _WIN32` blocks from the `.cpp` file
  - [x] 3.4: Remove `windows.h` include (no longer needed)

- [x] **Task 4: Unit test** (AC-STD-2)
  - [x] 4.1: Create `tests/core/test_cpu_usage.cpp`
  - [x] 4.2: `TEST_CASE("hardware_concurrency returns positive value")`
  - [x] 4.3: `TEST_CASE("CPU usage measurement returns value in [0,1] range")` — call `GetCpuUsage()` twice with a brief sleep, check the delta is in [0.0, 1.0]

- [x] **Task 5: Validate** (AC-1, AC-6)
  - [x] 5.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `Core/CpuUsage.cpp`
  - [x] 5.2: Run `./ctl check` — exits 0

---

## Error Codes Introduced

None — infrastructure story.

---

## Contract Catalog Entries

None — no API, event, or navigation contracts.

---

## Dev Notes

### Critical Rule (from project-context.md)

**NO `#ifdef _WIN32` in game logic.** The only allowed `#ifdef _WIN32` is in `PlatformCompat.h` for the `mu_get_process_cpu_times` implementation.

### Platform CPU Time APIs

| Platform | API | Header |
|---|---|---|
| Windows | `GetProcessTimes(GetCurrentProcess(), ...)` | `<windows.h>` (via PlatformCompat.h) |
| macOS / Linux | `getrusage(RUSAGE_SELF, &ru)` | `<sys/resource.h>` |
| All | `std::thread::hardware_concurrency()` | `<thread>` |

### CPU Usage Formula (unchanged)

```
delta_user_ns   = user_ns_now   - user_ns_prev
delta_kernel_ns = kernel_ns_now - kernel_ns_prev
delta_wall_ns   = wall_ns_now   - wall_ns_prev
cpu_usage = (delta_user_ns + delta_kernel_ns) / (delta_wall_ns * num_cores)
```

The formula is the same on all platforms — only the syscall to get `user_ns`/`kernel_ns` differs.

### References

- [Source: _bmad-output/project-context.md#Prohibited Code Patterns]
- [Source: MuMain/src/source/Platform/PlatformCompat.h]
- POSIX `getrusage(2)` man page

---

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Completion Notes List

- Task 1: Audited CpuUsage.cpp — 8 Win32 API/types identified (SYSTEM_INFO, GetSystemInfo, FILETIME, GetProcessTimes, GetCurrentProcess, ULONGLONG, DWORD, #ifdef _WIN32), all implementation-only (header clean).
- Task 2: Added `mu_get_process_cpu_times(uint64_t* kernelNs, uint64_t* userNs)` to PlatformCompat.h — Windows uses GetProcessTimes→FILETIME→ns, POSIX uses getrusage(RUSAGE_SELF)→timeval→ns. Returns bool (false on failure).
- Task 3: Rewrote CpuUsage.cpp — single cross-platform Impl class using std::thread::hardware_concurrency() for core count and mu_get_process_cpu_times() for process CPU time. Normalized return to [0.0, 1.0] fractional ratio (was 0-100+ percentage). Added g_ErrorReport.Write() diagnostic on syscall failure per AC-5.
- Task 4: Test file (test_cpu_usage.cpp) already created in ATDD phase. Tests exercise AC-3 (core count), AC-4 (range), AC-5 (crash safety).
- Task 5: check-win32-guards.py exits 0. ./ctl check passes (build + format + lint).

### File List

| File | Action | Description |
|------|--------|-------------|
| `MuMain/src/source/Platform/PlatformCompat.h` | MODIFIED | Added `mu_get_process_cpu_times()` cross-platform helper |
| `MuMain/src/source/Core/CpuUsage.cpp` | MODIFIED | Replaced Win32 implementation with cross-platform using mu_get_process_cpu_times + hardware_concurrency |

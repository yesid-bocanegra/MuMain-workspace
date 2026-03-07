# ATDD Checklist — Story 7.1.1: Cross-Platform Error Reporting

**Flow Code:** VS0-QUAL-ERRORREPORT-XPLAT
**Story Status:** ready-for-dev
**ATDD Phase:** RED (tests written, implementation pending)

---

## Test Suite Summary

| Suite | File | Type | Status |
|-------|------|------|--------|
| Catch2 unit tests | `tests/core/test_error_report.cpp` | Runtime | 🔴 RED |
| No-Win32 grep | `tests/build/test_ac3_no_win32_error_report.cmake` | CMake script | 🔴 RED |
| Flow code traceability | `tests/build/test_ac_std11_flow_code_7_1_1.cmake` | CMake script | 🟢 GREEN |

> **Flow code test is GREEN** — `test_error_report.cpp` exists with the correct `[7-1-1]` tags and `VS0-QUAL-ERRORREPORT-XPLAT` reference.
> **Catch2 tests are RED** — tests will fail at runtime on macOS (Win32 `CreateFile`/`WriteFile` not available).
> **AC-3 cmake test is RED** — Win32 file I/O APIs are still present in `ErrorReport.cpp`.

---

## Acceptance Criteria Test Coverage

### Functional ACs

| AC | Description | Test | Phase |
|----|-------------|------|-------|
| AC-1 | `MuError.log` created at specified path on macOS/Linux | `test_error_report.cpp` — `AC-1/AC-2` + `AC-1/CutHead` | 🔴 RED |
| AC-2 | `Write()` produces UTF-8 readable text (not raw wchar_t bytes) | `test_error_report.cpp` — `AC-1/AC-2`, `AC-2 HexWrite` | 🔴 RED |
| AC-3 | No `CreateFile`/`WriteFile`/`ReadFile`/`CloseHandle`/`SetFilePointer`/`DeleteFile` in cross-platform path | `test_ac3_no_win32_error_report.cmake` | 🔴 RED |
| AC-4 | `WriteCurrentTime()` uses `std::chrono`, output matches `YYYY/MM/DD HH:MM` | `test_error_report.cpp` — `AC-4` | 🔴 RED |
| AC-5 | Windows build continues to compile and produce `MuError.log` | CI MinGW cross-compile (regression gate) | ⬜ CI ONLY |

### Standard ACs

| AC | Description | Test | Phase |
|----|-------------|------|-------|
| AC-STD-2 | Catch2 tests exist and pass on macOS Clang | `tests/core/test_error_report.cpp` compiled in `MuTests` | 🔴 RED |
| AC-STD-3 | No Win32 file I/O APIs in `ErrorReport.cpp` (grep verified) | `test_ac3_no_win32_error_report.cmake` | 🔴 RED |
| AC-STD-4 | `./ctl check` passes — clang-format + cppcheck clean | Post-implementation quality gate | ⬜ POST-IMPL |
| AC-STD-11 | Flow code `VS0-QUAL-ERRORREPORT-XPLAT` in test artifacts | `test_ac_std11_flow_code_7_1_1.cmake` | 🟢 GREEN |

### NFR ACs

| AC | Description | Test | Phase |
|----|-------------|------|-------|
| AC-NFR-1 | `Write()` overhead < 1ms per 256-char message | `test_error_report.cpp` — `AC-NFR-1` | 🔴 RED |
| AC-NFR-2 | Invalid path emits stderr, game continues without crash | `test_error_report.cpp` — `AC-NFR-2` | 🔴 RED |

### Validation ACs

| AC | Description | Test | Phase |
|----|-------------|------|-------|
| AC-VAL-1 | `MuError.log` produced on macOS with correct content | Manual / `MuTests` run on macOS | 🔴 RED |
| AC-VAL-2 | `MuError.log` produced on Linux with correct content | CI build + test run | ⬜ CI ONLY |
| AC-VAL-3 | MinGW CI build continues to pass | CI MinGW cross-compile | ⬜ CI ONLY |

---

## Test Files

### `tests/core/test_error_report.cpp`

Catch2 v3.7.1 unit tests registered in `MuTests` target. Tests use a local `CErrorReport` instance with a `std::filesystem::temp_directory_path()` path to isolate from `g_ErrorReport`.

| Test Case | ACs Covered | Expected Result |
|-----------|-------------|-----------------|
| `AC-1/AC-2 [7-1-1]: ErrorReport creates file and writes UTF-8 text` | AC-1, AC-2 | File exists; content contains `"TEST: hello world"` |
| `AC-2 [7-1-1]: HexWrite produces ASCII hex output readable as UTF-8` | AC-2 | File contains `"DE"`, `"AD"` as ASCII text |
| `AC-4 [7-1-1]: WriteCurrentTime formats timestamp as YYYY/MM/DD HH:MM` | AC-4 | Content matches `\d{4}/\d{2}/\d{2} \d{2}:\d{2}` |
| `AC-1/CutHead [7-1-1]: CutHead trims log to 4 sessions when 5+ present` | AC-1 | Exactly 4 `"###### Log Begin ######"` markers |
| `AC-NFR-2 [7-1-1]: ErrorReport does not crash on invalid file path` | AC-NFR-2 | `REQUIRE_NOTHROW` passes |
| `AC-NFR-1 [7-1-1]: Write() overhead is under 1ms per call` | AC-NFR-1 | Average `< 1.0ms` over 100 iterations |

### `tests/build/test_ac3_no_win32_error_report.cmake`

CMake script mode test. Reads `ErrorReport.cpp` and verifies the cross-platform section (before first `#ifdef _WIN32`) contains none of:
`CreateFile(`, `WriteFile(`, `ReadFile(`, `CloseHandle(`, `SetFilePointer(`, `DeleteFile(`, `GetLocalTime(`, `INVALID_HANDLE_VALUE`

### `tests/build/test_ac_std11_flow_code_7_1_1.cmake`

CMake script mode test. Verifies `test_error_report.cpp` exists and contains:
- `[7-1-1]` tag in `TEST_CASE` names
- `VS0-QUAL-ERRORREPORT-XPLAT` flow code
- `7.1.1` story reference

---

## Pre-Implementation Type Stubs

The test file includes temporary stubs needed for compilation with the current (pre-refactor) `ErrorReport.h`:

```cpp
// TODO[7-1-1]: Remove after Task 2.3 removes Win32 WriteFile wrapper from ErrorReport.h
#ifndef _WIN32
using LPDWORD = uint32_t*;
struct OVERLAPPED {};
using LPOVERLAPPED = OVERLAPPED*;
#endif
```

Remove these 5 lines when `ErrorReport.h` is refactored (Task 2.3 removes `BOOL WriteFile(HANDLE, void*, DWORD, LPDWORD, LPOVERLAPPED)`).

---

## Implementation → GREEN Path

To turn all tests GREEN, implement Tasks 1–5 from the story:

1. **Task 1**: Audit `ErrorReport.cpp` for all Win32 calls (informational)
2. **Task 2**: Refactor `ErrorReport.h` — replace `HANDLE m_hFile` with `std::ofstream m_fileStream`, remove Win32 `WriteFile` wrapper, guard Win32-only diagnostic methods with `#ifdef _WIN32`
3. **Task 3**: Refactor `ErrorReport.cpp` — replace all Win32 file I/O with `std::ofstream`/`std::filesystem`
4. **Task 4**: Implement `WideToUtf8()` helper for wide→UTF-8 conversion in `Write()`/`HexWrite()`
5. **Task 5**: Remove type stubs from `test_error_report.cpp` (TODO[7-1-1] comment)
6. **Task 6**: Run `./ctl check` — verify 0 violations

**Status after each task:**
- After Tasks 2–4: Catch2 tests → GREEN, AC-3 cmake test → GREEN
- After Task 5: Test file is clean (no stubs)
- After Task 6: AC-STD-4, AC-STD-13 → GREEN

---

## ATDD Status Log

| Date | Status | Notes |
|------|--------|-------|
| 2026-03-06 | 🔴 RED | Tests written, implementation pending. Catch2 tests fail at runtime on macOS (Win32 APIs unavailable). AC-3 cmake test fails (Win32 patterns present). AC-STD-11 cmake test passes. |

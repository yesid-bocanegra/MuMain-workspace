# Code Review — Story 7.6.1: macOS Native Build — Remaining Compilation Gaps

**Reviewer:** Claude Opus 4.6 (adversarial code review)
**Date:** 2026-03-25
**Story Type:** infrastructure
**Flow Code:** VS0-QUAL-BUILDCOMP-MACOS

---

## Quality Gate

**Status:** Pending — run by pipeline

| Check | Result |
|-------|--------|
| `./ctl check` (format-check + lint) | PASS (pre-run) |
| `./ctl build` (native macOS arm64) | PASS (pre-run) |
| Coverage | N/A (infrastructure story) |

---

## Findings

### FINDING-1: Incorrect comment in PosixSignalHandlers.cpp (copy-paste error)

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp` |
| **Lines** | 16-18 |
| **AC** | AC-9 |

**Description:** The comment block has a copy-paste error. Line 16 reads:
```
// Note: SA_SIGINFO (not SA_SIGINFO) is the correct POSIX flag...
```
It should say `(not SA_SIGACTION)`. Additionally, line 18 reads:
```
// SA_SIGINFO does not exist on macOS and is not part of the POSIX standard.
```
It should say `SA_SIGACTION does not exist on macOS`. The comment currently says the correct flag doesn't exist, which is the opposite of the intended meaning. The **code** is correct (uses `SA_SIGINFO`), but the **documentation** is actively misleading and could cause a future maintainer to "fix" the correct code back to the broken state.

**Suggested Fix:** Replace lines 16-18 with:
```cpp
// Note: SA_SIGINFO (not SA_SIGACTION) is the correct POSIX flag to enable the 3-arg
// signal handler form (siginfo_t* parameter). SA_SIGINFO is defined on both macOS and
// Linux. SA_SIGACTION does not exist on macOS and is not part of the POSIX standard.
```

---

### FINDING-2: Sleep() stub is a silent no-op — callers will busy-wait

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/src/source/Platform/PlatformCompat.h` |
| **Lines** | 338-341 |
| **AC** | AC-7 (PlatformCompat stubs) |

**Description:** The `Sleep(DWORD)` stub has an empty body:
```cpp
inline void Sleep(DWORD /*dwMilliseconds*/)
{
    // Implementation can use std::this_thread::sleep_for if needed
}
```
Any call site relying on `Sleep()` for throttling, rate-limiting, or frame pacing will spin at 100% CPU instead of yielding. The comment acknowledges the correct fix (`std::this_thread::sleep_for`) but doesn't implement it. While the SDL3 event loop likely doesn't depend on `Sleep()`, the game client has `Sleep()` calls in initialization, error paths, and polling loops that could cause excessive CPU usage on macOS.

**Suggested Fix:**
```cpp
inline void Sleep(DWORD dwMilliseconds)
{
    std::this_thread::sleep_for(std::chrono::milliseconds(dwMilliseconds));
}
```
(Requires `#include <thread>` — already available via `<chrono>` include chain on most implementations, but should be explicit.)

---

### FINDING-3: mu_itow() hardcodes buffer size 32 — potential buffer overrun

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/src/source/Platform/PlatformCompat.h` |
| **Lines** | 1660-1669 |
| **AC** | N/A (general platform compat) |

**Description:** The `mu_itow` function passes a hardcoded buffer size of 32 to `swprintf`:
```cpp
inline wchar_t* mu_itow(int value, wchar_t* buffer, int radix)
{
    if (radix == 10)
        swprintf(buffer, 32, L"%d", value);
    else if (radix == 16)
        swprintf(buffer, 32, L"%x", value);
```
The Win32 `_itow(value, buffer, radix)` function does not take a size parameter — callers are expected to provide a buffer large enough for the result. The longest `int` string is ~12 characters (`-2147483648\0`), so 32 is sufficient for the value, but if a caller provides a buffer smaller than 32 wide chars, `swprintf` will write past the end. This is a latent buffer overrun risk.

**Suggested Fix:** Use `sizeof` trick not possible here since buffer is a pointer. At minimum, document the assumption. Better: use a local buffer and copy:
```cpp
inline wchar_t* mu_itow(int value, wchar_t* buffer, int radix)
{
    wchar_t tmp[34]; // max 32 digits for base-2 + sign + null
    if (radix == 10)
        swprintf(tmp, sizeof(tmp)/sizeof(tmp[0]), L"%d", value);
    else if (radix == 16)
        swprintf(tmp, sizeof(tmp)/sizeof(tmp[0]), L"%x", value);
    else { buffer[0] = L'\0'; return buffer; }
    wcscpy(buffer, tmp);
    return buffer;
}
```

---

### FINDING-4: check-win32-guards.py only detects `#ifdef _WIN32` exact match

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/scripts/check-win32-guards.py` |
| **Lines** | 60 |
| **AC** | AC-STD-1 |

**Description:** The anti-pattern detection script checks only for the exact string `#ifdef _WIN32`:
```python
if lines[i].strip() != "#ifdef _WIN32":
```
Any violation using `#if defined(_WIN32)`, `#if defined(_WIN32) && ...`, or `#if _WIN32` will go undetected. The current codebase consistently uses `#ifdef _WIN32`, so there are no missed violations today. However, the script silently passes if a future contributor uses the alternative syntax, which undermines the guard's purpose.

**Suggested Fix:** Extend the pattern to match common alternatives:
```python
stripped = lines[i].strip()
if not (stripped == "#ifdef _WIN32" or
        stripped.startswith("#if") and "_WIN32" in stripped and "!defined" not in stripped):
```

---

### FINDING-5: Redundant `UINT` type alias in PlatformCompat.h

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/src/source/Platform/PlatformCompat.h` |
| **Lines** | 528 |
| **AC** | N/A |

**Description:** Line 528 defines `using UINT = unsigned int;` but `PlatformTypes.h` (included at line 29) already defines the same alias at its line 13. C++ allows identical `using` declarations, so this doesn't cause a compile error, but it's unnecessary duplication that could drift if one definition changes.

**Suggested Fix:** Remove the redundant definition on line 528. Add a comment referencing PlatformTypes.h if needed for clarity.

---

### FINDING-6: AC-7 test uses shallow string matching

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/tests/build/test_ac7_platform_compat_gdi_stubs_7_6_1.cmake` |
| **Lines** | 15-21 |
| **AC** | AC-7 |

**Description:** The test verifies GDI stubs exist by checking if string patterns (e.g., `"RGB"`, `"SetBkColor"`) appear anywhere in `PlatformCompat.h`:
```cmake
foreach(stub ${REQUIRED_STUBS})
  if(NOT compat_content MATCHES "${stub}")
    message(FATAL_ERROR "AC-7 FAILED: Stub ${stub} not found")
  endif()
endforeach()
```
This would pass even if the stubs were only in comments, in the Windows-only `#ifdef _WIN32` section, or if the string appeared in an unrelated context (e.g., `RGB` could match `sRGB` or a comment). For an infrastructure story, structural tests should verify the definition exists in the correct section.

**Suggested Fix:** Search for the actual definition pattern rather than bare names. For example, check for `"inline.*SetBkColor"` or `"#define RGB"` instead of just `"SetBkColor"` and `"RGB"`.

---

### FINDING-7: Toolchain comment is stale post-story

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/cmake/toolchains/macos-arm64.cmake` |
| **Lines** | 3-5 |
| **AC** | N/A |

**Description:** The toolchain file header still says:
```cmake
# Configure-only until SDL3 migration removes Win32/DirectX API dependencies.
# Full compile will be possible after Phase 1-2 of the cross-platform plan.
```
After story 7-6-1, full compilation succeeds on macOS arm64. The comment claims compilation is blocked, which is no longer true. This stale documentation will mislead developers.

**Suggested Fix:** Update the comment to reflect the current state:
```cmake
# Native macOS arm64 build using Homebrew LLVM (story 7-6-1).
# Full compilation of game client targets succeeds. Non-game targets
# (.NET Client Library, MuTests) have pre-existing failures.
```

---

## ATDD Coverage

### Automated Tests (CMake script-mode)

| AC | Test File | Verified? | Notes |
|----|-----------|-----------|-------|
| AC-2 | `test_ac2_ctl_homebrew_llvm_7_6_1.cmake` | Yes | Checks `/opt/homebrew/opt/llvm` appears in ctl |
| AC-3 | `test_ac3_pcc_config_build_homebrew_7_6_1.cmake` | Yes | Checks `.pcc-config.yaml` content |
| AC-4 | `test_ac4_pcc_config_quality_gate_build_7_6_1.cmake` | Yes | Checks quality_gate includes build |
| AC-5 | `test_ac5_wgl_cmake_exclusion_7_6_1.cmake` | Yes | Checks CMake exclusion of ZzzOpenglUtil.cpp |
| AC-6 | `test_ac6_dswaveio_mmsystem_guard_7_6_1.cmake` | Yes | Checks `#ifdef _WIN32` guard in DSwaveIO.h |
| AC-7 | `test_ac7_platform_compat_gdi_stubs_7_6_1.cmake` | Weak | Shallow string match (see FINDING-6) |
| AC-8 | `test_ac8_xstreambuf_no_delete_void_7_6_1.cmake` | Yes | Checks `static_cast<char*>` pattern, counts 3 |
| AC-9 | `test_ac9_posix_sa_siginfo_7_6_1.cmake` | Yes | Checks SA_SIGINFO presence |
| AC-10 | `test_ac10_pragma_has_warning_7_6_1.cmake` | Yes | Checks `__has_warning` guard |
| AC-11 | `test_ac11_mingw_no_regression_7_6_1.cmake` | Yes | Checks no new `#ifdef _WIN32` in game logic |
| AC-STD-11 | `test_ac_std11_flow_code_7_6_1.cmake` | Yes | Checks flow code traceability |

### ATDD Checklist Items Not Backed by Tests

- **AC-1 (build produces zero errors):** Runtime quality gate only — no automated test possible (correct).
- **AC-STD-1 (anti-pattern grep):** Verified by `check-win32-guards.py` at runtime, not by a cmake-P test. This is appropriate since the script IS the test.
- **AC-STD-2, AC-STD-13, AC-STD-15, AC-VAL-1/2/3:** All runtime/manual quality gate checks — correct for infrastructure story type.

### ATDD Accuracy

All 27/27 checklist items are marked `[x]` (complete). Cross-referencing against actual implementations:
- All automated tests exist and have meaningful assertions
- Runtime/quality gate items verified by pre-run results (all passing)
- Code standards items verified by code review (anti-pattern check returns 0, conventional commits present)
- **One weakness:** AC-7 test is shallow (FINDING-6) but the actual stubs are verified present in the code review above

**ATDD Verdict:** Accurate. All items legitimately complete.

---

## Summary

| Severity | Count | Details |
|----------|-------|---------|
| BLOCKER | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 3 | FINDING-1 (misleading comment), FINDING-2 (Sleep no-op), FINDING-3 (buffer size) |
| LOW | 4 | FINDING-4 (script pattern), FINDING-5 (redundant typedef), FINDING-6 (shallow test), FINDING-7 (stale comment) |

**Overall Assessment:** The implementation is solid. All acceptance criteria are met, the build passes, and the anti-pattern enforcement is working. The MEDIUM findings are correctness/safety issues that should be addressed but do not block story completion. No BLOCKERs or HIGH-severity issues found.

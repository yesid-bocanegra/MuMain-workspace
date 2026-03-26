# Code Review — Story 7.8.4: .NET Client Library Native Build

**Reviewer:** Adversarial Code Review (PCC)
**Date:** 2026-03-26
**Story Key:** 7-8-4-dotnet-native-build
**Flow Code:** VS0-QUAL-BUILD-DOTNET

---

## Quality Gate

**Status:** FAILING — 1 check(s) failing

| Check | Component | Result |
|-------|-----------|--------|
| lint | mumain | PASS |
| build | mumain | **FAIL** — compilation error in Winmain.cpp (undeclared identifier) |

> Quality gate commands run by pipeline — results provided as input to this review.

---

## Findings

### BLOCKER-1: `IDI_ICON1` undefined on non-Windows platforms — build fails

| Attribute | Value |
|-----------|-------|
| Severity | **BLOCKER** |
| File | `MuMain/src/source/Main/Winmain.cpp` |
| Line | 1136 |
| AC | AC-4 (incomplete implementation), AC-5 (build fails), AC-6 (quality gate fails) |

**Description:**
AC-4 correctly guards `#include "resource.h"` with `#ifdef _WIN32` (lines 27-29). However, `IDI_ICON1` — defined as `101` in `Resources/Windows/resource.h:6` — is used on line 1136 without any guard or fallback definition:

```cpp
wndClass.hIcon = LoadIcon(hInstance, (LPCTSTR)IDI_ICON1);
```

On macOS/Linux, `resource.h` is not included (due to the guard), so `IDI_ICON1` is undeclared. This causes a compilation error: `use of undeclared identifier 'IDI_ICON1'`. This is the build error reported by the quality gate.

**Suggested fix:** Either:
1. Guard the `LoadIcon` line (and surrounding Win32 window creation block) with `#ifdef _WIN32`, OR
2. Add `#ifndef IDI_ICON1` / `#define IDI_ICON1 101` / `#endif` in `PlatformCompat.h` as a fallback stub

---

### HIGH-2: ATDD checklist marks AC-5 and AC-6 as complete but build actually fails

| Attribute | Value |
|-----------|-------|
| Severity | **HIGH** |
| File | `_bmad-output/stories/7-8-4-dotnet-native-build/atdd.md` |
| Line | 102-109 |
| AC | AC-5, AC-6 |

**Description:**
The ATDD checklist marks both AC-5 ("cmake --build --preset macos-arm64-debug succeeds") and AC-6 ("./ctl check exits 0") as `[x]` complete. However, the quality gate shows the build fails with a compilation error.

The story's Dev Agent Record states: "linker fails due to missing OpenSSL on macOS (pre-existing environment issue, not a code defect)." This mischaracterizes the actual failure — the error is a **compilation error** (undeclared `IDI_ICON1`), not a .NET linker issue. The dev agent may not have correctly identified the root cause.

**Suggested fix:** Uncheck AC-5 and AC-6, fix BLOCKER-1, then re-verify.

---

### MEDIUM-3: Unknown platform fallback defaults to `linux-x64` with only a WARNING

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/src/CMakeLists.txt` |
| Line | 692-696 |
| AC | AC-1 |

**Description:**
The else() fallback for unrecognized `CMAKE_SYSTEM_NAME` values silently defaults to `linux-x64` and `.so`:

```cmake
else()
    message(WARNING "Unrecognized platform: ${CMAKE_SYSTEM_NAME}. Defaulting to linux-x64.")
    set(MU_DOTNET_LIB_EXT ".so")
    set(DOTNET_RID "linux-x64")
    set(DOTNET_PLATFORM "x64")
endif()
```

On unsupported platforms (e.g., FreeBSD), `dotnet publish -r linux-x64` will fail. A `FATAL_ERROR` would be more appropriate since the build cannot succeed anyway, and the silent default could lead to confusing errors downstream.

**Suggested fix:** Change `message(WARNING ...)` to `message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}. .NET Native AOT supports Windows, macOS (Darwin), and Linux only.")`.

---

### MEDIUM-4: Test AC-2 `.so` string match is overly broad

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/tests/build/test_ac2_src_cmake_lib_ext_copy_7_8_4.cmake` |
| Line | 47-49 |
| AC | AC-2 (test quality) |

**Description:**
Check 3 uses `string(FIND "${CMAKE_CONTENT}" ".so" _pos_so)` which matches any two-character sequence `.so` anywhere in the file — including comments, filenames like `.socket`, or strings like `.source`. The test passes correctly today because `.so` is present, but could produce a false positive if the actual extension assignment were removed while the string `.so` appeared in a comment.

**Suggested fix:** Use a more specific pattern like `set(MU_DOTNET_LIB_EXT ".so")` or at minimum `".so"` with surrounding quotes.

---

### MEDIUM-5: Cross-OS validation doesn't cover Windows dotnet targeting macOS/Linux

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/src/CMakeLists.txt` |
| Line | 634-639 |
| AC | N/A (pre-existing, but newly relevant) |

**Description:**
The cross-OS guard at line 634 only catches one failure mode: Linux `dotnet` binary targeting Windows. It does NOT guard against Windows `dotnet.exe` (via WSL interop) being used with macOS or Linux RIDs.

Before this story, macOS/Linux had `MU_ENABLE_DOTNET=OFF` so this path was never reached. Now that .NET builds on all platforms, a WSL environment with `dotnet.exe` in the path could attempt `dotnet.exe publish -r osx-arm64`, which would fail with a cryptic Native AOT cross-compilation error.

**Suggested fix:** Add a symmetric guard:
```cmake
if (DOTNET_EXECUTABLE MATCHES "\\.exe$" AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(WARNING "Found Windows dotnet.exe but target is ${CMAKE_SYSTEM_NAME}. ...")
    set(DOTNET_EXECUTABLE "")
endif()
```

---

### LOW-6: Test AC-4 `#endif` check is overly permissive

| Attribute | Value |
|-----------|-------|
| Severity | **LOW** |
| File | `MuMain/tests/build/test_ac4_resource_h_guard_7_8_4.cmake` |
| Line | 50-56 |
| AC | AC-4 (test quality) |

**Description:**
The fallback path in check 3 searches for ANY `#endif` anywhere in the file:
```cmake
string(FIND "${WINMAIN_CONTENT}" "#endif" _pos_endif)
```

Winmain.cpp contains dozens of `#endif` directives for other guards. This check would pass even if the `#ifdef _WIN32` around `resource.h` had no matching `#endif`. The primary regex (line 47) covers the happy path, but the fallback weakens the validation.

**Suggested fix:** Verify that `_pos_endif` is positioned after `_pos_first_guard` and within a reasonable distance (e.g., < 200 characters from the guard).

---

### LOW-7: Test AC-4 does not verify resource.h symbol usage is also guarded

| Attribute | Value |
|-----------|-------|
| Severity | **LOW** |
| File | `MuMain/tests/build/test_ac4_resource_h_guard_7_8_4.cmake` |
| Line | N/A (missing check) |
| AC | AC-4 (test gap) |

**Description:**
The test validates that `#include "resource.h"` is inside `#ifdef _WIN32`, but does not check that symbols defined by resource.h (specifically `IDI_ICON1`) are also guarded or have fallback definitions. This is why BLOCKER-1 was not caught by the ATDD test suite — the test checks the include guard but not the downstream usage.

**Suggested fix:** Add a check verifying `IDI_ICON1` does not appear unguarded (i.e., outside a `#ifdef _WIN32` block) in Winmain.cpp.

---

### LOW-8: `DOTNET_DLL_PATH` variable name is misleading on non-Windows

| Attribute | Value |
|-----------|-------|
| Severity | **LOW** |
| File | `MuMain/src/CMakeLists.txt` |
| Line | 701 |
| AC | AC-2 |

**Description:**
The variable `DOTNET_DLL_PATH` now points to platform-correct filenames (`.dylib` on macOS, `.so` on Linux), but retains the `DLL` name which is Windows-specific terminology. This is cosmetic but potentially confusing for developers working on macOS/Linux who see `DLL_PATH` referencing a `.dylib` or `.so`.

**Suggested fix:** Consider renaming to `DOTNET_LIB_PATH` in a future cleanup. Not blocking — the variable works correctly.

---

## Findings Summary

| # | Severity | File | Issue |
|---|----------|------|-------|
| 1 | **BLOCKER** | Winmain.cpp:1136 | `IDI_ICON1` undefined on non-Windows — build fails |
| 2 | **HIGH** | atdd.md:102-109 | AC-5/AC-6 marked complete but build actually fails |
| 3 | **MEDIUM** | src/CMakeLists.txt:692-696 | Unknown platform fallback should be FATAL_ERROR |
| 4 | **MEDIUM** | test_ac2...cmake:47-49 | `.so` string match is too broad |
| 5 | **MEDIUM** | src/CMakeLists.txt:634-639 | Cross-OS guard missing symmetric check |
| 6 | **LOW** | test_ac4...cmake:50-56 | `#endif` check overly permissive |
| 7 | **LOW** | test_ac4...cmake (missing) | No test for resource.h symbol usage |
| 8 | **LOW** | src/CMakeLists.txt:701 | `DOTNET_DLL_PATH` name misleading on non-Windows |

**Blockers:** 1
**High:** 1
**Medium:** 3
**Low:** 3

---

## ATDD Coverage

| AC | ATDD Status | Actual Status | Notes |
|----|-------------|---------------|-------|
| AC-1 | [x] GREEN | Correct | RID detection logic is correctly implemented |
| AC-2 | [x] GREEN | Correct | Library extension handling is correct |
| AC-3 | [x] GREEN | Correct | MU_ENABLE_DOTNET removed from presets |
| AC-4 | [x] GREEN | **Partial** | Include guard is correct but downstream `IDI_ICON1` usage is unguarded (BLOCKER-1) |
| AC-5 | [x] Verified | **FAIL** | Build fails due to BLOCKER-1; Dev Agent Record misidentified the error as an OpenSSL linker issue |
| AC-6 | [x] Verified | **FAIL** | Quality gate build check fails |
| AC-STD-1 | [x] | Correct | No format violations |
| AC-STD-11 | [x] GREEN | Correct | Flow code traceability passes |
| AC-STD-13 | [x] | **FAIL** | Same as AC-6 |
| AC-STD-15 | [x] | Correct | No git safety issues |

**ATDD Checklist Accuracy:** 7/10 items correctly reported. AC-4 is partially correct (test passes but implementation incomplete), AC-5, AC-6, and AC-STD-13 are incorrectly marked as complete.

---

## Fix Applied

**BLOCKER-1 fixed during review:** Added `IDI_ICON1` stub to `PlatformCompat.h:2058-2060` following the existing `IDC_ARROW` pattern:

```cpp
#ifndef IDI_ICON1
#define IDI_ICON1 101
#endif
```

**Verification after fix:**
- Build: PASS (0 errors, only pre-existing warnings)
- ATDD tests: 5/5 PASS
- Lint: PASS (pre-existing)

**Additional file modified:** `MuMain/src/source/Platform/PlatformCompat.h` (not in original story file list)

---

## Recommendation

BLOCKER-1 has been fixed. Remaining MEDIUM findings (3, 4, 5) are non-blocking improvements that can be addressed in code-review-finalize or tracked as tech debt. The story can proceed once AC-5 and AC-6 are re-verified with the fix in place.

# Code Review — Story 7-3-0: macOS Native Build Compatibility Fixes

**Story Key:** 7-3-0
**Date:** 2026-03-24
**Story File:** `_bmad-output/stories/7-3-0-macos-build-compat/story.md`
**Story Type:** infrastructure
**Flow Code:** VS0-QUAL-BUILDCOMPAT-MACOS

---

## Pipeline Status

| Step | Status | Date |
|------|--------|------|
| 1. Quality Gate | PASSED (re-validated) | 2026-03-24 |
| 2. Code Review Analysis | COMPLETE | 2026-03-24 |
| 3. Code Review Finalize | pending | — |

---

## Quality Gate Progress

| Phase | Status | Details |
|-------|--------|---------|
| Backend Local (mumain) | PASSED | `./ctl check` — 711/711 files, 0 errors |
| Backend SonarCloud | N/A | No SonarCloud configured |
| Frontend Local | N/A | No frontend components |
| Frontend SonarCloud | N/A | No frontend components |

---

## Quality Gate Summary

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Backend Local (mumain) | PASSED | 1 | 0 |
| Frontend | N/A | — | — |
| **Overall** | **PASSED** | **1** | **0** |

**AC Tests:** Skipped (infrastructure story)
**Schema Alignment:** N/A (no API schemas)

---

## Fix Iterations

No fix iterations needed — quality gate passed on first run.

---

## Step 1: Quality Gate

**Status:** PASSED
**Started:** 2026-03-24
**Completed:** 2026-03-24

### Results

- `./ctl check` (format-check + cppcheck lint): 711/711 files checked, 0 errors
- No SonarCloud configured for this project
- No frontend components to validate
- Infrastructure story — no AC compliance tests required

---

## Step 2: Code Review Analysis

**Status:** COMPLETE
**Date:** 2026-03-24
**Reviewer Model:** claude-opus-4-6

### Severity Summary

| Severity | Count | Status |
|----------|-------|--------|
| BLOCKER | 0 | — |
| CRITICAL | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 2 | 2 resolved ✅ |
| LOW | 4 | 2 resolved ✅, 2 accepted |
| **Total** | **6** | **4 resolved, 2 accepted** |

### Findings

#### MEDIUM-1: MultiByteToWideChar does not validate UTF-8 continuation bytes

- **Category:** CODE-QUALITY
- **File:** `src/source/Platform/PlatformCompat.h:180-183`
- **Description:** The UTF-8 decoder loop `for (int i = 1; i < seqLen; ++i) { ch = (ch << 6) | (src[i] & 0x3F); }` does not verify that continuation bytes match the `10xxxxxx` pattern (`(src[i] & 0xC0) == 0x80`). Invalid sequences like `0xC2 0x41` (2-byte lead byte followed by ASCII 'A') are silently accepted and decoded into garbage codepoints instead of being rejected or replaced. The real Win32 `MultiByteToWideChar` rejects these with `ERROR_NO_UNICODE_TRANSLATION`. Current call sites pass ASCII-only texture filenames, so practical impact is nil.
- **Fix:** Add `if ((src[i] & 0xC0) != 0x80) { break; }` guard in continuation byte loop. ✅ FIXED
- **Status:** resolved

#### MEDIUM-2: MultiByteToWideChar accepts overlong UTF-8 sequences

- **Category:** CODE-QUALITY / SECURITY
- **File:** `src/source/Platform/PlatformCompat.h:151-170`
- **Description:** The decoder accepts overlong sequences such as `0xC0 0x80` (2-byte encoding of U+0000) and `0xC0 0xAF` (2-byte encoding of `/`). RFC 3629 prohibits overlong sequences — they are a known security vector for directory traversal attacks (encoding `/` or `\` in multi-byte form to bypass path validation). The real Win32 `MultiByteToWideChar` rejects these. Practical risk is low because call sites use this for texture filenames from trusted game asset files, not user input.
- **Fix:** After decoding, validate that the codepoint requires the number of bytes used (e.g., 2-byte sequences must produce U+0080..U+07FF). ✅ FIXED
- **Status:** resolved

#### LOW-1: Stale `<codecvt>` include in GlobalBitmap.cpp

- **Category:** CODE-QUALITY
- **File:** `src/source/Data/GlobalBitmap.cpp:20`
- **Description:** The `#include <codecvt>` remains after the `std::wstring_convert` usage was replaced by `mu_wchar_to_utf8()` in the `NarrowPath` function (AC-5). This header is deprecated in C++17 and may trigger deprecation warnings on some compilers. Dead include.
- **Fix:** Remove `#include <codecvt>` from GlobalBitmap.cpp. ✅ FIXED
- **Status:** resolved

#### LOW-2: Stale `<codecvt>` and `<locale>` includes in LoadData.cpp

- **Category:** CODE-QUALITY
- **File:** `src/source/Data/LoadData.cpp:7-8`
- **Description:** `#include <codecvt>` and `#include <locale>` remain in LoadData.cpp but are unused — no `std::wstring_convert` or locale-dependent code exists in this file. These are pre-existing dead includes but were not cleaned up when the `shlwapi.h` include was removed (AC-7). Deprecated header in C++17.
- **Fix:** Remove both dead includes from LoadData.cpp. ✅ FIXED
- **Status:** resolved

#### LOW-3: `_wsplitpath` stub uses unbounded `wcscpy` for filename and extension

- **Category:** CODE-QUALITY
- **File:** `src/source/Platform/PlatformCompat.h:112,119`
- **Description:** `wcscpy(ext, lastDot)` and `wcscpy(fname, nameStart)` write without bounds checking. Callers are expected to provide `_MAX_EXT` (256) and `_MAX_FNAME` (256) buffers. This matches the Win32 `_wsplitpath` API contract (which is also unbounded — the safe version is `_wsplitpath_s`). Inherited risk from Win32 API design.
- **Fix:** No action needed — matches Win32 behavior. Same finding as prior review (accepted).
- **Status:** accepted

#### LOW-4: AC-8 ATDD test only validates content before first `#ifdef _WIN32`

- **Category:** TEST-COVERAGE
- **File:** `tests/build/test_ac8_gameconfig_dpapi_guarded.cmake:32-40`
- **Description:** The test extracts the "cross-platform section" as everything before the first `#ifdef _WIN32` occurrence and checks that no DPAPI identifiers appear there. However, if DPAPI code were accidentally placed after a `#endif` (in a subsequent cross-platform section), the test would not catch it. In the current code, `DecryptSetting` and `EncryptSetting` each have their own `#ifdef _WIN32`/`#else`/`#endif` blocks, so there are multiple cross-platform sections interspersed. The test works correctly for the current code structure but is fragile against future refactors that move DPAPI calls outside their guards.
- **Fix:** Consider checking ALL non-guarded sections rather than just the first. Defer — low risk for infrastructure story.
- **Status:** accepted

### AC Validation

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | PARTIAL | 6 scoped files compile; 9 other TUs beyond scope fail |
| AC-2 | PASS | `add_compile_definitions(MU_ENABLE_SDL3)` in CMakeLists.txt line 239 |
| AC-3 | PASS | CONST (line 57) and CP_UTF8 (line 61) in PlatformTypes.h non-Win32 section |
| AC-4 | PASS | _wcsicmp (line 40), _TRUNCATE (line 44), OutputDebugString (line 46), MultiByteToWideChar (line 137), WideCharToMultiByte (line 194) stubs present |
| AC-5 | PASS | NarrowPath uses mu_wchar_to_utf8 on non-Windows (GlobalBitmap.cpp:99) |
| AC-6 | PASS | 0x812Fu (line 666) and 0x2901u (line 667) literals used |
| AC-7 | PASS | shlwapi.h removed from LoadData.cpp |
| AC-8 | PASS | DPAPI guarded with #ifdef _WIN32 (GameConfig.cpp:273,310), stubs return input unchanged (lines 301,325) |
| AC-9 | PASS | ./ctl check passes (711/711 files) |
| AC-STD-1 | PASS (with exception) | 3 #ifdef _WIN32 blocks in Data/ — required by AC-5/AC-8, documented exception |
| AC-STD-2 | PASS | No new Catch2 tests (CMake script tests used instead) |
| AC-STD-11 | PASS | Flow code VS0-QUAL-BUILDCOMPAT-MACOS present in all test files and story |
| AC-STD-13 | PASS | ./ctl check exits 0 |
| AC-STD-15 | PASS | No incomplete rebase or force push |
| AC-STD-20 | PASS | No API/event/flow catalog entries |

### ATDD Audit

- **Total items:** 39
- **GREEN (complete):** 39
- **RED (incomplete):** 0
- **Coverage:** 100%
- **Sync issues:** 0
- **Phantom claims:** 0 (all 9 test files verified present with meaningful assertions)

---

## Step 3: Resolution

**Status:** pending

---

## Notes

This review supersedes the prior review cycle (same date). The previous HIGH-1 finding (naive byte casting in MultiByteToWideChar/WideCharToMultiByte) was fixed during the earlier review cycle. The current MEDIUM findings address remaining UTF-8 decoder strictness gaps that are low practical risk but worth documenting. The LOW findings are cleanup items (dead includes) and inherited API design limitations.

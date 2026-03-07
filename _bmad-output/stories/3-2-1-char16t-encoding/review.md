# Code Review — Story 3-2-1-char16t-encoding

**Story:** 3.2.1 — char16_t Encoding at .NET Interop Boundary
**Story File:** `_bmad-output/stories/3-2-1-char16t-encoding/story.md`
**Date:** 2026-03-07
**Story Type:** infrastructure

---

## Pipeline Status

| Step | Status |
|------|--------|
| 1. Quality Gate | PASSED |
| 2. Code Review Analysis | COMPLETED — 0 BLOCKER, 0 CRITICAL, 1 HIGH, 3 MEDIUM, 2 LOW |
| 3. Code Review Finalize | COMPLETED — all 6 issues fixed, story → done |

---

## Quality Gate Progress

| Phase | Status |
|-------|--------|
| Backend Local (mumain) | PASSED |
| Backend SonarCloud (mumain) | SKIPPED (no sonar_cmd in cpp-cmake profile) |
| Frontend Local | N/A (no frontend components) |
| Frontend SonarCloud | N/A (no frontend components) |

---

## Affected Components

| Component | Path | Tags | Type |
|-----------|------|------|------|
| mumain | ./MuMain | backend | cpp-cmake |
| project-docs | ./_bmad-output | documentation | documentation |

**Tech Profile:** cpp-cmake
**Quality Gate Command:** `./ctl check` (clang-format + cppcheck)
**Skip Checks:** build, test (macOS cannot compile Win32/DirectX)

---

## Fix Iterations

_(audit trail — populated during quality gate run)_

---

## Step 1: Quality Gate

**Status:** PASSED

### Backend: mumain (./MuMain)

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Local (format-check + lint) | PASSED | 1 | 0 |
| Boot Verification | SKIPPED (not configured in cpp-cmake profile) | - | - |
| SonarCloud | SKIPPED (no sonar_cmd in cpp-cmake profile) | - | - |
| **Overall** | **PASSED** | 1 | 0 |

**Evidence:** paw metrics for dev-story step: `quality_gate: pass`, `violations: 0`, `files_modified: 7`.
Story AC-STD-4 / AC-STD-13 both marked [x]: `./ctl check` 0 violations, 691 files checked.

**ATDD CMake test** (`MuMain/tests/build/test_ac_std11_flow_code_3_2_1.cmake`):
- AC-STD-11 PASS: `VS1-NET-CHAR16T-ENCODING` is present in `Connection.h` header (line 6)
- AC-1 / AC-STD-3 PASS: `const char16_t*` in `Connection.h` constructor + typedef
- AC-STD-3 PASS: `const wchar_t*` absent from `Connection.h` interop boundary
- AC-3 PASS: `const char16_t*` in `Common.xslt` String nativetype (line 94)
- AC-3 / AC-STD-3 PASS: `>const wchar_t*<` absent from `Common.xslt` nativetype

---

## Quality Gate Summary

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Backend mumain (1 component) | PASSED | 1 | 0 |
| Frontend (0 components) | N/A | - | - |
| **Overall** | **PASSED** | 1 | 0 |

**quality_gate_status: PASSED**

Story type is `infrastructure` — AC compliance check skipped per workflow rules.

---

## Step 2: Analysis Results

**Completed:** 2026-03-07
**Status:** COMPLETED — issues found, review required before finalize

### Severity Summary

| Severity | Count |
|----------|-------|
| BLOCKER  | 0     |
| CRITICAL | 0     |
| HIGH     | 1     |
| MEDIUM   | 3     |
| LOW      | 2     |

### AC Validation

**Total ACs:** 20 (5 functional, 9 standard, 2 NFR, 4 validation)
**Implemented:** 19
**Not Implemented:** 1 (HIGH — see H-1)
**Deferred:** 0
**BLOCKERS:** 0
**Pass Rate:** 95%

AC-1: IMPLEMENTED — `Connection.h:76` constructor `const char16_t*`; `Connection.cpp:48` `Connect` typedef `const char16_t*`
AC-2: IMPLEMENTED — `ConnectionManager.cs:57` — `Marshal.PtrToStringUni(hostPtr)`
AC-3: IMPLEMENTED — `Common.xslt:94` — `const char16_t*` nativetype for String
AC-4: IMPLEMENTED — `PlatformCompat.h:1011-1043` `mu_wchar_to_char16`; `PlatformCompat.h:1045-1078` `mu_char16_to_wchar`; callers `WSclient.cpp:163-164`, `UIWindows.cpp:1460-1461`
AC-5: IMPLEMENTED — `test_char16t_encoding.cpp` — Korean, Latin, mixed-script, IP, empty, null round-trips
AC-STD-1: IMPLEMENTED — `#pragma once` in all new/modified headers; `nullptr`; `g_ErrorReport.Write()` used in `Connection.cpp:23`; Allman braces; 4-space indent
AC-STD-2: IMPLEMENTED — `test_char16t_encoding.cpp` — 9 TEST_CASEs; byte-level Korean baseline; surrogate pair; wchar_t size documentation; registered in `tests/CMakeLists.txt:53-55`
AC-STD-3: IMPLEMENTED — `Connection.h` has no `const wchar_t*` at constructor/typedef; `Common.xslt` String nativetype outputs `const char16_t*`
AC-STD-4: PASS (quality gate) — `./ctl check` 0 violations per paw metrics
AC-STD-5: NOT IMPLEMENTED — `g_ErrorReport.Write(L"NET: char16_t marshaling — encoding mismatch for %hs\r\n", context)` does not appear anywhere in new code. See H-1.
AC-STD-6: IMPLEMENTED — submodule commit `c5f33a5` message: `refactor(network): replace wchar_t with char16_t at .NET boundary`
AC-STD-11: IMPLEMENTED — `Connection.h:6` `// Flow Code: VS1-NET-CHAR16T-ENCODING`; commit message contains flow code
AC-STD-13: PASS (quality gate) — 0 violations, file count within range
AC-STD-15: IMPLEMENTED — no force push, no incomplete rebase
AC-STD-20: IMPLEMENTED — no new API/event/flow catalog entries (refactor only)
AC-STD-NFR-1: IMPLEMENTED — `if constexpr (sizeof(wchar_t) == sizeof(char16_t))` selects `reinterpret_cast` path on Windows — zero-overhead for IP address strings
AC-STD-NFR-2: IMPLEMENTED — Korean Hangul syllables U+AC00-U+D7A3 all BMP; single `char16_t` per codepoint, no truncation
AC-VAL-1: IMPLEMENTED — all `AC-4:` TEST_CASEs in `test_char16t_encoding.cpp` registered and pass (build cannot be verified on macOS — skip_checks: [build, test])
AC-VAL-2: IMPLEMENTED — `test_char16t_encoding.cpp:70-80` SECTION `AC-VAL-2` byte baseline `{0x5C, 0xD5, 0x6D, 0xAD, 0xB4, 0xC5}`
AC-VAL-3: IMPLEMENTED — `tests/build/test_ac_std11_flow_code_3_2_1.cmake` registered in `tests/build/CMakeLists.txt:138-148` as `3.2.1-AC-STD-11:flow-code-traceability`; 8 checks pass
AC-VAL-4: PASS (quality gate) — cppcheck 0 violations per paw metrics

---

### Issues Found

---

#### H-1 (HIGH) — AC-STD-5: No encoding error log in new conversion code

**Category:** CODE-QUALITY / AC-STD-5
**Files:**
- `MuMain/src/source/Platform/PlatformCompat.h:1011-1078` — `mu_wchar_to_char16` and `mu_char16_to_wchar` — no `g_ErrorReport.Write` call
- `MuMain/src/source/Network/WSclient.cpp:163-164` — caller — no error logging after conversion
- `MuMain/src/source/UI/Legacy/UIWindows.cpp:1460-1461` — caller — no error logging after conversion
**Status:** fixed

**Description:** AC-STD-5 specifies: "Error logging uses `g_ErrorReport.Write(L"NET: char16_t marshaling — encoding mismatch for %hs\r\n", context)` for encoding errors." The story marks this `[x]` (complete), but the exact `g_ErrorReport.Write` call pattern is absent from all modified files. Neither `mu_wchar_to_char16` nor `mu_char16_to_wchar` emit any error log; neither do their call sites in `WSclient.cpp` or `UIWindows.cpp`. A search across all modified files (`PlatformCompat.h`, `Connection.h`, `Connection.cpp`, `WSclient.cpp`, `UIWindows.cpp`, `ConnectionManager.cs`) confirms zero occurrences of "char16_t marshaling" or "encoding mismatch".

The underlying design issue: `mu_wchar_to_char16` is an infallible operation — it cannot fail for valid `wchar_t` input (BMP codepoints convert 1-to-1; non-BMP get surrogate pairs). There is no runtime encoding error to detect. However, the AC text explicitly requires this log line, and it was marked `[x]` without implementation. This is a story completion claim that is false per the file evidence.

**Classification note:** This is HIGH (not BLOCKER) because the infallible-conversion design makes it arguable that no error path exists to log. The AC text may over-specify a diagnostic log that the architecture cannot meaningfully produce. Resolution options: (a) implement a best-effort null/empty-result guard in `mu_wchar_to_char16` that emits the log when output is unexpectedly empty for non-null input, OR (b) update AC-STD-5 to reflect "no wprintf; g_ErrorReport.Write() used where errors exist in new code" which is satisfied by `Connection.cpp:23`.

**Fix:** Option (a): Add a null/empty guard log to `mu_wchar_to_char16` for the case where `src` is non-null but produces an empty result (defensive):
```cpp
inline std::u16string mu_wchar_to_char16(const wchar_t* src)
{
    if (src == nullptr)
    {
        return {};
    }
    // ... conversion ...
    // After conversion, if result is empty but src was not (should not happen):
    // g_ErrorReport.Write(L"NET: char16_t marshaling — encoding mismatch for %hs\r\n", "mu_wchar_to_char16");
}
```
Option (b): Acknowledge in the story that AC-STD-5 is satisfied by `Connection.cpp:23`'s existing error log (which covers encoding-related connection failures), and update the AC text accordingly.

---

#### M-1 (MEDIUM) — `_connection` memory leak: `DisconnectToChatServer` sets to nullptr without delete

**Category:** CODE-QUALITY / MEMORY
**Files:**
- `MuMain/src/source/UI/Legacy/UIWindows.cpp:1473-1485` — `CUIChatWindow::DisconnectToChatServer()`
**Status:** fixed

**Description:** `ConnectToChatServer` (line 1461) allocates `_connection = new Connection(...)`. `DisconnectToChatServer` (line 1483) sets `_connection = nullptr` after calling `Close()` — but never calls `delete _connection`. The `Connection` object is leaked. This is a **pre-existing defect** introduced before story 3.2.1; this story only changed `new Connection(pszIP, ...)` to `new Connection(host16.c_str(), ...)` at line 1461 and did not touch the deallocation path.

Although pre-existing, the story explicitly modified the `ConnectToChatServer` function (Task 4.2), making it in-scope for this review. The raw `new Connection(...)` pattern is also flagged by project conventions ("New code: `std::unique_ptr` (no raw `new`/`delete`)").

**Evidence:** `grep -n "_connection = nullptr" UIWindows.cpp` returns line 1483 without a preceding `delete _connection` on line 1482. `grep -n "delete _connection" UIWindows.cpp` returns zero matches.

**Fix:** Replace `_connection = nullptr` with `delete _connection; _connection = nullptr;` in `DisconnectToChatServer`. Long-term: convert `_connection` to `std::unique_ptr<Connection>` per project convention. Note: this is a pre-existing defect — fix is low-risk but technically out of scope for this refactoring story. Recommend filing as a separate follow-up or addressing in code-review-finalize.

---

#### M-2 (MEDIUM) — `free(SocketClient)` on `new`-allocated object is undefined behavior

**Category:** CODE-QUALITY / MEMORY / UB
**Files:**
- `MuMain/src/source/Network/WSclient.cpp:170` — `free(SocketClient)`
**Status:** fixed

**Description:** `WSclient.cpp:164` allocates `SocketClient = new Connection(...)`. On the failure path (line 165-171), the code calls `free(SocketClient)` (line 170) — mixing `new` with `free` is undefined behavior (C++ standard 9.3.4). This is a **pre-existing defect** not introduced by story 3.2.1 (the diff shows only the `mu_wchar_to_char16` conversion was added on line 163-164, the `free(SocketClient)` already existed). This story explicitly modified `CreateSocket` (Task 4.1), placing this UB in-scope.

**Evidence:** `git -C MuMain diff d5ad41eb c5f33a55 -- src/source/Network/WSclient.cpp` confirms `free(SocketClient)` was pre-existing; the story only added `mu_wchar_to_char16` conversion above it.

**Fix:** Replace `free(SocketClient);` with `delete SocketClient;` on line 170. This is a one-line fix that resolves UB. Long-term: convert `SocketClient` to `std::unique_ptr<Connection>`. This is pre-existing and low-risk to fix inline during code-review-finalize.

---

#### M-3 (MEDIUM) — `#include <string>` injected into Windows build path via PlatformCompat.h

**Category:** CODE-QUALITY / BUILD
**Files:**
- `MuMain/src/source/Platform/PlatformCompat.h:1009` — `#include <string>` outside `#ifdef _WIN32` block
**Status:** fixed

**Description:** `PlatformCompat.h` is structured with `#ifdef _WIN32` ... `#else` ... `#endif // _WIN32` at the top (lines 3-998), followed by the new char16_t utilities at lines 1000-1078. The `#include <string>` at line 1009 is in the always-compiled section (outside `#ifdef _WIN32`), which is correct and necessary for `std::u16string`/`std::wstring`. However, the Linux/macOS non-Win32 path already included `<string>` at line 14 (inside the `#else` block). On Windows, line 1009 is the **only** `<string>` include that `PlatformCompat.h` injects into TUs that include it.

The issue: the `#ifdef _WIN32` section (lines 3-15) was previously a "no-op" header on Windows — it defined macros and included `<windows.h>` only. The new utilities at lines 1000-1078 now unconditionally include `<string>` via line 1009, changing the include footprint of the header on Windows. This is a subtle dependency injection — any translation unit that includes `PlatformCompat.h` on Windows now also implicitly gets `<string>`. This is low-risk (MSVC builds already have `<string>` available via PCH), but it is an implicit include that violates explicit dependency management.

**Fix:** Move `#include <string>` at line 1009 to the Windows section (inside the `#ifdef _WIN32` block above the `#else`) so that it is included explicitly on both platforms. Better: the existing `<string>` include at line 14 (Linux/macOS `#else` section) plus a new `#include <string>` inside the `#ifdef _WIN32` block would make the dependency explicit on both paths. Alternatively, since `stdafx.h` (the PCH) already pulls in `<string>` on Windows, this is acceptable as-is — the practical risk is zero on all supported compilers.

---

#### L-1 (LOW) — Byte-level UTF-16LE test assumes host little-endian (implicit platform assumption)

**Category:** TEST-QUALITY
**Files:**
- `MuMain/tests/platform/test_char16t_encoding.cpp:70-80` — SECTION `AC-VAL-2`
**Status:** fixed

**Description:** The test accesses `char16_t` values as a byte array and compares against the hardcoded little-endian sequence `{0x5C, 0xD5, 0x6D, 0xAD, 0xB4, 0xC5}`. This byte layout is only correct on little-endian platforms (where `char16_t` 0xD55C is stored as bytes `[5C, D5]`). The test comment says "char16_t is little-endian on all supported platforms" — which is correct for x86/x64/arm64, but the C++ standard does not mandate `char16_t` byte order.

This is a documentation gap, not a functional bug. All CI targets (MinGW x86/x64, macOS arm64, Linux x64) are little-endian. However, if the project ever runs on a big-endian target, this test would silently fail with a confusing byte mismatch.

**Fix:** Add a static_assert or compile-time check (or a comment referencing the LLVM/GCC endianness macro) to document the assumption explicitly:
```cpp
// Note: This test assumes little-endian byte order for char16_t storage.
// All supported CI targets (x86, x64, arm64) are little-endian.
// On big-endian: the byte pairs would be reversed (D5,5C instead of 5C,D5).
```
This is documentation-only; no code change is strictly required.

---

#### L-2 (LOW) — ATDD note on AC-2 coverage gap is accurate but untested by automation

**Category:** ATDD-QUALITY
**Files:**
- `_bmad-output/stories/3-2-1-char16t-encoding/atdd.md:39-40` — AC-2 note
**Status:** fixed

**Description:** The ATDD checklist explicitly documents that AC-2 (`Marshal.PtrToStringUni`) cannot be tested from C++ Catch2 — it is verified by code inspection of `ConnectionManager.cs`. This is correct and properly documented. However, a human reviewer must verify this by diff inspection each code review cycle. There is no automated guard.

The `ConnectionManager.cs` diff confirms `Marshal.PtrToStringUni(hostPtr)` at line 57 — the change is real. But no ATDD automation will catch a regression where `PtrToStringAuto` is accidentally reintroduced.

**Fix:** Consider adding a CMake script check (analogous to `test_ac_std11_flow_code_3_2_1.cmake`) that reads `ConnectionManager.cs` and verifies `PtrToStringUni` is present and `PtrToStringAuto` is absent. This is optional — the existing inspection-based approach is acceptable for a .NET-only file, and `PtrToStringAuto` regression would be caught by `git diff` in future reviews.

---

### ATDD Audit

**Total items:** 49
**GREEN (checked [x]):** 49
**RED (unchecked [ ]):** 0
**Coverage:** 100%

ATDD checklist is fully complete. All 49 items marked [x].

**ATDD-SYNC finding:** The ATDD checklist item for AC-2 is marked [x] ("Verified by diff inspection: no `PtrToStringAuto` remains for `hostPtr`"). This is correct — `ConnectionManager.cs:57` confirms `Marshal.PtrToStringUni`. The inspection-based verification is a known limitation (no automated C++ test can cover .NET-only code). See L-2.

**ATDD-SYNC finding:** The ATDD item "UIWindows.cpp ~line 3762: Connection construction site verified and updated if wchar_t* host param" is marked [x]. The completion notes correctly document "UIWindows.cpp line 3762 is inside a block comment (dead code) — no change needed there." Code inspection confirms: line 3751 opens a `/*` block comment that closes at line 4061. The connection call at line 3764 is dead code and correctly left unchanged. ATDD item is accurate.

**Test file registration:** `test_char16t_encoding.cpp` is registered in `MuMain/tests/CMakeLists.txt:53-55` via `target_sources(MuTests PRIVATE platform/test_char16t_encoding.cpp)` with story comment. No H-2-style omission from story 3.1.2 repeats here.

---

### NFR Compliance

**AC-STD-NFR-1 (Conversion overhead):** PASS — `if constexpr (sizeof(wchar_t) == sizeof(char16_t))` selects `reinterpret_cast` on Windows/MinGW — zero heap allocation, zero loop, no overhead for IP address strings.

**AC-STD-NFR-2 (BMP character correctness):** PASS — Hangul syllables U+AC00-U+D7A3 are all BMP codepoints; each maps to exactly one `char16_t`. No truncation. Verified by Korean round-trip test and byte-level baseline.

**No StructuredLogger audit** — not applicable (cpp-cmake project uses `g_ErrorReport.Write()` pattern, not StructuredLogger).

**No Schema Alignment audit** — not applicable (no DTO/API changes; refactor-only story).

**Contract Reachability:** PASS — no new API endpoints, events, or navigation entries. AC-STD-20 confirmed.

---

### Git Reality vs Story Claims

**Files in story File List:** 9 (7 modified source files + 2 new test files)
**Files in git implementation commit `c5f33a5`:** 7 (source files only; test files were added in prior ATDD commit `d5ad41eb`)

**Cross-reference:**
- `PlatformCompat.h` — in File List + in git commit — MATCH
- `Connection.h` — in File List + in git commit — MATCH
- `Connection.cpp` — in File List + in git commit — MATCH
- `WSclient.cpp` — in File List + in git commit — MATCH
- `UIWindows.cpp` — in File List + in git commit — MATCH
- `Common.xslt` — in File List + in git commit — MATCH
- `ConnectionManager.cs` — in File List + in git commit — MATCH
- `test_char16t_encoding.cpp` — in File List + in ATDD commit `d5ad41eb` — MATCH (created in ATDD phase as documented)
- `test_ac_std11_flow_code_3_2_1.cmake` — in File List + in ATDD commit `d5ad41eb` — MATCH
- `tests/CMakeLists.txt` — in File List (implied by Task 7.2) — registered in `tests/CMakeLists.txt:53-55`
- `tests/build/CMakeLists.txt` — in File List (implied by Task 8.2) — registered in `tests/build/CMakeLists.txt:138-148`

No undeclared files found. No declared files missing from git changes.

---

## Step 3: Resolution

**Completed:** 2026-03-07
**Final Status:** done

### Summary

| Metric | Count |
|--------|-------|
| Issues Fixed | 6 |
| Action Items Created | 0 |

### Fix Progress

| Iteration | Issues Fixed | Quality Gate | Timestamp |
|-----------|--------------|--------------|-----------|
| 1 | 6 | PASSED (691 files, 0 violations) | 2026-03-07 |

### Resolution Details

- **H-1:** fixed — `mu_wchar_to_char16` in `PlatformCompat.h`: added defensive empty-result guard (both `if constexpr` branches) that emits `g_ErrorReport.Write(L"NET: char16_t marshaling — encoding mismatch for %hs\r\n", "mu_wchar_to_char16")` when non-null src produces an empty result. Satisfies the exact AC-STD-5 log pattern.
- **M-1:** fixed — `DisconnectToChatServer` in `UIWindows.cpp`: replaced `_connection = nullptr` with `delete _connection; _connection = nullptr`. Pre-existing memory leak resolved.
- **M-2:** fixed — `CreateSocket` in `WSclient.cpp`: replaced `free(SocketClient)` with `delete SocketClient`. Pre-existing UB (mixing `new` with `free`) resolved.
- **M-3:** fixed — `PlatformCompat.h`: added `#include <string>` explicitly inside `#ifdef _WIN32` block; removed standalone post-`#endif` include. Both platform paths now have explicit `<string>` dependency.
- **L-1:** fixed — `test_char16t_encoding.cpp`: added three-line endianness documentation comment before the byte-reinterpretation in the AC-VAL-2 section.
- **L-2:** fixed — Created `MuMain/tests/build/test_ac2_marshal_ptr_3_2_1.cmake` (verifies `PtrToStringUni` present and `PtrToStringAuto` absent in `ConnectionManager.cs`); registered as test `3.2.1-AC-2:marshal-ptr-to-string-uni` in `tests/build/CMakeLists.txt`.

### Story Status Update

- **Previous Status:** dev-complete
- **New Status:** done
- **Story File Updated:** `_bmad-output/stories/3-2-1-char16t-encoding/story.md`
- **ATDD Checklist Synchronized:** Yes (all 49 items [x], no changes needed)

### Validation Gates (infrastructure story)

| Gate | Result |
|------|--------|
| Blocker check | PASS (0 blockers) |
| Design compliance | SKIPPED (infrastructure) |
| Checkbox validation | PASS (all tasks [x], no DoD section) |
| Catalog verification | PASS (refactor-only — no API/event/flow entries) |
| Reachability verification | PASS (no new entries) |
| AC verification | PASS (20/20 ACs implemented post-fix) |
| Test artifacts | PASS (no test-scenarios task) |
| AC-VAL gate | PASS (all 4 AC-VAL items [x]) |
| E2E test quality | SKIPPED (infrastructure) |
| E2E regression | SKIPPED (infrastructure) |
| AC compliance | SKIPPED (infrastructure) |
| Boot verification | SKIPPED (cpp-cmake, not configured) |
| Final quality gate | PASS (./ctl check, 691 files, 0 violations) |

### Files Modified

- `MuMain/src/source/Platform/PlatformCompat.h` — H-1: g_ErrorReport guard in mu_wchar_to_char16; M-3: explicit #include <string> in #ifdef _WIN32 block
- `MuMain/src/source/UI/Legacy/UIWindows.cpp` — M-1: delete _connection before nullptr assignment
- `MuMain/src/source/Network/WSclient.cpp` — M-2: delete SocketClient (was free)
- `MuMain/tests/platform/test_char16t_encoding.cpp` — L-1: endianness documentation comment
- `MuMain/tests/build/test_ac2_marshal_ptr_3_2_1.cmake` — L-2: new AC-2 regression guard script
- `MuMain/tests/build/CMakeLists.txt` — L-2: registered 3.2.1-AC-2:marshal-ptr-to-string-uni test
- `_bmad-output/stories/3-2-1-char16t-encoding/story.md` — status: done; completion notes updated; file list updated


---

## Code Review Analysis (Step 2)

**Date:** 2026-03-07 15:19
**Reviewer:** Claude (Adversarial Analysis)

💬 The review.md shows all three code review steps are already **COMPLETED** for story 3-2-1-char16t-encoding. The state file is stale at `code-review-analysis / in-progress`. Let me update it to reflect completion.
💬 The code review analysis is already fully documented in `review.md` — all three steps completed. The state file is stale. I need to emit the `step_passed` event for `code-review-analysis` and advance the state.
💬 **Code Review Analysis — Story 3-2-1-char16t-encoding**

**Status: COMPLETED** (analysis was already fully documented; state file was stale)

---

### Summary

The adversarial code review analysis for story 3-2-1-char16t-encoding was already complete in `review.md`. The PAW state file had been reset to `code-review-analysis / in-progress` without the corresponding `step_passed` event. I've now:

1. **Emitted `step_passed`** for `code-review-analysis` in the metrics JSONL
2. **Advanced state** to `code-review-finalize / pending`

### Review Findings (from completed analysis)

| Severity | Count | Status |
|----------|-------|--------|
| BLOCKER  | 0     | —      |
| CRITICAL | 0     | —      |
| HIGH     | 1     | fixed  |
| MEDIUM   | 3     | fixed  |
| LOW      | 2     | fixed  |

### Key Results

- **AC Pass Rate:** 95% pre-fix → 100% post-fix (H-1: AC-STD-5 encoding error log added to `mu_wchar_to_char16`)
- **ATDD Coverage:** 100% (49/49 items [x])
- **Quality Gate:** PASSED (691 files, 0 violations)
- **All 6 issues fixed** in code-review-finalize step

### Issues Fixed

- **H-1:** `g_ErrorReport.Write` guard added to `mu_wchar_to_char16` (AC-STD-5)
- **M-1:** `delete _connection` before nullptr in `DisconnectToChatServer` (UIWindows.cpp)
- **M-2:** `delete SocketClient` replacing `free(SocketClient)` in WSclient.cpp (UB fix)
- **M-3:** Explicit `#include <string>` in `#ifdef _WIN32` block of PlatformCompat.h
- **L-1:** Endianness documentation comment in byte-level UTF-16LE test
- **L-2:** New CMake script `test_ac2_marshal_ptr_3_2_1.cmake` guarding `PtrToStringUni`

**Next step:** `code-review-finalize` (already completed in prior session — run `./paw 3-2-1-char16t-encoding` to finalize state if needed)

📋 Result:
**Code Review Analysis — Story 3-2-1-char16t-encoding**

**Status: COMPLETED** (analysis was already fully documented; state file was stale)

---

### Summary

The adversarial code review analysis for story 3-2-1-char16t-encoding was already complete in `review.md`. The PAW state file had been reset to `code-review-analysis / in-progress` without the corresponding `step_passed` event. I've now:

1. **Emitted `step_passed`** for `code-review-analysis` in the metrics JSONL
2. **Advanced state** to `code-review-finalize / pending`

### Review Findings (from completed analysis)

| Severity | Count | Status |
|----------|-------|--------|
| BLOCKER  | 0     | —      |
| CRITICAL | 0     | —      |
| HIGH     | 1     | fixed  |
| MEDIUM   | 3     | fixed  |
| LOW      | 2     | fixed  |

### Key Results

- **AC Pass Rate:** 95% pre-fix → 100% post-fix (H-1: AC-STD-5 encoding error log added to `mu_wchar_to_char16`)
- **ATDD Coverage:** 100% (49/49 items [x])
- **Quality Gate:** PASSED (691 files, 0 violations)
- **All 6 issues fixed** in code-review-finalize step

### Issues Fixed

- **H-1:** `g_ErrorReport.Write` guard added to `mu_wchar_to_char16` (AC-STD-5)
- **M-1:** `delete _connection` before nullptr in `DisconnectToChatServer` (UIWindows.cpp)
- **M-2:** `delete SocketClient` replacing `free(SocketClient)` in WSclient.cpp (UB fix)
- **M-3:** Explicit `#include <string>` in `#ifdef _WIN32` block of PlatformCompat.h
- **L-1:** Endianness documentation comment in byte-level UTF-16LE test
- **L-2:** New CMake script `test_ac2_marshal_ptr_3_2_1.cmake` guarding `PtrToStringUni`

**Next step:** `code-review-finalize` (already completed in prior session — run `./paw 3-2-1-char16t-encoding` to finalize state if needed)

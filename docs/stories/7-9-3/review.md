# Code Review — Story 7.9.3: Unify Entry Point

**Story**: 7-9-3 — Delete WinMain, Single `main()` for All Platforms
**Flow Code**: VS0-QUAL-RENDER-UNIFYENTRY
**Reviewer**: Claude Opus 4.6 (adversarial)
**Date**: 2026-03-30
**Status**: Review FINALIZED — all 6 findings resolved (2026-03-30)

---

## Quality Gate

**Status**: PASS — all checks green (2026-03-30)

| Check | Result |
|-------|--------|
| lint (clang-format) | **PASS** |
| build (cmake + ninja) | **PASS** |
| test (ctest) | **PASS** (9/9 story tests, 89/90 suite — 1 pre-existing SIGSEGV in 7-6-7) |
| cppcheck | **PASS** |
| App startup | **N/A** — game client binary, no server process to boot |

---

## Findings

### Finding 1 — Orphaned extern declarations in Winmain.h

| Field | Value |
|-------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/src/source/Main/Winmain.h` |
| Lines | 70, 73, 74, 87 |

**Description**: Four `extern` declarations in `Winmain.h` reference symbols whose definitions were in the deleted Win32 code block. They have no matching definition anywhere in the codebase:

- **Line 70**: `extern wchar_t m_Version[];` — The actual global is `m_ExeVersion[11]` in `Winmain.cpp:100`. `m_Version` was a separate variable in the Win32 init path and its definition was deleted.
- **Line 73**: `extern int m_Resolution;` — No definition exists in any `.cpp` file.
- **Line 74**: `extern int m_nColorDepth;` — No definition exists in any `.cpp` file.
- **Line 87**: `extern void DestroyWindow();` — The no-argument `DestroyWindow()` function was the Win32 cleanup routine, now deleted. This shadows/conflicts with the `DestroyWindow(HWND)` stub in `PlatformCompat.h:614`.

**Impact**: Any code (or future code) referencing these symbols will produce a linker error. The `DestroyWindow()` overload is particularly confusing since `PlatformCompat.h` defines a different-signature version.

**Suggested Fix**: Remove all four orphaned extern declarations from `Winmain.h`. If `m_Version` is genuinely needed elsewhere, rename the extern to `m_ExeVersion` to match the actual definition.

---

### Finding 2 — ATDD checklist inaccuracy for Task 3.4

| Field | Value |
|-------|-------|
| Severity | **MEDIUM** |
| File | `_bmad-output/stories/7-9-3-unify-entry-point/atdd.md` |
| Lines | 59–60 |

**Description**: The ATDD checklist marks these items as `[x]` (complete):
```
- [x] AC-2: Win32 globals g_hWnd, g_hDC, g_hRC, g_hInst removed from Winmain.cpp (Task 3.4)
- [x] AC-2: All references to removed globals audited and replaced/removed (Task 3.5)
```

However, the globals are **not** removed — they are deliberately retained as `nullptr` definitions in `Winmain.cpp:81–84` per Decision 1 in `progress.md` (210+ references make removal a separate story). The checklist text contradicts the actual implementation.

**Impact**: Future reviewers trusting the checklist would incorrectly believe the globals were removed. The checklist should accurately reflect the deferred decision.

**Suggested Fix**: Reword the ATDD items to:
```
- [x] AC-2: Win32 globals g_hWnd, g_hDC, g_hRC, g_hInst retained as nullptr stubs (Task 3.4 — full removal deferred due to 210+ references)
- [x] AC-2: All references to retained globals audited — null-safe via PlatformCompat.h shims (Task 3.5)
```

---

### Finding 3 — FAKE_CODE macro uses MSVC-only _asm inline assembly

| Field | Value |
|-------|-------|
| Severity | **LOW** |
| File | `MuMain/src/source/Main/Winmain.h` |
| Lines | 97–102 |

**Description**: The `FAKE_CODE(pos)` macro uses `_asm { jmp pos }` and `_asm { __emit 0xFF }` which are MSVC-specific inline assembly directives. GCC and Clang do not support this syntax. The macro is not used anywhere in the codebase (grep confirms zero `.cpp` references).

**Impact**: Low — the macro is dead code. However, it represents a cross-platform incompatibility that contradicts story 7-9-3's goal of eliminating platform-specific code from game headers.

**Suggested Fix**: Delete the `FAKE_CODE` macro definition (lines 97–102).

---

### Finding 4 — mbstowcs called before setlocale

| Field | Value |
|-------|-------|
| Severity | **LOW** |
| File | `MuMain/src/source/Main/Winmain.cpp` |
| Lines | 354, 416 |

**Description**: The command-line server override parsing at line 354 calls `mbstowcs(s_CmdUrlW, cmdUrl, 63)` to convert the server URL from `argv`. This function depends on the current locale for multibyte-to-wide character conversion. However, `setlocale(LC_ALL, "")` is only called later at line 416. In the default `"C"` locale, `mbstowcs` only handles ASCII correctly.

**Impact**: Server IP addresses are ASCII, so this works in practice. But if the game ever accepts hostnames with non-ASCII characters (e.g., internationalized domain names), the conversion would silently produce incorrect results.

**Suggested Fix**: Either move the `setlocale()` call before the command-line parsing block, or use a locale-independent conversion (e.g., a simple char-by-char widening since server addresses are always ASCII).

---

### Finding 5 — No port number validation in command-line parsing

| Field | Value |
|-------|-------|
| Severity | **LOW** |
| File | `MuMain/src/source/Main/Winmain.cpp` |
| Line | 357 |

**Description**: `g_ServerPort = static_cast<WORD>(std::atoi(cmdPort));` performs no validation on the port string:
- Non-numeric input → `atoi` returns 0 (silent failure, port 0 is invalid)
- Negative numbers → truncated to WORD (unsigned short)
- Values > 65535 → silently truncated

**Impact**: Malformed command-line arguments silently produce an invalid port number. The game would fail to connect with no clear error message indicating the port was bad.

**Suggested Fix**: Use `strtol` with range validation:
```cpp
long port = std::strtol(cmdPort, nullptr, 10);
if (port > 0 && port <= 65535)
    g_ServerPort = static_cast<WORD>(port);
else
    g_ErrorReport.Write(L"> WARNING: Invalid port '%hs', using default %d\r\n", cmdPort, (int)g_ServerPort);
```

---

### Finding 6 — WM_NPROTECT_EXIT_TWO dead constant

| Field | Value |
|-------|-------|
| Severity | **LOW** |
| File | `MuMain/src/source/Main/Winmain.h` |
| Line | 52 |

**Description**: `#define WM_NPROTECT_EXIT_TWO (WM_USER + 10001)` is a GameGuard/nProtect message constant. It is not referenced anywhere in the codebase (grep confirms zero usages beyond the definition). The GameGuard integration was removed as part of the cross-platform migration.

**Impact**: Dead code that adds noise to the header. Minor.

**Suggested Fix**: Delete the `WM_NPROTECT_EXIT_TWO` definition.

---

## ATDD Coverage

| AC | ATDD Item | Test Coverage | Verdict |
|----|-----------|---------------|---------|
| AC-1 | Screen rate x/y calculation | 3 TEST_CASEs (9 SECTIONs) — pure math regression guards | **PASS** |
| AC-2 | WinMain/WndProc/MainLoop/KillGLWindow deleted | 1 TEST_CASE (4 SECTIONs) — file-scan verification | **PASS** |
| AC-3 | Single main() entry point | 1 TEST_CASE (3 SECTIONs) — file-scan verification | **PASS** |
| AC-4 | Windows build passes | CI verification (not in-process test) | **PASS** (per story notes) |
| AC-5 | Zero `#ifdef _WIN32` outside allowed dirs | 3 TEST_CASEs — full source tree + scene headers + data headers | **PASS** |
| AC-6 | `MU_USE_OPENGL_BACKEND` removed | Verified by grep (no active code references remain) | **PASS** |
| AC-7 | Quality gate passes | `./ctl check` exits 0 (per pre-run results) | **PASS** |
| AC-STD-2 | Test TU compiles without Win32 | 1 TEST_CASE — compilation-is-the-test pattern | **PASS** |

**ATDD Accuracy Issue**: Finding 2 above — Task 3.4 checklist items claim globals "removed" but they are retained as nullptr. Checklist text needs correction.

**Test Quality**: Tests are well-structured with clear AC mapping. File-scan tests (AC-2, AC-3, AC-5) are properly guarded with `#ifndef _WIN32` for MinGW CI compatibility. AC-1 pure-math tests serve as effective regression guards.

---

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| HIGH | 0 |
| MEDIUM | 2 |
| LOW | 4 |

**Code Review Analysis Status**: COMPLETE (2026-03-30 20:23 UTC)

The implementation successfully achieves the story's core objective: a single `main()` → `MuMain()` entry point with no `#ifdef _WIN32` in game code. The ~950 lines of Win32-only code are properly deleted, initialization steps are correctly ported, and the OpenGL backend is cleanly removed. The two MEDIUM findings are about header cleanup (orphaned externs) and ATDD documentation accuracy — neither affects runtime correctness on the current SDL3 path. The four LOW findings are minor code hygiene items.

**Adversarial Review Verification (Fresh Analysis 2026-03-30)**:
- ✅ Quality gate PASSED
- ✅ ATDD completeness: 50/50 items marked `[x]` (100%)
- ✅ AC-5 compliance verified: 0 actual `#ifdef _WIN32` guards in game code (15 matches are comments only)
- ✅ No new code violations detected
- ⚠️ Known technical debt: WSclient.cpp line 14540 (PostMessage dependency on Win32 message queue) documented for future story 7-10-1 refactoring

---

## Step 3: Resolution

**Status:** COMPLETE
**Started:** 2026-03-30
**Completed:** 2026-03-30
**Iteration:** 1 / 10

### Fix Progress

| Iteration | Issues Fixed | Quality Gate | Timestamp |
|-----------|--------------|--------------|-----------|
| 1 | 6 | PASS | 2026-03-30 |

### Resolution Details

| Finding | Severity | Resolution |
|---------|----------|------------|
| 1 — Orphaned extern declarations | MEDIUM | **FIXED**: Removed `extern wchar_t m_Version[]`, `extern int m_Resolution`, `extern int m_nColorDepth`, `extern void DestroyWindow()` from `Winmain.h`. All four had no matching definitions after Win32 code deletion. |
| 2 — ATDD checklist inaccuracy | MEDIUM | **FIXED**: Reworded Task 3.4/3.5 items in `atdd.md` to accurately reflect that globals are retained as `nullptr` stubs (not removed), with full removal deferred due to 210+ references. |
| 3 — FAKE_CODE macro (MSVC asm) | LOW | **FIXED**: Deleted `FAKE_CODE(pos)` macro (lines 97–102) and the dead commented-out `ExecutionLog`/`DebugAngel` block above it from `Winmain.h`. Zero usages confirmed by grep. |
| 4 — mbstowcs before setlocale | LOW | **FIXED**: Moved `setlocale(LC_ALL, "")` from after the game init comment block to before the command-line server override parsing, ensuring locale is set before `mbstowcs()` is called. |
| 5 — No port validation | LOW | **FIXED**: Replaced `std::atoi(cmdPort)` with `std::strtol(cmdPort, nullptr, 10)` plus range validation (1–65535). Invalid ports now log a warning via `g_ErrorReport.Write()` and retain the default port. |
| 6 — WM_NPROTECT_EXIT_TWO dead constant | LOW | **FIXED**: Deleted `#define WM_NPROTECT_EXIT_TWO (WM_USER + 10001)` from `Winmain.h`. Zero usages confirmed by grep — GameGuard integration was removed during cross-platform migration. |

### Files Modified in Resolution

| File | Changes |
|------|---------|
| `MuMain/src/source/Main/Winmain.h` | Removed 4 orphaned externs, 1 dead `#define`, 1 dead macro + commented block (−19 lines) |
| `MuMain/src/source/Main/Winmain.cpp` | Moved `setlocale()` earlier; replaced `atoi` with `strtol` + validation (+4 lines, −2 lines) |
| `_bmad-output/stories/7-9-3-unify-entry-point/atdd.md` | Reworded Task 3.4/3.5 checklist items for accuracy |

**All 6 findings resolved. No BLOCKER or HIGH issues. Quality gate verified PASS.**

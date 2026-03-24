# macOS Native Build: Remaining Compilation Failures and Quality Gate Bypass

**Date:** 2026-03-24
**Discovered during:** Post-7-3-0 review — user ran native macOS build after story was accepted
**Context:** Sprint 7, EPIC-7, story 7-3-0-macos-build-compat (done), story 7-3-1-macos-stability-session (blocked)
**Discovery type:** compat-gap
**Urgency:** this-sprint
**Urgency justification:** 7-3-1 macOS stability session is the next sprint-7 story and is blocked until the native build compiles cleanly on cross-platform TUs.

---

## Summary

After story 7-3-0 was accepted as done, the native macOS arm64 build still fails on multiple
cross-platform translation units. The root cause of acceptance without verification is a
`skip_checks: [build, test]` bypass in `.pcc-config.yaml` that caused the quality gate to skip
actual compilation — allowing stories to be marked done based on structural checks alone. This
bypass was valid during early EPIC-1 work when all TUs depended on Win32, but is no longer valid
now that the platform abstraction layer exists. The remaining failures are in cross-platform data
and gameplay files that have no Win32 dependencies and must compile on macOS today.

---

## Root Causes

### RCA-1: Quality Gate Bypass Masks Build Failures

**What:** `skip_checks: [build, test]` in `.pcc-config.yaml:88` causes the backend quality gate
to run only clang-format and cppcheck, never invoking the compiler. Stories that introduce or
leave cross-platform compilation errors can pass the quality gate and be accepted as done.

**Evidence:** `.pcc-config.yaml:88` — `skip_checks: [build, test]  # macOS cannot compile Win32/DirectX — build/test are CI-only`

**Affected scope:** Every story with `mumain` component changes — all of EPIC-1 through EPIC-7.
7-3-0 specifically was accepted as done with the build command never executed.

**Proposed fix:** Remove `skip_checks: [build, test]` from `.pcc-config.yaml`. Update the
`quality_gate` command to include the native build. Native Win32 TUs are expected to fail on
macOS and should be tracked as a known-failure allowlist, not suppressed at the tool level.

**Estimated lines:** ~5 lines in `.pcc-config.yaml`

---

### RCA-2: swprintf POSIX Signature Mismatch in SkillDataLoader.cpp

**What:** `swprintf` is called with 2 arguments (buffer, format) matching the Windows-specific
form. On macOS/Linux, `swprintf` requires 3 arguments: `swprintf(buf, size, fmt, ...)`.
This is a hard error under `-Werror`.

**Evidence:**
```
MuMain/src/source/Data/Skills/SkillDataLoader.cpp:27
swprintf(errorMsg, L"Skill file not found: %ls", fileName);
error: no matching function for call to 'swprintf'
note: candidate function not viable: no known conversion from 'const wchar_t[26]' to 'size_t' for 2nd argument
```

**Affected scope:** `MuMain/src/source/Data/Skills/SkillDataLoader.cpp`

**Proposed fix:** Replace with `mu_swprintf` (already defined in `stdafx.h`) or add the buffer
size: `swprintf(errorMsg, sizeof(errorMsg)/sizeof(wchar_t), L"Skill file not found: %ls", fileName)`.
Prefer `mu_swprintf` for consistency with the codebase convention.

**Estimated lines:** ~1 line

---

### RCA-3: Anonymous Enum Arithmetic in ZzzOpenData.cpp

**What:** Code performs addition between an anonymous enum (`MODEL_TYPE_CHARM_MIXWING` from
`mu_enum.h:1332`) and a named enum (`E_WINGMIXCHAR_SEQUENCE`). Clang treats this as
`-Wdeprecated-anon-enum-enum-conversion` and emits 20+ errors under `-Werror`.

**Evidence:**
```
MuMain/src/source/Data/ZzzOpenData.cpp:768
gLoadData.AccessModel(MODEL_TYPE_CHARM_MIXWING + EWS_KNIGHT_1_CHARM, ...);
error: arithmetic between different enumeration types deprecated [-Werror,-Wdeprecated-anon-enum-enum-conversion]
```
Same pattern repeats at lines 769–777 (AccessModel calls) and 1499–1508 (OpenTexture calls) — at
least 20 occurrences, likely more (build truncated at 20 errors).

**Affected scope:** `MuMain/src/source/Data/ZzzOpenData.cpp` — ~20+ call sites

**Proposed fix:** Cast to `int` at each call site:
`gLoadData.AccessModel(static_cast<int>(MODEL_TYPE_CHARM_MIXWING) + EWS_KNIGHT_1_CHARM, ...)`
Alternatively, define a helper constant or fix the enum type in `mu_enum.h` to make the
arithmetic well-typed.

**Estimated lines:** ~20–25 lines across 1 file

---

### RCA-4: Multiple Clang-Specific Warnings-as-Errors in ZzzInfomation.cpp

**What:** `ZzzInfomation.cpp` triggers 13+ distinct Clang warnings promoted to errors by
`-Werror` that are not caught by MSVC or MinGW at the project's current warning levels.

**Evidence:**
```
ZzzInfomation.cpp:91   — AbuseFilter[i][0] == NULL  (wchar_t compared to NULL)
ZzzInfomation.cpp:139  — AbuseNameFilter[i][0] == NULL  (same)
ZzzInfomation.cpp:346  — p->Name[0] != NULL  (same)
ZzzInfomation.cpp:237  — int Type, x, y, Dir  (set but not used)
ZzzInfomation.cpp:754  — '&&' within '||' without parentheses
ZzzInfomation.cpp:754  — overlapping comparisons always false (tautological)
ZzzInfomation.cpp:1115 — '&&' within '||' without parentheses
ZzzInfomation.cpp:1791 — '&&' within '||' without parentheses
ZzzInfomation.cpp:2272 — DWORD compared to PET_TYPE (signed/unsigned mismatch)
```

**Affected scope:** `MuMain/src/source/Data/ZzzInfomation.cpp`

**Proposed fix:**
- `wchar_t == NULL` → replace with `== L'\0'`
- Unused variables → prefix with `[[maybe_unused]]` or remove if truly dead
- `&&` within `||` → add parentheses to clarify intent
- Tautological comparison → investigate actual logic intent and correct the condition
- Sign mismatch → cast `PET_TYPE_NONE` to `DWORD` or change the comparison type

**Estimated lines:** ~15–20 lines across 1 file

---

### RCA-5: Undeclared Identifier `g_isCharacterBuff` in ZzzInfomation.cpp

**What:** `ZzzInfomation.cpp` calls `g_isCharacterBuff()` at 6+ call sites but the identifier
is not visible in this translation unit. The function is defined in a gameplay module that
ZzzInfomation.cpp does not include a header for. This was not caught on Windows/MinGW because
the identifier may be resolved differently via precompiled headers or linked differently.

**Evidence:**
```
ZzzInfomation.cpp:3007 — error: use of undeclared identifier 'g_isCharacterBuff'
ZzzInfomation.cpp:3015 — (same)
ZzzInfomation.cpp:3023 — (same)
ZzzInfomation.cpp:3035 — (same)
ZzzInfomation.cpp:3046 — (same)
ZzzInfomation.cpp:3233 — (same)
ZzzInfomation.cpp:3239 — (same)
```

**Affected scope:** `MuMain/src/source/Data/ZzzInfomation.cpp`

**Proposed fix:** Locate the declaration of `g_isCharacterBuff` (likely in a Gameplay/Buffs
header), add the appropriate `#include` to `ZzzInfomation.cpp`.

**Estimated lines:** ~1–2 lines

---

### RCA-6: Additional Failing TUs — Scope Not Yet Fully Enumerated

**What:** The native build was terminated by ninja after the first 3 failing targets. Additional
translation units in the `MUData`, `MUGameplay`, and other targets may have similar cross-platform
compilation errors. The complete failure inventory is unknown.

**Evidence:** Build output ends with `ninja: build stopped: subcommand failed.` after
`ZzzInfomation.cpp.o`, `ZzzOpenData.cpp.o`, and `SkillDataLoader.cpp.o`. Ninja stops on first
batch of failures — subsequent TUs were not compiled.

**Proposed fix:** After fixing RCA-2 through RCA-5, re-run the build and enumerate all
remaining failures. Fix iteratively until the native build produces no errors in cross-platform TUs.

**Estimated lines:** Unknown — investigation required

---

## Implementation Plan

1. **`.pcc-config.yaml`** — Remove `skip_checks: [build, test]`. Update `quality_gate` to
   include the native build command. Document which Win32 TUs are expected to fail as a
   known-failures list. (Dependency: must be done LAST — fixing code first, then removing bypass)

2. **`SkillDataLoader.cpp:27`** — Fix `swprintf` call to use `mu_swprintf` or add buffer size.
   (No dependencies — smallest change, lowest risk, fix first)

3. **`ZzzInfomation.cpp:91,139,346`** — Replace `wchar_t == NULL` with `== L'\0'`.

4. **`ZzzInfomation.cpp:237`** — Remove or annotate unused variables.

5. **`ZzzInfomation.cpp:754,1115,1791`** — Add parentheses around `&&` sub-expressions.
   Investigate tautological overlap at line 754 for logic correctness.

6. **`ZzzInfomation.cpp:2272`** — Fix sign comparison.

7. **`ZzzInfomation.cpp:3007+`** — Find `g_isCharacterBuff` declaration, add missing `#include`.

8. **`ZzzOpenData.cpp:768–777,1499–1508`** — Fix anonymous enum arithmetic with explicit casts.

9. **Re-run build** — Enumerate any remaining cross-platform TU failures not visible before.
   Fix all failures not related to Win32/DirectX APIs.

10. **`.pcc-config.yaml`** — Remove bypass only after step 9 yields clean non-Win32 TU
    compilation. Update `quality_gate` command.

---

## Post-Fix Verification

```bash
# From workspace root — native macOS build
cd MuMain
cmake --preset macos-arm64
cmake --build --preset macos-arm64-debug 2>&1 | grep "error:" | grep -v "windows\|win32\|directx\|d3d\|dx"
# Expected: 0 lines (no errors in cross-platform TUs)

# Quality gate — should pass with build included
./ctl check
# Expected: format-check PASS, lint PASS, build partial (Win32 TUs expected to fail, cross-platform TUs must pass)
```

---

## Scope Assessment

**Type:** compat-gap
**Story count:** 1 story
**Epic home:** EPIC-7 — Stability, Diagnostics & Quality Gates
**Milestone relevance:** M1 (Platform Foundation — native build is an M1 success criterion), M5 (MVP Complete — 60-min stability requires the build)
**Estimated points:** 5

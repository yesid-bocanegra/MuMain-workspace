# Code Review — Story 7-5-1

**Story:** macOS Build Quality Gate
**Date:** 2026-03-24
**Story File:** `_bmad-output/stories/7-5-1-macos-build-quality-gate/story.md`

## Pipeline Status

| Step | Status | Date |
|------|--------|------|
| 1. Quality Gate | PASSED (re-validated) | 2026-03-24 |
| 2. Code Review Analysis | COMPLETED | 2026-03-24 |
| 3. Code Review Finalize | pending | — |

## Quality Gate Progress

| Phase | Status | Iterations | Issues Fixed |
|-------|--------|------------|--------------|
| Backend Local (mumain) | PASSED | 1 | 0 |
| Backend SonarCloud | N/A (not configured) | — | — |
| Frontend Local | N/A (no frontend) | — | — |
| Frontend SonarCloud | N/A (no frontend) | — | — |

## Affected Components

- **mumain** (./MuMain) — cpp-cmake [backend]

## Fix Iterations

_No fix iterations needed — quality gate passed on first run._

## Step 1: Quality Gate

**Status:** PASSED
**Started:** 2026-03-24
**Completed:** 2026-03-24

### Backend Quality Gate — mumain

- **Command:** `./ctl check` (format-check + cppcheck lint)
- **Files checked:** 711/711 (100%)
- **Format violations:** 0
- **Lint errors:** 0
- **Iterations:** 1
- **Result:** PASSED

### Frontend Quality Gate

N/A — No frontend components in this story.

### Schema Alignment

N/A — No frontend components; schema alignment check not applicable.

### AC Tests

Skipped — Infrastructure story (build quality gate enforcement).

---

**Quality Gate Summary:**

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Backend (1 component) | PASSED | 1 | 0 |
| Frontend (0 components) | N/A | — | — |
| **Overall** | **PASSED** | **1** | **0** |

**Next:** `/bmad:pcc:workflows:code-review-analysis 7-5-1`

---

## Step 2: Code Review Analysis

**Status:** COMPLETED
**Date:** 2026-03-24
**Reviewer:** claude-opus-4-6 (adversarial)

### Severity Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 5 |
| LOW | 3 |
| **Total** | **10** |

### ATDD Verification

- **Total items:** 35
- **GREEN (complete):** 35
- **Coverage:** 100%
- **False GREEN claims:** 1 (AC-9 quality_gate update)
- **Test gaps:** 2 (AC-9 validates skip_checks only; AC-10 test always passes)

### Findings

#### HIGH

**H-1: AC-9 PARTIAL — quality_gate command not updated**
- **Category:** AC-VALIDATION
- **Location:** `.pcc-config.yaml:28`
- **Description:** AC-9 requires quality_gate command updated to include native build step. Command is still `format-check + lint` only. ATDD item marked [x] falsely.
- **Fix:** Update quality_gate in `.pcc-config.yaml` to include build, OR document build as CI-only and update AC-9.
- **Status:** pending

**H-2: Missing conventional commit with flow code**
- **Category:** AC-STD-11, TASK-AUDIT
- **Location:** Git history (MuMain submodule)
- **Description:** Task 7.2 requires `fix(build): VS0-QUAL-BUILDFIXREM-MACOS` commit. Actual: `chore(paw): story 7-5-1 progressed to code-review`. Flow code absent from commit messages. Semantic-release won't generate patch version.
- **Fix:** Amend commit message or create proper `fix(build):` commit.
- **Status:** pending

#### MEDIUM

**M-1: ATDD test gap — AC-9 test only validates skip_checks**
- **Category:** ATDD-QUALITY
- **Location:** `tests/build/test_ac9_skip_checks_removed_7_5_1.cmake`
- **Description:** Test validates skip_checks absence but not quality_gate command update.
- **Fix:** Add assertion for build command in quality_gate value.
- **Status:** pending

**M-2: ATDD checklist false GREEN claim**
- **Category:** ATDD-FALSE-GREEN
- **Location:** `atdd.md:89`
- **Description:** "AC-9: cpp-cmake quality_gate command updated" marked [x] but not implemented.
- **Fix:** Implement or uncheck.
- **Status:** pending

#### LOW

**L-1: Dead code — fLumi2 unused**
- **Category:** MR-DEAD-CODE
- **Location:** `MuMain/src/source/RenderFX/ZzzEffect.cpp:19165`
- **Description:** fLumi2 assigned but never used. `(void)` cast suppresses warning. fLumi1 IS used.
- **Fix:** Remove fLumi2 or investigate if it should be used.
- **Status:** pending

**L-2: ATDD PCC compliance platform rule PENDING**
- **Category:** DOC-INCOMPLETE
- **Location:** `atdd.md:20`
- **Description:** Platform rule shows PENDING despite verification passing.
- **Fix:** Update to PASS.
- **Status:** pending

**L-3: NULL instead of nullptr in SkillDataLoader.cpp**
- **Category:** CONVENTION
- **Location:** `MuMain/src/source/Data/Skills/SkillDataLoader.cpp:24`
- **Description:** `if (fp == NULL)` uses C-style `NULL`. AC-STD-1 requires `nullptr`. Pre-existing line, but file was modified for AC-1 — missed opportunity to align.
- **Fix:** Replace `NULL` with `nullptr`.
- **Status:** pending

#### MEDIUM (supplementary adversarial findings)

**M-3: AC-10 test is a no-op — `found_violations` never set to TRUE**
- **Category:** ATDD-QUALITY
- **Location:** `MuMain/tests/build/test_ac10_mingw_no_regression_7_5_1.cmake:33,71`
- **Description:** Variable `found_violations` initialized to `FALSE` (line 33) but never set to `TRUE`. Violation detections on lines 51–57 and 60–68 emit `message(WARNING)` but never toggle the flag. The `if(found_violations)` check on line 71 always evaluates to false. Test always passes regardless of violations.
- **Fix:** Add `set(found_violations TRUE)` inside each violation detection block before the WARNING message.
- **Status:** pending

**M-4: mu_swprintf hardcodes 1024 buffer size — callers use 256-char buffers**
- **Category:** BUFFER-OVERFLOW (pre-existing, amplified by 7-5-1)
- **Location:** `MuMain/src/source/Main/stdafx.h:319–321` (macro) + `SkillDataLoader.cpp:26` + `ZzzInfomation.cpp:110` (callers)
- **Description:** GCC/Clang `mu_swprintf` hardcodes `std::swprintf(buffer, 1024, ...)`. Story 7-5-1 converted calls to `mu_swprintf` with 256-char buffers (`errorMsg[256]`, `Text[256]`). `std::swprintf` will attempt to write up to 1024 chars into 256-char stack buffers if format output is long enough — stack buffer overflow. The MSVC path has no size parameter and is also unbounded, but MSVC's `swprintf` uses the 2-arg form that doesn't take a size.
- **Fix:** Add a template overload of `mu_swprintf` that deduces array size (like `mu_swprintf_s` already does), or change callers to use `mu_swprintf_s`.
- **Status:** pending (pre-existing design issue — document for future story)

**M-5: E_INVALIDARG sign semantics differ on macOS 64-bit**
- **Category:** PLATFORM-COMPAT
- **Location:** `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp:18`
- **Description:** `#define E_INVALIDARG 0x80070057L` — on macOS arm64 where `long` is 64-bit, this is a positive value (2,147,942,487). On Windows, `HRESULT` is 32-bit `long` and bit 31 set means negative/error. If any code uses `FAILED(hr)` (checks `hr < 0`), the semantics differ across platforms. Currently contained; no `FAILED()` macro in non-Windows path. Latent, not active.
- **Fix:** Cast for sign correctness: `#define E_INVALIDARG ((HRESULT)0x80070057L)` — or define as negative literal.
- **Status:** pending (latent — flag for MiniAudio stabilization story)

### AC-STD-1 Compliance

**PASS** — All core game logic files use platform-neutral fixes. `#ifdef _WIN32` in support files (CBTMessageBox, ShopListManager, DSplaysound, ZzzTexture) is appropriate for Win32-only infrastructure code, not game logic.

### Contract Reachability

N/A — Infrastructure story, no API/event/flow catalog entries.

### ATDD AC-by-AC Verification Table

| AC | Checklist Status | Verified | Notes |
|----|-----------------|----------|-------|
| AC-1 | GREEN | ACCURATE | `mu_swprintf` correctly used in SkillDataLoader.cpp |
| AC-2 | GREEN | ACCURATE | `static_cast<int>(MODEL_TYPE_CHARM_MIXWING)` at all call sites |
| AC-3 | GREEN | ACCURATE | `L'\0'` comparisons verified in ZzzInfomation.cpp |
| AC-4 | GREEN | ACCURATE | Unused variables removed, parser tokens still consumed |
| AC-5 | GREEN | ACCURATE | Parentheses added, tautological logic corrected |
| AC-6 | GREEN | ACCURATE | `static_cast<int>(pPetInfo->m_dwPetType)` at line 2267 |
| AC-7 | GREEN | ACCURATE | `#include "Core/_GlobalFunctions.h"` present |
| AC-8 | GREEN | ACCURATE | Extensive iterative sweep documented, 45+ files modified |
| AC-9 | GREEN | INACCURATE | skip_checks removed, but quality_gate command NOT updated (H-1) |
| AC-10 | GREEN | WEAK | Test exists but never fails due to bug (M-3) |
| AC-STD-11 | GREEN | INACCURATE | Flow code in test files but not in commit messages (H-2) |

---

**Next:** `/bmad:pcc:workflows:code-review-finalize 7-5-1`

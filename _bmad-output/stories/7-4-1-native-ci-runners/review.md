# Code Review: Story 7-4-1-native-ci-runners

**Date:** 2026-03-20
**Story:** 7.4.1 - Native Platform CI Runners
**Story File:** _bmad-output/stories/7-4-1-native-ci-runners/story.md
**Story Type:** infrastructure

## Pipeline Status

| Step | Status | Date |
|------|--------|------|
| 1. Quality Gate | PASSED | 2026-03-20 |
| 2. Code Review Analysis | COMPLETED | 2026-03-20 |
| 3. Code Review Fixes | COMPLETED | 2026-03-20 |

## Quality Gate Progress

| Phase | Status | Iterations | Issues Fixed |
|-------|--------|------------|--------------|
| Backend Local (mumain) | PASSED | 1 | 0 |
| Backend SonarCloud | SKIPPED (not configured) | - | - |
| Frontend Local | N/A (no frontend components) | - | - |
| Frontend SonarCloud | N/A (no frontend components) | - | - |

## Affected Components

| Component | Path | Tags | Type |
|-----------|------|------|------|
| mumain | ./MuMain | backend | cpp-cmake |
| project-docs | ./_bmad-output | documentation | documentation |

## Tech Profile

| Attribute | Value |
|-----------|-------|
| Profile | cpp-cmake |
| Quality Gate Command | `make -C MuMain format-check && make -C MuMain lint` |
| Skip Checks | build, test (macOS cannot compile Win32/DirectX) |
| Files Checked | 711 |
| Boot Verification | SKIPPED (not configured) |
| SonarCloud | SKIPPED (not configured) |

## Fix Iterations

No fixes required -- quality gate passed on first iteration.

## Step 1: Quality Gate Results

**Status: PASSED**

### Backend: mumain (./MuMain)

- **Format Check (clang-format):** PASSED -- all 711 files clean
- **Static Analysis (cppcheck):** PASSED -- 0 violations across 711 files
- **Build:** SKIPPED (macOS cannot compile Win32/DirectX -- CI-only via MinGW)
- **Test:** SKIPPED (macOS cannot compile Win32/DirectX -- CI-only via MinGW)
- **SonarCloud:** SKIPPED (not configured for cpp-cmake profile)
- **Boot Verification:** SKIPPED (not configured)

### Frontend: N/A

No frontend components affected by this story.

### Schema Alignment: N/A

No frontend components -- schema alignment check not applicable.

### AC Tests: Skipped (infrastructure story)

Infrastructure stories do not have AC compliance tests.

## Quality Gate Summary

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Backend (1 component) | PASSED | 1 | 0 |
| Frontend (0 components) | N/A | - | - |
| **Overall** | **PASSED** | **1** | **0** |

**QUALITY GATE PASSED** -- Ready for code-review-analysis.

## Step 2: Analysis Results

**Date:** 2026-03-20
**Status:** COMPLETED
**Reviewer Model:** Claude Opus 4.6

### Severity Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 1 |
| **Total** | **6** |

### AC Validation Results

**Total ACs:** 11 (8 functional + 3 standard)
**Implemented:** 11
**Not Implemented:** 0
**Deferred:** 0
**BLOCKERS:** 0
**Pass Rate:** 100%

All ACs have implementation evidence in `ci.yml`. AC-8 has a nuance documented as HIGH-1 below (preset does not explicitly set `MU_ENABLE_DOTNET=OFF`, but graceful degradation in `FindDotnetAOT.cmake` means the functional outcome is correct).

### Findings

---

**HIGH-1: AC-8 False Claim — Presets Do NOT Set MU_ENABLE_DOTNET=OFF**
- **Category:** AC-ACCURACY
- **File:** `MuMain/CMakePresets.json` (macos-arm64, linux-x64 presets) + `MuMain/CMakeLists.txt:10`
- **Description:** The Dev Agent Record and test file `test_ac8_dotnet_disabled_native_runners.cmake` claim "presets handle MU_ENABLE_DOTNET=OFF implicitly through the preset configuration." This is false. Neither the `macos-arm64` nor `linux-x64` preset sets `MU_ENABLE_DOTNET` in `cacheVariables`. The CMake option defaults to `ON` (CMakeLists.txt:10). On native CI runners, `FindDotnetAOT.cmake` will execute, attempt to locate `dotnet`, print a warning when not found, and set `DOTNETAOT_FOUND=FALSE`. The build proceeds correctly, but the mechanism is "graceful failure" not "disabled by preset."
- **Impact:** Misleading documentation. If someone installs dotnet on a runner, the build will attempt AOT compilation, which may fail or produce unexpected results. The configure step wastes time searching for dotnet.
- **Fix:** Added `"MU_ENABLE_DOTNET": "OFF"` to `linux-base` and `macos-base` preset `cacheVariables` in `CMakePresets.json`. All inheriting presets now explicitly disable .NET.
- **Status:** fixed

---

**HIGH-2: ATDD Test AC-8 Validates Wrong Thing — Tests MinGW Flag, Not Native Jobs**
- **Category:** TEST-QUALITY
- **File:** `MuMain/tests/build/test_ac8_dotnet_disabled_native_runners.cmake:41-46`
- **Description:** The test's Check 2 searches for `MU_ENABLE_DOTNET=OFF` anywhere in ci.yml and finds it in the MinGW job (line 140), not in the native jobs. This means the test passes even though native jobs do NOT have `MU_ENABLE_DOTNET=OFF`. The test should verify the flag appears in the native job sections specifically, or verify that the presets contain it.
- **Impact:** False GREEN — the test claims to validate AC-8 for native runners but actually validates the MinGW job's flag. If someone removed `MU_ENABLE_DOTNET=OFF` from the MinGW job but kept it absent from native presets, the test would fail for the wrong reason.
- **Fix:** Rewrote Check 2 in `test_ac8_dotnet_disabled_native_runners.cmake` to validate `CMakePresets.json` (the source of truth) for `"MU_ENABLE_DOTNET": "OFF"` instead of searching ci.yml globally. Removed false "implicit" claim from test comments.
- **Status:** fixed

---

**MEDIUM-1: Native CI Jobs Missing BUILD_TESTING=ON — Tests Will Not Run**
- **Category:** CI-CONFIG
- **File:** `MuMain/.github/workflows/ci.yml:154-208`
- **Description:** AC-3 requires native runners to execute Catch2 tests via `ctest`. However, the CMake option `BUILD_TESTING` defaults to `OFF` (CMakeLists.txt:209). The native jobs use `cmake --preset macos-arm64` and `cmake --preset linux-x64`, and neither preset sets `BUILD_TESTING=ON`. Without this, the `tests/` subdirectory is never added, no test targets are built, and `ctest` will report 0 tests (which succeeds with exit code 0, masking the problem).
- **Impact:** The ctest step in CI will silently pass with 0 tests executed, defeating the purpose of AC-3 ("execute Catch2 test suite"). The CI gives a false sense of test coverage.
- **Fix:** Added `"BUILD_TESTING": "ON"` to `linux-base` and `macos-base` preset `cacheVariables` in `CMakePresets.json`. Also added `--no-tests=error` to both ctest invocations in ci.yml so CI fails if no tests are discovered.
- **Status:** fixed

---

**MEDIUM-2: No Per-Job Concurrency Groups for Native Runners**
- **Category:** CI-CONFIG
- **File:** `MuMain/.github/workflows/ci.yml:9-11`
- **Description:** The CI workflow uses a single global concurrency group `ci-${{ github.ref }}` with `cancel-in-progress: true`. This means if a new push arrives while the macOS job is running but the Linux job has not started, the entire workflow (including all jobs) is cancelled and restarted. For expensive native builds with SDL3 FetchContent, this could lead to wasted compute. The existing pattern was fine for 2 quick jobs but may not be optimal for 4 parallel jobs including slow native builds.
- **Impact:** Low — GitHub Actions' behavior is to cancel all pending/running jobs in the group. With caching, re-runs are faster. But initial uncached runs could waste significant time.
- **Fix:** Informational — no code change. Current pattern matches AC-STD-1 (follows existing workflow patterns). Deferred to future optimization story if build times become problematic.
- **Status:** deferred (informational)

---

**MEDIUM-3: SDL3 Cache May Be Invalidated Too Aggressively**
- **Category:** CI-PERFORMANCE
- **File:** `MuMain/.github/workflows/ci.yml:169,199`
- **Description:** The cache key uses `hashFiles('CMakeLists.txt', 'cmake/**')`. Any change to ANY file under `cmake/` (including toolchain files, FindDotnetAOT.cmake, or unrelated cmake modules) will invalidate the SDL3 cache for both platforms. The SDL3 FetchContent download and build is the most expensive part of the native CI jobs.
- **Impact:** Cache misses on unrelated cmake changes waste CI time re-downloading and re-building SDL3.
- **Fix:** Narrowed cache key hash from `hashFiles('CMakeLists.txt', 'cmake/**')` to `hashFiles('CMakeLists.txt', 'src/CMakeLists.txt')` where FetchContent_Declare is actually located. Both macOS and Linux cache keys updated.
- **Status:** fixed

---

**LOW-1: Install Step on macOS Uses `brew install cmake ninja` Without Version Pinning**
- **Category:** CI-REPRODUCIBILITY
- **File:** `MuMain/.github/workflows/ci.yml:163`
- **Description:** The macOS job installs cmake and ninja via `brew install cmake ninja` without version pinning. Homebrew formulas update frequently, which could cause non-reproducible builds if a CMake version change introduces behavioral differences. The Linux job also installs without version pinning but uses apt which has more stable versions per Ubuntu release.
- **Impact:** Low probability but could cause intermittent CI failures when Homebrew updates cmake/ninja.
- **Fix:** Informational — no code change. Low probability risk; `macos-latest` runner images have reasonably stable Homebrew versions. Deferred to future hardening story.
- **Status:** deferred (informational)

---

### ATDD Audit

| Metric | Value |
|--------|-------|
| Total ATDD Items | 12 |
| GREEN (complete) | 12 |
| RED (incomplete) | 0 |
| Coverage | 100% |
| Sync Issues | 1 (HIGH-2: AC-8 test validates wrong scope) |
| Quality Issues | 1 (HIGH-2: false GREEN) |

All ATDD items are marked [x]. All test files exist and follow the CMake script mode pattern. The AC-8 test has a scope issue (HIGH-2) where it validates a global ci.yml property rather than native-job-specific behavior.

### Task Completion Audit

| Task | Claimed | Verified | Notes |
|------|---------|----------|-------|
| Task 1: macOS job | [x] | PASS | All 6 subtasks verified in ci.yml |
| Task 2: Linux job | [x] | PASS | All 6 subtasks verified in ci.yml |
| Task 3: MinGW unchanged | [x] | PASS | MinGW job structure intact |
| Task 4: Release dependencies | [x] | PASS | needs array correct |
| Task 5: CMake preset conditions | [x] | PASS | 5.3 fixed — MU_ENABLE_DOTNET=OFF now explicitly set in native base presets (HIGH-1 resolved) |
| Task 6: Register ATDD CTest | [x] | PASS | 8 entries registered |

### NFR Compliance

- Quality gate artifacts: PASSED (clang-format + cppcheck)
- No backend API endpoints (infrastructure story)
- No frontend components
- Coverage: N/A (no new C++ source code; only YAML and CMake scripts)

### Mandatory Code Quality Rules

- Null safety: N/A (no C++ code)
- Generic exceptions: N/A
- Dead code: N/A
- Code generation: N/A
- Quality gate: PASSED (complete run, 711 files)

## Step 3: Code Review Fixes

**Date:** 2026-03-20
**Iterations:** 1
**Quality Gate After Fixes:** PASSED (711 files, 0 issues)

### Fix Summary

| Metric | Count |
|--------|-------|
| Total Issues | 6 |
| Fixed | 4 |
| Deferred (informational) | 2 |
| Remaining | 0 |
| Iterations Used | 1 |

### Files Modified

| File | Changes |
|------|---------|
| `MuMain/CMakePresets.json` | Added `MU_ENABLE_DOTNET=OFF` and `BUILD_TESTING=ON` to `linux-base` and `macos-base` cacheVariables |
| `MuMain/.github/workflows/ci.yml` | Added `--no-tests=error` to ctest steps; narrowed SDL3 cache key hash to `CMakeLists.txt` + `src/CMakeLists.txt` |
| `MuMain/tests/build/test_ac8_dotnet_disabled_native_runners.cmake` | Rewrote Check 2 to validate presets file instead of ci.yml global search; removed false "implicit" claim |

### Issue Resolution Detail

| Issue | Severity | Resolution |
|-------|----------|------------|
| HIGH-1 | HIGH | **Fixed** — `MU_ENABLE_DOTNET=OFF` added to native base presets |
| HIGH-2 | HIGH | **Fixed** — ATDD test now validates CMakePresets.json directly |
| MEDIUM-1 | MEDIUM | **Fixed** — `BUILD_TESTING=ON` added to native base presets + `--no-tests=error` on ctest |
| MEDIUM-2 | MEDIUM | **Deferred** — Informational; follows existing AC-STD-1 pattern |
| MEDIUM-3 | MEDIUM | **Fixed** — Cache key hash narrowed to FetchContent source files |
| LOW-1 | LOW | **Deferred** — Informational; low probability risk |

**Status: ✅ ALL ACTIONABLE ISSUES FIXED**

**Next:** `/bmad:pcc:workflows:code-review-finalize 7-4-1-native-ci-runners`

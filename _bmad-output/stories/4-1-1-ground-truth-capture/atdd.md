# ATDD Checklist — Story 4.1.1: Ground Truth Capture Mechanism

**Story ID:** 4-1-1-ground-truth-capture
**Story Type:** infrastructure
**Primary Test Level:** Unit (Catch2)
**Output File:** `_bmad-output/stories/4-1-1-ground-truth-capture/atdd.md`
**Date Generated:** 2026-03-09
**Phase:** RED — tests written, implementation pending

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| project-context.md loaded | PASS |
| development-standards.md loaded | PASS |
| Prohibited libraries in tests | NONE USED |
| Required test framework (Catch2 3.7.1) | PASS |
| No OpenGL calls in test code | PASS |
| mu:: namespace (declarations only, headers under test) | PASS |
| No raw new/delete in test code | PASS |
| No NULL (nullptr only) | PASS |
| Test file location (`tests/core/`) | PASS |
| Catch2 TEST_CASE / SECTION / REQUIRE / CHECK | PASS |
| No mocking framework | PASS |

---

## AC-to-Test Mapping

| AC | Description | Test Method | File | Phase |
|----|-------------|-------------|------|-------|
| AC-5 | SSIM score ≥ 0.99 for identical images | `AC-5: SSIM on identical buffers returns score >= 0.99` — sections: 8x8 solid-gray, 16x16 gradient, score capped at 1.0 | `tests/core/test_ground_truth.cpp` | RED |
| AC-5 | SSIM score < 0.99 for dissimilar images | `AC-5: SSIM on dissimilar buffers returns score < 0.99` — sections: inverted, checkerboard, random-noise | `tests/core/test_ground_truth.cpp` | RED |
| AC-5 | SSIM bounded in [0, 1] (edge cases) | `AC-5: SSIM score is bounded in [0.0, 1.0]` — sections: all-zero, single-channel | `tests/core/test_ground_truth.cpp` | RED |
| AC-STD-2 / AC-VAL-2 | SSIM correctly distinguishes identical from different | `AC-VAL-2: SSIM correctly distinguishes identical from different images` | `tests/core/test_ground_truth.cpp` | RED |
| AC-1 | CMake flag `-DENABLE_GROUND_TRUTH_CAPTURE` (default OFF) | Manual: configure with and without flag, verify no impact on release | N/A — build system check | Manual |
| AC-2 | `glReadPixels` → PNG + SHA256 per capture | Manual: Windows build with flag ON, verify files in `tests/golden/` | N/A — requires OpenGL context | Manual |
| AC-3 | Automated scene sweep via CNewUIManager | Manual: run sweep, verify all CNewUI* screens captured | N/A — requires live game instance | Manual |
| AC-4 | Captures written to `tests/golden/` with `{scene}_{w}x{h}.png` naming | Manual: verify naming convention in captured files | N/A — requires live game instance | Manual |
| AC-6 | Failure report with visual diff image when SSIM < threshold | Manual: provide two dissimilar images, verify diff image output | N/A — requires full implementation | Manual |
| AC-STD-1 | Code standards (mu:: namespace, PascalCase, m_ members, #pragma once, no raw new/delete, [[nodiscard]]) | Code review — verified in implementation | N/A — static review | Review |
| AC-STD-5 | Error logging via `g_ErrorReport.Write(...)` on failure | Code review — verify log calls in GroundTruthCapture.cpp | N/A — static review | Review |
| AC-STD-6 | Conventional commit `feat(render): implement ground truth capture and SSIM comparison` | Git history check | N/A — git check | Review |
| AC-STD-13 | Quality gate: `./ctl check` passes 0 errors | `./ctl check` | N/A — CI/local | CI |
| AC-STD-15 | Git safety (no incomplete rebase, no force push) | `git status`, `git log` check | N/A — git check | Review |
| AC-STD-16 | Correct test infrastructure (Catch2, MuTests target, `tests/core/`) | Verify CMakeLists.txt entry and file location | `tests/CMakeLists.txt` | Review |
| AC-VAL-1 | `tests/golden/` populated with baseline screenshots (login, char select, main HUD, inventory) | Manual: run Windows build with capture enabled | N/A — requires Windows + OpenGL build | Manual |
| AC-VAL-3 | `ctest --test-dir MuMain/build -R ground_truth` passes | CTest run | `tests/core/test_ground_truth.cpp` | Manual |

---

## Implementation Checklist

### Infrastructure Setup

- [ ] `MuMain/CMakeLists.txt`: `option(ENABLE_GROUND_TRUTH_CAPTURE "Enable ground truth screenshot capture (Windows only, not for release)" OFF)` added
- [ ] `MuMain/CMakeLists.txt`: `target_compile_definitions(MURenderFX PUBLIC ENABLE_GROUND_TRUTH_CAPTURE)` (or appropriate target) added inside `if(ENABLE_GROUND_TRUTH_CAPTURE)` block
- [ ] `MuMain/src/source/Platform/GroundTruthCapture.h` created with `mu::GroundTruthCapture` class, `[[nodiscard]]` on `CaptureScene()` and `CompareTo()`, `#pragma once`, no `#ifdef _WIN32` in game logic
- [ ] `MuMain/src/source/Platform/GroundTruthCapture.cpp` created — `glReadPixels` capture, PNG via `stb_image_write`, SHA256, SSIM computation — all implementation guarded by `#ifdef ENABLE_GROUND_TRUTH_CAPTURE` except `ComputeSSIM()` (always compiled)
- [ ] `stb_image_write.h` present in `MuMain/src/ThirdParty/stb/` (add if not already present)

### AC Test Coverage

- [ ] `MuMain/tests/core/test_ground_truth.cpp` compiles without errors
- [ ] `MuMain/tests/CMakeLists.txt` has `target_sources(MuTests PRIVATE core/test_ground_truth.cpp)` entry with Story 4.1.1 comment block
- [ ] All `TEST_CASE` tests in RED phase initially FAIL (as expected for TDD)

### AC-1: CMake Flag

- [ ] Running `cmake -DENABLE_GROUND_TRUTH_CAPTURE=OFF` compiles cleanly (no capture code in binary)
- [ ] Running `cmake -DENABLE_GROUND_TRUTH_CAPTURE=ON` (Windows only) compiles capture code
- [ ] Flag is NOT added to CI MinGW build or `CMakePresets.json` release presets

### AC-2: Capture Mechanism

- [ ] `CaptureScene()` calls `glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, ...)` with RGBA format
- [ ] Buffer is flipped vertically (OpenGL is bottom-up, PNG is top-down)
- [ ] PNG written via `stbi_write_png()` to correct path
- [ ] SHA256 hash computed and available per capture (logged or stored alongside PNG)
- [ ] On `glReadPixels` or write failure: `g_ErrorReport.Write(L"RENDER: ground truth -- capture failed for %hs", sceneName)`

### AC-3: Scene Sweep

- [ ] `RunUISweep()` (or equivalent) iterates `CNewUIManager` window list
- [ ] Each window: `Show()` → render → `CaptureScene()` → `Hide()`
- [ ] Sweep triggered at startup when `ENABLE_GROUND_TRUTH_CAPTURE` is set (from `WinMain()` or `SceneManager`)
- [ ] All instrumentation inside `#ifdef ENABLE_GROUND_TRUTH_CAPTURE` block

### AC-4: Output Directory and Naming

- [ ] `std::filesystem::create_directories("tests/golden")` called before first write
- [ ] Filename format: `{scene}_{width}x{height}.png` (e.g., `inventory_800x600.png`)
- [ ] At minimum: `login`, `char_select`, `main_hud`, `inventory` scene names captured

### AC-5: SSIM Function

- [ ] `ComputeSSIM()` is always compiled (no `ENABLE_GROUND_TRUTH_CAPTURE` guard)
- [ ] Luminance conversion: Y = 0.2126R + 0.7152G + 0.0722B per channel
- [ ] 8×8 sliding window (uniform or Gaussian weighting)
- [ ] Constants: C1 = (0.01 × 255)², C2 = (0.03 × 255)² per SSIM paper
- [ ] Returns mean SSIM across all windows in [0.0, 1.0]
- [ ] Default threshold 0.99 documented in header/comments
- [ ] `[[nodiscard]]` on `ComputeSSIM()` (informational — returns a value caller should check)

### AC-6: Failure Report

- [ ] `CompareTo()` produces a diff image marking divergent regions when SSIM < threshold
- [ ] Diff image written alongside source images in `tests/golden/` with `-diff` suffix
- [ ] On comparison failure: `g_ErrorReport.Write(L"RENDER: ground truth -- SSIM below threshold: %.4f for %hs", score, sceneName)`

### Code Standards (AC-STD-1)

- [ ] `mu::` namespace used for all new code in `GroundTruthCapture.h/cpp`
- [ ] PascalCase function names (`CaptureScene`, `ComputeSSIM`, `CompareTo`, `RunUISweep`)
- [ ] `m_` prefix on member variables (if any instance members)
- [ ] `#pragma once` in header (no `#ifndef` guard)
- [ ] No raw `new`/`delete` — `std::vector<unsigned char>` for pixel buffers
- [ ] `[[nodiscard]]` on `CaptureScene()` and `CompareTo()`
- [ ] Allman braces, 4-space indent, 120-column limit
- [ ] No `#ifdef _WIN32` in `GroundTruthCapture.cpp` game logic

### Error Logging (AC-STD-5)

- [ ] `g_ErrorReport.Write(L"RENDER: ground truth -- capture failed for %hs", sceneName)` on `glReadPixels`/write failure
- [ ] `g_ErrorReport.Write(L"RENDER: ground truth -- SSIM below threshold: %.4f for %hs", score, sceneName)` on comparison failure
- [ ] No `wprintf`, `__TraceF()`, or `DebugAngel` calls

### Quality Gate (AC-STD-13)

- [ ] `./ctl check` passes 0 errors (clang-format-check + cppcheck)
- [ ] No new cppcheck warnings introduced
- [ ] No new clang-format violations

### Catch2 Tests Pass GREEN (AC-STD-2, AC-VAL-2, AC-VAL-3)

- [ ] `ctest --test-dir MuMain/build -R ground_truth` exits 0
- [ ] `AC-5: SSIM on identical buffers returns score >= 0.99` — 3 sections PASS
- [ ] `AC-5: SSIM on dissimilar buffers returns score < 0.99` — 3 sections PASS
- [ ] `AC-5: SSIM score is bounded in [0.0, 1.0]` — 2 sections PASS
- [ ] `AC-VAL-2: SSIM correctly distinguishes identical from different images` PASS

### Manual Validation (AC-VAL-1, AC-VAL-2, AC-VAL-3)

- [ ] Windows OpenGL build with `-DENABLE_GROUND_TRUTH_CAPTURE=ON` produces PNG files in `tests/golden/`
- [ ] At least 4 scenes captured: `login_*`, `char_select_*`, `main_hud_*`, `inventory_*`
- [ ] SSIM tool returns 1.0 for identical image vs itself
- [ ] SSIM tool returns < 0.99 for known-different images

### Git Safety (AC-STD-15, AC-STD-6)

- [ ] No incomplete rebase (`git status` clean)
- [ ] Commit message: `feat(render): implement ground truth capture and SSIM comparison`
- [ ] No force push to main/master

---

## Test Files Created

| File | Status | Notes |
|------|--------|-------|
| `MuMain/tests/core/test_ground_truth.cpp` | CREATED (RED) | 4 TEST_CASEs, 10 SECTIONs; pure SSIM logic, no OpenGL |

## Files To Be Created/Modified During Implementation

| File | Action | Target |
|------|--------|--------|
| `MuMain/src/source/Platform/GroundTruthCapture.h` | CREATE | `MURenderFX` (Platform/ dir) |
| `MuMain/src/source/Platform/GroundTruthCapture.cpp` | CREATE | `MURenderFX` (Platform/ dir) |
| `MuMain/src/ThirdParty/stb/stb_image_write.h` | CREATE (if absent) | ThirdParty |
| `MuMain/CMakeLists.txt` | MODIFY | Add ENABLE_GROUND_TRUTH_CAPTURE option |
| `MuMain/src/source/Scenes/SceneManager.cpp` | MODIFY | Add #ifdef ENABLE_GROUND_TRUTH_CAPTURE instrumentation |
| `MuMain/tests/CMakeLists.txt` | MODIFY | Add test_ground_truth.cpp entry |

---

## Final Validation

- [x] project-context.md loaded and constraints verified
- [x] development-standards.md loaded
- [x] Existing tests checked (none matching ground_truth — 0 to map)
- [x] AC-N: prefix convention applied (new tests named with AC-N in TEST_CASE title)
- [x] All tests use PCC-approved patterns (Catch2, no mocking, no OpenGL in tests)
- [x] No prohibited libraries used
- [x] Implementation checklist includes PCC compliance items
- [x] ATDD checklist has AC-to-test mapping
- [x] Test file physically created: `MuMain/tests/core/test_ground_truth.cpp`

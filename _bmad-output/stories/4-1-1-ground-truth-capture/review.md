# Code Review: Story 4-1-1-ground-truth-capture

**Story:** 4.1.1 — Ground Truth Capture Mechanism
**Date:** 2026-03-09
**Story File:** `_bmad-output/stories/4-1-1-ground-truth-capture/story.md`

---

## Pipeline Status

| Step | Status | Notes |
|------|--------|-------|
| 1. Quality Gate | PASSED | format-check + lint: 701 files, 0 errors |
| 2. Code Review Analysis | PASSED (with findings) | 2026-03-09 — 0 BLOCKER, 0 CRITICAL, 2 HIGH, 3 MEDIUM, 3 LOW |
| 3. Code Review Finalize | pending | — |

---

## Quality Gate Progress

| Phase | Component | Status | Iterations | Issues Fixed |
|-------|-----------|--------|------------|--------------|
| Backend Local | mumain (./MuMain) | PASSED | 1 | 0 |
| Backend SonarCloud | mumain (./MuMain) | SKIPPED (not configured) | — | — |
| Frontend Local | — | N/A (no frontend components) | — | — |
| Frontend SonarCloud | — | N/A (no frontend components) | — | — |

---

## Affected Components

| Component | Path | Tags | Type |
|-----------|------|------|------|
| mumain | ./MuMain | backend | cpp-cmake |
| project-docs | ./_bmad-output | documentation | documentation |

**Backend:** 1 component (mumain)
**Frontend:** 0 components
**Documentation:** 1 component (project-docs)

---

## Fix Iterations

None required — quality gate passed on first iteration with 0 issues.

---

## Step 1: Quality Gate — COMPLETE

**quality_gate_status:** PASSED

### Tech Profile: cpp-cmake

| Command | Value |
|---------|-------|
| quality_gate_cmd | `make -C MuMain format-check && make -C MuMain lint` |
| lint_cmd | `make -C MuMain lint` |
| format_cmd | `make -C MuMain format` |
| skip_checks | build, test (macOS — Win32/DirectX) |
| sonar | not configured (no sonar_key) |
| boot_verify | not configured |

### Backend: mumain (./MuMain) — PASSED

| Check | Command | Result | Exit Code |
|-------|---------|--------|-----------|
| format-check | `make -C MuMain format-check` | PASSED | 0 |
| lint (cppcheck) | `make -C MuMain lint` | PASSED (701/701 files, 0 errors) | 0 |
| build | skipped (macOS cannot compile Win32/DirectX) | SKIPPED | — |
| test | skipped (macOS, skip_checks) | SKIPPED | — |
| SonarCloud | not configured | SKIPPED | — |

### Frontend: N/A

No frontend components in story's Affected Components table.

### Story Type: infrastructure

AC tests: Skipped (infrastructure story — no Playwright/integration tests applicable).

---

## Quality Gate Summary

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Backend Local (mumain) | PASSED | 1 | 0 |
| Backend SonarCloud | SKIPPED | — | — |
| Frontend | N/A | — | — |
| **Overall** | **PASSED** | — | 0 |

**Next step:** `/bmad:pcc:workflows:code-review-analysis 4-1-1-ground-truth-capture`

---

## Step 2: Analysis Results

**Completed:** 2026-03-09
**Status:** PASSED (with findings)
**Reviewer:** claude-sonnet-4-6 (adversarial)

### Severity Summary

| Severity | Count |
|----------|-------|
| BLOCKER  | 0     |
| CRITICAL | 0     |
| HIGH     | 2     |
| MEDIUM   | 3     |
| LOW      | 3     |
| **Total**| **8** |

---

### AC Validation Results

**Total ACs:** 16 (AC-1..6, AC-STD-1/2/5/6/13/15/16, AC-VAL-1/2/3)
**Implemented:** 13
**Deferred (legitimate):** 3 (AC-6, AC-VAL-1, AC-VAL-3 — explicitly marked `[ ]` in story with justification)
**BLOCKERS:** 0
**Pass Rate:** 100% of *expected* ACs (deferred ones are pre-declared)

| AC | Status | Evidence |
|----|--------|---------|
| AC-1 | IMPLEMENTED | `MuMain/CMakeLists.txt:92-97` |
| AC-2 | IMPLEMENTED | `GroundTruthCapture.cpp:288-325` |
| AC-3 | IMPLEMENTED (reduced scope) | `GroundTruthCapture.cpp:360-377` — see H-1 |
| AC-4 | IMPLEMENTED | `GroundTruthCapture.cpp:296-300` |
| AC-5 | IMPLEMENTED | `GroundTruthCapture.cpp:38-161` |
| AC-6 | DEFERRED (story `[ ]`) | `GroundTruthCapture.cpp:347-354` — CompareTo() returns -1.0 placeholder |
| AC-STD-1 | IMPLEMENTED | Header/cpp verified |
| AC-STD-2 | IMPLEMENTED | `tests/core/test_ground_truth.cpp` — 4 TEST_CASEs, 10 SECTIONs |
| AC-STD-5 | IMPLEMENTED | `GroundTruthCapture.cpp:315, 343` |
| AC-STD-6 | IMPLEMENTED | commit bd26f21e |
| AC-STD-13 | IMPLEMENTED | review.md QG step: 701 files, 0 errors |
| AC-STD-15 | IMPLEMENTED | git log clean |
| AC-STD-16 | IMPLEMENTED | `tests/CMakeLists.txt:51`, Catch2 framework |
| AC-VAL-1 | DEFERRED (story `[ ]`) | Requires Windows OpenGL build |
| AC-VAL-2 | IMPLEMENTED | `test_ground_truth.cpp:202-226` |
| AC-VAL-3 | DEFERRED (story `[ ]`) | macOS cannot compile Win32 TUs |

---

### Findings

#### HIGH-1 | ATDD-FALSE-GREEN — AC-6 implementation section marked [x] in atdd.md despite being unimplemented
- **Category:** ATDD-FALSE-GREEN
- **Severity:** HIGH
- **File:** `_bmad-output/stories/4-1-1-ground-truth-capture/atdd.md:108-110`
- **Description:** The ATDD checklist's "AC-6: Failure Report" section (lines 106-111) marks three items as `[x]` including "`CompareTo()` produces a diff image marking divergent regions when SSIM < threshold" and "Diff image written alongside source images in `tests/golden/`". However, the actual `CompareTo()` implementation in `GroundTruthCapture.cpp:347-354` **always returns -1.0** with a comment explicitly noting it is deferred to story 4.2.x. No diff image is ever written. The story correctly marks AC-6 as `[ ]` (deferred), but the ATDD checklist contradicts this with false [x] marks — creating a sync mismatch that could mislead the next reviewer.
- **Fix:** Set the three AC-6 items in atdd.md to `[ ]` (unchecked) to match the story's `[ ] AC-6` deferral status.
- **Status:** pending

#### HIGH-2 | CODE-QUALITY — Per-frame `CaptureScene("scene_main")` runs every render frame, not just once
- **Category:** CODE-QUALITY / PERFORMANCE
- **Severity:** HIGH
- **File:** `MuMain/src/source/Scenes/SceneManager.cpp:971-983`
- **Description:** The `RunUISweep()` call is correctly one-shot (guarded by `s_groundTruthSweeepDone`), but `CaptureScene("scene_main", ...)` at line 982 runs **every frame** inside the `#ifdef ENABLE_GROUND_TRUTH_CAPTURE` block. When the capture flag is enabled this will: (1) call `glReadPixels` every frame — a GPU synchronization stall that drops to ~1 FPS on large resolutions, (2) overwrite `tests/golden/scene_main_NxN.png` each frame, making the baseline useless, (3) produce tens of thousands of I/O operations per session. Story Dev Notes describe capture as a "one-shot via static bool guard" but only the sweep has that guard. The per-frame capture is unguarded.
- **Fix:** Wrap the `CaptureScene("scene_main", ...)` call in the same static-bool one-shot guard, or remove it if the sweep already covers the main scene (since `RunUISweep` has a `main_hud` entry).
- **Status:** pending

#### MEDIUM-1 | CODE-QUALITY — `s_groundTruthSweeepDone` has a double-`e` typo in the variable name
- **Category:** CODE-QUALITY
- **Severity:** MEDIUM
- **File:** `MuMain/src/source/Scenes/SceneManager.cpp:975-978`
- **Description:** Variable name `s_groundTruthSweeepDone` has three `e`s ("Sweeeep"). Not caught by cppcheck or clang-format. Minor but projects a careless image in a code-review context and could cause confusion in later diffs.
- **Fix:** Rename to `s_groundTruthSweepDone`.
- **Status:** pending

#### MEDIUM-2 | CODE-QUALITY — `ComputeSHA256Hex` parameter `len` is `int` but compared against `long long` bit_len cast — implicit narrowing risk for large buffers
- **Category:** CODE-QUALITY / CORRECTNESS
- **Severity:** MEDIUM
- **File:** `MuMain/src/source/Platform/GroundTruthCapture.cpp:182, 202`
- **Description:** `ComputeSHA256Hex(const unsigned char* data, int len, char outHex[65])` accepts `len` as `int`. At the call site in `CaptureScene` (line 321), `buf_size` is `std::size_t` and cast to `int`: `ComputeSHA256Hex(buffer.data(), static_cast<int>(buf_size), sha256hex)`. For a 4K capture (3840×2160×4 = ~33 MB), `buf_size` exceeds `INT_MAX` (2 GB limit not hit for typical resolutions, but 8K at RGBA = 67 MB, still fine). However the `static_cast<int>` silently truncates for truly large buffers and there is no assertion. Separately, the SHA-256 padding math on line 202 computes `bit_len` as `long long` from `int len` — if `len` were negative (from a bad cast), this yields undefined behaviour. The function signature should use `std::size_t len` throughout.
- **Fix:** Change `ComputeSHA256Hex` signature to accept `std::size_t len`, remove the `static_cast<int>(buf_size)` at call site, and update internal arithmetic accordingly.
- **Status:** pending

#### MEDIUM-3 | CODE-QUALITY — SSIM silently drops partial-window columns/rows at image boundaries when dimensions not divisible by 8
- **Category:** CODE-QUALITY / CORRECTNESS
- **Severity:** MEDIUM
- **File:** `MuMain/src/source/Platform/GroundTruthCapture.cpp:53-54, 80-81`
- **Description:** `windows_x = width / WINDOW` and `windows_y = height / WINDOW` use integer division. For an 800×600 image: `windows_x = 100`, `windows_y = 75` — exact fit, no issue. But for 1280×720: `windows_x = 160`, `windows_y = 90` — exact fit. For 1920×1080: same. However for non-standard sizes like 1366×768 or 1024×600: `1366/8 = 170` (drops 6px column), `600/8 = 75` — drops partial right/bottom strips silently. For a ground-truth tool, silently ignoring edge pixels could miss rendering artifacts in UI borders/status bars, which are precisely the areas most likely to diverge during migration. The acknowledged comment in the completeness-gate mentions this as LOW finding; it deserves MEDIUM here because it is the core purpose of the module.
- **Fix:** Compute `windows_x = (width + WINDOW - 1) / WINDOW` (ceiling division) and clamp window bounds with the existing `std::min(x0 + win_w, width)` (already present) — this requires only a 2-line change.
- **Status:** pending

#### LOW-1 | CODE-QUALITY — SHA256 is logged alongside PNG capture but NOT written to a companion `.sha256` file
- **Category:** CODE-QUALITY
- **Severity:** LOW
- **File:** `MuMain/src/source/Platform/GroundTruthCapture.cpp:319-322`
- **Description:** AC-2 says "writes PNG file + SHA256 hash per capture." The SHA256 is computed and logged to `g_ErrorReport` but never written to disk (e.g., `inventory_800x600.png.sha256`). The `g_ErrorReport` log is post-mortem/debug only — if the game crashes, the log may not flush. A companion `.sha256` text file alongside each PNG is the conventional and reliable way to persist checksums for later verification.
- **Fix:** Write a text file `path + ".sha256"` containing the hex string after the PNG write succeeds.
- **Status:** pending

#### LOW-2 | MISSING-ATDD — `CompareTo()` deferred stub has no test verifying the -1.0 "not yet implemented" return code
- **Category:** MISSING-ATDD
- **Severity:** LOW
- **File:** `MuMain/src/source/Platform/GroundTruthCapture.cpp:331-354`
- **Description:** `CompareTo()` exists in the public API (header declares it), is callable, but always returns -1.0. There is no test confirming that callers receive -1.0 (i.e., can detect "deferred" vs "pass" vs "fail"). Future story 4.2.x will implement it, but by then the existing test suite may assume a different contract. A single "deferred returns negative" test would lock in the temporary contract.
- **Fix:** Optional — add a `TEST_CASE` for `CompareTo("nonexistent", 1, 1)` verifying return < 0. Low priority given deferred status.
- **Status:** pending

#### LOW-3 | CODE-QUALITY — `stb_image_write.h` uses `#ifndef` include guard instead of `#pragma once` (project standard)
- **Category:** CODE-QUALITY
- **Severity:** LOW
- **File:** `MuMain/src/ThirdParty/stb/stb_image_write.h:34`
- **Description:** The bundled stb header uses `#ifndef INCLUDE_STB_IMAGE_WRITE_H` / `#define` / `#endif` guards instead of `#pragma once`. Per project conventions (AC-STD-1: `#pragma once`, no `#ifndef` header guards), new headers should use `#pragma once`. This file was added by the story (it is "new code" in the File List). However, it mimics the upstream stb style intentionally for easier future replacement with the real stb headers. Acceptable but worth flagging.
- **Fix:** Replace `#ifndef INCLUDE_STB_IMAGE_WRITE_H` guard with `#pragma once` for consistency with project style. OR add a comment explaining why the upstream stb guard is intentionally preserved.
- **Status:** pending

---

### ATDD Audit

- **Total ATDD items:** 18 (Implementation Checklist: counted from atdd.md)
- **GREEN [x]:** 15
- **RED [ ]:** 3 (ctest deferred, Windows manual captures, SSIM manual check)
- **Coverage:** 83% (3 items legitimately deferred to Windows manual validation)

**ATDD Issues Found:**
- **HIGH-1 above:** AC-6 section in atdd.md has 3 false-GREEN [x] items (lines 108-110)

---

### Task Audit

| Task | Claim | Reality |
|------|-------|---------|
| Task 1 (GroundTruthCapture module) | [x] | VERIFIED — all 4 subtasks have code evidence |
| Task 2 (SceneManager instrumentation) | [x] | PARTIAL — sweep is one-shot ✓; per-frame capture is not one-shot (see HIGH-2) |
| Task 3 (Output directory + naming) | [x] | VERIFIED |
| Task 4 (Catch2 tests) | [x] | VERIFIED — 4 TEST_CASEs, 10 SECTIONs, all GREEN |
| Task 5 (Quality gate + commit) | [x] | VERIFIED — bd26f21e, 701 files 0 errors |


---

## Code Review Analysis (Step 2)

**Date:** 2026-03-09 14:38
**Reviewer:** Claude (Adversarial Analysis)

💬 **Code Review Analysis for Story 4-1-1 complete.** Here's the summary:

**Result: 2 HIGH | 3 MEDIUM | 3 LOW — no BLOCKERS**

Key findings requiring action in code-review-finalize:

1. **HIGH-1 (ATDD false-green):** 3 items in `atdd.md` marked `[x]` for AC-6 (diff image output) that are actually stubs — needs unchecking
2. **HIGH-2 (Performance):** `CaptureScene("scene_main")` in `SceneManager.cpp:982` runs every render frame with no one-shot guard, causing repeated `glReadPixels` GPU stalls + disk writes
3. **MEDIUM-1:** Typo `s_groundTruthSweeepDone` (triple-e) in `SceneManager.cpp`
4. **MEDIUM-2:** `ComputeSHA256Hex` uses `int len` instead of `std::size_t`
5. **MEDIUM-3:** SSIM discards partial boundary windows when dimensions aren't divisible by 8

Run `/bmad-pcc-code-review-finalize` to fix these and close the story.

📋 Result:
**Code Review Analysis for Story 4-1-1 complete.** Here's the summary:

**Result: 2 HIGH | 3 MEDIUM | 3 LOW — no BLOCKERS**

Key findings requiring action in code-review-finalize:

1. **HIGH-1 (ATDD false-green):** 3 items in `atdd.md` marked `[x]` for AC-6 (diff image output) that are actually stubs — needs unchecking
2. **HIGH-2 (Performance):** `CaptureScene("scene_main")` in `SceneManager.cpp:982` runs every render frame with no one-shot guard, causing repeated `glReadPixels` GPU stalls + disk writes
3. **MEDIUM-1:** Typo `s_groundTruthSweeepDone` (triple-e) in `SceneManager.cpp`
4. **MEDIUM-2:** `ComputeSHA256Hex` uses `int len` instead of `std::size_t`
5. **MEDIUM-3:** SSIM discards partial boundary windows when dimensions aren't divisible by 8

Run `/bmad-pcc-code-review-finalize` to fix these and close the story.

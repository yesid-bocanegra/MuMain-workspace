# Story 4.1.1: Ground Truth Capture Mechanism

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 4 - Rendering Pipeline Migration |
| Feature | 4.1 - Ground Truth |
| Story ID | 4.1.1 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-RENDER-GROUNDTRUTH-CAPTURE |
| FRs Covered | FR15 |
| Prerequisites | EPIC-2 Story 2.1.1 (SDL3 windowing — done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | New `GroundTruthCapture.h/.cpp` in `Platform/`, CMake flag `-DENABLE_GROUND_TRUTH_CAPTURE`, instrumentation in `SceneManager.cpp`; Catch2 SSIM test in `tests/core/` |
| project-docs | documentation | Test scenarios, story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** an automated ground truth screenshot capture system,
**so that** I can validate rendering parity after each migration step against the Windows OpenGL baseline.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `-DENABLE_GROUND_TRUTH_CAPTURE` CMake option (default OFF) enables capture mode — no impact on release builds
- [ ] **AC-2:** Capture mechanism uses `glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, ...)` → writes PNG file + SHA256 hash per capture
- [ ] **AC-3:** Automated scene sweep: iterate through UI windows via `CNewUIManager::Show()` / `Hide()` to capture each CNewUI* screen
- [ ] **AC-4:** All captures written to `tests/golden/` with structured naming: `{scene}_{width}x{height}.png` (e.g., `inventory_800x600.png`)
- [ ] **AC-5:** SSIM comparison function: perceptual diff with configurable threshold (default > 0.99); NOT pixel-exact match
- [ ] **AC-6:** Comparison produces failure report including visual diff image marking divergent regions when SSIM < threshold

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — `mu::` namespace for new code, PascalCase functions, `m_` members, `#pragma once`, no raw `new`/`delete`, `[[nodiscard]]` on fallible functions
- [ ] **AC-STD-2:** Catch2 test in `tests/core/test_ground_truth.cpp`: SSIM comparison with two known-similar images (score ≥ 0.99 expected PASS) and two known-different images (score < 0.99 expected FAIL)
- [ ] **AC-STD-5:** Error logging via `g_ErrorReport.Write(L"RENDER: ground truth -- capture failed for %s", scene)` on failure
- [ ] **AC-STD-6:** Conventional commit: `feat(render): implement ground truth capture and SSIM comparison`

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [ ] **AC-STD-13:** Quality Gate passes (`make -C MuMain format-check && make -C MuMain lint`)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2, MuTests target, `tests/core/` directory)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** `tests/golden/` populated with baseline screenshots captured from Windows OpenGL build (at least login screen, character select, main UI frame, inventory)
- [ ] **AC-VAL-2:** SSIM tool correctly identifies identical images (score = 1.0) and known-different images (score < 0.99)
- [ ] **AC-VAL-3:** Catch2 test suite passes: `ctest --test-dir MuMain/build -R ground_truth`

---

## Tasks / Subtasks

- [ ] Task 1: Implement `GroundTruthCapture` module (AC: 1, 2, 4)
  - [ ] Subtask 1.1: Add `option(ENABLE_GROUND_TRUTH_CAPTURE "Enable ground truth capture mode" OFF)` to `MuMain/CMakeLists.txt`
  - [ ] Subtask 1.2: Create `MuMain/src/source/Platform/GroundTruthCapture.h` — declare `mu::GroundTruthCapture` class with `CaptureScene()`, `ComputeSSIM()`, `CompareTo()` interface
  - [ ] Subtask 1.3: Create `MuMain/src/source/Platform/GroundTruthCapture.cpp` — implement `glReadPixels` capture, PNG write via `stb_image_write` (already in ThirdParty or use libturbojpeg fallback), SHA256 hash via `<openssl/sha.h>` or simple custom impl
  - [ ] Subtask 1.4: Implement SSIM computation over captured RGBA buffers (standard 3-channel luminance formula, 8x8 window)
- [ ] Task 2: Instrument `SceneManager.cpp` (AC: 3)
  - [ ] Subtask 2.1: Add `#ifdef ENABLE_GROUND_TRUTH_CAPTURE` block — call `GroundTruthCapture::CaptureScene(scene_name)` after each scene render completes
  - [ ] Subtask 2.2: Add UI sweep helper: iterate `CNewUIManager` window list, `Show()` each, capture, `Hide()` (runs at app startup when flag is set)
- [ ] Task 3: Output directory and naming (AC: 4)
  - [ ] Subtask 3.1: Ensure `tests/golden/` directory is created if missing (use `std::filesystem::create_directories`)
  - [ ] Subtask 3.2: Implement `{scene}_{width}x{height}.png` naming convention
- [ ] Task 4: Catch2 test (AC: AC-STD-2, AC-VAL-2)
  - [ ] Subtask 4.1: Create `MuMain/tests/core/test_ground_truth.cpp`
  - [ ] Subtask 4.2: Add test source to `MuMain/tests/CMakeLists.txt` under BUILD_TESTING guard
  - [ ] Subtask 4.3: Write `TEST_CASE` for SSIM on identical buffers (expect ≥ 0.99)
  - [ ] Subtask 4.4: Write `TEST_CASE` for SSIM on randomized buffers (expect < 0.99)
- [ ] Task 5: Quality gate + commit (AC: AC-STD-13, AC-STD-6)
  - [ ] Subtask 5.1: Run `./ctl check` — zero errors
  - [ ] Subtask 5.2: Commit with message `feat(render): implement ground truth capture and SSIM comparison`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging pattern (not an error catalog entry):
- `g_ErrorReport.Write(L"RENDER: ground truth -- capture failed for %s", scene_name)` on `glReadPixels` failure
- `g_ErrorReport.Write(L"RENDER: ground truth -- SSIM below threshold: %.4f for %s", score, scene_name)` on comparison failure

---

## Contract Catalog Entries

### API Contracts

Not applicable — no network endpoints introduced.

### Event Contracts

Not applicable — no events introduced.

### Navigation Entries

Not applicable — infrastructure story, no UI navigation.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 3.7.1 | SSIM pure-logic functions | Identical buffers → 1.0; random buffers → < 0.99; partial overlap |
| Integration (manual) | Windows build | Golden baseline populated | Capture all screens, verify PNG files exist in `tests/golden/` |

---

## Dev Notes

### Context: Why This Story Exists

This story creates the **regression testing safety net** for all subsequent rendering migration work (EPIC-4). Before any OpenGL call sites are replaced, baselines must be captured from the working Windows OpenGL build. Subsequent stories (4.2.x, 4.3.x, 4.4.x) will use these baselines to validate that SDL_gpu output matches the OpenGL baseline at SSIM ≥ 0.99.

**Without this story, there is no way to objectively verify rendering parity** during migration.

### Project Structure Notes

**New files to create:**

| File | CMake Target |
|------|-------------|
| `MuMain/src/source/Platform/GroundTruthCapture.h` | `MURenderFX` (or `MUPlatform` — see decision below) |
| `MuMain/src/source/Platform/GroundTruthCapture.cpp` | Same target |
| `MuMain/tests/core/test_ground_truth.cpp` | `MuTests` |

**Placement decision:** `Platform/GroundTruthCapture.*` goes in `MuPlatform` conceptually (it's a platform diagnostic tool), but since `MURenderFX` is what owns `glReadPixels` today, and the capture code calls OpenGL directly, it can live in `Platform/` (inside `MuMain/src/source/`) and be linked into `MURenderFX`. The OpenGL stub in `stdafx.h` (`inline void glReadPixels(...) {}`) means the Catch2 tests can be compiled without OpenGL — the SSIM logic test does NOT call `glReadPixels`.

**Existing relevant code:**

- `MuMain/src/source/Scenes/SceneManager.cpp:210` — `CaptureScreenshot()` already calls `glReadPixels(0, 0, WindowWidth, WindowHeight, GL_RGB, GL_UNSIGNED_BYTE, Buffer.data())`. This is the existing in-game screenshot mechanism. **Do NOT remove it** — it serves a different purpose (player screenshots). The new `GroundTruthCapture` is a separate system activated only under `ENABLE_GROUND_TRUTH_CAPTURE`.
- `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp:233` — separate `glReadPixels` for depth reading; unrelated.
- `MuMain/src/source/Main/stdafx.h:237` — stub `inline void glReadPixels(...) {}` for macOS/Linux builds. This ensures Catch2 tests compile on all platforms.

**CMake target structure:**
```
MUCommon → MUCore → MURenderFX → MUGame → Main
                 └→ MUPlatform
```
`file(GLOB)` is used in `MURenderFX` for its source directory — new `.cpp` files in `RenderFX/` are auto-discovered. For `Platform/`, check whether `CMakeLists.txt` uses glob or explicit list for `MUPlatform`. If explicit, add the new file manually.

**Tests CMakeLists.txt pattern** (from existing stories):
```cmake
target_sources(MuTests PRIVATE core/test_ground_truth.cpp)
# Guard with BUILD_TESTING check (already conditional via if(BUILD_TESTING))
```

### Technical Implementation

#### PNG Output

The capture needs to write PNG files. Options in this codebase (no libpng currently linked):

1. **`stb_image_write.h`** — single-header, already commonly embedded in game engines. Check `MuMain/src/ThirdParty/` for existing stb headers. If not present, add `stb_image_write.h` to `ThirdParty/stb/`.
2. **libturbojpeg** — already linked, but only handles JPEG. For ground truth, PNG is preferred (lossless). Use stb for PNG.

Implementation skeleton:
```cpp
// Platform/GroundTruthCapture.cpp
#include "GroundTruthCapture.h"
#include "ErrorReport.h"
#ifdef ENABLE_GROUND_TRUTH_CAPTURE
#include <filesystem>
#include <vector>
// stb_image_write: only define implementation once in this TU
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb/stb_image_write.h"
#endif

namespace mu
{

#ifdef ENABLE_GROUND_TRUTH_CAPTURE
[[nodiscard]] bool GroundTruthCapture::CaptureScene(const char* sceneName, int width, int height)
{
    std::filesystem::create_directories("tests/golden");
    std::string path = std::string("tests/golden/") + sceneName
                       + "_" + std::to_string(width) + "x" + std::to_string(height) + ".png";

    std::vector<unsigned char> buffer(static_cast<size_t>(width) * height * 4);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer.data());
    // OpenGL framebuffer is bottom-up — flip vertically before writing
    FlipVertical(buffer, width, height, 4);

    if (!stbi_write_png(path.c_str(), width, height, 4, buffer.data(), width * 4))
    {
        g_ErrorReport.Write(L"RENDER: ground truth -- capture failed for %hs", sceneName);
        return false;
    }
    return true;
}
#endif

// SSIM is always compiled — pure logic, no OpenGL dependency
double GroundTruthCapture::ComputeSSIM(
    const unsigned char* imgA, const unsigned char* imgB, int width, int height, int channels)
{
    // ... luminance-based SSIM over 8x8 windows ...
    // Standard formula: SSIM(x,y) = (2μxμy + C1)(2σxy + C2) / ((μx²+μy²+C1)(σx²+σy²+C2))
    // Return mean over all windows
}

} // namespace mu
```

#### Vertical Flip Note

OpenGL's `glReadPixels` returns pixels bottom-row-first (origin at bottom-left). PNG convention is top-row-first. Must flip before writing:
```cpp
static void FlipVertical(std::vector<unsigned char>& buf, int w, int h, int ch)
{
    int stride = w * ch;
    for (int row = 0; row < h / 2; ++row)
    {
        std::swap_ranges(buf.begin() + row * stride,
                         buf.begin() + row * stride + stride,
                         buf.begin() + (h - 1 - row) * stride);
    }
}
```

#### SSIM Implementation Notes

- Use luminance channel only (convert RGB → Y = 0.2126R + 0.7152G + 0.0722B)
- 8×8 sliding window with Gaussian weighting (or uniform for simplicity)
- C1 = (0.01 × 255)², C2 = (0.03 × 255)² per standard SSIM paper
- Return mean SSIM across all windows
- Do NOT use floating-point image data for capture — `GL_UNSIGNED_BYTE` is correct

#### SceneManager Integration

Only add instrumentation under `#ifdef ENABLE_GROUND_TRUTH_CAPTURE`:
```cpp
// SceneManager.cpp — after scene render completes, before swap
#ifdef ENABLE_GROUND_TRUTH_CAPTURE
mu::GroundTruthCapture::CaptureScene("scene_main", WindowWidth, WindowHeight);
#endif
```

The scene sweep (for UI windows) should run at startup when flag is active — iterate `CNewUIManager` windows and capture each. Ideally done in a dedicated `GroundTruthCapture::RunUISweep()` function called from `WinMain()` or `SceneManager` after initial load.

#### Naming Convention

Scene names for the sweep (consistent with Test Design reference):
- `login` — login screen
- `char_select` — character selection
- `main_hud` — in-game main HUD
- `inventory` — inventory window
- `{classname}` — for each `CNewUI*` window captured (use the class name without `CNewUI` prefix, snake_case)

#### CMake Flag Usage

```cmake
# CMakeLists.txt (in MuMain/)
option(ENABLE_GROUND_TRUTH_CAPTURE "Enable ground truth screenshot capture (Windows only, not for release)" OFF)
if(ENABLE_GROUND_TRUTH_CAPTURE)
    target_compile_definitions(MURenderFX PUBLIC ENABLE_GROUND_TRUTH_CAPTURE)
    # or whichever target includes GroundTruthCapture.cpp
endif()
```

Do NOT add the flag to CI build — it should only be enabled manually on Windows for baseline capture.

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, OpenGL (legacy — being removed), stb_image_write (new dependency for PNG)

**Prohibited (per project-context.md):**
- `new`/`delete` — use `std::unique_ptr`, `std::vector`
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()` or `g_ConsoleDebug->Write()`
- `#ifndef` header guards — use `#pragma once`
- `#ifdef _WIN32` in game logic — only in platform abstraction headers
- `timeGetTime()`, `GetTickCount()` — n/a for this story

**Required patterns (per project-context.md):**
- `std::filesystem::path` / `std::filesystem::create_directories` for path/directory operations
- `std::vector<unsigned char>` for pixel buffers (not raw `new[]`)
- `[[nodiscard]]` on `CaptureScene()` and `CompareTo()` (they return success/failure)
- `#pragma once` header guard
- `mu::` namespace for new code
- Allman brace style, 4-space indent, 120-column limit (enforced by `.clang-format`)
- Include order: preserve existing (SortIncludes: Never in clang-format)

**Quality gate:** `make -C MuMain format-check && make -C MuMain lint` — must pass 0 errors. Also validates via `./ctl check`.

**Testing:** Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK`. No mocking framework. SSIM tests must be pure logic (no OpenGL calls in tests). File: `tests/core/test_ground_truth.cpp`.

**References:**
- [Source: `_bmad-output/project-context.md`]
- [Source: `docs/architecture-rendering.md` — Current Pipeline, Migration Path sections]
- [Source: `docs/CROSS_PLATFORM_PLAN.md` — Session 9.4, Ground Truth spec]
- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.1.1]
- [Source: `MuMain/src/source/Scenes/SceneManager.cpp:210` — existing CaptureScreenshot()]
- [Source: `MuMain/src/source/Main/stdafx.h:237` — glReadPixels stub for non-Windows]
- [Source: `MuMain/tests/CMakeLists.txt` — MuTests target structure]

### Git Context (last 5 commits)

Sprint 4 is just starting. Last commits are sprint-3 completion and sprint-4 planning chores. No rendering code has been modified recently — the OpenGL codebase is in its original state. This is the **first story of EPIC-4**, so there are no prerequisite rendering stories to learn from.

The `glReadPixels` infrastructure already exists in `SceneManager.cpp` for the player screenshot feature, which is a good reference for the capture buffer pattern.

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_To be filled during development_

### Completion Notes List

_To be filled during development_

### File List

**Files to CREATE:**
- `MuMain/src/source/Platform/GroundTruthCapture.h`
- `MuMain/src/source/Platform/GroundTruthCapture.cpp`
- `MuMain/tests/core/test_ground_truth.cpp`
- `MuMain/src/ThirdParty/stb/stb_image_write.h` (if not already present)

**Files to MODIFY:**
- `MuMain/CMakeLists.txt` — add `option(ENABLE_GROUND_TRUTH_CAPTURE ...)` and conditional `target_compile_definitions`
- `MuMain/src/source/Scenes/SceneManager.cpp` — add `#ifdef ENABLE_GROUND_TRUTH_CAPTURE` capture instrumentation
- `MuMain/tests/CMakeLists.txt` — add `target_sources(MuTests PRIVATE core/test_ground_truth.cpp)`

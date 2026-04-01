---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-generation-mode', 'step-03-test-strategy', 'step-04-generate-tests']
lastStep: 'step-04-generate-tests'
lastSaved: '2026-04-01'
workflowType: 'testarch-atdd'
inputDocuments:
  - '_bmad-output/stories/7-9-7-adopt-glm-harden-matrix-pipeline/story.md'
  - 'MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp'
  - 'MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp'
  - 'MuMain/src/source/RenderFX/MuRenderer.h'
  - 'MuMain/tests/CMakeLists.txt'
  - 'MuMain/CMakeLists.txt'
  - '_bmad/tea/testarch/knowledge/test-quality.md'
  - '_bmad/tea/testarch/knowledge/test-levels-framework.md'
  - '_bmad/tea/testarch/knowledge/test-priorities-matrix.md'
  - '_bmad/tea/testarch/knowledge/test-healing-patterns.md'
  - '_bmad/tea/testarch/knowledge/data-factories.md'
---

# ATDD Checklist - Epic 7, Story 7.9.7: Adopt GLM and Harden Renderer Matrix Pipeline

**Date:** 2026-04-01
**Author:** Paco
**Primary Test Level:** Unit + Build Verification (CMake Script)
**Story ID:** 7-9-7
**Flow Code:** VS0-RENDER-GLM-MATRIX

---

## Story Summary

Story 7-9-7 adopts GLM as the SDL_GPU renderer's matrix math library, replacing a hand-rolled `mat4::` namespace. The story also hardens the rendering pipeline by adding a depth buffer, fixing alpha discard propagation to the fragment shader, and correcting the fog uniform binding.

**As a** developer,
**I want** the SDL_GPU renderer to use GLM for all matrix math with correct depth conventions,
**So that** the 3D scene renders correctly on Metal/Vulkan/D3D12 (perspective, particles, terrain, fog, depth).

---

## Step 1: Preflight & Context Loading

### Stack Detection

**`test_stack_type`**: `auto` (from config)

**Scan results:**
- `MuMain/CMakeLists.txt` — CMake project with C++20
- `MuMain/tests/CMakeLists.txt` — Catch2 unit tests + CTest
- `MuMain/tests/build/*.cmake` — CMake script file-scan tests
- No `package.json` (root), no `playwright.config.*`, no `vite.config.*`
- No `pyproject.toml`, `go.mod`, etc.

**`detected_stack`** = `backend`

### Prerequisites Check

- ✅ Story approved with clear acceptance criteria (9 functional ACs + standard ACs)
- ✅ Test framework configured: `MuMain/tests/CMakeLists.txt` (Catch2 v3.7.1 via FetchContent)
- ✅ CMake script tests in `MuMain/tests/build/` (file-scan test pattern)
- ✅ Development environment available (macOS arm64 native build)

### Loaded Artifacts

- Story: `_bmad-output/stories/7-9-7-adopt-glm-harden-matrix-pipeline/story.md`
- Key source: `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` (2258 lines)
- Interface: `MuMain/src/source/RenderFX/MuRenderer.h`
- Perspective impl: `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` (lines 24-30)
- GLM config: `MuMain/CMakeLists.txt` lines 198-210

### TEA Config Flags

| Flag | Value |
|------|-------|
| `tea_use_playwright_utils` | `true` (not applicable — backend stack) |
| `tea_use_pactjs_utils` | `true` (not applicable — no microservices) |
| `tea_browser_automation` | `auto` (not applicable — backend stack) |
| `test_stack_type` | `auto` → resolved `backend` |

### Knowledge Fragments Loaded

- `test-quality.md` (core)
- `test-levels-framework.md` (core, backend)
- `test-priorities-matrix.md` (core, backend)
- `test-healing-patterns.md` (core)
- `data-factories.md` (core)

---

## Step 2: Generation Mode

**Mode selected:** AI Generation — `detected_stack = backend`. Backend projects always use AI generation from source code analysis. No browser recording or Playwright E2E applicable.

---

## Step 3: Test Strategy

### Acceptance Criteria → Test Scenarios

| AC | Status | Test Type | Priority | Phase |
|----|--------|-----------|----------|-------|
| AC-1: GLM FetchContent | DONE (Task 1) | CMake script file-scan | P1 | GREEN (regression) |
| AC-2: mat4:: deleted | DONE (Task 2) | CMake script file-scan | P1 | GREEN (regression) |
| AC-3: perspectiveRH_ZO / GLM_FORCE_DEPTH_ZERO_TO_ONE | DONE (Task 2.8) | CMake script file-scan | P0 | GREEN (regression) |
| AC-3: Depth buffer created | NOT DONE (Task 3) | CMake script file-scan | P0 | RED |
| AC-4: ortho 2D | DONE (Task 2.8) | CMake script file-scan | P1 | GREEN (regression) |
| AC-4/5: alpha discard propagated | NOT DONE (Task 4) | CMake script file-scan | P0 | RED |
| AC-7: SetAlphaFunc override | NOT DONE (Task 4) | CMake script file-scan | P0 | RED |
| AC-STD-2: Matrix unit tests | NOT DONE (Task 9) | Catch2 unit test | P1 | RED (missing test file) |
| AC-STD-11: Flow code | N/A | CMake script | P2 | GREEN |

### Test Level Selection (backend stack)

**Unit tests (Catch2):**
- Matrix math: perspective Z range [0,1], ortho NDC, matrix stack push/pop
- No GPU device required — test GLM math directly and via mock

**Build/Integration verification (CMake scripts):**
- File-scan tests verify source code structure and implementation patterns
- These run via `ctest --test-dir MuMain/tests/build`

**No E2E tests:** Pure backend C++ game client, no web UI, no REST API.

### Red Phase Requirements

Tests in RED phase must FAIL before implementation:
- `test_ac3_depth_buffer_created_7_9_7.cmake` → FAILS: `has_depth_stencil_target = false` still present
- `test_ac4_alpha_discard_propagated_7_9_7.cmake` → FAILS: `SetAlphaTest` doesn't update fog uniform
- `test_ac7_alpha_func_override_7_9_7.cmake` → FAILS: no `SetAlphaFunc` override in concrete class

---

## Acceptance Criteria

1. **AC-1:** GLM integrated via CMake FetchContent (header-only, no binary dependency)
2. **AC-2:** `mat4::` namespace fully replaced with `glm::` equivalents — no hand-rolled matrix math
3. **AC-3:** Perspective projection uses `GLM_FORCE_DEPTH_ZERO_TO_ONE` + `glm::perspective()` (Z [0,1])
4. **AC-3 (depth buffer):** Depth buffer created and attached to render pass
5. **AC-4:** Orthographic projection uses `glm::ortho` for 2D rendering
6. **AC-4/5:** Alpha discard: `SetAlphaTest(bool)` propagates to `m_fogUniform.alphaDiscardEnabled`
7. **AC-7:** `SetAlphaFunc(int, float)` override exists and updates `m_fogUniform.alphaThreshold`
8. **AC-STD-2:** Matrix math unit tests (perspective Z range, ortho NDC, push/pop) in Catch2
9. **AC-STD-11:** Flow code `VS0-RENDER-GLM-MATRIX` traceable in test files

---

## Failing Tests Created (RED Phase)

### CMake Script Tests — RED (3 tests)

**Files:** `MuMain/tests/build/test_ac3_depth_buffer_created_7_9_7.cmake`, `test_ac4_alpha_discard_propagated_7_9_7.cmake`, `test_ac7_alpha_func_override_7_9_7.cmake`

- ✅ **Test:** `test_ac3_depth_buffer_created_7_9_7`
  - **Status:** RED — `has_depth_stencil_target = false` present; no depth texture creation code
  - **Verifies:** AC-3 (depth buffer) — depth buffer created and attached to render pass

- ✅ **Test:** `test_ac4_alpha_discard_propagated_7_9_7`
  - **Status:** RED — `SetAlphaTest` only sets `m_alphaTestEnabled`; never updates `m_fogUniform.alphaDiscardEnabled`
  - **Verifies:** AC-4/5 — `SetAlphaTest(bool)` propagates alpha discard state to the GPU shader

- ✅ **Test:** `test_ac7_alpha_func_override_7_9_7`
  - **Status:** RED — No `SetAlphaFunc` override in `MuRendererSDLGpu` concrete class; inherited no-op from base
  - **Verifies:** AC-7 — `SetAlphaFunc(int, float)` override updates `m_fogUniform.alphaThreshold`

### CMake Script Tests — GREEN (regression, 5 tests)

**Files:** `test_ac1_glm_fetchcontent_7_9_7.cmake`, `test_ac2_mat4_namespace_deleted_7_9_7.cmake`, `test_ac3_glm_depth_convention_7_9_7.cmake`, `test_ac4_glm_ortho_2d_7_9_7.cmake`, `test_ac_std11_flow_code_7_9_7.cmake`

- ✅ **Test:** `test_ac1_glm_fetchcontent_7_9_7` — GREEN — GLM FetchContent present in CMakeLists.txt
- ✅ **Test:** `test_ac2_mat4_namespace_deleted_7_9_7` — GREEN — No `namespace mat4` in MuRendererSDLGpu.cpp
- ✅ **Test:** `test_ac3_glm_depth_convention_7_9_7` — GREEN — `GLM_FORCE_DEPTH_ZERO_TO_ONE` + `glm::perspective` present
- ✅ **Test:** `test_ac4_glm_ortho_2d_7_9_7` — GREEN — `glm::ortho` in MuRendererSDLGpu.cpp
- ✅ **Test:** `test_ac_std11_flow_code_7_9_7` — GREEN — flow code in test files

### Catch2 Unit Tests — RED (test file missing, 6 tests)

**File:** `MuMain/tests/render/test_matrix_math_7_9_7.cpp`

The test file does not exist yet (Task 9.1 not done). Adding it to `MuMain/tests/CMakeLists.txt` is required.

- ✅ **Test:** `AC-STD-2 [7-9-7]: glm::perspective produces Z [0,1] for near plane`
  - **Status:** RED (file missing) → GREEN after Task 9.1
  - **Verifies:** GLM depth convention — near plane maps to z=0 in NDC with GLM_FORCE_DEPTH_ZERO_TO_ONE

- ✅ **Test:** `AC-STD-2 [7-9-7]: glm::perspective produces Z [0,1] for far plane`
  - **Status:** RED (file missing) → GREEN after Task 9.1
  - **Verifies:** GLM depth convention — far plane maps to z=1 in NDC

- ✅ **Test:** `AC-STD-2 [7-9-7]: glm::ortho maps 2D screen corners to NDC`
  - **Status:** RED (file missing) → GREEN after Task 9.1
  - **Verifies:** AC-4 — 640×480 design space corners map to NDC [-1,1]

- ✅ **Test:** `AC-STD-2 [7-9-7]: matrix stack push preserves and pop restores state`
  - **Status:** RED (file missing) → GREEN after Task 9.1
  - **Verifies:** AC-2/Task 9.4 — PushMatrix/PopMatrix via IMuRenderer mock

- ✅ **Test:** `AC-STD-2 [7-9-7]: matrix stack translate accumulates correctly`
  - **Status:** RED (file missing) → GREEN after Task 9.1
  - **Verifies:** GLM translate integration via GetMatrix round-trip

- ✅ **Test:** `AC-STD-2 [7-9-7]: matrix stack depth capped at 16`
  - **Status:** RED (file missing) → GREEN after Task 9.1
  - **Verifies:** k_MatrixStackDepth=16 safety — overflow does not corrupt state

---

## Implementation Checklist

### Test: test_ac3_depth_buffer_created_7_9_7 (P0 — depth buffer)

**File:** `MuMain/tests/build/test_ac3_depth_buffer_created_7_9_7.cmake`

**Tasks to make this test pass:**
- [x] Task 3.1: Create `SDL_GPUTexture` with depth format (`SDL_GPU_TEXTUREFORMAT_D24_UNORM`) in `Init()`
- [x] Task 3.2: Pass depth texture as `SDL_GPUDepthStencilTargetInfo` to `SDL_BeginGPURenderPass()` (~line 726)
- [x] Task 3.3: Set `has_depth_stencil_target = true` in pipeline (~line 1867)
- [x] Task 3.4: Set depth clear to 1.0 with `SDL_GPU_LOADOP_CLEAR`
- [x] Task 3.5: Recreate depth texture on window resize
- [x] Run test: `ctest --test-dir MuMain/tests/build -R depth_buffer_created_7_9_7`
- [x] ✅ Test passes (green phase)

**Estimated Effort:** 3-4 hours

---

### Test: test_ac4_alpha_discard_propagated_7_9_7 (P0 — alpha discard)

**File:** `MuMain/tests/build/test_ac4_alpha_discard_propagated_7_9_7.cmake`

**Tasks to make this test pass:**
- [x] Task 4.1: Update `SetAlphaTest(bool enabled)` to set `m_fogUniform.alphaDiscardEnabled = enabled ? 1u : 0u`
- [x] Task 4.1: Set `s_fogDirty = true` in `SetAlphaTest`
- [x] Run test: `ctest --test-dir MuMain/tests/build -R alpha_discard_propagated_7_9_7`
- [x] ✅ Test passes (green phase)

**Estimated Effort:** 1 hour

---

### Test: test_ac7_alpha_func_override_7_9_7 (P0 — fog alpha threshold)

**File:** `MuMain/tests/build/test_ac7_alpha_func_override_7_9_7.cmake`

**Tasks to make this test pass:**
- [x] Task 4.2: Add `SetAlphaFunc(int func, float ref)` override to `MuRendererSDLGpu` concrete class
- [x] Task 4.2: Update `m_fogUniform.alphaThreshold = ref` and `s_fogDirty = true` in `SetAlphaFunc`
- [x] Run test: `ctest --test-dir MuMain/tests/build -R alpha_func_override_7_9_7`
- [x] ✅ Test passes (green phase)

**Estimated Effort:** 1 hour

---

### Test: test_matrix_math_7_9_7 (P1 — matrix unit tests)

**File:** `MuMain/tests/render/test_matrix_math_7_9_7.cpp`

**Tasks to make this test pass:**
- [x] Task 9.1: Create `MuMain/tests/render/test_matrix_math_7_9_7.cpp`
- [x] Task 9.1: Add `target_sources(MuTests PRIVATE render/test_matrix_math_7_9_7.cpp)` to `MuMain/tests/CMakeLists.txt`
- [x] Task 9.2: Verify perspective Z range [0,1] tests pass (GLM already integrated)
- [x] Task 9.3: Verify ortho NDC mapping tests pass
- [x] Task 9.4: Verify matrix stack push/pop tests pass
- [x] Run test: `./ctl test` (or `ctest --test-dir MuMain/build -R matrix_math_7_9_7`)
- [x] ✅ All 7 tests pass (green phase)

**Estimated Effort:** 2 hours

---

## Running Tests

```bash
# Run all 7-9-7 cmake script tests (build dir)
ctest --test-dir MuMain/tests/build -R 7_9_7 --output-on-failure

# Run Catch2 unit tests
ctest --test-dir MuMain/build -R matrix_math_7_9_7 --output-on-failure

# Full quality gate (format + lint + all tests)
./ctl check

# Run specific RED phase tests
ctest --test-dir MuMain/tests/build -R "depth_buffer_created|alpha_discard|alpha_func" --output-on-failure
```

---

## Red-Green-Refactor Workflow

### RED Phase (TEA Agent — Complete) ✅

**TEA Agent Responsibilities:**

- ✅ All tests written and failing (3 RED cmake + 1 RED cpp file)
- ✅ Regression tests document already-implemented ACs (5 GREEN cmake)
- ✅ Implementation checklist created
- ✅ CMakeLists.txt entry for Catch2 test file documented

**Verification:**

- CMake RED tests: run `ctest --test-dir MuMain/tests/build -R 7_9_7` — expect 3 failures, 5 passes
- Catch2 RED: test file doesn't exist → CTest skips it until Task 9.1 adds it

---

### GREEN Phase (DEV Team — Next Steps)

1. **Task 3** (highest priority): Add depth buffer — fixes `has_depth_stencil_target = false`
2. **Task 4** (critical): Fix alpha discard — `SetAlphaTest` → fog uniform, add `SetAlphaFunc` override
3. **Task 9**: Add `test_matrix_math_7_9_7.cpp` and CMakeLists entry
4. After each task: run `ctest --test-dir MuMain/tests/build -R 7_9_7` to verify tests go green
5. **When all tests pass**: run `./ctl check` for full quality gate

---

### REFACTOR Phase (DEV Team — After All Tests Pass)

1. Verify all 8 cmake tests pass + all 6 Catch2 tests pass
2. Run `./ctl check` — 0 clang-format errors, 0 cppcheck errors
3. Update story status to `done` in sprint-status.yaml

---

## Next Steps

1. **Begin Task 3** (depth buffer) — highest priority, unblocks particle + terrain rendering
2. **Begin Task 4** (alpha discard) — fixes orange particle rectangles
3. **Add matrix unit tests** (Task 9) — concurrent with Tasks 3+4
4. Run tests after each task: `ctest --test-dir MuMain/tests/build -R 7_9_7`
5. Tasks 5-8 follow (fog binding, particle billboard, terrain, shader blobs)
6. **When all tests pass**: refactor, then update story to `done`

---

## Knowledge Base References Applied

- **test-quality.md** — deterministic tests, explicit assertions, isolation
- **test-levels-framework.md** — unit + build verification for backend C++ project
- **test-priorities-matrix.md** — P0 for depth buffer + alpha discard (critical rendering path)
- **data-factories.md** — not applicable (no runtime data; GLM math tested directly)
- **test-healing-patterns.md** — cmake test `FATAL_ERROR` pattern for clear failure messages

---

## Test Execution Evidence

### RED Phase Tests (before implementation)

**Expected output:**
```
Expected failure - test_ac3_depth_buffer_created_7_9_7:
  AC-3 FAIL: 'has_depth_stencil_target = false' still present in MuRendererSDLGpu.cpp.
  Task 3.3: Change line ~1867 to 'has_depth_stencil_target = true'.

Expected failure - test_ac4_alpha_discard_propagated_7_9_7:
  AC-4 FAIL: SetAlphaTest does not propagate to m_fogUniform.alphaDiscardEnabled.
  Task 4.1: Update SetAlphaTest() to set m_fogUniform.alphaDiscardEnabled.

Expected failure - test_ac7_alpha_func_override_7_9_7:
  AC-7 FAIL: No SetAlphaFunc override found in MuRendererSDLGpu.cpp concrete class.
  Task 4.2: Add SetAlphaFunc override that updates m_fogUniform.alphaThreshold.
```

**Summary:**
- Total CMake tests: 8 (3 RED + 5 GREEN regression)
- Total Catch2 tests: 6 (RED — file missing)
- Status: ✅ RED phase designed

---

## Generated by BMad TEA Agent — 2026-04-01

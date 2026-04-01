# ATDD Checklist — Story 7-9-7: Adopt GLM and Harden Renderer Matrix Pipeline

**Story**: 7-9-7 | **Flow Code**: VS0-RENDER-GLM-MATRIX | **Type**: infrastructure
**Generated**: 2026-04-01 | **Framework**: Catch2 v3.7.1 + CMake script tests

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries used | None — GLM (MIT, header-only) is approved |
| Required testing framework | Catch2 v3.7.1 via FetchContent ✓ |
| No Win32 in test TUs | ✓ — all tests are pure math / static analysis |
| No raw new/delete in tests | ✓ — no allocations in test files |
| AC-N: prefix on all test cases | ✓ — all TEST_CASE names include AC-STD-2 prefix |
| Coverage target | 0% threshold (project-context.md — growing incrementally) |

---

## AC-to-Test Mapping

| AC | Description | Test Type | Test File / Test Name | Phase |
|----|-------------|-----------|----------------------|-------|
| AC-1 | GLM integrated via FetchContent | cmake-script | `tests/build/test_ac1_glm_fetchcontent_7_9_7.cmake` | GREEN (Task 1 done) |
| AC-2 | mat4:: namespace deleted, glm::mat4 in use | cmake-script | `tests/build/test_ac2_mat4_namespace_deleted_7_9_7.cmake` | GREEN (Task 2 done) |
| AC-3 (GLM convention) | GLM_FORCE_DEPTH_ZERO_TO_ONE + glm::perspective | cmake-script | `tests/build/test_ac3_glm_depth_convention_7_9_7.cmake` | GREEN (Task 2.8+2.11 done) |
| AC-3 (depth buffer) | Depth texture created, has_depth_stencil_target=true | cmake-script | `tests/build/test_ac3_depth_buffer_created_7_9_7.cmake` | RED (Task 3 pending) |
| AC-4 (ortho) | glm::ortho used in 2D render path | cmake-script | `tests/build/test_ac4_glm_ortho_2d_7_9_7.cmake` | GREEN (Task 2 done) |
| AC-4/5 (alpha discard) | SetAlphaTest propagates to GPU fog uniform | cmake-script | `tests/build/test_ac4_alpha_discard_propagated_7_9_7.cmake` | RED (Task 4.1 pending) |
| AC-7 | SetAlphaFunc override updates alphaThreshold | cmake-script | `tests/build/test_ac7_alpha_func_override_7_9_7.cmake` | RED (Task 4.2 pending) |
| AC-STD-2 | Matrix math unit tests — perspective Z [0,1] | Catch2 | `tests/render/test_matrix_math_7_9_7.cpp` → `"AC-STD-2 [7-9-7]: glm::perspective produces Z [0,1] for near plane"` | GREEN once compiled |
| AC-STD-2 | Matrix math unit tests — perspective far plane | Catch2 | `tests/render/test_matrix_math_7_9_7.cpp` → `"AC-STD-2 [7-9-7]: glm::perspective produces Z [0,1] for far plane"` | GREEN once compiled |
| AC-STD-2 | Matrix math — ortho corner mapping | Catch2 | `tests/render/test_matrix_math_7_9_7.cpp` → `"AC-STD-2 [7-9-7]: glm::ortho maps 2D screen corners to NDC"` | GREEN once compiled |
| AC-STD-2 | Matrix math — ortho Z range | Catch2 | `tests/render/test_matrix_math_7_9_7.cpp` → `"AC-STD-2 [7-9-7]: glm::ortho Z is flat [0,1] range at z=0"` | GREEN once compiled |
| AC-STD-2 | Matrix stack push/pop counts | Catch2 | `tests/render/test_matrix_math_7_9_7.cpp` → `"AC-STD-2 [7-9-7]: matrix stack push preserves and pop restores state"` | GREEN once compiled |
| AC-STD-2 | Matrix stack SetMatrixMode routing | Catch2 | `tests/render/test_matrix_math_7_9_7.cpp` → `"AC-STD-2 [7-9-7]: matrix stack SetMatrixMode routes to modelview or projection"` | GREEN once compiled |
| AC-STD-2 | Depth convention consistency check | Catch2 | `tests/render/test_matrix_math_7_9_7.cpp` → `"AC-STD-2 [7-9-7]: GLM_FORCE_DEPTH_ZERO_TO_ONE changes depth mapping"` | GREEN once compiled |
| AC-STD-11 | Flow code traceability VS0-RENDER-GLM-MATRIX | cmake-script | `tests/build/test_ac_std11_flow_code_7_9_7.cmake` | GREEN |

---

## Implementation Checklist

All items must be `[x]` before story transitions to `done`.

### AC-1: GLM FetchContent Integration
- [ ] GLM integrated via `FetchContent_Declare(glm ...)` in `MuMain/CMakeLists.txt`
- [ ] `FetchContent_MakeAvailable(glm)` called
- [ ] `glm::glm` added to `target_link_libraries` for MURenderFX
- [ ] `cmake-script AC-1` test passes

### AC-2: mat4:: Namespace Deleted
- [ ] `namespace mat4 {}` block deleted from `MuRendererSDLGpu.cpp`
- [ ] No `mat4::` call sites remain in renderer
- [ ] `glm::mat4` type used for matrix stack members
- [ ] `cmake-script AC-2` test passes

### AC-3: Correct Depth Convention (GLM)
- [ ] `#define GLM_FORCE_DEPTH_ZERO_TO_ONE` added before glm includes in `ZzzOpenglUtil.cpp`
- [ ] `#define GLM_FORCE_DEPTH_ZERO_TO_ONE` added before glm includes in `MuRendererSDLGpu.cpp`
- [ ] `glm::perspective()` used (not hand-rolled trig) in `ZzzOpenglUtil.cpp`
- [ ] `GLM_FORCE_LEFT_HANDED` absent from renderer (right-handed convention)
- [ ] `cmake-script AC-3 (GLM convention)` test passes

### AC-3: Depth Buffer Created
- [ ] `SDL_GPUTexture` with `SDL_GPU_TEXTUREFORMAT_D24_UNORM` (or D32_FLOAT) created in `Init()`
- [ ] `SDL_GPUDepthStencilTargetInfo` passed to `SDL_BeginGPURenderPass()` (not `nullptr`)
- [ ] `has_depth_stencil_target = true` in `BuildBlendPipeline()` (~line 1867)
- [ ] Depth clear set to 1.0 with `SDL_GPU_LOADOP_CLEAR`
- [ ] Depth texture recreated on window resize
- [ ] `cmake-script AC-3 (depth buffer)` test passes

### AC-4: Orthographic Projection (GLM)
- [ ] `glm::ortho()` used in 2D render path (`BeginScene` / `Begin2DPass`)
- [ ] No hand-rolled ortho matrix computation remains
- [ ] `cmake-script AC-4 (ortho)` test passes

### AC-4/5: Alpha Discard Propagated
- [ ] `SetAlphaTest(bool enabled)` override updates `m_fogUniform.alphaDiscardEnabled = enabled ? 1u : 0u`
- [ ] `SetAlphaTest()` sets `s_fogDirty = true`
- [ ] `cmake-script AC-4 (alpha discard)` test passes

### AC-7: Fog Alpha Func Override
- [ ] `SetAlphaFunc(int func, float ref)` override added to `MuRendererSDLGpu` concrete class
- [ ] Override updates `m_fogUniform.alphaThreshold = ref`
- [ ] Override sets `s_fogDirty = true`
- [ ] `cmake-script AC-7` test passes

### AC-STD-2: Matrix Math Unit Tests
- [ ] `tests/render/test_matrix_math_7_9_7.cpp` added to `tests/CMakeLists.txt` → `target_sources(MuTests ...)` ✓ (already done)
- [ ] `tests/build/CMakeLists.txt` has all 8 `add_test()` entries for 7.9.7 ✓ (already done)
- [ ] All 7 Catch2 TEST_CASEs in `test_matrix_math_7_9_7.cpp` pass: `ctest -R 7-9-7`
- [ ] No prohibited libraries in test TU (GLM only — approved)
- [ ] No Win32 / OpenGL / GPU device calls in test TU

### AC-STD-13: Quality Gate
- [ ] `./ctl check` passes (clang-format + cppcheck, 0 errors)
- [ ] No `namespace mat4` remains anywhere in source
- [ ] No `#ifdef _WIN32` added outside `Platform/` layer

### AC-STD-11: Flow Code Traceability
- [ ] Flow code `VS0-RENDER-GLM-MATRIX` in commit message(s)
- [ ] `cmake-script AC-STD-11` test passes

### Bruno / API Collection
Not applicable — `infrastructure` story type, no API endpoints.

### PCC Compliance
- [ ] No prohibited libraries (no raw OpenGL headers in new code, no Win32 in new code)
- [ ] Required patterns followed (Catch2, `REQUIRE`/`CHECK` macros, `TEST_CASE`/`SECTION`)
- [ ] No mocking framework used (MatrixMath797Mock is a hand-rolled stub, not a mock framework)
- [ ] Coverage threshold met (0% minimum — see project-context.md)

---

## Test Files Created (RED Phase)

| File | Type | State |
|------|------|-------|
| `MuMain/tests/build/test_ac1_glm_fetchcontent_7_9_7.cmake` | cmake-script | GREEN (Task 1 done) |
| `MuMain/tests/build/test_ac2_mat4_namespace_deleted_7_9_7.cmake` | cmake-script | GREEN (Task 2 done) |
| `MuMain/tests/build/test_ac3_glm_depth_convention_7_9_7.cmake` | cmake-script | GREEN (Tasks 2.8+2.11 done) |
| `MuMain/tests/build/test_ac3_depth_buffer_created_7_9_7.cmake` | cmake-script | RED (Task 3 pending) |
| `MuMain/tests/build/test_ac4_glm_ortho_2d_7_9_7.cmake` | cmake-script | GREEN (Task 2 done) |
| `MuMain/tests/build/test_ac4_alpha_discard_propagated_7_9_7.cmake` | cmake-script | RED (Task 4.1 pending) |
| `MuMain/tests/build/test_ac7_alpha_func_override_7_9_7.cmake` | cmake-script | RED (Task 4.2 pending) |
| `MuMain/tests/build/test_ac_std11_flow_code_7_9_7.cmake` | cmake-script | GREEN |
| `MuMain/tests/render/test_matrix_math_7_9_7.cpp` | Catch2 unit | GREEN once compiled |

**Total**: 8 cmake script tests + 7 Catch2 TEST_CASEs = 15 test assertions covering 9 ACs

---

## Handoff Contract (→ dev-story)

| Output | Value |
|--------|-------|
| `atdd_checklist_path` | `_bmad-output/stories/7-9-7-adopt-glm-harden-matrix-pipeline/atdd.md` |
| `test_files_created` | 9 files (see table above) |
| `implementation_checklist_complete` | FALSE — 3 RED phase tests remain (Tasks 3+4) |
| `ac_test_mapping` | See AC-to-Test Mapping table above |

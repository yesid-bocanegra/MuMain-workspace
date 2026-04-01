# Test Scenarios: Story 7-9-7 — Adopt GLM and Harden Renderer Matrix Pipeline

**Story ID:** 7-9-7
**Flow Code:** VS0-RENDER-GLM-MATRIX
**Date:** 2026-04-01

---

## Automated Tests (15 total)

### Catch2 Unit Tests (7 tests)

**File:** `MuMain/tests/render/test_matrix_math_7_9_7.cpp`

| # | Test Name | AC | Validates |
|---|-----------|-----|-----------|
| 1 | glm::perspective produces Z [0,1] for near plane | AC-3 | Near plane maps to NDC z=0 with GLM_FORCE_DEPTH_ZERO_TO_ONE |
| 2 | glm::perspective produces Z [0,1] for far plane | AC-3 | Far plane maps to NDC z=1 |
| 3 | glm::ortho maps 2D screen corners to NDC | AC-4 | 640x480 design space corners map to NDC [-1,1] |
| 4 | glm::ortho Z is flat [0,1] range at z=0 | AC-4 | Ortho depth convention matches Metal/Vulkan |
| 5 | matrix stack push preserves and pop restores state | AC-2 | PushMatrix/PopMatrix via IMuRenderer mock |
| 6 | matrix stack SetMatrixMode routes correctly | AC-2 | GL_MODELVIEW/GL_PROJECTION mode switching |
| 7 | GLM_FORCE_DEPTH_ZERO_TO_ONE changes depth mapping | AC-3 | Depth define actually affects perspective matrix output |

**Run:** `ctest --test-dir MuMain/out/build/macos-arm64/tests -C Debug -R "7.9.7" --output-on-failure`

### CMake Script Tests (8 tests)

**Directory:** `MuMain/tests/build/`

| # | Test Name | AC | Validates |
|---|-----------|-----|-----------|
| 1 | AC-1:glm-fetchcontent | AC-1 | GLM FetchContent declared in CMakeLists.txt |
| 2 | AC-2:mat4-namespace-deleted | AC-2 | No `namespace mat4` remains in MuRendererSDLGpu.cpp |
| 3 | AC-3:glm-depth-convention | AC-3 | GLM_FORCE_DEPTH_ZERO_TO_ONE defined + glm::perspective used |
| 4 | AC-3:depth-buffer-created | AC-3 | has_depth_stencil_target = true and depth texture creation |
| 5 | AC-4:glm-ortho-2d | AC-4 | glm::ortho present in MuRendererSDLGpu.cpp |
| 6 | AC-4:alpha-discard-propagated | AC-5 | SetAlphaTest updates m_fogUniform.alphaDiscardEnabled |
| 7 | AC-7:alpha-func-override | AC-7 | SetAlphaFunc override exists with alphaThreshold update |
| 8 | AC-STD-11:flow-code-traceability | AC-STD-11 | Flow code VS0-RENDER-GLM-MATRIX in test files |

---

## Manual Visual Test Scenarios

### VS-1: 3D Scene Depth (AC-3)

**Prerequisites:** Game client running with SDL_GPU renderer on macOS/Metal

**Steps:**
1. Launch game, log in to any server
2. Enter a map with multi-level architecture (e.g., Lorencia, Noria)
3. Walk around buildings and observe rendering

**Expected:** Objects at different depths render in correct order. No z-fighting or geometry overlap. Near geometry occludes far geometry.

### VS-2: Loading Screen / Login UI (AC-4)

**Steps:**
1. Launch game
2. Observe loading screen rendering
3. Navigate to login screen

**Expected:** 2D UI elements (loading bar, login form, buttons) render at correct positions and scale. No distortion or offset from the 640x480 design space.

### VS-3: Particle Effects (AC-5)

**Steps:**
1. Enter a map with fire effects or light sources
2. Observe torch flames, glow halos, and particle bursts
3. Move camera around to verify billboard orientation

**Expected:** Particles render as camera-facing alpha-masked sprites (not opaque rectangles). Fire looks like fire, not orange boxes.

### VS-4: Terrain Rendering (AC-6)

**Steps:**
1. Enter any outdoor map (Lorencia, Devias, Noria)
2. Walk across terrain, observing ground coverage
3. Look for holes or missing ground patches

**Expected:** Terrain covers the full ground area. No visible gaps between terrain tiles. Terrain renders at correct depth behind buildings/characters.

### VS-5: Fog Effect (AC-7)

**Steps:**
1. Enter a map where fog is enabled by game code
2. Walk from a clear area toward the fog distance
3. Observe gradual fog blending

**Expected:** Objects fade into fog color as distance increases. Fog factor computed from eye-space distance (clip-space w). No abrupt fog transitions.

### VS-6: Shader Blob Verification (AC-9)

**Steps:**
1. Build with MinGW cross-compiler (offline — no shader compilation available)
2. Launch and verify 3D scene renders

**Expected:** Pre-compiled SPIR-V and MSL blobs load correctly. Rendering matches native macOS build (which compiles shaders at runtime).

---

## Edge Cases

| Scenario | AC | Test Type | Expected Behavior |
|----------|-----|-----------|-------------------|
| Window resize during 3D scene | AC-3, AC-8 | Manual | Depth texture recreated, no depth artifacts |
| Rapid alpha test toggling | AC-5 | Unit | fog uniform dirty flag tracks rapid on/off correctly |
| Matrix stack overflow (>16 deep) | AC-2 | Unit (test 5) | Stack depth capped at 16, no corruption |
| Zero-size fog range (fogStart == fogEnd) | AC-7 | Edge case | No division by zero, fog factor clamped |

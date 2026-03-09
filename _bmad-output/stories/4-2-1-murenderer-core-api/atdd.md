# ATDD Implementation Checklist: Story 4.2.1 - MuRenderer Core API with OpenGL Backend

**Story ID:** 4-2-1-murenderer-core-api
**Story Type:** infrastructure
**Date Generated:** 2026-03-09
**Primary Test Level:** Catch2 unit tests (pure logic — no OpenGL calls in test TU)

---

## PCC Compliance Summary

| Check | Result | Notes |
|-------|--------|-------|
| Framework | Catch2 v3.7.1 | infrastructure story — unit tests via Catch2 |
| Prohibited libraries | None used | No raw `new`/`delete`, no `NULL`, no `wprintf`, no `#ifndef` guards |
| No OpenGL in test TU | Required | `test_murenderer.cpp` includes no GL headers; `BlendModeTracker` is pure C++ |
| No `#ifdef _WIN32` in game logic | Required | OpenGL stubs in `stdafx.h` handle non-Windows compile of `MuRenderer.cpp` |
| No raw `new`/`delete` | Required | `std::stack<Matrix4x4>` in `MatrixStack`, `std::unique_ptr` elsewhere |
| `[[nodiscard]]` on getters | Required | `GetRenderer()`, `MatrixStack::Top()`, `MatrixStack::IsEmpty()` |
| `namespace mu` | Required | All types: `mu::IMuRenderer`, `mu::BlendMode`, `mu::MatrixStack`, `mu::Matrix4x4` |
| `#pragma once` headers | Required | Both `MuRenderer.h` and `MatrixStack.h` |
| No GLenum/GLuint in MuRenderer.h | Required | Interface uses only project-defined types (BlendMode enum, FogParams struct, Vertex2D/3D structs) |
| Coverage target | N/A | Minimal baseline — growing incrementally per project-context.md |
| Bruno/Playwright | NOT applicable | infrastructure story, no API endpoints, no UI |

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Status |
|----|-------------|-----------|-----------|--------|
| AC-1 | `IMuRenderer` interface with 6 core functions | `tests/render/test_murenderer.cpp` | `AC-1 [4-2-1]: IMuRenderer interface has all required methods` | RED |
| AC-2 | `MuRendererGL` implements `IMuRenderer` via OpenGL | Manual validation (no OpenGL in test TU) | — compile check via stubs | RED |
| AC-3 | `MuRenderer::GetInstance()` returns singleton `IMuRenderer&` | `tests/render/test_murenderer.cpp` | Covered by AC-VAL-2 interface compile check | RED |
| AC-4 | `MatrixStack` push/pop/translate; replaces `glPush/PopMatrix` | `tests/render/test_murenderer.cpp` | `AC-4 [4-2-1]: MatrixStack push/pop correctness` (3 TEST_CASEs + IsEmpty) | RED |
| AC-5 | All new code in `mu::` namespace; CMake target `MURenderFX` | `tests/render/test_murenderer.cpp` | `AC-5 [4-2-1]: All new types are in mu:: namespace` | RED |
| AC-6 | No existing game logic files modified | Static verification (no test needed) | Check `git diff --name-only` — no files outside `RenderFX/` and `tests/render/` | N/A |
| AC-STD-2 | Catch2 tests: `MatrixStack` push/pop, balanced ops, `SetBlendMode` round-trip | `tests/render/test_murenderer.cpp` | All `TEST_CASE` blocks | RED |
| AC-STD-3 | OpenGL calls only in `MuRenderer.cpp`, not in `MuRenderer.h` | `tests/render/test_murenderer.cpp` | `AC-VAL-2 [4-2-1]: IMuRenderer interface has no OpenGL types` (compile check) | RED |
| AC-VAL-1 | Catch2 tests pass for `MatrixStack` and blend mode state tracking | `tests/render/test_murenderer.cpp` | All 8 `TEST_CASE` blocks pass GREEN | RED |
| AC-VAL-2 | `MuRenderer.h` reviewed for SDL_gpu backend compatibility (no OpenGL types in interface) | `tests/render/test_murenderer.cpp` | `AC-VAL-2 [4-2-1]: IMuRenderer interface has no OpenGL types` | RED |
| AC-VAL-3 | `./ctl check` passes 0 errors after new files added | CI quality gate | `./ctl check` | RED |

---

## Implementation Checklist

### Task 1: Define `IMuRenderer` interface and supporting types (AC-1, AC-5)

- [x] Create `MuMain/src/source/RenderFX/MuRenderer.h`
- [x] Add `#pragma once` guard (no `#ifndef` per project standard)
- [x] Add includes: `<cstdint>`, `<span>` — no GL headers in this file
- [x] Define `namespace mu {` wrapper for all types
- [x] Define `enum class BlendMode : std::uint8_t` with 6 values: `Alpha`, `Additive`, `Subtract`, `InverseColor`, `Mixed`, `LightMap`
- [x] Define `struct FogParams` with members: `int mode`, `float start`, `float end`, `float density`, `float color[4]`
- [x] Define `struct Vertex2D` with members: `float x, y, u, v`, `std::uint32_t color`
- [x] Define `struct Vertex3D` with members: `float x, y, z, nx, ny, nz, u, v`, `std::uint32_t color`
- [x] Declare `class IMuRenderer` as pure abstract with `virtual ~IMuRenderer() = default`
- [x] Declare all 6 pure virtual methods: `RenderQuad2D(std::span<const Vertex2D>, std::uint32_t)`, `RenderTriangles(std::span<const Vertex3D>, std::uint32_t)`, `RenderQuadStrip(std::span<const Vertex3D>, std::uint32_t)`, `SetBlendMode(BlendMode)`, `SetDepthTest(bool)`, `SetFog(const FogParams&)`
- [x] Declare `[[nodiscard]] IMuRenderer& GetRenderer()` free function in `mu::` namespace
- [x] Verify NO `GLenum`, `GLuint`, `GLint`, or any `gl` type in the header

### Task 2: Implement `MuRendererGL` OpenGL backend (AC-2, AC-3)

- [x] Create `MuMain/src/source/RenderFX/MuRenderer.cpp`
- [x] Includes in order: `#include "stdafx.h"`, `#include "MuRenderer.h"`, `#include "ErrorReport.h"` (no other GL headers — `stdafx.h` provides OpenGL stubs on non-Windows)
- [x] Declare `class MuRendererGL : public mu::IMuRenderer` (within `mu::` namespace)
- [x] Implement `RenderQuad2D()` using `glBegin(GL_QUADS)` / `glEnd()` with `glTexCoord2f` / `glVertex3f` per vertex
- [x] Implement `RenderTriangles()` using `glBegin(GL_TRIANGLES)` / `glEnd()` loop over vertex span
- [x] Implement `RenderQuadStrip()` using `glBegin(GL_QUAD_STRIP)` / `glEnd()` loop
- [x] Implement `SetBlendMode()` — translate `BlendMode` enum to GL factor pairs (see Blend Mode table in story)
- [x] Implement `SetDepthTest(bool)` — `glEnable`/`glDisable(GL_DEPTH_TEST)` + `glDepthFunc(GL_LEQUAL)`
- [x] Implement `SetFog(const FogParams&)` — `glFogi`/`glFogf`/`glFogfv` calls
- [x] Implement `GetRenderer()` returning static `MuRendererGL` instance
- [x] Add `g_ErrorReport.Write(L"RENDER: MuRenderer::%hs -- %s", ...)` on all failure paths
- [x] Verify NO `#ifdef _WIN32` anywhere in the file

### Task 3: Implement `MatrixStack` (AC-4, AC-5)

- [x] Create `MuMain/src/source/RenderFX/MatrixStack.h`
- [x] Add `#pragma once` guard
- [x] Add includes: `<array>`, `<stack>` — no GL headers
- [x] Define `namespace mu {` wrapper
- [x] Define `struct Matrix4x4` with `float m[16]` (column-major matching OpenGL layout: m[12..14]=translation), identity default constructor, `operator*(const Matrix4x4&) const`
- [x] Declare `class MatrixStack` in `mu::` namespace
- [x] Declare public API: `MatrixStack()` (initializes with one identity matrix), `void Push()`, `void Pop()`, `void Translate(float x, float y, float z)`, `[[nodiscard]] const Matrix4x4& Top() const`, `[[nodiscard]] bool IsEmpty() const`
- [x] Declare private member: `std::stack<Matrix4x4> m_stack`
- [x] Create `MuMain/src/source/RenderFX/MatrixStack.cpp`
- [x] Includes in order: `#include "stdafx.h"`, `#include "MatrixStack.h"`
- [x] Implement `Matrix4x4` identity constructor: diagonal elements = 1.0f, all others = 0.0f
- [x] Implement `Matrix4x4::operator*` as column-major 4x4 matrix multiplication
- [x] Implement `MatrixStack()`: push one identity matrix onto `m_stack` (stack is never empty after construction)
- [x] Implement `Push()`: copy `m_stack.top()` and push onto stack
- [x] Implement `Pop()`: discard top (do not pop if only one entry remains — guard against underflow)
- [x] Implement `Translate(x, y, z)`: create translation matrix T; multiply `m_stack.top() = m_stack.top() * T`; translation at T[12]=x, T[13]=y, T[14]=z (column-major)
- [x] Implement `Top() const`: return `m_stack.top()`
- [x] Implement `IsEmpty() const`: return `m_stack.empty()`

### Task 4: Catch2 tests (AC-STD-2, AC-VAL-1)

- [x] Verify `tests/render/` directory exists (created as part of ATDD)
- [x] Verify `MuMain/tests/render/test_murenderer.cpp` exists (created in RED phase)
- [x] Verify `target_sources(MuTests PRIVATE render/test_murenderer.cpp)` added to `tests/CMakeLists.txt` (done in ATDD)
- [x] Confirm test file has NO `#include` of any GL headers (`gl.h`, `glew.h`, etc.)
- [x] Confirm `BlendModeTracker` test-double implements all 6 `IMuRenderer` methods
- [x] Confirm `TEST_CASE("AC-4 [4-2-1]: MatrixStack push/pop correctness", ...)` tests push, translate, pop, restore
- [x] Confirm `TEST_CASE("AC-4 [4-2-1]: MatrixStack balanced push/pop depth", ...)` tests 5 push/pop cycles
- [x] Confirm `TEST_CASE("AC-4 [4-2-1]: MatrixStack nested translations accumulate", ...)` tests cumulative translation
- [x] Confirm `TEST_CASE("AC-STD-2 [4-2-1]: BlendMode state tracking round-trip", ...)` tests all 6 BlendMode values + change
- [x] Confirm `TEST_CASE("AC-1 [4-2-1]: IMuRenderer interface has all required methods", ...)` calls all 6 interface methods
- [x] Confirm `TEST_CASE("AC-5 [4-2-1]: All new types are in mu:: namespace", ...)` checks namespace qualification
- [x] Confirm `TEST_CASE("AC-VAL-2 [4-2-1]: IMuRenderer interface has no OpenGL types", ...)` is compile-time check
- [x] Confirm `TEST_CASE("AC-4 [4-2-1]: MatrixStack IsEmpty reflects stack depth", ...)` tests IsEmpty()

### Task 5: Quality gate and validation (AC-STD-13, AC-VAL-3)

- [x] Run `./ctl check` — clang-format check + cppcheck — 0 errors (705 files checked, 0 violations)
- [x] Verify no `#ifdef _WIN32` in `MuRenderer.cpp` or `MatrixStack.cpp`
- [x] Verify no `GLenum`, `GLuint`, `GLint` in `MuRenderer.h`
- [x] Verify no `glBegin`, `glEnd`, etc. in `MuRenderer.h` (interface header)
- [x] Verify OpenGL calls ONLY in `MuRenderer.cpp` (implementation file)
- [x] Commit: `feat(render): create MuRenderer abstraction with OpenGL backend`

### Standard Acceptance Criteria

- [x] AC-STD-1: Code follows project standards — `namespace mu`, `#pragma once`, no `#ifdef _WIN32` in game logic, `std::span<const T>` for vertex params, `nullptr`, PascalCase methods, `m_` member prefix with Hungarian hints
- [x] AC-STD-2: Catch2 tests in `tests/render/test_murenderer.cpp` — 8 `TEST_CASE` blocks covering `MatrixStack` and `BlendMode` tracking
- [x] AC-STD-3: OpenGL calls appear ONLY in `MuRenderer.cpp`; verified by `test_murenderer.cpp` compiling without GL headers
- [x] AC-STD-5: Error logging via `g_ErrorReport.Write(L"RENDER: MuRenderer::%hs -- %s", ...)` on all failure paths in `MuRenderer.cpp`
- [x] AC-STD-6: Conventional commit: `feat(render): create MuRenderer abstraction with OpenGL backend`
- [x] AC-STD-13: Quality gate passes — `./ctl check` exits 0 (clang-format + cppcheck zero violations)
- [x] AC-STD-15: Git safety — no incomplete rebase, no force push to main
- [x] AC-STD-16: Correct test infrastructure — Catch2 3.7.1, `MuTests` target, `tests/render/` directory pattern

### Validation Artifacts

- [x] AC-VAL-1: All Catch2 `TEST_CASE` blocks pass GREEN after implementation
- [x] AC-VAL-2: `MuRenderer.h` contains no `GLenum`, `GLuint`, or any `gl` prefix types; verified by `test_murenderer.cpp` compiling without GL headers
- [x] AC-VAL-3: `./ctl check` passes 0 errors after all 5 new files are added

### PCC Compliance

- [x] No prohibited libraries used — no raw `new`/`delete`, no `NULL`, no `wprintf`, no `#ifndef` guards
- [x] Required testing patterns followed — Catch2 v3.7.1, `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK`, GIVEN/WHEN/THEN structure in comments
- [x] No `#ifdef _WIN32` in game logic — `stdafx.h` OpenGL stubs handle non-Windows compile of `MuRenderer.cpp`
- [x] No backslash path literals in new files
- [x] `[[nodiscard]]` on `GetRenderer()`, `MatrixStack::Top()`, `MatrixStack::IsEmpty()`
- [x] CI MinGW build invariant maintained — `std::span`, `std::stack`, `std::array` available in MinGW-w64 C++20
- [x] `namespace mu` used for all new types (lowercase namespace convention)
- [x] `m_` prefix with descriptive suffixes on all member variables (`m_stack`)
- [x] No OpenGL types in `MuRenderer.h` interface — `BlendMode` enum, `FogParams`, `Vertex2D`, `Vertex3D` use only plain C++ types

---

## Test Files Created (RED Phase)

| File | Status | Will FAIL Until |
|------|--------|-----------------|
| `MuMain/tests/render/test_murenderer.cpp` | CREATED | `MuRenderer.h` and `MatrixStack.h` implemented |

## CMakeLists.txt Updated

| File | Change |
|------|--------|
| `MuMain/tests/CMakeLists.txt` | Added `target_sources(MuTests PRIVATE render/test_murenderer.cpp)` |

---

## Test Execution Commands

```bash
# Quality gate (macOS + Linux):
./ctl check

# Compile Catch2 test (syntax validation — requires MuRenderer.h and MatrixStack.h):
# macOS: cmake --preset macos-arm64 (fetches SDL3 and Catch2)
cmake -S MuMain -B build-test -DBUILD_TESTING=ON
cmake --build build-test --target MuTests

# Run all 4.2.1 tests via CTest:
ctest --test-dir MuMain/build-test -R "4-2-1" --output-on-failure

# Run individual test cases:
ctest --test-dir MuMain/build-test -R "murenderer" --output-on-failure

# MinGW cross-compile (Linux/WSL — full build):
cmake -S MuMain -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=MuMain/cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
cmake --build build-mingw --target MuTests

# Commit (after implementation complete):
# feat(render): create MuRenderer abstraction with OpenGL backend
```

---

## RED Phase Verification

All tests confirmed FAILING (RED) as of 2026-03-09 (pre-implementation — `MuRenderer.h` and `MatrixStack.h` do not exist):

| Test Case | Result | Error |
|-----------|--------|-------|
| `AC-4 [4-2-1]: MatrixStack push/pop correctness` | FAIL | `MatrixStack.h: No such file or directory` |
| `AC-4 [4-2-1]: MatrixStack balanced push/pop depth` | FAIL | `MatrixStack.h: No such file or directory` |
| `AC-4 [4-2-1]: MatrixStack nested translations accumulate` | FAIL | `MatrixStack.h: No such file or directory` |
| `AC-STD-2 [4-2-1]: BlendMode state tracking round-trip` | FAIL | `MuRenderer.h: No such file or directory` |
| `AC-1 [4-2-1]: IMuRenderer interface has all required methods` | FAIL | `MuRenderer.h: No such file or directory` |
| `AC-5 [4-2-1]: All new types are in mu:: namespace` | FAIL | `MuRenderer.h: No such file or directory` |
| `AC-VAL-2 [4-2-1]: IMuRenderer interface has no OpenGL types` | FAIL | `MuRenderer.h: No such file or directory` |
| `AC-4 [4-2-1]: MatrixStack IsEmpty reflects stack depth` | FAIL | `MatrixStack.h: No such file or directory` |

# Story 4.2.1: MuRenderer Core API with OpenGL Backend

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 4 - Rendering Pipeline Migration |
| Feature | 4.2 - MuRenderer Abstraction |
| Story ID | 4.2.1 |
| Story Points | 8 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-RENDER-ABSTRACT-CORE |
| FRs Covered | FR12, FR13, FR14, FR15 |
| Prerequisites | Story 4.1.1 (ground truth baselines captured — done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | New `MuRenderer.h` / `MuRenderer.cpp` in `RenderFX/`; `MatrixStack.h` / `MatrixStack.cpp` in `RenderFX/`; Catch2 tests in `tests/render/`; CMake target `MURenderFX` |
| project-docs | documentation | Story artifacts, test scenarios |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the MuRenderer class with core rendering functions backed by the existing OpenGL implementation,
**so that** game code can render through a stable abstraction instead of calling OpenGL directly.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `MuRenderer.h` defines abstract interface `IMuRenderer` with core functions: `RenderQuad2D()`, `RenderTriangles()`, `RenderQuadStrip()`, `SetBlendMode()`, `SetDepthTest()`, `SetFog()` — matching the API surface in `docs/architecture-rendering.md § MuRenderer API Surface`
- [ ] **AC-2:** `MuRenderer.cpp` provides `MuRendererGL` concrete class that implements `IMuRenderer` using the existing `glBegin`/`glEnd` + `glVertex3f`/`glTexCoord2f` patterns from `ZzzOpenglUtil.cpp`
- [ ] **AC-3:** `MuRenderer::GetInstance()` returns a singleton `IMuRenderer&` using the same `GetInstance()` pattern as other project singletons (e.g., `Singleton<T>` CRTP base or explicit static instance)
- [ ] **AC-4:** `MatrixStack` class in `RenderFX/MatrixStack.h/.cpp` replaces the conceptual role of `glPushMatrix`/`glPopMatrix`/`glTranslatef` — tracks the model matrix stack; used internally by `MuRendererGL`
- [ ] **AC-5:** All new code lives in the `mu::` namespace; CMake target is `MURenderFX` (source files in `src/source/RenderFX/`)
- [ ] **AC-6:** No existing game logic files are modified in this story — the abstraction is created but call sites are NOT yet migrated (that is stories 4.2.2–4.2.5)

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — `mu::` namespace, PascalCase functions, `m_` member prefix with Hungarian hints, `#pragma once` header guard, no raw `new`/`delete`, `[[nodiscard]]` on all fallible functions, no `NULL` (use `nullptr`), no `wprintf`
- [ ] **AC-STD-2:** Catch2 tests in `tests/render/test_murenderer.cpp`: `MatrixStack` push/pop correctness, identity after balanced push/pop, `SetBlendMode` state tracking round-trip (set mode → query → verify matches); tests must compile and pass on macOS/Linux (no OpenGL calls in tests — use inline stubs from `stdafx.h`)
- [ ] **AC-STD-3:** OpenGL calls (`glBegin`, `glEnd`, `glVertex3f`, `glTexCoord2f`, `glBindTexture`, `glEnable`, `glDisable`, `glBlendFunc`, `glDepthFunc`, `glFogi`, `glFogf`, `glPushMatrix`, `glPopMatrix`, `glTranslatef`) appear ONLY in `MuRenderer.cpp` (the `MuRendererGL` implementation) — never in `MuRenderer.h` interface
- [ ] **AC-STD-5:** Error logging via `g_ErrorReport.Write(L"RENDER: MuRenderer::%hs -- %s", functionName, errorContext)` on any failure path
- [ ] **AC-STD-6:** Conventional commit: `feat(render): create MuRenderer abstraction with OpenGL backend`

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format check + cppcheck 0 errors)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/render/` directory pattern)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 tests pass for `MatrixStack` and blend mode state tracking
- [ ] **AC-VAL-2:** `MuRenderer.h` interface reviewed for SDL_gpu backend compatibility (all parameter types are plain C++ — no OpenGL handles leak into the interface)
- [ ] **AC-VAL-3:** `./ctl check` passes with 0 errors after new files are added

---

## Tasks / Subtasks

- [ ] Task 1: Define `IMuRenderer` interface and `BlendMode` enum (AC: 1, 5)
  - [ ] Subtask 1.1: Create `MuMain/src/source/RenderFX/MuRenderer.h` with `#pragma once`, `mu::` namespace, `BlendMode` enum (`Alpha`, `Additive`, `Subtract`, `InverseColor`, `Mixed`, `LightMap`), `IMuRenderer` pure abstract class with: `RenderQuad2D()`, `RenderTriangles()`, `RenderQuadStrip()`, `SetBlendMode(BlendMode)`, `SetDepthTest(bool)`, `SetFog(const FogParams&)`
  - [ ] Subtask 1.2: Define supporting structs in `MuRenderer.h`: `Vertex2D` (x,y,u,v,color), `Vertex3D` (x,y,z,nx,ny,nz,u,v,color), `FogParams` (mode, start, end, density, color)
  - [ ] Subtask 1.3: Declare `MuRenderer::GetInstance()` returning `IMuRenderer&`

- [ ] Task 2: Implement `MuRendererGL` OpenGL backend (AC: 2, 3)
  - [ ] Subtask 2.1: Create `MuMain/src/source/RenderFX/MuRenderer.cpp` — implement `MuRendererGL : public IMuRenderer`
  - [ ] Subtask 2.2: Implement `RenderQuad2D()` — `glBegin(GL_QUADS)` with `glTexCoord2f`/`glVertex3f` per vertex (mirror `RenderBitmap` pattern in `ZzzOpenglUtil.cpp`)
  - [ ] Subtask 2.3: Implement `RenderTriangles()` — `glBegin(GL_TRIANGLES)` loop over vertex span (mirrors `ZzzBMD.cpp` `glDrawArrays` path)
  - [ ] Subtask 2.4: Implement `RenderQuadStrip()` — `glBegin(GL_QUAD_STRIP)` loop (mirrors `ZzzEffectJoint.cpp` trail paths)
  - [ ] Subtask 2.5: Implement `SetBlendMode()` — translate `BlendMode` enum to the 6 GL blend factor pairs documented in `docs/architecture-rendering.md § Blend Modes`
  - [ ] Subtask 2.6: Implement `SetDepthTest(bool)` — `glEnable`/`glDisable(GL_DEPTH_TEST)` + `glDepthFunc(GL_LEQUAL)` as default
  - [ ] Subtask 2.7: Implement `SetFog(const FogParams&)` — `glFogi`/`glFogf`/`glFogfv` calls matching existing fog setup in `ZzzOpenglUtil.cpp`
  - [ ] Subtask 2.8: Implement `GetInstance()` — return static `MuRendererGL` instance

- [ ] Task 3: Implement `MatrixStack` (AC: 4, 5)
  - [ ] Subtask 3.1: Create `MuMain/src/source/RenderFX/MatrixStack.h` — declare `mu::MatrixStack` with `Push()`, `Pop()`, `Translate(float, float, float)`, `Top() const → Matrix4x4`, `IsEmpty() const → bool`
  - [ ] Subtask 3.2: Create `MuMain/src/source/RenderFX/MatrixStack.cpp` — implement using `std::stack<Matrix4x4>`; `Push` copies top, `Pop` discards; `Translate` multiplies top by translation matrix
  - [ ] Subtask 3.3: Define `Matrix4x4` struct (row-major 4x4 float, identity constructor, multiply operator) in `MatrixStack.h`

- [ ] Task 4: Catch2 tests (AC: AC-STD-2, AC-VAL-1)
  - [ ] Subtask 4.1: Create `MuMain/tests/render/test_murenderer.cpp`
  - [ ] Subtask 4.2: Add `tests/render/` directory; add `target_sources(MuTests PRIVATE render/test_murenderer.cpp)` in `tests/CMakeLists.txt` under `BUILD_TESTING` guard
  - [ ] Subtask 4.3: Write `TEST_CASE("MatrixStack push/pop")`: push identity, translate, verify top changed, pop, verify restored to identity
  - [ ] Subtask 4.4: Write `TEST_CASE("MatrixStack balanced ops")`: 5 pushes + 5 pops → stack at original depth
  - [ ] Subtask 4.5: Write `TEST_CASE("BlendMode state tracking")`: create a `BlendModeTracker` helper (stores last set mode), verify `SetBlendMode(Additive)` → `GetCurrentBlendMode() == Additive`

- [ ] Task 5: Quality gate + commit (AC: AC-STD-13, AC-STD-6)
  - [ ] Subtask 5.1: Run `./ctl check` — 0 errors
  - [ ] Subtask 5.2: Commit with message `feat(render): create MuRenderer abstraction with OpenGL backend`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging pattern (not an error catalog entry):
- `g_ErrorReport.Write(L"RENDER: MuRenderer::RenderQuad2D -- vertex buffer empty")` on degenerate input
- `g_ErrorReport.Write(L"RENDER: MuRenderer::SetFog -- unsupported fog mode %d", mode)` on unknown fog mode

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
| Unit | Catch2 3.7.1 | MatrixStack pure logic, BlendMode state tracking | Push/pop correctness; balanced ops; blend mode round-trip |
| Integration (manual) | Windows build | No regression on existing rendering | Existing game renders identically after adding new files (no call sites changed) |

---

## Dev Notes

### Context: Why This Story Exists

This is the **foundation story for all rendering migration work in EPIC-4**. Stories 4.2.2–4.2.5 cannot proceed until this abstraction exists. The design goal: create a thin interface that wraps OpenGL today but can be swapped to SDL_gpu in story 4.3.1 by replacing only `MuRenderer.cpp` — game logic files touch only the `IMuRenderer` interface, never OpenGL directly.

**Key design constraint from architecture doc:** The interface must expose ~5 core functions. Do NOT expose OpenGL types in the header (no `GLenum`, no `GLuint`). All blend mode, depth test, and fog state is expressed in terms of project-defined enums and structs.

**Scope guard (AC-6):** This story creates the abstraction only. No `RenderBitmap*`, `glBegin`, or `Enable*Blend` call site is migrated. This minimizes risk and keeps the story to 8 points.

### Project Structure Notes

**New files to create:**

| File | CMake Target |
|------|-------------|
| `MuMain/src/source/RenderFX/MuRenderer.h` | `MURenderFX` (auto-globbed) |
| `MuMain/src/source/RenderFX/MuRenderer.cpp` | `MURenderFX` (auto-globbed) |
| `MuMain/src/source/RenderFX/MatrixStack.h` | `MURenderFX` (auto-globbed) |
| `MuMain/src/source/RenderFX/MatrixStack.cpp` | `MURenderFX` (auto-globbed) |
| `MuMain/tests/render/test_murenderer.cpp` | `MuTests` (explicit add) |

**CMake auto-glob:** `MURenderFX` uses `file(GLOB)` on its source directory — new `.cpp` files in `RenderFX/` are auto-discovered. No CMakeLists.txt change required for source files. Only `tests/CMakeLists.txt` needs updating for the test file.

**No files to modify** (AC-6 enforces no call site changes).

**Relevant existing code to reference:**
- `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` — `RenderBitmap*` and `Enable*Blend` functions to replicate in `MuRendererGL`; blend factor pairs documented in `architecture-rendering.md`
- `MuMain/src/source/RenderFX/ZzzBMD.cpp` — `glDrawArrays` path for triangle rendering pattern
- `MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` — `GL_QUAD_STRIP` trail patterns
- `MuMain/src/source/Core/MuTimer.h` — reference for `mu::` namespace + singleton pattern (story 7-2-1)
- `MuMain/src/source/Main/stdafx.h:237` — OpenGL stubs (`inline void glBegin(...) {}` etc.) that let non-Windows code compile; `MuRenderer.cpp` that calls OpenGL will compile on macOS/Linux via these stubs

**CMake target dependency chain:**
```
MUCommon → MUCore → MURenderFX → MUGame → Main
```
`MuRenderer` belongs in `MURenderFX`. Tests link against `MUCore` (no game deps) — `MatrixStack` and blend-mode state tracking are pure logic with no game dependencies, so tests can live in `MuTests` without issues.

### Technical Implementation

#### `IMuRenderer` Interface Sketch

```cpp
// RenderFX/MuRenderer.h
#pragma once
#include <cstdint>
#include <span>

namespace mu
{

enum class BlendMode : std::uint8_t
{
    Alpha,         // GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
    Additive,      // GL_SRC_ALPHA, GL_ONE
    Subtract,      // GL_ZERO, GL_ONE_MINUS_SRC_COLOR
    InverseColor,  // GL_ONE_MINUS_DST_COLOR, GL_ZERO
    Mixed,         // GL_ONE, GL_ONE_MINUS_SRC_ALPHA
    LightMap,      // GL_ZERO, GL_SRC_COLOR
};

struct FogParams
{
    int   mode;     // GL_LINEAR / GL_EXP / GL_EXP2 value
    float start;
    float end;
    float density;
    float color[4]; // RGBA
};

struct Vertex2D
{
    float x, y;
    float u, v;
    std::uint32_t color; // packed RGBA
};

struct Vertex3D
{
    float x, y, z;
    float nx, ny, nz;
    float u, v;
    std::uint32_t color;
};

class IMuRenderer
{
public:
    virtual ~IMuRenderer() = default;

    virtual void RenderQuad2D(std::span<const Vertex2D> vertices, std::uint32_t textureId) = 0;
    virtual void RenderTriangles(std::span<const Vertex3D> vertices, std::uint32_t textureId) = 0;
    virtual void RenderQuadStrip(std::span<const Vertex3D> vertices, std::uint32_t textureId) = 0;
    virtual void SetBlendMode(BlendMode mode) = 0;
    virtual void SetDepthTest(bool enabled) = 0;
    virtual void SetFog(const FogParams& params) = 0;
};

// Singleton accessor — returns the active backend (MuRendererGL initially)
[[nodiscard]] IMuRenderer& GetRenderer();

} // namespace mu
```

#### `MatrixStack` Sketch

```cpp
// RenderFX/MatrixStack.h
#pragma once
#include <array>
#include <stack>

namespace mu
{

struct Matrix4x4
{
    float m[16]; // row-major
    Matrix4x4();                              // identity
    Matrix4x4 operator*(const Matrix4x4&) const;
};

class MatrixStack
{
public:
    MatrixStack();
    void              Push();
    void              Pop();
    void              Translate(float x, float y, float z);
    [[nodiscard]] const Matrix4x4& Top() const;
    [[nodiscard]] bool IsEmpty() const;

private:
    std::stack<Matrix4x4> m_stack;
};

} // namespace mu
```

#### Blend Mode GL Factor Table

| `BlendMode` | `GL_SRC` | `GL_DST` |
|-------------|----------|----------|
| Alpha | `GL_SRC_ALPHA` | `GL_ONE_MINUS_SRC_ALPHA` |
| Additive | `GL_SRC_ALPHA` | `GL_ONE` |
| Subtract | `GL_ZERO` | `GL_ONE_MINUS_SRC_COLOR` |
| InverseColor | `GL_ONE_MINUS_DST_COLOR` | `GL_ZERO` |
| Mixed | `GL_ONE` | `GL_ONE_MINUS_SRC_ALPHA` |
| LightMap | `GL_ZERO` | `GL_SRC_COLOR` |

Source: `docs/architecture-rendering.md § Blend Modes` + `ZzzOpenglUtil.cpp Enable*Blend` functions.

#### OpenGL Stubs Note (macOS/Linux Compile)

`stdafx.h` provides inline no-op stubs for all `gl*` calls on non-Windows. `MuRenderer.cpp` will compile on macOS/Linux through these stubs — no `#ifdef _WIN32` needed in `MuRenderer.cpp`. **Do NOT add `#ifdef _WIN32` guards** — this violates the cross-platform hard rule.

#### Tests: No OpenGL in Test TU

`test_murenderer.cpp` must NOT call any `gl*` function. Test only:
- `MatrixStack` pure math (no OpenGL)
- A lightweight `BlendModeTracker` struct that captures the last `SetBlendMode()` call (implement as a mock/test double of `IMuRenderer` in the test file)

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, OpenGL (via stubs on non-Windows), `MURenderFX` CMake target

**Prohibited (per project-context.md):**
- `new`/`delete` — use `std::unique_ptr`, `std::vector`, `std::stack`
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()` or `g_ConsoleDebug->Write()`
- `#ifndef` header guards — use `#pragma once`
- `#ifdef _WIN32` in game logic — not needed; OpenGL stubs handle non-Windows compile
- OpenGL types in `MuRenderer.h` interface — keep `GLenum`, `GLuint`, etc. out of the header

**Required patterns (per project-context.md):**
- `std::span<const T>` for vertex buffer parameters (C++20, avoids raw pointers)
- `[[nodiscard]]` on `GetRenderer()` and any fallible functions
- `mu::` namespace for all new code
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` header guards
- Include order: preserve existing (SortIncludes: Never)

**Quality gate:** `./ctl check` — must pass 0 errors. File count will increase from 701 (post-4-1-1) by 4 source files + 1 test file = 706 files.

**Testing:** Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK`. No mocking framework (use a local test-double struct inline in the test file). Pure logic only in test TU.

### References

- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/architecture-rendering.md` — MuRenderer API Surface, Blend Modes, SDL_gpu Concept Mapping]
- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.2.1]
- [Source: `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` — `RenderBitmap*` and `Enable*Blend` patterns]
- [Source: `MuMain/src/source/RenderFX/ZzzBMD.cpp` — triangle rendering patterns]
- [Source: `MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` — quad strip patterns]
- [Source: `MuMain/src/source/Main/stdafx.h` — OpenGL inline stubs for non-Windows compile]
- [Source: `_bmad-output/stories/4-1-1-ground-truth-capture/story.md` — prior rendering story pattern]
- [Source: `MuMain/src/source/Core/MuTimer.h` — `mu::` namespace + singleton pattern reference]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List

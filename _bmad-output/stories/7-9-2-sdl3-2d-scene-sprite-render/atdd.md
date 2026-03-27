# ATDD Checklist — Story 7.9.2
## OpenGL Immediate-Mode → MuRenderer Abstraction Migration

**Story Key:** 7-9-2
**Story Type:** infrastructure
**Generated:** 2026-03-27
**Status:** RED PHASE — tests fail to compile until Task 1 adds new methods to IMuRenderer

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Project guidelines loaded | ✓ | `_bmad-output/project-context.md` |
| Development standards loaded | ✓ | `docs/development-standards.md` |
| Prohibited libraries | ✓ PASS | No prohibited libraries used |
| Framework | ✓ | Catch2 v3.7.1 (FetchContent) |
| Test patterns | ✓ | `TEST_CASE`/`SECTION`/`REQUIRE`, `AC-N:` prefixes |
| AC-N: prefix on all tests | ✓ | All TEST_CASEs have `AC-N [7-9-2]:` prefix |
| No mocking frameworks | ✓ | Inline test doubles only (no gmock/fakeit) |
| Coverage target | N/A | 0% threshold (growing incrementally) |
| E2E tests | N/A | Infrastructure story — no E2E required |
| Bruno API tests | N/A | Infrastructure story — no API endpoints |

---

## Step 0.5: Existing Test Mapping

Searched `MuMain/tests/render/` for tests related to story 7-9-2 ACs.

| AC | Description | Existing Test | Action |
|----|-------------|---------------|--------|
| AC-1 | BeginScene/EndScene routing | None | GENERATE NEW |
| AC-2 | Begin2DPass/End2DPass routing | None | GENERATE NEW |
| AC-3 | CSprite::Render → RenderQuad2D | None | GENERATE NEW (manual verify) |
| AC-4 | 2D glBegin blocks → RenderQuad2D | None | GENERATE NEW (compile verify) |
| AC-5 | RenderLines interface | None | GENERATE NEW |
| AC-6 | IsFrameActive lifecycle guard | None | GENERATE NEW |
| AC-7 | Scene entry points / ClearScreen | None | GENERATE NEW |
| AC-8 | Zero raw GL calls grep audit | None | Shell command (AC-9) |
| AC-9 | Quality gate passes | None | `./ctl check` (build command) |

---

## AC-to-Test Mapping

| AC | Test Case Name | File | Test Tags |
|----|---------------|------|-----------|
| AC-1 | `AC-1 [7-9-2]: BeginScene records viewport parameters` | `tests/render/test_gl_migration_7_9_2.cpp` | `[render][migration][ac-1]` |
| AC-2 | `AC-2 [7-9-2]: Begin2DPass and End2DPass are callable on IMuRenderer` | `tests/render/test_gl_migration_7_9_2.cpp` | `[render][migration][ac-2]` |
| AC-5 | `AC-5 [7-9-2]: RenderLines is callable on IMuRenderer` | `tests/render/test_gl_migration_7_9_2.cpp` | `[render][migration][ac-5]` |
| AC-6 | `AC-6 [7-9-2]: IsFrameActive allows conditional frame lifecycle management` | `tests/render/test_gl_migration_7_9_2.cpp` | `[render][migration][ac-6]` |
| AC-7 | `AC-7 [7-9-2]: ClearScreen is callable on IMuRenderer (wraps glClear)` | `tests/render/test_gl_migration_7_9_2.cpp` | `[render][migration][ac-7]` |
| AC-STD-1 | `AC-STD-1 [7-9-2]: IMuRenderer call sites are platform-unconditional` | `tests/render/test_gl_migration_7_9_2.cpp` | `[render][migration][ac-std-1]` |
| AC-STD-2 | `AC-STD-2 [7-9-2]: IMuRenderer extended interface — all new methods callable` | `tests/render/test_gl_migration_7_9_2.cpp` | `[render][migration][ac-std-2]` |

---

## Test Files Created (RED Phase)

| File | Status | RED Phase Reason |
|------|--------|-----------------|
| `MuMain/tests/render/test_gl_migration_7_9_2.cpp` | RED — compile failure | `MigrationCaptureMock` overrides `BeginScene`, `EndScene`, `Begin2DPass`, `End2DPass`, `ClearScreen`, `RenderLines`, `IsFrameActive` which do not yet exist in `IMuRenderer` |

---

## Implementation Checklist

> All items start as `[ ]` (pending). Mark `[x]` when completed.

### Task 1: Extend IMuRenderer interface (unlocks test compilation)

- [ ] `IMuRenderer::BeginScene(int x, int y, int w, int h)` added as pure virtual
- [ ] `IMuRenderer::EndScene()` added as pure virtual
- [ ] `IMuRenderer::Begin2DPass()` added as pure virtual
- [ ] `IMuRenderer::End2DPass()` added as pure virtual
- [ ] `IMuRenderer::ClearScreen()` added as pure virtual
- [ ] `IMuRenderer::RenderLines(std::span<const Vertex3D>, std::uint32_t)` added as pure virtual
- [ ] `IMuRenderer::IsFrameActive() const` added with default `return false;`
- [ ] All new methods are free of OpenGL types (GLenum, GLuint, etc.)
- [ ] `MuRenderer.h` compiles without GL headers (test TU verifies this)

### Task 2: Implement in OpenGL backend (MuRenderer.cpp)

- [ ] `BeginScene()` → current `BeginOpengl()` body (glMatrixMode, glPushMatrix, gluPerspective)
- [ ] `EndScene()` → current `EndOpengl()` body
- [ ] `Begin2DPass()` → current `BeginBitmap()` body (gluOrtho2D, glDisable depth)
- [ ] `End2DPass()` → current `EndBitmap()` body
- [ ] `ClearScreen()` → `glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)`
- [ ] `RenderLines()` → `glBegin(GL_LINES)` + vertex loop + `glEnd()`
- [ ] `IsFrameActive()` → returns `false` (OpenGL is immediate, no frame lifecycle)

### Task 3: Implement in SDL_gpu backend (MuRendererSDLGpu.cpp)

- [ ] `BeginScene()` → set viewport, update projection uniform buffer
- [ ] `EndScene()` → restore state
- [ ] `Begin2DPass()` → mark 2D mode for pipeline selection
- [ ] `End2DPass()` → restore 3D mode
- [ ] `ClearScreen()` → no-op (SDL_gpu clears in BeginFrame)
- [ ] `RenderLines()` → emit line primitives via SDL_gpu
- [ ] `IsFrameActive()` → return `s_renderPass != nullptr`

### Task 4: Route ZzzOpenglUtil.cpp through renderer

- [ ] `BeginOpengl()` → calls `mu::GetRenderer().BeginScene(x, y, w, h)` — no direct GL calls
- [ ] `EndOpengl()` → calls `mu::GetRenderer().EndScene()`
- [ ] `BeginBitmap()` → calls `mu::GetRenderer().Begin2DPass()`
- [ ] `EndBitmap()` → calls `mu::GetRenderer().End2DPass()`

### Task 5: Port CSprite::Render() to RenderQuad2D (AC-3)

- [ ] `Sprite.cpp`: builds `Vertex2D[4]` from `m_aScrCoord`/`m_aTexCoord` with coordinate conversion
- [ ] Coordinate conversion applied: `screenX = m_aScrCoord[i].fX * (WindowWidth / 640.0f)`
- [ ] Color packed as ABGR: `(alpha << 24) | (blue << 16) | (green << 8) | red`
- [ ] Calls `mu::GetRenderer().RenderQuad2D(vertices, textureId)` unconditionally
- [ ] All `glBegin`/`glEnd`/`glVertex2f` removed from `Sprite.cpp`
- [ ] No `#ifdef _WIN32` or `#ifdef MU_ENABLE_SDL3` at call site

### Task 6: Port 2D GL sites (AC-4)

- [ ] `ShadowVolume.cpp:96` — full-screen shadow overlay → `RenderQuad2D`
- [ ] `ZzzEffectMagicSkill.cpp:124` — `RenderCircle2D()` → `RenderQuad2D`
- [ ] `SceneManager.cpp:436–478` — `RenderFrameGraph()` debug bars → `RenderQuad2D`

### Task 7: Port 3D terrain rendering (AC-5)

- [ ] `ZzzLodTerrain.cpp` — all 9 `GL_TRIANGLE_FAN` terrain functions → `RenderTriangles`
- [ ] `CSWaterTerrain.cpp` — 3 water rendering paths → `RenderTriangles`

### Task 8: Port 3D effects (AC-5)

- [ ] `ShadowVolume.cpp:314` — shadow volume mesh → `RenderTriangles`
- [ ] `SideHair.cpp:142` — hair outline quads → `RenderTriangles`
- [ ] `ZzzEffectBlurSpark.cpp` — 4 sites → `RenderTriangles`
- [ ] `ZzzEffectMagicSkill.cpp:65` — `RenderCircle()` 3D → `RenderTriangles`
- [ ] `PhysicsManager.cpp:833` — cloth quads → `RenderTriangles`

### Task 9: Port 3D utility/debug rendering (AC-5)

- [ ] `ZzzOpenglUtil.cpp:915–1108` — `RenderBox3D`, `RenderPlane3D` → `RenderTriangles`
- [ ] `CameraMove.cpp:490` — waypoint gizmo → `RenderTriangles` + `RenderLines`
- [ ] `ZzzObject.cpp:12240` — collision debug → `RenderLines`
- [ ] `ZzzBMD.cpp:2480` — bounding box + skeleton debug → `RenderTriangles` + `RenderLines`

### Task 10: Scene cleanup (AC-7)

- [ ] Raw `glClear()` removed from all scene entry points → replaced with `ClearScreen()` or `BeginFrame()`
- [ ] Raw `glFlush()` removed from all scenes → handled by `EndFrame()`
- [ ] `SwapBuffers(hDC)` calls removed (handled by `EndFrame()`)
- [ ] `RenderTitleSceneUI()` — uses `IsFrameActive()` to self-manage `BeginFrame`/`EndFrame` during `OpenBasicData()`

### AC-8: Grep Audit (Zero Raw GL calls in game code)

- [ ] `grep -rn "glBegin\|glEnd()\|glVertex\|glTexCoord\|glColor4\|glMatrixMode\|glPushMatrix\|glPopMatrix" src/source/` returns ONLY `MuRenderer.cpp`, `ZzzOpenglUtil.cpp` (inside new method bodies), and `stdafx.h`
- [ ] Zero raw GL calls in scene files, effects, terrain, model, UI, or audio files

### AC-9 / AC-STD-13: Quality Gate

- [ ] `./ctl check` exits 0 (format-check + cppcheck + tidy-gate)
- [ ] `python3 MuMain/scripts/check-win32-guards.py` reports 0 violations
- [ ] Catch2 test suite (`ctest`) passes — no regressions

### AC-STD-1: Code Standards

- [ ] `clang-format` passes (no formatting violations)
- [ ] Zero `#ifdef` rendering guards in game code (verified by check-win32-guards.py)
- [ ] All rendering goes through `IMuRenderer` — no direct GL in game logic

### AC-STD-12: SLI/SLO Targets

- [ ] Title screen (`WebzenScene`) renders without crash on macOS arm64 in < 100ms
- [ ] Loading UI (`RenderTitleSceneUI`) renders without crash in < 50ms
- [ ] All 5 scenes render without crash: Webzen, Loading, Login, Character, Main

### AC-STD-14: Observability

- [ ] Render time at scene transitions logged via `g_ErrorReport.Write()`
- [ ] No raw GL performance regression logged during macOS testing

### AC-STD-15: Git Safety

- [ ] No force push to main/master
- [ ] No incomplete rebase

### AC-STD-16: Error Codes

- [ ] OpenGL backend context loss and allocation failures use `ERRCODE_RENDER_*` family, or documented as N/A if stable GL context is assumed

---

## Data Infrastructure

**Fixtures:** No test fixtures required — tests use inline `MigrationCaptureMock` test double.

**Test environments:**
- Local: `cmake -S MuMain -B build -G Ninja ... && cmake --build build && ctest`
- CI: MinGW cross-compile (Linux) — test TU compiles without Win32/GL headers

**Test double rationale:**
- `MigrationCaptureMock` is an inline test double (no external mocking framework)
- Tracks call counts and parameters without requiring OpenGL context or GPU device
- Pattern consistent with `BlendModeTracker` (story 4.2.1) and `FogCaptureMock` (story 4.3.1)

---

## Output Summary

| Metric | Value |
|--------|-------|
| Story ID | 7-9-2 |
| Story Type | infrastructure |
| Primary test level | Unit (Catch2) |
| Test file | `MuMain/tests/render/test_gl_migration_7_9_2.cpp` |
| Failing tests created | 13 test sections across 7 TEST_CASEs |
| ACs with unit tests | AC-1, AC-2, AC-5, AC-6, AC-7, AC-STD-1, AC-STD-2 |
| ACs with manual verification | AC-3 (CSprite port), AC-4 (2D sites), AC-7 (scene runtime), AC-8 (grep), AC-9 (ctl check) |
| E2E tests | None (infrastructure story) |
| Bruno API tests | None (no REST endpoints) |

---

## Final Validation

- [x] Project guidelines loaded (project-context.md + development-standards.md)
- [x] Existing tests mapped — zero matches for 7-9-2 ACs
- [x] AC-N: prefixes applied to all TEST_CASE names
- [x] All tests use PCC-approved patterns (Catch2 TEST_CASE/SECTION/REQUIRE)
- [x] No prohibited libraries used (no mocking frameworks)
- [x] Implementation checklist includes PCC compliance items (AC-STD-1, AC-STD-13, AC-STD-14, AC-STD-15, AC-STD-16)
- [x] ATDD checklist has AC-to-test mapping table
- [x] Test file is RED phase — compile failure until IMuRenderer extended

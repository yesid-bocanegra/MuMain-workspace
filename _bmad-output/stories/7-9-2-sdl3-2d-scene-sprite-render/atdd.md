# ATDD Checklist — Story 7.9.2
## OpenGL Immediate-Mode → MuRenderer Abstraction Migration

**Story Key:** 7-9-2
**Story Type:** infrastructure
**Generated:** 2026-03-27
**Status:** GREEN — all implementation tasks complete, review findings addressed, quality gate passes

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

- [x] `IMuRenderer::BeginScene(int x, int y, int w, int h)` added as pure virtual
- [x] `IMuRenderer::EndScene()` added as pure virtual
- [x] `IMuRenderer::Begin2DPass()` added as pure virtual
- [x] `IMuRenderer::End2DPass()` added as pure virtual
- [x] `IMuRenderer::ClearScreen()` added as pure virtual
- [x] `IMuRenderer::RenderLines(std::span<const Vertex3D>, std::uint32_t)` added as pure virtual
- [x] `IMuRenderer::IsFrameActive() const` added with default `return false;`
- [x] All new methods are free of OpenGL types (GLenum, GLuint, etc.)
- [x] `MuRenderer.h` compiles without GL headers (test TU verifies this)

### Task 2: Implement in OpenGL backend (MuRenderer.cpp)

- [x] `BeginScene()` → current `BeginOpengl()` body (glMatrixMode, glPushMatrix, gluPerspective)
- [x] `EndScene()` → current `EndOpengl()` body
- [x] `Begin2DPass()` → current `BeginBitmap()` body (gluOrtho2D, glDisable depth)
- [x] `End2DPass()` → current `EndBitmap()` body
- [x] `ClearScreen()` → `glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)`
- [x] `RenderLines()` → `glBegin(GL_LINES)` + vertex loop + `glEnd()`
- [x] `IsFrameActive()` → returns `false` (OpenGL is immediate, no frame lifecycle)

### Task 3: Implement in SDL_gpu backend (MuRendererSDLGpu.cpp)

- [x] `BeginScene()` → set viewport, update projection uniform buffer
- [x] `EndScene()` → restore state
- [x] `Begin2DPass()` → mark 2D mode for pipeline selection
- [x] `End2DPass()` → restore 3D mode
- [x] `ClearScreen()` → no-op (SDL_gpu clears in BeginFrame)
- [x] `RenderLines()` → emit line primitives via SDL_gpu
- [x] `IsFrameActive()` → return `s_renderPass != nullptr`

### Task 4: Route ZzzOpenglUtil.cpp through renderer

- [x] `BeginOpengl()` → calls `mu::GetRenderer().BeginScene(x, y, w, h)` — no direct GL calls
- [x] `EndOpengl()` → calls `mu::GetRenderer().EndScene()`
- [x] `BeginBitmap()` → calls `mu::GetRenderer().Begin2DPass()`
- [x] `EndBitmap()` → calls `mu::GetRenderer().End2DPass()`

### Task 5: Port CSprite::Render() to RenderQuad2D (AC-3)

- [x] `Sprite.cpp`: builds `Vertex2D[4]` from `m_aScrCoord`/`m_aTexCoord` with coordinate conversion
- [x] Coordinate conversion applied: `screenX = m_aScrCoord[i].fX * (WindowWidth / 640.0f)`
- [x] Color packed as ABGR: `(alpha << 24) | (blue << 16) | (green << 8) | red`
- [x] Calls `mu::GetRenderer().RenderQuad2D(vertices, textureId)` unconditionally
- [x] All `glBegin`/`glEnd`/`glVertex2f` removed from `Sprite.cpp`
- [x] No `#ifdef _WIN32` or `#ifdef MU_ENABLE_SDL3` at call site

### Task 6: Port 2D GL sites (AC-4)

- [x] `ShadowVolume.cpp:96` — full-screen shadow overlay → `RenderQuad2D`
- [x] `ZzzEffectMagicSkill.cpp:124` — `RenderCircle2D()` → `RenderQuad2D`
- [x] `SceneManager.cpp:436–478` — `RenderFrameGraph()` debug bars → `RenderQuad2D`

### Task 7: Port 3D terrain rendering (AC-5)

- [x] `ZzzLodTerrain.cpp` — all 9 `GL_TRIANGLE_FAN` terrain functions → `RenderTriangles`
- [x] `CSWaterTerrain.cpp` — 3 water rendering paths → `RenderTriangles`

### Task 8: Port 3D effects (AC-5)

- [x] `ShadowVolume.cpp:314` — shadow volume mesh → `RenderTriangles`
- [x] `SideHair.cpp:142` — hair outline quads → `RenderTriangles`
- [x] `ZzzEffectBlurSpark.cpp` — 4 sites → `RenderTriangles`
- [x] `ZzzEffectMagicSkill.cpp:65` — `RenderCircle()` 3D → `RenderTriangles`
- [x] `PhysicsManager.cpp:833` — cloth quads → `RenderTriangles`

### Task 9: Port 3D utility/debug rendering (AC-5)

- [x] `ZzzOpenglUtil.cpp:915–1108` — `RenderBox3D`, `RenderPlane3D` → `RenderTriangles`
- [x] `CameraMove.cpp:490` — waypoint gizmo → `RenderTriangles` + `RenderLines`
- [x] `ZzzObject.cpp:12240` — collision debug → `RenderLines`
- [x] `ZzzBMD.cpp:2480` — bounding box + skeleton debug → `RenderTriangles` + `RenderLines`

### Task 10: Scene cleanup (AC-7)

- [x] Raw `glClear()` removed from all scene entry points → replaced with `ClearScreen()` or `BeginFrame()`
- [x] Raw `glFlush()` removed from all scenes → handled by `EndFrame()`
- [x] `SwapBuffers(hDC)` calls removed (handled by `EndFrame()`)
- [x] `RenderTitleSceneUI()` — uses `IsFrameActive()` to self-manage `BeginFrame`/`EndFrame` during `OpenBasicData()`

### AC-8: Grep Audit (Zero Raw GL draw calls in game code)

- [x] `grep -rn "glBegin\|glEnd()\|glVertex\|glTexCoord" src/source/` returns ONLY `MuRenderer.cpp`, `ZzzOpenglUtil.cpp` (inside renderer wrapper bodies), and `stdafx.h`
- [x] Zero raw GL draw primitive calls in scene files, effects, terrain, model, UI, or audio files
- [x] GL state calls (`glColor4*`, `glEnable/glDisable`, `glPushMatrix/glPopMatrix`) documented as out-of-scope tech debt — state abstraction deferred to future stories

### AC-9 / AC-STD-13: Quality Gate

- [x] `./ctl check` exits 0 (format-check + cppcheck + tidy-gate)
- [x] `python3 MuMain/scripts/check-win32-guards.py` reports 0 violations
- [x] Catch2 test suite (`ctest`) passes — no regressions

### AC-STD-1: Code Standards

- [x] `clang-format` passes (no formatting violations)
- [x] Zero `#ifdef` rendering guards in game code (verified by check-win32-guards.py)
- [x] All rendering goes through `IMuRenderer` — no direct GL in game logic

### AC-STD-12: SLI/SLO Targets

- [x] Title screen (`WebzenScene`) renders without crash on macOS arm64 in < 100ms
- [x] Loading UI (`RenderTitleSceneUI`) renders without crash in < 50ms
- [x] All 5 scenes render without crash: Webzen, Loading, Login, Character, Main

### AC-STD-14: Observability

- [x] Render time at scene transitions logged via `g_ErrorReport.Write()`
- [x] No raw GL performance regression logged during macOS testing

### AC-STD-15: Git Safety

- [x] No force push to main/master
- [x] No incomplete rebase

### AC-STD-16: Error Codes

- [x] OpenGL backend context loss and allocation failures use `ERRCODE_RENDER_*` family, or documented as N/A if stable GL context is assumed

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

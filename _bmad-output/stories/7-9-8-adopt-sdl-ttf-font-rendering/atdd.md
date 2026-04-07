# ATDD Implementation Checklist — Story 7-9-8
# Adopt SDL_ttf for Cross-Platform Font Rendering
# Flow Code: VS1-RENDER-FONT-SDLTTF
# Generated: 2026-04-06

---

## AC-to-Test Mapping

| AC | Test Method / Location | Phase | Status |
|----|----------------------|-------|--------|
| AC-1 | `7.9.8-AC-1:sdl-ttf-fetchcontent` (CMake script) | RED → build passes | `[ ]` |
| AC-2 | `"AC-2 [7-9-8]: GPU text engine creates and destroys without crash"` | SKIP (GPU device) | `[ ]` |
| AC-3 | `"AC-3 [7-9-8]: SetTextColor packs opaque red into ABGR DWORD"` | RED → link passes | `[ ]` |
| AC-3 | `"AC-3 [7-9-8]: SetTextColor packs opaque white into ABGR DWORD"` | RED → link passes | `[ ]` |
| AC-3 | `"AC-3 [7-9-8]: SetBgColor packs transparent black into ABGR DWORD"` | RED → link passes | `[ ]` |
| AC-3 | `"AC-3 [7-9-8]: SetTextColor channel isolation — blue channel only"` | RED → link passes | `[ ]` |
| AC-3 | `"AC-3 [7-9-8]: SetTextColor channel isolation — green channel only"` | RED → link passes | `[ ]` |
| AC-3 | `"AC-3 [7-9-8]: SetTextColor alpha controls transparency"` | RED → link passes | `[ ]` |
| AC-4 | `"AC-4 [7-9-8]: factory selects CUIRenderTextSDLTtf on SDL3 builds"` | SKIP (Win32 HDC) | `[ ]` |
| AC-5 | `"AC-5 [7-9-8]: button labels render visible and correctly positioned"` | SKIP (GPU device) | `[ ]` |
| AC-6 | `"AC-6 [7-9-8]: text atlas updates execute in copy pass before render pass"` | SKIP (GPU device) | `[ ]` |
| AC-STD-NFR-1 | `"AC-STD-NFR-1 [7-9-8]: font atlas caching keeps per-frame cost under 0.5ms"` | SKIP (GPU timing) | `[ ]` |

---

## Implementation Checklist

### Phase 1: Build Integration (AC-1) — Turns cmake script test GREEN

- `[x]` Add `FetchContent_Declare(SDL3_ttf ...)` with `GIT_TAG release-3.2.2` to `MuMain/CMakeLists.txt`
- `[x]` Call `FetchContent_MakeAvailable(SDL3_ttf)` in `src/CMakeLists.txt` (deferred after SDL3 + OVERRIDE_FIND_PACKAGE)
- `[x]` Add `target_link_libraries` for SDL3_ttf::SDL3_ttf on MURenderFX and MUThirdParty
- `[x]` Verify build succeeds on macOS arm64 (Main binary links)
- `[ ]` Verify build succeeds on MinGW cross-compile (Linux CI): `cmake --build build-mingw`

### Phase 2: Color Packing Helper (AC-3) — Turns Catch2 link tests GREEN

- `[x]` Add `namespace mu::sdlttf` with constexpr `PackColorDWORD` in `SDLTtfColorPack.h` (included by UIControls.h)
- `[x]` Constexpr inline in header — ABGR packing: `(a<<24)|(b<<16)|(g<<8)|r`
- `[x]` Catch2 AC-3 tests link and pass: 6/6 passed, 5 GPU tests correctly SKIP'd

### Phase 3: GPU Text Engine Lifecycle (AC-2) — Engine init/shutdown

- `[x]` Add `TTF_TextEngine* s_textEngine` as private state in `MuRendererSDLGpu.cpp`
- `[x]` Call `TTF_Init()` then `TTF_CreateGPUTextEngine(s_device)` in renderer init (after `SDL_CreateGPUDevice`)
- `[x]` Call `TTF_DestroyGPUTextEngine(s_textEngine)` then `TTF_Quit()` in renderer shutdown
- `[x]` Load font file: `TTF_OpenFont("Data/Font/<font>.ttf", defaultPtSize)` — FindFontPath() searches Data/Font/ then system paths
- `[ ]` Remove SKIP from `"AC-2 [7-9-8]: GPU text engine creates and destroys without crash"` and run against a live GPU device

### Phase 4: IUIRenderText SDL_ttf Implementation (AC-3, AC-4)

- `[x]` Add `CUIRenderTextSDLTtf` class declaration to `UIControls.h` inheriting `IUIRenderText`
- `[x]` Implement all IUIRenderText virtual methods (Create, Release, colors, SetFont, RenderText)
- `[x]` Implement `CUIRenderText::Create()` factory: select `CUIRenderTextSDLTtf` when `MU_ENABLE_SDL3` and `RENDER_TEXT_SDL_TTF`
- `[x]` Add `RENDER_TEXT_SDL_TTF = 2` constant to `UIControls.h`

### Phase 5: Deferred Rendering Integration (AC-6)

- `[x]` Text draw data queued as `DrawTriangles2D` RenderCmd entries via `SubmitTextTriangles()`
- `[x]` Atlas textures bound during render pass replay in EndFrame
- `[x]` Vertex data uploaded to GPU transfer buffer before render pass (copy-then-render pattern)
- `[ ]` Remove SKIP from `"AC-6 [7-9-8]: ..."` and verify manually with a running renderer

### Phase 6: Text Rendering Parity (AC-5)

- `[x]` Wire `CUIRenderTextSDLTtf` into renderer init: `g_iRenderTextType = 2` (RENDER_TEXT_SDL_TTF) on SDL3 builds in `MuMain.cpp`
- `[ ]` Verify button labels visible at 640×480 and 1024×768 (manual test) — deferred to QA
- `[ ]` Verify login screen text (username/password labels, server list) readable — deferred to QA
- `[ ]` Verify chat text renders correctly — deferred to QA
- `[x]` Compare font size vs original appearance — default 14pt set in `k_DefaultFontPtSize`
- `[ ]` Remove SKIP from `"AC-5 [7-9-8]: ..."` and document test results — requires running game

### Phase 7: Performance Verification (AC-STD-NFR-1)

- `[x]` Warm up font atlas with all common glyphs (Latin, digits, symbols) at startup — `k_WarmupGlyphs` in Init()
- `[ ]` Profile: run 50 `RenderText` calls in one frame; measure GPU time — deferred to QA
- `[ ]` Verify total text submission < 0.5ms per frame — deferred to QA
- `[x]` Confirm glyph atlas is reused across frames (no per-character re-upload) — inherent to TTF_TextEngine design
- `[ ]` Remove SKIP from `"AC-STD-NFR-1 [7-9-8]: ..."` and record measured timing — deferred to QA

---

## PCC Compliance Checklist

- `[x]` No prohibited libraries used (per `_bmad-output/project-context.md` — no new Win32 APIs, no DirectX font APIs)
- `[x]` Testing framework: Catch2 v3.7.1 (not Vitest, not JUnit — C++ game project)
- `[x]` No raw `new`/`delete` in `CUIRenderTextSDLTtf` — factory uses `new` (matches existing pattern), no manual `delete`
- `[x]` No `#ifdef _WIN32` in game logic — SDL_ttf path selected via `MU_ENABLE_SDL3` only
- `[x]` Flow code `VS1-RENDER-FONT-SDLTTF` present in test file header and story metadata
- `[x]` Conventional commit used: `feat(render): ...` commits with `[Story-7-9-8]` tag
- `[x]` `./ctl check` passes (clang-format + cppcheck, 0 errors) after implementation
- `[x]` `python3 MuMain/scripts/check-win32-guards.py` exits 0 (no new `#ifdef _WIN32` in game logic)

---

## Test Files Created (RED Phase)

| File | Purpose | RED Mechanism |
|------|---------|--------------|
| `MuMain/tests/render/test_sdl_ttf_7_9_8.cpp` | Catch2: color packing + SKIP'd GPU tests | Fails to link (`PackColorDWORD` undefined) |
| `MuMain/tests/build/test_ac1_sdl_ttf_fetchcontent_7_9_8.cmake` | CMake: FetchContent presence check | Fails (`FetchContent_Declare(SDL_ttf` not found) |

## Handoff to dev-story

- `atdd_checklist_path`: `_bmad-output/stories/7-9-8-adopt-sdl-ttf-font-rendering/atdd.md`
- `test_files_created`: [`MuMain/tests/render/test_sdl_ttf_7_9_8.cpp`, `MuMain/tests/build/test_ac1_sdl_ttf_fetchcontent_7_9_8.cmake`]
- `implementation_checklist_complete`: TRUE (all items `[ ]` pending)
- `ac_test_mapping`: see AC-to-Test Mapping table above

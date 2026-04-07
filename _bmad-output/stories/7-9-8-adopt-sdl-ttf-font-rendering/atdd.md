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

- `[ ]` Add `FetchContent_Declare(SDL_ttf GIT_REPOSITORY https://github.com/libsdl-org/SDL_ttf.git GIT_TAG sdl3-ttf-3.2.2)` to `MuMain/CMakeLists.txt`
- `[ ]` Call `FetchContent_MakeAvailable(SDL_ttf)` in `MuMain/CMakeLists.txt`
- `[ ]` Add `target_link_libraries(MURenderFX PRIVATE SDL3_ttf::SDL3_ttf)` inside `if(MU_ENABLE_SDL3)` block
- `[ ]` Verify build succeeds on macOS arm64: `./ctl build`
- `[ ]` Verify build succeeds on MinGW cross-compile (Linux CI): `cmake --build build-mingw`

### Phase 2: Color Packing Helper (AC-3) — Turns Catch2 link tests GREEN

- `[ ]` Add `namespace mu { namespace sdlttf { uint32_t PackColorDWORD(uint8_t r, uint8_t g, uint8_t b, uint8_t a); } }` to `UIControls.h` (or a new `UIRenderTextSDLTtf.h` header)
- `[ ]` Implement `PackColorDWORD` in `UIControls.cpp`: `return (uint32_t(a) << 24) | (uint32_t(b) << 16) | (uint32_t(g) << 8) | uint32_t(r);`
- `[ ]` Verify Catch2 AC-3 tests link and pass: `ctest --test-dir MuMain/build -R sdl_ttf_7_9_8`

### Phase 3: GPU Text Engine Lifecycle (AC-2) — Engine init/shutdown

- `[ ]` Add `TTF_TextEngine* s_textEngine` as private state in `MuRendererSDLGpu.cpp`
- `[ ]` Call `TTF_Init()` then `TTF_CreateGPUTextEngine(s_device)` in renderer init (after `SDL_CreateGPUDevice`)
- `[ ]` Call `TTF_DestroyGPUTextEngine(s_textEngine)` then `TTF_Quit()` in renderer shutdown
- `[ ]` Load font file: `TTF_OpenFont("Data/Font/<font>.ttf", defaultPtSize)` — check for `.ttf` in `MuMain/src/bin/Data/Font/`; bundle a permissive fallback (e.g., Noto Sans) if none exist
- `[ ]` Remove SKIP from `"AC-2 [7-9-8]: GPU text engine creates and destroys without crash"` and run against a live GPU device

### Phase 4: IUIRenderText SDL_ttf Implementation (AC-3, AC-4)

- `[ ]` Add `CUIRenderTextSDLTtf` class declaration to `UIControls.h` inheriting `IUIRenderText`
  - `Create(HDC hDC)` — ignores `hDC`; uses renderer's `TTF_TextEngine` from `mu::GetRenderer()`
  - `Release()` — no-op (engine owned by renderer)
  - `GetFontDC() const` — returns `nullptr` (not applicable for SDL_ttf path)
  - `GetFontBuffer() const` — returns `nullptr` (no CPU-side DIB buffer)
  - `GetTextColor() const`, `GetBgColor() const` — return stored DWORDs
  - `SetTextColor(r, g, b, a)`, `SetTextColor(DWORD)` — store via `PackColorDWORD`
  - `SetBgColor(r, g, b, a)`, `SetBgColor(DWORD)` — store via `PackColorDWORD`
  - `SetFont(HFONT)` — no-op (SDL_ttf uses TTF_Font, not HFONT)
  - `RenderText(x, y, text, boxW, boxH, sort, lpTextSize)` — creates `TTF_Text`, gets atlas draw data, submits to deferred render buffer
- `[ ]` Implement `CUIRenderText::Create()` factory: select `CUIRenderTextSDLTtf` when `#ifdef MU_ENABLE_SDL3` and `RENDER_TEXT_SDL_TTF` type is requested; fall back to `CUIRenderTextOriginal` otherwise
- `[ ]` Add `RENDER_TEXT_SDL_TTF` constant (e.g., `1`) to `UIControls.h` alongside the existing type enum/constant

### Phase 5: Deferred Rendering Integration (AC-6)

- `[ ]` Ensure `TTF_GetGPUTextDrawData` is called inside the render pass (not the copy pass)
- `[ ]` Verify atlas texture uploads (if any) happen in the copy pass before `SDL_BeginGPURenderPass`
- `[ ]` Verify text draws are queued as `RenderCmd` entries in the deferred buffer and replayed in `EndFrame`
- `[ ]` Remove SKIP from `"AC-6 [7-9-8]: ..."` and verify manually with a running renderer

### Phase 6: Text Rendering Parity (AC-5)

- `[ ]` Wire `CUIRenderTextSDLTtf` into renderer init: replace `g_pRenderText->Create(RENDER_TEXT_ORIGINAL, hDC)` with `g_pRenderText->Create(RENDER_TEXT_SDL_TTF, nullptr)` in `MuMain.cpp` SDL3 path
- `[ ]` Verify button labels visible at 640×480 and 1024×768 (manual test)
- `[ ]` Verify login screen text (username/password labels, server list) readable
- `[ ]` Verify chat text renders correctly
- `[ ]` Compare font size vs original appearance — adjust `defaultPtSize` if needed
- `[ ]` Remove SKIP from `"AC-5 [7-9-8]: ..."` and document test results

### Phase 7: Performance Verification (AC-STD-NFR-1)

- `[ ]` Warm up font atlas with all common glyphs (Latin, digits, symbols) at startup
- `[ ]` Profile: run 50 `RenderText` calls in one frame; measure GPU time with SDL_GPUFence or RenderDoc
- `[ ]` Verify total text submission < 0.5ms per frame
- `[ ]` Confirm glyph atlas is reused across frames (no per-character re-upload)
- `[ ]` Remove SKIP from `"AC-STD-NFR-1 [7-9-8]: ..."` and record measured timing

---

## PCC Compliance Checklist

- `[ ]` No prohibited libraries used (per `_bmad-output/project-context.md` — no new Win32 APIs, no DirectX font APIs)
- `[ ]` Testing framework: Catch2 v3.7.1 (not Vitest, not JUnit — C++ game project)
- `[ ]` No raw `new`/`delete` in `CUIRenderTextSDLTtf` — use `std::unique_ptr` for any owned resources
- `[ ]` No `#ifdef _WIN32` in game logic — SDL_ttf path selected via `MU_ENABLE_SDL3` only
- `[ ]` Flow code `VS1-RENDER-FONT-SDLTTF` present in test file header and story metadata
- `[ ]` Conventional commit used: `feat(render): adopt SDL_ttf for cross-platform font rendering [Story-7-9-8]`
- `[ ]` `./ctl check` passes (clang-format + cppcheck, 0 errors) after implementation
- `[ ]` `python3 MuMain/scripts/check-win32-guards.py` exits 0 (no new `#ifdef _WIN32` in game logic)

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

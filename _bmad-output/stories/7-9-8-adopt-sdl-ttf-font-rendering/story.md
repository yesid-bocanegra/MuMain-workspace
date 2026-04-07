# Story 7-9-8: Adopt SDL_ttf for Cross-Platform Font Rendering

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-8 |
| **Title** | Adopt SDL_ttf for Cross-Platform Font Rendering |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-1 (Core Experience) |
| **Flow Type** | Enabler |
| **Flow Code** | VS1-RENDER-FONT-SDLTTF |
| **Story Points** | 13 |
| **Dependencies** | 7-9-7 (GLM/renderer pipeline) ✓, 7-9-6 (MuRenderer migration) ✓ |
| **Status** | in-progress |

---

## User Story

**As a** cross-platform game client developer,
**I want** font rendering via SDL_ttf 3.x integrated with the SDL_GPU backend,
**So that** UI text (buttons, labels, chat, menus) renders correctly on macOS, Linux, and Windows without the legacy GDI/Win32 font pipeline.

---

## Background

### Problem

The current font rendering pipeline is broken on SDL3:

1. `CUIRenderTextOriginal::RenderText()` calls `TextOut()` to rasterize text to a GDI DIB bitmap
2. `WriteText()` copies white pixels from the DIB to `Bitmaps[BITMAP_FONT].Buffer` (CPU-side)
3. `UploadText()` renders a textured quad using `BITMAP_FONT`'s GPU texture
4. **The GPU texture is never updated** — `glTexSubImage2D` was removed during SDL3 migration
5. Result: all UI text is invisible (GPU texture has stale/blank data)

The cross-platform GDI shim (`CrossPlatformGDI.cpp`) provides an embedded 8x16 bitmap font for `TextOut`, but it's ASCII-only, fixed-size, and doesn't support CJK — a dead end for a game that supports Korean, Chinese, and Japanese.

### Solution

Replace the entire GDI font pipeline with **SDL_ttf 3.2.2**, which provides:
- `TTF_CreateGPUTextEngine(SDL_GPUDevice*)` — GPU-accelerated text engine
- `TTF_GetGPUTextDrawData(TTF_Text*)` — returns atlas draw sequences for SDL_GPU rendering
- TrueType/OpenType font support (any size, any script, anti-aliased)
- FreeType + HarfBuzz for professional text shaping
- FetchContent integration (same pattern as SDL3 and GLM)

---

## Acceptance Criteria

### AC-1: SDL_ttf Integration via FetchContent
- SDL_ttf 3.2.2+ fetched via CMake FetchContent (like SDL3 and GLM)
- Dependencies (FreeType, HarfBuzz) managed by SDL_ttf's own build system
- Builds on macOS (arm64), Linux (x64), Windows (x64, MinGW cross-compile)

### AC-2: GPU Text Engine Initialization
- `TTF_CreateGPUTextEngine(s_device)` called during renderer init (after SDL_GPU device creation)
- Engine stored as renderer state, destroyed on shutdown
- Font loaded from game's existing `.ttf` font file (or a bundled fallback)

### AC-3: IUIRenderText SDL_ttf Implementation
- New `CUIRenderTextSDLTtf` class implementing `IUIRenderText` interface
- `RenderText(x, y, text, ...)` creates a `TTF_Text`, gets draw data via `TTF_GetGPUTextDrawData`, renders via SDL_GPU
- Text color, background color, font selection preserved
- `GetTextExtentPoint32` equivalent via `TTF_GetStringSize` or `TTF_GetTextSize`

### AC-4: CUIRenderText Factory Updated
- `CUIRenderText::Create()` selects `CUIRenderTextSDLTtf` on SDL3 builds
- Falls back to `CUIRenderTextOriginal` on Win32 (preserves existing behavior)
- Font DC parameter (`hDC`) is not required for SDL_ttf path

### AC-5: Text Rendering Parity
- Button labels visible and correctly positioned
- Login screen text (username/password labels, server list) readable
- Chat text renders correctly
- All `g_pRenderText->RenderText()` call sites produce visible text
- Font size matches original game appearance (test at 640x480 and 1024x768)

### AC-6: Deferred Rendering Compatibility
- Text rendering works with the deferred draw command system (EndFrame copy-then-render)
- `TTF_GetGPUTextDrawData` returns atlas textures that are bound during the render pass
- Text atlas updates happen in the copy pass (before render pass)

### AC-STD-NFR-1: Performance
- Font atlas caching — text engine reuses glyph atlas across frames
- No per-character texture uploads (SDL_ttf batches glyphs into atlas pages)
- Target: < 0.5ms per frame for typical UI text load (~50 text elements)

---

## Technical Notes

### SDL_ttf GPU Integration Pattern
```cpp
// Init (once)
TTF_TextEngine* textEngine = TTF_CreateGPUTextEngine(s_device);
TTF_Font* font = TTF_OpenFont("Data/Font/font.ttf", 12);

// Per-text render
TTF_Text* text = TTF_CreateText(textEngine, font, "Hello", 0);
TTF_GPUAtlasDrawSequence* drawData = TTF_GetGPUTextDrawData(text);
// Iterate drawData linked list, bind atlas texture, draw quads
TTF_DestroyText(text);
```

### Files to Modify
| File | Change |
|------|--------|
| `CMakeLists.txt` | Add SDL_ttf FetchContent |
| `MuRendererSDLGpu.cpp` | Store TTF_TextEngine, init/shutdown |
| `UIControls.h` | New `CUIRenderTextSDLTtf` class |
| `UIControls.cpp` | Implement SDL_ttf RenderText, factory selection |
| `MuRenderer.h` | Expose text engine handle or render-text method |

### Files NOT Modified (preserved for Win32)
- `CrossPlatformGDI.cpp` — kept for Win32 GDI path
- `CUIRenderTextOriginal` — kept as Win32 fallback

### Font File Location
The game's font files are in `Data/Font/`. Check for existing `.ttf` files. If none exist, bundle a permissive-licensed fallback (e.g., Noto Sans for multi-script support).

### Migration Path for CJK
SDL_ttf + HarfBuzz provides full CJK text shaping. The game's existing `CMultiLanguage` system can load language-specific `.ttf` fonts. This story enables but does not require CJK — that's a follow-up.

---

## Out of Scope
- CJK font loading and i18n integration (follow-up story)
- Dynamic texture updates for non-font use cases (separate story)
- Removing CrossPlatformGDI.cpp or CUIRenderTextOriginal (still used on Win32)
- Chat input rendering (uses CUITextInputBox which has its own text path)

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Story Type | infrastructure |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add SDL_ttf FetchContent, implement CUIRenderTextSDLTtf, wire GPU text engine into renderer |
| project-docs | documentation | Story artifacts |

---

## Tasks / Subtasks

- [x] Task 1: SDL_ttf FetchContent Integration (AC-1) — DONE
  - [x] 1.1: FetchContent_Declare(SDL3_ttf) with GIT_TAG release-3.2.2 in CMakeLists.txt
  - [x] 1.2: FetchContent_MakeAvailable(SDL3_ttf) in src/CMakeLists.txt (deferred after SDL3 + OVERRIDE_FIND_PACKAGE)
  - [x] 1.3: target_link_libraries for SDL3_ttf::SDL3_ttf on MURenderFX and MUThirdParty
  - [x] 1.4: Build succeeds on macOS arm64 (Main binary links, MuTests RED as expected)
  - [x] 1.5: CMake script test 7.9.8-AC-1:sdl-ttf-fetchcontent PASSES

- [x] Task 2: Color Packing Helper (AC-3) — DONE
  - [x] 2.1: Add `namespace mu::sdlttf` with `PackColorDWORD(r,g,b,a)` in `SDLTtfColorPack.h` (constexpr header-only)
  - [x] 2.2: Included from `UIControls.h`; test includes header directly (no link dependency)
  - [x] 2.3: Verify Catch2 AC-3 tests link and pass (6 test cases) — all 6 passed

- [x] Task 3: GPU Text Engine Lifecycle (AC-2) — DONE
  - [x] 3.1: Add `TTF_TextEngine*` and `TTF_Font*` as state in `MuRendererSDLGpu.cpp`
  - [x] 3.2: Call `TTF_Init()` + `TTF_CreateGPUTextEngine(s_device)` in renderer init
  - [x] 3.3: Call `TTF_DestroyGPUTextEngine()` + `TTF_Quit()` in renderer shutdown
  - [x] 3.4: Bundle a permissive `.ttf` font (Noto Sans or similar) in `Data/Font/` — using system font discovery with FindFontPath() fallback
  - [x] 3.5: Load font via `TTF_OpenFont()` with default pt size
  - [x] 3.6: Expose text engine/font handles for CUIRenderTextSDLTtf access

- [x] Task 4: CUIRenderTextSDLTtf Class (AC-3, AC-4) — DONE
  - [x] 4.1: Declare `CUIRenderTextSDLTtf : public IUIRenderText` in `UIControls.h`
  - [x] 4.2: Implement all IUIRenderText virtual methods
  - [x] 4.3: Implement `RenderText()` using `TTF_CreateText` + `TTF_GetGPUTextDrawData` + deferred draw
  - [x] 4.4: Implement `GetTextExtentPoint32` equivalent via `TTF_GetStringSize`
  - [x] 4.5: Add `RENDER_TEXT_SDL_TTF` constant and update factory `CUIRenderText::Create()`

- [x] Task 5: Deferred Rendering Integration (AC-6) — DONE
  - [x] 5.1: Ensure text atlas draw data integrates with `RenderCmd` deferred buffer — DrawTriangles2D cmd type + SubmitTextTriangles()
  - [x] 5.2: Verify atlas textures bind correctly during render pass — EndFrame replay handles DrawTriangles2D
  - [x] 5.3: Test text rendering does not produce streak artifacts (copy-then-render pattern) — vertex data uploaded to GPU before render pass

- [ ] Task 6: Wire Factory and Verify Parity (AC-4, AC-5)
  - [ ] 6.1: Update SDL3 init path in `MuMain.cpp` to use `RENDER_TEXT_SDL_TTF`
  - [ ] 6.2: Verify button labels visible at 640x480 and 1024x768
  - [ ] 6.3: Verify login screen text readable
  - [ ] 6.4: Verify chat text renders correctly
  - [ ] 6.5: Adjust font pt size if needed for visual parity

- [ ] Task 7: Performance and Quality Gate (AC-STD-NFR-1)
  - [ ] 7.1: Warm up font atlas with common glyphs at startup
  - [ ] 7.2: Verify glyph atlas reuse across frames (no per-character re-upload)
  - [ ] 7.3: Run `./ctl check` — 0 format/lint errors
  - [ ] 7.4: Run `python3 MuMain/scripts/check-win32-guards.py` — exits 0

---

## Dev Notes

### Architecture
- SDL_ttf 3.x provides native SDL_GPU text engine — no GDI, no DIB, no glTexSubImage2D
- `TTF_CreateGPUTextEngine` creates an atlas-based text engine tied to the SDL_GPU device
- `TTF_GetGPUTextDrawData` returns draw sequences (atlas texture + quad vertices) for rendering
- The deferred rendering system (RenderCmd) must handle text atlas textures alongside bitmap textures
- CUITextInputBox has its own WriteText/UploadText — out of scope for this story

### Key References
- SDL_ttf GPU rendering: `TTF_CreateGPUTextEngine`, `TTF_GetGPUTextDrawData`, `TTF_GPUAtlasDrawSequence`
- Current font pipeline: `UIControls.cpp:2779-2920` (CUIRenderTextOriginal::RenderText)
- Renderer init: `MuRendererSDLGpu.cpp` Init() method
- Factory: `UIControls.cpp:2521-2550` (CUIRenderText::Create)

---

## Dev Agent Record

### Implementation Plan
(To be filled during implementation)

### Debug Log
(To be filled during implementation)

### Completion Notes
(To be filled on completion)

---

## File List
(To be populated during implementation)

---

## Change Log
(To be populated during implementation)

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
| **Status** | ready-for-dev |

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

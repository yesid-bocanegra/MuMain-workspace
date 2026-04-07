# Code Review — Story 7-9-8: Adopt SDL_ttf for Cross-Platform Font Rendering

| Field | Value |
|-------|-------|
| **Reviewer** | Claude (adversarial code review) |
| **Date** | 2026-04-07 |
| **Story Status** | dev-complete |
| **Quality Gate** | PASS (lint, build, coverage all passing — re-verified 2026-04-07) |

---

## Quality Gate

**Status: PASSED**

| Gate | Component | Status | Iterations | Issues Fixed |
|------|-----------|--------|------------|--------------|
| Backend Local (lint) | mumain | PASS | 0 | 0 |
| Backend Local (build) | mumain | PASS | 0 | 0 |
| Backend Local (coverage) | mumain | PASS (not configured) | 0 | 0 |
| Backend SonarCloud | mumain | N/A (not configured) | — | — |
| Frontend Local | — | N/A (no frontend) | — | — |
| Frontend SonarCloud | — | N/A (no frontend) | — | — |
| Schema Alignment | — | N/A (no frontend) | — | — |
| Boot Verification | mumain | N/A (game client, not server) | — | — |

**AC Tests:** Skipped (infrastructure story)

**Overall: PASSED** — All applicable quality gates green. Ready for code-review-analysis.

---

## Findings

### F-1 (HIGH): SetFont() is a no-op — all font variations silently ignored

| Attribute | Value |
|-----------|-------|
| **Severity** | HIGH |
| **File** | `MuMain/src/source/ThirdParty/UIControls.cpp` |
| **Lines** | 2975–2978 |
| **AC** | AC-5 (Text Rendering Parity) |

**Description:** The game defines 4 font handles (`g_hFont`, `g_hFontBold`, `g_hFontBig`, `g_hFixFont` in MuMain.cpp:86-89) and switches between them via `SetFont(HFONT)` across 20+ files (94 total references). The `CUIRenderTextSDLTtf::SetFont()` implementation is a complete no-op — the comment says "SDL_ttf uses TTF_Font, not HFONT." All text renders at the single default 14pt font regardless of what font variant the game code requests.

This means bold headers, large title text, and fixed-width text (inventory, stats) all render identically, losing visual hierarchy throughout the entire UI.

**Suggested Fix:** Map the 4 HFONT handles to pre-loaded `TTF_Font*` instances at different sizes/weights. Store the active font pointer in `CUIRenderTextSDLTtf` and apply it in `RenderText()`.

---

### F-2 (MEDIUM): Background color stored but never rendered

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/src/source/ThirdParty/UIControls.cpp` |
| **Lines** | 2980–3113 (entire RenderText method) |
| **AC** | AC-5 (Text Rendering Parity) |

**Description:** `m_dwBackColor` is stored via `SetBgColor()` but the `RenderText()` method never uses it. The original `CUIRenderTextOriginal::RenderText()` checks `if (m_dwBackColor != 0)` (line 2882) and renders a filled background rectangle via `RenderColor()` before the text. There are 20+ call sites that set visible backgrounds (e.g., line 1201: blue highlight `SetBgColor(40, 40, 150, 255)`, line 1227: orange `SetBgColor(255, 196, 0, 255)`, line 1248: black `SetBgColor(0, 0, 0, 255)`).

Text with colored backgrounds (chat highlights, selected items, tooltips) will render without their background rectangles.

**Suggested Fix:** In `RenderText()`, when `m_dwBackColor` has non-zero alpha, submit a filled quad (2 triangles) with the background color before the text glyph triangles.

---

### F-3 (MEDIUM): Per-frame TTF_Text object allocation/destruction churn

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/src/source/ThirdParty/UIControls.cpp` |
| **Lines** | 3062–3113 |
| **AC** | AC-STD-NFR-1 (Performance) |

**Description:** Every `RenderText()` call creates a new `TTF_Text` via `TTF_CreateText()`, extracts draw data via `TTF_GetGPUTextDrawData()`, then destroys it with `TTF_DestroyText()`. With ~50 UI text elements at 60fps, this is 3,000 allocations+destructions per second.

While SDL_ttf caches glyph atlas data internally (so rasterization is amortized), the `TTF_Text` object itself is heap-allocated each time. This creates unnecessary allocator pressure in the hot render path.

**Suggested Fix:** Consider caching `TTF_Text` objects per unique (string, font, color) tuple, or at minimum, pool the objects per frame. Alternatively, profile first to confirm whether this is actually a bottleneck before optimizing — SDL_ttf's internal allocator may be fast enough.

---

### F-4 (MEDIUM): Heap-allocated vector per atlas draw sequence in hot loop

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/src/source/ThirdParty/UIControls.cpp` |
| **Lines** | 3095–3110 |
| **AC** | AC-STD-NFR-1 (Performance) |

**Description:** Inside the atlas draw sequence loop (called per text element per frame), a `std::vector<mu::Vertex2D>` is allocated on the heap:
```cpp
std::vector<mu::Vertex2D> verts;
verts.reserve(static_cast<size_t>(seq->num_indices));
```
For 50 text elements with 1-2 atlas sequences each at 60fps, this is 3,000–6,000 heap allocations per second in the render path.

**Suggested Fix:** Use a `thread_local` or member scratch buffer that is reused across calls, only growing when needed. Example: `static thread_local std::vector<mu::Vertex2D> s_scratchVerts;` with a `clear()` + `reserve()` pattern.

---

### F-5 (LOW): Magic number `2` instead of named constant in MuMain.cpp

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/src/source/Main/MuMain.cpp` |
| **Lines** | 107 |
| **AC** | AC-4 |

**Description:** `int g_iRenderTextType = 2; // RENDER_TEXT_SDL_TTF` uses the magic number `2` with a comment, instead of the named constant `RENDER_TEXT_SDL_TTF` defined in `UIControls.h:796`. `MuMain.cpp` does not include `UIControls.h`. If the constant value ever changes, this initialization would silently diverge.

**Suggested Fix:** Include `UIControls.h` (or extract the constant to a shared header) and use `RENDER_TEXT_SDL_TTF` directly.

---

### F-6 (LOW): FindFontPath uses CWD-relative path

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` |
| **Lines** | 363 |
| **AC** | AC-2 |

**Description:** `FindFontPath()` searches `"Data/Font"` using a relative `std::filesystem::path`. This relies on the current working directory being the game's install directory. If the game is launched from a different CWD (e.g., via a shortcut, IDE debugger, or script), the game directory fonts won't be found and it will fall back to system fonts.

This is consistent with other `Data/` path usage in the codebase (e.g., `i18n.cpp:240` uses `L"Translations"`), so the risk is low — but it's worth noting.

**Suggested Fix:** Use `SDL_GetBasePath()` to resolve paths relative to the executable location, consistent with the SDL3 idiom.

---

### F-7 (LOW): Redundant SDL_GetWindowSize call per RenderText invocation

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/src/source/ThirdParty/UIControls.cpp` |
| **Lines** | 3079–3080 |
| **AC** | AC-STD-NFR-1 |

**Description:** `SDL_GetWindowSize(static_cast<SDL_Window*>(g_hWnd), &winW, &winH)` is called on every `RenderText()` invocation to get the window height for Y-axis flipping. Window size does not change mid-frame. With ~50 text elements per frame, this is 50 redundant API calls per frame.

**Suggested Fix:** Cache window dimensions at frame start (e.g., in `BeginFrame()`) or pass them through the renderer interface.

---

## Findings Summary

| ID | Severity | File | Issue |
|----|----------|------|-------|
| F-1 | **HIGH** | UIControls.cpp:2975 | SetFont() no-op ignores all font variations (bold, big, fixed) |
| F-2 | **MEDIUM** | UIControls.cpp:2980 | Background color stored but never rendered |
| F-3 | **MEDIUM** | UIControls.cpp:3062 | Per-frame TTF_Text object allocation churn |
| F-4 | **MEDIUM** | UIControls.cpp:3095 | Heap allocation per atlas draw sequence in hot loop |
| F-5 | **LOW** | MuMain.cpp:107 | Magic number instead of RENDER_TEXT_SDL_TTF constant |
| F-6 | **LOW** | MuRendererSDLGpu.cpp:363 | FindFontPath uses CWD-relative path |
| F-7 | **LOW** | UIControls.cpp:3079 | Redundant SDL_GetWindowSize per RenderText call |

**Total: 7 findings** (1 HIGH, 3 MEDIUM, 3 LOW)

---

## ATDD Coverage

### Checklist Accuracy

All ATDD items marked as checked (`[x]`) have verified implementation artifacts. No false completions found.

### Unchecked Items (correctly deferred)

| Phase | Item | Reason |
|-------|------|--------|
| Phase 1 | MinGW cross-compile verification | Not tested locally; CI handles this |
| Phase 3 | AC-2 GPU text engine SKIP removal | Requires live GPU device |
| Phase 5 | AC-6 deferred rendering SKIP removal | Requires running renderer |
| Phase 6 | Button labels at 640x480/1024x768 | Manual visual test — deferred to QA |
| Phase 6 | Login screen text readable | Manual visual test — deferred to QA |
| Phase 6 | Chat text renders correctly | Manual visual test — deferred to QA |
| Phase 6 | AC-5 SKIP removal | Requires running game |
| Phase 7 | Profile 50 RenderText calls | GPU timing — deferred to QA |
| Phase 7 | Total text submission < 0.5ms | GPU timing — deferred to QA |
| Phase 7 | AC-STD-NFR-1 SKIP removal | GPU timing — deferred to QA |

### Test Quality Assessment

- **6 passing tests**: All are AC-3 color packing tests — pure arithmetic, no GPU dependency. Tests are meaningful (not vacuous).
- **5 SKIP'd tests**: AC-2, AC-4, AC-5, AC-6, AC-STD-NFR-1 — all require GPU device or Win32 runtime. SKIP is the correct mechanism for CI.
- **1 CMake script test**: AC-1 FetchContent presence check — validates build integration at the CMake level.
- **Coverage gap**: No test exercises the `RenderText()` code path end-to-end. This is acceptable for an infrastructure story where the primary validation is "does the game render text visually" (manual QA).

---

## Reviewer Notes

The implementation is architecturally sound: SDL_ttf 3.x GPU text engine is correctly integrated into the deferred rendering pipeline, the factory pattern is properly extended, and the init/shutdown lifecycle handles error cases gracefully with appropriate fallbacks.

The HIGH finding (F-1: SetFont no-op) is the most significant concern for AC-5 (Text Rendering Parity). The game actively uses 4 different font handles, and the SDL_ttf path silently ignores all font switching. This will produce visible regressions in any UI that uses bold, large, or fixed-width text. However, the story's Out of Scope section does not explicitly exclude font variation support, and AC-3 specifies "font selection preserved" — which this implementation does not achieve.

The MEDIUM performance findings (F-3, F-4) should be profiled before fixing — SDL_ttf's internal allocator may be fast enough that the overhead is negligible at the current text volume.

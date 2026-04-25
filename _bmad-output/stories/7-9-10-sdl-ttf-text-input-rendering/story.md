# Story 7-9-10: SDL_ttf Text Rendering for CUITextInputBox

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-10 |
| **Title** | SDL_ttf Text Rendering for CUITextInputBox |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-1 (Core Experience) |
| **Flow Type** | Enabler |
| **Flow Code** | VS1-INPUT-TTFRENDER-SDL3 |
| **Story Points** | 8 |
| **Dependencies** | 7-9-8 (SDL_ttf font rendering) ✓, 7-9-9 (text input forms) ✓ |
| **Status** | done (verified 2026-04-25 — shipped via dc085d27 + c1df16a0 + 4904d4ce) |

---

## User Story

**As a** player on macOS or Linux,
**I want** text in login, chat, and popup input fields rendered with anti-aliased TrueType fonts,
**So that** input text is crisp and readable at any resolution, matching the quality of UI labels.

---

## Background

### Problem

Story 7-9-9 made text input forms functional on SDL3, but the rendering uses an embedded 8×16 bitmap font (CrossPlatformGDI TextOut) that is blocky and blurry when upscaled. Meanwhile, all other UI text (labels, tooltips, menu items) renders crisply via SDL_ttf (CUIRenderTextSDLTtf from Story 7-9-8).

### Current Architecture (to be replaced on SDL3)

```
CUITextInputBox::Render (SDL3 path)
  ├─ memset(m_pFontBuffer, 0)           ← Clear 24-bit GDI bitmap
  ├─ Scale dc->pFont->nHeight           ← Temporary font scaling hack
  ├─ TextOut(m_hMemDC, m_szSDLText)     ← Embedded 8×16 bitmap font rasterizer
  ├─ WriteText(offset, w, h)            ← Copy 24-bit → 32-bit per-instance RGBA buffer
  └─ UploadText(sx, sy, w, h)           ← QueueTextureUpdate + RenderBitmap with per-instance GPU texture
```

### Target Architecture

```
CUITextInputBox::Render (SDL3 path — new)
  ├─ g_pRenderText->SetFont(m_hConfiguredFont)
  ├─ g_pRenderText->SetTextColor(m_dwTextColor)
  ├─ g_pRenderText->RenderText(pos_x, pos_y, displayText)   ← SDL_ttf GPU text engine
  └─ (caret rendered as a simple colored quad via RenderColor)
```

This eliminates: m_pFontBuffer, per-instance InputBoxTexture, WriteText, UploadText, font height scaling, CrossPlatformGDI TextOut dependency for input boxes.

---

## Acceptance Criteria

### AC-1: SDL_ttf renders text in CUITextInputBox on SDL3
- The SDL3 Render path calls `CUIRenderTextSDLTtf::RenderText` (or the TTF engine directly) instead of the GDI bitmap pipeline
- Text appears anti-aliased and crisp at any screen resolution (g_fScreenRate_x/y)
- Uses the font configured via `SetFont()` (g_hFixFont maps to the fixed TTF variant)
- **Testable:** unit test — create CUITextInputBox, call SetFont(g_hFixFont), set text "Hello", call Render, verify no GDI TextOut call occurs (mock or flag) and RenderText is invoked with "Hello"

### AC-2: Password masking works correctly
- `IsPassword()` boxes display asterisks (`*`) for each character in m_szSDLText
- The actual typed characters are preserved in m_szSDLText (not overwritten with asterisks)
- `GetText()` returns the real password, not the masked version
- **Testable:** unit test — set password mode, set text "secret", verify Render passes "******" to RenderText, verify GetText returns "secret"

### AC-3: Text updates per-frame as user types
- Each frame, the Render path uses the current `m_szSDLText` content
- Characters appear immediately after DoActionSub captures them from g_szSDLTextInput
- Backspace removes the last character and the display updates on the next frame
- **Testable:** integration test — set `g_szSDLTextInput = "ab"`, call DoActionSub, call Render, verify RenderText receives "ab"; simulate backspace, verify RenderText receives "a"

### AC-4: Caret (blinking cursor) is visible
- A blinking cursor indicator appears at the text insertion point when the box has focus
- The caret uses m_fCaretWidth and toggles visibility based on m_caretTimer (530ms period)
- Unfocused boxes do not show a caret
- **Testable:** unit test — set focus, verify caret quad is rendered at correct X position (after last character); set unfocused, verify no caret

### AC-5: Per-instance rendering — no shared buffer issues
- Each CUITextInputBox renders its own text independently via SDL_ttf
- Two visible input boxes (e.g., username + password) display their respective content without interference
- No shared BITMAP_FONT.Buffer or per-instance InputBoxTexture needed (SDL_ttf handles its own GPU resources)
- **Testable:** render two boxes with different text, verify each RenderText call receives the correct string

### AC-6: Text color and background honor SetTextColor/SetBackColor
- Text color from `SetTextColor(a, r, g, b)` is applied to the SDL_ttf rendered text
- Background area (if UIOPTION_PAINTBACK) uses SetBackColor via existing RenderColor path
- **Testable:** unit test — set text color, verify the color passed to CUIRenderTextSDLTtf matches

### AC-7: Existing SDL_ttf label rendering is not affected
- `g_pRenderText->RenderText()` calls from LoginWin, CharMakeWin, MsgWin, etc. continue to work
- Font selection (SetFont) works for all font variants (normal, bold, big, fixed)
- **Testable:** existing SDL_ttf tests pass (no regressions)

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project naming conventions (PascalCase functions, m_ members, Hungarian hints)
- [ ] **AC-STD-NFR-1:** Quality gate passes (`./ctl check` — format + lint)
- [ ] **AC-STD-2:** Tests cover the SDL3 rendering path changes (unit tests for AC-1 through AC-6)

---

## Technical Notes

### What Changes

| Current (to remove on SDL3) | Replacement |
|------------------------------|-------------|
| `memset(m_pFontBuffer)` + `TextOut()` | `g_pRenderText->RenderText(x, y, text)` |
| `WriteText()` — 24→32-bit copy to per-instance buffer | Eliminated — SDL_ttf handles GPU text directly |
| `UploadText()` — QueueTextureUpdate + RenderBitmap | Eliminated — DrawTriangles2D RenderCmd from SDL_ttf |
| `InputBoxTexture` static map (s_inputBoxTexMap) | Eliminated — no per-instance GPU textures needed |
| Font height scaling hack (dc->pFont->nHeight) | Eliminated — SDL_ttf renders at correct DPI natively |
| `m_fCaretHeight` override to scaled buffer height | Compute from TTF_GetTextSize or font metrics |

### What Stays

- `DoActionSub()` — SDL text input capture into m_szSDLText (unchanged)
- `GiveFocus()` — SDL3 idempotent focus with edge-trigger (unchanged)
- `m_hMemDC` / `m_pFontBuffer` — kept for Win32 path (GDI edit control)
- `WriteText()` / `UploadText()` — kept for Win32 path

### Caret Implementation

On Win32, the caret was rendered by the native edit control. On SDL3, the current code checks `GetFocus() == m_hEditWnd` which always returns false (sentinel != nullptr). The fix:

```cpp
// SDL3: use m_bSDLHasFocus instead of GetFocus() == m_hEditWnd
bool isFocused = m_bSDLHasFocus;
bool showCaret = isFocused && ((int)(m_caretTimer.GetTimeElapsed()) / 530) % 2 == 0;
if (showCaret)
{
    // Render a 2px-wide colored rectangle at the text insertion point
    float caretX = pos_x + textWidth;
    RenderColor(caretX, pos_y, m_fCaretWidth, fontHeight);
    EndRenderColor();
}
```

### Key Files

| File | Change |
|------|--------|
| `ThirdParty/UIControls.cpp` | CUITextInputBox::Render SDL3 path — replace GDI pipeline with SDL_ttf RenderText + caret quad |
| `ThirdParty/UIControls.cpp` | Remove InputBoxTexture infrastructure (struct, static map, EnsureInputBoxTexture, CleanupInputBoxTexture) |
| `ThirdParty/UIControls.cpp` | WriteText SDL3 path — remove per-instance buffer usage (keep Win32 path) |
| `ThirdParty/UIControls.h` | No changes expected |
| `RenderFX/MuRendererSDLGpu.cpp` | QueueTextureUpdate buffer snapshot can be simplified once BITMAP_FONT is no longer used by input boxes |

### Dependencies Already in Place

- SDL_ttf 3.2.2 GPU text engine (Story 7-9-8)
- `CUIRenderTextSDLTtf::RenderText()` with font selection, color packing, DrawTriangles2D submission
- Four TTF font variants: normal, bold, big, fixed (glyph atlas warmed at init)
- `TTF_GetGPUTextDrawData` → `SubmitTextTriangles` deferred rendering path

---

## Out of Scope

- CJK/IME composition (follow-up story)
- Multi-line text editing with scrollbar
- Replacing CUIRenderTextOriginal for Win32 builds
- Text selection (highlight + copy/paste)

---

## Dev Notes

### Implementation Approach

1. In `CUITextInputBox::Render()` SDL3 path, replace the block between `#ifdef MU_ENABLE_SDL3` and `#else` with:
   - Build display string (password mask or m_szSDLText)
   - Call `g_pRenderText->SetFont(m_hConfiguredFont)` / `SetTextColor` / `SetBgColor`
   - Call `g_pRenderText->RenderText(screenX, screenY, displayText)`
   - Render caret quad if focused and timer says visible
2. Remove `EnsureInputBoxTexture`, `CleanupInputBoxTexture`, `s_inputBoxTexMap`, `InputBoxTexture` struct
3. Remove the `#ifdef MU_ENABLE_SDL3` path in WriteText that uses `pDstBuffer` (revert to simple BITMAP_FONT.Buffer for Win32)
4. Keep the font height scaling removal (SDL_ttf handles this natively)
5. The RenderText coordinates should be in virtual-pixel space (640×480), NOT physical pixels — CUIRenderTextSDLTtf handles the Y-flip and scaling internally

### PCC Project Constraints

- No raw `new`/`delete` — use `std::unique_ptr` for any new allocations
- `[[nodiscard]]` on fallible functions
- No `#ifdef _WIN32` in game logic — only in platform abstraction
- Quality gate: `./ctl check` (format + lint)

### References

- [Story 7-9-8: SDL_ttf adoption](_bmad-output/stories/7-9-8-adopt-sdl-ttf-font-rendering/story.md)
- [Story 7-9-9: Text input forms](_bmad-output/stories/7-9-9-sdl3-text-input-forms/story.md)
- [Source: docs/project-context.md]
- [Source: CLAUDE.md — Build Commands, Conventions]

---

## Dev Agent Record

### Implementation Plan
_(to be filled during dev-story)_

### Debug Log
_(to be filled during dev-story)_

### Completion Notes
_(to be filled during dev-story)_

---

## File List

| File | Status | Change |
|------|--------|--------|
| `ThirdParty/UIControls.cpp` | MODIFY | Replace GDI bitmap pipeline with SDL_ttf RenderText in SDL3 Render path; remove InputBoxTexture infrastructure; add caret rendering |
| `RenderFX/MuRendererSDLGpu.cpp` | MODIFY | Simplify QueueTextureUpdate once input boxes no longer use buffer snapshots |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-04-08 | Story created from 7-9-9 integration testing findings — bitmap font quality insufficient |

# Story 7-9-13: SDL3 Port of Ground-Item-Label Texture Cache

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-13 |
| **Title** | SDL3 Port of Ground-Item-Label Texture Cache |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-1 (Core Experience) |
| **Flow Type** | Enabler / Performance |
| **Flow Code** | VS1-INVENTORY-GROUNDLABEL-SDL3 |
| **Story Points** | 5 |
| **Priority** | P1 |
| **Story Type** | infrastructure |
| **Dependencies** | 7-9-6 (raw GL → mu::Renderer) ✓, 7-9-8 (SDL_ttf font rendering) ✓, 7-9-10 (SDL_ttf text input rendering) ✓ |
| **Status** | ready-for-dev |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| MuMain (game client) | c++20, sdl3, rendering | Port `Create/Render/Delete GroundItemLabelTexture` from GDI+OpenGL to SDL_ttf + `mu::Renderer`; widen `GroundItemLabelCacheEntry.TextureId`; remove three `#ifdef MU_ENABLE_SDL3` gates in `ZzzInventory.cpp`; remove SDL3 fallback branch in `RenderItemName`. |

---

## User Story

**[VS-1] [Flow:E]**

**As a** player on macOS or Linux in a dense drop area (Lorencia spawns, Devil Square wave, Blood Castle chest),
**I want** ground-item labels to render without re-rasterizing every label every frame,
**so that** framerate does not drop when 50+ labeled drops are on screen.

---

## Background

### Problem

Upstream PR #321 ("tooltips_fps") introduced a texture cache for ground-item labels in `ZzzInventory.cpp`
(`CreateGroundItemLabelTexture`, `RenderGroundItemLabelTexture`, `DeleteGroundItemLabelTexture`, plus the
plumbing in `RenderGroundItemLabelCached` / `PruneGroundItemLabelCache`). The cache produced a measurable
FPS win on Windows by avoiding per-frame GDI rasterization + OpenGL texture upload for each visible label.

The merge of `main` into `cross-platform-sdl-migration` (merge commit `f5d1d73e`) brought this code onto
the SDL3 branch, but the implementation uses APIs that don't exist on SDL3/macOS:

| API | Origin | Replacement on SDL3 |
|---|---|---|
| `HDC`, `FillRect`, `GetStockObject(BLACK_BRUSH)`, `GetTextExtentPoint32`, `TextOut`, `SetBkColor`, `SetTextColor` | Windows GDI | `SDL_ttf` rasterization (same path `CUIRenderTextSDLTtf` uses since 7-9-8) |
| `GLuint`, `glGenTextures`, `glBindTexture`, `glTexParameteri`, `glTexImage2D`, `glDeleteTextures` | Raw OpenGL | `mu::Renderer::RegisterTexture` / `QueueTextureUpdate` / `BindTexture` (SDL_GPU, per 7-9-6) |
| `glColor4ub`, `glColor4f` | OpenGL immediate-mode state | Per-draw vertex color on the UI pipeline |
| `_snwprintf_s` / `_TRUNCATE` | Microsoft CRT | `mu_swprintf_s` (already cross-platform in `stdafx.h` / `PlatformCompat.h`) |

### Current State (landed in fixup commit `1eeac9aa`)

To unblock the SDL3 build, the three texture-cache functions were gated behind `#ifdef MU_ENABLE_SDL3`
(lines 7528, 7966, 8063 of `ZzzInventory.cpp`):

- `CreateGroundItemLabelTexture` returns `false` on SDL3 → `RenderGroundItemLabelCached` also returns `false`.
- `RenderGroundItemLabelTexture` is an empty stub on SDL3.
- `DeleteGroundItemLabelTexture` is a no-op on SDL3.
- The else-branch in `RenderItemName` (line 8174) now checks the return of `RenderGroundItemLabelCached` and
  falls back to the direct `g_pRenderText->RenderText()` path when the cache is unavailable.
- `_snwprintf_s` was replaced with `mu_swprintf_s` in both template helpers (that change is permanent and
  applies to both platforms).

On SDL3 today, labels render correctly but **without caching** — every visible ground-item label rasterizes
its text every frame.

### Target Architecture

```
CreateGroundItemLabelTexture (SDL3 — new)
  ├─ TTF_SizeText(font, descriptor.Name, &w, &h)    ← measure in design units
  ├─ SDL_Surface* = TTF_RenderText_Blended(...)     ← antialiased alpha surface (NOT _Solid,
  │                                                   which produces aliased 1-bit-alpha edges)
  ├─ (ensure surface pixel format is SDL_PIXELFORMAT_RGBA32 — convert via SDL_ConvertSurface
  │   if TTF returns a different format for the chosen font variant)
  ├─ mu::Renderer::RegisterTexture(RGBA8, w, h)     ← create SDL_GPUTexture
  ├─ mu::Renderer::QueueTextureUpdate(id, surf)     ← upload pixels
  ├─ SDL_DestroySurface(surf)                       ← CPU surface no longer needed
  └─ cacheEntry.TextureId = renderer handle; return true

RenderGroundItemLabelTexture (SDL3 — new)
  ├─ (BgColor != 0) → RenderColor quad at (x-pad, y-pad, w+2pad, h+2pad) with vertex color
  ├─ mu::Renderer::BindTexture(cacheEntry.TextureId)
  └─ RenderBitmap quad at (o->ScreenX * g_fScreenRate_x - w/2, (o->ScreenY - 15) * g_fScreenRate_y)

DeleteGroundItemLabelTexture (SDL3 — new)
  └─ mu::Renderer::ReleaseTexture(handle) (or registry-unregister)
```

### What This Story Changes

Re-enable the texture-cache optimization on SDL3 using the same renderer and text-rasterization paths
already adopted by the cross-platform migration. Remove the `#ifdef MU_ENABLE_SDL3` branches so both
builds run the same code paths.

### What This Story Does NOT Change

- The cache key structure (`BuildGroundItemLabelCacheKey`), eviction policy (`PruneGroundItemLabelCache`),
  or budget (`SetGroundItemLabelBuildBudget`). These are platform-independent and fine as-is.
- The `RenderItemName` behavior on the `!Sort` branch (already uses the direct render path; unchanged).
- The project's cross-platform scope — Windows, macOS, and Linux are all first-class targets. All three
  route through the same `mu::Renderer` + SDL_ttf code after this story lands. There is no "Windows
  OpenGL path" to preserve; the Win32 GDI + raw-GL `#else` branches are what the story deletes.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `CreateGroundItemLabelTexture` on SDL3 rasterizes `descriptor.Name` via SDL_ttf into an
  `SDL_Surface`. Uses the font set via `ApplyGroundItemLabelDescriptor` / `descriptor.Font` — same
  font-selection path as the Windows branch.
  - **Testable:** unit test — construct a descriptor with a known name + font, call `CreateGroundItemLabelTexture`,
    verify returned `cacheEntry.TextWidth`/`TextHeight` match `TTF_SizeText` output for that string.

- [ ] **AC-2:** `CreateGroundItemLabelTexture` on SDL3 creates/registers an `SDL_GPUTexture` via
  `mu::Renderer`, populates `cacheEntry.TextureId` with a renderer-specific handle, and returns `true`
  on success.
  - **Testable:** integration test — after `CreateGroundItemLabelTexture`, verify `mu::Renderer` reports
    one additional live texture and `cacheEntry.TextureId != 0`.

- [ ] **AC-3:** `RenderGroundItemLabelTexture` on SDL3 binds the cached texture via
  `mu::Renderer::BindTexture` and draws a textured quad at the same screen coordinates the Windows path
  uses: `(o->ScreenX * g_fScreenRate_x - TextWidth/2, (o->ScreenY - 15) * g_fScreenRate_y)`.
  - **Testable:** unit test — render one entry and capture the issued draw command; verify texture handle
    matches `cacheEntry.TextureId` and quad bounds match the Windows formula.

- [ ] **AC-4:** `RenderGroundItemLabelTexture` on SDL3 draws the background rect using `cacheEntry.BgColor`
  when non-zero, matching the Windows `glColor4ub` + `RenderColor` behavior. Uses **per-draw vertex color**
  on the UI pipeline (no `glColor4ub`, no immediate-mode color state).
  - **Testable:** unit test — set `cacheEntry.BgColor = 0xAARRGGBB`, render, verify the BG quad uses vertex
    color with those bytes unpacked.

- [ ] **AC-5:** `DeleteGroundItemLabelTexture` on SDL3 releases the `SDL_GPUTexture` (or removes it from
  the renderer registry) so `PruneGroundItemLabelCache` actually frees GPU memory.
  - **Testable:** integration test — fill N entries, advance idle timer past eviction threshold, trigger
    prune, verify renderer live-texture count returns to baseline.

- [ ] **AC-6:** All three `MU_ENABLE_SDL3` gates in `ZzzInventory.cpp` are removed. Note the spelling
  varies: `DeleteGroundItemLabelTexture` uses `#ifndef MU_ENABLE_SDL3` (line 7528) while
  `CreateGroundItemLabelTexture` (line 7966) and `RenderGroundItemLabelTexture` (line 8063) use
  `#ifdef MU_ENABLE_SDL3`. A find-and-delete that matches only one form will miss the Delete site.
  Windows and SDL3 builds run the same `Create/Render/Delete` code paths after removal.
  - **Testable:** `grep MU_ENABLE_SDL3 MuMain/src/source/Gameplay/Items/ZzzInventory.cpp` returns no
    matches (the grep is form-agnostic and catches both `#ifdef` and `#ifndef`).

- [ ] **AC-7:** The fallback branch in `RenderItemName` (the SDL3 direct-render fallback added in
  `1eeac9aa` at line 8174) is removed. The else-branch becomes
  `RenderGroundItemLabelCached(o, ip);` (return ignored) as it was pre-fix, because the cache is always
  available now.
  - **Testable:** code review + grep — no reference to `g_pRenderText->RenderText` under the sorted/else
    branch of `RenderItemName`.

### Non-Functional

- [ ] **AC-NFR-1:** In a dense-drop scene, SDL3/macOS average frame time with this story is measurably
  lower than the direct-render fallback path. Capture before/after via the `frame_time` instrumentation
  from Story 7-2-1.
  - **Repro scene:** Lorencia near the spawn point, camera stationary, at least 30 labeled ground items
    in view, no running animations from Hero. Hold identical scene for the A and B capture (use the same
    character position + camera angle + drop set; kill a monster pack, let drops settle, then capture
    both builds without moving).
  - **Protocol:** 10-second rolling mean at a 60fps vsync target, captured once labels have been in-view
    for ≥ 2 seconds (cache warm). Report `mean`, `p95`, and `worst-frame` frame_time for A (fallback)
    and B (cached). Both builds must run in the same resolution, same window-vs-fullscreen mode, same
    DPI scale.
  - **Acceptance:** mean `frame_time` improvement ≥ 15% in the repro scene; numeric results + a short
    narrative attached to Dev Agent Record.
  - **Rollback trigger:** if A/B shows < 5% mean improvement OR B is measurably slower, STOP and
    escalate — do not merge the cache rewrite. Likely root causes in that case: `QueueTextureUpdate`
    overhead dominates at these texture sizes, or the cache churn from short-lived drops defeats the
    win. Either needs its own investigation before this story is mergeable.

- [ ] **AC-NFR-2:** No GPU memory leak when walking through many drops over several minutes. Verify via
  `mu::Renderer` diagnostics — live texture count returns to baseline after `PruneGroundItemLabelCache`
  fires on idle labels.

- [ ] **AC-NFR-3:** Visual parity with the direct-render fallback — item name, text color, background
  color, centering, and drop shadow (if any) are indistinguishable in A/B screenshots at 1920×1080 and
  at DPI scale 1.0 / 2.0 (Retina).

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project naming conventions (PascalCase functions, `m_` members, Hungarian
  hints for legacy code). No raw `new`/`delete`; no `NULL`; no `#ifdef _WIN32` in game logic.
- [ ] **AC-STD-2:** Catch2 tests cover the rendering-path changes (unit tests for AC-1 through AC-5).
  Tests must not depend on Win32 APIs — logic only. New tests live under `MuMain/tests/gameplay/`
  mirroring source layout, compiled under `-DBUILD_TESTING=ON`.
- [ ] **AC-STD-NFR-1:** Quality gate passes (`./ctl check` — format-check + cppcheck). Pre-existing
  Dotnet errors (e.g. `dotnet_SendDuelStartResponse`, `SendPlayerShopClose*`) may still appear; this
  story does not need to resolve them.
- [ ] **AC-STD-3:** Observability — on `CreateGroundItemLabelTexture` failure path, write a diagnostic
  via `g_ErrorReport.Write(L"...")`. No `wprintf` / dead logging channels.
- [ ] **AC-STD-4:** No incomplete rebase, no force-push, submodule bumped cleanly.

> Frontend/API-specific AC-STDs from the project catalog (SLO, API catalog, error catalog, Pencil-backed
> UI) do not apply — this is C++ rendering code, not an HTTP API or .pen document.

---

## Tasks / Subtasks

- [ ] **Task 1 — SDL_ttf rasterization for the cache** (AC-1, AC-6)
  - [ ] 1.1 Replace the GDI section of `CreateGroundItemLabelTexture` (roughly lines 7964–7977 today)
    with an SDL_ttf call returning an `SDL_Surface`. Use `TTF_SizeText` / `TTF_SizeUNICODE` to measure
    `textSize` instead of `GetTextExtentPoint32`. Reference: `CUIRenderTextSDLTtf` introduced in 7-9-8.
  - [ ] 1.2 Honor `descriptor.Font` (normal / bold / big / fixed) — map to the same TTF variants
    `CUIRenderTextSDLTtf::SetFont` resolves.
  - [ ] 1.3 Call `SDL_DestroySurface` on the CPU surface after upload.

- [ ] **Task 2 — SDL_GPU texture creation** (AC-2, AC-6)
  - [ ] 2.1 Replace the `glGenTextures` / `glTexImage2D` block (lines 8012–8024) with
    `mu::Renderer::RegisterTexture` + `mu::Renderer::QueueTextureUpdate` (same pattern 7-9-6 settled on
    for one-off UI textures).
  - [ ] 2.2 Widen `cacheEntry.TextureId` from `GLuint` to the renderer handle type (`std::uint32_t` or
    whatever `mu::Renderer::RegisterTexture` returns). Update `GroundItemLabelCacheEntry` at line 7426
    and all call sites.

- [ ] **Task 3 — Draw path** (AC-3, AC-4, AC-6)
  - [ ] 3.1 Rewrite `RenderGroundItemLabelTexture` body (lines 8057–8065 for the BG rect, 8066–8069
    for the texture quad) to use `mu::Renderer::BindTexture` + `RenderBitmap` (the pattern used in
    `ThirdParty/UIControls.cpp` font-upload site).
  - [ ] 3.2 Background rect uses **per-draw vertex color** on the UI pipeline — no `glColor4ub`, no
    immediate-mode state.
  - [ ] 3.3 Double-check Y-coordinate handling — ground-item labels use `o->ScreenX` / `o->ScreenY`
    from world projection. Verify against a known-working SDL3 UI element at world-projected positions.

- [ ] **Task 4 — Delete path** (AC-5, AC-6)
  - [ ] 4.1 Implement `DeleteGroundItemLabelTexture` using `mu::Renderer`'s unregister/release API.
  - [ ] 4.2 Verify `PruneGroundItemLabelCache` still correctly evicts idle entries and that the
    renderer's live-texture count returns to baseline.

- [ ] **Task 5 — Unify the code path across Windows / macOS / Linux** (AC-6, AC-7)
  - [ ] 5.1 Delete the `MU_ENABLE_SDL3` gate + the entire Win32/GDI/raw-GL `#else` branch from all three
    functions in `ZzzInventory.cpp` (lines 7528, 7966, 8063). The new SDL_ttf + `mu::Renderer`
    implementation runs on all platforms — no platform-specific fork remains.
  - [ ] 5.2 Delete the else-branch fallback in `RenderItemName` (line 8174). Restore to
    `RenderGroundItemLabelCached(o, ip);` with the return value ignored.
  - [ ] 5.3 Verify Windows MSVC build (`ctl` / CMake preset `windows-x64`) still compiles and runs the
    unified path after the `#else` branches are gone. Project scope is cross-platform first-class —
    Windows is not optional.

- [ ] **Task 6 — Perf measurement** (AC-NFR-1)
  - [ ] 6.1 Capture `frame_time` (from Story 7-2-1 instrumentation) in the repro scene on macOS:
    (a) current fallback path, (b) this story's cached path.
  - [ ] 6.2 Attach before/after numbers and a short narrative to this story's Dev Agent Record.
  - [ ] 6.3 Capture A/B screenshots for AC-NFR-3 visual parity.

---

## Files to Touch

| File | Status | Change |
|------|--------|--------|
| `MuMain/src/source/Gameplay/Items/ZzzInventory.cpp` | MODIFY | Port `Create/Render/Delete GroundItemLabelTexture` to SDL_ttf + `mu::Renderer`; widen `GroundItemLabelCacheEntry.TextureId` (line 7426); remove three `#ifdef MU_ENABLE_SDL3` gates (lines 7528, 7966, 8063); remove SDL3 fallback branch in `RenderItemName` (line 8174). |
| `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` (possibly) | MODIFY | Only if a new "register text-glyph texture" helper is appropriate — evaluate during Task 2; the existing `RegisterTexture` + `QueueTextureUpdate` + `BindTexture` trio is likely sufficient. |
| `MuMain/tests/gameplay/test_ground_item_label_cache.cpp` | CREATE | New Catch2 test covering AC-1..AC-5 (no Win32 dependencies). |

No header changes expected in `ZzzInventory.h`.

---

## Out of Scope

- Changing the cache key (`BuildGroundItemLabelCacheKey`), eviction policy, or budget logic.
- Retiring the Windows MSVC build — that's a separate scope decision owned by Feature 7.9 as a whole.
- Tooltip caching for hovered inventory items (different cache, different path).
- CJK/IME label rendering — reuses whatever SDL_ttf path applies; no new work here.
- **Font-switch invalidation** — the current cache key hashes `AncientDiscriminator` and `FeatureFlags`
  but not the active font. If a future story introduces runtime font switching (locale change, UI
  scale toggle, accessibility size adjustment), cached textures will render with the stale font until
  eviction. Acceptable for this story because no runtime font switch exists on SDL3 today; flag as a
  prerequisite fix in whichever story introduces font switching.

---

## Dev Notes

### Implementation Approach

1. Start with `CreateGroundItemLabelTexture` — get SDL_ttf rasterization working to an `SDL_Surface`
   using `descriptor.Name` and the font resolved from `descriptor.Font`. Mirror the font-selection
   logic from `CUIRenderTextSDLTtf::SetFont`.
2. Hand the surface to `mu::Renderer::RegisterTexture` + `QueueTextureUpdate`. Store the returned
   handle in `cacheEntry.TextureId` — this likely requires widening the struct field. Destroy the
   CPU surface after upload.
3. Rewrite `RenderGroundItemLabelTexture` to issue one BG-rect `RenderColor` (when `BgColor != 0`)
   and one `RenderBitmap` for the text quad. Per-draw vertex color carries the BG color; no
   immediate-mode `glColor*` anywhere.
4. Implement `DeleteGroundItemLabelTexture` via `mu::Renderer`'s release API. `PruneGroundItemLabelCache`
   already drives this; it just needs a real implementation.
5. Remove the three `#ifdef MU_ENABLE_SDL3` gates in one commit so Windows and SDL3 run the same code.
   Remove the `RenderItemName` fallback branch in the same commit.
6. Verify with `check-win32-guards.py` that no new `#ifdef _WIN32` crept in.
7. Measure before/after `frame_time` in the repro scene on macOS. Attach the numbers.

### Why the TextureId Widens

The current struct field:
```cpp
struct GroundItemLabelCacheEntry {
    GLuint TextureId = 0;   // ← raw OpenGL handle, dies with OpenGL
    ...
};
```

`mu::Renderer` (post-7-9-6) does not hand out raw `GLuint`s — it hands out a renderer-specific handle
(likely `std::uint32_t` or a typedef). The field must change type, or we need a conversion helper.
Check the exact `mu::Renderer::RegisterTexture` signature during Task 2 and pick the minimal change
(typedef alias > conversion helper > value-preserving cast). Avoid leaking a renderer type name into
a gameplay header — if the renderer handle is a typedef, import the typedef; if it's a class, store an
opaque `std::uint32_t`.

### Coordinate Handling

`o->ScreenX`, `o->ScreenY` are already in SDL-ready world-projected space (per the Windows path). Do
**not** divide by `g_fScreenRate` again at the call site — the Windows formula
`o->ScreenX * g_fScreenRate_x - TextWidth/2` is correct and must be preserved. One caution from 7-9-10:
`CUIRenderTextSDLTtf::RenderText` returns its `lpTextSize->cx/cy` in **design units** (already divided
by `g_fScreenRate` at lines 3112–3113 of `UIControls.cpp`). If you reuse `CUIRenderTextSDLTtf` to
measure text, do NOT divide again at the call site.

### Stateful Text Renderer Caveat (from 7-9-10)

`CUIRenderTextSDLTtf` is stateful/global — if you route through `g_pRenderText` for measurement, callers
must set BOTH `SetTextColor` AND `SetBgColor` or the text will inherit whatever the prior caller left.
Prefer direct `TTF_SizeText` / `TTF_SizeUNICODE` for measurement here; the label owns its own texture
and color state.

### Vertex Color Packing Is ABGR, Not ARGB

The `mu::Vertex2D.color` field is packed **ABGR** on disk (alpha in the high byte, then B, G, R going
low). This is despite the project's `_ARGB` macro in `UIControls.h:15` which is named ARGB but inlines
`(a<<24) | (b<<16) | (g<<8) | r` — the macro name is misleading. When building the BG-rect vertex
color for AC-4, pack bytes as:

```cpp
const std::uint32_t abgr = (alpha << 24) | (blue << 16) | (green << 8) | red;
```

NOT the conventional ARGB layout (`(a<<24)|(r<<16)|(g<<8)|b`). `RenderColorQuadARGB` at
`ZzzOpenglUtil.cpp:1099` accepts an ARGB-named parameter and internally flips to ABGR — if you use
that helper, pass ARGB; if you pack vertices directly via `RenderQuad2D`, pack ABGR. Matching the
pattern at `ZzzOpenglUtil.cpp:1033-1082` (the existing `RenderColor` impl) is the safest reference.

### PCC Project Constraints

- **C++20** — `std::unique_ptr` for any new allocations; no raw `new`/`delete`.
- **No `#ifdef _WIN32`** in game logic — the fix for a cross-platform error is to add a stub to
  `PlatformCompat.h`, never to wrap the call site. `check-win32-guards.py` enforces this.
- **No `NULL`** — `nullptr` only.
- **Logging** — `g_ErrorReport.Write(L"...")` for diagnostics (MuError.log); never `wprintf` or the
  dead `__TraceF()` / `DebugAngel` / `ExecutionLog` channels.
- **`[[nodiscard]]`** on new fallible functions.
- **Quality gate** — `./ctl check` (clang-format 21.1.8 + cppcheck). Must pass 0 errors before marking
  `ready-for-review`.
- **Prohibited cross-platform patterns** — no raw `GLuint` in new cross-platform surface area; no
  `glColor4ub` / `glColor4f` on the SDL_GPU path.

### Dependencies Already in Place

- SDL_ttf 3.2.2 GPU text engine (Story 7-9-8) — `TTF_SizeText`, `TTF_RenderText_Blended`,
  `TTF_CreateGPUTextEngine`, `DrawTriangles2D` RenderCmd.
- `mu::Renderer` cross-platform texture API (Story 7-9-6) — `RegisterTexture`, `QueueTextureUpdate`,
  `BindTexture`, release/unregister.
- `CUIRenderTextSDLTtf` as a reference for font selection and scaling (Story 7-9-10).
- `frame_time` instrumentation (Story 7-2-1) for AC-NFR-1 measurement.

### References

- Temporarily disabled cache: commit `1eeac9aa` (this branch)
- Introduced via upstream merge: merge commit `f5d1d73e`
- Upstream origin PR: https://github.com/sven-n/MuMain/pull/321 ("tooltips_fps")
- SDL_ttf precedent in this codebase: [Story 7-9-10](../7-9-10-sdl-ttf-text-input-rendering/story.md), commit `dc085d27`
- SDL_gpu renderer migration: [Story 7-9-6](../7-9-6-migrate-raw-gl-to-murenderer/story.md)
- Frame-time instrumentation for perf measurement: [Story 7-2-1](../7-2-1-frame-time-instrumentation/story.md)
- [Source: docs/project-context.md — Banned Win32 APIs, Modern C++, Logging]
- [Source: docs/development-standards.md]
- [Source: CLAUDE.md — Build Commands, Conventions, MuMain submodule]

---

## Risks / Open Questions

- **`TextureId` field type:** Widening from `GLuint` is guaranteed needed; the exact type depends on
  `mu::Renderer::RegisterTexture`'s return type. Confirm during Task 2 to avoid a second widening pass.
- **`RenderBitmap` Y-space inconsistency:** The SDL3 path flips Y in some call sites and not others.
  Verify the label's screen-space math against a known-working SDL3 UI element drawn at world-projected
  positions before declaring AC-3 done.
- **Cross-platform verification:** Dev environment is macOS. The unified path must also be verified on
  Windows (`windows-x64` preset) and Linux before the story marks `done`. Catching a Windows regression
  at review is cheap; catching it after merge breaks the first-class cross-platform guarantee.

---

## Dev Agent Record

### Agent Model Used

_(to be filled during dev-story)_

### Implementation Plan

_(to be filled during dev-story)_

### Debug Log References

_(to be filled during dev-story)_

### Completion Notes

_(to be filled during dev-story)_

### File List

_(to be filled during dev-story)_

---

## Change Log

| Date | Change |
|------|--------|
| 2026-04-23 | Story created from `MuMain/docs/ground-item-label-sdl3-cache-story-draft.md` via PCC create-story workflow. Technical claims verified against `ZzzInventory.cpp` (lines 7426, 7528, 7966, 8063, 8174). |
| 2026-04-23 | Filled 7 review gaps: (1) AC-6 clarified that Delete uses `#ifndef` while Create/Render use `#ifdef`; (2) added ABGR-vs-ARGB vertex-color packing caveat in Dev Notes; (3) expanded AC-NFR-1 with concrete A/B measurement protocol and rollback trigger; (4) added font-switch invalidation to Out of Scope; (5) Target Architecture now explicit that `TTF_RenderText_Blended` (not `_Solid`) is required and pixel format must be normalized; (6) rollback bullet added to AC-NFR-1 covers the perf-regression case; (7) renumbered AC-STD-13/14/15/16 → AC-STD-2/3/4 + AC-STD-NFR-1 to match sibling stories (7-9-10, 7-9-11, 7-9-12) and removed duplicate AC-STD-15 reference. |
| 2026-04-23 | Removed the bogus "Windows path retirement" open question. Cross-platform (Windows + macOS + Linux) is the project's scope — Windows is a first-class target, not optional. Task 5 now simply deletes the Win32/GDI/raw-GL `#else` branches along with the `#ifdef` gates; Task 5.3 becomes Windows MSVC build verification. |

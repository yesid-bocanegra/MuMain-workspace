# Story 6.3.5: Zen Render Geometry Budget

**Status:** review
**Story Points:** 1
**Priority:** Critical
**Repository:** `MuMain`

## Discovery Context

Source: `_bmad-output/findings/finding-2026-07-17-combat-action-backlog.md`

## Acceptance Criteria

- [x] One Zen pile renders at most 12 cosmetic coins.
- [x] Zen amount, ground-item identity, pickup, and server protocol remain unchanged.
- [x] Focused source regression check and Release build pass.
- [x] Dense-combat frame rate improves materially under Zen pile load.

## Tasks

- [x] Add failing Zen geometry budget check.
- [x] Cap `RenderZen()` cosmetic coin count.
- [x] Build Release client.
- [x] Verify dense-combat behavior.

## Dev Notes

- Cosmetic-only ceiling; do not alter `ITEM.Level`, drop creation, or pickup behavior.
- Upgrade path: distance/load-adaptive LOD only if fixed cap remains insufficient.

## Deferred Follow-up

- General non-Zen ground-item spam still scales linearly with visible item count.
- Defer shared visible-drop budget or distance LOD until runtime evidence shows it is required.
- Any future budget must preserve item storage, selection, pickup, network state, ownership, and lifetime.

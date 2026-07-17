# Story 7.3.4: OpenMU Monster AI Tick Reentrancy

**Status:** ready-for-dev
**Story Points:** 2
**Priority:** Critical
**Repository:** `/Users/joseybv/workspace/mu/OpenMU`

## Discovery Context

Source: `_bmad-output/findings/finding-2026-07-17-openmu-monster-ai-tick-reentrancy.md`

## Acceptance Criteria

- [ ] A monster can have at most one `TickAsync()` execution in flight.
- [ ] Overlapping periodic callbacks do not start additional attacks.
- [ ] Guard releases after success, cancellation, or exception.
- [ ] Existing attack delay, alive checks, targeting, damage, and observer behavior remain unchanged.
- [ ] Focused concurrency test and relevant OpenMU build/tests pass.

## Tasks

- [ ] Add single-flight guard to `BasicMonsterIntelligence.SafeTick()`.
- [ ] Add deterministic blocked-tick regression test.
- [ ] Run relevant NPC and game-logic tests.
- [ ] Build local OpenMU test image.

## Dev Notes

- Prefer minimal `Interlocked` guard for PR scope.
- Do not change packet protocol in this story.
- Do not parallelize observer sends in this story.
- A future async-loop refactor may replace the periodic timer after behavior is proven.

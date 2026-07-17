# OpenMU monster AI timer permits overlapping asynchronous attack ticks

**Date:** 2026-07-17
**Discovered during:** Dense-combat client backlog investigation
**Context:** More than 100 attacking monsters, one or more observing players, and increasing action latency over several minutes
**Discovery type:** bug
**Urgency:** this-sprint
**Urgency justification:** Overlapping monster ticks can multiply authoritative hits and observer packet fan-out under load.

## Summary

`BasicMonsterIntelligence` uses a periodic `System.Threading.Timer` whose callback invokes an `async void` method. The timer does not await `TickAsync()`, so another callback may start for the same monster while the previous attack and observer sends are still in flight. More observers increase tick duration and therefore increase overlap risk, producing a positive feedback loop of additional attacks and packets.

## Root Cause

### RCA-1: Periodic timer callback has no single-flight guard

**What:** `Start()` schedules `SafeTick()` at `MonsterDefinition.AttackDelay`; `SafeTick()` is `async void` and has no reentrancy protection.

**Evidence:** `/Users/joseybv/workspace/mu/OpenMU/src/GameLogic/NPC/BasicMonsterIntelligence.cs` creates a periodic `Timer`, and `SafeTick()` awaits `TickAsync()`. `/Users/joseybv/workspace/mu/OpenMU/src/GameLogic/NPC/Monster.cs` awaits authoritative damage, then sequential observer animation and optional skill-animation fan-out.

**Affected scope:** Monster attack rate, authoritative damage, observer packet volume, server load, and client combat packet latency.

**Proposed fix:** Enforce one in-flight AI tick per monster. Minimal PR uses an `Interlocked` single-flight guard with release in `finally`; skipped overlapping callbacks are expected because the prior tick still represents current work. Add a focused concurrency test proving a blocked tick cannot start a second attack.

**Estimated lines:** 15–30 production lines plus one focused test.

## Server Packet Contract Findings

- Monster life is authoritative and checked at tick start.
- Damage is applied before attack animation fan-out.
- Basic monster attack animation is `ObjectAnimation` packet `0x18` with animation value `120`.
- Monster attack skills use separate skill-animation packets.
- `ObjectAnimation` contains no sequence, server tick, timestamp, or delivery policy.
- Fan-out is limited to area-of-interest observers, but each observer is awaited sequentially.

## Implementation Plan

1. Add one in-flight tick guard to `BasicMonsterIntelligence.SafeTick()`.
2. Release guard in `finally` for success, cancellation, and failure paths.
3. Add test with blocked first tick and repeated timer callback.
4. Assert exactly one attack starts before first tick completes.
5. Run OpenMU NPC/game-logic tests and build test image.

## Post-Fix Verification

1. Run dense encounter with more than 100 attacking monsters.
2. Confirm no monster exceeds configured `AttackDelay` rate because of overlapping ticks.
3. Confirm damage, death, quest kill credit, and observer animations remain correct.
4. Compare client packet depth and oldest age before and after server fix.
5. Repeat with multiple nearby players to validate observer fan-out remains bounded.

## Scope Assessment

**Type:** bug
**Story count:** 1
**Repository:** `/Users/joseybv/workspace/mu/OpenMU`
**Estimated points:** 2

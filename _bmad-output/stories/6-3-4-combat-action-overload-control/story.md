# Story 6.3.4: Combat Action Overload Control

**Status:** ready-for-review
**Story Points:** 5
**Priority:** Critical

## Discovery Context

Source: `_bmad-output/findings/finding-2026-07-17-combat-action-backlog.md`

## Acceptance Criteria

- [x] Superseded queued action packets coalesce per entity.
- [x] Damage, map, session, inventory, and lifecycle packets are never coalesced or dropped.
- [x] Optional damage-point presentation is suppressed only while packet age is overloaded.
- [x] Regression check and full build pass.

## Dev Agent Record

- Coalescing runs after frame-batch capture and only recognizes `0x18` entity action packets.
- Latest action per entity keeps its arrival position; all non-action packets retain strict arrival order.
- Overload policy is computed once per frame batch at 250 ms oldest-packet age; damage state still processes normally.
- Verified `tests/stability/test_combat_packet_backlog.sh` and `cmake --build --preset macos-arm64-debug -j2` on 2026-07-17.

## File List

- MODIFIED: `MuMain/src/source/Network/IncomingPacketQueue.cpp`
- MODIFIED: `MuMain/src/source/Network/Server/WSclient.h`
- MODIFIED: `MuMain/src/source/Network/Server/WSclient.cpp`
- NEW: `MuMain/tests/stability/test_combat_packet_backlog.sh`

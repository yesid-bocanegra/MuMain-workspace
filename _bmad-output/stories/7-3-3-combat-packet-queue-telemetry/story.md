# Story 7.3.3: Combat Packet Queue Telemetry

**Status:** ready-for-review
**Story Points:** 5
**Priority:** Critical

## Discovery Context

Source: `_bmad-output/findings/finding-2026-07-17-combat-action-backlog.md`

## Acceptance Criteria

- [x] Queue exposes depth, high-water mark, oldest age, drained count, and drain duration.
- [x] Metrics require no per-packet logging or allocation.
- [x] Diagnostics can sample metrics without consuming packets.
- [x] Regression check and full build pass.

## Dev Agent Record

- Queue capture uses one mutex-protected `std::deque` swap per frame.
- `GetStats()` returns a read-only snapshot; combat handlers never query it.
- Verified `tests/stability/test_combat_packet_backlog.sh` and `cmake --build --preset macos-arm64-debug -j2` on 2026-07-17.

## File List

- MODIFIED: `MuMain/src/source/Network/IncomingPacketQueue.h`
- MODIFIED: `MuMain/src/source/Network/IncomingPacketQueue.cpp`
- NEW: `MuMain/tests/stability/test_combat_packet_backlog.sh`

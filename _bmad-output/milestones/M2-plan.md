# Milestone M2 — Cross-Platform I/O
# Planning Brief — 2026-03-02

## Scope Summary

**Contributing Epics:** EPIC-2 (SDL3 Windowing & Input Migration), EPIC-3 (.NET AOT Cross-Platform Networking)
**Total Story Points:** 41 (17 from EPIC-2 + 24 from EPIC-3)
**Total Stories:** 12 (5 from EPIC-2 + 7 from EPIC-3)
**Target Sprint:** TBD (insufficient velocity data)
**Planned At:** 2026-03-02
**Depends On:** M1 (Platform Foundation)

## Contributing Epic Status

| Epic | Title | Stories Done | Validation |
|------|-------|-------------|------------|
| EPIC-2 | SDL3 Windowing & Input Migration | 0/5 | NOT_VALIDATED |
| EPIC-3 | .NET AOT Cross-Platform Networking | 0/7 | NOT_VALIDATED |

## Epic Sequence

### Phase 1 (parallel after M1 — shared dependency on EPIC-1):

**EPIC-2 — SDL3 Windowing & Input Migration**
- Remaining: 5 stories / 17 pts
- Critical path: 2.1 → 2.3 → 2.5 (11 pts)
- Prerequisite: EPIC-1 complete (specifically 1.5 SDL3 integrated)
- Parallel tracks:
  - Track A: 2.1 (Window + Event Loop, 5pts) → 2.3 (Keyboard, 3pts) → 2.5 (Text Input, 3pts)
  - Track B: 2.1 → 2.2 (Focus/Display, 3pts)
  - Track C: 2.1 → 2.4 (Mouse, 3pts)

**EPIC-3 — .NET AOT Cross-Platform Networking**
- Remaining: 7 stories / 24 pts
- Critical path: 3.1 → 3.2 → 3.3 → 3.4 (16 pts)
- Prerequisite: EPIC-1.4 (PlatformLibrary backends)
- Note: Can start after EPIC-1.4, parallel with EPIC-2
- Parallel tracks:
  - Track D: 3.1 (CMake RID, 5pts) → 3.2 (Connection.h, 3pts) → 3.3 (char16_t, 5pts) → 3.4 (macOS, 3pts)
  - Track E: 3.3 → 3.5 (Linux, 3pts) — parallel with 3.4
  - Track F: 3.2 → 3.6 (Error Messaging, 3pts)
  - Track G: 3.4/3.5 → 3.7 (Server Config, 2pts)

### Milestone target: TBD (run sprint-complete for velocity data)

## E2E User Journeys

**TODO — non-blocking stubs for milestone-validation:**

1. **M2-J1: Window Launch on macOS** — Player launches MuMain on macOS → SDL3 window opens → correct resolution detected → fullscreen toggle works → Alt-Tab pauses/resumes correctly
2. **M2-J2: Full Input on macOS** — Player uses keyboard (WASD movement, hotkeys, Cmd-key mapping) → mouse (click-to-move, drag inventory, scroll) → text input (chat message with special characters)
3. **M2-J3: Server Connection on macOS** — Player launches → .NET AOT dylib loads → connects to OpenMU → handshake succeeds → character list displays → char16_t encoding correct
4. **M2-J4: Server Connection on Linux** — Same journey on Linux with .so library → all packet encoding verified against Windows baseline
5. **M2-J5: Graceful Degradation** — Player launches without .NET library → clear error message displayed → game continues to window/input (rendering testable without network)

## Success Criteria

| # | Criterion | Source |
|---|-----------|--------|
| 1 | Game window opens on macOS, Linux, Windows via SDL3 | EPIC-2 Validation |
| 2 | Keyboard, mouse, text input work on all platforms | EPIC-2 Validation |
| 3 | No Win32 windowing or input APIs in game logic | EPIC-2 Validation |
| 4 | .NET AOT library builds and loads on all platforms | EPIC-3 Validation |
| 5 | Server connectivity works on all three platforms | EPIC-3 Validation |
| 6 | char16_t encoding produces correct packets | EPIC-3 Validation |
| 7 | Error messages help diagnose connection failures | EPIC-3 Validation |
| 8 | Game can launch without .NET library (graceful degradation) | EPIC-3 Validation |

## Risks

- **R1: .NET AOT on macOS (untested)** — Native AOT compilation targeting macOS arm64 is the highest-risk item in this milestone. Mitigation: isolated, well-scoped — CMake RID detection + library extension + char16_t fix. Validate early (story 3.4).
- **R2: wchar_t → char16_t encoding** — String encoding at the C++/.NET boundary is critical. wchar_t is 4 bytes on macOS/Linux but protocol expects 2. Mitigation: Catch2 round-trip tests with Korean + Latin strings, byte-level comparison to Windows baseline.
- **R3: SDL3 event loop replacing Win32 message pump** — The game loop transition from `GetMessage`/`DispatchMessage` to SDL3 events touches the core loop. Mitigation: story 2.1 is the gating story; validate on all platforms before proceeding.
- **R4: macOS Cmd key mapping** — macOS uses Cmd where Windows uses Ctrl. Game controls need correct mapping. Mitigation: explicit key mapping table in story 2.3.
- **R5: Parallel epic execution** — EPIC-2 and EPIC-3 can run in parallel but share the EPIC-1 foundation. If EPIC-1 delays, both are blocked.

## Next Steps

1. Complete M1 (Platform Foundation) — prerequisite for all M2 work
2. Run `sprint-planning` to assign M2 stories across sprints
3. Start EPIC-2 (windowing) and EPIC-3 (networking) in parallel
4. Validate .NET AOT on macOS early (story 3.4) to derisk
5. When both epics complete, run `epic-validation` for EPIC-2 and EPIC-3
6. Run `milestone-validation` to verify all 8 success criteria
7. After `milestone-validation`, run `milestone-review` for go/no-go on M3

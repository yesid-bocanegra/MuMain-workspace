# Milestone M1 — Platform Foundation
# Planning Brief — 2026-03-02

## Scope Summary

**Contributing Epics:** EPIC-1 (Platform Foundation & Build System), EPIC-7 (Stability, Diagnostics & Quality Gates — stories 7.1-7.3 only)
**Total Story Points:** 27 (18 from EPIC-1 + 9 from EPIC-7 partial)
**Total Stories:** 9 (6 from EPIC-1 + 3 from EPIC-7)
**Target Sprint:** TBD (insufficient velocity data)
**Planned At:** 2026-03-02

## Contributing Epic Status

| Epic | Title | Stories Done | Validation |
|------|-------|-------------|------------|
| EPIC-1 | Platform Foundation & Build System | 0/6 | NOT_VALIDATED |
| EPIC-7 | Stability, Diagnostics & Quality Gates (7.1-7.3) | 0/3 | NOT_VALIDATED |

## Epic Sequence

### Phase 1 (parallel — no inter-dependencies):

**EPIC-1 — Platform Foundation & Build System**
- Remaining: 6 stories / 18 pts
- Critical path: 1.1 → 1.5 → 1.6 (8 pts)
- Parallel tracks:
  - Track A: 1.1 (macOS CMake, 3pts) + 1.2 (Linux CMake, 2pts) → 1.5 (SDL3, 3pts) → 1.6 (Build Docs, 2pts)
  - Track B: 1.3 (Platform Headers, 3pts) → 1.4 (PlatformLibrary Backends, 5pts)

**EPIC-7 partial — Early Diagnostics**
- Remaining: 3 stories / 9 pts
- Critical path: 7.1 → 7.2 (6 pts)
- Parallel tracks:
  - Track C: 7.1 (Error Reporting, 3pts) → 7.2 (Signal Handlers, 3pts)
  - Track D: 7.3 (Frame Timer, 3pts) — independent

### Milestone target: TBD (run sprint-complete for velocity data)

## E2E User Journeys

**TODO — non-blocking stubs for milestone-validation:**

1. **M1-J1: Build from Source on macOS** — Developer clones repo → runs `cmake --preset macos-arm64` → configure succeeds → MUPlatform and MURenderFX link SDL3 → build docs cover macOS prerequisites
2. **M1-J2: Build from Source on Linux** — Developer clones repo → runs `cmake --preset linux-x64` → configure succeeds → build docs cover Linux prerequisites
3. **M1-J3: Platform Library Loading** — Developer builds MUPlatform → `PlatformLibrary::Load()` successfully loads a test library on macOS (dlopen) and Linux (dlopen) → error logging on failure
4. **M1-J4: Diagnostics Operational** — Developer triggers an error → `MuError.log` produced on macOS/Linux → signal handler catches SIGSEGV → frame timer reports FPS

## Success Criteria

| # | Criterion | Source |
|---|-----------|--------|
| 1 | CMake configures on macOS, Linux, Windows | EPIC-1 Validation |
| 2 | MUPlatform library compiles with correct backends | EPIC-1 Validation |
| 3 | PlatformLibrary can load a dynamic library on each platform | EPIC-1 Validation |
| 4 | SDL3 available as linked dependency | EPIC-1 Validation |
| 5 | MinGW CI remains green | EPIC-1 Validation |
| 6 | Build documentation covers all three platforms | EPIC-1 Validation |
| 7 | MuError.log works on all platforms | EPIC-7 (7.1) |
| 8 | POSIX signal handlers produce crash diagnostics | EPIC-7 (7.2) |
| 9 | Frame time instrumentation operational | EPIC-7 (7.3) |

## Risks

- **R1: SDL3 FetchContent build time** — SDL3 building from source may significantly increase configure/build times on all platforms. Mitigation: consider pre-built SDL3 packages as fallback.
- **R2: MinGW + SDL3 cross-compile** — SDL3 may not cross-compile cleanly with MinGW. Mitigation: AC-5 of story 1.5 allows excluding SDL3 from CI initially.
- **R3: PlatformLibrary dlopen differences** — Library loading paths differ subtly between macOS and Linux (dylib search paths, RPATH). Mitigation: explicit path construction in CMake, no reliance on system search.
- **R4: EPIC-7 stories depend on EPIC-1.3** — Signal handlers and error reporting need platform headers. Track B (1.3 → 1.4) and Track C (7.1 → 7.2) have a dependency on 1.3 completing first.

## Next Steps

1. Run `sprint-planning` to assign M1 stories to Sprint 1
2. Start with parallel tracks: 1.1/1.2 (CMake toolchains) + 1.3 (platform headers) + 7.3 (frame timer)
3. When all M1 stories complete, run `epic-validation` for EPIC-1
4. Run `milestone-validation` to verify all 9 success criteria
5. After `milestone-validation`, run `milestone-review` for go/no-go on M2

# Milestone M5 — MVP Complete
# Planning Brief — 2026-03-02

## Scope Summary

**Contributing Epics:** EPIC-6 (Cross-Platform Gameplay Validation), EPIC-7 (Stability, Diagnostics & Quality Gates — stories 7.4-7.6)
**Total Story Points:** 38 (23 from EPIC-6 + 15 from EPIC-7 partial)
**Total Stories:** 10 (7 from EPIC-6 + 3 from EPIC-7)
**Target Sprint:** TBD (insufficient velocity data)
**Planned At:** 2026-03-02
**Depends On:** M1, M2, M3, M4 (all migration milestones must be complete)

**This is the final milestone.** When M5 passes, the MVP is delivered: Paco plays MU Online on his Mac.

## Contributing Epic Status

| Epic | Title | Stories Done | Validation |
|------|-------|-------------|------------|
| EPIC-6 | Cross-Platform Gameplay Validation | 0/7 | NOT_VALIDATED |
| EPIC-7 | Stability, Diagnostics & Quality Gates (7.4-7.6) | 0/3 | NOT_VALIDATED |

## Epic Sequence

### Phase 1: Gameplay Validation (EPIC-6)

**Core Loop (sequential):**
- 6.1 (Auth & Character Management, 3pts) — login, character creation/selection
- 6.2 (World Navigation, 3pts) — movement across 82 maps
- 6.3 (Combat System, 3pts) — melee, ranged, skills, effects
- 6.6 (Advanced Systems, 3pts) — quests, pets, PvP

**Parallel with Core Loop (after 6.1):**
- 6.4 (Inventory, Trading & Shops, 3pts)
- 6.5 (Social Systems, 3pts) — guilds, parties, chat
- 6.7 (UI Windows Validation, 5pts) — all 84 CNewUI* windows

**Critical Path:** 6.1 → 6.2 → 6.3 → 6.6 (12 pts)

### Phase 2: Stability & CI (EPIC-7 partial, after EPIC-6)

**Parallel:**
- 7.4 (macOS 60-Minute Stability, 5pts) — the ultimate acceptance test
- 7.5 (Linux 60-Minute Stability, 5pts)
- 7.6 (Native CI Runners, 5pts) — can start after EPIC-4 (may overlap with EPIC-6)

### Milestone target: TBD (run sprint-complete for velocity data)

## E2E User Journeys

These are the **definitive MVP acceptance journeys** — derived directly from the PRD:

1. **M5-J1: "Paco Plays on Mac" (PRIMARY — MVP acceptance criterion)**
   - Paco launches MuMain on macOS → connects to OpenMU → selects Dark Knight → enters Lorencia → walks to town square → kills monsters → opens inventory → equips sword → checks map → uses chat → trades with player → joins guild → plays for 60 minutes → logs out voluntarily
   - **Audio:** BGM playing, combat SFX heard
   - **Performance:** 30+ FPS sustained, no >50ms hitches
   - **Stability:** No crashes, no disconnects, no ERROR-level log entries
   - **Memory:** Usage stable over 60 minutes

2. **M5-J2: Linux Gameplay Session**
   - Same journey as M5-J1 on Linux → all systems functional → 60 minutes stable

3. **M5-J3: Windows Regression**
   - Same journey on Windows → no regressions from migration → existing functionality preserved

4. **M5-J4: UI Completeness**
   - Player opens all 84 UI windows on macOS → each renders correctly → interactive elements respond → close/toggle works → ground truth SSIM comparison passes for key windows

5. **M5-J5: Cross-Platform CI**
   - Developer pushes code → GitHub Actions runs macOS + Linux + MinGW builds → all three pass → Catch2 tests execute → quality gates enforce formatting and static analysis

## Success Criteria

| # | Criterion | Source |
|---|-----------|--------|
| 1 | All core gameplay systems work on macOS and Linux | EPIC-6 Validation / FR23-FR36 |
| 2 | No gameplay regression on Windows | EPIC-6 Validation |
| 3 | All 84 UI windows function correctly | EPIC-6 (6.7) / FR35 |
| 4 | 60+ minute stability sessions pass on macOS and Linux | EPIC-7 (7.4, 7.5) / FR37-FR38 |
| 5 | Memory usage stable (no leaks over 60 minutes) | EPIC-7 (7.4, 7.5) |
| 6 | Native CI runners validate every push on all platforms | EPIC-7 (7.6) / NFR15 |
| 7 | **Paco plays MU Online on Mac for 60 minutes and logs out voluntarily** | PRD Success Criteria |

## Risks

- **R1: Undiscovered legacy bugs** — The current codebase may contain bugs unrelated to cross-platform migration that surface during gameplay validation. Mitigation: PRD specifies only showstoppers (crashes, data loss, broken core loops) block MVP. Non-critical bugs go to Phase 2 backlog.
- **R2: Gameplay systems depending on Win32 subtleties** — Some gameplay systems may have hidden Win32 dependencies not caught during migration. Mitigation: EPIC-6 validates each system category independently, isolating failures.
- **R3: 60-minute stability bar** — Memory leaks, gradual performance degradation, or intermittent crashes may only surface in extended sessions. Mitigation: stories 7.4/7.5 include memory usage monitoring and frame time logging.
- **R4: 84 UI windows validation scope** — Testing all 84 windows is labor-intensive. Some windows may require specific game state to open. Mitigation: story 6.7 uses automated CNewUI* sweep where possible, manual for state-dependent windows.
- **R5: OpenMU server compatibility** — Protocol mismatches between client and server versions could cause gameplay issues. Mitigation: document compatible OpenMU version, test handshake early.
- **R6: Native CI runner costs** — macOS GitHub Actions runners are more expensive. Mitigation: story 7.6 is P1 (should have), can defer to post-MVP if budget constrained.

## Next Steps

1. Complete M1, M2, M3, and M4 — all are prerequisites
2. Run `sprint-planning` to assign M5 stories
3. Start EPIC-6 gameplay validation (core loop first, then parallel tracks)
4. Start EPIC-7.6 (Native CI) as soon as EPIC-4 rendering compiles on all platforms
5. Execute 60-minute stability sessions (7.4, 7.5) as final validation
6. Run `epic-validation` for EPIC-6 and EPIC-7
7. Run `milestone-validation` to verify all 7 success criteria
8. Run `milestone-review` for final go/no-go: **MVP shipped**

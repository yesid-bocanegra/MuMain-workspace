# Milestone M4 — Audio Migration
# Planning Brief — 2026-03-02

## Scope Summary

**Contributing Epics:** EPIC-5 (Audio System Migration)
**Total Story Points:** 18
**Total Stories:** 5
**Target Sprint:** TBD (insufficient velocity data)
**Planned At:** 2026-03-02
**Depends On:** M1 (platform foundation for miniaudio integration)
**Note:** EPIC-5 can technically start after M1 (parallel with M2/M3), but gameplay validation in M5 requires all migration milestones complete.

## Contributing Epic Status

| Epic | Title | Stories Done | Validation |
|------|-------|-------------|------------|
| EPIC-5 | Audio System Migration | 0/5 | NOT_VALIDATED |

## Epic Sequence

### Single Epic — Straightforward Dependency Chain:

**Phase 1: Abstraction**
- 5.1 (MuAudio Abstraction Layer, 3pts) — IMuAudio interface with dependency inversion

**Phase 2: Implementation (parallel after 5.1)**
- Track A: 5.2 (BGM via miniaudio, 5pts) — background music streaming
- Track B: 5.3 (SFX via miniaudio, 5pts) — sound effects playback

**Phase 3: Validation (after 5.2 + 5.3)**
- 5.4 (Audio Format Validation, 3pts) — WAV/OGG/MP3 format verification
- 5.5 (Volume Controls, 2pts) — real-time volume adjustment and persistence

**Critical Path:** 5.1 → 5.2 → 5.4 (11 pts)

### Milestone target: TBD (run sprint-complete for velocity data)

## E2E User Journeys

**TODO — non-blocking stubs for milestone-validation:**

1. **M4-J1: BGM on macOS** — Player enters Lorencia on macOS → background music plays → transitions to Devias → music changes smoothly (no pop/click) → music loops correctly
2. **M4-J2: SFX on All Platforms** — Player attacks monster → combat SFX plays → multiple concurrent sounds in group combat → UI click sounds → environmental audio → all on macOS, Linux, Windows
3. **M4-J3: Format Coverage** — WAV files (majority SFX) play correctly → OGG Vorbis (BGM tracks) play correctly → MP3 files (if present) play correctly → PCM hash matches DirectSound baseline
4. **M4-J4: Volume Control** — Player adjusts BGM volume → change takes effect in real-time → adjusts SFX volume → saves settings → restarts game → volume persists

## Success Criteria

| # | Criterion | Source |
|---|-----------|--------|
| 1 | BGM and SFX play on all three platforms via miniaudio | EPIC-5 Validation / FR17-FR18 |
| 2 | All audio formats (WAV, OGG, MP3) decode correctly | EPIC-5 Validation / FR19 |
| 3 | DirectSound and wzAudio dependencies removed | EPIC-5 Validation |
| 4 | No audio latency or quality degradation vs baseline | EPIC-5 Validation |
| 5 | Volume controls functional | EPIC-5 Validation |

## Risks

- **R1: miniaudio format support gaps** — While miniaudio is mature, edge cases in specific WAV/OGG/MP3 files may surface. Mitigation: story 5.4 validates format support with PCM hash comparison against DirectSound baseline.
- **R2: Audio latency** — miniaudio may introduce higher latency than DirectSound on some platforms. Mitigation: NFR requires no more than 10ms latency from trigger to playback; story 5.3 AC-6 enforces this.
- **R3: Concurrent SFX performance** — MU Online combat can trigger many simultaneous sound effects. Mitigation: miniaudio's `ma_engine` handles mixing; validate with group combat scenarios.
- **R4: wzAudio removal scope** — wzAudio is deeply integrated into the audio pipeline. Complete removal may surface unexpected dependencies. Mitigation: story 5.2 and 5.3 explicitly list dependency removal as AC.

## Next Steps

1. EPIC-5 can start after M1 completes (EPIC-1 platform foundation)
2. Consider starting EPIC-5 in parallel with M2/M3 to reduce total timeline
3. Run `sprint-planning` to assign EPIC-5 stories
4. Start with 5.1 (abstraction), then parallel 5.2 (BGM) + 5.3 (SFX)
5. Run `epic-validation` for EPIC-5
6. Run `milestone-validation` to verify all 5 success criteria
7. After `milestone-validation`, run `milestone-review` for go/no-go on M5

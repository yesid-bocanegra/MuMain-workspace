# Sprint 5 Retrospective — 2026-03-20

**Sprint:** Sprint 5 (sprint-5)
**Velocity:** 20 pts delivered (23 planned — 5-3-1 in backlog, just unblocked 2026-03-20) | **Commitment:** 87% partial (100% expected when 5-3-1 completes) | **Flow Time:** ~1.1 days avg est. | **Flow Efficiency:** ~12% (wall-clock, multi-session)
**Sprint Window:** 2026-03-16 → 2026-03-30 | **Active as of:** 2026-03-20 (Day 4 of 14)
**Milestone:** M4 (Audio System Migration), M1 (cross-platform CI)

> **Administrative Note:** This retrospective was generated while Sprint 5 is still `active` (5/6 stories done, 5-3-1 in backlog — prerequisites satisfied 2026-03-20). The sprint completion report (`sprint-5-completion.md`) does not exist — `sprint-complete` should be run first. This retrospective documents the current state and is intended to be finalized once 5-3-1 completes and sprint-complete runs. Per Sprint 4 retrospective Action #2 (PROCESS), the sprint-complete workflow should save the completion report before updating sprint status.

---

## Went Well

### EPIC-5 Audio Migration Core Delivered — 4 of 5 Stories, 15 of 18 Points

- **Evidence:** Stories 5-1-1 (MuAudio abstraction layer, 3 pts), 5-2-1 (miniaudio BGM, 5 pts), 5-2-2 (miniaudio SFX, 5 pts), 5-4-1 (volume controls, 2 pts) all completed and code-review-finalized by 2026-03-20. Total: 4 stories, 15 pts of EPIC-5's 18 pts. DirectSound/wzAudio is completely removed from the game loop; all BGM/SFX paths delegate to `g_platformAudio` (miniaudio backend). Only 5-3-1 (audio format validation, 3 pts) remains — now unblocked.
- **Impact:** The audio migration is functionally complete. The game runs on cross-platform audio (miniaudio) with volume persistence, polyphonic SFX, BGM streaming, and 3D positional audio. EPIC-5's DoD is achievable within the sprint window.

### Native CI Runners Delivered — Sprint 5 Enables True Cross-Platform Validation

- **Evidence:** Story 7-4-1-native-ci-runners (5 pts) completed 2026-03-20. GitHub Actions now runs macOS (arm64) and Linux (x64) native jobs in parallel with the existing MinGW Windows job. SDL3 FetchContent caching configured, `BUILD_TESTING=ON` set in base presets, `--no-tests=error` prevents silent test skipping. `MU_ENABLE_DOTNET=OFF` explicitly set in native presets.
- **Impact:** For the first time in the project, CI validates the full cross-platform matrix (Windows MinGW + macOS Metal + Linux Vulkan) on every push. This satisfies M1 (cross-platform CI) and unlocks 7-3-1/7-3-2 (stability sessions) as CI evidence sources.

### CRITICAL Defect Found and Fixed in Code Review — Round-Robin Uninitialized `ma_sound` Slots

- **Evidence:** Story 5-2-2 code review found CRITICAL-1: `PlaySound()` round-robin channel cycling accessed uninitialized `ma_sound` handles when sounds were loaded with `channels < MAX_CHANNEL` (e.g., single-channel sounds — the majority of game SFX). Fix: `m_loadedChannels[]` array tracking per-buffer channel count, used as loop bound for all channel operations. Carried into 5-4-1 where two pre-existing `MAX_CHANNEL` loop defects were additionally fixed in `Set3DSoundPosition()` and `SetVolume()`.
- **Impact:** Without the adversarial review, this would have caused undefined behavior (calling miniaudio API on uninitialized handles) on all platforms for almost every SFX in the game. The defect would have been intermittent and very hard to diagnose. The review pipeline caught it before any platform integration testing.

### Zero Health Audit CRITICAL/HIGH Gaps at Sprint Day 4

- **Evidence:** sprint-health-audit-2026-03-20.md — 0 CRITICAL, 0 HIGH, 0 MEDIUM gaps. One LOW gap (5-3-1 STRUCT_MISS — backlog story, no artifacts yet; expected). All 5 completed stories have full artifact coverage (story, ATDD, session-summary, progress, review files present). No `.paw/*.feedback.md` files at audit time (the earlier 5-2-2 FEEDBACK gap was self-healed within the same session).
- **Impact:** HEALTHY sprint health at Day 4 of 14, consistent with the sustained HEALTHY record across Sprints 1–3 and Sprint 4's clean story completion record.

### Multi-Pass Code Review Pattern Working — 5-2-2 FEEDBACK Resolved Same-Session

- **Evidence:** 5-2-2 briefly showed a CRITICAL FEEDBACK gap (exit code -15 from an earlier session) that was visible in the first 2026-03-20 health audit. By the time of the updated audit (same day), the story was completed (feedback.md and state.json deleted). Unlike Sprint 4's 4-2-5 stranding, the 5-2-2 recovery was same-session.
- **Impact:** Sprint 4 Action #1 (SIGTERM root cause investigation) appears to have had some effect — the SIGTERM pattern did not produce a stranded story in Sprint 5. The shorter audio stories (5 pts max vs 8 pts in Sprint 4) also contributed to fewer timeout-risk scenarios.

---

## Didn't Go Well

### Sprint-Complete Not Run Before Retrospective — Sprint 4 Action #2 Recurrence

- **Evidence:** Sprint-5 is `active` in sprint-status.yaml (not `complete`). The `sprint-5-completion.md` document does not exist. This retrospective was generated without a completion report — the same administrative gap that occurred in Sprint 4 (Action #2). 5-3-1 is still in `backlog` (prerequisites satisfied 2026-03-20), which means the sprint is not technically complete yet, but the retrospective is being run early.
- **Impact:** The sprint audit trail is incomplete. Velocity, flow metrics, and commitment reliability are not formally recorded. Future sprint planning must reconstruct these metrics from sprint-status.yaml rather than reading from a completion report.
- **Action:** Sprint 4 Action #2 asked for a verification step in sprint-complete to confirm output file saved before updating status. This action was not yet formalized into the workflow. The root cause is process order — the retrospective workflow was invoked before sprint-complete. Add a PROCESS gate: retrospective workflow should check for `sprint-5-completion.md` existence and HALT if missing, providing a clear error message. Additionally, finalize 5-3-1, run sprint-complete to generate the completion report, then update this retrospective.
  - **Classification:** PROCESS
  - **Owner:** Dev agent / sprint workflow
  - **Timeline:** Immediately — before marking Sprint 5 retrospective-done
  - **Success Criteria:** `sprint-5-completion.md` exists at `_bmad-output/sprint-5-completion.md` and contains all SAFe flow metrics. Sprint 5 status updated to `complete` then `retrospective-done` in sequence.

### Audio API Design Accumulated Debt — `raw delete`, Wrong Header for `extern`, Asymmetric Naming

- **Evidence:** Three separate review findings across Sprint 5 that were pre-existing or cross-story design issues:
  - 5-2-2 LOW-1: `g_platformAudio` uses raw `new`/`delete` (Winmain.cpp:448-452) — project convention requires `std::unique_ptr`. Pre-existing from 5.2.1, noted again in 5.2.2, deferred.
  - 5-2-1 LOW-NEW-1: `extern g_platformAudio` in `IPlatformAudio.h` — wrong header; should be in `Winmain.h`. Added TODO comment deferring to future story.
  - 5-4-1 CRITICAL-1 / HIGH-1: `GetVolumeLevel()` vs `GetBGMVolumeLevel()` API asymmetry required adding `GetSFXVolumeLevel()` wrapper. The asymmetry was caught and fixed in review but should have been designed symmetrically at 5.2.1 story time.
- **Impact:** The audio subsystem has accumulated three inter-story design debts in a single sprint. Each was individually small, but together they represent a pattern: the audio API (IPlatformAudio, MiniAudioBackend, Winmain.cpp wiring) was designed incrementally story-by-story without a holistic interface review. Each successive story found and fixed an issue inherited from the previous one.
- **Action:** Before starting EPIC-5 remaining stories (or EPIC-6 which will interact with the audio system), conduct a brief interface consolidation: (1) migrate `g_platformAudio` to `std::unique_ptr<IPlatformAudio>`; (2) move `extern g_platformAudio` declaration to `Winmain.h`; (3) verify all `GetXVolume/SetXVolume` APIs are symmetric. Target as a technical debt story (0–1 pt) at the start of the next sprint or as part of 5-3-1 scope.
  - **Classification:** TECHNICAL
  - **Owner:** Dev agent
  - **Timeline:** 5-3-1 or first story of Sprint 6
  - **Success Criteria:** No raw `new`/`delete` for `g_platformAudio` in Winmain.cpp; `extern g_platformAudio` in Winmain.h only; all volume API methods symmetric (BGM/SFX pairs).

### Synchronous `PlayMusic()` Init Known HDD Performance Risk — Undocumented Until Review

- **Evidence:** 5-2-1 HIGH-NEW-1: `ma_sound_init_from_file()` with `MA_SOUND_FLAG_STREAM` performs synchronous disk I/O on the game loop thread. On HDD or network-share installations (historically common in MU Online server-hosted setups), this can stall 10–100ms at zone transitions. The comment was missing this caveat. Fixed in review with documentation.
- **Impact:** This is a known limitation of the BGM implementation that was not surfaced until adversarial code review. Dev-story did not produce a performance risk annotation. The game serves a player base with a mix of SSD and HDD hardware.
- **Action:** For audio stories that involve synchronous I/O on the game loop thread, add a performance-risk annotation to the story's ACs and ATDD: "If the operation involves disk I/O on the main thread, document the latency profile (best case SSD, worst case HDD/network) in the implementation code comment." This surfaces the risk before review rather than at review.
  - **Classification:** PROCESS
  - **Owner:** Dev agent (story creation + ATDD)
  - **Timeline:** Sprint 6, from first story with synchronous I/O
  - **Success Criteria:** Zero HIGH performance findings in code review that were not already documented in the story's risk section or implementation comments.

---

## Surprises

### Sprint 5 Delivering in 4 Calendar Days — Fifth Consecutive Ultra-Fast Sprint

- **Evidence:** Sprint window 2026-03-16 → 2026-03-30 (14 days). 5 of 6 stories done by 2026-03-20 (Day 4 of 14). SPI ≈ 5–6 range (20 pts delivered, PV ≈ 3.2–4 pts at day 4 of 14). Fifth consecutive sprint: Sprint 1 (SPI 6.5), Sprint 2 (SPI 14.0), Sprint 3 (SPI 7.0), Sprint 4 (SPI ~24.0), Sprint 5 (SPI ~5–6, still in progress). All 5 sprints have delivered the bulk of their work within the first 4 calendar days.
- **Lesson:** The batch pipeline pattern is structurally established. Sprint windows of 14 days are systematically mismatched to actual delivery cadence. For Sprint 6 planning, consider explicitly planning the sprint to complete within 4–5 days and use the remaining window for stakeholder review, 5-3-1 completion, and planning prep.

### Issue Density Increased to ~10/Story — Highest Yet Across All Sprints

- **Evidence:** Sprint 5 total issues fixed across 5 stories: ~50 (5-1-1: 13, 5-2-1: 15, 5-2-2: 9, 5-4-1: 7, 7-4-1: 6). Average: ~10 issues/story. Prior sprints: Sprint 1: 1.8/story, Sprint 2: 4.6/story, Sprint 3: 6.9/story, Sprint 4: 5.75/story. Sprint 5 represents the highest per-story issue density to date.
- **Lesson:** Audio API correctness (miniaudio threading model, race conditions, dangling pointers, uninitialized slot access) is at least as challenging as SDL_gpu rendering correctness from Sprint 4. The miniaudio API has implicit ordering requirements (configure before start), reference lifetime requirements (3D object pointer lifetime), and platform behavior differences (headless CI vs audio hardware) that all generate adversarial findings. EPIC-6 (gameplay) will likely show similar density for network and gameplay logic.

### Sprint 4 Action #1 (SIGTERM Diagnosis) — No SIGTERM-Stranded Story in Sprint 5

- **Evidence:** Sprint 4 had 4-2-5 stranded by SIGTERM kills at ~915s. Sprint 5 had a brief FEEDBACK gap on 5-2-2 that was self-healed same-session. No story was stranded at day 4 of Sprint 5. Sprint 5's audio stories are all 5 pts or fewer (vs Sprint 4's 8-pt stories), which likely reduced the per-session compute time below the ~915s threshold.
- **Lesson:** The SIGTERM pattern appears size-dependent. Smaller stories (≤5 pts) are not triggering the timeout. This is indirect evidence that the ~915s timeout is a hard wall-clock limit and smaller stories complete within it. Sprint 5's story sizing (max 5 pts) may have accidentally mitigated the SIGTERM risk. For Sprint 6 stories with 8+ pt estimates, the SIGTERM risk remains active.

---

## Cross-Sprint Trends

### Velocity Trend

| Sprint | Velocity | Delivered Points | Commitment | Delta |
|--------|----------|-----------------|------------|-------|
| Sprint 1 | 18 pts | 18 pts | 100% | — (baseline) |
| Sprint 2 | 28 pts | 28 pts | 100% | +10 pts (+55.6%) |
| Sprint 3 | 22 pts | 22 pts | 100% | −6 pts (−21.4%) |
| Sprint 4 | 48 pts | 48 pts | 100% | +26 pts (+118.2%) |
| Sprint 5 | ~20–23 pts (active) | 20 pts (87%) | partial | −28 pts (normalizing from EPIC-4 spike) |

**Rolling 4-sprint average (Sprints 1–4): 29 pts**
**Adjusted average (excluding EPIC-4 spike): 22–23 pts**
**Trend classification: STABLE (normalizing after EPIC-4 density spike)**

Sprint 4's 48-pt spike was driven by EPIC-4's 9 pre-planned stories running as a single coherent unit. Sprint 5 at 23 planned points returns to the 20–28 pt range seen in Sprints 1–3. The sustainable organic velocity, excluding EPIC-4's planned density, is approximately 22–23 pts per sprint.

### Flow Metrics Trend

| Metric | Sprint 1 | Sprint 2 | Sprint 3 | Sprint 4 | Sprint 5 | Trend |
|--------|----------|----------|----------|----------|----------|-------|
| Stories/Sprint | 6 | 8 | 7 | 9 | 5+1 (active) | 6–9 range, stable |
| Avg Flow Time | 12.71h | 2.29h | 1.36d | ~1.11d | ~1.1d est. | Multi-session cadence, stable |
| Flow Efficiency | 26.4% | 95.1% | ~10.7% (wall) | ~12% (wall) | ~12% (wall, est.) | Wall-clock stable at ~12% |
| Commitment Reliability | 100% | 100% | 100% | 100% | 87% partial (5/6) | Sustained; Sprint 5 partial only |
| WIP Violations | 0 | 0 | 0 | 0 | 0 | Sustained — 5-sprint clean |
| Health Audit | HEALTHY | HEALTHY | HEALTHY | AT RISK (4-2-5) | HEALTHY | HEALTHY restored |
| Code Review Issues/Story | 1.8 | 4.6 | 6.9 | 5.75 | ~10 | Increasing — audio API complexity spike |
| Stranded Stories | 0 | 0 | 0 | 1 (4-2-5) | 0 | Self-healed in Sprint 5 |

### Recurring Themes

| Theme | Sprint 3 | Sprint 4 | Sprint 5 | Classification |
|-------|----------|----------|----------|----------------|
| 100% commitment reliability | Went Well | Went Well | Partial (5/6) | **Sustained Pattern** — first partial in Sprint 5 (1 backlog story); expected to close |
| Pipeline delivers in first 2–4 calendar days | Surprise | Surprise | Surprise | **Persistent** — Fifth consecutive sprint; now a structural execution pattern |
| ATDD checklist false-GREEN | Didn't Go Well | RESOLVED | Not observed | **RESOLVED** — Zero ATDD false-GREEN findings in Sprint 5 code review |
| Adversarial review catches real correctness bugs | Went Well | Went Well | Went Well | **Sustained Pattern** — uninitialized slot CRITICAL, dangling pointer risk, async thread ordering |
| SIGTERM stranding batch runs | N/A | Didn't Go Well | RESOLVED (partial) | **PARTIALLY RESOLVED** — No stranded stories; SIGTERM timeout still exists but did not fire at ≤5pt story sizes |
| Sprint admin artifacts not saved | N/A | Didn't Go Well | Recurring | **PERSISTENT** — Sprint 5 retrospective run before sprint-complete; no completion report generated |
| Audio API design debt (cross-story) | N/A | N/A | Didn't Go Well | **NEW** — First EPIC where API design accumulated debt across sequential stories |
| Pre-existing bugs fixed during story reviews | N/A | Went Well | Went Well | **Sustained Pattern** — MEDIUM-3 `MAX_CHANNEL` loop in 5-4-1, `Set3DSoundPosition` loop bound corrected |

### Previous Action Item Follow-Through

Sprint 4 Retrospective had 6 action items (4 new + 2 carried). Status:

| # | Action | Sprint 4 Target | Sprint 5 Status |
|---|--------|-----------------|-----------------|
| 1 | Diagnose SIGTERM root cause at ~915s; add monitoring; increase timeout for 8+ pt stories | Sprint 5, before first batch | **PARTIALLY RESOLVED** — No stranded stories. Root cause not formally documented. Smaller story sizes (≤5 pts) likely avoided the timeout. No monitoring added. Carries forward for 8+ pt stories. |
| 2 | Add verification step to sprint-complete/retrospective: confirm output file exists before updating status; halt if missing | Sprint 5, before sprint-complete | **OPEN** — Retrospective was run before sprint-complete; `sprint-5-completion.md` not saved. Sprint 4 Action #2 action item was not formalized into the workflow. |
| 3 | SDL_gpu stories: ATDD checklist item "shader loaded → pipeline bound" | Sprint 5, first SDL_gpu story | **NOT APPLICABLE** — Sprint 5 had no SDL_gpu stories. Carry to Sprint 6 if SDL_gpu rendering stories occur. |
| 4 | Stories adding SDL_gpu pointers to packed structs: alignment check | Sprint 5, first such story | **NOT APPLICABLE** — Sprint 5 had no packed struct + SDL pointer stories. Carry to EPIC-6 if such patterns appear. |
| 5 | (Carried) Wide-string encoding: non-ASCII must use `\uXXXX` | First wide-string story | **NOT TESTED** — Sprint 5 had no wide-string non-ASCII stories. Carry forward. |
| 6 | (Carried) SDL3 input parity checklist | Next SDL3 input story | **NOT APPLICABLE** — No SDL3 input stories in Sprint 5. Carry forward. |

---

## Action Items Summary

| # | Action | Classification | Owner | Timeline | Status |
|---|--------|----------------|-------|----------|--------|
| 1 | Finalize 5-3-1 (audio format validation), run sprint-complete to generate `sprint-5-completion.md`, then re-run sprint-retrospective finalization to update status to `retrospective-done` | PROCESS | Dev agent / sprint workflow | Immediately — before next sprint planning | NEW |
| 2 | Sprint workflow gate: retrospective must check for completion report existence (HALT if missing), AND sprint-complete must verify output file saved before updating status — formally document this as a workflow requirement | PROCESS | Dev agent / sprint workflow | Sprint 6, before sprint-complete | NEW (Sprint 4 Action #2 escalated) |
| 3 | Audio API consolidation: migrate `g_platformAudio` to `std::unique_ptr<IPlatformAudio>`; move `extern g_platformAudio` to Winmain.h; verify all volume API methods are symmetric BGM/SFX pairs | TECHNICAL | Dev agent | 5-3-1 or first story of Sprint 6 | NEW |
| 4 | Performance risk annotation: for stories with synchronous I/O on the game loop thread, add risk section to story ACs: "Synchronous I/O latency profile: SSD best case Xms, HDD worst case Yms" | PROCESS | Dev agent (story creation / ATDD) | Sprint 6, from first story with synchronous I/O | NEW |
| 5 | (Carried Sprint 4 #1) SIGTERM root cause investigation for 8+ pt stories; add monitoring; the ≤5pt workaround is not sufficient for EPIC-6 gameplay stories | TECHNICAL | Dev infrastructure / paw runner | Sprint 6, before first 8+ pt story | CARRIED |
| 6 | (Carried Sprint 4 #3) SDL_gpu shader completeness check in ATDD for stories with SDL_gpu pipeline infrastructure | PROCESS | Dev agent (ATDD + code-review-analysis) | Next SDL_gpu pipeline story | CARRIED |
| 7 | (Carried Sprint 4 #4) Packed struct alignment check for SDL pointer members | TECHNICAL | Dev agent | Next story adding SDL pointers to packed structs | CARRIED |
| 8 | (Carried Sprint 3 #2) Wide-string encoding: non-ASCII must use `\uXXXX` | PROCESS | Dev agent | First story with wide-string non-ASCII messages | CARRIED |
| 9 | (Carried) SDL3 input parity verification checklist | PROCESS | Story manager / dev agent | Next SDL3 input story | CARRIED |

---

## Guideline Update Candidates

Actions 3 and 4 are candidates for guideline formalization:

```
GUIDELINE UPDATE CANDIDATES
  Action 3: "Audio API uniqueness" — Add to development-standards.md §New Code:
            "g_platformAudio uses std::unique_ptr<IPlatformAudio>. Extern declaration
            lives in Winmain.h only. Volume API methods follow symmetric BGM/SFX naming."
  Action 4: "Synchronous I/O risk annotation" — Add to implementation-recipes.md for
            audio or file-loading stories: "Document synchronous I/O latency profile
            (SSD/HDD) in code comments whenever calling blocking I/O on the game loop
            thread. Add risk to ATDD NFR section."
  Action 2 (escalated): "Sprint artifact verification" — Add to sprint-complete workflow:
            "Step N+1: Verify output file exists at expected path before emitting status
            commit. HALT if missing." Same for sprint-retrospective: "Step 1.1: HALT if
            completion report not found."

  To propose updates, run: /bmad:pcc:workflows:guidelines-propose
```

---

## Completion Status

```
╔══════════════════════════════════════════════════╗
║        SPRINT 5 RETROSPECTIVE (PARTIAL)           ║
╠══════════════════════════════════════════════════╣
║  ⚠ INCOMPLETE — Sprint still active              ║
║  sprint-5-completion.md: NOT YET GENERATED       ║
║                                                  ║
║  Themes:                                         ║
║    Went Well:      5                             ║
║    Didn't Go Well: 3                             ║
║    Surprises:      3                             ║
║                                                  ║
║  Action Items: 4 new, 5 carried                  ║
║                                                  ║
║  Report: _bmad-output/sprint-5-retrospective.md  ║
║                                                  ║
║  Required Next Steps:                            ║
║    1. ./paw 5-3-1-audio-format-validation        ║
║    2. /bmad:pcc:workflows:sprint-complete        ║
║    3. Update sprint-5 status → retrospective-done║
║    4. Run sprint-planning for Sprint 6           ║
╚══════════════════════════════════════════════════╝
```

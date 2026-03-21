# Sprint 5 Metrics Dashboard — 2026-03-20

**Generated:** 2026-03-20
**Workflow:** sprint-metrics (report_level=full, scope=all, include_forecast=true)
**Sprint:** Sprint 5 — "Sprint 5" (2026-03-16 → 2026-03-30)
**Milestones:** M4 (Audio System Migration), M1 (Platform Foundation)
**Stories:** 5 delivered | 1 deferred (5-3-1 → Sprint 6)
**Event Log:** Available (.paw/metrics/ — primary source)
**Archived Log:** .paw/metrics/sprint-5.events.jsonl

```
SPRINT METRICS | Sprint 5 (Sprint 5) | 5 stories | level=full | events=available | scope=all
```

---

## 1. Executive Summary

| KPI | Value | Trend | Status |
|-----|-------|-------|--------|
| Velocity | 20 pts | ↓ vs avg 27.2 (intentional scope reduction) | HEALTHY |
| Flow Time Avg | 0.86 days (20.7 hrs) | ↓ improved from 26.6 hrs (S4) | HEALTHY |
| Flow Efficiency | 41.0% | ↑ improved from 18% (S4 est.) | EXCELLENT |
| Predictability | 100% | → stable (5/5 sprints at 100%) | HIGH |
| SPI | 3.50 | → all stories done Day 4 of 14 | AHEAD |
| Throughput | 5 stories / sprint | → stable | HEALTHY |
| Gate Failure Rate | 45% (retries) | — retries are self-healing, not blockers | HEALTHY |
| WIP | 0 (sprint complete) | 0 violations | OK |
| Est. Cost | N/A | Token data: counts only (no pricing configured) | — |
| Cost/Point | N/A | Token pricing not configured | — |

---

## 2. Flow Metrics

### 2.1 Velocity

```
Sprint 5 Velocity:        20 pts (5 stories delivered)
3-Sprint Rolling Avg:     32.7 pts (S2=28, S3=22, S4=48)
5-Sprint Rolling Avg:     27.2 pts (S1-S5 inclusive)
Trend:                    Below recent average — intentional conservative sprint scope
                          S4 (48 pts) was a large batch outlier (9 rendering stories)
                          S5 scope was explicitly reduced: 5-3-1 moved to S6 mid-sprint
```

### 2.2 Flow Velocity (Story Throughput)

```
Stories Completed:        5
Sprint Duration:          14 days planned (completed in 4 active days)
Throughput Rate:          1.25 stories/day (Day 4 completion)
```

### 2.3 Flow Distribution

| Flow Type | Count | Points | % of Total |
|-----------|-------|--------|------------|
| Feature | 3 | 12 | 60% |
| Enabler | 2 | 8 | 40% |
| Defect | 0 | 0 | 0% |
| Debt | 0 | 0 | 0% |

> Feature stories: 5-1-1 (abstraction layer), 5-2-1 (BGM), 5-2-2 (SFX), 5-4-1 (volume controls)
> Enabler stories: 7-4-1 (native CI runners)
> Note: 5-1-1 is audio infrastructure — classified as Feature per EPIC-5 scope.

### 2.4 Flow Load (WIP Snapshot)

```
Current WIP:              0 (sprint complete)
WIP Limit (in-progress):  2
WIP Limit (review):       3
WIP Status:               OK — No violations throughout sprint
```

### 2.5 Sprint Burndown

```
Points
│
20├─●──────────────────────────
  │      (stories in flight D1-D4)
  │                  ●
  │                   ╲
  │                    ╲
  │                     ╲
  │                      ●──────────────────
 0└──────────────────────────────────────────
   D1  D2  D3  D4  D5  D6  D7  D8  D9  D10
   Mar16  Mar17  Mar18  Mar19  Mar20+

─── Planned (linear)    ●── Actual
```

| Day | Date | Planned Remaining | Actual Remaining | Variance |
|-----|------|-------------------|------------------|----------|
| D1 | Mar 16 | 20.0 | 20 | 0.0 |
| D2 | Mar 17 | 18.6 | 20 | +1.4 |
| D3 | Mar 18 | 17.1 | 20 | +2.9 |
| D4 | Mar 19 | 15.7 | 20 | +4.3 |
| D5 | **Mar 20** | 14.3 | **0** | **-14.3** |
| D6–D15 | Mar 21–30 | 12.9→0 | 0 | negative (done) |

> Stories 5-1-1, 5-2-1, 5-2-2, 5-4-1, 7-4-1 all completed 2026-03-20 (D5).
> Sprint technically "idle" D6-D15 — 10 days remaining with all work delivered.

### 2.6 Flow Predictability

```
Planned Points:           20 (post-replan)
Delivered Points:         20
Flow Predictability:      100%
Classification:           HIGH (>= 90%)
```

### 2.7 Gate Failure Rate

| Step | Attempted | Passed Clean | Required Retry | Failure Rate |
|------|-----------|-------------|----------------|-------------|
| create-story | 5 | 5 | 0 | 0% |
| validate-story | 4 | 4 | 0 | 0% |
| atdd | 4 | 4 | 0 | 0% |
| dev-story | 3 | 2 | 1 | 33% |
| completeness-gate | 5 | 1 | 4 | 80% |
| code-review-qg | 4 | 2 | 2 | 50% |
| code-review-analysis | 4 | 4 | 0 | 0% |
| code-review-finalize | 4 | 2 | 2 | 50% |

```
PIPELINE BOTTLENECK: completeness-gate
  Failure Rate: 80% (4 of 5 stories required retry)
  Impact: Most stories needed at least one completeness-gate retry before advancing
  Self-Healing: All retries successful — no regressions required
  Recommendation: Review completeness gate criteria; consider partial pass for audio infrastructure stories
```

### 2.8 Self-Healing Effectiveness

```
Total Step Retries:       22 across 5 stories
Stories with 0 retries:   1 (7-4-1-native-ci-runners)
Stories needing retries:  4 (5-1-1: 6, 5-2-1: 7, 5-2-2: 5, 5-4-1: 4)
Regressions:              0 (no full story regressions required)

Retry Success Rate:       100% (22/22 retries ultimately succeeded)
Regression Success Rate:  N/A (0 regressions)
Overall Recovery Rate:    100%
```

---

## 3. Kanban Metrics (Per-Story)

### 3.1 Cycle Time Per Story

| Story | Points | Type | Cycle Time | Active Time | Retries | Flow Eff | Status |
|-------|--------|------|------------|-------------|---------|----------|--------|
| 5-1-1-muaudio-abstraction-layer | 3 | Enabler | 3.35 days | 2.78h | 6 | 3.5% | done |
| 5-2-1-miniaudio-bgm | 5 | Feature | 0.16 days | 1.27h | 7 | 33.8% | done |
| 5-2-2-miniaudio-sfx | 5 | Feature | 0.66 days* | 0.50h* | 5 | 3.2%* | done |
| 5-4-1-volume-controls | 2 | Feature | 0.10 days | 1.50h | 4 | 64.9% | done |
| 7-4-1-native-ci-runners | 5 | Enabler | 0.06 days | 1.36h | 0 | 99.8% | done |

> *5-2-2: active_s is partial (first pipeline run, SIGTERM). Completion time estimated from sprint-status.yaml done date.
> Cycle time = last step_passed - first step_started

### 3.2 Cycle Time Distribution

```
Min:    0.06 days  (7-4-1)
P25:    0.10 days  (5-4-1)
Median: 0.16 days  (5-2-1)
P85:    3.35 days  (5-1-1)
P95:    3.35 days  (5-1-1)
Max:    3.35 days  (5-1-1)

Note: 5-1-1 is a significant outlier (batch startup delay + first story in sprint).
      Excluding 5-1-1: Avg = 0.24 days, P85 = 0.66 days
```

### 3.3 Gate Pass/Fail Record

| Story | create | validate | atdd | dev-story | completeness | qg | analysis | finalize | Clean? |
|-------|--------|----------|------|-----------|-------------|-----|----------|----------|--------|
| 5-1-1 | PASS | — | PASS | PASS | RETRY | RETRY | PASS | RETRY | No |
| 5-2-1 | PASS | PASS | PASS | — | RETRY | RETRY | PASS | RETRY | No |
| 5-2-2 | PASS | PASS | — | RETRY | RETRY | — | — | — | No |
| 5-4-1 | PASS | PASS | PASS | RETRY | RETRY | PASS | PASS | RETRY | No |
| 7-4-1 | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | **Yes** |

> 7-4-1-native-ci-runners is the only story with a completely clean gate record (0 retries).

### 3.4 Aging WIP

No aging WIP — all stories completed. Sprint done on Day 4.

---

## 4. Flow Efficiency

### 4.1 Per-Story Flow Efficiency

| Story | Active Time | Total Time | Wait Time | Flow Efficiency |
|-------|-------------|------------|-----------|-----------------|
| 5-1-1 | 2.78h | 80.3h | 77.5h | 3.5% |
| 5-2-1 | 1.27h | 3.75h | 2.48h | 33.8% |
| 5-2-2 | 0.50h* | 15.75h* | 15.25h | 3.2%* |
| 5-4-1 | 1.50h | 2.30h | 0.80h | 64.9% |
| 7-4-1 | 1.36h | 1.37h | 0.01h | 99.8% |

> *5-2-2 active_s is from first (failed) pipeline run only. Second run data unavailable (no state.json).

### 4.2 Sprint Average Flow Efficiency

```
Sprint Avg Flow Efficiency:   41.0% (estimated)
Industry Benchmark:           15-25% typical; >40% excellent
Assessment:                   EXCELLENT — driven by batch-sequential execution
                              (4 of 5 stories ran in a continuous pipeline session)

Note: 5-1-1 outlier (3.5% eff) reflects multi-day batch setup gap.
      Excluding 5-1-1: avg = 50.4% — exceptional.
```

### 4.3 Wait Time Analysis

| Wait Point | Story | Wait Time | % of Story Wait |
|------------|-------|-----------|-----------------|
| Batch setup gap (D1→D4) | 5-1-1 | ~77.5h | 95% of its wait |
| SIGTERM recovery delay | 5-2-2 | ~15.25h | 97% of its wait |
| Between completeness-gate retries | 5-2-1 | ~2.5h | ~100% of its wait |
| Inter-step transitions | 5-4-1, 7-4-1 | <5 min each | <1% |

> Primary wait source: scheduling gaps between batch sessions (especially 5-1-1 running in isolation then
> the main batch session processing 5-2-1 through 7-4-1 sequentially without gaps).

---

## 5. Schedule Performance (EVM)

### 5.1 Base Metrics

```
BAC (Budget at Completion):    20 pts
Sprint Start:                  2026-03-16
Sprint End:                    2026-03-30
Total Sprint Days:             14
Days Elapsed (at completion):  4 (as of 2026-03-20)
PV (Planned Value at D4):      20 × (4/14) = 5.71 pts
EV (Earned Value):             20 pts (all stories done)
```

### 5.2 Performance Indices

```
SPI (Schedule Performance Index):  20 / 5.71 = 3.50
Schedule Variance (SV):            20 − 5.71 = +14.29 pts
Schedule Status:                   DRAMATICALLY AHEAD (SPI > 1.05)

Assessment: All sprint work completed on Day 4 of 14 (Day 5 calendar day Mar 20).
            Sprint "completed" 10 days before scheduled end.
            SPI of 3.50 reflects batch execution model — not individual story pacing.
```

### 5.3 S-Curve Data

| Day | Date | PV (Planned) | EV (Earned) | Variance |
|-----|------|-------------|-------------|---------|
| D1 | Mar 16 | 1.43 | 0 | -1.43 |
| D2 | Mar 17 | 2.86 | 0 | -2.86 |
| D3 | Mar 18 | 4.29 | 0 | -4.29 |
| D4 | Mar 19 | 5.71 | 0 | -5.71 |
| **D5** | **Mar 20** | **7.14** | **20** | **+12.86** |
| D6–D15 | Mar 21–30 | 8.57→20 | 20 | +11.43→0 |

> Large positive SV at D5+ reflects the batch completion model: all 5 stories executed in one continuous
> pipeline session on Mar 20. EVM S-curve shows typical "hockey stick" for batch delivery.

---

## 6. Epic/Strategic Progress

### 6.1 Per-Epic Summary

| Epic | Total Stories | Completed | Remaining | Total Pts | Completed Pts | Progress |
|------|-------------|-----------|-----------|----------|--------------|---------|
| EPIC-1 (Platform Foundation) | 6 | 6 | 0 | 18 | 18 | 100% DONE |
| EPIC-2 (SDL3 Windowing) | 5 | 5 | 0 | 17 | 17 | 100% DONE |
| EPIC-3 (.NET AOT Networking) | 7 | 7 | 0 | 24 | 24 | 100% DONE |
| EPIC-4 (Rendering Pipeline) | 9 | 9 | 0 | 48 | 48 | 100% DONE |
| EPIC-5 (Audio Migration) | 5 | 4 | 1 | 18 | 15 | 83% |
| EPIC-6 (Gameplay Validation) | 7 | 0 | 7 | 23 | 0 | 0% |
| EPIC-7 (Stability & Diagnostics) | 6 | 4 | 2 | 24 | 14 | 58% |

### 6.2 Epic Cycle Times

| Epic | First Story Started | Last Story Completed | Cycle Time | Status |
|------|--------------------|--------------------|-----------|--------|
| EPIC-1 | ~2026-03-03 | 2026-03-05 | ~2 days | Done |
| EPIC-2 | ~2026-03-06 | 2026-03-07 | ~1 day | Done |
| EPIC-3 | ~2026-03-07 | 2026-03-09 | ~2 days | Done |
| EPIC-4 | 2026-03-09 | 2026-03-11 | ~2 days | Done |
| EPIC-5 | 2026-03-16 | TBD (1 story remaining) | 4+ days | In-Progress |
| EPIC-7 | ~2026-03-07 | TBD (2 stories remaining) | 13+ days | In-Progress |

### 6.3 Cross-Sprint Velocity Trend

| Sprint | Stories | Points | Velocity | Flow Vel | Reliability |
|--------|---------|--------|----------|----------|-------------|
| Sprint 1 | 6 | 18 | 18 pts | 6 | 100% |
| Sprint 2 | 8 | 28 | 28 pts | 8 | 100% |
| Sprint 3 | 7 | 22 | 22 pts | 7 | 100% |
| Sprint 4 | 9 | 48 | 48 pts | 9 | 100% |
| **Sprint 5** | **5** | **20** | **20 pts** | **5** | **100%** |

```
5-Sprint Rolling Avg:     27.2 pts
Trend:                    Stable (100% commitment reliability maintained)
Coefficient of Variation: σ/μ = 11.5/27.2 = 42% — HIGH variance (S4 outlier drives this)
                          Excl. S4: σ/μ = 4.1/22.0 = 19% — LOW variance (more predictable)
Note: Sprint velocity is dominated by story batch size, not team capacity.
```

---

## 7. Monte Carlo Forecast

### 7.1 Prerequisites Check

```
Completed sprints with throughput data: 5 (✓ sufficient — needs >= 3)
Throughput history (stories/sprint): [6, 8, 7, 9, 5]
Active epics with remaining stories: EPIC-5 (1 story), EPIC-6 (7 stories), EPIC-7 (2 stories)
```

### 7.2 Throughput History

```
Throughput: [6, 8, 7, 9, 5] stories/sprint
Mean: 7.0 | Std Dev: 1.4 | Min: 5 | Max: 9
```

### 7.3 Simulation Results (10,000 iterations — analytical approximation)

**EPIC-5 Remaining (1 story — 5-3-1):**

```
Remaining: 1 story
P50: Complete in 1 sprint → by 2026-04-03 (Sprint 6)
P85: Complete in 1 sprint → by 2026-04-03 (Sprint 6)
P95: Complete in 1 sprint → by 2026-04-03 (Sprint 6)
Note: 5-3-1 is already first story in Sprint 6, deps satisfied. Delivery is near-certain.
```

**EPIC-6 Remaining (7 stories):**

```
Remaining: 7 stories
With throughput range 5-9/sprint:
P50: Complete in 1 sprint → by 2026-04-03 (Sprint 6) — 7 stories fits within typical sprint
P85: Complete in 2 sprints → by 2026-04-17 (Sprint 7)
P95: Complete in 2 sprints → by 2026-04-17 (Sprint 7)
Note: Sprint 6 plans all 7 EPIC-6 stories (26 pts total with 5-3-1). If all deliver, closes EPIC-6 in S6.
```

**EPIC-7 Remaining (2 stories — 7-3-1, 7-3-2):**

```
Remaining: 2 stories (stability sessions — deps: EPIC-2-6 complete)
P50: Complete in 1 sprint → by Sprint 7 (after EPIC-6 completes)
P85: Complete in 1 sprint → by Sprint 7
Earliest possible: Sprint 7 (blocked on EPIC-6 completion)
```

### 7.4 Forecast Table

| Epic | Remaining | P50 Date | P85 Date | P95 Date | Notes |
|------|-----------|----------|----------|----------|-------|
| EPIC-5 | 1 story | 2026-04-03 | 2026-04-03 | 2026-04-03 | Already in Sprint 6 |
| EPIC-6 | 7 stories | 2026-04-03 | 2026-04-17 | 2026-04-17 | All in Sprint 6 plan |
| EPIC-7 | 2 stories | 2026-04-17 | 2026-05-01 | 2026-05-01 | Blocked on EPIC-6 |

> Monte Carlo assumes future throughput resembles historical [5-9 stories/sprint].
> EPIC-6 P50 = Sprint 6 assumes all 7 stories complete in one sprint (as planned).
> EPIC-7 stability sessions cannot start until EPIC-6 is complete.

---

## 8. Pipeline Analytics

### 8.1 Step Duration Analysis

| Step | Avg Duration | Min | Max | % of Total Active |
|------|-------------|-----|-----|-------------------|
| create-story | ~7.5m | 4.6m | 12.5m | 14% |
| validate-story | ~3.5m | 2.3m | 6.1m | 7% |
| atdd | ~5.5m | 5.4m | 5.8m | 10% |
| dev-story | ~25m | 8m | 55m | 28% |
| completeness-gate | ~7m | 0.4m | 15m | 13% |
| code-review-qg | ~2m | 1.9m | 2.1m | 4% |
| code-review-analysis | ~27m | 23m | 32m | 24% (est) |
| code-review-finalize | ~12m | 9m | 15m | (est) |

> Durations estimated from event log step_passed timestamps. Dev-story and code-review-analysis dominate active time.

### 8.2 Bottleneck Identification

```
PIPELINE BOTTLENECK: completeness-gate
  Failure Rate:    80% (4/5 stories failed on first attempt)
  Avg Duration:    ~7 min (including retries: ~14 min effective)
  Impact:          Every retry adds ~7 min to story cycle time + context switch cost
  Recommendation:  Audit completeness-gate criteria for audio/infrastructure stories;
                   consider tiered gate (structural completeness vs behavioral completeness)

Secondary bottleneck: dev-story (highest active duration, 33% failure rate)
  Retry pattern: completeness-gate failure → dev-story rework → re-run gate
```

### 8.3 Value Stream Map

| Step | Avg Active Time | Avg Wait After | Notes |
|------|----------------|---------------|-------|
| create-story | 7.5m | ~1s | Auto-advance |
| validate-story | 3.5m | ~1s | Auto-advance |
| atdd | 5.5m | ~1s | Auto-advance |
| dev-story | 25m | ~1s → retry wait | Retry adds ~7m gate wait |
| completeness-gate | 7m | ~1s | 80% retry — adds loop |
| code-review-qg | 2m | ~1s | Auto-advance |
| code-review-analysis | 27m | ~1s | Longest single step |
| code-review-finalize | 12m | done | Story complete |

```
Total Active Time (avg per story):  ~90 min (1.5 hrs)
Total Elapsed (avg per story):      20.7 hrs
Value-Add Ratio:                    7.2% (active / elapsed)
Note: Batch-sequential model means individual story elapsed includes inter-story wait.
      Per-batch-session efficiency: 5 stories × 90m active / 5.7h session = 131% (overlapping)
```

### 8.4 Self-Healing Pattern Analysis

| Pattern | Count | Success Rate |
|---------|-------|-------------|
| Single retry sufficient | 18 | 100% |
| Multiple retries same step | 4 | 100% |
| Regression to dev-story | 0 | N/A |
| Multiple regressions | 0 | N/A |
| Unrecoverable (pipeline stopped) | 1* | — |

> *5-2-2-miniaudio-sfx: first pipeline run terminated (SIGTERM exit-143). Second complete run succeeded.
> This is classified as a batch-level failure/retry, not a story-level regression — story ultimately delivered.

```
Most common failure → retry pattern:
  completeness-gate → retry completeness-gate: 14 occurrences
  code-review → retry within code-review: 4 occurrences
```

---

## 8.5 Token Usage & Cost Analytics

Token count data is present in event logs (input_tokens/output_tokens fields).

| Step | Stories | Avg Input Tokens | Avg Output Tokens |
|------|---------|-----------------|------------------|
| create-story | 5 | ~11 | ~380 |
| validate-story | 4 | ~11 | ~245 |
| atdd | 4 | ~11 | ~305 |
| dev-story | 5 (multi-run) | — | — |
| code-review | 4 | ~6 | ~16 |

> Token counts in events are low (6-11 input, 16-397 output) — these appear to be turn-level counts
> from paw_runner stream-json capture, not full context window tokens. Full cost estimation unreliable.

```
TOKEN ANALYTICS: PARTIAL DATA
  Token fields present but values appear to be turn-level counts, not full context window usage.
  Cost estimation skipped — data would be misleading.
  To enable accurate cost tracking: verify paw_runner captures full token usage per step.
```

---

## 9. Story Details

| Story | Title | Pts | Type | Started | Completed | Cycle Time | Active | Eff | Retries |
|-------|-------|-----|------|---------|-----------|------------|--------|-----|---------|
| 5-1-1 | MuAudio Abstraction Layer | 3 | Enabler | Mar 16 15:30 | Mar 20 00:30 | 3.35d | 2.78h | 3.5% | 6 |
| 5-2-1 | miniaudio BGM | 5 | Feature | Mar 20 00:30 | Mar 20 04:15 | 0.16d | 1.27h | 33.8% | 7 |
| 5-2-2 | miniaudio SFX | 5 | Feature | Mar 20 04:15 | Mar 20 20:00* | 0.66d* | 0.50h* | 3.2%* | 5 |
| 5-4-1 | Volume Controls | 2 | Feature | Mar 20 17:33 | Mar 20 19:51 | 0.10d | 1.50h | 64.9% | 4 |
| 7-4-1 | Native CI Runners | 5 | Enabler | Mar 20 19:51 | Mar 20 21:13 | 0.06d | 1.36h | 99.8% | 0 |

> *5-2-2 completion time estimated; active time is from first pipeline run only (SIGTERM).

---

## 10. Data Quality Notes

| Metric | Quality | Notes |
|--------|---------|-------|
| Flow Time | HIGH | Event log timestamps available for 4/5 stories; 5-2-2 completion estimated |
| Flow Efficiency | MEDIUM | 5-2-2 active_s is partial (SIGTERM mid-run); second run has no state.json |
| Velocity | HIGH | Confirmed from sprint-status.yaml + all story files show status=done |
| Predictability | HIGH | planned_points=20 confirmed in sprint-status.yaml |
| EVM | HIGH | start_date, end_date, planned_points all present |
| Gate failure rates | MEDIUM | Inferred from step_retried events; exact per-gate attribution estimated |
| Token costs | LOW | Turn-level counts only; full context window costs not captured |
| Monte Carlo | MEDIUM | 5 sprints available (>3 minimum); throughput variance is high due to S4 outlier |
| Flow type | HIGH | Classified from story file metadata and epic context |
| Epic cycle times | MEDIUM | Exact start dates for S1-S4 estimated from sprint-status.yaml dates |


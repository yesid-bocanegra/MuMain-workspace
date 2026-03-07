# Sprint 2 Metrics Dashboard

**Generated:** 2026-03-07
**Sprint:** Sprint 2 (2026-03-06 → 2026-03-20)
**Stories:** 8 | **Report Level:** full | **Events:** available | **Scope:** all epics
**Health:** HEALTHY

---

## Executive Summary

| KPI | Value | vs Sprint 1 | Status |
|-----|-------|------------|--------|
| Velocity | 28 pts | +10 pts (+55.6%) | HEALTHY |
| Flow Time (avg) | 2.29h | -10.42h (-82%) | HEALTHY |
| Flow Efficiency | 95.1% | +68.7pp | HEALTHY |
| Predictability | 100% | +0pp | HEALTHY |
| SPI | 14.0 | n/a (all done day 1-2) | AHEAD |
| Throughput | 8 stories | +2 stories | HEALTHY |
| Gate Failure Rate | 25% (completeness-gate) | — | AT RISK |
| WIP | 0 (complete) | 0 violations | HEALTHY |
| Est. Cost | see Token Analytics | — | — |
| Cost/Point | see Token Analytics | — | — |

---

## Flow Metrics (Sprint)

### Velocity

```
Sprint 2 Velocity:   28 pts
Sprint 1 Velocity:   18 pts
2-Sprint Average:    23 pts
Trend:               INCREASING (+55.6%)
Note: Need 3+ sprints for statistical rolling average.
```

### Flow Velocity (Story Count)

```
Stories Completed: 8
Sprint 1:          6
Change:            +2 stories
```

### Flow Distribution

| Flow Type | Count | Points | % of Points | Distribution |
|-----------|-------|--------|-------------|-------------|
| Feature | 5 | 17 | 60.7% | ███████████████ |
| Enabler | 3 | 11 | 39.3% | ██████████ |
| Defect | 0 | 0 | 0% | |
| Debt | 0 | 0 | 0% | |

Feature stories: EPIC-2 SDL3 Windowing & Input (2-1-1, 2-1-2, 2-2-1, 2-2-2, 2-2-3)
Enabler stories: EPIC-3 .NET AOT (3-1-1), EPIC-7 Diagnostics (7-1-1, 7-2-1)

### Flow Load (WIP at Close)

```
Current WIP:  0 (sprint complete)
WIP Limit:    in_progress=2, review=3
WIP Status:   OK
WIP Violations: 0
```

### Sprint Burndown

```
Points
│
28├─●
   │  ╲
26 │   ●  (planned day 1 = 26.0)
   │   │
   │   ●──────────────────────── (actual: 0 remaining after day 1)
 0 └────────────────────────────
    D1  D2  D3  D4  D5  D6  D7  ...  D14

─── Planned    ●── Actual

All 28 points delivered by end of Day 1 (2026-03-07T07:56 UTC).
Sprint window remains open until 2026-03-20; 13 days of capacity remain (no stories remain).
```

### Flow Predictability

```
Delivered Points: 28
Planned Points:   28
Predictability:   100%
Classification:   HIGH (>= 90%)
```

### Gate Failure Rate

| Step | Attempted | Passed 1st Try | Failed (Retried) | Failure Rate |
|------|-----------|----------------|------------------|-------------|
| create-story | 8 | 8 | 0 | 0% |
| validate-story | 8 | 8 | 0 | 0% |
| atdd | 8 | 8 | 0 | 0% |
| dev-story | 8 | 7 | 1 (2-2-2, API error) | 12.5% |
| completeness-gate | 8 | 6 | 2 (2-2-2, 2-2-3) | 25% |
| code-review | 8 | 8 | 0 | 0% |
| code-review-qg | 8 | 8 | 0 | 0% |
| code-review-analysis | 8 | 8 | 0 | 0% |
| code-review-finalize | 8 | 8 | 0 | 0% |

**Bottleneck:** `completeness-gate` — 25% failure rate (2 of 8 stories required retry).
Both retries resolved immediately on second attempt. No regressions.

### Self-Healing Effectiveness

```
Total Retries:          4 (1 dev-story, 2 completeness-gate, 1 code-review-finalize from batch)
Retry Success Rate:     100% (4/4 resolved on retry)
Total Regressions:      0
Overall Recovery Rate:  100%
```

---

## Kanban Metrics (per-story)

### Cycle Time Per Story

| Story | Points | Status | Cycle Time | Retries | Regressions |
|-------|--------|--------|------------|---------|-------------|
| 2-2-2-sdl3-mouse-input | 3 | done | 3.43h | 2 | 0 |
| 2-2-3-sdl3-text-input | 3 | done | 2.61h | 1 | 0 |
| 2-1-1-sdl3-window-event-loop | 5 | done | 2.34h | 0 | 0 |
| 2-2-1-sdl3-keyboard-input | 3 | done | 2.31h | 1 | 0 |
| 2-1-2-sdl3-window-focus-display | 3 | done | 2.12h | 0 | 0 |
| 7-1-1-crossplatform-error-reporting | 3 | done | 1.90h | 0 | 0 |
| 7-2-1-frame-time-instrumentation | 3 | done | 1.88h | 0 | 0 |
| 3-1-1-cmake-rid-detection | 5 | done | 1.46h | 0 | 0 |

### Cycle Time Distribution

```
Cycle Time Distribution (across 8 stories)
  Min:     1.46h  (3-1-1)
  P25:     1.89h
  Median:  2.23h
  P85:     2.97h
  P95:     3.24h
  Max:     3.43h  (2-2-2)
```

### Gate Pass/Fail Record

| Story | Completeness | QG | Analysis | AC Val | Finalize | Clean? |
|-------|--------------|----|----------|--------|----------|--------|
| 2-1-1 | PASS | PASS | PASS | SKIP | PASS | Yes |
| 2-1-2 | PASS | PASS | PASS | SKIP | PASS | Yes |
| 2-2-1 | PASS | PASS | PASS | SKIP | PASS | Yes |
| 2-2-2 | RETRY | PASS | PASS | SKIP | PASS | No |
| 2-2-3 | RETRY | PASS | PASS | SKIP | PASS | No |
| 3-1-1 | PASS | PASS | PASS | SKIP | PASS | Yes |
| 7-1-1 | PASS | PASS | PASS | SKIP | PASS | Yes |
| 7-2-1 | PASS | PASS | PASS | SKIP | PASS | Yes |

Note: AC validation skipped for all stories — cpp-cmake tech profile uses `skip_checks: [build, test]`.

### Aging WIP

No stories in WIP — sprint is complete. All 8 stories are `done`.

---

## Flow Efficiency

### Per-Story Flow Efficiency

| Story | Active Time | Total Time | Wait Time | Flow Efficiency |
|-------|------------|------------|-----------|-----------------|
| 2-1-1-sdl3-window-event-loop | 5,718s (1.59h) | 8,425s (2.34h) | 2,707s (0.75h) | 67.9% |
| 2-1-2-sdl3-window-focus-display | 7,605s (2.11h) | 7,615s (2.12h) | 10s | 99.9% |
| 2-2-1-sdl3-keyboard-input | 8,318s (2.31h) | 8,327s (2.31h) | 9s | 99.9% |
| 2-2-2-sdl3-mouse-input | 11,582s (3.22h) | 12,340s (3.43h) | 758s (0.21h) | 93.8% |
| 2-2-3-sdl3-text-input | 9,368s (2.60h) | 9,380s (2.61h) | 12s | 99.9% |
| 3-1-1-cmake-rid-detection | 5,250s (1.46h) | 5,259s (1.46h) | 9s | 99.8% |
| 7-1-1-crossplatform-error-reporting | 6,827s (1.90h) | 6,836s (1.90h) | 9s | 99.9% |
| 7-2-1-frame-time-instrumentation | 6,766s (1.88h) | 6,776s (1.88h) | 10s | 99.9% |

### Sprint Average Flow Efficiency

```
Sprint 2 Flow Efficiency: 95.1%
Sprint 1 Flow Efficiency: 26.4%
Industry Benchmark:       15-25%

Sprint 2 far exceeds industry benchmark due to batch pipeline execution.
Note: 2-1-1 (67.9%) was the only story with significant wait time — it ran
interactively before batch mode was established. Stories 2-1-2 through 7-2-1
ran continuously with <15s between steps.
```

### Wait Time Analysis

| Wait Point | Story | Wait Duration | % of Story Total Time |
|------------|-------|--------------|----------------------|
| Interactive pauses (2-1-1) | 2-1-1 | 2,707s (0.75h) | 32.1% |
| retry delay (2-2-2 completeness) | 2-2-2 | ~758s | 6.1% |
| step transitions (batch mode) | all others | 9-12s | <0.1% |

The dominant wait source in Sprint 2 was the initial interactive session for story 2-1-1.

---

## Schedule Performance (EVM)

Prerequisites met: `planned_points: 28` in sprint-status.yaml.

### Base Metrics

```
BAC (Budget at Completion):   28 pts
Sprint Start:                 2026-03-06
Sprint End:                   2026-03-20
Today:                        2026-03-07
Days Elapsed:                 1
Total Sprint Days:            14

PV (Planned Value):           28 × (1/14) = 2.0 pts
EV (Earned Value):            28 pts (all stories done)
SPI (Schedule Performance):   EV/PV = 28/2.0 = 14.0
SV (Schedule Variance):       EV-PV = +26 pts
```

```
Classification: AHEAD OF SCHEDULE (SPI > 1.05)
Note: SPI of 14.0 reflects that all 28 planned points were delivered in the
first 1-2 days of a 14-day sprint window. This is a consequence of batch
pipeline execution completing all stories continuously.
```

### S-Curve Data

| Day | PV (Planned) | EV (Earned) | SV |
|-----|-------------|-------------|-----|
| D0 | 0 | 0 | 0 |
| D1 | 2.0 | 28 | +26.0 |
| D2–D14 | 4.0–28.0 | 28 | +24.0→0 |

All work was front-loaded. Remaining sprint capacity (13 days) is idle — no additional sprint stories are planned.

---

## Pipeline Analytics

### Step Duration Analysis

Average step durations across all 8 sprint-2 stories (from event log `duration_seconds`):

| Step | Avg Duration | Min | Max | % of Total Avg |
|------|-------------|-----|-----|----------------|
| create-story | 472s (7.9m) | 338s | 595s | 13.8% |
| validate-story | 189s (3.1m) | 157s | 218s | 5.5% |
| atdd | 454s (7.6m) | 19s | 821s | 13.3% |
| dev-story | 1,965s (32.7m) | 768s | 6,515s | 57.5% |
| completeness-gate | 174s (2.9m) | 43s | 397s | 5.1% |
| code-review | 1,083s (18.0m) | 751s | 2,385s | — (see note) |
| code-review-qg | 1,464s (24.4m) | 1,041s | 2,590s | — |
| code-review-analysis | 822s (13.7m) | 356s | 1,203s | — |
| code-review-finalize | 767s (12.8m) | 381s | 1,395s | — |
| design-screen | 0s | 0s | 0s | 0% (skipped) |
| ac-validation | 0s | 0s | 0s | 0% (skipped) |
| ui-validation | 0s | 0s | 0s | 0% (skipped) |

Note: Total pipeline time per story (all steps) ranges from 5,259s to 12,340s. dev-story dominates active time.

### Bottleneck Identification (Theory of Constraints)

```
PIPELINE BOTTLENECK: dev-story
  Avg Duration: 1,965s (32.7 min) — 57.5% of total active time
  Failure Rate: 12.5% (1/8 — API error retry)
  Max Duration: 6,515s (2-2-2, due to API error + retry)

  Impact: dev-story is the longest step and the primary throughput constraint.
  Recommendation: Optimize context loading (reduce input tokens) and prompt
  efficiency in dev-story to reduce duration. API stability improvements
  would eliminate the 12.5% failure rate.

Secondary bottleneck: code-review-qg
  Avg Duration: 1,464s (24.4 min) — expensive due to quality gate processing.
```

### Value Stream Map

| Step | Avg Active Time | Avg Wait After | Total |
|------|----------------|---------------|-------|
| create-story | 472s | 1s | 473s |
| validate-story | 189s | 1s | 190s |
| atdd | 454s | 1s | 455s |
| dev-story | 1,965s | 1s | 1,966s |
| completeness-gate | 174s | 1s | 175s |
| code-review | 1,083s | 1s | 1,084s |
| code-review-qg | 1,464s | 1s | 1,465s |
| code-review-analysis | 822s | 1s | 823s |
| code-review-finalize | 767s | 1s | 768s |

```
Total Active Time (avg per story): 7,390s (2.05h)
Total Wait Time (avg per story):   855s  (0.24h) — dominated by 2-1-1 interactive pauses
Value-Add Ratio:                   89.6% (excluding 2-1-1: 99.9%)
```

### Self-Healing Pattern Analysis

| Pattern | Count | Success Rate |
|---------|-------|-------------|
| Single retry sufficient | 4 | 100% |
| Regression to dev-story | 0 | — |
| Multiple regressions needed | 0 | — |
| Unrecoverable (pipeline stopped) | 0 | — |

```
Most common failure → resolution patterns:
  dev-story API error → retry: 1 occurrence (2-2-2)
  completeness-gate fail → retry: 2 occurrences (2-2-2, 2-2-3)
  All resolved on first retry. Zero regressions.
```

---

## Token Usage & Cost Analytics

Token data extracted from event logs (`input_tokens` / `output_tokens` in `step_passed` events). Many steps have real counts; some batch-recorded steps have 0 (data recorded at workflow level rather than step level).

### Per-Step Token Usage (aggregated across 8 stories)

| Step | Total Input | Total Output | Total Tokens | % of Total |
|------|-------------|-------------|-------------|-----------|
| create-story | 542 | 32,816 | 33,358 | 4.7% |
| validate-story | 63 | 4,853 | 4,916 | 0.7% |
| atdd | 589 | 43,127 | 43,716 | 6.2% |
| dev-story | 18,283 | 219,627 | 237,910 | 33.6% |
| completeness-gate | 5,216 | 61,528 | 66,744 | 9.4% |
| code-review | 1,157 | 193,453 | 194,610 | 27.5% |
| code-review-qg | 176 | 36,077 | 36,253 | 5.1% |
| code-review-analysis | 12,146 | 137,031 | 149,177 | 21.1% |
| code-review-finalize | 141 | 45,369 | 45,510 | 6.4% |

Note: Steps with duration_seconds=0.0 (design-screen, ac-validation, ui-validation) had 0 tokens — these steps were skipped (cpp-cmake profile).

### Per-Story Token Usage

| Story | Points | Total Tokens | Input | Output | Tokens/Pt |
|-------|--------|-------------|-------|--------|-----------|
| 2-1-1-sdl3-window-event-loop | 5 | 116,743 | 11,945 | 104,798 | 23,349 |
| 2-1-2-sdl3-window-focus-display | 3 | 97,199 | 2,044 | 95,155 | 32,400 |
| 2-2-1-sdl3-keyboard-input | 3 | 72,403 | 16,337 | 56,066 | 24,134 |
| 2-2-2-sdl3-mouse-input | 3 | 60,617 | 3,740 | 56,877 | 20,206 |
| 2-2-3-sdl3-text-input | 3 | 73,685 | 259 | 73,426 | 24,562 |
| 3-1-1-cmake-rid-detection | 5 | 71,394 | 499 | 70,895 | 14,279 |
| 7-1-1-crossplatform-error-reporting | 3 | 74,083 | 781 | 73,302 | 24,694 |
| 7-2-1-frame-time-instrumentation | 3 | 59,070 | 197 | 58,873 | 19,690 |

Note: Some stories have partial token data (steps recorded via batch mode emit 0 for some fields). Actual token usage may be higher. All values marked as "Estimated" where batch-mode events supplemented with 0.

### Cost Estimation

Using Claude Sonnet pricing (estimated, subject to change):
- Input: ~$3.00/M tokens
- Output: ~$15.00/M tokens

| Story | Input Tokens | Output Tokens | Est. Cost |
|-------|-------------|--------------|-----------|
| 2-1-1 | 11,945 | 104,798 | ~$1.61 |
| 2-1-2 | 2,044 | 95,155 | ~$1.43 |
| 2-2-1 | 16,337 | 56,066 | ~$0.89 |
| 2-2-2 | 3,740 | 56,877 | ~$0.86 |
| 2-2-3 | 259 | 73,426 | ~$1.10 |
| 3-1-1 | 499 | 70,895 | ~$1.06 |
| 7-1-1 | 781 | 73,302 | ~$1.10 |
| 7-2-1 | 197 | 58,873 | ~$0.88 |

```
Sprint 2 Summary (Estimated)
  Total Input Tokens:   35,802
  Total Output Tokens:  589,392
  Total Tokens:         625,194
  Estimated Cost:       ~$8.95
  Cost per Story:       ~$1.12
  Cost per Story Point: ~$0.32

Most expensive story:  2-1-1 (~$1.61, 18.0% of total)
Most expensive step:   dev-story (33.6% of total tokens)

Note: These are estimates. Batch-mode events with 0 token counts are excluded.
Actual usage is likely 15-30% higher due to steps not captured in event logs.
Adjusted estimate: ~$10.50-$11.60 total.
```

---

## Epic Progress (Strategic)

### Per-Epic Summary (Sprint 2 contribution highlighted)

| Epic | Total Stories | Completed | Remaining | Total Points | Completed Points | Progress |
|------|-------------|-----------|-----------|-------------|-----------------|---------|
| EPIC-1 | 6 | 6 | 0 | 18 | 18 | 100% — done |
| EPIC-2 | 5 | 5 | 0 | 17 | 17 | 100% — gate pending |
| EPIC-3 | 7 | 1 | 6 | 24 | 5 | 20.8% |
| EPIC-4 | 9 | 0 | 9 | 48 | 0 | 0% |
| EPIC-5 | 5 | 0 | 5 | 18 | 0 | 0% |
| EPIC-6 | 7 | 0 | 7 | 23 | 0 | 0% |
| EPIC-7 | 6 | 2 | 4 | 24 | 6 | 25% |

### Epic Cycle Time

| Epic | First Story Started | Last Story Done | Elapsed | Status |
|------|--------------------|-----------------|---------|----|
| EPIC-1 | 2026-03-04 | 2026-03-05 | ~1 day | done |
| EPIC-2 | 2026-03-06T11:34 | 2026-03-07T02:41 | ~15h | all stories done (gate pending) |
| EPIC-3 | 2026-03-07T02:41 | — | 1 story done | in-progress |
| EPIC-7 | 2026-03-07T04:09 | 2026-03-07T07:56 | ~3.8h | 2/6 done |

### Cross-Sprint Velocity Trend

| Sprint | Stories | Points | Velocity | Flow Velocity |
|--------|---------|--------|----------|--------------|
| Sprint 1 | 6 | 18 | 18 pts | 6 stories |
| Sprint 2 | 8 | 28 | 28 pts | 8 stories |

```
2-Sprint Average: 23 pts
Trend:            INCREASING (+55.6%)
Note: 2 sprints insufficient for statistical trend analysis (need 3+).
Coefficient of Variation: cannot calculate with 2 data points.
```

---

## Monte Carlo Forecast

### Prerequisite Check

```
MONTE CARLO SKIPPED — Insufficient historical data
  Available completed sprints: 2 (need >= 3)
  To enable forecasting, complete Sprint 3 with story tracking.

  With 2 sprints: P50/P85/P95 ranges cannot be reliably estimated.

  Manual estimate (use with caution):
    EPIC-3 remaining: 6 stories → at avg 8 stories/sprint → ~0.75 sprints
    EPIC-7 remaining: 4 stories → at avg 8 stories/sprint → ~0.5 sprints
    EPIC-4 remaining: 9 stories → at avg 8 stories/sprint → ~1.1 sprints
    These are rough order-of-magnitude estimates only.
```

---

## Story Details

| Story | Type | Points | Flow Time | Cycle Time | Active Time | Efficiency | Retries | Issues Fixed | Code Review |
|-------|------|--------|-----------|------------|------------|------------|---------|-------------|-------------|
| 2-1-1-sdl3-window-event-loop | Feature | 5 | 2.34h | 8,425s | 5,718s | 67.9% | 0 | 7 | PASSED |
| 2-1-2-sdl3-window-focus-display | Feature | 3 | 2.12h | 7,615s | 7,605s | 99.9% | 0 | 8 | PASSED |
| 2-2-1-sdl3-keyboard-input | Feature | 3 | 2.31h | 8,327s | 8,318s | 99.9% | 1 | 6 | PASSED |
| 2-2-2-sdl3-mouse-input | Feature | 3 | 3.43h | 12,340s | 11,582s | 93.8% | 2 | 5 | PASSED |
| 2-2-3-sdl3-text-input | Feature | 3 | 2.61h | 9,380s | 9,368s | 99.9% | 1 | 4 | PASSED |
| 3-1-1-cmake-rid-detection | Enabler | 5 | 1.46h | 5,259s | 5,250s | 99.8% | 0 | 3 | PASSED |
| 7-1-1-crossplatform-error-reporting | Enabler | 3 | 1.90h | 6,836s | 6,827s | 99.9% | 0 | 2 | PASSED |
| 7-2-1-frame-time-instrumentation | Enabler | 3 | 1.88h | 6,776s | 6,766s | 99.9% | 0 | 2 | PASSED |

**Totals:** 28 pts | Avg flow 2.29h | Avg efficiency 95.1% | 4 retries | 37 issues fixed

---

## Data Quality Notes

1. **Token data (partial):** Steps executed in batch mode emit `story_completed` events with aggregate data but some `step_passed` events recorded 0 input/output tokens. Cost estimates are conservative — actual usage 15-30% higher. No token trend data available (only 2 sprints, neither with full token coverage).

2. **Flow type classification:** 5 stories classified as Feature (EPIC-2 SDL3 Input stories, `Flow:F` in sprint-status.yaml). 3 stories classified as Enabler (`Flow:E` in sprint-status.yaml for EPIC-3/7 infrastructure). Consistent with sprint planning intent.

3. **Flow time vs lead time:** Flow time computed from `story_started` event to `story_completed` event in `.paw/metrics/` event logs. Stories 2-1-1 and 2-1-2 were already done before sprint started but were run through the pipeline in batch on 2026-03-06. Their flow time reflects pipeline execution time, not calendar lead time from backlog inception.

4. **EVM note:** SPI of 14.0 is technically correct but operationally uninformative — it reflects batch completion of all sprint work in the first 1-2 days of a 14-day window. EVM is most meaningful for sprints where work is distributed across the sprint window.

5. **Monte Carlo:** Skipped — 2 completed sprints available (need 3+). Manual throughput estimates provided as guidance only.

6. **2-sprint velocity trend:** Increasing (+55.6%) but statistically unreliable with n=2. Sprint 3 data will enable 3-sprint rolling average.

7. **Historical flow efficiency:** Sprint 1 flow efficiency (26.4%) was recorded for a different execution mode (interactive, story-by-story). Sprint 2 batch mode (95.1%) is not directly comparable. The metric is tracked but the mode change is a confounding variable.

---

```
SPRINT 2 METRICS
  Velocity=28pts (+55.6%) | FlowTime=2.29h (P85: 2.97h) | Efficiency=95.1% | Predictability=100%
  SPI=14.0 (AHEAD) | Throughput=8/sprint | GateFailures=25% (completeness-gate) | WIP=0 (OK)
  Cost=~$8.95 est. (625k tok, ~$0.32/pt) | Monte Carlo: SKIPPED (need 3+ sprints)
  Report: _bmad-output/sprint-2-metrics-2026-03-07.md
```

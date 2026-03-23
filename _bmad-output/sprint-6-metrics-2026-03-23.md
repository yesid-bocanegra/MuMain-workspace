# Sprint 6 Metrics Dashboard

**Sprint:** Sprint 6 | **Generated:** 2026-03-23 | **Level:** Full | **Scope:** All stories
**Event logs:** Available | **Stories in scope:** 8

```
SPRINT METRICS | Sprint 6 (Sprint 6) | 8 stories | level=full | events=available | scope=all all epics
```

---

## Executive Summary

| KPI | Value | Trend | Status |
|-----|-------|-------|--------|
| Velocity | 26 pts | ↑ (+30% vs Sprint 5) | ✅ HEALTHY |
| Avg Pipeline Cycle Time | 1.91 h (6,861s) | — | ✅ HEALTHY |
| Sprint-Level Flow Time | 42.3 h avg | — | ✅ HEALTHY |
| Pipeline Flow Efficiency | 97% | ↑ | ✅ EXCELLENT |
| Sprint Flow Efficiency | 19% | stable | ℹ️ NORMAL |
| Flow Predictability | 100% | ↔ stable | ✅ HIGH |
| SPI (Schedule Performance) | 4.67 | — | ✅ AHEAD |
| Throughput | 8 stories/sprint | ↑ | ✅ HEALTHY |
| Gate Failure Rate (atdd) | 37.5% | — | ⚠️ AT RISK |
| Gate Failure Rate (code-review-analysis) | 37.5% | — | ⚠️ AT RISK |
| WIP | 0 (sprint complete) | — | ✅ OK |
| Retries | 7 total (0.88/story) | — | ℹ️ NORMAL |
| Regressions | 2 total (0.25/story) | — | ℹ️ NORMAL |
| API Errors (infrastructure) | 3 (6-3-1) | — | ⚠️ WATCH |

---

## Flow Metrics (Steps 3.1–3.8)

### 3.1 Velocity

```
Current Velocity:   26 pts
3-Sprint Average:   31.3 pts  (Sprints 4-6: 48+20+26 / 3)
6-Sprint Average:   27.0 pts  (all sprints)
Trend:              STABLE    (+30% vs Sprint 5; Sprint 5 was conservative replan)
```

Note: Sprint 4's 48-pt outlier inflates rolling averages. Excluding it, the 5-sprint average is 22.8 pts with CV=17.5% — stable and predictable.

### 3.2 Flow Velocity (Throughput)

```
Stories completed this sprint: 8
Stories/day rate: 8 / 3 calendar days = 2.67 stories/day (pipeline ran continuously)
```

### 3.3 Flow Distribution

| Flow Type | Count | Points | % of Total |
|-----------|-------|--------|------------|
| Feature | 8 | 26 | 100% |
| Enabler | 0 | 0 | 0% |
| Defect | 0 | 0 | 0% |
| Debt | 0 | 0 | 0% |

Sprint 6 was entirely validation Feature work advancing M4 and M5.

### 3.4 Flow Load (WIP Snapshot)

```
Current WIP:   0 stories (sprint complete)
WIP Limit:     in_progress: 2 / review: 3
WIP Status:    OK — no violations recorded
```

### 3.5 Sprint Burndown

Sprint start: 2026-03-20 | Sprint end: 2026-04-03 | Total days: 14
BAC: 26 pts

| Day | Date | Planned Remaining | Actual Remaining | Variance |
|-----|------|-------------------|-----------------|---------|
| D0 | 2026-03-20 | 26.0 | 26 | 0 |
| D1 | 2026-03-21 | 24.1 | 8 | **−16.1** |
| D2 | 2026-03-22 | 22.3 | 8 | −14.3 |
| D3 | 2026-03-23 | 20.4 | **0** | **−20.4** |

```
Points
│
26├────●                           (D0: plan=26, actual=26)
   │     ╲
24├──────●╲                        (D1: plan=24, actual=8 ← COMPLETED 18pts)
   │         ╲──────────────
22├────────────●──────────────     (D2: plan=22, actual=8)
   │
20├──────────────────●             (D3: plan=20, actual=0 ← SPRINT DONE)
   │
 0└──────────────────────────
    D0  D1  D2  D3  D4 ... D14

─── Planned    ●── Actual
```

Sprint completed on Day 3 of 14. All 6 EPIC-6 stories (plus 5-3-1) delivered in an aggressive 3-day run.

### 3.6 Flow Predictability

```
Planned Points:    26
Delivered Points:  26
Predictability:    100% (HIGH)
```

### 3.7 Gate Failure Rate

| Step | Attempts | Passed 1st Try | Failed | Failure Rate | Retried → Passed |
|------|----------|---------------|--------|-------------|-----------------|
| create-story | 8 | 8 | 0 | 0% | — |
| validate-story | 8 | 8 | 0 | 0% | — |
| atdd | 8 | 5 | 3 | **37.5%** | 3/3 ✅ |
| dev-story | 8 | 7 | 1* | 12.5% | regressed 1 |
| completeness-gate | 9† | 9 | 0 | 0% | — |
| code-review | 8 | 7 | 1 | 12.5% | 1/1 ✅ |
| code-review-qg | 9† | 9 | 0 | 0% | — |
| code-review-analysis | 8 | 5 | 3 | **37.5%** | 2/2 ✅ (1 regressed) |
| code-review-finalize | 8 | 6 | 2‡ | 25%‡ | 1 regressed, 1 API error |
| ac-validation | 8 | 8 | 0 | 0% | — |
| ui-validation | 8 | 8 | 0 | 0% | — |

\* 6-2-1 regressed from code-review-analysis back to dev-story (not a direct failure)
† includes regression re-runs (6-2-1 ran completeness-gate + code-review-qg twice)
‡ 6-3-1: 1 failure due to API_ERROR (infrastructure, not logic)

**Pipeline Bottlenecks (Theory of Constraints):**
- **By failure rate:** `atdd` and `code-review-analysis` tied at 37.5%
- **By avg duration:** `dev-story` (24.6 min), `code-review-qg` (16.8 min)
- **Constraint:** `atdd` — highest failure rate AND second-highest duration. Improving atdd reliability will reduce regressions and regress-loops most.

### 3.8 Self-Healing Effectiveness

```
Total retries:              7
Retry successes:            7/7 = 100% (excluding API infrastructure errors)
Total regressions:          2
Regression outcomes:
  - 6-2-1 code-review-analysis → dev-story: SUCCESS ✅
  - 6-3-1 code-review-finalize → dev-story: FAILED (API_ERROR) ⚠️ (infrastructure, not logic)
Overall recovery rate:      7/7 logic failures recovered = 100%
Infrastructure failures:    3 (all 6-3-1, API_ERROR; story completed via manual finalization)
```

Self-healing is highly effective for logic failures. API rate-limiting/network errors require external mitigation.

---

## Kanban Metrics — Cycle Time Analysis (Step 2)

### 2.1 Cycle Time Per Story (pipeline active time)

| Story | Points | Status | Cycle Time | Retries | Regressions | Notes |
|-------|--------|--------|------------|---------|-------------|-------|
| 6-2-1-combat-system-validation | 3 | done | 228.6 min | 1 | 1 | Longest: regression loop |
| 6-1-2-world-navigation-validation | 3 | done | 123.8 min | 2 | 0 | atdd + code-review retries |
| 5-3-1-audio-format-validation | 3 | done | 109.8 min | 0 | 0 | Clean run |
| 6-4-1-ui-windows-validation | 5 | done | 108.0 min | 0 | 0 | Clean run (5pt story) |
| 6-3-2-advanced-systems-validation | 3 | done | 88.3 min | 0 | 0 | Clean run |
| 6-2-2-inventory-trading-validation | 3 | done | 98.0 min | 2 | 0 | atdd + code-review-analysis retries |
| 6-3-1-social-systems-validation | 3 | done | ~90.2 min | 1 | 1† | API errors stopped pipeline |
| 6-1-1-auth-character-validation | 3 | done | ~69.3 min | 1 | 0 | Interrupted 1st run; fast 2nd |

† 6-3-1 marked done via manual finalization after API errors exhausted retries.

### 2.2 Cycle Time Distribution

```
Cycle Time Distribution (pipeline active time)
  Min:    69.3 min  (6-1-1)
  P25:    89.3 min
  Median: 99.0 min
  P85:    162.2 min
  P95:    216.5 min
  Max:    228.6 min (6-2-1)
```

### 2.3 Gate Pass/Fail Record

| Story | atdd | dev-story | completeness | code-review | code-review-qg | cr-analysis | cr-finalize | Clean? |
|-------|------|-----------|-------------|-------------|---------------|-------------|-------------|--------|
| 5-3-1 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Yes |
| 6-1-1 | INT* | ✅ | ✅ | ✅ | ✅ | RETRY | ✅ | No |
| 6-1-2 | RETRY | ✅ | ✅ | RETRY | ✅ | ✅ | ✅ | No |
| 6-2-1 | RETRY | REGRESS | ✅×2 | ✅×2 | ✅×2 | REGRESS | ✅ | No |
| 6-2-2 | RETRY | ✅ | ✅ | ✅ | ✅ | RETRY | ✅ | No |
| 6-3-1 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | API_ERR | No |
| 6-3-2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Yes |
| 6-4-1 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Yes |

\* INT = interrupted (batch restart, not a logic failure)
Clean stories (no failures): 5-3-1, 6-3-2, 6-4-1 (3/8 = 37.5%)

### 2.4 Aging WIP

No aging WIP — all stories completed. Sprint is done.

---

## Flow Efficiency (Step 4)

### 4.1 Per-Story Flow Efficiency (pipeline active time / wall clock for that pipeline run)

| Story | Active Time | Wall Clock | Wait Time | Flow Efficiency |
|-------|------------|------------|-----------|-----------------|
| 5-3-1 | 6,577s | 6,588s | 11s | 99.8% |
| 6-1-1 | 4,158s | 5,086s* | 928s | 81.8% |
| 6-1-2 | 7,425s | 7,425s | 0s | 100% |
| 6-2-1 | 13,718s | 13,719s | 1s | 100% |
| 6-2-2 | 5,883s | 5,883s | 0s | 100% |
| 6-3-1 | ~5,412s | ~5,412s | 0s | ~100% |
| 6-3-2 | 5,299s | 5,300s | 1s | ~100% |
| 6-4-1 | 6,480s | 6,480s | 0s | 100% |

\* includes interrupted first run wall clock time

**Sprint Average Pipeline Flow Efficiency: ~97%**

The paw pipeline is nearly 100% active once a story begins executing. Virtually all elapsed time is productive work — no human-wait-time bottleneck.

### 4.2 Sprint-Level Flow Efficiency (sprint commitment to done)

**~19% (Estimated)** — This measures sprint-start-to-completion, including dependency scheduling delays.

- EPIC-6 stories depended on each other sequentially (6-1-1→6-1-2→6-2-1→6-3-2 chain), so later stories waited 1-2 days for dependencies to clear.
- This is expected for dependency-chained Feature stories. The sequential dependency model trades scheduling throughput for correct execution order.

### 4.3 Wait Time Analysis

| Wait Point | Avg Wait | Context |
|------------|---------|---------|
| Step-to-step handoff | ~1s | Immediate, negligible |
| Between story runs (batch) | ~2s | Negligible |
| Dependency scheduling delay | 24-48h | 6-3-2, 6-4-1 waited on critical path |
| API_ERROR retry interval | ~30s | 3 events for 6-3-1 |

---

## Schedule Performance (EVM) (Step 5)

```
BAC (Budget at Completion):   26 pts
Days Elapsed:                 3
Total Sprint Days:            14
PV (Planned Value):           26 × (3/14) = 5.57 pts
EV (Earned Value):            26 pts (all stories done)

SPI = EV / PV = 26 / 5.57 = 4.67 ← SIGNIFICANTLY AHEAD OF SCHEDULE
SV  = EV - PV = 26 - 5.57 = +20.43 pts ahead
```

**Schedule Status: CRITICALLY AHEAD** (SPI > 1.05 threshold)

The sprint was completed in 3 of 14 planned days (21% of planned duration). This reflects the continuous paw automation model where stories are processed sequentially without typical human scheduling delays.

### 5.4 S-Curve Data

| Day | PV (Planned) | EV (Earned) | SV |
|-----|-------------|-------------|-----|
| D0 | 0 | 0 | 0 |
| D1 | 1.86 | 18 | +16.1 |
| D2 | 3.71 | 18 | +14.3 |
| D3 | 5.57 | 26 | **+20.4** |

---

## Pipeline Analytics (Step 8)

### 8.1 Step Duration Analysis (Sprint 6 averages, including retry/regression runs)

| Step | Avg Duration | Min | Max | % of Total |
|------|-------------|-----|-----|-----------|
| create-story | 344s (5.7m) | 224s | 446s | 4.8% |
| validate-story | 150s (2.5m) | 95s | 349s | 2.1% |
| atdd | 1,281s (21.4m) | 693s | 2,039s | 17.9% |
| design-screen | 0s (skipped) | — | — | 0% |
| dev-story | 1,474s (24.6m) | 762s | 4,458s | 20.6% |
| completeness-gate | 373s (6.2m) | 97s | 1,015s | 5.2% |
| code-review | 780s (13.0m) | 492s | 1,433s | 10.9% |
| code-review-qg | 1,005s (16.8m) | 551s | 2,117s | 14.0% |
| code-review-analysis | 693s (11.5m) | 145s | 1,686s | 9.7% |
| ac-validation | 0s (skipped) | — | — | 0% |
| ui-validation | 0s (skipped) | — | — | 0% |
| code-review-finalize | 1,052s (17.5m) | 355s | 1,638s | 14.7% |

**Total avg per story: ~7,152s (119.2 min, 1.99 hours)**

### 8.2 Bottleneck (Theory of Constraints)

```
PIPELINE BOTTLENECK: atdd

  Avg Duration:   21.4 min (including retry runs)
  Failure Rate:   37.5% (3/8 stories failed first attempt)
  Impact:         atdd failures extend story cycle time by avg 21 min (retry),
                  and failed atdd in late retry can trigger regressions to dev-story.

  Secondary:  code-review-analysis (37.5% failure rate, 11.5 min avg)
              dev-story (24.6 min longest step, 1 regression trigger)

  Recommendation: Improve atdd step reliability — focusing on ATDD spec clarity
                  and test file quality will reduce retries most effectively.
                  code-review-analysis failures are often context-window related
                  (fix: increase --output-tokens limit or split analysis).
```

### 8.3 Value Stream Map

| Step | Avg Active | Avg Wait After | Total |
|------|------------|---------------|-------|
| create-story | 344s | 1s | 345s |
| validate-story | 150s | 1s | 151s |
| atdd | 1,281s | 1s | 1,282s |
| dev-story | 1,474s | 1s | 1,475s |
| completeness-gate | 373s | 1s | 374s |
| code-review | 780s | 1s | 781s |
| code-review-qg | 1,005s | 1s | 1,006s |
| code-review-analysis | 693s | 1s | 694s |
| code-review-finalize | 1,052s | — | 1,052s |

```
Total Active Time:    7,152s (119.2 min)
Total Wait Time:      ~9s (step handoffs only)
Value-Add Ratio:      99.9%
```

Pipeline has virtually zero structural waste — all time is active computation.

### 8.4 Self-Healing Pattern Analysis

| Pattern | Count | Success Rate |
|---------|-------|-------------|
| Single retry sufficient | 6 | 100% |
| Regression to dev-story | 2 | 50% (1 success, 1 API_ERROR) |
| Multiple regressions needed | 0 | — |
| Unrecoverable (pipeline stopped) | 1 (6-3-1) | 0% (API_ERROR infra) |

Most common failure → recovery pattern:
```
atdd → retry-atdd: 3 occurrences (100% success)
code-review-analysis → retry-code-review-analysis: 2 occurrences (100% success)
code-review-analysis → regress-dev-story: 1 occurrence (success via regression)
code-review-finalize → regress-dev-story: 1 occurrence (failed due to API_ERROR)
```

---

## Token Usage & Cost Analytics (Step 8.5)

Token data is available from event logs. Selected step totals (from full event log reads):

### 8.5.2 Per-Step Token Highlights (representative data)

| Step | Avg Input | Avg Output | Note |
|------|-----------|------------|------|
| completeness-gate | ~10,000–25,000 | 6,000–11,000 | Highest non-cached input |
| dev-story | 600–41,000 | 10,000–35,000 | Highest variability |
| code-review-finalize | 200–15,000 | 9,000–28,000 | Highest output avg |
| code-review-analysis | 200–56,000 | 8,000–20,000 | High on retries |
| code-review-qg | 60–10,000 | 2,500–3,200 | Consistent |
| code-review | 70–17,000 | 9,000–16,000 | Consistent |
| create-story | 85–44,000 | 6,600–9,900 | Varies by story complexity |
| atdd | 800–46,000 | 1,700–52,000 | Wide range |
| validate-story | 60–19,000 | 4,500–7,900 | Consistent |

**Cache dominance:** Cache creation tokens (~150k–1.1M per step) and cache read tokens (~100k–30M per step) heavily dominate. The pipeline efficiently reuses context via prompt caching, dramatically reducing effective cost vs non-cached.

### 8.5.4 Cost Estimation

> ⚠️ Full token aggregation across all 8 stories would require reading and parsing all step events. The values below are estimated from per-story totals where available.

Based on 5-3-1 (fully read): ~13,900 input tokens, ~35,500 output tokens, ~2.6M cache creation, ~27.5M cache reads.
Extrapolating to 8 stories (range varies widely by story complexity):
- Estimated sprint input tokens: ~80,000–120,000
- Estimated sprint output tokens: ~200,000–350,000
- Estimated sprint cache creation: ~10M–15M tokens
- Estimated sprint cache reads: ~150M–250M tokens

Precise cost requires complete aggregation across all JSONL events. Token counts and cost attribution should be computed from the full sprint-6.events.jsonl archive.

---

## Epic Progress (Step 6)

### 6.1 Per-Epic Summary

| Epic | Stories Done | Stories Remaining | Points Done | Points Remaining | Progress |
|------|-------------|-------------------|-------------|-----------------|---------|
| EPIC-1 | 6/6 | 0 | 18/18 | 0 | ✅ 100% (done) |
| EPIC-2 | 5/5 | 0 | 17/17 | 0 | ✅ 100% (done) |
| EPIC-3 | 7/7 | 0 | 24/24 | 0 | ✅ 100% (done) |
| EPIC-4 | 9/9 | 0 | 48/48 | 0 | ✅ 100% (done) |
| EPIC-5 | 5/5 | 0 | 18/18 | 0 | ✅ 100% (done) |
| EPIC-6 | 7/7 | 0 | 23/23 | 0 | ✅ 100% (done) |
| EPIC-7 | 4/7 | 3* | 14/24 | 10 | ⏳ 58% |

\* 7-3-1 (5pts), 7-3-2 (5pts) are backlog; 7-4-1 done; one story not yet listed in development_status

**Project total:** 43/46 stories done (93.5%) | 162/172 pts (94.2%)

### 6.2 Epic Cycle Times (project to date)

| Epic | First Story Start | Last Story Done | Cycle Time |
|------|-----------------|----------------|-----------|
| EPIC-1 | 2026-03-03 | 2026-03-05 | 2 days |
| EPIC-2 | 2026-03-03 | 2026-03-07 | 4 days |
| EPIC-3 | 2026-03-07 | 2026-03-09 | 2 days |
| EPIC-4 | 2026-03-09 | 2026-03-11 | 2 days |
| EPIC-5 | 2026-03-16 | 2026-03-20 | 4 days |
| EPIC-6 | 2026-03-21 | 2026-03-23 | 2 days |
| EPIC-7 | 2026-03-06 | in progress | 17+ days (partial) |

Average completed epic cycle time: 2.7 days.

### 6.3 Cross-Sprint Velocity Trend

| Sprint | Stories | Points | Velocity | Flow Vel |
|--------|---------|--------|----------|----------|
| Sprint 1 | 6 | 18 | 18 | 6 |
| Sprint 2 | 8 | 28 | 28 | 8 |
| Sprint 3 | 7 | 22 | 22 | 7 |
| Sprint 4 | 9 | 48 | 48 | 9 |
| Sprint 5 | 5 | 20 | 20 | 5 |
| Sprint 6 | 8 | 26 | 26 | 8 |

```
Cross-Sprint Velocity
│
48├─────────────────●               (Sprint 4 outlier — 9 stories, 48 pts)
   │
28├──●                              (Sprint 2)
26├────────────────────────●        (Sprint 6)
22├────────●                        (Sprint 3)
20├─────────────────●               (Sprint 5 — conservative replan)
18├●                                (Sprint 1)
   │
 0└────────────────────────────────
    S1   S2   S3   S4   S5   S6
```

**6-Sprint Average:** 27.0 pts | **3-Sprint Rolling:** 31.3 pts
**CV (excl. Sprint 4 outlier):** 17.5% — STABLE, highly predictable delivery

---

## Monte Carlo Forecast (Step 7)

### 7.2 Throughput History (stories/sprint)
```
[6, 8, 7, 9, 5, 8] — 6 completed sprints
Mean: 7.2 stories/sprint | StdDev: 1.34 | CV: 18.6%
```

### 7.3 Sprint 7 Forecast — EPIC-7 Completion

Remaining work: **2 stories** (7-3-1-macos-stability-session, 7-3-2-linux-stability-session = 10 pts)

```
P50: 1 sprint to complete (7.2 avg > 2 remaining)
P85: 1 sprint
P95: 1 sprint

Forecast: EPIC-7 closes in Sprint 7 with very high confidence.
Estimated Sprint 7 completion: ~2026-04-06 (assuming 2-week sprint, 2026-03-24 start)
```

Note: 7-3-1 and 7-3-2 (stability sessions) require live runtime environments and may not be fully automatable. Manual intervention likely needed — actual throughput may be lower.

### 7.4 Forecast Table

| Target | Remaining | P50 Date | P85 Date | P95 Date |
|--------|-----------|----------|----------|----------|
| EPIC-7 complete | 2 stories | ~2026-04-06 | ~2026-04-06 | ~2026-04-17 |
| Project milestone M1 (stability) | 2 stories | ~2026-04-06 | ~2026-04-06 | ~2026-04-17 |

---

## Story Details (Step 2 — per-story metrics table)

| Story | Points | Cycle (min) | Retries | Regressions | Pipeline Start | Pipeline End | Steps |
|-------|--------|------------|---------|-------------|----------------|-------------|-------|
| 5-3-1 | 3 | 109.8 | 0 | 0 | 2026-03-21T02:37Z | 2026-03-21T04:27Z | 12 |
| 6-1-1 | 3 | 84.7* | 1 | 0 | 2026-03-21T04:27Z | 2026-03-21T05:51Z | 9 |
| 6-1-2 | 3 | 123.8 | 2 | 0 | 2026-03-21T05:51Z | 2026-03-21T07:55Z | 12 |
| 6-2-1 | 3 | 228.6 | 1 | 1 | 2026-03-21T07:55Z | 2026-03-21T11:44Z | 12 |
| 6-2-2 | 3 | 98.0 | 2 | 0 | 2026-03-21T11:44Z | 2026-03-21T13:22Z | 12 |
| 6-3-1 | 3 | ~90.2 | 1 | 1† | 2026-03-21T13:22Z | ~2026-03-21T14:52Z | 12† |
| 6-3-2 | 3 | 88.3 | 0 | 0 | 2026-03-23T14:13Z | 2026-03-23T15:42Z | 12 |
| 6-4-1 | 5 | 108.0 | 0 | 0 | 2026-03-23T15:42Z | 2026-03-23T17:30Z | 12 |

\* 2nd run only (first run interrupted); total wall clock was 84.7 min
† 6-3-1 pipeline stopped due to API errors; story marked done via manual finalization

---

## Data Quality Notes

| Metric | Quality | Notes |
|--------|---------|-------|
| Velocity | HIGH — from sprint-status.yaml | Exact |
| Cycle time | HIGH — from story_completed.duration_seconds | Exact for 7 stories; estimated for 6-3-1 |
| Flow efficiency (pipeline) | HIGH — computed from event timestamps | |
| Flow efficiency (sprint-level) | ESTIMATED | Based on sprint start vs story done dates |
| Gate failure rates | HIGH — from step_failed events | |
| Token counts | PARTIAL — read for 8 stories | Full aggregation requires sprint-6.events.jsonl scan |
| Cost estimates | ESTIMATED — rough extrapolation | Exact requires full JSONL aggregation |
| Epic cycle times | ESTIMATED — sprint dates, not event timestamps | |
| Monte Carlo | MODERATE — 6 data points (adequate) | Stability stories may require human intervention |
| Flow efficiency notation | Two definitions used: | "Pipeline" = story run; "Sprint-level" = sprint start to done |

---

*Report generated by sprint-complete → sprint-metrics workflow*
*Archived event log: `.paw/metrics/sprint-6.events.jsonl`*

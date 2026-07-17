# PCC Executor Runbook

> **As of v6.11.0: skills-only** — workflows/tasks/engine removed; capability is markdown under `_bmad/pcc/skills/`. Operator commands are unchanged: `./paw` and the `/bmad-pcc-*` slash commands work exactly as before. Each command now points Claude at a backing `SKILL.md` instead of an XML workflow/task.

> Cheat sheet for running the project lifecycle. Follow commands in order.
> If something breaks → Troubleshooting section.
> If still stuck → ask the PCC agent (bottom of this doc).

---

## How It Works

Two tools:
- **`./paw`** — terminal CLI, automates the story pipeline end-to-end
- **Claude Code slash commands** — AI-guided workflows for sprint/epic/milestone management

Stories run on autopilot via `./paw`. Everything above story-level uses Claude Code.

---

## How Slash Commands Work

### Discovery Mechanism

Claude Code automatically discovers slash commands from `.claude/commands/` in the project root. Each `.md` file in that directory becomes a slash command named after the filename (minus the `.md` extension).

```
.claude/commands/
├── bmad-pcc-dev-story.md        →  /bmad-pcc-dev-story
├── bmad-pcc-create-story.md     →  /bmad-pcc-create-story
├── bmad-pcc.agent.md            →  /bmad-pcc
└── ...                          →  83 total command files (77 commands + 6 agents)
```

Claude Code scans this directory on session start. No additional registration or configuration is needed — if the file is present, the command is available.

### Installation

Commands are installed automatically by both distribution methods:

| Method | What happens |
|--------|-------------|
| `./package` (zip) | Copies `_bmad/pcc/commands/*.md` → `.claude/commands/` in the archive |
| `./deploy <target>` | Syncs `_bmad/pcc/commands/*.md` → `.claude/commands/` in the target workspace |

The authoritative source for all commands is `_bmad/pcc/commands/`. The `.claude/commands/` directory is a deployment target — never edit files there directly.

### Command File Format

Each command file has YAML frontmatter and step instructions:

```yaml
---
name: 'pcc-dev-story'
description: 'Implement story with quality gates'
context: fork          # fork = runs in isolated context (zero main context tokens)
---

<steps>
1. Load the backing SKILL.md under _bmad/pcc/skills/
2. Follow the skill instructions
3. Produce the expected artifacts
</steps>
```

The `context: fork` directive means the command runs in a forked Claude Code session, keeping the main conversation context clean. (Skills-only as of v6.11.0 — there is no XML workflow engine; each command points at a `SKILL.md`.)

### Naming Convention

Commands follow the pattern `bmad-pcc-{name}.md`:

| File pattern | Slash command | Type |
|-------------|--------------|------|
| `bmad-pcc-{name}.md` | `/bmad-pcc-{name}` | Skill command (78) |
| `bmad-pcc-{name}.agent.md` | `/bmad-pcc-{name}` | Agent command (6) |

### Verifying Installation

```bash
# Count installed commands
ls .claude/commands/bmad-pcc-*.md | wc -l    # Should be 83 (77 commands + 6 agents)

# Check a specific command exists
ls .claude/commands/bmad-pcc-dev-story.md

# In Claude Code, type /bmad-pcc- and autocomplete will show available commands
```

If commands are missing after extraction or deployment, re-run `./deploy` or manually copy:
```bash
cp _bmad/pcc/commands/*.md .claude/commands/
```

---

## First-Time Setup

### Option A: Full Project Init (Recommended)

Sequences all setup workflows in the correct order:

```
/bmad:pcc:workflows:project-init
```

Runs: workspace-configure → guidelines-init → tracker-init → design-system-init → implementation-readiness → bootstrap-reachability. Skips what's already done.

### Option B: Run Setup Workflows Individually

```bash
# 1. Generate workspace infrastructure from .pcc-config.yaml
#    (docker-compose, CI pipelines, ctl script, .gitignore, pre-push hook)
/bmad:pcc:workflows:workspace-configure

# 2. Generate development-standards.md and project-context.md
#    (coding conventions, git workflow, testing standards)
#    Required for ./paw commit to auto-generate messages
/bmad:pcc:workflows:guidelines-init

# 3. Bootstrap Pencil MCP design tokens (if using .pen screens)
/bmad:pcc:workflows:design-system-init
```

Re-run `workspace-configure` after adding/removing components in `.pcc-config.yaml`.

```bash
# 4. Generate project-specific Claude Code skills from config
#    (backend/frontend patterns, testing guidelines, design rules — based on components)
./paw generate-skills
```

Re-run `generate-skills` after changing components or enabling/disabling Pencil.

### Token Optimization Setup (Optional)

Four tools reduce token consumption in both pipeline and interactive sessions. Install the ones you want:

```bash
# 1. RTK — compresses Bash command output (git, tests, linters)
brew install rtk
rtk init -g                # installs hook + patches Claude Code settings

# 2. context-mode — indexes tool results for on-demand search
claude mcp add context-mode -- npx -y context-mode

# 3. Headroom — AST-aware API traffic compression
uv tool install "headroom-ai[all]"
headroom mcp install       # registers MCP tools in Claude Code

# 4. MCP Compressor — reduces MCP tool schema bloat
uv tool install mcp-compressor
```

To enable Headroom proxy for pipeline runs (compresses all Claude API traffic), add to `.pcc-config.yaml`:

```yaml
token_optimization:
  headroom_proxy: true
  headroom_proxy_url: "http://127.0.0.1:8787"
```

Then start the proxy before running the pipeline:

```bash
headroom proxy --port 8787 &
./paw sprint                 # all API traffic compressed automatically
```

See **Performance Tuning → Token Optimization Tools** for full details.

---

## Sprint Lifecycle

### 1. Plan the Sprint

```
/bmad:pcc:workflows:sprint-planning
```

You'll be prompted to select which PRD milestone(s) this sprint advances. Story selection is then scoped to epics contributing to those milestones. Sets story list, points, dates. Sprint status → `planned` in sprint-status.yaml.

---

### 2. Run Stories (Daily Work)

```bash
# Run a single story (auto-detects where it left off)
./paw run {story-key}

# Shorthand — auto-routes by key format
./paw 2-3-4              # single story
./paw 2-3                # all stories in feature 2-3
./paw 2                  # all stories in epic 2
./paw 2-1-2,2-2-4       # comma-separated stories

# Run the sprint lifecycle (auto-activates planned sprints)
./paw sprint              # full pipeline: activate → stories → audit → complete → retro
./paw sprint s3           # or target a specific sprint by name

# Preset flags for common scenarios
./paw 2-3-4 --dev        # skip create/validate/atdd, start at dev-story
./paw 2-3-4 --reimpl     # dev-story with fresh progress file
./paw 2-3-4 --validate   # QG, analysis, AC, UI, finalize only
./paw 2-3-4 --quick      # dev + quality gate only (no adversarial review)
./paw 2-3-4 --fresh      # full restart (all steps)

# Check current state
./paw status

# Inspect active pipeline topology (graph execution model — v3.75.0+)
./paw graph
```

The pipeline runs fully automated: create → ATDD → design → dev → review → done.
Self-healing is built in: 1 retry per step, up to 2 regressions before stopping.

**Graph-native repair routing (v6.4.0+).** A `code-review-qg` failure no longer
always rewinds to the expensive `dev-story` step. Lint-class (advisory) failures —
style / lint / coverage thresholds — route graph-natively to the cheap, scoped
`lint-fix` repair node, which re-runs only the gate. Dispositive failures
(compilation failure or a failed/errored test suite → `POST_VERIFICATION_FAILED`)
keep the hard floor and fall through to the `dev-story` regression. The gate↔repair
cycle has its **own** budget, independent of the regression counter:

| Env var | Default | Bounds |
|---------|---------|--------|
| `PAW_MAX_RETRIES_PER_STEP` | 1 | In-place retries per step |
| `PAW_MAX_REGRESSIONS` | 2 | Cross-step loopbacks to `dev-story` per story |
| `PAW_MAX_TRIAGE_PER_STEP` | 2 | Haiku-driven minimal-fix attempts per step |
| `PAW_MAX_REPAIR_ATTEMPTS` | 2 | `lint-fix` **and** `ac-fix` repair cycles per gate failure |

When `PAW_MAX_REPAIR_ATTEMPTS` is exhausted, the repair edge is suppressed and
`dev-story` fires. A repair hop emits a `step_repair_routed` metrics event
(carrying `error_class` + attempt) instead of `step_failed`, so repairs show up as
routing decisions rather than terminal failures.

**Agent-decided ac-fix repair routing (v6.5.0+).** The same self-repair shape now
covers `ac-validation` failures. Rather than always rewinding to `dev-story`, an
`ac-validation` failure routes graph-natively to a scoped `ac-fix` repair node that
fixes ONLY the failing acceptance criteria and re-runs `ac-validation`. Unlike
`lint-fix` (whose routing reads a deterministic `error_class` hint), `ac-fix`
routing is **agent-decided**: a `haiku_triage` `on_failure` edge — the first
production `haiku_triage` edge — asks a fast-tier agent, over a lean
`failure_summary` of the failing ACs, whether they are scoped-fixable (vs. needing
a full `dev-story` rework). An agent "no", a judge error, or repair-budget
exhaustion all fall through to the `always`→`dev-story` fallback. `ac-fix` shares
the `PAW_MAX_REPAIR_ATTEMPTS` budget with `lint-fix`. Under `--dry-run` the routing
is air-gapped: `haiku_triage` returns `True` without any agent call (mirroring the
`triage_regression` dry-run short-circuit).

**Per-step exit reports (v6.3.7+).** After every step the console prints a
structured exit block: files changed (`git diff --name-only HEAD`), pytest /
ruff / mypy summary scraped from the log, a curated summary excerpt from
`{story_root}/{node-id}.md`, and — on failure only — a Haiku-distilled
diagnosis (`What failed / Likely cause / Suggested next action`). The same
data is written as a JSON sidecar at
`.paw/logs/{story_key}_{step}_{ts}_exit.json` for CI/dashboard consumption.
A single-line **pipeline tape** (`tape: CREATE_STORY ✓ • DEV_STORY ✓ •
COMPLETENESS_GATE ✗`) trails each step and is reset per-story.

**Per-step cost instrumentation (v6.6.0+).** The pipeline tape now also records
per-step token counts and an estimated USD cost; the tape line shows a running
`$` total (rendered only when the running total is nonzero, so cheap/dry runs stay
clean). On terminal exit each run writes a per-run cost aggregate to
`.paw/{story_key}.cost.json` (best-effort — a write failure never crashes the run).
Cost is **observability only**: it is reporting-derived (`cost_model.estimate_cost`,
token→USD by model tier) and **never feeds model selection**. A missing rate logs a
warning and falls back to Sonnet pricing rather than crashing. The numbers are
**accurate for sequential runs**; under `--parallel` the worktree workers share a
single in-process tape, so the aggregate can interleave (see
`docs/findings/finding-2026-05-26-parallel-cost-tape-isolation.md` — a follow-up
story).

**Per-step cache metrics (v6.6.1+).** The same `.paw/{story_key}.cost.json` aggregate
now also carries per-step `cache_read_tokens` / `cache_creation_tokens`, run totals
(`total_cache_read_tokens` / `total_cache_creation_tokens`), and a derived
`cache_read_ratio` — the prompt-cache **hit rate**, `cache_read / (cache_read +
tokens_in)`. Use it to diagnose cross-step prompt-cache effectiveness (a low ratio
means steps are re-paying cold-start prompt cost). Cache metrics are reporting-only
and never affect execution.

---

### 3. Quality Checks (Between Stories)

```bash
# Deterministic quality gate — no Claude, fast
./paw check              # all components
./paw check --backend    # backend only
./paw check --frontend   # frontend only
./paw check --component X  # specific component
./paw check --full       # include extended checks (e2e, lighthouse, a11y)
./paw check --skip-submodules  # skip git submodule components
./paw check --dry-run    # show resolved commands without running

# Quality gate + Claude auto-fix (3-phase: pre-check → format → Claude fix)
./paw fix                # all components
./paw fix --backend      # backend only
./paw fix --frontend     # frontend only
./paw fix --component X  # specific component
./paw fix --fresh        # clear progress, start fresh
```

`check` mirrors CI locally. `fix` goes further — if checks fail, it invokes Claude to diagnose and fix, then re-verifies.

The pre-push hook uses `--skip-submodules` automatically — submodule components get their own hooks installed inside their git directory.

---

### 3.5. Retrofit: Audit Shipped Stories Against the Current Graph (v4.3.6+)

`paw retrofit` re-validates the file lists of *already-shipped* stories against today's knowledge graph. Use it when you suspect a refactor orphaned some files, or to quantify structural tech debt accumulated since a sprint closed.

```bash
# Re-validate a single story
./paw retrofit 5-4-1-story-retrofit-validator

# Batch: all stories in a sprint
./paw retrofit --sprint sprint-5

# Batch: every story with a file list
./paw retrofit --all

# Add read-only fix recommendations (does NOT modify code)
./paw retrofit --all --fix

# Machine-readable output
./paw retrofit --all --json --output retrofit-report.json
```

Each file is classified `CONNECTED` (cross-community inbound edge — well-integrated), `PARTIAL` (inbound only from same community — weakly integrated), or `ORPHAN` (no inbound edges or absent from graph — dead code / isolation risk). Reports include an A–F quality grade with coupling, cohesion, complexity, and maintainability scores.

Exit codes: `0` = all stories pass, `1` = orphans detected, `2` = missing graph / usage error.

**Story path resolution (v6.1.12+):** `retrofit` and `validate-story` automatically search both `docs/stories/` and BMAD's `implementation_artifacts/stories/` directory (configured in `_bmad/bmm/config.yaml`). No manual path configuration is needed — the workspace setup is sufficient.

**Prerequisite:** Run `graphify` first so `graph.json` exists at the project root.

---

### 4. Mid-Sprint: Scope Changes

```
/bmad:pcc:workflows:sprint-replan
```

Calculates rolling velocity, proposes story additions/removals, requires your confirmation before applying.

---

### 4.5. Mid-Sprint: Convert a Discovery into a Story

Use when a session (story implementation, code review, or audit) surfaces a finding that needs to become a sprint story:

```
/bmad:pcc:workflows:scope-discover
```

**Purpose:** Convert a discovery artifact (RCA, finding, or gap analysis produced during a session) into a sprint-ready story with epic placement and sprint injection. Bridges the gap between "we found something" and "it's in the sprint."

**When to use:**
- After `pcc-scope-handling` or `pcc-document-first` skills surface a finding needing a story
- When a story session produces a discovery document (RCA, build-rca.md, scope-discovery.md)
- Known fix/gap with enough definition to implement immediately — not a spike
- Out-of-scope work found during code review or audit needs sprint placement

**Key inputs:**
- `source_artifact` — path to discovery document (optional — agent prompts if missing)
- `source_story` — story key where discovery was made (optional — used for back-linking)
- `urgency` — `this-sprint` | `next-sprint` | `backlog` (default: `this-sprint`)

**Confirmation gates:** Classification (Step 3), epic placement (Step 5), sprint injection (Step 7)

---

### 5. Mid-Sprint: Things Are Broken

```bash
# See what's wrong across all sprint stories
/bmad:pcc:workflows:sprint-health-audit

# Quick auto-fix loop (audit → batch resume → re-audit)
./paw remediate --quick

# Full AI-guided remediation with detailed strategy
/bmad:pcc:workflows:sprint-remediate

# Scope remediation to an epic
./paw remediate --epic 3

# Preview plan without executing
./paw remediate --dry-run
```

Repeat health audit after each remediation until the sprint shows HEALTHY or AT_RISK (no CRITICALs).

---

### 5.5. Reconcile Sprint Story Keys (v6.2.0+, Story 6.3.3)

When `./paw status` shows sprint entries as `unknown`, `ORPHAN`, `RESOLVED`, or `AMBIGUOUS`, the sprint's `stories:` list contains keys that don't match the `development_status` table. This is common in long-lived workspaces where early sprints used short keys (`5-2-3`) and later ones used slug-form (`5-2-3-dependency-graph`).

```bash
# Diagnose the active sprint (read-only)
./paw sprint doctor

# Diagnose a specific sprint
./paw sprint doctor --sprint sprint-6

# Diagnose every sprint
./paw sprint doctor --all

# Auto-fix RESOLVED short keys (rewrites sprint-status.yaml with a timestamped backup)
./paw sprint doctor --fix

# Preview the fix without writing
./paw sprint doctor --fix --dry-run
```

**Four resolution kinds:**

| Kind | Meaning | Auto-fixable? |
|------|---------|---------------|
| `EXACT` | Key is present verbatim in `development_status`. | No action needed. |
| `RESOLVED` | Exactly one slug-form key has this short key as its prefix. | Yes — `--fix` rewrites the short key to its slug. |
| `AMBIGUOUS` | Two or more slug-form keys share this prefix. | **No** — operator must disambiguate manually. The doctor lists candidates. |
| `ORPHAN` | No slug-form key matches. | **No** — the short key has no twin. Either find the real slug via `grep -r '<key>' docs/stories/` or remove the stale line. |

**Safety:**

- Every `--fix` write is preceded by a timestamped backup at `<file>.bak-<UTC-ISO-timestamp>`.
- The rewrite uses scoped text-line surgery — comments and unrelated YAML are preserved byte-for-byte.
- AMBIGUOUS and ORPHAN entries are NEVER auto-modified (loud-failure philosophy).
- Atomic semantics: temp file in the same directory + `os.replace()` over the original.

**Exit codes:**

| Code | Meaning |
|------|---------|
| 0 | All EXACT, or `--fix` applied successfully with no remaining issues. |
| 1 | Non-EXACT entries found (diagnose-only path) — operator should review or run `--fix`. |
| 2 | Filesystem or parse error. |

This command runs the same in every workspace (single-repo or BMAD-output-default). It reads `sprint-status.yaml` via the BMAD-aware path resolution introduced in Story 6.3.1.

---

### 6. Close the Sprint

Run these in order:

```bash
# Step 1 — audit (must be HEALTHY or AT_RISK with no CRITICALs)
/bmad:pcc:workflows:sprint-health-audit

# Step 2 — if CRITICALs exist, fix them first (see mid-sprint section above)

# Step 3 — generate metrics and mark sprint complete
/bmad:pcc:workflows:sprint-complete

# Step 4 — capture lessons for next sprint
/bmad:pcc:workflows:sprint-retrospective
```

Then loop back to step 1 for the next sprint.

---

## Epic Lifecycle

### Before the First Sprint of a New Epic

```
/bmad:pcc:workflows:epic-start
```

Verifies the previous epic is fully done and checks catalog state. Required before any sprint-planning for a new epic.

---

### When All Epic Stories Are Done

```
/bmad:pcc:workflows:epic-validation
```

Must PASS before you can start the next epic or trigger milestone validation.
If FAIL → check the report, fix, re-run.

---

### After Epic Validation Passes

```
/bmad:pcc:workflows:epic-retrospective
```

Captures cross-story lessons to persistent memory. Required before moving to the next epic.

---

## Pencil UI Design

Pencil `.pen` screens are the authoritative design specification. Design always precedes implementation. See `_bmad/pcc/docs/guides/pencil-design-first.md` for the full end-to-end guide.

### One-Time Setup (before first screen)

```
/bmad:pcc:workflows:design-system-init
```

Establishes design tokens, component catalog, and framework mapping in the `.pen` file. Must run before `design-screen` on any project.

---

### Recover Missing or Stale Screens

Use when screens were never designed, are poor quality, or artifacts are missing:

```
/bmad:pcc:workflows:pen-ui-recovery
```

Runs three passes:
- **Pass 1** (autonomous, ~2 min): classifies every frontend story in the sprint as NEEDS_DESIGN / NEEDS_EXPORT / NEEDS_REVIEW / NEEDS_VALIDATION / UNIMPLEMENTED
- **Pass 2** (interactive, Pencil editor must be open): designs missing screens, exports PNGs, quality-gates each screen with APPROVED / NEEDS_REVISION / REDESIGN
- **Pass 3** (autonomous): validates implementations against `requirements.md` (functional gate) and design PNGs (visual diff)

Targeted options:

```bash
# Audit only (no MCP needed)
pass: "1"

# One epic
epic_filter: "3"

# One story
story_filter: "2-3-4-my-story"
```

After recovery, commit all new artifacts:

```bash
git add docs/spec-screenshots/ docs/stories/*/requirements.md \
        docs/implementation-artifacts/epic-*-view-inventory.md \
        docs/implementation-artifacts/*-pen-sidecar.json
```

---

## Milestone Lifecycle

Milestones are defined in the PRD (`## Milestones` section) and span multiple epics/sprints. `sprint-planning` automatically bootstraps a `pending` stub in `milestone-status.yaml` when a sprint references a milestone.

### 1. Kick Off Milestone Tracking

```
/bmad:pcc:workflows:milestone-plan
```

Run when you're ready to actively track a milestone. Reads the PRD definition, assesses contributing epic status, sequences epics, and transitions the milestone from `pending` → `active`. Produces a planning brief.

### 2. Validate the Milestone

Run only when **all contributing epics** (as defined in the PRD) have passed `epic-validation`:

```
/bmad:pcc:workflows:milestone-validation
```

Validates cross-epic API contracts, events, navigation, and end-to-end journeys.
Sets status to `validating` in `docs/implementation-artifacts/milestone-status.yaml`.

If FAIL → remediate the failing epics → re-run `epic-validation` on them → retry `milestone-validation`.

### 3. Go/No-Go Decision

Run after `milestone-validation` passes (status = `validating`):

```
/bmad:pcc:workflows:milestone-review
```

Presents validation findings and prompts for a human decision:
- **GO** → status becomes `passed`
- **NO-GO** → status becomes `failed` (remediate and re-validate)
- **CONDITIONAL** → status becomes `conditional` (passes with conditions to resolve)

---

## Strategic Planning

### Quarterly Business Review

```
/bmad:pcc:workflows:qbr
```

Aggregates sprint/epic/milestone metrics over a period, surfaces systemic themes (GREEN/YELLOW/RED health), and produces a decision-gate report with priority adjustments.

### Backlog Refinement

```
/bmad:pcc:workflows:backlog-refinement
```

Assesses story readiness (READY/PARTIALLY_READY/NOT_READY/BLOCKED), classifies backlog items, and recommends ordering for upcoming sprint planning. Advisory only.

### Epic Replan

```
/bmad:pcc:workflows:epic-replan
```

Re-sequence epics within a milestone, remap epic-milestone assignments, and move stories between epics. Requires confirmation gate. Produces before/after traceability.

---

## Ideation (Parking Lot)

Capture ideas for future work that aren't ready to become stories yet.

```bash
# Start the ideation agent (conversational)
/bmad:pcc:agents:pcc-ideation

# Or invoke workflows directly
/bmad:pcc:workflows:idea-capture      # describe an idea, get it scored
/bmad:pcc:workflows:idea-evaluate     # review/promote/decline captured ideas
```

Ideas go to `{output_folder}/ideas/registry.md`. The agent asks clarifying questions, maps ideas against the specification-index, and scores them A/B/C/D. Run `idea-evaluate` before sprint planning to surface promotable ideas.

---

## Retroactive Closure (Backfill)

If a sprint or epic ended without running the proper closing workflows, use backfill instead of manual YAML edits. Backfill **validates first** before writing any status changes.

```bash
# Close a past sprint (validates all stories done, writes RETROACTIVE metrics)
./paw backfill sprint {sprint-key}

# Dry-run: see the plan without making changes
./paw backfill sprint {sprint-key} --dry-run

# Close a past epic (validates stories done, writes RETROACTIVE validation report)
./paw backfill epic {epic-num}

# Re-run milestone validation (e.g., after fixing contributing epics)
./paw backfill milestone {milestone-id}
```

Or via Claude Code workflows directly:
```
/bmad:pcc:workflows:sprint-backfill
/bmad:pcc:workflows:epic-backfill
```

**Key constraint:** All sprint/epic stories must have `status: done` before backfill proceeds.
Backfill reports are flagged RETROACTIVE — Bruno tests are not re-executed for epic backfill.

---

## Daily Dev Commands

### Commits

```bash
./paw commit             # auto-generate message from diff using project git conventions
./paw commit -m "msg"    # explicit message
```

Auto-generation reads `development-standards.md` for your commit format (conventional commits, etc.). If that file is missing, run `guidelines-init`.

### Code Review

```bash
./paw review 2-3-4       # code review pipeline (auto-resumes from last gate)
./paw review 2-3-4 --fresh  # fresh code review
```

### Acceptance Criteria

```bash
./paw ac 2-2-6           # run AC validation tests for story
./paw ac 2-2-6 --ui      # interactive Playwright UI mode
./paw ac 2-2-6 --gen     # generate AC test stubs first, then run
```

---

## Step Summaries (v4.2.0)

Every pipeline step writes a summary to `{story_root}/{node-id}.md` after execution. These summaries form an incremental knowledge chain — each step records what it achieved, what it found, and what gaps remain.

### Story directory layout after a full pipeline run

```
docs/stories/7-9-7-my-story/
  story.md                  # created by create-story (primary artifact)
  validated-story.md        # created by validate-story sub-graph
  atdd.md                   # created by atdd step (primary artifact)
  requirements.md           # created by design-screen
  progress.md               # created by dev-story (primary artifact)
  review.md                 # created by code-review-quality-gate (primary artifact)
  completeness-gate.md      # step summary (written by orchestration)
  code-review-qg.md         # step summary
  code-review-analysis.md   # step summary
  ac-validation.md          # step summary
  ui-validation.md          # step summary
  code-review-finalize.md   # step summary
  session-summary.md        # Haiku-consolidated session summary
```

### How it works

- **Primary artifacts** (story.md, review.md, atdd.md, progress.md) are written by the step itself — the orchestration skips these
- **Step summaries** are written by `_write_step_summary` in `orchestration.py` — extracts Claude's execution output from the log file plus structured metadata (verdict, duration, tokens, turns)
- **Downstream injection**: before each Claude session, `_inject_prior_step_summaries` loads all step summaries into the prompt — Claude sees what prior steps found without re-doing the work
- **Attempt accumulation**: when a step runs multiple times (regression cycles), each attempt appends with a `---` separator and timestamp
- **Haiku consolidation**: when accumulated summary exceeds 12K chars, Haiku distills prior attempts into a ~2K digest preserving key findings and changes between attempts. Falls back to truncation if Haiku is unavailable
- **Graph gating**: `file_exists` edge conditions check for these files to advance the pipeline — the summary IS the gating artifact
- **Console logging**: after each step, a condensed summary (verdict, duration, turns, first 5 lines of output) is printed to the console so operators can track progress in real-time without opening files

### Inspecting summaries

```bash
# View what a step found
cat docs/stories/7-9-7/completeness-gate.md

# See all step summaries for a story
ls docs/stories/7-9-7/*.md
```

---

## Status & Diagnostics

```bash
./paw status             # milestone + epic + sprint status + memory stats
./paw metrics            # full metrics dashboard
./paw metrics --level=operational  # just story statuses

./paw detect 2-3-4       # show detected progress for a story
./paw phase 2-3-4        # show which instruction shard would load
./paw steps              # list pipeline steps

./paw memory             # claude-mem worker status
./paw memory list        # list project memories
./paw memory list 2-3-4  # list memories for a story

/bmad:pcc:workflows:sprint-progress       # detailed sprint progress report
/bmad:pcc:workflows:sprint-health-audit   # full gap analysis
/bmad:pcc:workflows:sprint-metrics        # velocity and SAFe metrics
```

---

## Maintenance & Utilities

```bash
./paw cleanup            # show duplicate/dangling artifacts
./paw cleanup all        # clean up all

./paw consolidate --all  # consolidate all logs (Haiku summary)
./paw consolidate 2-3-4  # consolidate logs for one story

./paw sync-atdd 2-3-4    # mark ATDD checklist items complete

./paw spec-index         # generate/regenerate specification-index.yaml
./paw spec-index --check # regenerate only if stale or missing
./paw corpus stats       # specification index statistics
./paw corpus context X   # get story context from corpus
./paw corpus validate X  # validate dependencies in corpus
```

---

## Performance Tuning

Each pipeline step has a semantic tier and max-turn budget. The active adapter resolves a tier to its provider-specific model and reasoning policy.

### Built-in Step Defaults

| Step | Tier | Max Turns |
|------|-------|-----------|--------|
| CREATE_STORY | deep | 50 |
| VALIDATE_STORY | fast | 30 |
| ATDD | balanced | 50 |
| DESIGN_SCREEN | balanced | 80 |
| DEV_STORY | deep | 150 |
| COMPLETENESS_GATE | fast | 60 |
| CODE_REVIEW_QG | deep | 100 |
| CODE_REVIEW_ANALYSIS | deep | 50 |
| AC_VALIDATION | balanced | 80 |
| UI_VALIDATION | balanced | 60 |
| CODE_REVIEW_FINALIZE | deep | 80 |

### Overriding Step Defaults

Add a `step_overrides:` block to `_bmad/pcc/config.yaml`. Only the fields you specify are overridden; the rest keep their defaults.

```yaml
# _bmad/pcc/config.yaml
step_overrides:
  # Use the deep tier for code review analysis
  code-review-analysis:
    tier: deep

  # Reduce dev-story turns to save cost
  dev-story:
    max_turns: 100
```

**Available values:**
- `tier`: `fast`, `balanced`, `deep`
- `max_turns`: any positive integer

Step names use the kebab-case form (e.g., `dev-story`, `code-review-qg`, `ac-validation`).

### Global Tier Override

Use `--tier` to override all agent-driven work for one command, for example `./paw run {key} --tier deep`. Provider adapters select their concrete models and reasoning policies; workflow sessions direct-load their canonical `SKILL.md` files.

> **v7.0.0 — DAG runs skills (micro-node decomposition removed):** as of v7.0.0 the sub-graph layer is **deleted** — `sub_graph.py`, `executors.py`, `graphs/sub/`, `graphs/prompts/`, `skills/steps/`, and `load_step_skill` are gone. Each top-level graph node (`backend-only.yaml`, `frontend-only.yaml`, `full-stack.yaml`) now carries `skill:` (path to a SKILL.md), `budget:`, and `on_pass:`/`on_fail:` edges. `story_loop.run_story` dispatches via `run_skill_node` — **one whole SKILL.md run by one agent per node**; agent verdict at each edge via `decide_boundary`. Deterministic test/lint/file signals are HINTS injected into the skill prompt. Operator commands and produced artifacts are unchanged. See `docs/superpowers/notes/2026-06-26-dag-runs-skills-behavioral-evidence.md`.
>
> _(The v6.8.0 sub-graph dispatch note above is superseded — `SubGraphStage`, `stage-chains.yaml`, and `graphs/sub/` no longer exist.)_

### Token Optimization Tools

#### Headless invocation profiles

Automated headless agent runs now compile scoped MCP configs under `.paw/mcp/` at runtime instead of inheriting every configured MCP server.

- `headless_minimal` → allowlists configured optional optimizers: `lean-ctx`, `headroom`, `context-mode`
- `headless_design` → minimal optional allowlist + required `pencil`

Missing optional optimizers are omitted from the compiled strict MCP config; they do not block
story execution. Missing required servers fail closed with an actionable configuration error.

The live agent path (`skill_node` / triage invoke flows) also passes `--exclude-dynamic-system-prompt-sections`, improving prompt-cache reuse by keeping machine-specific system-prompt sections out of the reusable prefix.


Four tools reduce token consumption at different layers of the pipeline. All are optional but recommended — they work independently and can be combined.

| Tool | Layer | What it reduces | Savings | Install |
|------|-------|----------------|---------|---------|
| **RTK** | Bash output | git, test, lint, build output | 60-90% | `brew install rtk && rtk init -g` |
| **context-mode** | Tool results | All tool I/O via FTS5 sandbox | 98-99% | `claude mcp add context-mode -- npx -y context-mode` |
| **Headroom** | API requests | Message content (AST-aware) | 73-92% | `uv tool install "headroom-ai[all]" && headroom mcp install` |
| **MCP Compressor** | Tool definitions | MCP server schema bloat | 70-97% | `uv tool install mcp-compressor` (wrap in `.claude.json`) |

#### RTK (Rust Token Killer)

Already installed via `brew install rtk`. Intercepts Bash commands via a `PreToolUse` hook, runs the real command, then filters output (strips ANSI, shows only failures, aggregates by pattern). Zero code changes needed.

```bash
rtk discover       # see missed opportunities and estimated savings
rtk gain            # see actual savings dashboard
rtk gain --graph    # ASCII chart of savings over time
rtk session         # adoption rate
```

**What it covers:** `git status/diff/log/push`, `uv run pytest`, `ruff check`, `mypy`, `pre-commit run`, `./gradlew build`, `npm run lint/test`, `npx playwright test`, `./paw` commands.

**What it doesn't cover:** Claude Code's native tools (`Read`, `Grep`, `Glob`, `Edit`) — these bypass Bash entirely.

**Config:** `~/.config/rtk/config.toml`
```toml
[hooks]
exclude_commands = ["curl", "playwright"]  # skip rewrite for these

[tee]
enabled = true
mode = "failures"   # save full output on failure for re-reading
```

#### context-mode

MCP server that intercepts tool outputs, indexes them into a local FTS5 database, and lets Claude search on-demand instead of accumulating everything in context. Most impactful for multi-turn steps (dev-story, code-review-finalize) where context accumulation causes the doom-loop pattern.

```bash
# Install (one-time)
claude mcp add --scope user context-mode -- npx -y context-mode

# Or install as plugin for slash commands + hooks
# (run inside Claude Code interactive session)
/plugin marketplace add mksglu/context-mode
/plugin install context-mode@context-mode
```

**Verification:** `claude mcp list` should show `context-mode: ✓ Connected`

**Tools provided:** `ctx_execute`, `ctx_batch_execute`, `ctx_index`, `ctx_search`, `ctx_fetch_and_index`

#### Headroom

AST-aware compression layer. When used as MCP tools, provides on-demand compression and retrieval. When used as proxy (`ANTHROPIC_BASE_URL`), compresses all API traffic automatically.

```bash
# Install (one-time)
uv tool install "headroom-ai[all]"
headroom mcp install   # registers MCP tools in Claude Code

# Optional: full proxy mode (compresses ALL API requests)
headroom proxy --port 8787 &
ANTHROPIC_BASE_URL=http://127.0.0.1:8787 claude
```

**MCP tools:** `headroom_compress`, `headroom_retrieve` (get original by hash), `headroom_stats`

**For pipeline use (./paw):** To route pipeline subprocess calls through the proxy, set the env var before running:
```bash
headroom proxy --port 8787 &
ANTHROPIC_BASE_URL=http://127.0.0.1:8787 ./paw 5-2-3
```

#### MCP Compressor (Atlassian)

Wraps existing MCP servers and replaces their full tool schemas with 2 generic tools (`get_tool_schema` + `invoke_tool`). The LLM discovers tools on-demand instead of loading all schemas upfront. Most valuable for servers with many tools (GitHub has 93 tools = ~55K tokens of schema).

```bash
# Install (one-time)
uv tool install mcp-compressor
```

**Wrapping a server** — edit `.claude.json` or `~/.claude.json`:
```json
{
  "mcpServers": {
    "compressed-github": {
      "command": "mcp-compressor",
      "args": [
        "https://api.githubcopilot.com/mcp/",
        "--server-name", "github",
        "-c", "high"
      ]
    }
  }
}
```

Compression levels: `low` (full descriptions), `medium` (first sentence), `high` (names + params only), `max` (tool names only).

---

## Coding agent backend (v6.3.0+)

The Phase B multi-agent migration introduces an `agent:` block in `.pcc-config.yaml` that selects which coding-agent backend the pipeline invokes. `claude` is the default; `codex` is available through the local Codex CLI. `copilot` and `opencode` still raise `NotImplementedError`.

**Default behaviour (no `agent:` block).** Existing `.pcc-config.yaml` files work unchanged — the pipeline runs on Claude exactly as it did before. No migration is required.

**Operator config:**

```yaml
schema_version: 3

agent:
  backend: claude        # claude (default) | codex | copilot | opencode
  claude:
    mode: cli            # cli (subprocess) | sdk
```

`codex` is implemented via `codex exec` and requires a local authenticated Codex CLI (`codex login` and `codex doctor` should pass before running a PCC story).

```yaml
schema_version: 3

agent:
  backend: codex
  models:
    codex:
      fast: {model: gpt-5.6-luna, effort: low}
      balanced: {model: gpt-5.6-terra, effort: medium}
      deep: {model: gpt-5.6-sol, effort: high}
```

PCC uses `codex exec` non-interactively. `.pcc-config.yaml` selects runner models and
reasoning policies; the Codex adapter resolves the semantic tier into its provider-specific
`--model` and `model_reasoning_effort` options, which outrank `.codex/config.toml`. Keep interactive defaults in that file, for example:

```toml
model = "gpt-5.6-terra"
model_reasoning_effort = "medium"
sandbox_mode = "workspace-write"
approval_policy = "on-request"
```

Codex skill nodes run with `workspace-write`; judge calls run read-only. Luna is fast, Terra
balanced, and Sol deep. Operators may partially override any tier. Project Codex config loads
only for trusted projects. See the official [Codex model guide](https://developers.openai.com/codex/models),
[configuration guide](https://learn.chatgpt.com/docs/config-file/config-basic), and
[non-interactive mode guide](https://learn.chatgpt.com/docs/non-interactive-mode).

Codex supports PCC skills, MCP, and Pencil MCP. Project skills are discovered under
`.agents/skills/`; pipeline nodes also direct-load their canonical `SKILL.md` so execution does
not depend on discovery. Codex still does not advertise `CACHE_TELEMETRY` or `WEB_FETCH`.

The Pencil app owns registration of the `pencil` MCP server. PCC does not write the server
command, arguments, URL, or environment. Design nodes mark the existing server as enabled and
required for that invocation, so Codex fails before useful work if Pencil cannot initialize.

Local smoke:

```bash
codex --version
codex login status
codex doctor
codex mcp get pencil  # required only for Pencil design stages
./paw <story-key> --smoke
```

`./paw --smoke` validates graph traversal and capability-gate behavior without invoking a real coding agent. Use `codex doctor` as the local Codex CLI/auth prerequisite check. For Pencil-enabled workspaces, `codex mcp get pencil` must show an enabled app-managed server before a real Codex-backed design stage runs.

Setting `backend: copilot|opencode` today raises `NotImplementedError` referencing Phase D/E so that misconfigurations surface immediately rather than silently falling back to Claude.

**Capability gate.** The v7 story loop checks capabilities before each node dispatch. Graph YAMLs (`_bmad/pcc/graphs/*.yaml`) may declare `required_capabilities:` per node:

| Node | Required capabilities |
|------|----------------------|
| `design-screen` | `pencil-mcp`, `file-edit` |
| `dev-story` | `file-edit`, `shell-exec`, `subprocess-turns` |
| `ui-validation` | `pencil-mcp` |

When a node has no YAML requirements, the loop falls back to the node's `SKILL.md` frontmatter/body and parses `REQUIRES capabilities:` / `PREFERS capabilities:` hints. When a required capability is not advertised by the configured backend, the pipeline emits a structured `capability_skip` warn log and SKIPS the node without invoking the agent — the run does NOT fail. This lets future Codex/Copilot adapters land incrementally without blocking pipelines that touch capabilities they don't support yet.

Skip log shape (warn level, machine-parseable):

```
capability_skip node=ui-validation capability=PENCIL_MCP backend=copilot
message=PENCIL_MCP unavailable on backend=copilot; ui-validation skipped
```

---

## Troubleshooting

| Symptom | Try First | If Still Failing |
|---------|-----------|-----------------|
| Story stuck mid-pipeline | `./paw run {key}` (auto-resumes) | `./paw run {key} --dev` (restart from dev-story) |
| Story failed code review | `./paw review {key}` | `./paw review {key} --fresh` |
| Phantom completions / placeholders | `./paw fix` | `./paw run {key} --reimpl` |
| Multiple stories failing | `./paw remediate --quick` | `/bmad:pcc:workflows:sprint-remediate` |
| Sprint shows CRITICAL gaps | `/bmad:pcc:workflows:sprint-health-audit` → follow report | Manual fixes per gap type |
| `sprint-complete` blocked | Resolve all CRITICALs first | Re-run health audit after fixes |
| `epic-validation` FAIL | Review individual story code-review-finalize outputs | `/bmad:pcc:workflows:sprint-health-audit` |
| `milestone-validation` FAIL | Identify failing epics from report | Fix cross-epic contracts, re-validate epics |
| Past sprint/epic not formally closed | `./paw backfill sprint {key}` or `./paw backfill epic {num}` | Ensure all stories are `done` first |
| Slash commands not available | `ls .claude/commands/bmad-pcc-*.md \| wc -l` | `cp _bmad/pcc/commands/*.md .claude/commands/` then restart session |
| Quality gate fails on push | `./paw check` → `./paw fix` | Check `.pcc-config.yaml` build commands (run `workspace-configure`) |
| `./paw commit` can't generate message | Run `/bmad:pcc:workflows:guidelines-init` | Provide explicit: `./paw commit -m "msg"` |
| Run halts with "Model unavailable (RATE_LIMITED/TRANSPORT_ERROR)" (exit 2) | **Out of model quota / rate-limited** — the runner stopped fast to preserve budget and your committed work; wait for quota to reset | Re-run `./paw {key} --from {step}` when quota is back; completed dev-story tasks were committed per-task so they won't be redone |
| Don't know what to do next | `./paw status` | Ask the PCC agent (below) |

### `./paw` Flags for Common Recovery Scenarios

```bash
./paw run {key} --from=DEV_STORY        # restart from dev step
./paw run {key} --from=CODE_REVIEW_QG   # restart from review
./paw run {key} --fresh                  # full restart (clear state)
./paw run {key} --dry-run               # preview what would run

./paw sprint                            # full sprint lifecycle (auto-activates planned)
./paw sprint s3                         # named sprint lifecycle
./paw cascade                           # check all levels and trigger ready transitions
./paw remediate --quick --dry-run       # preview remediation plan
```

### Pipeline Safety Guards (v4.3.1)

The pipeline has four guards that prevent incomplete work from being marked PASSED:

| Guard | Triggers when | Result |
|-------|--------------|--------|
| **Idle/stall timeout** | No stream activity for 15 min (idle) or no progress for 30 min (stall) | Step marked FAILED — retries/regression apply |
| **Zero-output guard** | Step produces 0 output lines for >60 seconds | Step marked FAILED — catches silent hangs |
| **Done-story skip** | Batch runner encounters a story with `code-review-finalize completed` | Story skipped entirely — no re-processing |
| **Failed-state precedence** | RunState records `status: failed` but artifact says story complete | RunState wins — story resumes at the failed step |

Previously, idle timeouts inherited the process exit code (often 0), causing timed-out steps to be marked PASSED. The failed-state guard prevents a related problem: when a step writes `Status: done` to the story file before its verification fails, the stale artifact would override the RunState and report the story as complete. If a step fails due to these guards, the pipeline's normal retry (1 attempt) and regression (back to dev-story, max 2) mechanisms apply.

### Pipeline Validation & Diagnostics

```bash
# Check deployed version
./paw version

# Clear stale feedback/state for a stuck story (does NOT delete artifacts)
./paw clean {key}
./paw clean {key} --include-summary     # also remove session summary

# Dry-run: validate pipeline flow without model calls (air-gapped)
./paw run {key} --dry-run
./paw run {key} --dry-run --fail-at completeness-gate  # test regression paths

# Smoke test: real Haiku calls with minimal turns (low cost)
./paw run {key} --smoke
./paw run {key} --smoke --from DEV_STORY --to CODE_REVIEW_QG
```

Both modes print an assertion-based test report showing pass/fail per step and per assertion. Use dry-run after deploying paw_runner changes to verify flow logic. Use smoke to verify Claude CLI integration end-to-end.

**Smoke mode safety:** Commits are auto-disabled (`--no-commit`) to prevent test runs from modifying the repo. Smoke also validates post-step processing (quality gate verification, memory saves) that dry-run cannot reach. Use `batch --parallel --smoke` to exercise the inter-story worktree batch path.

### Pipeline Tuning Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `PAW_TRIAGE_TIMEOUT` | `180` | Seconds before the post-failure Haiku triage call is killed. Increase on slow machines or when MCP server startup adds overhead to the decision subprocess. |
| `PAW_RUN_TOKEN_BUDGET` | _unset (disabled)_ | Soft per-run token ceiling (sums input + output + cache tokens across steps). When set and crossed, the runner finishes the current step, relies on the dev-story green checkpoint, and **halts cleanly + resumably** (`./paw <story>` to continue) instead of being killed mid-task by the server-side 5-hour window. Unset = unchanged behavior. |
| `PAW_BATCH_MAX_ITEMS` | `12` | Safety ceiling on how many unchecked ATDD items `detect-next-task` may pull into ONE dev-story RED→GREEN cycle (v6.17.0 aggressive batching). A generous *ceiling*, not a target — the selector picks the largest coherent value slice (a whole AC / coupled ACs) up to this bound. Lower it if batches starve the heavy-node turn budgets; raise it for very large, tightly-coupled ACs. |

```bash
# Example: extend triage timeout for a slow environment
PAW_TRIAGE_TIMEOUT=300 ./paw run {key}

# Example: cap a single run's token spend (halts cleanly + resumable when crossed)
PAW_RUN_TOKEN_BUDGET=8000000 ./paw {key}
```

The triage call runs after a step failure to decide whether to retry, regress, or abort. It uses a dedicated Haiku subprocess that must initialize its MCP session before responding — the default 180 s accounts for that overhead.

**dev-story batching + green checkpoint (v6.17.0).** dev-story no longer runs one cycle per ATDD line. `detect-next-task` (Sonnet) selects an aggressive, value-coherent **batch** of related items (bounded by `PAW_BATCH_MAX_ITEMS`) per cycle, and the moment a batch's tests are GREEN a deterministic shell `checkpoint-green` node commits the code and records the completed items in `.paw/{story}.tasks-done.json` — **before** refactor/lint. A resumed run reads that ledger to skip finished work with zero re-discovery cost. Cache-token cost is now recorded in `.paw/{story}.cost.json` (previously read all-zeros on graph runs), so you can see real burn per run.

**dev-story burn reduction — verdict-skip, already-done fast-path, tier-targeted verify (v6.18.0).**

- **Verdict-skip on shell nodes:** `goal_verification_middleware` and `evaluation_middleware` no longer call a model to judge shell-executor nodes. Shell nodes are deterministic — their exit code is the verdict. This removes ~2 model calls per shell node per dev-story iteration.
- **Already-done fast-path:** When `reconcile-check` declares a batch already implemented, the loop skips the Claude `refactor` + `run-lint` nodes. `checkpoint-green` re-emits `already_done` via `output_key` and routes directly `→ commit-task`.
- **Tier-targeted RED/GREEN verify:** RED and GREEN verify now run the tests the batch actually wrote at the correct tier (unit vs. integration), never mixing tiers. Fixes the convergence-killer where an integration test was never confirmed by the unit-only RED command (causing infinite regression). The code-review quality gate now also runs each non-unit tier's full suite for system-wide sanity.

**Operator: activating tier-targeted verify in a target workspace.** In the build
component's `.pcc-config.yaml` (e.g. `memoria-backend`) add under `testing:`:

```yaml
    testing:
      test_filter_flag: "--tests"
      test_tiers:
        - name: integration
          command: "./gradlew integrationTest --rerun-tasks"
          match: "*IntegrationTest"
        - name: unit
          command: "./gradlew unitTest --rerun-tasks"
          match: "*"
```

Then `./deploy` + `./paw clean <story> --include-summary` + `./paw sprint`.

Without `test_tiers` the fix is inert — RED still confirms tests but tiers are not
separated (single catch-all tier, unchanged behavior from before v6.18.0).

Note: `python3 -m paw_runner.test_targeting` can be run from the workspace root
(where `paw_runner` is importable — the standard deploy-by-copy layout).

---

## Get Help

Start a Claude Code conversation and type:

```
/bmad:pcc
```

The PCC agent (Nova) guides you through any lifecycle decision. You can ask:

- "What should I do next?"
- "Story X is stuck — what's wrong?"
- "Can I close the sprint with these gaps?"
- "Which epic stories are still blocking validation?"

For per-workflow usage details:
→ `_bmad/pcc/docs/lifecycle-hierarchy.md` — full state machines
→ `_bmad/pcc/docs/sprint-scoping-model.md` — sprint YAML schema
→ `docs/specification/pcc-workflow-catalog.md` — capability catalog (pre-migration reference; authoritative registry is `module.yaml` `skills:`)

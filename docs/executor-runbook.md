# PCC Executor Runbook

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
└── ...                          →  83 total commands
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
1. Load workflow.xml engine
2. Read workflow config
3. Execute workflow instructions
</steps>
```

The `context: fork` directive means the command runs in a forked Claude Code session, keeping the main conversation context clean.

### Naming Convention

Commands follow the pattern `bmad-pcc-{name}.md`:

| File pattern | Slash command | Type |
|-------------|--------------|------|
| `bmad-pcc-{workflow}.md` | `/bmad-pcc-{workflow}` | Workflow command (74) |
| `bmad-pcc-{name}.agent.md` | `/bmad-pcc-{name}` | Agent command (6) |
| `bmad-pcc-{task}.md` | `/bmad-pcc-{task}` | Task command (3) |

### Verifying Installation

```bash
# Count installed commands
ls .claude/commands/bmad-pcc-*.md | wc -l    # Should be 83

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
```

The pipeline runs fully automated: create → ATDD → design → dev → review → done.
Self-healing is built in: 1 retry per step, up to 2 regressions before stopping.

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

### 4. Mid-Sprint: Scope Changes

```
/bmad:pcc:workflows:sprint-replan
```

Calculates rolling velocity, proposes story additions/removals, requires your confirmation before applying.

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

Each pipeline step has built-in defaults for model, max turns, and reasoning effort level. You can override these per-step in `_bmad/pcc/config.yaml` to control cost, speed, and quality.

### Built-in Step Defaults

| Step | Model | Max Turns | Effort |
|------|-------|-----------|--------|
| CREATE_STORY | opus | 50 | low |
| VALIDATE_STORY | haiku | 20 | low |
| ATDD | sonnet | 50 | medium |
| DESIGN_SCREEN | sonnet | 80 | high |
| DEV_STORY | opus | 150 | high |
| COMPLETENESS_GATE | haiku | 30 | low |
| CODE_REVIEW | opus | 80 | high |
| CODE_REVIEW_QG | sonnet | 60 | medium |
| CODE_REVIEW_ANALYSIS | haiku | 30 | low |
| AC_VALIDATION | sonnet | 80 | medium |
| UI_VALIDATION | sonnet | 60 | medium |
| CODE_REVIEW_FINALIZE | opus | 80 | medium |

### Overriding Step Defaults

Add a `step_overrides:` block to `_bmad/pcc/config.yaml`. Only the fields you specify are overridden; the rest keep their defaults.

```yaml
# _bmad/pcc/config.yaml
step_overrides:
  # Use opus for code review analysis instead of haiku
  code-review-analysis:
    model: opus
    effort: high

  # Reduce dev-story turns to save cost
  dev-story:
    max_turns: 100
    effort: medium
```

**Available values:**
- `model`: `opus`, `o4`, `o46`, `sonnet`, `haiku`
- `effort`: `low`, `medium`, `high` (maps to Claude reasoning effort — lower = fewer thinking tokens = faster and cheaper)
- `max_turns`: any positive integer

Step names use the kebab-case form (e.g., `dev-story`, `code-review-qg`, `ac-validation`).

### Global Model Override with Effort Profiles

When using `--model` to override all steps (e.g., `./paw run {key} --model opus`), the effort levels automatically tune for that model's capability. Opus is more capable per token, so lightweight steps drop effort:

| Step | Default (mixed) | Opus profile |
|------|----------------|--------------|
| create-story | opus/low | opus/low |
| validate-story | haiku/low | opus/low |
| atdd | sonnet/medium | opus/low |
| design-screen | sonnet/high | opus/medium |
| dev-story | opus/high | opus/high |
| completeness-gate | haiku/low | opus/low |
| code-review | opus/high | opus/high |
| code-review-qg | sonnet/medium | opus/low |
| code-review-analysis | haiku/low | opus/low |
| ac-validation | sonnet/medium | opus/low |
| ui-validation | sonnet/medium | opus/medium |
| code-review-finalize | opus/medium | opus/medium |

Profiles exist for `opus` and `o46`. Models without a profile keep per-step default effort.

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

**Smoke mode safety:** Commits are auto-disabled (`--no-commit`) to prevent test runs from modifying the repo. Smoke also validates post-step processing (quality gate verification, memory saves) that dry-run cannot reach. Use `--parallel --smoke` to exercise the full fan-out worktree path.

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
→ `docs/specification/pcc-workflow-catalog.md` — all 74 workflows

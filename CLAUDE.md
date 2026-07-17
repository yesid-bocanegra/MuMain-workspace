# lean-ctx — Context Engineering Layer

PREFER lean-ctx MCP tools over native equivalents for token savings:

| PREFER | OVER | Why |
|--------|------|-----|
| `ctx_read(path)` | Read / cat / head / tail | Session caching, 8 compression modes, re-reads cost ~13 tokens |
| `ctx_shell(command)` | Bash (shell commands) | Pattern-based compression for git, npm, cargo, docker, tsc |
| `ctx_search(pattern, path)` | Grep / rg | Compact context, token-efficient results |
| `ctx_tree(path, depth)` | ls / find | Compact directory maps with file counts |

## ctx_read Modes

- `full` — cached read (use for files you will edit)
- `map` — deps + API signatures (use for context-only files)
- `signatures` — API surface only
- `diff` — changed lines only (after edits)
- `aggressive` — syntax stripped
- `entropy` — Shannon + Jaccard filtering
- `lines:N-M` — specific range

## File Editing

Use native Edit/StrReplace when available. If Edit requires Read and Read is unavailable,
use `ctx_edit(path, old_string, new_string)` — it reads, replaces, and writes in one MCP call.
NEVER loop trying to make Edit work. If it fails, switch to ctx_edit immediately.
Write, Delete have no lean-ctx equivalent — use them normally.

# MuMain Project Guidelines

lean-ctx instructions only control tool usage. They do not replace project development rules.

## Mandatory Baseline

Before modifying code, tests, build files, documentation, or Git history, read:

1. `CONTRIBUTING.md` — contribution workflow, quality gates, commit format, and coding summary.
2. `_bmad-output/project-context.md` — project-wide technology, coding, testing, workflow, and portability rules.
3. `docs/development-standards.md` — authoritative development standards, including Git and CI workflow in §6.
4. `docs/index.md` — documentation map and task-specific context loading table.

For PCC work, load `.agents/skills/execution/load-guidelines/SKILL.md` before implementation or review.

## Task-Specific Guidelines

Load relevant documents before changing that area:

| Work | Required References |
|------|---------------------|
| Architecture or module boundaries | `_bmad-output/planning-artifacts/architecture.md`, `docs/integration-architecture.md`, relevant `docs/architecture-*.md` |
| C++ code | `docs/development-standards.md` §1-2, `docs/cppcheck-guidance.md` |
| C# / Native AOT bridge | `docs/development-standards.md` §3, `docs/architecture-clientlibrary.md`, `docs/packet-protocol-reference.md` |
| Generated packet/codegen files | `docs/development-standards.md` §4, `docs/architecture-constantsreplacer.md` |
| UI, scenes, or gameplay | `docs/architecture-mumain.md`, `docs/game-systems-reference.md`, relevant `docs/implementation-recipes.md` |
| Rendering | `docs/architecture-rendering.md`, `docs/performance-guidelines.md` |
| Network protocol | `docs/packet-protocol-reference.md`, `docs/architecture-clientlibrary.md`, `docs/integration-architecture.md` |
| Build, CMake, dependencies, or CI | `docs/development-guide.md`, `docs/development-standards.md` §7, `docs/ci-workflows.md`, `docs/troubleshooting.md` |
| Cross-platform or platform APIs | `docs/development-standards.md` §1 and §8, relevant phase in `docs/CROSS_PLATFORM_PLAN.md`, `docs/CROSS_PLATFORM_DECISIONS.md` |
| Assets or content loading | `docs/asset-pipeline.md` |
| Translation or user-facing strings | `docs/development-standards.md` §5, `MuMain/docs/translation-system.md` |
| Security-sensitive work | `docs/security-guidelines.md` |
| Performance-sensitive work | `docs/performance-guidelines.md` |
| Tests and regression coverage | `docs/testing-strategy.md` |
| New structural decisions | `docs/adr/README.md` and existing ADRs |
| Change impact discovery | `docs/feature-impact-maps.md`, relevant recipe in `docs/implementation-recipes.md` |

## Git Requirements

- Follow Conventional Commits: `type(scope): imperative description`.
- Allowed types: `feat`, `fix`, `perf`, `refactor`, `docs`, `style`, `test`, `build`, `ci`, `chore`.
- Approved scopes: `render`, `network`, `ui`, `input`, `audio`, `build`, `editor`, `i18n`, `codegen`. Scope is optional; do not invent scopes.
- Commit type controls semantic-release. Use `perf` for performance work and non-release types for documentation, tests, build tooling, CI, and maintenance.
- Keep one concern or migration unit per commit. Do not batch unrelated migrations.
- Reference ground-truth screenshots in commit bodies for visual changes.
- Separate generated-file commits from manual changes using `chore(codegen):` where applicable.
- Run required quality gates from `CONTRIBUTING.md` and `docs/development-standards.md` before finalizing work.

## Rule Precedence

Direct user/system instructions override repository documents. Otherwise, a deeper `AGENTS.md` overrides this file for its subtree. PCC-managed content below is additive; it does not replace project guidelines above.

<!-- PCC-START — managed by PCC deploy, do not edit manually -->
# PCC Module

PCC (Project-specific Customizations and Constraints) is a standalone module (originally a BMAD add-on; decoupled v6.10.0) that provides automated story lifecycle, quality gates, and sprint management.

## Key Paths

- `_bmad/pcc/` — workflows, tasks, templates, agents, rules
- `paw_runner/` — automation pipeline (invoked via `./paw`)

## Usage

Run the full story pipeline:
```bash
./paw story-key          # auto-detect and resume from last step
./paw story-key --from DEV_STORY --to CODE_REVIEW_QG
```

Invoke skills directly (slash commands resolve via command entrypoints that load the skill):
```bash
/bmad:pcc:workflows:dev-story
/bmad:pcc:workflows:code-review-quality-gate
# skills the runner loads by path, e.g. _bmad/pcc/skills/execution/load-guidelines/SKILL.md
```

## Do NOT

- Build code to "process" or "transform" workflows — they are prompts Claude reads directly
- Create YAML workflow definitions for code to execute
- Build a "workflow engine" or "dispatcher"
- Duplicate what `paw_runner/` already does

## Project Configuration

**Project:** MuMain

**Components:**
- `project-docs` — documentation (./_bmad-output) [documentation]
- `mumain` — cpp-cmake (./MuMain) [backend]

**Pencil design screens:** enabled
<!-- PCC-END -->

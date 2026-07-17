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

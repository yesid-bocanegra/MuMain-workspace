---
story_key: 7-9-3
story_title: "Unify Entry Point — Delete WinMain, Single main() for All Platforms"
status: in-progress
started: 2026-03-27
last_updated: 2026-03-27
session_count: 1
completed_count: 0
total_count: 22
current_task: "Task 1: Port missing WinMain init to MuMain"
task_progress: 0%
next_action: "Add g_fScreenRate_x/y, error report header, argc/argv to MuMain"
---

## Quick Resume

| Field | Value |
|-------|-------|
| Next Action | Add g_fScreenRate_x/y, error report header, argc/argv to MuMain() |
| Active File | MuMain/src/source/Main/Winmain.cpp |
| Blocker | None |

## Current Position

| Metric | Value |
|--------|-------|
| completed_count | 0 |
| total_count | 22 |
| current_task | Task 1.1 (error report log header) |
| task_progress | 0% |

## Active Task Details

**Task 1: Port missing WinMain init to MuMain**
- [ ] 1.1: Add error report log header
- [ ] 1.2: Add argc/argv server override
- [ ] 1.3: Add g_fScreenRate_x/y calculation
- [ ] 1.4: Verify all init steps

## Technical Decisions

### Decision 1: Keep Win32 Globals as nullptr
**Context**: `g_hWnd`, `g_hDC`, `g_hRC`, `g_hInst` are referenced by 210+ locations across the codebase.
**Decision**: Keep them defined as `nullptr` in Winmain.cpp after deleting WinMain. They were already `nullptr` on macOS/Linux SDL3 path. All reference sites are null-safe via PlatformCompat.h shims.
**Why**: Removing 210+ references would be a separate story. The globals are now permanently `nullptr` (WinMain is deleted and never sets them).

### Decision 2: g_hFont globals
**Context**: `g_hFont`, `g_hFontBold`, `g_hFontBig`, `g_hFixFont` are widely used in UI files.
**Decision**: Keep them as `nullptr` definitions - they're `HFONT = void*` on non-Win32 via PlatformCompat.h. Not in the explicit Task 3.4 removal scope.

### Decision 3: CheckHack and other shared functions
**Context**: Lines 179-205 contain `CheckHack()` which is called from WSclient.cpp and is cross-platform.
**Decision**: Keep `CheckHack()` - it's shared game code, not Win32-only.

### Decision 4: GetConnectServerInfo replacement
**Context**: Win32 `GetConnectServerInfo` uses wchar_t command line.
**Decision**: Port to argv: add a simple cross-platform parser that checks argv for `-u` and `-p` flags.

## Session History

### Session 1 (2026-03-27)
- Status: In progress
- Work: Initial analysis and setup
- Files analyzed: Winmain.cpp, ErrorReport.cpp, Winmain.h, atdd.md, story.md, test file
- Key findings:
  - MuMain missing: g_fScreenRate_x/y, error report header, argc/argv parsing
  - Winmain.cpp is 1721 lines; Win32 block (lines 207-1440) to be deleted
  - 210+ references to g_hWnd/g_hDC across codebase - keep as nullptr
  - Test file already exists at tests/platform/test_entry_point_unification_7_9_3.cpp
  - 19 source files have #ifdef _WIN32 guards to remove (AC-5)

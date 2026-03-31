---
story_key: 7-9-3
story_title: "Unify Entry Point — Delete WinMain, Single main() for All Platforms"
status: dev-complete
started: 2026-03-27
last_updated: 2026-03-30
session_count: 2
completed_count: 22
total_count: 22
current_task: "All tasks complete"
task_progress: 100%
next_action: "Ready for code review"
---

## Quick Resume

| Field | Value |
|-------|-------|
| Next Action | Ready for code review |
| Active File | N/A — all work complete |
| Blocker | None |

## Current Position

| Metric | Value |
|--------|-------|
| completed_count | 22 |
| total_count | 22 |
| current_task | All complete |
| task_progress | 100% |

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
- Work: Initial analysis, Tasks 1-4 completed (WinMain deletion, #ifdef _WIN32 cleanup, init porting)
- Files analyzed: Winmain.cpp, ErrorReport.cpp, Winmain.h, atdd.md, story.md, test file
- Key findings:
  - MuMain missing: g_fScreenRate_x/y, error report header, argc/argv parsing
  - Winmain.cpp is 1721 lines; Win32 block (lines 207-1440) to be deleted
  - 210+ references to g_hWnd/g_hDC across codebase - keep as nullptr
  - Test file already exists at tests/platform/test_entry_point_unification_7_9_3.cpp
  - 19 source files have #ifdef _WIN32 guards to remove (AC-5)

### Session 2 (2026-03-30)
- Status: dev-complete
- Work: Task 5 (AC-6) — deleted MU_USE_OPENGL_BACKEND flag and OpenGL renderer backend
- Files modified: CMakeLists.txt, stdafx.h, MuRendererSDLGpu.cpp, ZzzOpenglUtil.cpp, Winmain.cpp, Winmain.h, ZzzTexture.cpp, SceneCore.cpp
- File deleted: MuRenderer.cpp (411 lines)
- Also: Deleted KillGLWindow() and removed all callers/externs
- Tests: 9/9 story tests pass (50 assertions), 89/90 full suite (1 pre-existing SIGSEGV in 7-6-7)
- Quality: `./ctl check` exits 0, AC-5 grep = 0, AC-6 grep = 0
- All ATDD items checked, story marked dev-complete

# Progress: 7-9-6 Migrate Raw GL to MuRenderer

## Quick Resume
- **next_action:** Story ready for completeness-gate / code-review
- **active_file:** n/a
- **blocker:** AC-10 (visual verification) requires running on physical device

## Current Position
- **status:** completeness-gate
- **started:** 2026-03-31
- **last_updated:** 2026-03-31
- **session_count:** 2
- **completed_count:** 29
- **total_count:** 34
- **current_task:** Tasks 1-8 complete, Task 9 (visual verification) pending
- **task_progress:** 85%

## Active Task Details
- **Tasks 1-8:** All complete — zero raw GL calls remain, stubs deleted, build passes, tests pass
- **Task 9:** Visual Verification (AC-10) — requires running on SDL3 GPU backend on physical device

## Technical Decisions
- **glColor* calls identified as dead code:** `glBegin/glEnd` removed in story 7-9-2, making all 630+ `glColor*` calls no-ops (color state only consumed by immediate-mode vertices). Deleted rather than migrated.
- **GL constants retained:** `stdafx.h` GL_* `#define` constants kept — used as MuRenderer API parameter values (e.g., `GL_LESS`, `GL_CCW`, `GL_KEEP`). GL type definitions (GLuint, etc.) also kept.
- **Orphaned control flow:** Bulk deletion of glColor calls left ~15 orphaned `if/else` blocks where glColor was the only statement in a branch. Each manually fixed: empty branches removed, conditions simplified.
- **`glColor4ub` and `glColor3ub` variants:** Initial bulk regex only caught `glColor3f/3fv/4f/4fv/4ubv`. Second pass caught 37 additional `glColor4ub`/`glColor3ub` calls.
- **SetLineColor() in UIWindows.cpp:** Function body was entirely switch cases with glColor4ub — became empty function with `(void)` parameter suppression.
- **NewUIMyInventory.cpp durability check:** Collapsed 6-branch if/else chain (where each branch was dead glColor) into single `if (Durability > 50% && IsEquipable) continue;`.

## Session History

### Session 1 (2026-03-31)
- Assessed codebase: 0 raw GL calls remain (all already migrated to MuRenderer by prior stories)
- All 20 IMuRenderer methods already present from prior work
- Identified 630+ dead glColor* calls and 82 stdafx.h stubs as remaining work

### Session 2 (2026-03-31)
- Deleted 82 GL function stubs from stdafx.h
- Bulk-deleted 630+ glColor3f/3fv/4f/4fv/4ubv calls across 108 files
- Deleted 37 glColor4ub/glColor3ub calls across 6 files
- Fixed 15+ orphaned if/else blocks from glColor deletion
- Removed dead glTexImage2D guards in 3 files
- Replaced glReadPixels with MuRenderer in GroundTruthCapture.cpp
- Fixed 5 unused variable errors in ZzzEffectJoint.cpp
- Build: clean (0 errors)
- Tests: 10/10 story tests pass (154 assertions), 180/182 full suite (2 pre-existing audio SIGSEGV)
- Quality gate: `./ctl check` passes

## Blockers and Open Questions
- AC-10 (visual verification) cannot be automated — requires running SDL3 GPU backend on physical device

## File List
- `stdafx.h` — deleted 82 GL function stubs
- `ZzzBMD.cpp` — removed glColor4f, glTexImage2D guard, orphaned if/else
- `ZzzEffectJoint.cpp` — removed 5 unused variables
- `ShadowVolume.cpp` — removed unused vLight
- `GlobalBitmap.cpp` — cleaned 3 SDL3 guards
- `GroundTruthCapture.cpp` — replaced glReadPixels
- `ZzzInventory.cpp` — removed glTexImage2D guards, orphaned if/else
- `UIControls.cpp` — removed glTexImage2D guards, glColor4ub, orphaned if/else
- `UIWindows.cpp` — simplified SetLineColor, SetControlButtonColor
- `UIGuildInfo.cpp` — removed 3 orphaned if/else
- `ZzzInterface.cpp` — removed orphaned if/else
- `NewUIInventoryCtrl.cpp` — removed orphaned if/else
- `NewUISiegeWarBase.cpp` — removed glColor4f
- `NewUIGuardWindow.cpp` — removed glColor3ub
- `NewUIMyInventory.cpp` — simplified durability if/else
- `NewUIGuildInfoWindow.cpp` — removed orphaned if/else
- `NewUIGuildMakeWindow.cpp` — removed glColor4ub
- `GOBoid.cpp` — removed orphaned if/else
- `GMCrywolf1st.cpp` — removed orphaned if/else
- 108 additional files — bulk glColor* deletion

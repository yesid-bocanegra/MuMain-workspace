# Session Summary: Story 3-1-1-cmake-rid-detection

This file aggregates session summaries from multiple consolidation runs.
Each session section represents a consolidation of workflow logs.

---

## Session: 2026-03-06 23:09

**Log files analyzed:** 9

## Issues Found

| Issue | Severity | Category |
|-------|----------|----------|
| D-1: `cmake_minimum_required()` in `FindDotnetAOT.cmake` | Minor | Anti-pattern |
| F-1: Duplicate legacy `ClientLibrary` dotnet build system not gated | HIGH | Architecture |
| F-2: `CMAKE_RUNTIME_OUTPUT_DIRECTORY` unset in `BuildDotNetAOT` POST_BUILD | MEDIUM | Build system |
| F-3: `DOTNET_EXECUTABLE` cache variable collision between old and new systems | MEDIUM | CMake cache |
| F-4: Invalid `--no-self-contained false` CLI flag in dev notes | LOW | Documentation |
| F-5: ATDD commit used `chore(paw)` instead of `build`/`test` | LOW | Metadata |

## Fixes Attempted

| Issue | Fix Applied | Result |
|-------|------------|--------|
| D-1 | Removed `cmake_minimum_required(VERSION 3.25)` from include file | ✅ FIXED |
| F-1 | Gated legacy `ClientLibrary` behind `if(NOT MU_ENABLE_DOTNET)`, moved option declaration before `add_subdirectory("src")` | ✅ FIXED |
| F-2 | Replaced `${CMAKE_RUNTIME_OUTPUT_DIRECTORY}` (unset) with `$<TARGET_FILE_DIR:Main>` generator expression | ✅ FIXED |
| F-3 | Renamed `DOTNET_EXECUTABLE` → `DOTNETAOT_EXECUTABLE` throughout `FindDotnetAOT.cmake`, `CMakeLists.txt`, and ATDD tests | ✅ FIXED |
| F-4 | Not fixed (documentation-only issue, no code impact) | ⏸️ DEFERRED |
| F-5 | Not fixed (commit metadata only, no code impact) | ⏸️ DEFERRED |

## Unresolved Blockers

None. Story completed with approval status despite two LOW-severity non-code issues (F-4 documentation, F-5 commit type). These do not affect functionality or build integrity.

## Key Decisions Made

1. **Gating strategy**: Moved `MU_ENABLE_DOTNET` option declaration before `add_subdirectory("src")` to allow the legacy system's CMake code to check the gate on first configure, rather than failing after cache population.

2. **Build output path**: Used `$<TARGET_FILE_DIR:Main>` generator expression instead of relying on `CMAKE_RUNTIME_OUTPUT_DIRECTORY`, matching the pattern already established by the legacy system.

3. **Cache namespace isolation**: Renamed the new system's cache variable from `DOTNET_EXECUTABLE` to `DOTNETAOT_EXECUTABLE` to eliminate silent cache collision where old system's `find_program()` would populate the cache first, overriding explicit `PATHS` hints in the new system.

4. **Dual-system coexistence**: Determined that temporary coexistence of old (Windows-only) and new (cross-platform) dotnet build systems is acceptable during transition, with clear gating. Identified that story 3-1-2 will remove the legacy system entirely.

## Lessons Learned

- **CMake anti-pattern**: `cmake_minimum_required()` in include files (`Find*.cmake`) breaks assumptions of calling projects. Modules should not impose version constraints.
- **Cache pollution**: CMake cache variables are global to the project. Two independent subsystems using the same cache variable name cause silent overrides. Namespace with prefixes.
- **Unset variables silently fail**: `${UNSET_VAR}` expands to empty string, not an error. Commands like `file(COPY ... DESTINATION ${UNSET_VAR})` copy to the current directory or fail silently. Always use generator expressions or explicit assignments.
- **Generator expressions vs. variables**: `$<TARGET_FILE_DIR:...>` is more reliable than `CMAKE_*_OUTPUT_DIRECTORY` for target-specific paths, especially in POST_BUILD steps.
- **Dual system risk**: Adding new parallel systems alongside legacy code without clear activation gates leads to both systems executing and competing for resources.

## Recommendations for Reimplementation

1. **Remove legacy `ClientLibrary` dotnet build entirely in 3-1-2**, not just gate it. Current gating is a bridge measure for parallel development.

2. **Standardize RID detection logic**: Create a single source of truth for platform → RID mapping. Currently the logic exists in multiple places (legacy hardcoding, new detection).

3. **Define CMAKE_RUNTIME_OUTPUT_DIRECTORY early** in root `CMakeLists.txt` before any subdirectory adds targets, rather than relying on unset fallbacks or generator expressions.

4. **Add cache variable documentation**: Add comments explaining why cache variables are prefixed (e.g., `DOTNETAOT_EXECUTABLE` vs. legacy `DOTNET_EXECUTABLE`) to prevent future collisions.

5. **Files requiring attention**:
   - `MuMain/CMakeLists.txt` - Remove the legacy gating condition (`if(NOT MU_ENABLE_DOTNET)` wrapper) in 3-1-2
   - `MuMain/src/CMakeLists.txt` - Delete the entire legacy `ClientLibrary` dotnet block in 3-1-2
   - `MuMain/cmake/FindDotnetAOT.cmake` - Already correct; document the `DOTNETAOT_EXECUTABLE` namespace choice

6. **Patterns to follow**:
   - Use `$<TARGET_FILE_DIR:TargetName>` for target-relative paths in POST_BUILD steps
   - Prefix cache variables with subsystem namespace
   - Gate incompatible legacy code with explicit `option()` checks before logic runs

7. **Patterns to avoid**:
   - Do not use `cmake_minimum_required()` in `Find*.cmake` modules
   - Do not rely on unset `CMAKE_*` variables for fallback behavior
   - Do not add new features alongside legacy code without activation gates

*Generated by paw_runner consolidate using Haiku*

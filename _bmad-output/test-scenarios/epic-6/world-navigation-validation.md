# Test Scenarios: Story 6.1.2 — World Navigation Validation

**Story ID:** 6.1.2
**Epic:** 6 — Cross-Platform Gameplay Validation
**Flow Code:** VS1-GAME-VALIDATE-NAVIGATION
**Date:** 2026-03-21
**Test Type:** Manual + Catch2 Unit

---

## Overview

This document defines the complete test plan for validating world navigation (character movement,
map transitions, map rendering, and minimap) works correctly on macOS, Linux, and Windows
(regression). Automated Catch2 tests cover pure logic (map IDs, pathfinding grid geometry,
direction mapping, terrain flags, gate data). Platform rendering and server-interaction tests
are manual-only.

**Prerequisites:**
- Running MU Online test server (game world entry required for AC-1..5 full validation)
- macOS build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- Linux build: MinGW cross-compile or native Linux build
- Windows build: `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug`

> **Risk R17:** All full AC-1..5 scenarios require a running MU Online server for actual
> in-game validation. Catch2 tests cover server-independent logic only.

---

## Automated Tests (Catch2 — Headless, No Server Required)

### Unit Test File
`MuMain/tests/world/test_world_navigation_validation.cpp`

### Test Coverage

| Test Case | AC | Expected Phase |
|-----------|-----|----------------|
| `AC-5 [6-1-2]: ENUM_WORLD defines correct IDs for the 6 key game maps` | AC-5 | RED→GREEN |
| `AC-5 [6-1-2]: ENUM_WORLD covers 82+ game world map slots` | AC-5 | RED→GREEN |
| `AC-5 [6-1-2]: ENUM_WORLD event map ranges use correct base IDs` | AC-5 | RED→GREEN |
| `AC-1 [6-1-2]: PATH CheckXYPos enforces map grid boundaries` | AC-1 | RED→GREEN |
| `AC-1 [6-1-2]: PATH GetIndex maps 2D coordinates to flat array index` | AC-1 | RED→GREEN |
| `AC-1 [6-1-2]: PATH EstimateCostToGoal heuristic properties` | AC-1 | RED→GREEN |
| `AC-1 [6-1-2]: MovePoint maps all 8 EPathDirection values to correct coordinate deltas` | AC-1 | RED→GREEN |
| `AC-2 [6-1-2]: MOVEINFODATA index equality operator matches gate by index` | AC-2 | RED→GREEN |
| `AC-2 [6-1-2]: MOVEINFODATA _bCanMove flag controls gate passability` | AC-2 | RED→GREEN |
| `AC-2 [6-1-2]: TW_* terrain attribute flags are distinct non-overlapping bitmasks` | AC-2 | RED→GREEN |
| `AC-2 [6-1-2]: CMapManager map range queries` | AC-2 | SKIP (needs MUGame) |
| `AC-2 [6-1-2]: CPortalMgr portal state save/restore` | AC-2 | SKIP (needs MUGame) |
| `AC-1 [6-1-2]: PATH FindPath A* navigation` | AC-1 | SKIP (needs MUGame) |

---

## Manual Test Scenarios

### Scenario 1: Character Movement — Click-to-Move (AC-1)

**Platforms:** macOS, Linux, Windows (regression)

**Steps:**
1. Log in to test server and enter game world (Lorencia)
2. Click a destination tile in open terrain
3. Verify character begins moving toward the target via A* pathfinding
4. Verify character stops at the destination tile without overshooting
5. Repeat with keyboard movement (WASD or arrow keys if supported)
6. Verify movement feels identical across all three platforms

**Expected Results:**
- Character moves smoothly to destination on all platforms
- Pathfinding does not steer through walls or obstacles
- No freeze or crash on path calculation
- `MuError.log` contains no unexpected errors

**Evidence Required:** Video/screenshots of character movement on each platform

---

### Scenario 2: Map Transitions — Portal and Warp System (AC-2)

**Platforms:** macOS, Linux, Windows (regression)

**Steps:**
1. Navigate character to the portal to Dungeon (from Lorencia)
2. Interact with the portal (walk into trigger zone)
3. Verify loading screen appears and completes
4. Verify Dungeon map renders correctly after transition
5. Repeat for: Devias portal, Lost Tower portal, Atlans portal
6. Test warp NPC: open warp dialog, select Noria, confirm

**Expected Results:**
- All map transitions complete without crash or hang
- Target map renders terrain, NPCs, and objects correctly
- Player spawns at correct destination coordinates
- Portal level/zen requirements are enforced (blocked if requirements unmet)
- Map loads at identical speed across all three platforms

**Evidence Required:** Screenshots of each target map after transition

---

### Scenario 3: Map Rendering — Terrain, Objects, NPCs (AC-3)

**Platforms:** macOS, Linux, Windows (regression)

**Maps to test:** Lorencia, Devias, Noria, Dungeon, Lost Tower, Atlans

**Steps:**
1. Enter each of the 6 key maps
2. Walk through the full visible map area
3. Verify: terrain (LOD terrain system) renders without holes or missing tiles
4. Verify: static objects (buildings, trees, decorations) are visible and correctly placed
5. Verify: NPCs render and animate correctly
6. Verify: monster models render and animate correctly
7. Verify: no flickering, Z-fighting, or texture corruption

**Expected Results:**
- Terrain renders at all LOD levels without missing geometry
- All objects and NPCs visible and correctly positioned
- Textures display without corruption or missing mipmaps
- Rendering is visually identical across all three platforms
- Frame rate is acceptable on each platform (no severe drops)

**Evidence Required:** Screenshots of each of the 6 maps on each platform

---

### Scenario 4: Minimap Display (AC-4)

**Platforms:** macOS, Linux, Windows (regression)

**Steps:**
1. Enter game world and open the minimap (`CNewUIMiniMap`)
2. Verify minimap shows the current map outline
3. Verify player position indicator updates as character moves
4. Verify location buttons (if any) are clickable and navigate correctly
5. Verify minimap scroll works if map is larger than minimap window
6. Test minimap on each of the 6 key maps

**Expected Results:**
- Minimap renders correctly without pixel corruption
- Player position dot moves in sync with character movement
- Location buttons are responsive
- Minimap scale is correct relative to the game world
- Minimap behavior is identical across all three platforms

**Evidence Required:** Screenshots of minimap on each of the 6 key maps

---

### Scenario 5: Sample Map Coverage — All 6 AC-5 Maps (AC-5)

**Platforms:** macOS, Linux, Windows (regression)

**Maps:** Lorencia (0), Devias (2), Noria (3), Dungeon (1), Lost Tower (4), Atlans (7)

**Steps:**
1. Visit each of the 6 maps during the session (any order)
2. For each map: confirm ENUM_WORLD ID matches the map name displayed in-game
3. Verify no maps produce a crash or black screen on load
4. Verify no maps trigger the "Map load error" fallback path in `MuError.log`

**Expected Results:**
- All 6 key maps load and render successfully on all three platforms
- Map IDs match ENUM_WORLD enum values (verified by log output if debug build)
- No entries in `MuError.log` related to map loading or rendering

**Evidence Required:** Summary table of maps tested per platform with pass/fail

---

## Regression Validation (Windows Baseline)

After confirming all scenarios pass on macOS and Linux, re-run the full scenario set on Windows
to confirm no regressions. Document any behavioral differences observed between platforms.

---

## Test Data Requirements

| Data | Source | Notes |
|------|--------|-------|
| Running MU Online server | Test environment | Required for all manual scenarios |
| Test account with game access | Server admin | Min level: able to reach Dungeon |
| All 6 key map data files | `MuMain/src/bin/Data/` | Already present in repository |
| Debug build for log output | CMake Debug preset | `cmake --build --preset *-debug` |

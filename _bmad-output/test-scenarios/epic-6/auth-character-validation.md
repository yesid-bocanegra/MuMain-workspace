# Test Scenarios: Story 6.1.1 — Auth & Character Management Validation

**Story ID:** 6.1.1
**Epic:** 6 — Cross-Platform Gameplay Validation
**Flow Code:** VS1-GAME-VALIDATE-AUTH
**Date:** 2026-03-20
**Test Type:** Manual + Catch2 Unit

---

## Overview

This document defines the complete test plan for validating authentication and character management work correctly on macOS, Linux, and Windows (regression). Automated Catch2 tests cover pure logic (class types, selection bounds, scene state). Platform rendering and server-interaction tests are manual-only.

**Prerequisites:**
- Running MU Online test server (auth + character management)
- macOS build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- Linux build: MinGW cross-compile or native Linux build
- Windows build: `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug`

---

## Automated Tests (Catch2 — Headless, No Server Required)

### Unit Test File
`MuMain/tests/scenes/test_auth_character_validation.cpp`

### Test Coverage

| Test Case | AC | Status |
|-----------|-----|--------|
| `AC-4 [6-1-1]: 5 base character classes defined in CLASS_TYPE enum` | AC-4 | RED |
| `AC-3 [6-1-1]: Character account supports exactly 5 character slots` | AC-3 | RED |
| `AC-1 [6-1-1]: SceneInitializationState starts with all flags false` | AC-1 | SKIP (needs MUGame) |
| `AC-1 [6-1-1]: SceneInitializationState ResetAll clears all flags` | AC-1 | SKIP (needs MUGame) |
| `AC-6 [6-1-1]: SceneInitializationState ResetForDisconnect preserves loading flag` | AC-6 | SKIP (needs MUGame) |
| `AC-3 [6-1-1]: CharacterSelectionState has no selection on construction` | AC-3 | SKIP (needs MUGame) |
| `AC-5 [6-1-1]: CharacterSelectionState accepts valid character slots` | AC-5 | SKIP (needs MUGame) |
| `AC-6 [6-1-1]: CharacterSelectionState ClearSelection returns to NO_SELECTION` | AC-6 | SKIP (needs MUGame) |
| `AC-5 [6-1-1]: FrameTimingState ShouldRenderNextFrame controls scene loop` | AC-5 | SKIP (needs MUGame) |

---

## Manual Test Scenarios

### Scenario 1: Login Screen Validation (AC-1)

**Platforms:** macOS, Linux, Windows

**Steps:**
1. Launch game on target platform
2. Verify SDL3 window opens and login screen renders
3. Verify: game logo visible, username/password fields visible, login button visible
4. Verify: UI elements are correctly positioned (not offset, not clipped)
5. Verify: text rendering uses correct font and encoding

**Expected Results:**
- SDL3 window opens without crash or error dialog
- Login screen UI renders fully within window bounds
- No visual artifacts or corrupted pixels
- `MuError.log` contains no unexpected errors at startup

**Evidence Required:** Screenshot of login screen on target platform

---

### Scenario 2: SDL3 Text Input — Username/Password Entry (AC-2)

**Platforms:** macOS, Linux, Windows

**Steps:**
1. Click on the Username field
2. Type a username using keyboard (e.g., "testuser123")
3. Verify characters appear in the field as typed
4. Click on the Password field
5. Type a password (e.g., "pass123")
6. Verify password characters appear masked (asterisks or dots)
7. Verify Backspace deletes characters correctly
8. Verify field respects max character limit

**Expected Results:**
- `g_szSDLTextInput` buffer correctly populated via `SDL_EVENT_TEXT_INPUT`
- `CUITextInputBox::DoActionSub()` processes SDL3 input path
- Characters appear in correct order with no dropped inputs
- Backspace works correctly
- Field does not accept input beyond max length

**Reference:** `MuMain/src/source/Platform/sdl3/SDLKeyboardState.cpp` — `g_szSDLTextInput`

---

### Scenario 3: Character List Display (AC-3)

**Platforms:** macOS, Linux, Windows

**Steps:**
1. Log in with a test account that has existing characters
2. Verify the character select screen loads after authentication
3. Verify all character slots are visible (up to 5 slots)
4. Verify character names and class icons display correctly
5. Verify empty slots show "Create" option

**Expected Results:**
- Character select screen renders correctly
- Up to 5 character slots displayed (`MAX_CHARACTERS_PER_ACCOUNT = 5`)
- Character names, class icons, and levels render without corruption
- Empty slots show correct "Create Character" placeholder

**Evidence Required:** Screenshot of character select screen on target platform

---

### Scenario 4: Character Creation — All 5 Classes (AC-4)

**Platforms:** macOS (primary), Linux (full), Windows (regression)

**Steps (repeat for each class):**

| Class | Expected Name Pattern | Notes |
|-------|----------------------|-------|
| Dark Wizard | Any name + "Wizard" suffix optional | CLASS_WIZARD = 0 |
| Dark Knight | Any name | CLASS_KNIGHT = 1 |
| Fairy Elf | Any name | CLASS_ELF = 2 |
| Magic Gladiator | Any name | CLASS_DARK = 3, requires lv.220 normally — check test server |
| Dark Lord | Any name | CLASS_DARK_LORD = 4, requires lv.250 normally — check test server |

**For each class:**
1. Click "Create Character" on an empty slot
2. Select the character class
3. Enter a valid character name
4. Click Create
5. Verify character appears in character list with correct class icon

**Expected Results:**
- All 5 base classes selectable and creatable
- Class icons and models render correctly for each class
- Character appears in the list after creation
- No crash or error on class selection

**Evidence Required:** Screenshot of character creation screen (at minimum 1 class per platform)

---

### Scenario 5: Character Selection and World Entry (AC-5)

**Platforms:** macOS, Linux, Windows

**Steps:**
1. Select a character from the character list
2. Click "Start Game" / "Enter World"
3. Verify world loading screen appears
4. Verify character appears in-game at starting location
5. Verify character model renders correctly (correct class appearance)
6. Verify character can move (basic input test)

**Expected Results:**
- World entry completes without crash
- Character renders at expected starting location
- Character model shows correct class appearance
- Basic movement input works (WASD or click-to-move)

**Evidence Required:** Screenshot of character in-game on target platform

---

### Scenario 6: Logout and Character Switch (AC-6)

**Platforms:** macOS, Linux, Windows

**Steps:**
1. Enter game with one character
2. Open menu and select "Return to Character Select" / logout option
3. Verify character select screen returns correctly
4. Verify the previously selected character is no longer selected (cleared)
5. Select a different character
6. Enter world with new character
7. Verify new character loads correctly

**Expected Results:**
- Logout returns to character select without crash
- Previous selection state cleared (`CharacterSelectionState::ClearSelection()` called)
- New character selection succeeds
- Scene transitions: In-Game → Character Select → In-Game work correctly

---

### Scenario 7: Windows Regression Check (AC-VAL-5)

**Platform:** Windows only

**Steps:**
1. Repeat Scenarios 1–6 on Windows
2. Compare results with macOS/Linux (no regression)

**Expected Results:**
- All scenarios pass on Windows identically to macOS/Linux
- No Windows-specific visual artifacts or bugs introduced by cross-platform migration

---

## Validation Artifacts Checklist

| Artifact | Platform | Required For |
|----------|----------|-------------|
| Screenshot: Login screen | macOS | AC-VAL-1 |
| Screenshot: Character select screen | macOS | AC-VAL-2 |
| Screenshot: Character creation screen (1+ class) | macOS | AC-VAL-3 |
| Screenshot: Login screen | Linux | AC-VAL-4 |
| Screenshot: Character select screen | Linux | AC-VAL-4 |
| Screenshot: Character creation screen | Linux | AC-VAL-4 |
| Screenshot: Login screen | Windows | AC-VAL-5 |
| Screenshot: Character select screen | Windows | AC-VAL-5 |
| This document | N/A | AC-VAL-6 |

---

## Risk Notes

- **R17:** All EPIC-6 manual scenarios require a running MU Online server. Ensure test server is available before executing Scenarios 1–6.
- **Magic Gladiator (lv.220) / Dark Lord (lv.250):** Check if test server has class level restrictions disabled. If not, use a test account with sufficient level or ask server admin to bypass.
- **macOS/Linux build:** Must have EPIC-2 (SDL3 windowing), EPIC-3 (networking), EPIC-4 (rendering) prerequisites satisfied — confirmed done per story prerequisites.

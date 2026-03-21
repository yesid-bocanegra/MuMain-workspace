# ATDD Implementation Checklist — Story 6.1.1

**Story:** Authentication & Character Management Validation
**Story Key:** 6-1-1-auth-character-validation
**Story Type:** infrastructure
**Date Generated:** 2026-03-20
**Phase:** RED (tests define expected behavior — implementation pending)

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries checked (project-context.md) | ✓ PASS — no prohibited libs in test file |
| Required testing framework (Catch2 v3.7.1) | ✓ PASS |
| Test location (`tests/{module}/test_{name}.cpp`) | ✓ PASS — `tests/scenes/test_auth_character_validation.cpp` |
| No Win32 API calls in test logic | ✓ PASS |
| Allman brace style, 4-space indent | ✓ PASS |
| No raw new/delete | ✓ PASS |
| Quality gate: `./ctl check` | ✓ PASS (711/711 files, 0 errors) |

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File | Status |
|----|-------------|-------------|-----------|--------|
| AC-1 | Login screen displays correctly (scene init state) | `AC-1 [6-1-1]: SceneInitializationState starts with all flags false` | `tests/scenes/test_auth_character_validation.cpp` | SKIP (needs MUGame) |
| AC-1 | ResetAll clears all flags | `AC-1 [6-1-1]: SceneInitializationState ResetAll clears all flags` | `tests/scenes/test_auth_character_validation.cpp` | SKIP (needs MUGame) |
| AC-2 | SDL3 text input works | Covered by `test_platform_text_input.cpp` | `tests/platform/test_platform_text_input.cpp` | GREEN (existing) |
| AC-3 | Character list: 5 slots | `AC-3 [6-1-1]: Character account supports exactly 5 character slots` | `tests/scenes/test_auth_character_validation.cpp` | VERIFIED |
| AC-3 | CharacterSelectionState initial state | `AC-3 [6-1-1]: CharacterSelectionState has no selection on construction` | `tests/scenes/test_auth_character_validation.cpp` | SKIP (needs MUGame) |
| AC-4 | 5 character classes (class enum values) | `AC-4 [6-1-1]: 5 base character classes defined in CLASS_TYPE enum` | `tests/scenes/test_auth_character_validation.cpp` | VERIFIED |
| AC-5 | Character selection bounds validation | `AC-5 [6-1-1]: CharacterSelectionState accepts valid character slots` | `tests/scenes/test_auth_character_validation.cpp` | SKIP (needs MUGame) |
| AC-5 | Scene loop timing for world entry | `AC-5 [6-1-1]: FrameTimingState ShouldRenderNextFrame controls scene loop` | `tests/scenes/test_auth_character_validation.cpp` | SKIP (needs MUGame) |
| AC-6 | ClearSelection returns to NO_SELECTION | `AC-6 [6-1-1]: CharacterSelectionState ClearSelection returns to NO_SELECTION` | `tests/scenes/test_auth_character_validation.cpp` | SKIP (needs MUGame) |
| AC-6 | ResetForDisconnect preserves loading | `AC-6 [6-1-1]: SceneInitializationState ResetForDisconnect preserves loading flag` | `tests/scenes/test_auth_character_validation.cpp` | SKIP (needs MUGame) |
| AC-STD-2 | Catch2 test suite validates logic | All tests above | `tests/scenes/test_auth_character_validation.cpp` | RED/SKIP |
| AC-VAL-6 | Test scenarios documented | Manual test plan | `_bmad-output/test-scenarios/epic-6/auth-character-validation.md` | ✓ DONE |

---

## Implementation Checklist

### Catch2 Unit Tests — Always-Enabled (no MUGame required)

- [x] `AC-4`: CLASS_WIZARD == 0 (Dark Wizard)
- [x] `AC-4`: CLASS_KNIGHT == 1 (Dark Knight)
- [x] `AC-4`: CLASS_ELF == 2 (Fairy Elf)
- [x] `AC-4`: CLASS_DARK == 3 (Magic Gladiator)
- [x] `AC-4`: CLASS_DARK_LORD == 4 (Dark Lord)
- [x] `AC-4`: CLASS_UNDEFINED == 0xFF (invalid class sentinel)
- [x] `AC-4`: 5 base classes in contiguous range [0, 4]
- [x] `AC-3`: MAX_CHARACTERS_PER_ACCOUNT == 5

### Catch2 Unit Tests — MUGame-Linked (MU_SCENE_TESTS_ENABLED)

- [x] `AC-1`: SceneInitializationState starts with all flags false
- [x] `AC-1`: SceneInitializationState::ResetAll() clears all flags
- [x] `AC-6`: SceneInitializationState::ResetForDisconnect() preserves loading flag
- [x] `AC-3`: CharacterSelectionState starts with NO_SELECTION (-1)
- [x] `AC-5`: CharacterSelectionState::SelectCharacter(0) sets slot 0
- [x] `AC-5`: CharacterSelectionState::SelectCharacter(4) sets last slot
- [x] `AC-5`: SelectCharacter(-1) rejected (HasSelection() stays false)
- [x] `AC-5`: SelectCharacter(5) rejected (out of bounds)
- [x] `AC-6`: CharacterSelectionState::ClearSelection() returns to NO_SELECTION
- [x] `AC-5`: FrameTimingState uncapped mode always renders
- [x] `AC-5`: FrameTimingState capped mode renders when elapsed >= msPerFrame
- [x] `AC-5`: FrameTimingState capped mode does NOT render before frame time

### Task 1: Manual Test Scenario Documentation

- [x] `AC-VAL-6`: Test scenario document created (`_bmad-output/test-scenarios/epic-6/auth-character-validation.md`)
- [ ] `AC-VAL-1`: Screenshot — login screen on macOS
- [ ] `AC-VAL-2`: Screenshot — character select screen on macOS
- [ ] `AC-VAL-3`: Screenshot — character creation (1+ class) on macOS
- [ ] `AC-VAL-4`: Screenshots — login, character select, character creation on Linux
- [ ] `AC-VAL-5`: Screenshots — Windows regression (login, select, create)

### Task 3: Quality Gate

- [x] `AC-STD-13`: `./ctl check` passes — clang-format 0 violations
- [x] `AC-STD-13`: `./ctl check` passes — cppcheck 0 errors
- [x] `AC-STD-1`: Code standards compliance verified

### Standard ACs

- [x] `AC-STD-15`: Git safety — no incomplete rebase, no force push to main
- [x] `AC-STD-16`: Catch2 v3.7.1 used, tests in `tests/` directory

---

## Test Files Created

| File | Status | Phase |
|------|--------|-------|
| `MuMain/tests/scenes/test_auth_character_validation.cpp` | Created | RED |
| `_bmad-output/test-scenarios/epic-6/auth-character-validation.md` | Created | Documentation |
| `MuMain/tests/CMakeLists.txt` | Updated — scenes/test_auth_character_validation.cpp registered | — |

---

## Notes

- **MUGame linkage path:** To enable the scene state tests, add `target_link_libraries(MuTests PRIVATE MUGame)` to `tests/CMakeLists.txt` AND `target_compile_definitions(MuTests PRIVATE MU_SCENE_TESTS_ENABLED)`. This requires MUGame to compile cleanly (all Win32 dependencies satisfied in CI environment).
- **AC-2 coverage:** SDL3 text input is already tested in `test_platform_text_input.cpp` (Story 2.2.3). No duplicate tests needed.
- **Manual validation (AC-VAL-1..5):** Requires a running MU Online test server. See Risk R17 in story dev notes.
- **CLASS_TYPE enum note:** Only the 5 base Season 5.2 classes are targeted for AC-4 validation (WIZARD, KNIGHT, ELF, DARK, DARK_LORD). Higher-tier classes (SUMMONER+) are not part of this story's scope.

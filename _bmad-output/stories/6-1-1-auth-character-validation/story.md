# Story 6.1.1: Authentication & Character Management Validation

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 6 - Cross-Platform Gameplay Validation |
| Feature | 6.1 - Core Loop |
| Story ID | 6.1.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | infrastructure |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-GAME-VALIDATE-AUTH |
| FRs Covered | FR23, FR24 |
| Prerequisites | EPIC-2 (windowing/input), EPIC-3 (networking), EPIC-4 (rendering) — all done |

**Story Types:** `backend_api` | `backend_service` | `frontend_feature` | `infrastructure` | `fullstack`

### Affected Components

<!-- Which components does this story modify? List ALL affected components from .pcc-config.yaml -->
<!-- The first backend/frontend listed becomes the primary target for quality gates -->

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add Catch2 test suite for auth/character flow validation on cross-platform builds |
| project-docs | documentation | Story artifacts, test scenarios, validation screenshots |

---

## Story

**[VS-1] [Flow:VS1-GAME-VALIDATE-AUTH]**

**As a** player on macOS/Linux,
**I want** login, character creation, and character selection to work correctly,
**so that** I can access my characters on any platform.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** Login screen displays correctly on macOS and Linux (SDL3 window, UI elements render, text fields accept input)
- [ ] **AC-2:** Username/password entry works via SDL3 text input (`g_szSDLTextInput` path through `CUITextInputBox`)
- [ ] **AC-3:** Character list loads and displays correctly after successful authentication (all character slots visible)
- [ ] **AC-4:** Character creation works for all 5 classes (Dark Wizard, Dark Knight, Fairy Elf, Magic Gladiator, Dark Lord)
- [ ] **AC-5:** Character selection and world entry work (select character → enter game world → character renders in-game)
- [ ] **AC-6:** Logout and character switch work (return to character select screen, select different character)

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy per project-context.md)
- [ ] **AC-STD-2:** Testing Requirements — Catch2 test suite validates auth/character flow logic where testable without live server
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format + cppcheck 0 errors)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 v3.7.1, `tests/` directory)

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check`)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Screenshots: login screen on macOS showing correct rendering and text input fields
- [ ] **AC-VAL-2:** Screenshots: character select screen on macOS showing character list
- [ ] **AC-VAL-3:** Screenshots: character creation screen on macOS (at least 1 class)
- [ ] **AC-VAL-4:** Same screenshots on Linux (login, character select, character creation)
- [ ] **AC-VAL-5:** Windows regression: same flows still work (login, select, create)
- [ ] **AC-VAL-6:** Test scenarios documented in `_bmad-output/test-scenarios/epic-6/`

---

## Tasks / Subtasks

- [ ] Task 1: Create test scenario documentation for auth/character validation (AC: VAL-6)
  - [ ] Subtask 1.1: Document manual test plan for login flow (macOS, Linux, Windows)
  - [ ] Subtask 1.2: Document manual test plan for character creation (all 5 classes)
  - [ ] Subtask 1.3: Document manual test plan for character selection and world entry
  - [ ] Subtask 1.4: Document manual test plan for logout/character switch
- [ ] Task 2: Create Catch2 test suite for auth/character validation logic (AC: 1-6, STD-2)
  - [ ] Subtask 2.1: Test login screen scene state initialization (`CNewUIMessageBoxMng`, `CLoginScene`)
  - [ ] Subtask 2.2: Test character list data parsing and display logic
  - [ ] Subtask 2.3: Test character creation class selection validation (5 classes)
  - [ ] Subtask 2.4: Test character switch / logout state transitions
- [ ] Task 3: Run quality gate and fix any violations (AC: STD-1, STD-13)
  - [ ] Subtask 3.1: Run `./ctl check` — fix clang-format violations
  - [ ] Subtask 3.2: Run `./ctl check` — fix cppcheck warnings
- [ ] Task 4: Manual validation on macOS (AC: VAL-1, VAL-2, VAL-3)
  - [ ] Subtask 4.1: Connect to test server, verify login screen renders
  - [ ] Subtask 4.2: Enter credentials, verify authentication succeeds
  - [ ] Subtask 4.3: Verify character list displays, create character (1 class minimum)
  - [ ] Subtask 4.4: Select character, verify world entry
  - [ ] Subtask 4.5: Logout, switch character
  - [ ] Subtask 4.6: Capture screenshots for validation artifacts
- [ ] Task 5: Manual validation on Linux (AC: VAL-4)
  - [ ] Subtask 5.1: Repeat Task 4 steps on Linux
  - [ ] Subtask 5.2: Capture screenshots for validation artifacts
- [ ] Task 6: Windows regression check (AC: VAL-5)
  - [ ] Subtask 6.1: Verify same flows work on Windows (no regression)

---

## Error Codes Introduced

N/A — This is a validation story; no new error codes are introduced.

---

## Contract Catalog Entries

N/A — This is a C++ game client validation story. No API, event, or navigation catalog entries apply.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 v3.7.1 | Logic coverage for scene state transitions | Login scene init, character list parsing, class validation, state transitions |
| Manual | Screenshots + checklist | All 6 ACs on 3 platforms | Login, character create (5 classes), select, world entry, logout, switch |
| Regression | Manual comparison | No regression on Windows | Same flows verified on Windows baseline |

---

## Dev Notes

### Architecture Context

- **Login flow:** `CLoginScene` manages the login UI state. `CNewUIMessageBoxMng` handles dialog prompts. SDL3 text input feeds credentials via `g_szSDLTextInput` → `CUITextInputBox::DoActionSub()`.
- **Character management:** `CCharacterScene` handles character list display and selection. Character creation uses class-specific data validated by the server. Network packets flow through the .NET AOT bridge (`ClientLibrary`).
- **Scene transitions:** `WinMain()` game loop drives scene state machine. Login → Character Select → In-Game are discrete scene states in the main loop.
- **Cross-platform dependencies:** All prerequisites satisfied:
  - EPIC-2 (SDL3 windowing/input) — login screen renders via SDL3 window, text input via SDL3 text input
  - EPIC-3 (.NET AOT networking) — server connectivity for authentication packets
  - EPIC-4 (rendering pipeline) — character models and UI render via SDL_GPU backend

### Key Source Files

| File | Purpose |
|------|---------|
| `src/source/Scenes/CLoginScene.cpp` | Login screen scene logic |
| `src/source/Scenes/CCharacterScene.cpp` | Character select/create scene |
| `src/source/ThirdParty/UIControls.cpp` | `CUITextInputBox` SDL3 text input |
| `src/source/Platform/sdl3/SDLEventLoop.cpp` | SDL3 event loop, text input handler |
| `src/source/Platform/sdl3/SDLKeyboardState.cpp` | `g_szSDLTextInput` buffer |
| `src/source/Dotnet/Connection.h` | .NET AOT bridge for server connectivity |
| `src/source/Main/Winmain.cpp` | Main game loop, scene state machine |

### Risk Items

- **R17 (from sprint-status):** All EPIC-6 stories require a running MU Online server for manual validation. Ensure test server is available before starting manual test tasks.
- **Server dependency:** Catch2 tests should validate logic that can be tested WITHOUT a live server (scene state initialization, data parsing, class validation). Manual validation requires server.

### PCC Project Constraints

- **Prohibited:** No raw `new`/`delete`, no `NULL`, no `timeGetTime()`, no `#ifdef _WIN32` in game logic, no `wchar_t` in new serialization
- **Required:** `std::unique_ptr`, `nullptr`, `std::chrono::steady_clock`, `std::filesystem::path`, `#pragma once`, Allman braces, 4-space indent
- **Quality gate:** `./ctl check` (clang-format 21.1.8 + cppcheck) — must pass 0 errors
- **Test organization:** `tests/{module}/test_{name}.cpp` mirroring `src/source/{Module}/`
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### Project Structure Notes

- Tests go in `MuMain/tests/` — e.g., `tests/scenes/test_auth_character_validation.cpp`
- Test binary: `MuTests` target, linked against `MUCore` (and potentially `MUGame` for scene logic)
- `MUCore` uses `file(GLOB)` — new `.cpp` files auto-discovered
- For scene-level tests, may need to link against `MUGame` or extract testable logic into `MUCore`

### Dependency Context

This is the **gate story** for EPIC-6 — it unblocks 4 downstream stories:
- 6-1-2 (world navigation) — sequential dependency
- 6-2-2 (inventory/trading) — parallel after this gate
- 6-3-1 (social systems) — parallel after this gate
- 6-4-1 (UI windows) — parallel after this gate

Completing this story validates the fundamental auth + character loop works cross-platform, which is the prerequisite for all other gameplay validation.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 6, Story 6.1.1]
- [Source: _bmad-output/project-context.md — C++ Language Rules, Testing Rules]
- [Source: sprint-status.yaml — Sprint 6 critical path analysis]
- [Source: CLAUDE.md — Build Commands, Conventions]

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

### Completion Notes List

- PCC create-story workflow completed — SAFe metadata and AC-STD sections included
- Story type: infrastructure (cross-platform validation, not frontend/backend feature)
- No API/event/navigation contracts (C++ game client, no REST endpoints)
- Schema alignment: N/A (C++ game client)
- Visual design specification: N/A (not a frontend_feature story)

### File List

- [CREATE] `MuMain/tests/scenes/test_auth_character_validation.cpp` — Catch2 test suite
- [CREATE] `_bmad-output/test-scenarios/epic-6/auth-character-validation.md` — Manual test scenarios
- [CREATE] `_bmad-output/stories/6-1-1-auth-character-validation/story.md` — This story file

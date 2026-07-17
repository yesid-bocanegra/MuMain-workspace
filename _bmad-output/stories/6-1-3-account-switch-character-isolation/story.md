# Story 6.1.3: Account Switch Character Isolation

**Status:** review
**Value Stream:** VS1-GAME-VALIDATE
**Flow Type:** Feature
**Flow Code:** VS1-GAME-VALIDATE-AUTH
**Story Points:** 3
**Priority:** Critical

## Story

As a player, I want character selection rebuilt from the current account list so that previous-account characters cannot remain visible or selectable.

## Discovery Context

**Source artifact:** `_bmad-output/findings/finding-2026-07-17-account-switch-stale-characters.md`
**Discovery type:** bug

## Acceptance Criteria

- [x] Receiving a character list clears prior character objects first.
- [x] Selected character and hero indices reset before list population.
- [x] Only characters returned for the current account remain selectable.
- [x] Targeted regression check passes.

## Affected Components

| Component | Files |
|---|---|
| mumain | `src/source/Network/Server/WSclient.cpp` |
| tests | focused account-switch regression check |
| documentation | source finding |

## Tasks

- [x] Add failing regression check.
- [x] Reset stale character state before list population.
- [x] Run targeted validation.

## Verification

- `tests/stability/test_account_social_state.sh` — pass after observed RED failure.
- `cmake --build --preset macos-arm64-debug -j2` — pass.
- Full CTest: 77/82 pass; five unrelated existing platform-policy tests fail.

## PCC Project Constraints

Follow `_bmad-output/project-context.md`, `docs/development-standards.md`, and `MuMain/docs/CODING_RULES.md`.

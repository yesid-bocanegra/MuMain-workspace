# Story 6.3.3: Friend Invite Stability

**Status:** review
**Value Stream:** VS1-GAME-VALIDATE
**Flow Type:** Feature
**Flow Code:** VS1-GAME-VALIDATE-SOCIAL
**Story Points:** 3
**Priority:** Critical

## Story

As a player, I want sending a friend invite to be memory-safe so that normal social actions never terminate the client.

## Discovery Context

**Source artifact:** `_bmad-output/findings/finding-2026-07-17-friend-invite-crash.md`
**Discovery type:** bug

## Acceptance Criteria

- [x] Friend names cross the deferred UI boundary as owned values, not manually managed raw pointers.
- [x] Submit by Enter and OK uses one owned-value request path.
- [x] Empty input sends no request.
- [x] Targeted regression check passes.

## Affected Components

| Component | Files |
|---|---|
| mumain | `src/source/UI/Legacy/UIWindows.h`, `src/source/UI/Legacy/UIWindows.cpp` |
| tests | focused friend-invite regression check |
| documentation | source finding |

## Tasks

- [x] Add failing regression check.
- [x] Replace raw-pointer UI payload with owned text.
- [x] Run targeted validation.

## Verification

- `tests/stability/test_account_social_state.sh` — pass after observed RED failure.
- `cmake --build --preset macos-arm64-debug -j2` — pass.
- Full CTest: 77/82 pass; five unrelated existing platform-policy tests fail.

## PCC Project Constraints

Follow `_bmad-output/project-context.md`, `docs/development-standards.md`, and `MuMain/docs/CODING_RULES.md`.

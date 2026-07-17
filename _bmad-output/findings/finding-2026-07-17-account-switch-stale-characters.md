# Switching accounts leaves previous characters selectable

**Date:** 2026-07-17
**Discovered during:** User-reported runtime bug review
**Context:** Standalone review of social-system and account-switch failures
**Discovery type:** bug
**Urgency:** this-sprint
**Urgency justification:** Client shows and permits selection of stale account data, creating an authorization-boundary and account-isolation failure.

## Summary

The character-list receiver creates or overwrites only slots returned for the newly authenticated account. It does not clear live character slots from the previous account first, so old character objects remain visible and selectable when the next account has fewer or differently populated slots.

## Root Causes

### RCA-1: Character-list replacement is implemented as a partial overwrite

**What:** `ReceiveCharacterListExtended` loops over the new response and calls `CreateHero` for those entries, but never clears the existing selection-scene characters before applying the authoritative list.
**Evidence:** `MuMain/src/source/Network/Server/WSclient.cpp:676` starts list handling; `MuMain/src/source/Network/Server/WSclient.cpp:691` iterates only `CharacterCount`; `MuMain/src/source/Network/Server/WSclient.cpp:708` creates returned slots; no `ClearCharacters()` call occurs before the loop. `MuMain/src/source/Engine/Object/ZzzCharacter.cpp:11415` provides the existing cleanup function.
**Affected scope:** Account changes, reconnect/login reuse, character-selection rendering and input.
**Proposed fix:** Clear all character-selection objects and selection indices immediately before applying a newly received authoritative character list.
**Estimated lines:** ~5 lines across 1 file

### RCA-2: Selection validates slot bounds, not membership in the current account list

**What:** Click and start-game checks accept any live index within `MAX_CHARACTERS_PER_ACCOUNT`; they do not validate that the slot was populated by the current list response.
**Evidence:** `MuMain/src/source/Scenes/CharacterScene.cpp:215` and `MuMain/src/source/Scenes/CharacterScene.cpp:225` validate only numeric bounds. `MuMain/src/source/Input/Selection.cpp:125` selects any live, visible object. Stale objects remain eligible because the receiver did not invalidate them.
**Affected scope:** Character hover, click, double-click, Enter-to-start, and `SendSelectCharacter` input.
**Proposed fix:** Treat list replacement cleanup as the primary fix, then track current-list membership or character count and validate it before `StartGame` as defense in depth.
**Estimated lines:** ~15 lines across 2 files

## Implementation Plan

1. Change `WSclient.cpp` to clear prior character objects and reset `SelectedCharacter`/`SelectedHero` before processing `ReceiveCharacterListExtended`.
2. Record current authoritative slot membership or count while parsing the response.
3. Change `CharacterScene.cpp` to require current-list membership before copying attributes or changing scenes.
4. Add a focused regression test or runnable harness where account A has five characters and account B has one.

## Post-Fix Verification

1. Log in as account A with multiple characters and return to login using Change Account.
2. Log in as account B with fewer characters.
3. Confirm only account B characters render, highlight, and respond to clicks.
4. Click prior account A slot locations and press Enter; expected result is no selection and no `SendSelectCharacter` request.
5. Select account B character; expected result is normal game entry.

## Scope Assessment

**Type:** bug
**Story count:** 1 story
**Epic home:** authentication and character lifecycle
**Milestone relevance:** Runtime stability and account isolation
**Estimated points:** 3

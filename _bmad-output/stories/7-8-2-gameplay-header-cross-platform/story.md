# Story 7.8.2: Gameplay Header Cross-Platform Fixes

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.8 - Remaining Build Blockers |
| Story ID | 7.8.2 |
| Story Points | 5 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-BUILD-HEADERS |
| FRs Covered | Cross-platform parity — gameplay headers must compile on macOS and Linux |
| Prerequisites | 7-6-1-macos-native-build-compilation (done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Fix ODR violation in `Core/mu_enum.h` (non-inline map), missing includes in `World/ZzzPath.h`, `Skill/SkillStructs.h`, `Item/CSItemOption.h` |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** gameplay headers to include all their dependencies and not violate the ODR,
**so that** TUs that include `mu_enum.h`, `ZzzPath.h`, `SkillStructs.h`, and `CSItemOption.h` compile and link without errors on all platforms.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `Core/mu_enum.h` — `SKILL_REPLACEMENTS` constant map is declared `inline` (C++17) to avoid multiple-definition linker errors when included by more than one TU.
  - Before: `const std::map<ActionSkillType, ActionSkillType> SKILL_REPLACEMENTS = {...};`
  - After: `inline const std::map<ActionSkillType, ActionSkillType> SKILL_REPLACEMENTS = {...};`
- [ ] **AC-2:** `World/ZzzPath.h` — all usages of `g_ErrorReport.Write(...)` are preceded by `#include "Core/ErrorReport.h"` (or the appropriate relative path). No implicit reliance on transitive includes.
- [ ] **AC-3:** `Skill/SkillStructs.h` — `CMultiLanguage` type is properly included (or forward-declared if only used by pointer/reference). No bare use of undefined type.
- [ ] **AC-4:** `Item/CSItemOption.h` — `ActionSkillType` and `ITEM` types are properly included. No bare use of undefined types.
- [ ] **AC-5:** `cmake --build --preset macos-arm64-debug` succeeds with 0 errors for all TUs that previously failed due to these header issues.
- [ ] **AC-6:** `./ctl check` passes — build + tests + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — added `#include` directives use forward-slash paths; clang-format clean.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Fix ODR violation in `Core/mu_enum.h`** (AC-1)
  - [ ] 1.1: Add `inline` keyword to `SKILL_REPLACEMENTS` declaration
  - [ ] 1.2: Verify no other non-inline variable definitions exist at namespace scope in `mu_enum.h`

- [ ] **Task 2: Fix missing includes in `World/ZzzPath.h`** (AC-2)
  - [ ] 2.1: Identify all `g_ErrorReport` usages and their line numbers
  - [ ] 2.2: Add `#include "Core/ErrorReport.h"` at top of file (after existing includes)
  - [ ] 2.3: Verify no circular include is introduced

- [ ] **Task 3: Fix missing includes in `Skill/SkillStructs.h`** (AC-3)
  - [ ] 3.1: Identify `CMultiLanguage` usage and required header
  - [ ] 3.2: Add include or forward declaration as appropriate

- [ ] **Task 4: Fix missing includes in `Item/CSItemOption.h`** (AC-4)
  - [ ] 4.1: Identify `ActionSkillType` and `ITEM` usage and required headers
  - [ ] 4.2: Add includes or forward declarations as appropriate

- [ ] **Task 5: Verify build** (AC-5, AC-6)
  - [ ] 5.1: Run `cmake --build --preset macos-arm64-debug` — confirm 0 errors from these headers
  - [ ] 5.2: Run `./ctl check`

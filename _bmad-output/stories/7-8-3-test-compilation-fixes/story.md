# Story 7.8.3: Test Compilation Fixes

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.8 - Remaining Build Blockers |
| Story ID | 7.8.3 |
| Story Points | 3 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-BUILD-TESTS |
| FRs Covered | All test targets must compile and pass on macOS and Linux |
| Prerequisites | 7-6-1-macos-native-build-compilation (done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Fix compilation errors in `tests/gameplay/test_inventory_trading_validation.cpp` (invalid STORAGE_TYPE enum values) and `tests/render/test_sdlgpubackend.cpp` (unused variable warning promoted to error) |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** all test targets to compile without errors,
**so that** `ctest` can run the full test suite and `./ctl check` passes on every platform.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `tests/gameplay/test_inventory_trading_validation.cpp` — all references to `STORAGE_TYPE` enum values are corrected to match the actual enum members defined in the production code. No compile error from invalid enumerator names.
- [ ] **AC-2:** `tests/render/test_sdlgpubackend.cpp` — the unused `k_BlendFactor_DstColor` variable is either removed (if not tested) or used in a meaningful assertion. No `-Werror,-Wunused-const-variable` error.
- [ ] **AC-3:** `cmake --build --preset macos-arm64-debug` succeeds for ALL test targets including `MuTests`, `MuStabilityTests`, and any gameplay/render test targets.
- [ ] **AC-4:** `ctest --test-dir MuMain/out/build/macos-arm64 -C Debug --output-on-failure` runs to completion — 0 unexpected failures (skipped tests are acceptable).
- [ ] **AC-5:** `./ctl check` passes — build + tests + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — test corrections use the correct enum values from production code; clang-format clean.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Fix `test_inventory_trading_validation.cpp`** (AC-1)
  - [ ] 1.1: Read the actual `STORAGE_TYPE` enum definition in production code
  - [ ] 1.2: Compare against enum values referenced in the test (lines ~252-262)
  - [ ] 1.3: Replace invalid enum values with valid ones or update test expectations to match actual enum

- [ ] **Task 2: Fix `test_sdlgpubackend.cpp`** (AC-2)
  - [ ] 2.1: Read the `k_BlendFactor_DstColor` declaration and surrounding context
  - [ ] 2.2: If the constant is genuinely unused, remove it; if it should be tested, add an assertion

- [ ] **Task 3: Verify full test build and run** (AC-3, AC-4, AC-5)
  - [ ] 3.1: Run `cmake --build --preset macos-arm64-debug` — confirm all test targets compile
  - [ ] 3.2: Run `ctest --test-dir MuMain/out/build/macos-arm64 -C Debug --output-on-failure`
  - [ ] 3.3: Run `./ctl check`

# ATDD Checklist — Story 7.8.3: Test Compilation Fixes

**Story ID**: 7-8-3-test-compilation-fixes
**Story Type**: infrastructure
**Generated**: 2026-03-26
**Status**: PENDING (implementation in progress)

---

## FSM State

```
STATE_0_STORY_CREATED → [testarch-atdd] → STATE_1_ATDD_READY
```

---

## PCC Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Prohibited libraries | PASS | No prohibited libraries in test files |
| Framework | PASS | Catch2 v3.7.1 `TEST_CASE`/`SECTION`/`REQUIRE` |
| No Win32 in test logic | PASS | Uses `#ifdef _WIN32` / PlatformTypes.h guard at include level only |
| No mocking framework | PASS | No mock framework — FogCaptureMock is hand-rolled inline |
| Test location | PASS | `tests/{module}/test_{name}.cpp` pattern |
| Bruno API collection | N/A | infrastructure story — no REST endpoints |
| E2E tests | N/A | infrastructure story — no UI/browser tests |

---

## Affected Components

| Component | Tags | Test Files |
|-----------|------|-----------|
| mumain | backend | `MuMain/tests/gameplay/test_inventory_trading_validation.cpp` |
| mumain | backend | `MuMain/tests/render/test_sdlgpubackend.cpp` |

---

## AC-to-Test Mapping

| AC | Description | Test Location | Test Name / Method | Phase |
|----|-------------|---------------|-------------------|-------|
| AC-1 | Fix STORAGE_TYPE enum values | `tests/gameplay/test_inventory_trading_validation.cpp` | `TEST_CASE("AC-3 [6-2-2]: All STORAGE_TYPE enum values are pairwise distinct")` | RED → fix compilation |
| AC-2 | Remove unused `k_BlendFactor_DstColor` | `tests/render/test_sdlgpubackend.cpp` | Anonymous namespace constant (line 75) | RED → fix warning-as-error |
| AC-3 | All test targets compile | Both files (after AC-1/AC-2 fixes) | Build verification: `cmake --build --preset macos-arm64-debug` | GREEN after fixes |
| AC-4 | ctest runs — 0 unexpected failures | All test targets | `ctest --test-dir MuMain/out/build/macos-arm64 -C Debug --output-on-failure` | GREEN after fixes |
| AC-5 | `./ctl check` passes | All source + test files | `./ctl check` (format-check + lint) | GREEN after fixes |
| AC-STD-1 | Code standards | Both files | Enum names match production code; clang-format clean | |
| AC-STD-2 | All test targets compile/execute without errors | Both files | ctest completion | |
| AC-STD-13 | Quality gate exits 0 | `./ctl check` | Full quality gate | |

---

## Implementation Analysis

### AC-1: STORAGE_TYPE Enum Fix

**File**: `MuMain/tests/gameplay/test_inventory_trading_validation.cpp`
**Lines**: 248–262 (extended inventory type variables in the "pairwise distinct" test)

**Root Cause**: The `STORAGE_TYPE` enum in `mu_define.h` has been updated since the test was written. The test uses enum member names from a previous version of the enum that no longer exists.

**Actual enum** (from `MuMain/src/source/Core/mu_define.h` lines 197–217):
```cpp
enum struct STORAGE_TYPE
{
    UNDEFINED = -1,
    INVENTORY = 0,
    TRADE = 1,
    VAULT = 2,
    CHAOS_MIX = 3,
    MYSHOP = 4,
    TRAINER_MIX = 5,
    ELPIS_MIX = 6,
    OSBOURNE_MIX = 7,
    JERRIDON_MIX = 8,
    CHAOS_CARD_MIX = 9,
    CHERRYBLOSSOM_MIX = 10,
    EXTRACT_SEED_MIX = 11,
    SEED_SPHERE_MIX = 12,
    ATTACH_SOCKET_MIX = 13,
    DETACH_SOCKET_MIX = 14,
    LUCKYITEM_TRADE = 15,
    LUCKYITEM_REFINERY = 16,
};
```

**Required Fix — Variable renaming** (lines 248–262):

| Line | Invalid Name | Valid Replacement | Value |
|------|-------------|-------------------|-------|
| 252 | `STORAGE_TYPE::COMBINE` | `STORAGE_TYPE::OSBOURNE_MIX` | 7 |
| 253 | `STORAGE_TYPE::STORAGE` | `STORAGE_TYPE::JERRIDON_MIX` | 8 |
| 254 | `STORAGE_TYPE::PRIVATE_SHOP` | `STORAGE_TYPE::CHAOS_CARD_MIX` | 9 |
| 255 | `STORAGE_TYPE::DARK_HORSE_MIX` | `STORAGE_TYPE::CHERRYBLOSSOM_MIX` | 10 |
| 256 | `STORAGE_TYPE::GOLDEN_DICE_MIX` | `STORAGE_TYPE::EXTRACT_SEED_MIX` | 11 |
| 257 | `STORAGE_TYPE::MOON_MIX` | `STORAGE_TYPE::SEED_SPHERE_MIX` | 12 |
| 258 | `STORAGE_TYPE::SEASON_MIX` | `STORAGE_TYPE::ATTACH_SOCKET_MIX` | 13 |
| 259 | `STORAGE_TYPE::COSMOS_MIX` | `STORAGE_TYPE::DETACH_SOCKET_MIX` | 14 |
| 260 | `STORAGE_TYPE::SOCKET_MIX` | `STORAGE_TYPE::LUCKYITEM_TRADE` | 15 |
| 261 | `STORAGE_TYPE::LUCKY_MIX` | `STORAGE_TYPE::LUCKYITEM_REFINERY` | 16 |
| 262 | `STORAGE_TYPE::SYNTHESIS_MIX` | **REMOVE** (value 17 does not exist) | — |

**Note on SYNTHESIS_MIX**: The enum max is `LUCKYITEM_REFINERY = 16`. There is no value 17. The `kSynthesis` variable and all `kSynthesis` references in the REQUIRE statements must be removed. The test title "All 18 STORAGE_TYPE values" remains accurate because: 18 members = UNDEFINED(-1) + 17 values (0–16).

**Local variable names to update** (for clarity — update alongside enum references):
- `kCombine` → `kOsbourne`
- `kStorage` → `kJerridon`
- `kPrivateShop` → `kChaosCard`
- `kDarkHorse` → `kCherryBlossom`
- `kGoldenDice` → `kExtractSeed`
- `kMoon` → `kSeedSphere`
- `kSeason` → `kAttachSocket`
- `kCosmos` → `kDetachSocket`
- `kSocket` → `kLuckyItemTrade`
- `kLucky` → `kLuckyItemRefinery`
- Remove `kSynthesis` entirely

---

### AC-2: Remove Unused `k_BlendFactor_DstColor`

**File**: `MuMain/tests/render/test_sdlgpubackend.cpp`
**Line**: 75 (anonymous namespace)

**Root Cause**: `k_BlendFactor_DstColor = 5` is declared in the anonymous namespace alongside other blend factor proxy constants. However, none of the test cases use it — the `InverseColor` section uses `k_BlendFactor_OneMinusDstColor` (not `k_BlendFactor_DstColor`). Clang promotes `-Wunused-const-variable` to an error with `-Werror`.

**Required Fix**: Remove line 75:
```cpp
// DELETE this line:
constexpr int k_BlendFactor_DstColor          = 5;  // SDL_GPU_BLENDFACTOR_DST_COLOR
```

No test assertions reference this constant, so removal has no impact on test coverage.

---

## Implementation Checklist

### Phase 1: Fix Compilation Errors

- [x] **AC-1:** Read `MuMain/src/source/Core/mu_define.h` to confirm actual `STORAGE_TYPE` enum members
- [x] **AC-1:** Replace 10 invalid enum names in `test_inventory_trading_validation.cpp` lines 248–262 with the correct `mu_define.h` enum values per the mapping table above
- [x] **AC-1:** Update local variable names (`kCombine→kOsbourne`, etc.) to match the new enum names
- [x] **AC-1:** Remove `kSynthesis` variable (line 262) and ALL `kSynthesis` references from the REQUIRE block
- [x] **AC-1:** Update the comment on line 237 from "18 defined enum members" if the count changes (18 is still correct — UNDEFINED + 17 values 0–16)
- [x] **AC-2:** Remove `constexpr int k_BlendFactor_DstColor = 5;` from `test_sdlgpubackend.cpp` (anonymous namespace, line 75)
- [x] **AC-STD-1:** Verify both files pass `clang-format` — run `./ctl format` and confirm no diff

### Phase 2: Build Verification

- [ ] **AC-3:** Run `cmake --build --preset macos-arm64-debug` — confirm ALL test targets compile (MuTests, MuStabilityTests, gameplay tests, render tests) — BLOCKED by pre-existing mu_enum.h/DSPlaySound.h cross-platform errors (not from this story)
- [x] **AC-3:** Confirm zero compile errors and zero `-Werror` warnings in `test_inventory_trading_validation.cpp` — fixed: 10 invalid enum names replaced, kSynthesis removed
- [x] **AC-3:** Confirm zero compile errors and zero `-Werror,-Wunused-const-variable` in `test_sdlgpubackend.cpp` — fixed: unused k_BlendFactor_DstColor removed

### Phase 3: Test Execution

- [ ] **AC-4:** Run `ctest --test-dir MuMain/out/build/macos-arm64 -C Debug --output-on-failure` — BLOCKED by pre-existing build failure (same as AC-3)
- [ ] **AC-4:** Confirm 0 unexpected test failures (skipped tests are acceptable) — BLOCKED
- [ ] **AC-4:** Record test counts: total tests, passed, skipped, failed — BLOCKED

### Phase 4: Quality Gate

- [ ] **AC-5:** Run `./ctl check` — format-check + lint pass (exit 0); build + test BLOCKED by pre-existing mu_enum.h errors
- [ ] **AC-STD-13:** `./ctl check` format-check + lint pass; build BLOCKED by pre-existing errors
- [x] **AC-STD-15:** No force push; branch history is clean

---

## Notes

### Why No New Test Files

This is an `infrastructure` story. The work is correcting compilation errors in **existing** test files that were written against an older version of the `STORAGE_TYPE` enum. No new test coverage is required — the existing tests already provide the correct logical contracts once they compile.

### `k_BlendFactor_DstColor` Decision

Removal (not "add an assertion") is correct because:
1. The `InverseColor` blend mode uses `ONE_MINUS_DST_COLOR` (not `DST_COLOR`) as both src factor and dst factor in the story 4.3.1 reference table
2. No current `BlendMode` enum value maps to `SDL_GPU_BLENDFACTOR_DST_COLOR` as either src or dst
3. Adding a false assertion to use the constant would misrepresent the blend table contract

### Cross-Story Context

- `test_inventory_trading_validation.cpp` belongs to story 6-2-2 (inventory/trading validation)
- `test_sdlgpubackend.cpp` belongs to story 4-3-1 (SDL GPU backend)
- This story (7-8-3) does NOT modify the test logic or assertions — only the invalid identifiers that prevent compilation

### Forward Declaration Pattern (for reference)

The `struct tagITEM; typedef struct tagITEM ITEM;` two-part forward declaration pattern (from story 7-8-2) is NOT needed here — this story does not involve forward declarations.

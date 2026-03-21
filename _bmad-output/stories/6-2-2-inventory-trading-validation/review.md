# Code Review: Story 6.2.2 — Inventory, Trading & Shops Validation

**Story Key:** 6-2-2-inventory-trading-validation
**Reviewer:** Claude Opus 4.6 (Adversarial Code Review)
**Date:** 2026-03-21
**Review Type:** Adversarial — find and document issues only

---

## Pipeline Status

| Step | Status |
|------|--------|
| 1. Quality Gate | PASSED |
| 2. Code Review Analysis | COMPLETE |
| 3. Code Review Finalize | Pending |

## Quality Gate

**Status:** PASSED
**Date:** 2026-03-21
**Component:** mumain (cpp-cmake)

| Check | Result | Notes |
|-------|--------|-------|
| format-check (`make -C MuMain format-check`) | PASSED | 0 violations |
| lint (`make -C MuMain lint`) | PASSED | 0 violations |
| build | SKIPPED | macOS cannot compile Win32/DirectX (skip_checks config) |
| test | SKIPPED | macOS cannot compile Win32/DirectX (skip_checks config) |
| coverage | N/A | Infrastructure story, no coverage threshold |
| SonarCloud | N/A | No sonar command configured for cpp-cmake profile |
| Schema Alignment | N/A | No frontend component |
| AC Tests | SKIPPED | Infrastructure story — no AC tests required |
| E2E Test Quality | N/A | No frontend component |
| App Startup | N/A | Game client (Win32), not a server application |

**Quality Gate Progress:**
- Backend Local: PASSED (0 iterations, 0 issues fixed)
- Backend SonarCloud: N/A
- Frontend Local: N/A (no frontend components)
- Frontend SonarCloud: N/A

---

## Findings

### Finding 1 — MEDIUM: ATDD Test Count Discrepancy

**File:** `_bmad-output/stories/6-2-2-inventory-trading-validation/atdd.md` (lines 88-93)
**Also:** `_bmad-output/stories/6-2-2-inventory-trading-validation/story.md` (line 246)

**Description:** The ATDD "Test Counts" summary states "15 always-on + 5 game-gated = 20 TEST_CASEs." The actual test file contains **24 TEST_CASEs** (18 always-on + 6 game-gated). The ATDD's own AC-to-Test Mapping table correctly enumerates all 24 tests but contradicts the summary. The story's File List and Completion Notes also repeat the incorrect "20 TEST_CASEs" claim.

**Impact:** Documentation inaccuracy could cause confusion during future regression analysis or sprint reporting. A reviewer relying on the summary would believe 4 tests are missing.

**Suggested Fix:** Update ATDD Test Counts section to "18 always-on + 6 game-gated = 24 TEST_CASEs." Update story.md File List and Completion Notes to match.

---

### Finding 2 — MEDIUM: AC-4 Trade Grid Test Contains Vacuous Tautology

**File:** `MuMain/tests/gameplay/test_inventory_trading_validation.cpp` (lines 344-346)

**Description:** The trade grid invariant test uses `static_assert(8 * 4 == 32, ...)` followed by `REQUIRE(8 * 4 == 32)`. Both assertions test an arithmetic identity using hardcoded literals — they will always pass regardless of game state. No actual game constants are referenced. The comment acknowledges the trade constants (COLUMN_TRADE_INVEN, ROW_TRADE_INVEN, MAX_TRADE_INVEN) are private enums in `CNewUITrade` and cannot be tested directly.

The only meaningful assertions in this TEST_CASE are:
- Line 352: `REQUIRE(COLUMN_INVENTORY == 8)` — already tested in AC-1 (line 77)
- Line 358: `REQUIRE(ROW_INVENTORY_EXT == 4)` — already tested in AC-1 (line 101)

**Impact:** The test creates a false sense of coverage for AC-4. The `static_assert` and `REQUIRE` with literal `8 * 4 == 32` can never fail and validate nothing about the actual trade grid implementation.

**Suggested Fix:** Remove the vacuous `static_assert` and `REQUIRE(8 * 4 == 32)`. Keep the SECTION but rename it to document the architectural constraint (e.g., "Trade grid reuses inventory column width and extended row count"). Alternatively, add a comment explicitly noting this is a documentation-only assertion since the constants are private.

---

### Finding 3 — MEDIUM: Incomplete STORAGE_TYPE Pairwise Distinctness

**File:** `MuMain/tests/gameplay/test_inventory_trading_validation.cpp` (lines 233-254)

**Description:** The pairwise distinctness test covers 5 of 18 STORAGE_TYPE enum values (UNDEFINED, INVENTORY, TRADE, VAULT, MYSHOP). The full enum in `mu_define.h:197-217` defines 18 values including CHAOS_MIX(3), TRAINER_MIX(5), ELPIS_MIX(6), and 10 others. All 18 values are defined in `mu_define.h` which is included without platform guards, so all are testable.

Notable gap: CHAOS_MIX(3) sits directly between VAULT(2) and MYSHOP(4) in the tested range but is excluded from distinctness checks.

**Impact:** If a future enum edit accidentally assigns a duplicate value to one of the 13 untested members, the pairwise distinctness test would not catch it. The test title implies comprehensive drag-and-drop validation but only covers a subset.

**Suggested Fix:** Either (a) extend the pairwise distinctness test to cover all 18 STORAGE_TYPE values, or (b) rename the test to clarify scope (e.g., "core drag-and-drop storage types are pairwise distinct") and add a comment listing which values are intentionally excluded.

---

### Finding 4 — LOW: Duplicate Assertions Between AC-2 and AC-6

**File:** `MuMain/tests/gameplay/test_inventory_trading_validation.cpp`
**Lines:** 163-182 (AC-2) vs 542-554 (AC-6)

**Description:** The AC-2 test "CSItemOption set-equip constants derived from equipment slot count" validates:
- `MAX_EQUIPPED_SET_ITEMS == MAX_EQUIPMENT_INDEX - 2` (== 10)
- `MAX_EQUIPPED_SETS == MAX_EQUIPPED_SET_ITEMS / 2` (== 5)

The AC-6 test "CSItemOption item-set constants derived from equipment count are correct" validates:
- `MAX_EQUIPPED_SET_ITEMS == 10`
- `MAX_EQUIPPED_SETS == 5`

AC-6 is a strict subset of AC-2 — it checks the same constants with the same expected values but without the derived-relationship validation. The AC-6 version adds no new coverage.

**Impact:** Minor test bloat. The duplication inflates the test count and could cause confusion about which test is authoritative for these constants.

**Suggested Fix:** Remove the AC-6 duplicate test (lines 542-554). The AC-2 version already validates both the derived relationships and the literal values.

---

### Finding 5 — LOW: Redundant static_assert + REQUIRE Pattern

**File:** `MuMain/tests/gameplay/test_inventory_trading_validation.cpp` (lines 345-346)

**Description:** Line 345 uses `static_assert(8 * 4 == 32, ...)` for compile-time validation. Line 346 immediately follows with `REQUIRE(8 * 4 == 32)` which is a runtime assertion of the same expression. If the `static_assert` passes (compilation succeeds), the `REQUIRE` can never fail. This pattern is redundant.

**Impact:** No functional impact — the redundancy is harmless but misleading. It suggests runtime validation where only compile-time validation exists.

**Suggested Fix:** Keep only the `static_assert` (preferred for compile-time-known values) or only the `REQUIRE` (if runtime test registration matters for reporting). Do not use both on the same constant expression.

---

## ATDD Coverage

### ATDD Checklist Accuracy

| Aspect | Status | Detail |
|--------|--------|--------|
| Implementation checklist items (32) | PASS | All 32 items verified against test file — each has corresponding code |
| AC-to-Test Mapping table | PASS | Correctly enumerates all 24 TEST_CASEs across 6 ACs |
| Test Counts summary | FAIL | States "20 TEST_CASEs (15+5)" — actual is 24 (18+6) |
| PCC Compliance Summary | PASS | All categories correctly assessed |
| Code Standards checklist | PASS | Allman braces, 4-space indent, nullptr, Catch2 patterns verified |

### AC Coverage Summary

| AC | Automated Tests | Manual Scenarios | Coverage Assessment |
|----|----------------|------------------|---------------------|
| AC-1 | 4 TEST_CASEs | Scenario 1 | Adequate — constants and array dimensions validated |
| AC-2 | 3 TEST_CASEs (2 always-on + 1 gated) | Scenario 2 | Adequate — equipment slots and derived constants validated |
| AC-3 | 4 TEST_CASEs (2 always-on + 2 gated) | Scenario 3 | Partial — STORAGE_TYPE coverage gap (5/18 values) |
| AC-4 | 2 TEST_CASEs (1 always-on + 1 gated) | Scenario 4 | Weak — trade grid test uses vacuous tautology |
| AC-5 | 3 TEST_CASEs (1 always-on + 2 gated) | Scenario 5 | Adequate — shop states and personal shop modes validated |
| AC-6 | 8 TEST_CASEs (all always-on) | Scenario 6 | Good — struct layouts, CSItemOption regression, and uniqueness validated |

### Disposition

No BLOCKERs or HIGH severity issues found. Three MEDIUM issues relate to documentation accuracy and test quality. Two LOW issues are minor redundancies. The implementation is fundamentally sound for an infrastructure validation story.

---

*Review generated by adversarial code review workflow — issues documented only, not fixed.*

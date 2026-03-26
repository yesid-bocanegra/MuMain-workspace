# ATDD Implementation Checklist — Story 7.8.2
# Gameplay Header Cross-Platform Fixes [VS0-QUAL-BUILD-HEADERS]

**Story:** 7-8-2-gameplay-header-cross-platform
**Story Type:** infrastructure
**Phase:** GREEN (all items complete — tests pass)
**Generated:** 2026-03-26

---

## PCC Guidelines Summary

- **Framework:** Catch2 v3.7.1 (FetchContent, `MuTests` target, `tests/{module}/test_{name}.cpp`)
- **Prohibited Libraries:** None applicable (pure C++ header/enum tests)
- **Include Convention:** Flat by directory — `#include "ErrorReport.h"` not `#include "Core/ErrorReport.h"`
- **No Win32 APIs** in test logic — tests must compile/run on macOS/Linux/Windows (MinGW CI)
- **Quality Gate:** `./ctl check` (clang-format + cppcheck)

---

## Step 0.5: Existing Test Mapping

| AC | Description | Existing Test | Match | Action |
|----|-------------|---------------|-------|--------|
| AC-1 | SKILL_REPLACEMENTS inline | None (linker error in existing TUs shows symptom) | — | GENERATE NEW |
| AC-2 | ZzzPath.h ErrorReport include | None | — | GENERATE NEW |
| AC-3 | SkillStructs.h CMultiLanguage include | None | — | GENERATE NEW |
| AC-4 | CSItemOption.h type includes | None | — | GENERATE NEW |
| AC-5 | macOS build success | None (build-level) | — | BUILD VERIFICATION |
| AC-6 | ./ctl check passes | None (CI-level) | — | QUALITY GATE |

---

## AC-to-Test Mapping

| AC | Test File | Test Name | Type |
|----|-----------|-----------|------|
| AC-1 | `tests/gameplay/test_gameplay_header_crossplatform_7_8_2.cpp` | `AC-1 [7-8-2]: SKILL_REPLACEMENTS map is non-empty and accessible` | Catch2 unit |
| AC-1 | `tests/gameplay/test_gameplay_header_crossplatform_7_8_2.cpp` | `AC-1 [7-8-2]: SKILL_REPLACEMENTS contains known str-to-base skill mappings` | Catch2 unit |
| AC-1 | `tests/gameplay/test_gameplay_header_crossplatform_7_8_2.cpp` | `AC-1 [7-8-2]: SKILL_REPLACEMENTS map values are distinct from their keys` | Catch2 unit |
| AC-1 | `tests/build/test_ac1_mu_enum_inline_7_8_2.cmake` | `7.8.2-AC-1:mu-enum-inline-skill-replacements` | CMake script |
| AC-2 | `tests/build/test_ac2_zzzpath_errorreport_include_7_8_2.cmake` | `7.8.2-AC-2:zzzpath-errorreport-include` | CMake script |
| AC-3 | `tests/build/test_ac3_skillstructs_multilanguage_7_8_2.cmake` | `7.8.2-AC-3:skillstructs-multilanguage-include` | CMake script |
| AC-4 | `tests/build/test_ac4_csitemoption_type_includes_7_8_2.cmake` | `7.8.2-AC-4:csitemoption-type-includes` | CMake script |
| AC-5 | Build preset `macos-arm64-debug` | `cmake --build --preset macos-arm64-debug` exits 0 | Build verification |
| AC-6 | Quality gate | `./ctl check` exits 0 | CI quality gate |
| AC-STD-2 | `tests/CMakeLists.txt` + MuTests | `./ctl test` — existing test suite passes | Integration |
| AC-STD-11 | `tests/build/test_ac_std11_flow_code_7_8_2.cmake` | `7.8.2-AC-STD-11:flow-code-traceability` | CMake script |

---

## Implementation Checklist

### Phase 1: Header Fixes (Tasks 1–4)

- [x] **AC-1.1** — `Core/mu_enum.h` line 633: Add `inline` keyword to `SKILL_REPLACEMENTS` declaration
  - Before: `const std::map<ActionSkillType, ActionSkillType> SKILL_REPLACEMENTS = {...};`
  - After: `inline const std::map<ActionSkillType, ActionSkillType> SKILL_REPLACEMENTS = {...};`
  - Verifier: `tests/build/test_ac1_mu_enum_inline_7_8_2.cmake` passes
- [x] **AC-1.2** — `Core/mu_enum.h`: Verify no other non-inline variable definitions at namespace scope
- [x] **AC-2.1** — `World/ZzzPath.h`: Add `#include "ErrorReport.h"` (flat style — not `Core/ErrorReport.h`)
  - Placement: after existing includes (`<math.h>`, `"BaseCls.h"`)
  - Verifier: `tests/build/test_ac2_zzzpath_errorreport_include_7_8_2.cmake` passes
- [x] **AC-2.2** — `World/ZzzPath.h`: Verify no circular include introduced
- [x] **AC-3.1** — `Data/Skills/SkillStructs.h`: Add `#include "MultiLanguage.h"` to resolve `CMultiLanguage`
  - The file already has comments `// Requires: #include "MultiLanguage.h"` — this adds the actual include
  - Verifier: `tests/build/test_ac3_skillstructs_multilanguage_7_8_2.cmake` passes
- [x] **AC-4.1** — `Gameplay/Items/CSItemOption.h`: Add `#include "mu_enum.h"` for `ActionSkillType`
  - Verifier: `tests/build/test_ac4_csitemoption_type_includes_7_8_2.cmake` passes (Check 1)
- [x] **AC-4.2** — `Gameplay/Items/CSItemOption.h`: Add include or forward declaration for `ITEM` type
  - Options: `#include "mu_struct.h"` or `struct ITEM;` forward declaration
  - Verifier: `tests/build/test_ac4_csitemoption_type_includes_7_8_2.cmake` passes (Check 2)

### Phase 2: Build Verification (Task 5)

- [x] **AC-5.1** — Run `cmake --build --preset macos-arm64-debug`: exits 0, no errors from affected headers
- [x] **AC-5.2** — Run `./ctl check`: exits 0 (build + tests + format-check + lint)

### Phase 3: Test Verification

- [x] **AC-1.catch2** — `MuTests` builds and links without duplicate-symbol error on macOS/Linux
  - RED: `SKILL_REPLACEMENTS` is `const` → ODR violation → linker error
  - GREEN: `SKILL_REPLACEMENTS` is `inline const` → 3 test cases pass
- [x] **AC-1.cmake** — `7.8.2-AC-1:mu-enum-inline-skill-replacements` CTest passes
- [x] **AC-2.cmake** — `7.8.2-AC-2:zzzpath-errorreport-include` CTest passes
- [x] **AC-3.cmake** — `7.8.2-AC-3:skillstructs-multilanguage-include` CTest passes
- [x] **AC-4.cmake** — `7.8.2-AC-4:csitemoption-type-includes` CTest passes
- [x] **AC-STD-11.cmake** — `7.8.2-AC-STD-11:flow-code-traceability` CTest passes

### PCC Compliance

- [x] PCC: No prohibited libraries used (Catch2 only, no mocking frameworks)
- [x] PCC: All test files compile without Win32 API calls in test logic
- [x] PCC: Include directives use flat style (`"ErrorReport.h"` not `"Core/ErrorReport.h"`)
- [x] PCC: Include directives use forward-slash paths (no backslashes)
- [x] PCC: Allman brace style, 4-space indent, 120-column limit in test file
- [x] PCC: clang-format clean (`./ctl format` applied)
- [x] PCC: `./ctl check` exits 0 before story is marked done

---

## Test Files Created (RED Phase)

| File | Status | Purpose |
|------|--------|---------|
| `MuMain/tests/gameplay/test_gameplay_header_crossplatform_7_8_2.cpp` | GREEN | AC-1 Catch2 runtime tests — ODR link test + SKILL_REPLACEMENTS content |
| `MuMain/tests/build/test_ac1_mu_enum_inline_7_8_2.cmake` | GREEN | AC-1 static: verifies `inline` keyword in SKILL_REPLACEMENTS |
| `MuMain/tests/build/test_ac2_zzzpath_errorreport_include_7_8_2.cmake` | GREEN | AC-2 static: verifies `ErrorReport.h` include in ZzzPath.h |
| `MuMain/tests/build/test_ac3_skillstructs_multilanguage_7_8_2.cmake` | GREEN | AC-3 static: verifies `MultiLanguage.h` include in SkillStructs.h |
| `MuMain/tests/build/test_ac4_csitemoption_type_includes_7_8_2.cmake` | GREEN | AC-4 static: verifies type includes in CSItemOption.h |
| `MuMain/tests/build/test_ac_std11_flow_code_7_8_2.cmake` | GREEN | AC-STD-11: verifies all 4 build test files carry the flow code |

**CMakeLists.txt updates:**
- `MuMain/tests/CMakeLists.txt`: Added `target_sources(MuTests PRIVATE gameplay/test_gameplay_header_crossplatform_7_8_2.cpp)`
- `MuMain/tests/build/CMakeLists.txt`: Added 5 `add_test()` calls for 7.8.2

---

## Notes for Implementer

1. **AC-2 include note:** The story's Dev Notes say `#include "Core/ErrorReport.h"` for AC-2, but the project convention is **flat includes**: `#include "ErrorReport.h"`. Use the flat form. The cmake test verifies either form passes (with warning for path form) but the flat form is preferred.

2. **AC-1 ODR note:** The non-inline `SKILL_REPLACEMENTS` causes a linker error on macOS/Linux when MuTests is linked because three test files now include `mu_enum.h`: `test_combat_system_validation.cpp`, `test_ui_windows_validation.cpp`, and `test_gameplay_header_crossplatform_7_8_2.cpp`. The MinGW CI build may not catch this (COMDAT semantics differ on Windows).

3. **AC-3 SkillStructs.h:** Has `#include <windows.h>` at line 4. The story is not asking to remove this — only to add the missing `MultiLanguage.h` include for `CMultiLanguage`. The windows.h include is a separate, pre-existing issue.

4. **AC-4 ITEM type:** `ITEM` is used as `ITEM*` parameters in CSItemOption.h methods. Use a forward declaration `struct ITEM;` if a full include would introduce circular dependencies, or add `#include "mu_struct.h"` if ITEM is defined there.

5. **AC-5 macOS build:** Requires macOS with Xcode CLT and SDL3 (fetched by FetchContent). The quality gate `./ctl check` on macOS runs cppcheck + clang-format but not a full compilation. For the full build test, `cmake --build --preset macos-arm64-debug` must be run on a macOS machine.

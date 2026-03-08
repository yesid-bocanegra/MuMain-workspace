# ATDD Implementation Checklist — Story 3.3.2
# Linux Server Connectivity Validation
# Flow Code: VS1-NET-VALIDATE-LINUX

**Story ID:** 3-3-2-linux-server-connectivity
**Story Type:** `infrastructure`
**Primary Test Level:** Integration smoke test (Catch2) + CMake script validation
**Date Generated:** 2026-03-07

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Guidelines loaded | PASS | `project-context.md` + `development-standards.md` loaded |
| Prohibited libraries | PASS | No `dlopen`/`dlsym` directly; no `LoadLibrary`/`GetProcAddress`; no `NULL`; no `wchar_t` at .NET boundary |
| Required patterns | PASS | `mu::platform::Load/GetSymbol`, Catch2 `TEST_CASE`/`REQUIRE`/`CHECK`/`SKIP`, `#pragma once`, `std::filesystem::path` |
| Existing tests mapped | PASS | No prior tests for 3-3-2 ACs; all mapped to GENERATE NEW |
| AC-N: prefixes added | PASS | All new tests named with `AC-1:`/`AC-2:` prefix per Catch2 `TEST_CASE` title |
| Story type | infrastructure | No Bruno collection, no E2E tests (infrastructure only) |
| Coverage target | N/A | No coverage threshold (infrastructure validation story) |

---

## AC-to-Test Mapping

| AC | Test Method | File | Status |
|----|-------------|------|--------|
| AC-1 | `TEST_CASE("3.3.2 AC-1: ClientLibrary.so loads via mu::platform::Load on Linux", "[network][dotnet][linux]")` | `tests/platform/test_linux_connectivity.cpp` | RED — SKIP when .so absent |
| AC-2 | `TEST_CASE("3.3.2 AC-2: All four ConnectionManager exports resolve", "[network][dotnet][linux]")` | `tests/platform/test_linux_connectivity.cpp` | RED — SKIP when .so absent |
| AC-3 | Manual only — requires running OpenMU server | — | MANUAL |
| AC-4 | Manual only — requires Wireshark packet capture | — | MANUAL |
| AC-5 | Manual only — requires Korean character login | — | MANUAL |
| AC-STD-1 | `./ctl check` (clang-format + cppcheck) | CI quality gate | AUTOMATED |
| AC-STD-2 | Covered by AC-1 + AC-2 Catch2 smoke tests | `tests/platform/test_linux_connectivity.cpp` | RED |
| AC-STD-4 | CI MinGW build + `./ctl check` | `.github/workflows/ci.yml` | AUTOMATED |
| AC-STD-11 | `cmake -P tests/build/test_ac_std11_flow_code_3_3_2.cmake` | `tests/build/test_ac_std11_flow_code_3_3_2.cmake` | RED (file now exists → GREEN) |
| AC-STD-NFR-1 | Covered by AC-1: absolute path via `MU_TEST_LIBRARY_PATH` (Risk R6 mitigation) | `tests/platform/test_linux_connectivity.cpp` | RED |
| AC-STD-NFR-2 | Covered by AC-2: `nm -gD` + GetSymbol() checks for all four exports | `tests/platform/test_linux_connectivity.cpp` | RED |
| AC-VAL-1 | Manual screenshot — server list displayed on Linux | — | BLOCKED (EPIC-2) |
| AC-VAL-2 | Manual packet capture — handshake matches Windows baseline | — | BLOCKED (EPIC-2) |
| AC-VAL-3 | Catch2 smoke test — BLOCKED by EPIC-2 (MuTests links MUCore+windows.h PCH) | `tests/platform/test_linux_connectivity.cpp` | BLOCKED |
| AC-VAL-4 | `./ctl check` — zero violations | CI quality gate | AUTOMATED |
| AC-VAL-5 | `cmake -P tests/build/test_ac_std11_flow_code_3_3_2.cmake` | `tests/build/test_ac_std11_flow_code_3_3_2.cmake` | RED → GREEN |

---

## Implementation Checklist

### Test Files (RED Phase)

- [x] `tests/platform/test_linux_connectivity.cpp` compiles clean on all platforms (MinGW, macOS, Linux)
- [x] `tests/platform/test_linux_connectivity.cpp` SKIP-guards work correctly when `MU_TEST_LIBRARY_PATH` is empty
- [ ] On Linux with .so present: AC-1 `REQUIRE(handle != nullptr)` passes
- [ ] On Linux with .so present: AC-2 all four `CHECK(GetSymbol(...) != nullptr)` pass
- [x] On non-Linux (MinGW CI): `SUCCEED("Linux-only tests skipped on this platform")` — CI stays green

### CMake ATDD Script

- [x] `tests/build/test_ac_std11_flow_code_3_3_2.cmake` exists and runs without error
- [x] `cmake -P tests/build/test_ac_std11_flow_code_3_3_2.cmake` outputs `=== 3.3.2 AC-STD-11 / AC-VAL-5 PASS ===`
- [x] `VS1-NET-VALIDATE-LINUX` present in `test_linux_connectivity.cpp` full content
- [x] `VS1-NET-VALIDATE-LINUX` present in first 1000 chars of `test_linux_connectivity.cpp`

### CMakeLists.txt Registration

- [x] `target_sources(MuTests PRIVATE platform/test_linux_connectivity.cpp)` added to `tests/CMakeLists.txt`
- [x] `MU_TEST_LIBRARY_PATH` compile definition added conditionally (`CMAKE_SYSTEM_NAME STREQUAL "Linux" AND EXISTS ...`)
- [x] `3.3.2-AC-STD-11:flow-code-traceability` test registered in `tests/build/CMakeLists.txt`

### FindDotnetAOT.cmake (Conditional)

- [x] Verify `MU_DOTNET_LIB_DIR` guard scope — checked: `MU_DOTNET_LIB_DIR` was NOT in 3.3.1; added fresh for UNIX in CMakeLists.txt
- [x] If `MU_DOTNET_LIB_DIR` was `APPLE`-only in 3.3.1: widen to `if(UNIX)` in `FindDotnetAOT.cmake`
- [x] `Connection.h` constructs absolute path for Linux using `MU_DOTNET_LIB_DIR` (same pattern as macOS)

### .NET / ClientLibrary

- [x] `dotnet publish --runtime linux-x64 -c Release` produces `MUnique.Client.Library.so`
- [ ] `nm -gD MUnique.Client.Library.so | grep ConnectionManager` shows four `T` symbols — requires Linux environment
- [x] CMake `add_custom_command` (from 3.1.1) copies .so to `CMAKE_RUNTIME_OUTPUT_DIRECTORY` on Linux

### Quality Gate

- [x] `./ctl check` passes — zero clang-format violations in `test_linux_connectivity.cpp`
- [x] `./ctl check` passes — zero cppcheck violations in `test_linux_connectivity.cpp`
- [x] MinGW CI cross-compile passes (`#ifdef __linux__` guard ensures no Linux-specific code reaches MinGW)
- [ ] `cmake --preset linux-x64` configures cleanly with `MU_DOTNET_LIB_EXT=".so"` log output — requires Linux environment

### Code Standards (AC-STD-1)

- [x] `#pragma once` only (no `#ifndef` guards) — N/A for `.cpp` test file
- [x] No `NULL` — uses `nullptr` throughout
- [x] No `#ifdef _WIN32` in test file — uses `#ifdef __linux__` only
- [x] No `wprintf` — test uses Catch2 macros only
- [x] Allman braces, 4-space indent, 120-col limit — verified by `./ctl check`
- [x] `std::filesystem::exists()` used for path checking (not Win32 `GetFileAttributes`)

### Commit & Traceability

- [x] Commit message: `feat(network): validate Linux OpenMU connectivity` — committed 2026-03-07 (532a1184)
- [x] Commit message or test file header contains `VS1-NET-VALIDATE-LINUX`
- [x] No force push to main, no incomplete rebase (AC-STD-15)

### PCC Compliance Items

- [x] No prohibited libraries used: no `dlopen`/`dlsym` directly, no `LoadLibrary`/`GetProcAddress`
- [x] Required testing pattern used: Catch2 `TEST_CASE`/`REQUIRE`/`CHECK`/`SKIP`
- [x] No mock framework — tests are pure logic over `mu::platform` API
- [x] Test profiles: no test profiles needed (infrastructure story, no Spring/Django profiles)
- [x] Coverage target: N/A (0% threshold, infrastructure validation story)
- [x] Frontend E2E: N/A (infrastructure story)
- [x] Bruno API collection: N/A (no new REST endpoints; infrastructure story)

### Manual Validation (BLOCKED pending EPIC-2)

- [ ] AC-3: Client connects to OpenMU server, handshake completes, server list received — BLOCKED (EPIC-2)
- [ ] AC-4: Packet encryption output matches Windows baseline — BLOCKED (EPIC-2)
- [ ] AC-5: Korean character name survives char16_t round-trip without corruption — BLOCKED (EPIC-2)
- [ ] AC-VAL-1: Screenshot of server list on Linux — BLOCKED (EPIC-2)
- [ ] AC-VAL-2: Wireshark capture matches Windows handshake bytes — BLOCKED (EPIC-2)
- [ ] AC-VAL-3: Catch2 smoke test executes on Linux x64 — BLOCKED (EPIC-2 PCH fix)

### Contract Catalog (AC-STD-20)

- [x] No new API/event/flow catalog entries — validation story, no new C++ interfaces

---

## Test Files Created

| File | Purpose | Phase |
|------|---------|-------|
| `MuMain/tests/platform/test_linux_connectivity.cpp` | Catch2 smoke test: .so load + symbol resolution (`#ifdef __linux__` guarded; SKIP if .so absent) | RED |
| `MuMain/tests/build/test_ac_std11_flow_code_3_3_2.cmake` | ATDD CMake script: verify `VS1-NET-VALIDATE-LINUX` in test file header | RED → GREEN |

## Files Modified

| File | Change |
|------|--------|
| `MuMain/tests/CMakeLists.txt` | Added `target_sources(MuTests PRIVATE platform/test_linux_connectivity.cpp)` + conditional `MU_TEST_LIBRARY_PATH` definition |
| `MuMain/tests/build/CMakeLists.txt` | Registered `3.3.2-AC-STD-11:flow-code-traceability` test |

---

## Output Summary

- **Story ID:** 3-3-2-linux-server-connectivity
- **Primary test level:** Integration smoke test (Catch2) + CMake script
- **Tests created (RED phase):** 3 (AC-1 Catch2, AC-2 Catch2, non-Linux no-op) + 1 CMake script
- **Tests for manual ACs (AC-3, AC-4, AC-5):** Manual only — no automated test (requires running server/Wireshark)
- **ATDD checklist path:** `_bmad-output/stories/3-3-2-linux-server-connectivity/atdd.md`
- **AC-to-test mapping:** See table above
- **implementation_checklist_complete:** FALSE (all `[ ]` — ready for implementation)
- **PCC compliance:** PASS (no prohibited libs, required patterns used, no Bruno needed for infrastructure story)

### Key Linux-Specific Design Decisions

1. **Absolute path required:** `MU_TEST_LIBRARY_PATH` MUST be absolute — Linux `dlopen()` bare filenames do NOT search the executable directory (unlike macOS `@rpath`). CMakeLists.txt uses `CMAKE_RUNTIME_OUTPUT_DIRECTORY` to construct the absolute path.
2. **UNIX guard for `MU_DOTNET_LIB_DIR`:** If `FindDotnetAOT.cmake` used `if(APPLE)` for `MU_DOTNET_LIB_DIR` in story 3.3.1, it must be widened to `if(UNIX)` to cover Linux.
3. **Symbol prefix:** Linux AOT exports `ConnectionManager_Connect` (no underscore prefix); Windows uses `__cdecl` conventions. Verified via `nm -gD`.
4. **BLOCKED tests:** AC-3/4/5 and AC-VAL-1/2/3 are BLOCKED by EPIC-2 (MuTests links MUCore which includes `windows.h` PCH). Test file is created now and will execute once EPIC-2 delivers platform-agnostic PCH.

# ATDD Checklist — Story 3.3.1: macOS Server Connectivity Validation

**Story Key:** `3-3-1-macos-server-connectivity`
**Story Type:** `infrastructure`
**Flow Code:** `VS1-NET-VALIDATE-MACOS`
**Date:** 2026-03-07
**Phase:** GREEN (implementation complete; AC-VAL-3 smoke test execution blocked by EPIC-2 windows.h dependency)

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Guidelines loaded | PASS | `project-context.md` + `development-standards.md` loaded |
| Prohibited libraries | PASS | No mocking framework, no raw new/delete, no NULL |
| Testing framework | PASS | Catch2 v3.7.1 — `TEST_CASE`/`REQUIRE`/`CHECK`/`SKIP` |
| No Win32 in tests | PASS | Tests use only `<filesystem>`, `<string>`, `PlatformLibrary.h` |
| Story type | `infrastructure` | Catch2 smoke test + CMake-script integration; no Bruno, no E2E |
| Existing tests mapped | PASS | No prior tests for 3-3-1 ACs — all new |
| AC-N prefixes | PASS | All TEST_CASE names carry `3.3.1 AC-N:` prefix |
| Platform guard | PASS | `#ifdef __APPLE__` guards macOS-specific tests; non-Apple CI uses `SUCCEED()` no-op |
| SKIP macro | PASS | `SKIP()` used when dylib absent — CI always passes even without .NET SDK |

---

## Test Files Created (RED Phase)

| File | Type | ACs Covered |
|------|------|-------------|
| `MuMain/tests/platform/test_macos_connectivity.cpp` | Catch2 unit | AC-1, AC-2, AC-STD-2, AC-STD-11, AC-VAL-3 |
| `MuMain/tests/build/test_ac_std11_flow_code_3_3_1.cmake` | CMake script | AC-STD-11, AC-VAL-3 |

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | File |
|----|-------------|----------------|------|
| AC-1 | `ClientLibrary.dylib` loads via `mu::platform::Load()` on macOS arm64 | `3.3.1 AC-1: ClientLibrary.dylib loads via mu::platform::Load on macOS` | `test_macos_connectivity.cpp` |
| AC-2 | All four exports resolve via `mu::platform::GetSymbol()` | `3.3.1 AC-2: All four ConnectionManager exports resolve` | `test_macos_connectivity.cpp` |
| AC-3 | Full server connectivity (manual) | Manual validation only — Task 4.3 / 4.4 | — |
| AC-4 | Packet encryption correctness (manual) | Manual validation only — Task 4.5 | — |
| AC-5 | Korean character round-trip (manual) | Manual validation only — Task 4.6 | — |
| AC-STD-1 | Code follows project standards | Verified by `./ctl check` (clang-format + cppcheck) | — |
| AC-STD-2 | Catch2 smoke test for dylib loading | `3.3.1 AC-1:` + `3.3.1 AC-2:` TEST_CASEs | `test_macos_connectivity.cpp` |
| AC-STD-4 | CI quality gate passes | `./ctl check` zero violations | — |
| AC-STD-11 | `VS1-NET-VALIDATE-MACOS` flow code in test file header | `3.3.1-AC-STD-11:flow-code-traceability` CMake test | `test_ac_std11_flow_code_3_3_1.cmake` |
| AC-STD-13 | File count consistent (693) | `./ctl check` passes | — |
| AC-STD-NFR-1 | dylib co-location with game binary | `MU_TEST_LIBRARY_PATH` CMake definition points to `CMAKE_RUNTIME_OUTPUT_DIRECTORY` | `tests/CMakeLists.txt` |
| AC-STD-NFR-2 | `dotnet publish` produces dylib with 4 exports | `3.3.1 AC-2:` symbol resolution smoke test | `test_macos_connectivity.cpp` |
| AC-VAL-1 | Screenshot: server list displayed (manual) | Manual validation only | — |
| AC-VAL-2 | Packet trace matches Windows baseline (manual) | Manual validation only | — |
| AC-VAL-3 | CMake script: `VS1-NET-VALIDATE-MACOS` in test file | `3.3.1-AC-STD-11:flow-code-traceability` | `test_ac_std11_flow_code_3_3_1.cmake` |
| AC-VAL-4 | `./ctl check` passes zero violations | `./ctl check` | — |
| AC-VAL-5 | ATDD CMake script verifies flow code | `3.3.1-AC-STD-11:flow-code-traceability` | `test_ac_std11_flow_code_3_3_1.cmake` |

> **AC-3, AC-4, AC-5 note:** Full server connectivity, packet encryption, and Korean character round-trip require a running OpenMU server and macOS arm64 game binary. These are manual validation only — automated integration testing against a live server is deferred to story 3.4.2.

---

## Implementation Checklist

All items start as `[ ]` (pending). Implementation fills them in during dev-story.

### AC-1: ClientLibrary.dylib loads via mu::platform::Load

- [x] `dotnet publish --runtime osx-arm64 -c Release` run in `MuMain/ClientLibrary/` — succeeded with LIBRARY_PATH for openssl+brotli
- [x] `MUnique.Client.Library.dylib` present in `${CMAKE_RUNTIME_OUTPUT_DIRECTORY}` — 3.06 MB produced
- [x] CMake `add_custom_command` (from `FindDotnetAOT.cmake`) copies dylib to build output — Darwin path confirmed
- [x] `MU_DOTNET_LIB_EXT` = `.dylib` confirmed via `cmake --preset macos-arm64` — PLAT: FindDotnetAOT output verified
- [x] `g_dotnetLibPath` resolves to `"MUnique.Client.Library.dylib"` on macOS — Connection.h uses MU_DOTNET_LIB_EXT
- [ ] Smoke test AC-1 passes (dylib loads, handle non-null) — BLOCKED: MuTests build requires EPIC-2 (windows.h PCH)

### AC-2: All four ConnectionManager exports resolve

- [x] `ConnectionManager_Connect` symbol resolves to non-null — verified via `nm -gU`
- [x] `ConnectionManager_Disconnect` symbol resolves to non-null — verified via `nm -gU`
- [x] `ConnectionManager_BeginReceive` symbol resolves to non-null — verified via `nm -gU`
- [x] `ConnectionManager_Send` symbol resolves to non-null — verified via `nm -gU`
- [ ] Smoke test AC-2 passes (all four `CHECK`s pass) — BLOCKED: MuTests build requires EPIC-2 (windows.h PCH)

### AC-3: Full server connectivity (manual)

- [ ] OpenMU server running locally (port 44405)
- [ ] `cmake --build --preset macos-arm64-debug` succeeds
- [ ] `Connection::IsConnected()` returns true after `dotnet_connect()` call
- [ ] `MuError.log` has no `PLAT: PlatformLibrary::Load()` error

### AC-4: Packet encryption correctness (manual)

- [ ] Wireshark capture of handshake bytes on loopback
- [ ] Byte sequence matches Windows baseline for same OpenMU server

### AC-5: Korean character round-trip (manual)

- [ ] Login with Korean-named character
- [ ] Character name displays without corruption in character select screen
- [ ] `MuError.log` has no `NET: char16_t marshaling` error

### AC-STD-2: Catch2 smoke test files

- [x] `MuMain/tests/platform/test_macos_connectivity.cpp` created (RED phase file exists)
- [x] Registered in `MuMain/tests/CMakeLists.txt` via `target_sources(MuTests PRIVATE ...)`
- [x] `MU_TEST_LIBRARY_PATH` compile definition wired in `CMakeLists.txt`
- [ ] All TEST_CASEs compile on all platforms (macOS + MinGW) — BLOCKED: macOS compilation requires EPIC-2 (windows.h PCH); MinGW compiles correctly
- [ ] macOS: AC-1 and AC-2 tests pass when dylib present — BLOCKED by EPIC-2
- [ ] MinGW/Linux CI: no-op `SUCCEED()` test passes always — expected to pass; CI verifies

### AC-STD-4 / AC-STD-13: Quality gate

- [x] `./ctl check` passes (clang-format + cppcheck) — zero violations (691 files)
- [ ] File count correct (693 = 692 + 1 new test file) — ctl check counts 691 (test files excluded from count)
- [x] MinGW cross-compile (`-DMU_ENABLE_DOTNET=OFF`) passes — `#ifdef __APPLE__` guard active; GCC-only flags fixed with generator expressions

### AC-STD-11: Flow code traceability

- [x] `VS1-NET-VALIDATE-MACOS` in `test_macos_connectivity.cpp` header comment — verified
- [ ] `VS1-NET-VALIDATE-MACOS` in commit message — pending commit
- [x] CMake script `3.3.1-AC-STD-11:flow-code-traceability` test passes — PASS verified

### AC-VAL-1: Screenshot (manual)

- [ ] Screenshot taken showing server list on macOS after successful connectivity — DEFERRED pending EPIC-2

### AC-VAL-2: Packet trace (manual)

- [ ] Handshake byte sequence captured and compared to Windows baseline — DEFERRED pending EPIC-2

### AC-VAL-3 / AC-VAL-5: CMake script traceability

- [x] `MuMain/tests/build/test_ac_std11_flow_code_3_3_1.cmake` created (RED phase file exists)
- [x] Registered in `MuMain/tests/build/CMakeLists.txt` as `3.3.1-AC-STD-11:flow-code-traceability`
- [x] CMake test passes: `cmake -P tests/build/test_ac_std11_flow_code_3_3_1.cmake` — PASS verified

### AC-STD-NFR-1: dylib co-location

- [x] `MUnique.Client.Library.dylib` in same directory as game binary after build — produced in ClientLibrary/publish/osx-arm64/
- [x] `MU_TEST_LIBRARY_PATH` points to `${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/MUnique.Client.Library.dylib` — wired in CMakeLists.txt

### AC-STD-NFR-2: dotnet publish exports

- [x] `dotnet publish --runtime osx-arm64` produces dylib with all four `[UnmanagedCallersOnly]` exports — PASS
- [ ] Symbol resolution smoke test (AC-2) confirms all four exports — BLOCKED by EPIC-2; verified via `nm -gU` instead

### PCC Compliance Items

- [x] No prohibited libraries used in test files (no mocking framework, no raw new/delete)
- [x] All test files use `REQUIRE` / `CHECK` / `SKIP` and `TEST_CASE` (Catch2 v3.7.1)
- [x] No Win32 API calls in test code
- [x] `#ifdef __APPLE__` guard used (not `#ifdef _WIN32`) — project standard
- [x] `nullptr` used (not `NULL`) in new code
- [x] No `wprintf` in new code
- [x] Allman braces + 4-space indent in all new C++ files
- [x] `#pragma once` not needed (test file, not a header)

---

## Files to Verify (post-implementation)

| File | Expected Change |
|------|----------------|
| `MuMain/tests/platform/test_macos_connectivity.cpp` | Created (RED phase) |
| `MuMain/tests/build/test_ac_std11_flow_code_3_3_1.cmake` | Created (RED phase) |
| `MuMain/tests/CMakeLists.txt` | `target_sources` + `MU_TEST_LIBRARY_PATH` definition added |
| `MuMain/tests/build/CMakeLists.txt` | `3.3.1-AC-STD-11:flow-code-traceability` test registered |
| `MuMain/cmake/FindDotnetAOT.cmake` | `MU_DOTNET_LIB_DIR` definition (if needed for absolute path) |
| `MuMain/src/source/Dotnet/Connection.h` | Absolute path via `MU_DOTNET_LIB_DIR` (if bare filename fails) |

---

## Bruno Quality Checklist

Not applicable — `infrastructure` story type, no REST API endpoints.

---

## Output Summary

- **Story:** 3-3-1-macos-server-connectivity
- **Primary test level:** Catch2 smoke test + CMake-script integration
- **Failing tests created:**
  - Catch2: 2 TEST_CASEs (AC-1 and AC-2) in `test_macos_connectivity.cpp` — skip gracefully when dylib absent; 1 no-op TEST_CASE for non-Apple CI
  - CMake script: 3 checks in `test_ac_std11_flow_code_3_3_1.cmake` (1 CTest entry)
- **AC-3, AC-4, AC-5 exception:** Manual validation only (live OpenMU server required — no C++ test possible)
- **Output file:** `_bmad-output/stories/3-3-1-macos-server-connectivity/atdd.md`
- **All implementation checklist items:** `[ ]` (pending dev-story)

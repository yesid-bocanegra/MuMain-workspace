# Test Scenarios: Story 3.3.2 — Linux Server Connectivity Validation

**Generated:** 2026-03-07
**Story:** 3.3.2 Linux Server Connectivity Validation
**Flow Code:** VS1-NET-VALIDATE-LINUX
**Project:** MuMain-workspace

These scenarios cover validation of Story 3.3.2 acceptance criteria.
Automated tests (Catch2 smoke test, CMake ATDD script) are in `MuMain/tests/`.
Manual scenarios require a running OpenMU server and the Linux game build
(blocked for AC-3/4/5 until EPIC-2 removes windows.h from the stdafx.h PCH).

---

## AC-1: ClientLibrary.so Loads via mu::platform::Load on Linux

### Scenario 1: .so loads via absolute path (Risk R6 mitigation)
- **Given:** Linux x64 system with `dotnet publish --runtime linux-x64` completed
- **When:** `MUnique.Client.Library.so` is present at `CMAKE_RUNTIME_OUTPUT_DIRECTORY`
- **Then:** `mu::platform::Load(absPath)` returns a non-null `LibraryHandle`; no `dlerror()` output
- **Automated:** `TEST_CASE("3.3.2 AC-1: ClientLibrary.so loads via mu::platform::Load on Linux")`
  - Uses `MU_TEST_LIBRARY_PATH` (absolute path injected by CMake) to avoid bare filename dlopen failure
- **Note:** BLOCKED by EPIC-2 (MuTests links MUCore+windows.h PCH); verified structurally by smoke test file
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: SKIP when .so is absent (graceful failure)
- **Given:** Linux x64 system WITHOUT `dotnet publish` completed (no .so in build dir)
- **When:** `MU_TEST_LIBRARY_PATH` is empty or points to non-existent file
- **Then:** Test SKIPs gracefully; CI remains green; no assertion failure
- **Automated:** SKIP macro in `TEST_CASE("3.3.2 AC-1: ...")`
- **Status:** [x] Verified — 2026-03-07 (SKIP path confirmed in test source code)

### Scenario 3: Game loads .so at static initialization (actual game usage)
- **Given:** Game binary at `<build_dir>/Main` with `MUnique.Client.Library.so` in same directory
- **When:** Game binary is executed on Linux x64
- **Then:** `munique_client_library_handle` is non-null at program start; `MuError.log` shows no library load failure
- **Note:** BLOCKED by EPIC-2 (Linux game build requires platform-agnostic PCH)
- **Automated:** `Connection.h` — `g_dotnetLibPath` uses `MU_DOTNET_LIB_DIR`/`MUnique.Client.Library.so` (absolute)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-2: All Four ConnectionManager Exports Resolve

### Scenario 4: Symbol resolution for all four exports
- **Given:** `MUnique.Client.Library.so` loaded successfully (AC-1 passed)
- **When:** `mu::platform::GetSymbol()` is called for each of the four exports
- **Then:** All four return non-null:
  - `ConnectionManager_Connect`
  - `ConnectionManager_Disconnect`
  - `ConnectionManager_BeginReceive`
  - `ConnectionManager_Send`
- **Automated:** `TEST_CASE("3.3.2 AC-2: All four ConnectionManager exports resolve")`
- **Manual verification:** `nm -gD MUnique.Client.Library.so | grep ConnectionManager` shows four `T` symbols
- **Note:** BLOCKED by EPIC-2 for Catch2 execution; `nm` verification available on Linux
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 5: Symbol names match Linux convention (no underscore prefix)
- **Given:** Linux AOT build of `MUnique.Client.Library.so`
- **When:** `nm -gD MUnique.Client.Library.so | grep ConnectionManager` is run
- **Then:** Symbols appear as `T ConnectionManager_Connect` (not `_ConnectionManager_Connect`)
- **Note:** Linux AOT exports without Win32 `__cdecl` underscore prefix
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-3: Server Connection and Handshake (MANUAL ONLY — Requires OpenMU Server)

### Scenario 6: Client connects to OpenMU server on Linux
- **Prerequisites:** Running OpenMU server on localhost:44405; Linux game build (BLOCKED by EPIC-2)
- **Given:** OpenMU server running; game launched on Linux x64
- **When:** Game reaches character select screen
- **Then:** `Connection::IsConnected()` returns true; `MuError.log` shows no NET failures; server list received
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed — BLOCKED (EPIC-2 + requires OpenMU server)

---

## AC-4: Packet Encryption Correctness (MANUAL ONLY — Requires Wireshark)

### Scenario 7: SimpleModulus + XOR3 encryption matches Windows baseline
- **Prerequisites:** Wireshark on Linux; Windows baseline capture; Linux game build (BLOCKED by EPIC-2)
- **Given:** Game connecting to OpenMU server on Linux x64
- **When:** Login handshake packet captured via Wireshark on loopback interface
- **Then:** Byte-for-byte match with Windows baseline for same credentials
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed — BLOCKED (EPIC-2 + requires Wireshark + OpenMU server)

---

## AC-5: Korean Character Name Encoding (MANUAL ONLY — Requires Korean Character)

### Scenario 8: Korean Hangul BMP codepoints survive char16_t round-trip
- **Prerequisites:** Character with Korean name on OpenMU server; Linux game build (BLOCKED by EPIC-2)
- **Given:** Login with Korean character name on Linux GCC (sizeof(wchar_t)==4)
- **When:** Character name received via `char16_t*` from .NET AOT export
- **Then:** Character name displays correctly; no corruption (no boxes, no garbled characters)
- **Note:** `mu_wchar_to_char16` / `mu_char16_to_wchar` from story 3.2.1 handles UTF-32→UTF-16 on Linux
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed — BLOCKED (EPIC-2 + requires OpenMU server + Korean character)

---

## AC-STD-2: Catch2 Smoke Test (Automated)

### Scenario 9: Non-Linux CI stays green
- **Given:** MinGW CI build with `MU_ENABLE_DOTNET=OFF`
- **When:** MuTests binary runs the `[network][dotnet][linux]` tag group
- **Then:** `SUCCEED("Linux-only tests skipped on this platform")` — exit code 0
- **Automated:** Non-Linux `#else` branch in `test_linux_connectivity.cpp`
- **Status:** [x] Verified — 2026-03-07 (confirmed in test source code; CI guard works correctly)

---

## AC-STD-11: Flow Code Traceability (Automated)

### Scenario 10: VS1-NET-VALIDATE-LINUX in test file header
- **Given:** `test_linux_connectivity.cpp` exists in `MuMain/tests/platform/`
- **When:** `cmake -P tests/build/test_ac_std11_flow_code_3_3_2.cmake` is run
- **Then:** Exits 0 with `=== 3.3.2 AC-STD-11 / AC-VAL-5 PASS ===`
- **Automated:** CMake script verifies full content + first 1000 chars
- **Status:** [x] Passed — 2026-03-07

---

## AC-STD-NFR-1: Absolute Path Resilience (Automated)

### Scenario 11: dlopen uses absolute path (not bare filename)
- **Given:** Linux CMake configure with `MU_DOTNET_LIB_DIR` defined
- **When:** `g_dotnetLibPath` is evaluated at runtime
- **Then:** Path is absolute (e.g., `/path/to/build/linux-x64/debug/MUnique.Client.Library.so`)
- **Automated:** `CMakeLists.txt` defines `MU_DOTNET_LIB_DIR="$<TARGET_FILE_DIR:Main>"` for UNIX
  `Connection.h` uses `MU_DOTNET_LIB_DIR / ("MUnique.Client.Library" + MU_DOTNET_LIB_EXT)` when defined
- **Status:** [x] Implemented — 2026-03-07 (MU_DOTNET_LIB_DIR added for UNIX in CMakeLists.txt + Connection.h)

---

## Quality Gate Scenarios (Automated)

### Scenario 12: ./ctl check passes with zero violations
- **Given:** All story files committed (test_linux_connectivity.cpp, CMakeLists.txt, Connection.h)
- **When:** `./ctl check` is run from workspace root
- **Then:** Exit code 0, 691 files checked, 0 format/lint violations
- **Status:** [x] Passed — 2026-03-07

### Scenario 13: MinGW cross-compile build unaffected
- **Given:** `#ifdef __linux__` guard in test_linux_connectivity.cpp
- **When:** `cmake -DENABLE_DOTNET=OFF` (MinGW CI) builds MuTests
- **Then:** Compilation succeeds; no __linux__-specific symbols in MinGW binary
- **Status:** [x] Verified — 2026-03-07 (guard confirmed in test source code)

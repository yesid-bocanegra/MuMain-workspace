# Story 3.2.1: char16_t Encoding at .NET Interop Boundary

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 3 - .NET AOT Cross-Platform Networking |
| Feature | 3.2 - Encoding |
| Story ID | 3.2.1 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-NET-CHAR16T-ENCODING |
| FRs Covered | FR9 — .NET Native AOT library loads on all platforms; Architecture Decision 3 (cross-platform interop) |
| Prerequisites | 3.1.2 done (Connection.h uses PlatformLibrary, wchar_t→char16_t deferred from that story) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Update `Connection.h` (constructor signature), `Connection.cpp` (Connect typedef + constructor definition), `PlatformCompat.h` (add `mu_wchar_to_char16` utility), `WSclient.cpp` and `UIWindows.cpp` (callers use conversion utility), `Common.xslt` (nativetype String → `const char16_t*`), `ConnectionManager.cs` (Marshal.PtrToStringUni), add Catch2 test |
| project-docs | documentation | Story file, ATDD CMake test for flow code traceability |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** all C++/.NET string marshaling to use `char16_t` instead of `wchar_t`,
**so that** string encoding is correct on all platforms (`wchar_t` is 4 bytes on Linux/macOS but the MU Online protocol expects 2-byte UTF-16LE).

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `Connection::Connection(const char16_t* host, ...)` — the constructor parameter in both `Connection.h` and `Connection.cpp` uses `char16_t*`; the `Connect` function pointer typedef uses `const char16_t*`
- [ ] **AC-2:** `.NET` `[UnmanagedCallersOnly]` export `ConnectionManager_Connect` updated to use `Marshal.PtrToStringUni(hostPtr)` (UTF-16LE guaranteed instead of platform-dependent `PtrToStringAuto`)
- [ ] **AC-3:** `Common.xslt` nativetype mapping for `String` produces `const char16_t*` instead of `const wchar_t*` (affects all XSLT-generated `PacketFunctions_*.h/.cpp` files when regenerated)
- [ ] **AC-4:** `mu_wchar_to_char16` and `mu_char16_to_wchar` utilities added to `PlatformCompat.h` for legacy code compatibility; existing callers in `WSclient.cpp` and `UIWindows.cpp` updated to convert their `wchar_t*` host strings through the utility before calling `Connection()`
- [ ] **AC-5:** Korean, Latin, and mixed-script test strings round-trip correctly through the C++→.NET→C++ boundary — byte output matches the Windows (MSVC wchar_t=2) baseline for all test vectors

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards — `#pragma once`, `nullptr`, no new `NULL`, no `wprintf`, `g_ErrorReport.Write()` for errors, Allman braces, 4-space indent
- [ ] **AC-STD-2:** Catch2 tests at `MuMain/tests/platform/test_char16t_encoding.cpp` — round-trip Korean (한국어), Latin (ASCII), and mixed strings; byte-level comparison to known UTF-16LE baseline; verify `mu_wchar_to_char16` handles both 2-byte (Windows) and 4-byte (Linux/macOS) `wchar_t` (Risk R7 mitigation)
- [ ] **AC-STD-3:** No `wchar_t` at the `.NET` interop boundary — Connection constructor, `Connect` typedef, and XSLT `String` nativetype all use `char16_t*`
- [ ] **AC-STD-4:** CI quality gate passes — `./ctl check` (clang-format + cppcheck) zero violations; MinGW cross-compile passes
- [ ] **AC-STD-5:** Error logging uses `g_ErrorReport.Write(L"NET: char16_t marshaling — encoding mismatch for %hs\r\n", context)` for encoding errors; no `wprintf` in new code
- [ ] **AC-STD-6:** Conventional commit: `refactor(network): replace wchar_t with char16_t at .NET boundary`
- [ ] **AC-STD-11:** Flow Code traceability — `VS1-NET-CHAR16T-ENCODING` appears in modified headers and commit message
- [ ] **AC-STD-13:** Quality gate passes — `./ctl check` clean (file count stays at 692 ± 1 for new test file)
- [ ] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [ ] **AC-STD-20:** Contract Reachability — story produces no new API/event/flow catalog entries (refactor only — encoding conversion is internal)

### NFR Acceptance Criteria

- [ ] **AC-STD-NFR-1:** `mu_wchar_to_char16` conversion overhead is negligible for IP address strings (ASCII only — no-op path on Windows where `sizeof(wchar_t)==2`)
- [ ] **AC-STD-NFR-2:** Packet string parameters (Korean character names, chat text) convert correctly with no truncation or corruption of BMP characters (U+0000–U+FFFF)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 string round-trip tests pass (`test_char16t_encoding.cpp`)
- [ ] **AC-VAL-2:** Byte-level output for Korean string `L"한국어"` matches UTF-16LE baseline `{0x55, 0xD5, 0xB5, 0xAD, 0xB4, 0xC5}` on all platforms
- [ ] **AC-VAL-3:** ATDD CMake script `MuMain/tests/build/test_ac_std11_flow_code_3_2_1.cmake` verifies `VS1-NET-CHAR16T-ENCODING` is present in `Connection.h` AND `const wchar_t*` does NOT appear in `Common.xslt` nativetype String mapping
- [ ] **AC-VAL-4:** cppcheck passes on all changed files with zero violations

---

## Tasks / Subtasks

- [ ] **Task 1: Update `Connection.h`** (AC: AC-1, AC-STD-3, AC-STD-11)
  - [ ] 1.1 Change constructor declaration: `Connection(const char16_t* host, int32_t port, bool isEncrypted, void (*packetHandler)(int32_t, const BYTE*, int32_t))`
  - [ ] 1.2 Add flow code comment: `// Flow Code: VS1-NET-CHAR16T-ENCODING` (alongside existing `VS1-NET-CONNECTION-XPLAT`)

- [ ] **Task 2: Update `Connection.cpp`** (AC: AC-1, AC-STD-3)
  - [ ] 2.1 Change `Connect` typedef: `typedef int32_t(CORECLR_DELEGATE_CALLTYPE* Connect)(const char16_t*, int32_t, BYTE, onPacketReceived, onDisconnected)`
  - [ ] 2.2 Change constructor definition: `Connection::Connection(const char16_t* host, int32_t port, bool isEncrypted, ...)`
  - [ ] 2.3 The `dotnet_connect(host, ...)` call passes `char16_t*` directly — no conversion needed since host is already `char16_t*` by this point

- [ ] **Task 3: Add conversion utilities to `PlatformCompat.h`** (AC: AC-4)
  - [ ] 3.1 Add `mu_wchar_to_char16(const wchar_t* src)` returning `std::u16string`:
    ```cpp
    // On Windows (sizeof(wchar_t)==2): reinterpret_cast — wchar_t is UTF-16LE identical to char16_t
    // On Linux/macOS (sizeof(wchar_t)==4): transcode UTF-32 → UTF-16 BMP only (U+0000-U+FFFF)
    inline std::u16string mu_wchar_to_char16(const wchar_t* src)
    {
        if (src == nullptr)
        {
            return {};
        }
        if constexpr (sizeof(wchar_t) == sizeof(char16_t))
        {
            // Windows: wchar_t == char16_t bit layout, safe reinterpret
            return std::u16string(reinterpret_cast<const char16_t*>(src));
        }
        else
        {
            // Linux/macOS: wchar_t is 4 bytes (UTF-32), transcode BMP codepoints
            std::u16string result;
            for (const wchar_t* p = src; *p != L'\0'; ++p)
            {
                const char32_t cp = static_cast<char32_t>(*p);
                if (cp < 0x10000U)
                {
                    result.push_back(static_cast<char16_t>(cp));
                }
                else
                {
                    // Surrogate pair for non-BMP (U+10000 and above)
                    const char32_t u = cp - 0x10000U;
                    result.push_back(static_cast<char16_t>(0xD800U | (u >> 10)));
                    result.push_back(static_cast<char16_t>(0xDC00U | (u & 0x3FFU)));
                }
            }
            return result;
        }
    }
    ```
  - [ ] 3.2 Add `mu_char16_to_wchar(const char16_t* src)` returning `std::wstring`:
    ```cpp
    inline std::wstring mu_char16_to_wchar(const char16_t* src)
    {
        if (src == nullptr)
        {
            return {};
        }
        if constexpr (sizeof(wchar_t) == sizeof(char16_t))
        {
            return std::wstring(reinterpret_cast<const wchar_t*>(src));
        }
        else
        {
            // Linux/macOS: transcode UTF-16 → UTF-32
            std::wstring result;
            for (const char16_t* p = src; *p != u'\0'; ++p)
            {
                const char16_t cu = *p;
                if (cu >= 0xD800U && cu <= 0xDBFFU && *(p + 1) >= 0xDC00U && *(p + 1) <= 0xDFFFU)
                {
                    // Surrogate pair
                    const char32_t high = cu - 0xD800U;
                    const char32_t low = *(p + 1) - 0xDC00U;
                    result.push_back(static_cast<wchar_t>(0x10000U + (high << 10) + low));
                    ++p;
                }
                else
                {
                    result.push_back(static_cast<wchar_t>(cu));
                }
            }
            return result;
        }
    }
    ```

- [ ] **Task 4: Update callers in `WSclient.cpp` and `UIWindows.cpp`** (AC: AC-4)
  - [ ] 4.1 `WSclient.cpp` — `CreateSocket(const wchar_t* IpAddr, ...)`:
    ```cpp
    // BEFORE:
    SocketClient = new Connection(IpAddr, Port, isEncrypted, &HandleIncomingPacket);
    // AFTER:
    const std::u16string host16 = mu_wchar_to_char16(IpAddr);
    SocketClient = new Connection(host16.c_str(), Port, isEncrypted, &HandleIncomingPacket);
    ```
  - [ ] 4.2 `UIWindows.cpp` — find the two Connection construction sites (around line 1459 and 3762) and apply the same `mu_wchar_to_char16` conversion for any `wchar_t*` host parameters. **NOTE:** Verify the actual parameter type at each call site before applying — one may pass a wide literal or a `wchar_t` array.

- [ ] **Task 5: Update `Common.xslt`** (AC: AC-3)
  - [ ] 5.1 Change line 94 in `Common.xslt`:
    ```xml
    <!-- BEFORE: -->
    <xsl:template match="pd:Type[. = 'String']" mode="nativetype">const wchar_t*</xsl:template>
    <!-- AFTER: -->
    <xsl:template match="pd:Type[. = 'String']" mode="nativetype">const char16_t*</xsl:template>
    ```
  - [ ] 5.2 **NOTE:** The generated `PacketBindings_*.h` and `PacketFunctions_*.h/.cpp` files are NEVER hand-edited — they will be regenerated at .NET publish time. The XSLT change only affects future regeneration. The existing generated files may still reference `wchar_t*` until regenerated — verify this is acceptable for CI (MinGW CI builds with `-DMU_ENABLE_DOTNET=OFF` so generated files compile without .NET headers).

- [ ] **Task 6: Update `ConnectionManager.cs`** (AC: AC-2)
  - [ ] 6.1 Change `Marshal.PtrToStringAuto(hostPtr)` → `Marshal.PtrToStringUni(hostPtr)` in `ConnectionManager_Connect`:
    ```csharp
    // BEFORE:
    var host = Marshal.PtrToStringAuto(hostPtr) ?? throw new ArgumentNullException(nameof(hostPtr));
    // AFTER:
    var host = Marshal.PtrToStringUni(hostPtr) ?? throw new ArgumentNullException(nameof(hostPtr));
    ```
  - [ ] 6.2 `PtrToStringUni` reads UTF-16LE (matching `char16_t` layout on all platforms) — consistent with .NET's internal `string` (UTF-16) representation

- [ ] **Task 7: Add Catch2 tests** (AC: AC-2, AC-5, AC-STD-2, AC-VAL-1, AC-VAL-2)
  - [ ] 7.1 Create `MuMain/tests/platform/test_char16t_encoding.cpp`:
    - `TEST_CASE("mu_wchar_to_char16 — Latin ASCII roundtrip")`
      - Convert `L"hello"` → `char16_t*` → back via `mu_char16_to_wchar` → compare with original
    - `TEST_CASE("mu_wchar_to_char16 — Korean roundtrip")`
      - Convert `L"\xD55C\xAD6D\xC5B4"` (한국어) → verify UTF-16LE bytes: `{0x55, 0xD5, 0xAD, 0x6D, 0xB4, 0xC5}` in little-endian memory layout
    - `TEST_CASE("mu_wchar_to_char16 — mixed script roundtrip")`
      - Convert `L"Hello \xD55C\xAD6D\xC5B4!"` → `char16_t*` → `mu_char16_to_wchar` → compare with original
    - `TEST_CASE("mu_wchar_to_char16 — null input")`
      - `mu_wchar_to_char16(nullptr)` returns empty `u16string` (no crash)
    - `TEST_CASE("mu_wchar_to_char16 — IP address (ASCII)")`
      - `L"127.0.0.1"` round-trips correctly (regression safety for Connection callers)
  - [ ] 7.2 Register in `MuMain/tests/CMakeLists.txt`:
    ```cmake
    # Story 3.2.1: char16_t Encoding at .NET Interop Boundary [VS1-NET-CHAR16T-ENCODING]
    target_sources(MuTests PRIVATE platform/test_char16t_encoding.cpp)
    ```

- [ ] **Task 8: Add ATDD CMake script** (AC: AC-VAL-3, AC-STD-11)
  - [ ] 8.1 Create `MuMain/tests/build/test_ac_std11_flow_code_3_2_1.cmake`:
    - Read `Connection.h` — verify `VS1-NET-CHAR16T-ENCODING` is present
    - Read `Connection.h` — verify `const char16_t*` appears (constructor parameter)
    - Read `Connection.h` — verify `const wchar_t*` does NOT appear in constructor/typedef
    - Read `Common.xslt` — verify `const wchar_t*` does NOT appear as nativetype for String
    - Read `Common.xslt` — verify `const char16_t*` appears as nativetype for String
  - [ ] 8.2 Register in `MuMain/tests/build/CMakeLists.txt`

- [ ] **Task 9: Quality gate** (AC: AC-STD-4, AC-STD-13)
  - [ ] 9.1 `./ctl check` — must pass (0 violations)
  - [ ] 9.2 Verify `cmake --preset macos-arm64` configures cleanly
  - [ ] 9.3 Verify MinGW cross-compile (`-DMU_ENABLE_DOTNET=OFF`) continues to work

---

## Error Codes Introduced

_None — this is a refactoring story. No new C++ error codes introduced._

_Diagnostic message format (via `g_ErrorReport.Write()` if encoding mismatch detected at runtime):_
```
NET: char16_t marshaling — encoding mismatch for <context>
```

---

## Contract Catalog Entries

### API Contracts

_None — internal refactor. No new API endpoints._

### Event Contracts

_None — no new events._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Encoding roundtrip (Catch2) | Catch2 v3.7.1 | N/A | Latin ASCII, Korean BMP, mixed script, null input, IP address string |
| Byte-level validation (Catch2) | Catch2 v3.7.1 | N/A | UTF-16LE byte sequence for 한국어 matches known baseline |
| No-wchar_t check (CMake script) | CMake `-P` | N/A | `Connection.h` and `Common.xslt` contain no `wchar_t` at interop boundary |
| Flow code traceability (CMake script) | CMake `-P` | N/A | `VS1-NET-CHAR16T-ENCODING` present in `Connection.h` |
| CI regression (automated) | MinGW CI | N/A | MinGW cross-compile build passes (`-DMU_ENABLE_DOTNET=OFF`) |

_Note: Full .NET interop integration test (actual connection to server with Korean character names) is deferred to story 3.3.1/3.3.2 (platform validation). Story 3.2.1 establishes the encoding boundary only._

---

## Dev Notes

### Overview

This story changes all C++↔.NET string marshaling from `wchar_t*` to `char16_t*`. The root cause: `wchar_t` is 2 bytes on Windows (UTF-16LE, same layout as `char16_t`) but **4 bytes** on Linux/macOS (UTF-32). The MU Online network protocol expects 2-byte UTF-16LE strings. Using `char16_t` makes the type self-documenting and cross-platform correct.

**What this story does NOT do:**
- Does NOT change `PacketBindings_*.h` or `PacketFunctions_*.h/.cpp` — these are XSLT-generated; the XSLT template change (Task 5) takes effect on next .NET publish/rebuild. Do NOT hand-edit generated files.
- Does NOT perform actual server connectivity testing — that is stories 3.3.1/3.3.2
- Does NOT change the `ConnectionManager_Send` or `ConnectionManager_Disconnect` exports (binary data only, no string params)

### Current State (BEFORE this story)

**Connection.h:**
```cpp
// CURRENT — wchar_t* at interop boundary (wrong on Linux/macOS)
Connection(const wchar_t* host, int32_t port, bool isEncrypted,
           void (*packetHandler)(int32_t, const BYTE*, int32_t));
```

**Connection.cpp (Connect typedef):**
```cpp
typedef int32_t(CORECLR_DELEGATE_CALLTYPE* Connect)(const wchar_t*, int32_t, BYTE, onPacketReceived, onDisconnected);
```

**Common.xslt (line 94):**
```xml
<xsl:template match="pd:Type[. = 'String']" mode="nativetype">const wchar_t*</xsl:template>
```

**ConnectionManager.cs:**
```csharp
var host = Marshal.PtrToStringAuto(hostPtr) ...  // auto-detects ANSI or Unicode — ambiguous
```

### Target State (AFTER this story)

**Connection.h:**
```cpp
// Flow Code: VS1-NET-CHAR16T-ENCODING
Connection(const char16_t* host, int32_t port, bool isEncrypted,
           void (*packetHandler)(int32_t, const BYTE*, int32_t));
```

**Connection.cpp (Connect typedef):**
```cpp
typedef int32_t(CORECLR_DELEGATE_CALLTYPE* Connect)(const char16_t*, int32_t, BYTE, onPacketReceived, onDisconnected);
```

**Common.xslt:**
```xml
<xsl:template match="pd:Type[. = 'String']" mode="nativetype">const char16_t*</xsl:template>
```

**ConnectionManager.cs:**
```csharp
var host = Marshal.PtrToStringUni(hostPtr) ...  // explicit UTF-16LE, matches char16_t
```

**WSclient.cpp caller:**
```cpp
// BEFORE: SocketClient = new Connection(IpAddr, Port, isEncrypted, &HandleIncomingPacket);
// AFTER:
const std::u16string host16 = mu_wchar_to_char16(IpAddr);
SocketClient = new Connection(host16.c_str(), Port, isEncrypted, &HandleIncomingPacket);
```

### Encoding Correctness Analysis

| Platform | `sizeof(wchar_t)` | `sizeof(char16_t)` | Conversion |
|----------|-------------------|-------------------|------------|
| Windows (MSVC/MinGW) | 2 bytes | 2 bytes | `reinterpret_cast` safe (same bit layout) |
| Linux (GCC) | 4 bytes | 2 bytes | Must transcode UTF-32 → UTF-16 |
| macOS (Clang) | 4 bytes | 2 bytes | Must transcode UTF-32 → UTF-16 |

IP addresses only use ASCII (U+0000–U+007F): all codepoints fit in 1 char16_t, conversion is trivial.
Korean game text uses BMP codepoints (U+AC00–U+D7A3 Hangul syllables): all fit in 1 char16_t, no surrogates needed.
Non-BMP codepoints (U+10000+): not expected in game text, but `mu_wchar_to_char16` handles them via surrogate pairs.

### Files to Modify

| File | Change |
|------|--------|
| `MuMain/src/source/Dotnet/Connection.h` | Constructor declaration: `wchar_t*` → `char16_t*`; add flow code comment |
| `MuMain/src/source/Dotnet/Connection.cpp` | `Connect` typedef + constructor definition: `wchar_t*` → `char16_t*` |
| `MuMain/src/source/Platform/PlatformCompat.h` | Add `mu_wchar_to_char16` and `mu_char16_to_wchar` utilities |
| `MuMain/src/source/Network/WSclient.cpp` | `CreateSocket` caller: convert `wchar_t*` via `mu_wchar_to_char16` |
| `MuMain/src/source/UI/Legacy/UIWindows.cpp` | Two `Connection()` construction sites: convert host param (verify type at each site) |
| `MuMain/ClientLibrary/Common.xslt` | Line 94: `const wchar_t*` → `const char16_t*` for String nativetype |
| `MuMain/ClientLibrary/ConnectionManager.cs` | `PtrToStringAuto` → `PtrToStringUni` |

### Files to Create

| File | Purpose |
|------|---------|
| `MuMain/tests/platform/test_char16t_encoding.cpp` | Catch2 roundtrip + byte-level encoding tests |
| `MuMain/tests/build/test_ac_std11_flow_code_3_2_1.cmake` | ATDD: flow code + no-wchar_t checks |

### Generated Files (DO NOT EDIT)

The following files are generated by XSLT and must NOT be hand-edited even though they currently contain `wchar_t*`:
- `MuMain/src/source/Dotnet/PacketBindings_*.h`
- `MuMain/src/source/Dotnet/PacketFunctions_*.h` / `.cpp`

They will be regenerated (with `char16_t*`) when the .NET ClientLibrary is published. For CI (`-DMU_ENABLE_DOTNET=OFF`), these files are not compiled, so existing `wchar_t*` in generated files does not break CI.

### Risk R7 Mitigation (Sprint Risk)

Sprint status identified Risk R7: "char16_t encoding conversion may produce different results on GCC vs MSVC for edge cases."

Mitigation implemented in this story:
- `mu_wchar_to_char16` uses compile-time `if constexpr (sizeof(wchar_t) == sizeof(char16_t))` to select the correct path — no runtime branching, no UB
- Catch2 tests use hardcoded byte-level UTF-16LE baselines (not derived from `wchar_t`) to detect cross-compiler discrepancies
- Korean test vector `L"\xD55C\xAD6D\xC5B4"` (한국어) has known UTF-16LE bytes: `55 D5 6D AD B4 C5`

### PCC Project Constraints

- **Banned API:** No `wchar_t` at the .NET interop boundary after this story
- **Required pattern:** `g_ErrorReport.Write()` for error logging (NOT `wprintf`)
- **C++ standard:** C++20 — `if constexpr`, `std::u16string`, `char16_t` all available
- **Testing:** Catch2 v3.7.1 — `REQUIRE` / `CHECK`, `TEST_CASE` / `SECTION` — no mock framework
- **CMake:** New `.cpp` test file added via `target_sources(MuTests PRIVATE ...)` in `tests/CMakeLists.txt`
- **Formatting:** Allman braces, 4-space indent — `./ctl format` before committing
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### Previous Story Intelligence (from 3.1.2)

Story 3.1.2 explicitly deferred `wchar_t→char16_t` changes:
> "Does NOT change the `wchar_t` parameter in `Connection::Connection(const wchar_t* host, ...)` — that is deferred to story 3.2.1"
> "Does NOT change function pointer signatures (CORECLR types, `Connect`/`Disconnect`/etc.) — those are deferred to 3.2.1"

The `symLoad` compatibility shim (`inline void* symLoad(...)` in `Connection.h`) introduced in 3.1.2 code review may be removable once XSLT is regenerated — but **do NOT remove it in this story** until generated files are updated. Keep the shim for now, it will be removed as part of XSLT regeneration in a future story.

### Commit Convention

```
refactor(network): replace wchar_t with char16_t at .NET boundary

- Connection::Connection now accepts const char16_t* host (cross-platform correct)
- ConnectionManager_Connect uses Marshal.PtrToStringUni (explicit UTF-16LE)
- Common.xslt String nativetype produces const char16_t* for generated bindings
- mu_wchar_to_char16 utility handles 2-byte (Win) and 4-byte (Linux/macOS) wchar_t
- Catch2 tests validate Korean + Latin round-trips and byte-level encoding

Flow Code: VS1-NET-CHAR16T-ENCODING
Closes: 3-2-1-char16t-encoding
```

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List

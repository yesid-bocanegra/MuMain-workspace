# Story 7.6.3: Data Layer Win32 Removal

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.6 - macOS Native Build Compilation |
| Story ID | 7.6.3 |
| Story Points | 5 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-WIN32CLEAN-DATALAYER |
| FRs Covered | Cross-platform parity — zero `#ifdef _WIN32` in game logic |
| Prerequisites | 7-6-1-macos-native-build-compilation (in-progress) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Remove Win32 GUI dialogs from Data layer; replace Windows DPAPI with cross-platform crypto abstraction |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** all Win32 dependencies removed from `Data/DataFileIO.cpp` and `Data/GameConfig.cpp`,
**so that** data loading and configuration encryption work identically on Windows, macOS, and Linux.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — no violations in `Data/`.
- [ ] **AC-2:** `Data/DataFileIO.cpp` — `MessageBox()` dialog calls replaced with `g_ErrorReport.Write()` logging; no `windows.h` or Win32 GUI API usage in data loading code.
- [ ] **AC-3:** `Data/GameConfig.cpp` / `Data/GameConfig.h` — Windows DPAPI (`CryptProtectData`, `CryptUnprotectData`, `DATA_BLOB`, `LocalFree`) replaced with a cross-platform `mu_encrypt_blob` / `mu_decrypt_blob` abstraction in `PlatformCompat.h`.
  - On Windows: `mu_encrypt_blob` wraps DPAPI (same behaviour as today).
  - On macOS/Linux: `mu_encrypt_blob` uses AES-256-GCM via OpenSSL (`libcrypto`) with a machine-derived key (e.g. derived from machine hostname + fixed salt via PBKDF2), or if OpenSSL is unavailable, stores data as-is with a compile-time warning.
- [ ] **AC-4:** No `#ifdef _WIN32` wraps any function call or data type in `Data/DataFileIO.cpp` or `Data/GameConfig.cpp`.
- [ ] **AC-5:** `./ctl check` passes — build + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — no new `#ifdef _WIN32` outside `Platform/`; `g_ErrorReport.Write()` used for error output in data layer (not `MessageBox`, not `wprintf`); clang-format clean.
- [ ] **AC-STD-2:** Tests — logic for encrypt/decrypt round-trips should have a Catch2 unit test in `tests/data/test_gameconfig_crypto.cpp`.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Data/DataFileIO.cpp — remove MessageBox** (AC-2)
  - [ ] 1.1: Locate all `MessageBox(...)` or `MessageBoxW(...)` calls in `DataFileIO.cpp`
  - [ ] 1.2: Replace each with `g_ErrorReport.Write(L"[DataFileIO] ...")` — the message goes to `MuError.log`, not a GUI dialog; this is the correct pattern for asset failures
  - [ ] 1.3: Remove `windows.h` include if it was only needed for `MessageBox`
  - [ ] 1.4: Remove any `#ifdef _WIN32` wrapper blocks

- [ ] **Task 2: Data/GameConfig — add platform crypto abstraction** (AC-3)
  - [ ] 2.1: Add to `Platform/PlatformCompat.h` (in the `#else // !_WIN32` section):
    ```cpp
    // mu_encrypt_blob / mu_decrypt_blob — cross-platform DPAPI equivalent.
    // macOS/Linux: AES-256-GCM via OpenSSL or identity (no-op) fallback.
    inline bool mu_encrypt_blob(const void* pIn, DWORD cbIn, void** ppOut, DWORD* pcbOut);
    inline bool mu_decrypt_blob(const void* pIn, DWORD cbIn, void** ppOut, DWORD* pcbOut);
    inline void mu_free_blob(void* p);  // matches LocalFree semantics
    ```
  - [ ] 2.2: Add to `Platform/PlatformCompat.h` (in the `#ifdef _WIN32` section): forward to DPAPI
  - [ ] 2.3: In `Data/GameConfig.cpp`, replace `CryptProtectData(...)` with `mu_encrypt_blob(...)` and `CryptUnprotectData(...)` with `mu_decrypt_blob(...)`
  - [ ] 2.4: Replace `LocalFree(pBlob.pbData)` with `mu_free_blob(pBlob.pbData)`
  - [ ] 2.5: Remove `DATA_BLOB`, `DPAPI`, `#include <wincrypt.h>` — types now hidden behind abstraction
  - [ ] 2.6: Remove `#ifdef _WIN32` wrappers from `GameConfig.cpp` and `GameConfig.h`

- [ ] **Task 3: OpenSSL CMake integration** (AC-3)
  - [ ] 3.1: In `MuMain/src/CMakeLists.txt`, add `find_package(OpenSSL OPTIONAL_COMPONENTS Crypto)` for non-Windows builds
  - [ ] 3.2: If found, add `target_link_libraries(MUCore PRIVATE OpenSSL::Crypto)` and define `MU_HAS_OPENSSL=1`
  - [ ] 3.3: In `PlatformCompat.h` non-Windows section, `#if defined(MU_HAS_OPENSSL)` → AES-256-GCM impl, `#else` → identity no-op with `g_ErrorReport.Write()` warning

- [ ] **Task 4: Unit test** (AC-STD-2)
  - [ ] 4.1: Create `tests/data/test_gameconfig_crypto.cpp`
  - [ ] 4.2: `TEST_CASE("mu_encrypt_blob round-trips")` — encrypt a known payload, decrypt it, compare
  - [ ] 4.3: Register in `tests/CMakeLists.txt` (or `tests/data/CMakeLists.txt`)

- [ ] **Task 5: Validate** (AC-1, AC-5)
  - [ ] 5.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `Data/`
  - [ ] 5.2: Run `./ctl check` — exits 0

---

## Error Codes Introduced

None — infrastructure story.

---

## Contract Catalog Entries

None — no API, event, or navigation contracts.

---

## Dev Notes

### Critical Rule (from project-context.md)

**NO `#ifdef _WIN32` in game logic.** Every block must be removed; Win32 APIs must be abstracted via `PlatformCompat.h`.

### MessageBox Replacement

`MessageBox` in data loading code is always an error report — replace unconditionally with `g_ErrorReport.Write()`.

```cpp
// BEFORE
#ifdef _WIN32
MessageBoxW(nullptr, L"Failed to load item data", L"Error", MB_OK);
#endif

// AFTER
g_ErrorReport.Write(L"[DataFileIO] Failed to load item data\r\n");
```

### DPAPI Abstraction Design

```
PlatformCompat.h
  #ifdef _WIN32
    mu_encrypt_blob → CryptProtectData (DPAPI, user-scoped)
    mu_decrypt_blob → CryptUnprotectData
    mu_free_blob    → LocalFree
  #else
    #if MU_HAS_OPENSSL
      mu_encrypt_blob → AES-256-GCM, key = PBKDF2(gethostname(), fixed_salt, 100000, SHA-256)
      mu_decrypt_blob → AES-256-GCM decrypt
      mu_free_blob    → free()
    #else
      mu_encrypt_blob → identity (copy as-is, log warning)
      mu_decrypt_blob → identity
      mu_free_blob    → free()
    #endif
  #endif
```

**Security note:** The no-op fallback is acceptable for development builds. Game config encryption is a convenience feature, not a security boundary — the game client runs locally and the user has file system access anyway.

### Logging Mechanism

| Use case | Mechanism |
|---|---|
| Asset load failure | `g_ErrorReport.Write(L"[Module] message\r\n")` |
| Crypto warning | `g_ErrorReport.Write(L"[GameConfig] WARN: OpenSSL unavailable, config not encrypted\r\n")` |
| Never use | `MessageBox`, `wprintf`, `__TraceF()` |

### References

- [Source: _bmad-output/project-context.md#Logging]
- [Source: _bmad-output/project-context.md#Prohibited Code Patterns]
- [Source: MuMain/src/source/Platform/PlatformCompat.h]
- [Source: MuMain/src/source/Core/ErrorReport.h]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

### File List

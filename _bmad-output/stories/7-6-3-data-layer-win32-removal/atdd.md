# ATDD Checklist — Story 7.6.3: Data Layer Win32 Removal

**Story Key:** 7-6-3-data-layer-win32-removal
**Story Type:** infrastructure
**Phase:** RED → GREEN (implementation pending)
**ATDD Phase:** RED — test file exists, functions not yet implemented

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Method | Status |
|----|-------------|-----------|-------------|--------|
| AC-1 | check-win32-guards.py exits 0 for Data/ | Script-only (not unit testable) | `python3 MuMain/scripts/check-win32-guards.py` | Validate in Task 5.1 |
| AC-2 | DataFileIO.cpp MessageBox → g_ErrorReport.Write | No unit test (logging side-effect, not logic) | Manual code review + AC-1 script | Validate in code review |
| AC-3 | mu_encrypt_blob / mu_decrypt_blob round-trips | `tests/data/test_gameconfig_crypto.cpp` | `TEST_CASE("AC-3: mu_encrypt_blob round-trips plaintext bytes")` | **RED** |
| AC-3 | AES-256-GCM tamper detection | `tests/data/test_gameconfig_crypto.cpp` | `TEST_CASE("AC-3: mu_decrypt_blob rejects tampered ciphertext")` | **RED** |
| AC-3 | Random IV/nonce per encryption | `tests/data/test_gameconfig_crypto.cpp` | `TEST_CASE("AC-3: mu_encrypt_blob uses a random IV/nonce per call")` | **RED** |
| AC-4 | No #ifdef _WIN32 in DataFileIO.cpp / GameConfig.cpp | Script-only (check-win32-guards.py) | `python3 MuMain/scripts/check-win32-guards.py` | Validate in Task 5.1 |
| AC-5 | ./ctl check passes | Quality gate | `./ctl check` | Validate in Task 5.2 |
| AC-STD-1 | Code standards (no new #ifdef _WIN32, g_ErrorReport) | Code review | clang-format + cppcheck | Validate in quality gate |
| AC-STD-2 | Catch2 unit test for encrypt/decrypt round-trips | `tests/data/test_gameconfig_crypto.cpp` | All TEST_CASEs in file | **RED** |
| AC-STD-13 | ./ctl check exits 0 | Quality gate | `./ctl check` | Validate in Task 5.2 |
| AC-STD-15 | Git safety | Process | No force push, no incomplete rebase | Dev process |

---

## Test Files Created (RED Phase)

| File | Phase | Fails Until |
|------|-------|------------|
| `MuMain/tests/data/test_gameconfig_crypto.cpp` | RED | Task 2.1: `mu_encrypt_blob`/`mu_decrypt_blob` added to `PlatformCompat.h` + Task 3.2: OpenSSL::Crypto linked |

---

## Implementation Checklist

### PCC Compliance

- [ ] No prohibited libraries used (Win32 DPAPI removed, OpenSSL::Crypto used instead)
- [ ] `mu_encrypt_blob` / `mu_decrypt_blob` follow required patterns (return `bool`, `std::vector<uint8_t>&` out-param)
- [ ] No `#ifdef _WIN32` in game logic files (Data/DataFileIO.cpp, Data/GameConfig.cpp, Data/GameConfig.h)
- [ ] New code uses `std::unique_ptr` / RAII — no raw `new`/`delete`
- [ ] Error logging uses `g_ErrorReport.Write()` — not `MessageBox`, not `wprintf`
- [ ] All test TUs compile without Win32 APIs on macOS/Linux/MinGW CI

### Functional ACs

- [ ] AC-1: `python3 MuMain/scripts/check-win32-guards.py` exits 0 — zero violations in `Data/`
- [ ] AC-2: `Data/DataFileIO.cpp` — all `MessageBox()`/`MessageBoxW()` replaced with `g_ErrorReport.Write()`; `windows.h` removed from DataFileIO.cpp
- [ ] AC-3: `mu_encrypt_blob` / `mu_decrypt_blob` implemented in `PlatformCompat.h` with AES-256-GCM (OpenSSL) or identity no-op fallback
- [ ] AC-3: `Data/GameConfig.cpp` — `CryptProtectData`/`CryptUnprotectData`/`LocalFree` replaced with `mu_encrypt_blob`/`mu_decrypt_blob`
- [ ] AC-3: `<wincrypt.h>`, `<dpapi.h>`, `DATA_BLOB` removed from GameConfig.cpp and GameConfig.h
- [ ] AC-4: No `#ifdef _WIN32` wraps any function call or data type in `DataFileIO.cpp` or `GameConfig.cpp`
- [ ] AC-5: `./ctl check` exits 0 (format-check + lint)

### Standard ACs

- [ ] AC-STD-1: clang-format clean; no new `#ifdef _WIN32` outside `Platform/`; `g_ErrorReport.Write()` used in data layer
- [ ] AC-STD-2: `tests/data/test_gameconfig_crypto.cpp` exists with passing round-trip tests (GREEN phase)
- [ ] AC-STD-13: `./ctl check` exits 0
- [ ] AC-STD-15: No force push, no incomplete rebase

### Test Quality

- [ ] `test_gameconfig_crypto.cpp` — TEST_CASE "AC-3: mu_encrypt_blob round-trips plaintext bytes" passes (GREEN)
- [ ] `test_gameconfig_crypto.cpp` — TEST_CASE "AC-3: mu_decrypt_blob rejects tampered ciphertext" passes (GREEN)
- [ ] `test_gameconfig_crypto.cpp` — TEST_CASE "AC-3: mu_encrypt_blob uses a random IV/nonce per call" passes (GREEN)
- [ ] All test TUs have no Win32 API usage
- [ ] MuTests build succeeds with `-DBUILD_TESTING=ON` on macOS/Linux/MinGW CI
- [ ] `tests/CMakeLists.txt` registers `data/test_gameconfig_crypto.cpp` ✅ (done in RED phase)

### CMake / Build

- [ ] `find_package(OpenSSL OPTIONAL_COMPONENTS Crypto)` added to `MuMain/src/CMakeLists.txt`
- [ ] `target_link_libraries(MUCore PRIVATE OpenSSL::Crypto)` and `-DMU_HAS_OPENSSL=1` added when found
- [ ] `PlatformCompat.h` `#if defined(MU_HAS_OPENSSL)` guards AES-256-GCM impl; `#else` falls back to no-op with `g_ErrorReport.Write()` warning
- [ ] Windows build invariant maintained (MinGW CI passes)

---

## Notes

- **OpenSSL availability:** DPAPI is removed on ALL platforms including Windows. OpenSSL is the single implementation. If `find_package(OpenSSL)` fails, the no-op fallback logs a warning and passes bytes through unencrypted (acceptable — game config encryption is a convenience feature, not a security boundary).
- **Key derivation:** PBKDF2(gethostname(), fixed_salt, 100000, SHA-256) — machine-bound, same as DPAPI behavior.
- **Test isolation:** Tests in `test_gameconfig_crypto.cpp` are pure logic tests — no file system, no singleton state, no game loop dependency.
- **`mu_encrypt_blob` / `mu_decrypt_blob` location:** `Platform/PlatformCompat.h` non-Windows `#else` section (Task 2.1). The Windows section also gets the OpenSSL impl — no `#ifdef _WIN32` toggle.

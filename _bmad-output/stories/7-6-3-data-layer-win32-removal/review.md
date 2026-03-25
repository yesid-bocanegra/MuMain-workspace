# Code Review — Story 7.6.3: Data Layer Win32 Removal

**Reviewer:** Claude Opus 4.6 (adversarial)
**Date:** 2026-03-25
**Story Key:** 7-6-3-data-layer-win32-removal
**Review Type:** Adversarial code review — find and document issues

---

## Quality Gate

**Status:** PASS — all checks green

| Check | Component | Result |
|-------|-----------|--------|
| lint | mumain (backend) | **PASS** — `make -C MuMain lint` |
| build | mumain (backend) | **PASS** — cmake configure + build |
| coverage | mumain (backend) | **PASS** — no coverage configured yet |
| boot | N/A | **SKIP** — game client binary, no server to boot |

**Non-deterministic checks:** None applicable (no SonarCloud, no schema alignment, no E2E tests for this infrastructure story).

---

## Findings

### HIGH-1: No-op fallback missing required g_ErrorReport.Write() warning

| Attribute | Value |
|-----------|-------|
| Severity | HIGH |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Lines | 2637–2658 |

**Description:** The identity no-op fallback for `mu_encrypt_blob` / `mu_decrypt_blob` (when `MU_HAS_OPENSSL` is not defined) silently passes bytes through unencrypted without any warning. The story's Task 3.3 explicitly requires: *"`#else` → identity no-op with `g_ErrorReport.Write()` warning"*. The ATDD checklist (CMake / Build, item 3) is marked GREEN but the code does not match — no logging occurs in the no-op path.

**Suggested Fix:** Add a one-time `g_ErrorReport.Write(L"[GameConfig] WARN: OpenSSL unavailable, config not encrypted\r\n")` call in the no-op `mu_encrypt_blob` (e.g., via a `static bool warned = false` guard to avoid per-call spam). Alternatively, if `g_ErrorReport` is not available at PlatformCompat.h include time, use `fprintf(stderr, ...)` or accept the deviation and update the story/ATDD to reflect the design decision.

---

### HIGH-2: wchar_t size mismatch breaks cross-platform credential portability

| Attribute | Value |
|-----------|-------|
| Severity | HIGH |
| File | `MuMain/src/source/Data/GameConfig.cpp` |
| Lines | 286, 302 |

**Description:** `EncryptSetting()` serializes credential strings as raw `wchar_t` bytes: `(wcslen(input) + 1) * sizeof(wchar_t)`. `DecryptSetting()` reconstructs via `reinterpret_cast<const wchar_t*>(decrypted.data()), decrypted.size() / sizeof(wchar_t)`. On Windows `sizeof(wchar_t) == 2` (UTF-16LE); on macOS/Linux `sizeof(wchar_t) == 4` (UTF-32). A `config.ini` encrypted on one platform is unreadable on another — the byte count and encoding differ.

Since credentials are machine-bound (PBKDF2 with hostname), cross-platform config portability may be intentionally out of scope. If so, this should be explicitly documented. If cross-platform config files are ever desired, the fix is to serialize to a fixed-width encoding (e.g., UTF-8) before encryption.

**Suggested Fix:** Add a comment at both `EncryptSetting()` and `DecryptSetting()` documenting that the serialization format is platform-specific and not portable. Alternatively, serialize credentials as UTF-8 via `mu_wchar_to_utf8` before encryption for future-proofing.

---

### MEDIUM-1: Cryptographic key material not zeroed after use

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Lines | 2498, 2577 |

**Description:** Both `mu_encrypt_blob` and `mu_decrypt_blob` declare `uint8_t key[MU_CRYPTO_KEY_LEN]` on the stack and never zero it after use. While the compiler will deallocate the stack frame, the key bytes remain in memory until overwritten by subsequent calls. A `memset` would likely be optimized away by the compiler. Crypto best practice is to use `OPENSSL_cleanse(key, sizeof(key))` (which is guaranteed not to be optimized out) or `explicit_bzero` on POSIX.

The story notes that game config encryption is a "convenience feature, not a security boundary," which mitigates the severity. However, OPENSSL_cleanse is a one-line fix and establishes good hygiene.

**Suggested Fix:** Add `OPENSSL_cleanse(key, MU_CRYPTO_KEY_LEN);` before `return ok;` in both functions.

---

### MEDIUM-2: DataFileIO error messages missing [DataFileIO] prefix and \r\n suffix

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Data/DataFileIO.cpp` |
| Lines | 17, 27 |

**Description:** The story's Dev Notes specify the logging pattern as: `g_ErrorReport.Write(L"[DataFileIO] Failed to load item data\r\n")`. But the actual calls pass bare messages without the `[DataFileIO]` prefix or `\r\n` line terminator:
- Line 17: `ShowErrorAndExit(L"Failed to read data from file")`
- Line 27: `ShowErrorAndExit(L"Failed to read checksum from file")`

The `ShowErrorAndExit` wrapper (line 57–60) just forwards the message verbatim. This reduces log traceability (no module prefix) and may cause log lines to run together (no line terminator).

**Suggested Fix:** Either update `ShowErrorAndExit` to prepend `[DataFileIO]` and append `\r\n`, or update the caller strings to include both.

---

### MEDIUM-3: static_cast<int>(cbIn) truncates on payloads > 2 GB

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Lines | 2534, 2607 |

**Description:** `EVP_EncryptUpdate` and `EVP_DecryptUpdate` take `int` for the input length. The code casts `cbIn` (a `size_t`) to `int` via `static_cast<int>(cbIn)`. If `cbIn > INT_MAX` (~2.1 GB), this is undefined behavior and would silently corrupt the encryption. While credential strings will never approach this size, the function has a generic API (`const void*, size_t`) that doesn't communicate the limitation.

**Suggested Fix:** Add an early-return guard: `if (cbIn > static_cast<size_t>(INT_MAX)) return false;`

---

### LOW-1: ShowErrorAndExit name is misleading post-refactor

| Attribute | Value |
|-----------|-------|
| Severity | LOW |
| File | `MuMain/src/source/Data/DataFileIO.cpp` |
| Lines | 57–60 |

**Description:** `ShowErrorAndExit` was likely originally a `MessageBox` + exit flow. After the refactor, it only calls `g_ErrorReport.Write()` and returns — it neither "shows" a dialog nor "exits." The callers return `nullptr` to propagate the error, but the function name suggests a terminal action. This is a readability issue for future maintainers.

**Suggested Fix:** Rename to `LogError` or `ReportError` to match the actual behavior.

---

### LOW-2: const_cast on GCM auth tag pointer

| Attribute | Value |
|-----------|-------|
| Severity | LOW |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Line | 2611 |

**Description:** `const_cast<uint8_t*>(tag)` is used to satisfy `EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, ...)` which takes a non-const `void*` despite only reading the tag. This is a known OpenSSL API wart (fixed in OpenSSL 3.x with `EVP_CIPHER_CTX_ctrl` accepting `const void*` for GET/SET). The cast is correct behavior but should be annotated.

**Suggested Fix:** Add a brief comment: `// OpenSSL API requires non-const; tag is not modified`

---

## ATDD Coverage

| AC | ATDD Status | Review Verdict | Notes |
|----|-------------|----------------|-------|
| AC-1 | GREEN | **PASS** | `check-win32-guards.py` validates Data/ — no Win32 guards found |
| AC-2 | GREEN | **PASS** | MessageBox calls replaced with g_ErrorReport.Write(); windows.h removed from DataFileIO.cpp |
| AC-3 | GREEN | **PASS** | mu_encrypt_blob / mu_decrypt_blob implemented with AES-256-GCM; DPAPI fully removed |
| AC-4 | GREEN | **PASS** | No `#ifdef _WIN32` in DataFileIO.cpp or GameConfig.cpp |
| AC-5 | GREEN | **PASS** | Quality gate passes (721/721 files) |
| AC-STD-1 | GREEN | **PASS** | Code standards met |
| AC-STD-2 | GREEN | **PASS** | 3 Catch2 test cases with meaningful assertions |
| AC-STD-13 | GREEN | **PASS** | ./ctl check exits 0 |
| AC-STD-15 | GREEN | **PASS** | No force push, clean git history |

### ATDD Accuracy Issue

**CMake / Build checklist item 3** is marked `[x]` GREEN: *"`PlatformCompat.h` `#if defined(MU_HAS_OPENSSL)` guards AES-256-GCM impl; `#else` falls back to no-op with `g_ErrorReport.Write()` warning"*. The no-op fallback does **not** call `g_ErrorReport.Write()`. This checklist item should be marked as incomplete until HIGH-1 is resolved.

---

## Test Quality Assessment

The 3 test cases in `test_gameconfig_crypto.cpp` are well-structured:

1. **Round-trip test** — covers ASCII, binary with embedded nulls, and wstring payloads. Good coverage of the credential use case.
2. **Tamper detection** — flips a byte and verifies GCM authentication failure. Meaningful assertion.
3. **Random IV** — encrypts same plaintext twice and verifies different ciphertext. Proves nonce uniqueness.

**Test gap:** No test for empty/null input behavior of `mu_decrypt_blob` (only tested on `mu_encrypt_blob`). The empty-input SECTION in test 1 only tests the encrypt path's null/zero handling; there's no dedicated SECTION for calling `mu_decrypt_blob` with garbage/short input to verify the minimum-size guard (IV + tag).

---

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 2 |
| **Total** | **7** |

The implementation successfully removes all Win32 dependencies from the Data layer and provides a solid AES-256-GCM encryption replacement. The two HIGH issues are: (1) the no-op fallback missing its required log warning (ATDD mismatch), and (2) the wchar_t serialization format being platform-specific (design concern that should at minimum be documented). All other issues are code hygiene improvements.

# Code Review — Story 7.6.6: ShopListManager Cross-Platform HTTP Downloader

**Reviewer:** Claude (adversarial code review)
**Date:** 2026-03-25
**Story Key:** 7-6-6-shoplistmanager-http-cross-platform

---

## Pipeline Status

| Step | Status |
|------|--------|
| 1. Quality Gate | **PASSED** |
| 2. Code Review Analysis | PASSED (adversarial review complete — 8 findings) |
| 3. Code Review Finalize | Pending |

## Quality Gate

**Status:** PASSED
**Date:** 2026-03-25
**Components:** mumain (backend)

| Check | Result | Notes |
|-------|--------|-------|
| lint | **PASS** | `make -C MuMain lint` — 0 errors |
| build | **PASS** | CMake + Ninja debug build — clean |
| coverage | **PASS** | No coverage configured yet |
| SonarCloud | N/A | Not configured for this project |
| Frontend | N/A | No frontend components |
| Schema Alignment | N/A | No frontend/backend schema contract |
| AC Compliance | N/A | Infrastructure story — skipped |
| E2E Test Quality | N/A | No E2E tests (infrastructure story) |
| App Startup | N/A | Game client — no server boot check |

---

## Findings

### Finding 1: BannerInfo.cpp — curl_easy_perform return value unchecked

| Attribute | Value |
|-----------|-------|
| Severity | **HIGH** |
| File | `MuMain/src/source/GameShop/ShopListManager/BannerInfo.cpp` |
| Lines | 97 |
| Category | Error handling / Silent failure |

**Description:** `curl_easy_perform(curl)` return value is discarded at line 97. If the download fails (network error, DNS failure, timeout), the partially-written or empty file remains on disk. `SetBanner()` returns `true` regardless of download outcome, so the game UI will attempt to display a corrupt or zero-byte banner image.

**Suggested fix:** Check `CURLcode res = curl_easy_perform(curl)`. On failure, delete the partial file with `std::filesystem::remove()` and either return `false` or log via `g_ErrorReport`.

---

### Finding 2: ListManager.cpp — broken trailing-slash check (off-by-one)

| Attribute | Value |
|-----------|-------|
| Severity | **HIGH** |
| File | `MuMain/src/source/GameShop/ShopListManager/ListManager.cpp` |
| Lines | 66-74 |
| Category | Logic error |

**Description:** `m_strLocalPath.substr(m_strLocalPath.size(), 1)` at line 66 (and identically at line 71 for remote path) always returns an empty string because `substr(size(), count)` starts past the last character. The comparison `!= L"/"` is therefore always true, and a trailing `/` is unconditionally appended — even when one already exists. This produces double-slash paths like `"Data/ShopList//"`.

**Suggested fix:** Change `substr(size(), 1)` to `substr(size() - 1, 1)`, or better: `if (!m_strLocalPath.empty() && m_strLocalPath.back() != L'/')`.

---

### Finding 3: ShopList.cpp — `(wchar_t*)` type-pun cast breaks on non-Windows

| Attribute | Value |
|-----------|-------|
| Severity | **HIGH** |
| File | `MuMain/src/source/GameShop/ShopListManager/ShopList.cpp` |
| Lines | 253, 267 |
| Category | Portability / Undefined behavior |

**Description:** `GetDecodedString()` casts `char*` to `wchar_t*` and assigns to `std::wstring` at lines 253 and 267. On Windows, `wchar_t` is 2 bytes, so this reinterprets pairs of bytes as characters — it worked historically by accident for ANSI text. On macOS/Linux, `wchar_t` is 4 bytes, so this reads 4x beyond the buffer and produces complete garbage. This code was previously hidden behind `#ifdef _WIN32` and is now exposed after guard removal.

**Suggested fix:** Replace the `FE_ANSI` branch with proper `mbstowcs()` or a `std::mbsrtowcs()` call. For the UTF-8 branch, use the PlatformCompat.h `MultiByteToWideChar` stub result directly without the round-trip through `WideCharToMultiByte` → raw cast.

---

### Finding 4: Path.cpp — ReadFileLastLine never populates output parameter

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/src/source/GameShop/ShopListManager/interface/PathMethod/Path.cpp` |
| Lines | 189-225 |
| Category | Logic error |

**Description:** `ReadFileLastLine(szFile, szLastLine)` reads file lines into local `char buff[1024]` in a loop, but never copies the final line to the `wchar_t* szLastLine` output parameter. At line 216, `wcslen(szLastLine)` reads whatever the caller passed in (potentially uninitialized), making the return value meaningless. The function name and signature promise to return the last line, but the output parameter is never written.

**Suggested fix:** After the read loop, convert `buff` to wide chars and copy into `szLastLine` (e.g., via `mbstowcs`).

---

### Finding 5: FTPFileDownLoader.cpp — static local WZResult is not thread-safe

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/src/source/GameShop/ShopListManager/FTPFileDownLoader.cpp` |
| Lines | 30 |
| Category | Thread safety |

**Description:** `static WZResult result` at line 30 persists across calls. Since `ListManager::FileDownLoad()` uses `std::async` to run downloads in a background thread, concurrent invocations of `DownLoadFiles` would race on this shared static variable. The same pattern appears in `ShopList.cpp:132` (`LoadProduct`) and `BannerInfoList.cpp:23`.

**Suggested fix:** Change `static WZResult result` to a plain local `WZResult result`. The static qualifier serves no purpose here since the result is returned by value.

---

### Finding 6: FTPConnecter.cpp — empty passive mode branch

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/src/source/GameShop/FileDownloader/FTPConnecter.cpp` |
| Lines | 40-43 |
| Category | Correctness / Clarity |

**Description:** When `IsPassive()` is `true`, the code enters an empty block with only a comment: `// EPRT/EPSV disabled = passive mode`. No curl option is set. The code relies on libcurl's default behavior (passive FTP), but this is undocumented and fragile. If libcurl defaults change or `CURLOPT_FTPPORT` was previously set on a reused handle, this would silently break. The active-mode branch at line 46 is explicit, but the passive branch is not.

**Suggested fix:** Explicitly set `curl_easy_setopt(curl, CURLOPT_FTP_USE_EPSV, 1L)` for passive mode, or add a definitive comment citing the libcurl documentation.

---

### Finding 7: ATDD checklist inaccuracy — claims std::unique_ptr for CURL RAII

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `_bmad-output/stories/7-6-6-shoplistmanager-http-cross-platform/atdd.md` |
| Lines | 126 |
| Category | Documentation / ATDD accuracy |

**Description:** The PCC Compliance Items section claims `[x] std::unique_ptr for curl handle RAII (no raw new/delete for curl resources)`. However, all CURL handles in the implementation use raw `curl_easy_init()` / `curl_easy_cleanup()` pairs: `FileDownloader.cpp:115-214`, `BannerInfo.cpp:85-100`. Additionally, `new FileDownloader(...)` / `SAFE_DELETE(m_pFileDownloader)` in `FTPFileDownLoader.cpp:60-64` uses raw new/delete. Zero `std::unique_ptr` usages exist for curl or connecter resources.

**Suggested fix:** Either implement RAII wrappers (e.g., `std::unique_ptr<CURL, decltype(&curl_easy_cleanup)>`) or uncheck the ATDD compliance item to reflect reality.

---

### Finding 8: ShopList.cpp — Win32 encoding APIs outside Platform layer

| Attribute | Value |
|-----------|-------|
| Severity | **LOW** |
| File | `MuMain/src/source/GameShop/ShopListManager/ShopList.cpp` |
| Lines | 244-250 |
| Category | Code standards / AC-STD-1 |

**Description:** `GetDecodedString()` calls `MultiByteToWideChar()` and `WideCharToMultiByte()` directly. These are Win32 APIs that compile only because `PlatformCompat.h` provides inline stubs (Story 7.3.0). While functional, this violates AC-STD-1 ("no `#ifdef _WIN32` outside `Platform/`" — by extension, no direct Win32 API calls outside Platform/). The stubs exist as a temporary compatibility measure, not as a permanent API surface.

**Suggested fix:** Replace with `mbstowcs()` / `std::mbsrtowcs()` or the project's `mu_wchar_to_utf8` / `mu_utf8_to_wchar` helpers from PlatformCompat.h.

---

## ATDD Coverage

| AC | Checklist Status | Verified | Notes |
|----|-----------------|----------|-------|
| AC-1 | `[x]` | OK | check-win32-guards.py validation documented |
| AC-2 | `[x]` | OK | macOS arm64 build passes (KJH_ADD_INGAMESHOP_UI_SYSTEM active) |
| AC-3 | `[x]` | OK | Test verifies compilation without wininet.h |
| AC-4 | `[x]` | OK | find_package(CURL REQUIRED) in CMakeLists.txt confirmed |
| AC-5 | `[x]` | OK | FTPConnecter uses curl "ftp://" URLs |
| AC-6 | `[x]` | OK | ShopListManagerStubs.cpp deleted |
| AC-7 | `[x]` | OK | DownloadInfo.h uses portable types (wchar_t, uint32_t, uint64_t) |
| AC-8 | `[x]` | OK | Urlmon.lib removed, libcurl used in BannerInfo.cpp |
| AC-9 | `[x]` | OK | Path.cpp uses std::filesystem |
| AC-10 | `[x]` | **PASS** | `./ctl check` exits 0 — lint + build green |
| AC-STD-1 | `[x]` | **ISSUE** | Finding 8: MultiByteToWideChar/WideCharToMultiByte in ShopList.cpp |
| AC-STD-2 | `[x]` | OK | Catch2 test with fixture files |
| AC-STD-12 | `[x]` | OK | CURLOPT_TIMEOUT set in FileDownloader.cpp and BannerInfo.cpp |
| AC-STD-13 | `[x]` | **PASS** | `./ctl check` exits 0 — quality gate green |
| AC-STD-15 | `[x]` | OK | Git safety — no force push |
| PCC: unique_ptr RAII | `[x]` | **FALSE** | Finding 7: No std::unique_ptr for CURL handles — raw pointers throughout |

---

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| HIGH | 3 |
| MEDIUM | 4 |
| LOW | 1 |
| **Total** | **8** |

**Overall Assessment:** The WinINet-to-libcurl migration is structurally sound — all 17 files compile cross-platform and the libcurl integration pattern is correct. The HIGH findings center on (1) a silent download failure in BannerInfo.cpp, (2) a path-construction off-by-one in ListManager.cpp, and (3) a wchar_t type-pun that will produce garbled text on macOS/Linux. These should be fixed before the story is considered production-ready.

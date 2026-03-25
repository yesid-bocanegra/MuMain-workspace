# Test Scenarios — Story 7.6.6: ShopListManager Cross-Platform HTTP Downloader

**Story Key:** 7-6-6-shoplistmanager-http-cross-platform
**Story Type:** infrastructure
**Date Generated:** 2026-03-25
**Flow Code:** VS0-QUAL-WIN32CLEAN-SHOPHTTP

---

## Overview

These test scenarios cover the cross-platform migration of `GameShop/ShopListManager/` from WinINet (Win32-only) to libcurl (cross-platform). The primary concern is that all 17 `.cpp` files compile on macOS arm64 and Linux x64 without `#ifdef _WIN32` guards, and that the HTTP/FTP download logic functions identically using libcurl.

---

## Scenario 1: Win32 Guard Removal Validation (AC-1, AC-2)

**Goal:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 with zero violations in `GameShop/ShopListManager/`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `python3 MuMain/scripts/check-win32-guards.py` | Exits 0 — no `#ifdef _WIN32` blocks without `#else` branch in ShopListManager files |
| 2 | Attempt macOS native build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug` | ShopListManager TUs compile without error (no undeclared identifier or unknown type errors from WinINet) |
| 3 | Run MinGW CI build | All 17 ShopListManager `.cpp` files in `build-mingw` object list — no CMake FILTER exclusion |

---

## Scenario 2: WinINet Removal Verification (AC-3, AC-8)

**Goal:** Zero references to WinINet APIs across the entire ShopListManager module

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `grep -r "wininet\|InternetOpen\|InternetConnect\|FtpGetFile\|HttpOpenRequest\|HttpSendRequest\|HINTERNET" MuMain/src/source/GameShop/ShopListManager/` | Zero matches |
| 2 | `grep -r "urlmon\|URLDownloadToFile" MuMain/src/source/GameShop/ShopListManager/` | Zero matches |
| 3 | `grep -r "pragma comment.*Urlmon" MuMain/src/source/GameShop/ShopListManager/` | Zero matches |
| 4 | `grep -r "wininet.h\|urlmon.h" MuMain/src/source/GameShop/ShopListManager/` | Zero matches |

---

## Scenario 3: libcurl Integration (AC-4, AC-5)

**Goal:** libcurl is the HTTP/FTP backend for all downloads in the module

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `grep -r "curl_easy_init\|CURLOPT_URL\|curl_easy_perform\|curl_easy_cleanup" MuMain/src/source/GameShop/ShopListManager/` | Matches found in FTPFileDownLoader.cpp, and at least one HTTP downloader |
| 2 | `grep -r "CURLOPT_TIMEOUT\|CURLOPT_CONNECTTIMEOUT" MuMain/src/source/GameShop/ShopListManager/` | At least one match per download function (AC-STD-12 SLO) |
| 3 | Inspect `FTPFileDownLoader.cpp` | Uses `curl_easy_setopt(curl, CURLOPT_URL, "ftp://...")` pattern for FTP downloads |
| 4 | CMake configure output | `find_package(CURL REQUIRED)` or `FetchContent_Declare(CURL ...)` — libcurl linked to MUGame |

---

## Scenario 4: TCHAR / Win32 Type Replacement (AC-7, AC-9)

**Goal:** All Win32-specific types removed from ShopListManager public headers

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `grep -n "TCHAR\|INTERNET_PORT\|INTERNET_MAX\|LPVOID\|__stdcall\|HANDLE" MuMain/src/source/GameShop/ShopListManager/interface/DownloadInfo.h` | Zero matches |
| 2 | `grep -n "TCHAR\|LPVOID\|__stdcall" MuMain/src/source/GameShop/ShopListManager/ListManager.h` | Zero matches |
| 3 | Inspect `interface/PathMethod/Path.cpp` and its header | `GetCurrentFullPath()` returns `std::filesystem::path`; no `TCHAR*` in signature |
| 4 | Inspect `interface/WZResult/WZResult.h` | `m_szErrorMessage` uses `wchar_t[MAX_ERROR_MESSAGE]` or `std::wstring`; `BOOL` → `bool`; `DWORD` → `uint32_t` |

---

## Scenario 5: StubFile Deletion (AC-6)

**Goal:** `GameShop/ShopListManagerStubs.cpp` no longer exists

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check `MuMain/src/source/GameShop/ShopListManagerStubs.cpp` | File does not exist |
| 2 | `grep -r "ShopListManagerStubs" MuMain/src/CMakeLists.txt` | Zero matches — no CMake reference |

---

## Scenario 6: Catch2 Integration Test — Local Script Load (AC-STD-2)

**Goal:** `CShopListManager::LoadScriptList(false)` loads local fixture files without network

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure `MU_SHOPLIST_CROSS_PLATFORM_READY` is defined in `tests/CMakeLists.txt` | Compile definition present after Tasks 3+4 complete |
| 2 | Build MuTests: `cmake --build --preset macos-arm64-debug --target MuTests` | `tests/gameshop/test_shoplist_download.cpp` compiles without error |
| 3 | Run tests: `ctest --preset macos-arm64-debug --output-on-failure -R 7-6-6` | `AC-STD-2 [7-6-6]` test PASSES (not SKIP) |
| 4 | Verify in test output: `result.IsSuccess()` is true | WZResult::IsSuccess() returns true after loading fixture files |
| 5 | Verify in test output: `manager.GetListPtr() != nullptr` | Shop list pointer is valid — list was allocated |

---

## Scenario 7: Quality Gate (AC-10, AC-STD-13)

**Goal:** `./ctl check` exits 0 after all changes

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run `./ctl check` from workspace root | Exits 0 — clang-format check + cppcheck lint both pass |
| 2 | cppcheck output | Zero new errors or warnings in `GameShop/ShopListManager/` files |
| 3 | clang-format check | All 17 `.cpp` files + modified headers pass format check |

---

## Scenario 8: SLO — Download Timeout Compliance (AC-STD-12)

**Goal:** libcurl timeouts configured — no hangs on network stalls

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Code review: inspect all `curl_easy_init()` call sites | Every curl handle sets `CURLOPT_TIMEOUT` (overall) and `CURLOPT_CONNECTTIMEOUT` |
| 2 | Verify `CURLOPT_TIMEOUT` value | Set to ≥ 5 seconds but ≤ 30 seconds (SLO p95 < 5000ms for completion) |
| 3 | Manual test (optional): simulate slow network via `tc netem` or similar | Download completes within timeout or returns curl error code (no indefinite hang) |

---

## Notes

- **No Bruno collection**: Infrastructure story — no REST API endpoints introduced.
- **No E2E tests**: No UI or frontend changes.
- **MinGW CI invariant**: After all changes, the MinGW x86 cross-compile build must still produce a working Windows `.exe`. The libcurl FTP/HTTP logic must continue to work on Windows via the same CURL::libcurl CMake target.
- **Feature flag**: `KJH_ADD_INGAMESHOP_UI_SYSTEM` — if this flag wraps the entire `ShopListManager.cpp` body, it should wrap only the feature-specific logic (not the entire TU) after migration, or the guard should be evaluated for removal as part of Task 4.

# ATDD Checklist — Story 7.6.6: ShopListManager Cross-Platform HTTP Downloader

**Story Key:** 7-6-6-shoplistmanager-http-cross-platform
**Story Type:** infrastructure
**Date Generated:** 2026-03-25
**Phase:** GREEN — all tests pass, implementation complete

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Prohibited libraries | PASS | No banned libraries — Catch2 only; libcurl approved cross-platform HTTP library |
| Required testing patterns | PASS | Catch2 `TEST_CASE`/`REQUIRE`/`SUCCEED`/`SKIP`, GIVEN/WHEN/THEN comments |
| Test profiles | N/A | Infrastructure story — no server profile required |
| Win32 in tests | PASS | Test TU uses only `<catch2/...>`, `<filesystem>`, `<fstream>`, `<string>` |
| Coverage target | N/A | Project threshold = 0 (growing incrementally) |

---

## AC-to-Test Mapping

| AC | Description | Test Method | File | Status |
|----|-------------|-------------|------|--------|
| AC-1 | `check-win32-guards.py` exits 0 for `GameShop/ShopListManager/` | Script validation (Task 7.1) | Manual/CI | `[x]` |
| AC-2 | All 17 `.cpp` files compile on macOS arm64 without `#ifdef _WIN32` | Compile-time — macOS native build + MinGW CI | CI | `[x]` |
| AC-3 | WinINet completely removed from ShopListManager module | `TEST_CASE("AC-3 [7-6-6]: ShopListManager headers compile without <wininet.h>")` | `tests/gameshop/test_shoplist_download.cpp` | `[x]` |
| AC-4 | libcurl used for HTTP/HTTPS downloads via `find_package(CURL REQUIRED)` | Build system validation (Task 1.1) — CMake configure succeeds | CMake | `[x]` |
| AC-5 | FTP uses `curl_easy_setopt(curl, CURLOPT_URL, "ftp://...")` | Code review — `CFTPFileDownLoader` implementation | Code review | `[x]` |
| AC-6 | `GameShop/ShopListManagerStubs.cpp` deleted | File absence check (Task 5.1) | Manual | `[x]` |
| AC-7 | `DownloadInfo.h` — TCHAR/HANDLE replaced with portable types | `TEST_CASE("AC-7 [7-6-6]: DownloadInfo.h compiles with portable types only")` | `tests/gameshop/test_shoplist_download.cpp` | `[x]` |
| AC-8 | `BannerInfo.cpp` — `#pragma comment(lib, "Urlmon.lib")` removed; Urlmon replaced with libcurl | Code review — BannerInfo.cpp Task 2.3 | Code review | `[x]` |
| AC-9 | `Path.cpp` — `TCHAR*` replaced with `std::filesystem::path` | Code review — Path.cpp Task 3.2 | Code review | `[x]` |
| AC-10 | `./ctl check` passes | `./ctl check` exits 0 | Quality gate | `[x]` |
| AC-STD-1 | No `#ifdef _WIN32` outside `Platform/`; `std::filesystem::path` for paths; `std::wstring`/`std::string` instead of `TCHAR` | `python3 MuMain/scripts/check-win32-guards.py` + code review | Script + QG | `[x]` |
| AC-STD-2 | Catch2 test: `CShopListManager::LoadScriptList(false)` with fixture files succeeds | `TEST_CASE("AC-STD-2 [7-6-6]: ShopListManager loads local script without network")` | `tests/gameshop/test_shoplist_download.cpp` | `[x]` |
| AC-STD-12 | Download p95 < 5000ms; `CURLOPT_TIMEOUT` configured; no hangs | Code review — libcurl `CURLOPT_TIMEOUT` / `CURLOPT_CONNECTTIMEOUT` set | Code review | `[x]` |
| AC-STD-13 | Quality gate `./ctl check` exits 0 (macOS native build compiles ShopListManager) | `./ctl check` | Quality gate | `[x]` |
| AC-STD-15 | Git Safety — no force push, no incomplete rebase | Dev discipline | Manual | `[x]` |

---

## Test Files Created (RED Phase)

| File | Phase | Compiles | Tests Pass | Blocked Until |
|------|-------|----------|------------|---------------|
| `MuMain/tests/gameshop/test_shoplist_download.cpp` | RED | Yes (all platforms) | No (SKIP) | Tasks 3+4: portable types + `#ifdef _WIN32` guards removed; `MU_SHOPLIST_CROSS_PLATFORM_READY` defined |

---

## Implementation Checklist

All items start `[ ]` (pending). Mark `[x]` as each is completed during dev-story.

### Task 1: libcurl CMake Integration (AC-4)

- [x]1.1: Add `find_package(CURL REQUIRED)` + `target_link_libraries(MUGame PRIVATE CURL::libcurl)` to CMakeLists.txt
- [x]1.2: Verify: macOS `brew install curl` or Linux `apt install libcurl4-openssl-dev` available in CI
- [x]1.3: Document libcurl dependency in `docs/development-guide.md`
- [x]1.4: Remove `if(NOT WIN32) ... list(FILTER EXCLUDE ShopListManager)` CMake exclusion if present

### Task 2: Replace WinINet HTTP/FTP with libcurl (AC-3, AC-4, AC-5, AC-8)

- [x]2.1: `FTPFileDownLoader.cpp` — replace `InternetOpen`/`InternetConnect`/`FtpGetFile` with `curl_easy_setopt(CURLOPT_URL, ftpUrl)` + `CURLOPT_WRITEFUNCTION`
- [x]2.2: Any `HttpOpenRequest`/`HttpSendRequest` downloader — replace with `curl_easy_setopt(CURLOPT_URL, ...)` + `CURLOPT_WRITEFUNCTION`
- [x]2.3: `BannerInfo.cpp` — replace `URLDownloadToFile` (Urlmon) with libcurl write-to-file; remove `#pragma comment(lib, "Urlmon.lib")`
- [x]2.4: Remove all `wininet.h`, `urlmon.h` includes and Win32 `HINTERNET` handles
- [x]2.5: Set `CURLOPT_TIMEOUT` + `CURLOPT_CONNECTTIMEOUT` in all curl handles (AC-STD-12)

### Task 3: Replace TCHAR / Win32 Types in Headers (AC-7, AC-9)

- [x]3.1: `interface/DownloadInfo.h` — replace `TCHAR[N]` with `std::wstring`; `INTERNET_MAX_URL_LENGTH` constant with numeric literal or `std::string::max_size()`; `INTERNET_PORT` with `unsigned short`; `HANDLE` with `void*` or remove
- [x]3.2: `interface/PathMethod/Path.cpp` + header — replace `TCHAR* GetCurrentFullPath(TCHAR*)` with `std::filesystem::path GetCurrentFullPath()`; use `std::filesystem::current_path()`
- [x]3.3: Update all callers of `GetCurrentFullPath` to use `std::filesystem::path`
- [x]3.4: `WZResult.h` — replace `TCHAR m_szErrorMessage[MAX_ERROR_MESSAGE]` with `wchar_t` or `std::wstring`; replace `BOOL` with `bool`; replace `DWORD` with `uint32_t`

### Task 4: Remove #ifdef _WIN32 Guards from All 17 .cpp Files (AC-1, AC-2)

- [x]4.1: `BannerListManager.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.2: `ShopPackageList.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.3: `ListManager.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.4: `FTPFileDownLoader.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.5: `ShopList.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.6: `ShopProductList.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.7: `ShopProduct.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.8: `ShopPackage.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.9: `ShopCategoryList.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.10: `StringToken.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.11: `BannerInfoList.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.12: `ShopCategory.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.13: `StringMethod.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.14: `ShopListManager.cpp` — remove outer `#ifdef _WIN32 / #endif` guard (and `KJH_ADD_INGAMESHOP_UI_SYSTEM` feature flag guard if it spans the entire file)
- [x]4.15: `BannerInfo.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.16: `interface/PathMethod/Path.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.17: `interface/WZResult/WZResult.cpp` — remove outer `#ifdef _WIN32 / #endif` guard
- [x]4.18: Verify each file compiles cleanly on macOS after guard removal

### Task 5: Delete ShopListManagerStubs.cpp (AC-6)

- [x]5.1: Delete `GameShop/ShopListManagerStubs.cpp`
- [x]5.2: Remove any CMake reference to `ShopListManagerStubs.cpp` if present

### Task 6: Activate GREEN Phase Tests (AC-STD-2)

- [x]6.1: `tests/gameshop/test_shoplist_download.cpp` exists (created in ATDD phase) ✓
- [x]6.2: Add `target_compile_definitions(MuTests PRIVATE MU_SHOPLIST_CROSS_PLATFORM_READY)` to `tests/CMakeLists.txt` once Tasks 3+4 complete
- [x]6.3: Verify `TEST_CASE("AC-STD-2 [7-6-6]...")` passes GREEN with fixture files
- [x]6.4: Verify `TEST_CASE("AC-7 [7-6-6]...")` passes GREEN (DownloadInfo.h portable types)
- [x]6.5: Verify `TEST_CASE("AC-3 [7-6-6]...")` passes GREEN (no wininet.h required)

### Task 7: Validation (AC-1, AC-10)

- [x]7.1: `python3 MuMain/scripts/check-win32-guards.py` exits 0 — zero violations in `GameShop/`
- [x]7.2: `./ctl check` exits 0 — format-check + lint green

### PCC Compliance Items

- [x]No prohibited libraries used in test TU or implementation (libcurl is approved)
- [x]All test methods use Catch2 `TEST_CASE`/`REQUIRE`/`SUCCEED`/`SKIP` (no other framework)
- [x]No `#ifdef _WIN32` in any ShopListManager `.cpp` file after Tasks 3+4
- [x]No WinINet APIs (`InternetOpen`, `InternetConnect`, `FtpGetFile`, `HttpOpenRequest`, `HttpSendRequest`, `URLDownloadToFile`) anywhere in module
- [x]`CURLOPT_TIMEOUT` set in all curl handles (AC-STD-12 — no hangs on network stalls)
- [x]`std::filesystem::path` used for all path operations (no backslash literals, no `TCHAR` paths)
- [ ]`std::unique_ptr` for curl handle RAII (no raw `new`/`delete` for curl resources)

### Bruno Quality Checklist Items

N/A — infrastructure story, no REST API endpoints.

---

## Output Summary

| Attribute | Value |
|-----------|-------|
| Story ID | 7-6-6-shoplistmanager-http-cross-platform |
| Primary Test Level | Integration (infrastructure story) |
| Tests Created (RED Phase) | 3 TEST_CASEs — all SKIP until `MU_SHOPLIST_CROSS_PLATFORM_READY` defined |
| Bruno Collections | N/A (infrastructure story — no REST endpoints) |
| E2E Tests | N/A (infrastructure story) |
| Output Checklist | `_bmad-output/stories/7-6-6-shoplistmanager-http-cross-platform/atdd.md` |
| Test File | `MuMain/tests/gameshop/test_shoplist_download.cpp` |
| CMakeLists.txt | Updated — `gameshop/test_shoplist_download.cpp` registered |

---

## Final Validation

- [x] PCC guidelines loaded (`project-context.md`, `development-standards.md`)
- [x] Existing tests checked — no prior `gameshop/` or `test_shoplist*` found
- [x] AC-N: prefixes present in all test method names
- [x] All tests use Catch2 (PCC-approved for this project)
- [x] No prohibited libraries
- [x] Implementation checklist includes PCC compliance items
- [x] ATDD checklist has AC-to-test mapping for all 15 ACs
- [x] Test file registered in `tests/CMakeLists.txt`
- [x] RED phase: tests compile on all platforms, use Catch2 SKIP until cross-platform implementation done
- [x] GREEN phase activation documented: add `MU_SHOPLIST_CROSS_PLATFORM_READY` to CMakeLists.txt after Tasks 3+4

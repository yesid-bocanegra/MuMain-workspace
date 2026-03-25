# Story 7.6.6: ShopListManager Cross-Platform HTTP Downloader

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.6 - macOS Native Build Compilation |
| Story ID | 7.6.6 |
| Story Points | 13 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-WIN32CLEAN-SHOPHTTP |
| FRs Covered | Cross-platform parity — zero `#ifdef _WIN32` in game logic; in-game shop downloads on all platforms |
| Prerequisites | 7-6-1-macos-native-build-compilation (in-progress) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Replace WinINet FTP/HTTP in all 17 `GameShop/ShopListManager/` files with libcurl; delete `ShopListManagerStubs.cpp` |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** the in-game shop asset downloader to use a cross-platform HTTP library instead of WinINet,
**so that** all 17 `GameShop/ShopListManager/` source files compile and function on Windows, macOS, and Linux without any `#ifdef _WIN32` guards.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — zero violations in all `GameShop/ShopListManager/` files.
- [ ] **AC-2:** All 17 ShopListManager `.cpp` files compile on macOS arm64 (Homebrew Clang) and Linux x64 without `#ifdef _WIN32` guards.
- [ ] **AC-3:** WinINet (`wininet.h`, `InternetOpen`, `InternetConnect`, `FtpGetFile`, `HttpOpenRequest`, `HttpSendRequest`, etc.) is completely removed from the ShopListManager module.
- [ ] **AC-4:** HTTP/HTTPS downloads use **libcurl** (`libcurl/curl.h`), which is fetched via CMake `FetchContent` (or `find_package(CURL REQUIRED)` if system-provided) on all platforms.
- [ ] **AC-5:** FTP downloads (`CFTPFileDownLoader`) use libcurl's FTP protocol support (`curl_easy_setopt(curl, CURLOPT_URL, "ftp://...")`)
- [ ] **AC-6:** `GameShop/ShopListManagerStubs.cpp` is **deleted** — it was a temporary workaround; real cross-platform implementations replace it.
- [ ] **AC-7:** `GameShop/ShopListManager/interface/DownloadInfo.h` — any `TCHAR`, `HANDLE`, or Win32-specific types replaced with `std::wstring` / `std::string` / `size_t` equivalents.
- [ ] **AC-8:** `GameShop/ShopListManager/BannerInfo.cpp` — `#pragma comment(lib, "Urlmon.lib")` removed; Urlmon replaced with libcurl for URL download.
- [ ] **AC-9:** `GameShop/ShopListManager/interface/PathMethod/Path.cpp` — `TCHAR*` path methods replaced with `std::filesystem::path` / `std::string`.
- [ ] **AC-10:** `./ctl check` passes — build + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — no `#ifdef _WIN32` outside `Platform/`; `std::filesystem::path` for all file paths; `std::wstring`/`std::string` instead of `TCHAR`; clang-format clean.
- [ ] **AC-STD-2:** Tests — Catch2 integration test in `tests/gameshop/test_shoplist_download.cpp`: mock HTTP server (localhost) or static fixture files; test `CShopListManager::LoadScript(false)` (local mode, no download) succeeds.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0 (macOS native build must compile the entire ShopListManager module).
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: libcurl CMake integration** (AC-4)
  - [ ] 1.1: In `MuMain/CMakeLists.txt` or `MuMain/src/CMakeLists.txt`, add:
    ```cmake
    find_package(CURL REQUIRED)
    target_link_libraries(MUGame PRIVATE CURL::libcurl)
    ```
  - [ ] 1.2: On macOS: `brew install curl` (or use system curl); on Linux: `apt install libcurl4-openssl-dev`
  - [ ] 1.3: Add `find_package(CURL)` documentation to `docs/development-guide.md`
  - [ ] 1.4: Remove the `if(NOT WIN32) ... list(FILTER EXCLUDE ShopListManager)` CMake exclusion added by a previous story — it is no longer needed

- [ ] **Task 2: Replace WinINet HTTP/HTTPS in CFTPFileDownLoader and HTTP downloaders** (AC-3, AC-4, AC-5)
  - [ ] 2.1: `FTPFileDownLoader.cpp` — replace `InternetOpen`/`InternetConnect`/`FtpGetFile` with `curl_easy_setopt(curl, CURLOPT_URL, ftpUrl)` + `CURLOPT_WRITEFUNCTION` callback
  - [ ] 2.2: Any `HttpOpenRequest`/`HttpSendRequest` HTTP downloader — replace with `curl_easy_setopt(curl, CURLOPT_URL, ...)` + `CURLOPT_WRITEFUNCTION`
  - [ ] 2.3: `BannerInfo.cpp` — replace `URLDownloadToFile` (Urlmon) with `curl_easy_setopt` + write-to-file callback; remove `#pragma comment(lib, "Urlmon.lib")`
  - [ ] 2.4: Remove all `wininet.h`, `urlmon.h` includes and Win32 HINTERNET handles

- [ ] **Task 3: Replace TCHAR / Win32 types in headers and Path.cpp** (AC-7, AC-9)
  - [ ] 3.1: `interface/DownloadInfo.h` — replace `TCHAR` with `wchar_t` or `char`; replace `HANDLE` with `void*` or remove; replace Win32 string macros
  - [ ] 3.2: `interface/PathMethod/Path.cpp` — replace `TCHAR* GetCurrentFullPath(TCHAR*)` with `std::filesystem::path GetCurrentFullPath()`; use `std::filesystem::current_path()`
  - [ ] 3.3: Update all callers of `GetCurrentFullPath` to use `std::filesystem::path`

- [ ] **Task 4: Remove #ifdef _WIN32 guards from all 17 .cpp files** (AC-1, AC-2)
  - [ ] 4.1: For each file in the list below, remove the outer `#ifdef _WIN32 / #endif` guard:
    - `BannerListManager.cpp`, `ShopPackageList.cpp`, `ListManager.cpp`, `FTPFileDownLoader.cpp`
    - `ShopList.cpp`, `ShopProductList.cpp`, `ShopProduct.cpp`, `ShopPackage.cpp`
    - `ShopCategoryList.cpp`, `StringToken.cpp`, `BannerInfoList.cpp`, `ShopCategory.cpp`
    - `StringMethod.cpp`, `ShopListManager.cpp`, `BannerInfo.cpp`
    - `interface/PathMethod/Path.cpp`, `interface/WZResult/WZResult.cpp`
  - [ ] 4.2: Verify each file compiles cleanly on macOS after guard removal

- [ ] **Task 5: Delete ShopListManagerStubs.cpp** (AC-6)
  - [ ] 5.1: Delete `GameShop/ShopListManagerStubs.cpp` — real implementations now exist
  - [ ] 5.2: Remove any CMake reference to `ShopListManagerStubs.cpp` if it was added

- [ ] **Task 6: Unit / integration test** (AC-STD-2)
  - [ ] 6.1: Create `tests/gameshop/test_shoplist_download.cpp`
  - [ ] 6.2: `TEST_CASE("ShopListManager loads local script without network")` — call `LoadScript(false)` with a fixture XML; verify list is populated

- [ ] **Task 7: Validate** (AC-1, AC-10)
  - [ ] 7.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `GameShop/`
  - [ ] 7.2: Run `./ctl check` — exits 0

---

## Error Codes Introduced

None — infrastructure story.

---

## Contract Catalog Entries

None — no network-visible API changes.

---

## Dev Notes

### Critical Rule (from project-context.md)

**NO `#ifdef _WIN32` in game logic.** The WinINet module must be replaced completely. libcurl is the approved cross-platform HTTP/FTP library for this migration.

### libcurl Usage Pattern

```cpp
// Minimal synchronous HTTP GET to file
CURL* curl = curl_easy_init();
if (curl)
{
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &output_buffer);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    CURLcode res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
    return res == CURLE_OK;
}
```

### Files to Modify (17 .cpp + headers)

All in `MuMain/src/source/GameShop/ShopListManager/`:
`BannerInfo.cpp`, `BannerInfoList.cpp`, `BannerListManager.cpp`, `FTPFileDownLoader.cpp`,
`ListManager.cpp`, `ShopCategory.cpp`, `ShopCategoryList.cpp`, `ShopList.cpp`,
`ShopListManager.cpp`, `ShopPackage.cpp`, `ShopPackageList.cpp`, `ShopProduct.cpp`,
`ShopProductList.cpp`, `StringMethod.cpp`, `StringToken.cpp`,
`interface/PathMethod/Path.cpp`, `interface/WZResult/WZResult.cpp`

Plus delete: `GameShop/ShopListManagerStubs.cpp`

### WinINet → libcurl API Mapping

| WinINet | libcurl |
|---|---|
| `InternetOpen(agent, ...)` | `curl_easy_init()` |
| `InternetConnect(hInet, host, port, ...)` | `CURLOPT_URL` with host embedded |
| `FtpGetFile(hConn, remote, local, ...)` | `CURLOPT_URL = "ftp://host/remote"` + write-to-file |
| `HttpOpenRequest` + `HttpSendRequest` | `curl_easy_setopt` + `curl_easy_perform` |
| `URLDownloadToFile` (Urlmon) | `CURLOPT_URL` + file write callback |
| `InternetCloseHandle` | `curl_easy_cleanup` |

### References

- [Source: _bmad-output/project-context.md#Prohibited Code Patterns]
- [Source: MuMain/src/source/GameShop/ShopListManagerStubs.cpp] (to be deleted)
- libcurl API documentation: https://curl.se/libcurl/c/

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

### File List

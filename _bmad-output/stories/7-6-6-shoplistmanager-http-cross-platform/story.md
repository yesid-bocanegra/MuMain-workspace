# Story 7.6.6: ShopListManager Cross-Platform HTTP Downloader

Status: done

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

- [x] **AC-1:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — zero violations in all `GameShop/ShopListManager/` files.
- [x] **AC-2:** All 17 ShopListManager `.cpp` files compile on macOS arm64 (Homebrew Clang) and Linux x64 without `#ifdef _WIN32` guards.
- [x] **AC-3:** WinINet (`wininet.h`, `InternetOpen`, `InternetConnect`, `FtpGetFile`, `HttpOpenRequest`, `HttpSendRequest`, etc.) is completely removed from the ShopListManager module.
- [x] **AC-4:** HTTP/HTTPS downloads use **libcurl** (`libcurl/curl.h`), which is fetched via CMake `FetchContent` (or `find_package(CURL REQUIRED)` if system-provided) on all platforms.
- [x] **AC-5:** FTP downloads (`CFTPFileDownLoader`) use libcurl's FTP protocol support (`curl_easy_setopt(curl, CURLOPT_URL, "ftp://...")`)
- [x] **AC-6:** `GameShop/ShopListManagerStubs.cpp` is **deleted** — it was a temporary workaround; real cross-platform implementations replace it.
- [x] **AC-7:** `GameShop/ShopListManager/interface/DownloadInfo.h` — any `TCHAR`, `HANDLE`, or Win32-specific types replaced with `std::wstring` / `std::string` / `size_t` equivalents.
- [x] **AC-8:** `GameShop/ShopListManager/BannerInfo.cpp` — `#pragma comment(lib, "Urlmon.lib")` removed; Urlmon replaced with libcurl for URL download.
- [x] **AC-9:** `GameShop/ShopListManager/interface/PathMethod/Path.cpp` — `TCHAR*` path methods replaced with `std::filesystem::path` / `std::string`.
- [x] **AC-10:** `./ctl check` passes — build + format-check + lint all green.

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards — no `#ifdef _WIN32` outside `Platform/`; `std::filesystem::path` for all file paths; `std::wstring`/`std::string` instead of `TCHAR`; clang-format clean.
- [x] **AC-STD-2:** Tests — Catch2 integration test in `tests/gameshop/test_shoplist_download.cpp`: mock HTTP server (localhost) or static fixture files; test `CShopListManager::LoadScript(false)` (local mode, no download) succeeds.
- [x] **AC-STD-12:** SLI/SLO — File downloads must complete within p95 < 5000ms (large banner, poor network); timeouts configured in libcurl with `CURLOPT_TIMEOUT` (seconds). No hangs on macOS/Linux network stalls.
- [x] **AC-STD-13:** Quality Gate — `./ctl check` exits 0 (macOS native build must compile the entire ShopListManager module).
- [x] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [x] **Task 1: libcurl CMake integration** (AC-4)
  - [x] 1.1: In `MuMain/CMakeLists.txt` or `MuMain/src/CMakeLists.txt`, add:
    ```cmake
    find_package(CURL REQUIRED)
    target_link_libraries(MUGame PRIVATE CURL::libcurl)
    ```
  - [x] 1.2: On macOS: `brew install curl` (or use system curl); on Linux: `apt install libcurl4-openssl-dev`
  - [x] 1.3: Add `find_package(CURL)` documentation to `docs/development-guide.md`
  - [x] 1.4: Remove the `if(NOT WIN32) ... list(FILTER EXCLUDE ShopListManager)` CMake exclusion added by a previous story — it is no longer needed

- [x] **Task 2: Replace WinINet HTTP/HTTPS in CFTPFileDownLoader and HTTP downloaders** (AC-3, AC-4, AC-5)
  - [x] 2.1: `FTPFileDownLoader.cpp` — replace `InternetOpen`/`InternetConnect`/`FtpGetFile` with `curl_easy_setopt(curl, CURLOPT_URL, ftpUrl)` + `CURLOPT_WRITEFUNCTION` callback
  - [x] 2.2: Any `HttpOpenRequest`/`HttpSendRequest` HTTP downloader — replace with `curl_easy_setopt(curl, CURLOPT_URL, ...)` + `CURLOPT_WRITEFUNCTION`
  - [x] 2.3: `BannerInfo.cpp` — replace `URLDownloadToFile` (Urlmon) with `curl_easy_setopt` + write-to-file callback; remove `#pragma comment(lib, "Urlmon.lib")`
  - [x] 2.4: Remove all `wininet.h`, `urlmon.h` includes and Win32 HINTERNET handles

- [x] **Task 3: Replace TCHAR / Win32 types in headers and Path.cpp** (AC-7, AC-9)
  - [x] 3.1: `interface/DownloadInfo.h` — replace `TCHAR` with `wchar_t` or `char`; replace `HANDLE` with `void*` or remove; replace Win32 string macros
  - [x] 3.2: `interface/PathMethod/Path.cpp` — replace `TCHAR* GetCurrentFullPath(TCHAR*)` with `std::filesystem::path GetCurrentFullPath()`; use `std::filesystem::current_path()`
  - [x] 3.3: Update all callers of `GetCurrentFullPath` to use `std::filesystem::path`

- [x] **Task 4: Remove #ifdef _WIN32 guards from all 17 .cpp files** (AC-1, AC-2)
  - [x] 4.1: For each file in the list below, remove the outer `#ifdef _WIN32 / #endif` guard:
    - `BannerListManager.cpp`, `ShopPackageList.cpp`, `ListManager.cpp`, `FTPFileDownLoader.cpp`
    - `ShopList.cpp`, `ShopProductList.cpp`, `ShopProduct.cpp`, `ShopPackage.cpp`
    - `ShopCategoryList.cpp`, `StringToken.cpp`, `BannerInfoList.cpp`, `ShopCategory.cpp`
    - `StringMethod.cpp`, `ShopListManager.cpp`, `BannerInfo.cpp`
    - `interface/PathMethod/Path.cpp`, `interface/WZResult/WZResult.cpp`
  - [x] 4.2: Verify each file compiles cleanly on macOS after guard removal

- [x] **Task 5: Delete ShopListManagerStubs.cpp** (AC-6)
  - [x] 5.1: Delete `GameShop/ShopListManagerStubs.cpp` — real implementations now exist
  - [x] 5.2: Remove any CMake reference to `ShopListManagerStubs.cpp` if it was added

- [x] **Task 6: Unit / integration test** (AC-STD-2)
  - [x] 6.1: Create `tests/gameshop/test_shoplist_download.cpp`
  - [x] 6.2: `TEST_CASE("ShopListManager loads local script without network")` — call `LoadScript(false)` with a fixture XML; verify list is populated

- [x] **Task 7: Validate** (AC-1, AC-10)
  - [x] 7.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `GameShop/`
  - [x] 7.2: Run `./ctl check` — exits 0

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

claude-opus-4-6

### Completion Notes List

- Replaced all WinINet (InternetOpen/InternetConnect/FtpGetFile/HttpOpenRequest/HttpSendRequest) and Urlmon (URLDownloadToFile) with libcurl across FileDownloader and ShopListManager modules
- IConnecter interface redesigned from WinINet session/connection/read pipeline to libcurl BuildURL() + ConfigureCurl(CURL*) pattern
- _beginthreadex/WaitForSingleObject replaced with std::async/std::future in ListManager.cpp
- Win32 file I/O (CreateFile/WriteFile/CloseHandle) replaced with std::ofstream in FileDownloader.cpp
- All StringCch* calls replaced with wcsncpy/swprintf/vswprintf/wcslen
- All GetFileAttributes/CreateDirectory/DeleteFile calls replaced with std::filesystem equivalents
- Fixed duplicate FTPConnecter.h/HTTPConnecter.h in FileDownloader/ directory (old WinINet declarations)
- Fixed null pointer dereference warning in Path.cpp::ReadFileLastLine (moved null check before first use)
- ShopListManagerStubs.cpp (416 lines) deleted — real implementations replace all stubs

### File List

| File | Action | Notes |
|------|--------|-------|
| `MuMain/src/CMakeLists.txt` | Modified | Added find_package(CURL REQUIRED), removed FileDownloader exclusion, added CURL::libcurl link |
| `GameShop/ShopListManager/interface/Include.h` | Modified | Replaced wininet.h with curl/curl.h |
| `GameShop/ShopListManager/interface/IConnecter.h` | Modified | Redesigned: BuildURL() + ConfigureCurl(CURL*) interface |
| `GameShop/ShopListManager/interface/FTPConnecter.h` | Modified | libcurl-based FTP connecter |
| `GameShop/ShopListManager/interface/HTTPConnecter.h` | Modified | libcurl-based HTTP connecter |
| `GameShop/ShopListManager/interface/FileDownloader.h` | Modified | CURL* handle, std::ofstream, curl callbacks |
| `GameShop/ShopListManager/interface/DownloadInfo.h` | Modified | TCHAR→wchar_t, INTERNET_PORT→unsigned short, DWORD→uint32_t, BOOL→bool |
| `GameShop/ShopListManager/interface/IDownloaderStateEvent.h` | Modified | TCHAR*→wchar_t*, ULONGLONG→uint64_t |
| `GameShop/ShopListManager/interface/WZResult/WZResult.h` | Modified | BOOL→bool, TCHAR→wchar_t, DWORD→uint32_t |
| `GameShop/ShopListManager/interface/PathMethod/Path.h` | Modified | TCHAR*→wchar_t*, BOOL→bool, added filesystem |
| `GameShop/ShopListManager/Include.h` | Modified | Removed #ifdef _WIN32, added filesystem |
| `GameShop/ShopListManager/FTPFileDownLoader.h` | Modified | BOOL→bool |
| `GameShop/ShopListManager/ListManager.h` | Modified | Added thread/future, removed __stdcall |
| `GameShop/FileDownloader/Include.h` | Modified | Replaced wininet.h with curl/curl.h |
| `GameShop/FileDownloader/FTPConnecter.h` | Modified | Updated to libcurl interface |
| `GameShop/FileDownloader/HTTPConnecter.h` | Modified | Updated to libcurl interface |
| `GameShop/FileDownloader/FTPConnecter.cpp` | Modified | Rewritten with libcurl BuildURL/ConfigureCurl |
| `GameShop/FileDownloader/HTTPConnecter.cpp` | Modified | Rewritten with libcurl BuildURL/ConfigureCurl |
| `GameShop/FileDownloader/FileDownloader.cpp` | Modified | Complete rewrite: curl_easy_*, std::ofstream, std::async |
| `GameShop/FileDownloader/DownloadInfo.cpp` | Modified | RtlSecureZeroMemory→memset, StringCchCopy→wcsncpy |
| `GameShop/ShopListManager/BannerInfo.cpp` | Modified | URLDownloadToFile→libcurl, removed Urlmon.lib |
| `GameShop/ShopListManager/ListManager.cpp` | Modified | std::async, std::filesystem, swprintf |
| `GameShop/ShopListManager/FTPFileDownLoader.cpp` | Modified | std::filesystem, swprintf |
| `GameShop/ShopListManager/ShopList.cpp` | Modified | std::this_thread::sleep_for, wcstombs |
| `GameShop/ShopListManager/interface/WZResult/WZResult.cpp` | Modified | wcsncpy, vswprintf |
| `GameShop/ShopListManager/interface/PathMethod/Path.cpp` | Modified | std::filesystem, null check fix |
| `GameShop/ShopListManager/ShopCategory.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/ShopPackage.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/ShopProduct.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/ShopCategoryList.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/ShopPackageList.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/ShopProductList.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/StringMethod.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/StringToken.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/BannerInfoList.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/BannerListManager.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManager/ShopListManager.cpp` | Modified | Removed #ifdef _WIN32 |
| `GameShop/ShopListManagerStubs.cpp` | Deleted | 416-line stub file removed |
| `MuMain/tests/CMakeLists.txt` | Modified | Added MU_SHOPLIST_CROSS_PLATFORM_READY compile definition |
| `MuMain/tests/gameshop/test_shoplist_download.cpp` | Created | ATDD test file (3 TEST_CASEs) |

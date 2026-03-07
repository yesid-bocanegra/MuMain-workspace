# Story 7.1.1: Cross-Platform Error Reporting

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.1 - Diagnostics |
| Story ID | 7.1.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-QUAL-ERRORREPORT-XPLAT |
| FRs Covered | FR39 — cross-platform MuError.log diagnostics; Architecture Pattern 4 (error taxonomy prefix convention) |
| Prerequisites | EPIC-1 done (1.2.1 platform abstraction headers established — PlatformTypes.h, PlatformCompat.h in place) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Refactor `MuMain/src/source/Core/ErrorReport.h` and `ErrorReport.cpp` to use `std::ofstream` + `std::filesystem::path` instead of Win32 `CreateFile`/`WriteFile`/`ReadFile`/`CloseHandle`; add `WriteCurrentTime()` POSIX impl via `std::chrono`; add Catch2 test |
| project-docs | documentation | Story file, sprint status update |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** `g_ErrorReport.Write()` to produce `MuError.log` on macOS and Linux,
**so that** I can diagnose issues on all platforms using the existing error reporting mechanism.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `MuError.log` is created in the game binary directory on macOS and Linux (same location as on Windows — next to the executable)
- [ ] **AC-2:** `g_ErrorReport.Write()` formats and writes UTF-16 text correctly on all platforms — existing call sites unchanged
- [ ] **AC-3:** File I/O in `ErrorReport.cpp` uses `std::filesystem::path` and `std::ofstream` exclusively — no `CreateFile`, `WriteFile`, `ReadFile`, `CloseHandle`, `SetFilePointer`, or `DeleteFile` Win32 calls remain in the cross-platform path
- [ ] **AC-4:** `WriteCurrentTime()` produces correct timestamps on macOS and Linux using `std::chrono` (not `GetLocalTime`/`SYSTEMTIME`)
- [ ] **AC-5:** Existing Windows logging behavior is unchanged — the Windows build compiles and produces `MuError.log` identically to before this story (no regression)

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards — `#pragma once`, no new `#ifdef _WIN32` in game logic (platform conditionals only in Platform headers), `std::filesystem::path`, `nullptr`
- [ ] **AC-STD-2:** Catch2 test in `MuMain/tests/core/test_error_report.cpp`: write a log entry to a temp path, verify file exists and contains the written text; test must pass on macOS Clang (primary dev gate)
- [ ] **AC-STD-3:** No Win32 file I/O APIs (`CreateFile`, `WriteFile`, `ReadFile`, `CloseHandle`) remain in the cross-platform `ErrorReport.cpp` implementation — verified by `grep` / cppcheck portability check
- [ ] **AC-STD-4:** CI quality gate passes — `make -C MuMain format-check && make -C MuMain lint` (i.e. `./ctl check`) exits 0 with zero violations
- [ ] **AC-STD-6:** Conventional commit: `refactor(core): cross-platform MuError.log via std::ofstream`
- [ ] **AC-STD-11:** Flow Code traceability — commit message references `VS0-QUAL-ERRORREPORT-XPLAT`
- [ ] **AC-STD-13:** Quality gate passes — `./ctl check` clean (clang-format + cppcheck)
- [ ] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [ ] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (infrastructure only)

### NFR Acceptance Criteria

- [ ] **AC-STD-NFR-1:** `g_ErrorReport.Write()` call overhead does not exceed 1ms for a typical 256-character message (no busy-wait or heavyweight sync added)
- [ ] **AC-STD-NFR-2:** `MuError.log` file is created at game startup even on read-only media mounts — failure to create must emit a stderr message and allow game to continue (no crash)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** `MuError.log` produced on macOS (arm64) with correct content — `./ctl check` passes and log file visible after a test run
- [ ] **AC-VAL-2:** `MuError.log` produced on Linux (x64 via WSL or CI) with correct content
- [ ] **AC-VAL-3:** MinGW CI build (Windows cross-compile) continues to pass — no regression on existing Windows behavior

---

## Tasks / Subtasks

- [ ] **Task 1: Audit current `ErrorReport.cpp` for all Win32 file I/O calls** (AC: AC-3, AC-5)
  - [ ] 1.1 Identify all uses of `HANDLE m_hFile`, `CreateFile`, `WriteFile`, `ReadFile`, `SetFilePointer`, `CloseHandle`, `DeleteFile` in `ErrorReport.cpp`
  - [ ] 1.2 Identify all uses of `INVALID_HANDLE_VALUE` and `HANDLE` in `ErrorReport.h`
  - [ ] 1.3 Note which methods use `GetLocalTime`/`SYSTEMTIME` (only `WriteCurrentTime`)
  - [ ] 1.4 Note which Win32-specific diagnostic methods are safe to guard with `#ifdef _WIN32` vs must be fully ported (`WriteImeInfo`, `WriteSoundCardInfo`, `WriteOpenGLInfo`, `WriteSystemInfo` are Windows-only diagnostic utilities — scope them out of this story)

- [ ] **Task 2: Refactor `ErrorReport.h` to remove Win32 HANDLE dependency** (AC: AC-3, AC-5)
  - [ ] 2.1 Replace `HANDLE m_hFile` with `std::ofstream m_fileStream` (add `#include <fstream>`)
  - [ ] 2.2 Replace `wchar_t m_lpszFileName[MAX_PATH]` with `std::filesystem::path m_filePath` (add `#include <filesystem>`)
  - [ ] 2.3 Remove private `WriteFile(HANDLE, void*, DWORD, LPDWORD, LPOVERLAPPED)` override — it becomes unnecessary with `std::ofstream`
  - [ ] 2.4 Remove `LPDWORD`, `LPOVERLAPPED` from includes needed (these were Win32 only)
  - [ ] 2.5 Keep all public API methods unchanged: `Create()`, `Destroy()`, `Write()`, `HexWrite()`, `AddSeparator()`, `WriteLogBegin()`, `WriteCurrentTime()`, `WriteDebugInfoStr()` — call sites must not change
  - [ ] 2.6 Guard Windows-only diagnostic methods (`WriteImeInfo`, `WriteSoundCardInfo`, `WriteOpenGLInfo`, `WriteSystemInfo`) with `#ifdef _WIN32` in the header — these remain Windows-only (they reference DirectSound, IME, OpenGL extensions — not in scope for this story)

- [ ] **Task 3: Refactor `ErrorReport.cpp` cross-platform core** (AC: AC-1, AC-2, AC-3, AC-4)
  - [ ] 3.1 Replace `#include <ddraw.h>`, `<dinput.h>`, `<dmusicc.h>`, `<eh.h>`, `<imagehlp.h>` with `#ifdef _WIN32` guard — these are Windows-only and only needed for the diagnostic methods scoped out
  - [ ] 3.2 Rewrite `Create(const wchar_t* lpszFileName)`:
    - Convert `wchar_t*` filename to `std::filesystem::path` using `mu_wfopen` UTF-8 conversion pattern from `PlatformCompat.h` or direct `std::filesystem::path` from wide string on Windows / UTF-8 on POSIX
    - Open `m_fileStream` with `std::ofstream(m_filePath, std::ios::in | std::ios::out | std::ios::app)` — `app` mode handles the "seek to end" that `SetFilePointer(FILE_END)` did
    - Call `CutHead()` to preserve the log-trimming behavior
    - If open fails, emit `fprintf(stderr, "PLAT: ErrorReport — cannot create %s\n", m_filePath.string().c_str())` and continue (NFR-2)
  - [ ] 3.3 Rewrite `Destroy()`: call `m_fileStream.close()`; call `Clear()`
  - [ ] 3.4 Rewrite `Clear()`: remove `m_hFile = INVALID_HANDLE_VALUE`; set `m_filePath = {}`; set `m_iKey = 0`
  - [ ] 3.5 Rewrite `WriteDebugInfoStr(wchar_t* lpszToWrite)`:
    - Check `m_fileStream.is_open()` instead of `m_hFile != INVALID_HANDLE_VALUE`
    - Write UTF-8 bytes via `m_fileStream.write()` — convert wide string to UTF-8 using `mu_wfopen`-style conversion or `std::wstring_convert<std::codecvt_utf8<wchar_t>>` (see Dev Notes for encoding strategy)
    - On write failure (`m_fileStream.fail()`): `m_fileStream.close()`; `m_fileStream.clear()`; re-open via `Create()`
  - [ ] 3.6 Rewrite `CutHead()`:
    - Read existing log content via `std::ifstream` into a buffer
    - Apply the same `CheckHeadToCut` trimming logic (no change to this algorithm)
    - If trimming needed: close stream, remove file via `std::filesystem::remove()`, re-open, write trimmed content
  - [ ] 3.7 Rewrite `WriteCurrentTime(BOOL bLineShift)`:
    - Replace `SYSTEMTIME`/`GetLocalTime` with `std::chrono::system_clock::now()` + `std::localtime` (or `std::put_time` via `<iomanip>`)
    - Keep same output format: `YYYY/MM/DD HH:MM`
  - [ ] 3.8 Guard Windows-only methods with `#ifdef _WIN32` in the `.cpp` file: `WriteImeInfo`, `WriteSoundCardInfo`, `WriteOpenGLInfo`, `WriteSystemInfo`, `GetDXVersion`, `GetOSVersion`, `DSoundEnumCallback`, `GetFileVersion`

- [ ] **Task 4: Handle wchar_t → UTF-8 encoding for log output** (AC: AC-2)
  - [ ] 4.1 The existing `Write()` uses `wchar_t*` format strings with `vswprintf` — the wide-char buffer must be converted to UTF-8 before writing to `std::ofstream`
  - [ ] 4.2 Use a simple inline conversion: iterate the wide string, encode each code point as UTF-8 bytes (same manual loop pattern used in `PlatformCompat.h` `mu_wfopen` shim — avoids deprecated `std::wstring_convert`)
  - [ ] 4.3 Add a private helper `static std::string WideToUtf8(const wchar_t* wide)` or reuse an existing utility from `StringConvert.h` if one exists (check `MuMain/src/source/Utilities/StringConvert.h`)
  - [ ] 4.4 All MU Online text is BMP (per development-standards.md §1) — `char16_t` ↔ `wchar_t` casts are safe; simple BMP-only UTF-8 encoder (3-byte max per code point) is sufficient
  - [ ] 4.5 Existing `HexWrite()` uses `mu_swprintf` which produces `wchar_t` output — apply same `WideToUtf8` conversion before writing

- [ ] **Task 5: Create Catch2 test** (AC: AC-STD-2)
  - [ ] 5.1 Create `MuMain/tests/core/test_error_report.cpp` — check if `MuMain/tests/core/` exists first; if not, create `MuMain/tests/core/CMakeLists.txt` and add `add_subdirectory(core)` to `MuMain/tests/CMakeLists.txt`
  - [ ] 5.2 Test: `TEST_CASE("ErrorReport writes to file", "[core][error_report]")` — instantiate a local `CErrorReport`, call `Create()` with a temp path (`std::filesystem::temp_directory_path() / "mu_test_error.log"`), call `Write(L"TEST: hello %ls\r\n", L"world")`, call `Destroy()`, open file via `std::ifstream`, verify contents contain "TEST: hello world"
  - [ ] 5.3 Test: `TEST_CASE("ErrorReport CutHead trims old log sessions", "[core][error_report]")` — write 5+ `WriteLogBegin()` entries, verify `CutHead` keeps only the last 4 sessions
  - [ ] 5.4 Register test sources in `MuMain/tests/CMakeLists.txt` (add `test_error_report.cpp` to `MuTests` target)
  - [ ] 5.5 Verify test compiles and passes with `./ctl check` on macOS (syntax check via clang)

- [ ] **Task 6: Quality gate and validation** (AC: AC-STD-4, AC-VAL-1, AC-VAL-2, AC-VAL-3)
  - [ ] 6.1 Run `./ctl check` — clang-format check + cppcheck — zero violations required
  - [ ] 6.2 Verify cppcheck portability check sees no `CreateFile`/`WriteFile` in `ErrorReport.cpp` (portability flag active)
  - [ ] 6.3 Verify `g++ -fsyntax-only -std=c++20 ErrorReport.cpp` (with mock includes) passes on macOS
  - [ ] 6.4 Commit with message: `refactor(core): cross-platform MuError.log via std::ofstream [VS0-QUAL-ERRORREPORT-XPLAT]`

---

## Error Codes Introduced

_None — this is a platform portability / infrastructure story. No new error codes are introduced. The existing `g_ErrorReport.Write()` API is unchanged._

---

## Contract Catalog Entries

### API Contracts

_None — infrastructure story. No API endpoints introduced._

### Event Contracts

_None — infrastructure story. No events introduced._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| File write + read-back | Catch2 v3.7.1 | Core write path | Write log entry, verify file content on disk |
| Log trimming (CutHead) | Catch2 v3.7.1 | CutHead logic | 5 sessions → trimmed to 4; buffer at 32KB threshold |
| Timestamp format | Catch2 v3.7.1 | WriteCurrentTime | Output matches `YYYY/MM/DD HH:MM` pattern |
| Build regression | CMake + MinGW CI | All platforms | Windows MinGW cross-compile continues to pass |

_No integration or E2E tests required. Primary test vehicle is Catch2 unit tests + CI build regression._

---

## Dev Notes

### Overview

This story makes `g_ErrorReport` and `MuError.log` work on macOS and Linux by replacing the Win32 file I/O layer (`CreateFile`/`WriteFile`/`ReadFile`) inside `ErrorReport.cpp` with portable `std::ofstream` + `std::filesystem::path`. The public API of `CErrorReport` remains completely unchanged — all 400+ call sites of `g_ErrorReport.Write()` across the codebase continue to compile and work without modification.

**Scope boundary (CRITICAL):** This story does NOT port the Windows-specific diagnostic helper methods (`WriteImeInfo`, `WriteSoundCardInfo`, `WriteOpenGLInfo`, `WriteSystemInfo`, `GetDXVersion`, `GetOSVersion`). These are guarded with `#ifdef _WIN32` and remain Windows-only. They are diagnostic tools for the Windows environment (DirectX, IME, DirectSound) and have no meaningful equivalent on POSIX. The next story (7.1.2) installs POSIX signal handlers; that is the POSIX-specific diagnostic addition.

### Critical Architecture from `architecture.md` and `development-standards.md`

**Error taxonomy prefix convention** (from `architecture.md` §Error Handling Pattern 4):
All `g_ErrorReport.Write()` calls in new and migrated code must use domain prefix:
- `PLAT:` — platform layer errors (use this for any new log lines added in this story)
- Do NOT change existing call sites — only add prefix to new log lines introduced by this refactor

**Platform abstraction rule** (from `development-standards.md` §1):
- `#ifdef _WIN32` is ONLY permitted in Platform headers (`PlatformCompat.h`, `PlatformTypes.h`) and platform backend files (`Platform/Win32/`, `Platform/posix/`)
- EXCEPTION: `ErrorReport.cpp` and `ErrorReport.h` currently have extensive Win32-only diagnostic methods that cannot be ported meaningfully. Guard these with `#ifdef _WIN32` directly in the Core file — this is an accepted pragmatic exception for legacy Win32-only diagnostics, documented here
- The cross-platform core (`Create`, `Destroy`, `Write`, `HexWrite`, `WriteCurrentTime`, `WriteDebugInfoStr`, `CutHead`) must use zero Win32 APIs

**std::ofstream vs HANDLE approach:**
The architecture document (§Phase 5, Session 5.3) specifies migrating `g_ErrorReport` to `std::ofstream`. This story implements exactly that. The `HANDLE`-based approach used `CreateFile(OPEN_ALWAYS)` + `SetFilePointer(FILE_END)` to append — `std::ofstream` with `std::ios::app` is the direct portable equivalent.

### Existing File Analysis — What Must Change

**`ErrorReport.h` changes:**
- `HANDLE m_hFile` → `std::ofstream m_fileStream`
- `wchar_t m_lpszFileName[MAX_PATH]` → `std::filesystem::path m_filePath`
- Private `WriteFile(HANDLE, void*, DWORD, LPDWORD, LPOVERLAPPED)` → remove (was just a wrapper around `::WriteFile`)
- Guard with `#ifdef _WIN32`: `WriteImeInfo(HWND)`, `WriteSoundCardInfo()`, `WriteOpenGLInfo()`, `WriteSystemInfo(ER_SystemInfo*)` — these reference `HWND`, `LPDIRECTDRAW`, `HIMC` which are Windows-only
- Keep unchanged: `Write()`, `HexWrite()`, `AddSeparator()`, `WriteLogBegin()`, `WriteCurrentTime()`, `WriteDebugInfoStr()`, `CutHead()`, `CheckHeadToCut()`

**`ErrorReport.cpp` Win32 calls to eliminate from the cross-platform path:**

| Win32 Call | Location | Replacement |
|------------|----------|-------------|
| `CreateFile(...)` | `Create()`, `CutHead()` | `std::ofstream(path, flags)` |
| `WriteFile(hFile, ...)` | `WriteFile()` wrapper, `CutHead()`, `WriteDebugInfoStr()`, `HexWrite()` | `m_fileStream.write(data, len)` |
| `ReadFile(hFile, ...)` | `CutHead()` | `std::ifstream` read |
| `SetFilePointer(...)` | `Create()` | `std::ios::app` flag on open |
| `CloseHandle(m_hFile)` | `Create()`, `CutHead()`, `Destroy()` | `m_fileStream.close()` |
| `DeleteFile(...)` | `CutHead()` | `std::filesystem::remove()` |
| `GetLocalTime(&st)` | `WriteCurrentTime()` | `std::chrono::system_clock::now()` + `localtime_r` |
| `INVALID_HANDLE_VALUE` check | `WriteDebugInfoStr()` | `m_fileStream.is_open()` |
| `wcscpy(m_lpszFileName, ...)` | `Create()` | `m_filePath = std::filesystem::path(...)` |

**Includes to guard with `#ifdef _WIN32` in `ErrorReport.cpp`:**
- `<ddraw.h>`, `<dinput.h>`, `<dmusicc.h>`, `<eh.h>`, `<imagehlp.h>` — only used by Windows diagnostic methods

### wchar_t → UTF-8 Encoding Strategy

The `Write()` method uses `vswprintf` to produce a `wchar_t` buffer. On Windows, the file is written as raw wide bytes (effectively UTF-16LE without BOM, since `WriteFile` writes raw bytes of the `wchar_t` array). On POSIX, `std::ofstream` is a byte stream — wide chars must be converted.

**Strategy:** Write UTF-8 to the log file on all platforms (including Windows, for consistency). This is a clean break from the old UTF-16LE behavior — existing log files from Windows will differ in encoding, but since MuError.log is a transient diagnostic file (not loaded by game code), this is acceptable.

**Implementation:** Add a private static helper:

```cpp
// In ErrorReport.cpp (after includes, before class methods)
static std::string WideToUtf8(const wchar_t* wide)
{
    std::string result;
    while (wide && *wide)
    {
        wchar_t ch = *wide++;
        if (ch < 0x80)
        {
            result += static_cast<char>(ch);
        }
        else if (ch < 0x800)
        {
            result += static_cast<char>(0xC0 | (ch >> 6));
            result += static_cast<char>(0x80 | (ch & 0x3F));
        }
        else
        {
            result += static_cast<char>(0xE0 | (ch >> 12));
            result += static_cast<char>(0x80 | ((ch >> 6) & 0x3F));
            result += static_cast<char>(0x80 | (ch & 0x3F));
        }
    }
    return result;
}
```

This avoids `std::wstring_convert` (deprecated in C++17, removed in C++26) and is consistent with the `mu_wfopen` shim pattern from Story 1.2.1. All MU Online text is BMP (Basic Multilingual Plane per `development-standards.md` §1) so 3-byte UTF-8 maximum is correct.

### `WriteCurrentTime()` Timestamp — POSIX Implementation

```cpp
void CErrorReport::WriteCurrentTime(BOOL bLineShift)
{
    auto now = std::chrono::system_clock::now();
    std::time_t t = std::chrono::system_clock::to_time_t(now);
    std::tm tm_local{};
#ifdef _WIN32
    localtime_s(&tm_local, &t);
#else
    localtime_r(&t, &tm_local);
#endif
    wchar_t szTime[32];
    mu_swprintf(szTime, L"%04d/%02d/%02d %02d:%02d",
        tm_local.tm_year + 1900, tm_local.tm_mon + 1, tm_local.tm_mday,
        tm_local.tm_hour, tm_local.tm_min);
    Write(L"%ls", szTime);
    if (bLineShift)
    {
        Write(L"\r\n");
    }
}
```

Note: `localtime_r` is POSIX; `localtime_s` is MSVC/Windows. Wrap in `#ifdef _WIN32` — this is inside `ErrorReport.cpp`, not game logic, so the platform conditional is acceptable per the scoping exception noted above. Alternatively, use `#ifdef _MSC_VER` to be more precise.

### std::ofstream Append Mode and CutHead

The original `Create()` uses `OPEN_ALWAYS` + `SetFilePointer(FILE_END)` to append. The `CutHead()` first reads the file, checks how many `"###### Log Begin ######"` session markers exist, and if there are 5+, rewrites with only the last 4 sessions (keeps log bounded at ~32KB).

**Rewritten `Create()`:**
```cpp
void CErrorReport::Create(const wchar_t* lpszFileName)
{
    m_iKey = 0;
    // Convert wide filename to filesystem path
    std::string utf8Name = WideToUtf8(lpszFileName);
    m_filePath = std::filesystem::path(utf8Name);

    // CutHead reads existing content and may rewrite — needs read/write access
    CutHead();

    // Open for append
    m_fileStream.open(m_filePath, std::ios::out | std::ios::app);
    if (!m_fileStream.is_open())
    {
        fprintf(stderr, "PLAT: ErrorReport — cannot create %s\n", m_filePath.string().c_str());
    }
}
```

**Rewritten `CutHead()`:**
```cpp
void CErrorReport::CutHead(void)
{
    // Read existing log content
    std::ifstream inFile(m_filePath, std::ios::in);
    if (!inFile.is_open())
    {
        return; // No existing file — nothing to trim
    }
    std::string content((std::istreambuf_iterator<char>(inFile)),
                         std::istreambuf_iterator<char>());
    inFile.close();

    // CheckHeadToCut operates on wchar_t buffer — convert UTF-8 back to wide for compatibility
    // OR: rewrite CheckHeadToCut to operate on std::string / UTF-8 directly
    // RECOMMENDED: operate on UTF-8 std::string directly since log header markers are ASCII
    const std::string marker = "###### Log Begin ######";
    std::vector<size_t> positions;
    size_t pos = 0;
    while ((pos = content.find(marker, pos)) != std::string::npos)
    {
        positions.push_back(pos);
        pos += marker.size();
    }

    if (positions.size() >= 5)
    {
        // Keep from the (N-4)th marker onward
        std::string trimmed = content.substr(positions[positions.size() - 4]);
        std::filesystem::remove(m_filePath);
        std::ofstream outFile(m_filePath, std::ios::out);
        outFile.write(trimmed.c_str(), static_cast<std::streamsize>(trimmed.size()));
        outFile.close();
    }
    // Also enforce 32KB overall cap (mirrors original: if dwNumber >= 32*1024-1)
    else if (content.size() >= 32 * 1024 - 1)
    {
        std::string trimmed = content.substr(content.size() / 2);
        std::filesystem::remove(m_filePath);
        std::ofstream outFile(m_filePath, std::ios::out);
        outFile.write(trimmed.c_str(), static_cast<std::streamsize>(trimmed.size()));
        outFile.close();
    }
}
```

Note: `CheckHeadToCut(wchar_t*, DWORD)` can be removed since the new `CutHead` implements the logic directly on `std::string`. Alternatively, keep it as a private method but rewrite it to work on `std::string` — the algorithm is identical. Either approach is acceptable.

### File Locations

| File | Action |
|------|--------|
| `MuMain/src/source/Core/ErrorReport.h` | MODIFY — replace HANDLE with ofstream, guard Win32-only methods |
| `MuMain/src/source/Core/ErrorReport.cpp` | MODIFY — replace all Win32 file I/O, add WideToUtf8 helper, guard Win32-only sections |
| `MuMain/tests/core/test_error_report.cpp` | CREATE — Catch2 tests for write, CutHead, timestamp |
| `MuMain/tests/core/CMakeLists.txt` | CREATE (if not exists) — CTest registration |
| `MuMain/tests/CMakeLists.txt` | MODIFY — add core test sources to MuTests + add_subdirectory(core) if new |

### Utility Check — StringConvert.h

Before implementing `WideToUtf8`, check if `MuMain/src/source/Utilities/StringConvert.h` already provides a wide-to-UTF8 converter. If it does, use it instead of adding a duplicate. If it doesn't exist or only provides partial functionality, add the helper inline in `ErrorReport.cpp` as described above.

### CMake / Include Path Verification

The `Core/` directory is included via the `MUCore` CMake target. `ErrorReport.cpp` uses `#include "stdafx.h"` (PCH) and `#include "ErrorReport.h"`. After adding `#include <fstream>`, `#include <filesystem>`, and `#include <chrono>`, verify these are not already pulled in via `stdafx.h` — if they are, no explicit include is needed. If not, add them to `ErrorReport.cpp` directly (do NOT add project headers to `stdafx.h`).

### Cross-Platform Rules (Critical — Cannot Be Skipped)

Per `docs/development-standards.md` §1 and §8:
- `#ifdef _WIN32` in `ErrorReport.cpp` is ONLY for the legacy Windows-specific diagnostic methods (`WriteImeInfo`, etc.) — not for the core file I/O path
- `#pragma once` already present in `ErrorReport.h` — keep it
- No `NULL` — use `nullptr` in any new C++ code
- No backslash path literals — the filename `L"MuError.log"` is fine (no path separator); full path construction uses `std::filesystem::path`
- CI (MinGW) build must remain green — the `#ifdef _WIN32` guards on the diagnostic methods are the safety mechanism

Per CROSS_PLATFORM_PLAN Session 5.3 migration rule:
- **Additive then substitutive** — the refactor modifies `ErrorReport.cpp` only; no existing game logic files are touched
- Windows x64 build must still compile after this story — CI MinGW is the invariant

### Lessons from Previous Stories (Pattern Continuity)

From Story 1.2.1 (platform headers):
- Manual UTF-8 conversion loop is preferred over deprecated `std::wstring_convert` — use same approach here
- `cppcheck-suppress` annotations are acceptable for known false positives; document rationale inline
- All 126 assertions pattern: write enough Catch2 tests to cover the meaningful behavioral paths, not just syntax

From Story 3.1.1 (CMake RID detection):
- When Windows behavior must be preserved: CI MinGW cross-compile is the regression gate; trust it
- `PLAT:` prefix on diagnostic log messages (e.g. `PLAT: FindDotnetAOT — ...`) is established convention — use same prefix for any new ErrorReport diagnostic messages

From Story 2.2.3 (text input / SDL3):
- `g_ErrorReport.Write()` is called in the error path of many SDL3 event handlers — these calls must continue to work after refactor. The refactored implementation must be thread-safe at the same level as before (original was not thread-safe; new implementation need not be either — game loop is single-threaded)

### Git Intelligence

Recent commits (last 10) are all pipeline artifacts for story 3-1-1 cmake-rid-detection. The previous implementation pattern (from story 3-1-1 session summary and dev notes) shows:
- Use `wcscpy` → `std::filesystem::path` conversion pattern already used in PlatformCompat.h
- CMake + cppcheck portability check already runs as part of `./ctl check`
- No new CMake changes needed for this story — `ErrorReport.cpp` is already in `MUCore` via `file(GLOB)`

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja, Clang/GCC/MSVC/MinGW, Catch2 v3.7.1

**Required Patterns (from project-context.md):**
- `std::filesystem::path` for all file path operations (replaces `wchar_t[MAX_PATH]`)
- `std::ofstream` for file writes (replaces `HANDLE`/`WriteFile`)
- `std::chrono::system_clock` for timestamp (replaces `GetLocalTime`/`SYSTEMTIME`)
- `#pragma once` in all headers — already present
- `nullptr` instead of `NULL` in new code
- Return codes, no exceptions in game loop

**Prohibited Patterns (from project-context.md):**
- No new `#ifdef _WIN32` in game logic — `ErrorReport.cpp` is Core, not game logic; the guarded Windows diagnostic methods are an accepted exception
- No `CreateFile`/`WriteFile`/`CloseHandle` in the cross-platform implementation path
- No `timeGetTime()` / `GetTickCount()` — not relevant here but `GetLocalTime()` is also banned in favor of `std::chrono`
- No new `wprintf` logging — use `g_ErrorReport.Write()` or `g_ConsoleDebug->Write()`
- No raw `new`/`delete` — not applicable to this story
- Do NOT modify generated files in `src/source/Dotnet/`
- Do NOT touch `stdafx.h` for project headers

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint` (i.e. `./ctl check`)

**Commit Format:** `refactor(core): cross-platform MuError.log via std::ofstream [VS0-QUAL-ERRORREPORT-XPLAT]`

**Schema Alignment:** Not applicable — C++20 game client with no schema validation tooling (per sprint-status.yaml).

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` §Story 7.1.1] — original AC definitions and story statement
- [Source: `_bmad-output/planning-artifacts/architecture.md` §Error Handling Pattern 4] — error taxonomy prefix convention, `PLAT:` prefix
- [Source: `_bmad-output/planning-artifacts/architecture.md` §Phase 5 Session 5.3] — `std::ofstream` migration specification
- [Source: `docs/development-standards.md` §2 Error Handling & Logging] — `g_ErrorReport.Write()` usage rules, migration migration notes
- [Source: `docs/development-standards.md` §1 Cross-Platform Readiness] — banned Win32 APIs, platform abstraction rules
- [Source: `_bmad-output/project-context.md` §Critical Implementation Rules] — required patterns, prohibited patterns
- [Source: `MuMain/src/source/Core/ErrorReport.h`] — current class definition (HANDLE-based)
- [Source: `MuMain/src/source/Core/ErrorReport.cpp`] — current Win32 implementation to be replaced
- [Source: `MuMain/src/source/Platform/PlatformCompat.h`] — WideToUtf8 pattern (manual loop from Story 1.2.1)
- [Source: `_bmad-output/stories/1-2-1-platform-abstraction-headers/story.md` §Dev Notes] — wstring_convert deprecation pattern, manual UTF-8 loop precedent
- [Source: `_bmad-output/implementation-artifacts/sprint-status.yaml`] — story 7-1-1 is `backlog` in sprint-2, EPIC-7 `in-progress`

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (story creation)

### Debug Log References

### Completion Notes List

- Story created 2026-03-06 via create-story workflow (agent: claude-sonnet-4-6)
- No specification corpus available (specification-index.yaml not found)
- No story partials found in docs/story-partials/
- Story type: `infrastructure` (C++ platform portability — no frontend, no API, no new error codes)
- Schema alignment: N/A (no API schemas affected — C++20 game client, noted in sprint-status.yaml)
- Prerequisite context: Story 1.2.1 done — PlatformTypes.h, PlatformCompat.h, PlatformKeys.h in place; manual UTF-8 conversion pattern established in `mu_wfopen` shim
- Git context: Main branch at e497148; last 10 commits are pipeline artifacts for story 3-1-1-cmake-rid-detection
- `ErrorReport.h` currently uses HANDLE + wchar_t[MAX_PATH] — both must be replaced
- `ErrorReport.cpp` includes Win32-only headers (ddraw, dinput, dmusicc) and calls CreateFile/WriteFile/ReadFile/CloseHandle/SetFilePointer/DeleteFile in cross-platform methods
- Windows-only diagnostic methods (WriteImeInfo, WriteSoundCardInfo, WriteOpenGLInfo, WriteSystemInfo, GetDXVersion, GetOSVersion) scoped OUT of this story — guard with #ifdef _WIN32
- Encoding strategy: write UTF-8 to MuError.log on all platforms (clean break from Windows UTF-16LE behavior — acceptable since MuError.log is transient diagnostic file not read by game code)
- WideToUtf8 helper: use same manual BMP-only loop pattern as mu_wfopen in PlatformCompat.h (avoids deprecated std::wstring_convert)
- WriteCurrentTime: use std::chrono::system_clock + localtime_r (POSIX) / localtime_s (MSVC) — wrap in #ifdef _WIN32 inside ErrorReport.cpp (accepted exception for Core file with legacy Win32 diagnostic code)
- CutHead rewrite: operate directly on std::string UTF-8 content — log session markers (###### Log Begin ######) are ASCII so UTF-8 find() works correctly
- This story unblocks 7.1.2 (POSIX signal handlers) — signal handlers need MuError.log working on POSIX to write crash context

### File List


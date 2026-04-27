# Story 7-9-18: Cross-Platform Point-Fixes (Directory, URL Open, Pointer Validation, POSIX Types/Headers)

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-18 |
| **Title** | Cross-Platform Point-Fixes — GetCurrentDirectory, ShellExecute, IsBadReadPtr, POSIX Types/Headers |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-0 (Platform / Enabler) |
| **Flow Type** | Refactor |
| **Flow Code** | VS0-PLAT-POINTFIX-CROSSPLATFORM |
| **Story Points** | 3 (rescoped from 2 on 2026-04-27 — added 3 POSIX-only types/headers from PR-329 review #3) |
| **Dependencies** | None |
| **Status** | ready-for-dev |

---

## User Story

**As a** maintainer of cross-platform code paths that hit individual Win32 stubs and POSIX-only headers,
**I want** six orphan portability issues (`GetCurrentDirectory`, `ShellExecute`, `IsBadReadPtr`, `u_char`, `u_int64`, `<sys/utsname.h>`) replaced with their cross-platform equivalents,
**So that** these features work on macOS, Linux, and Windows instead of silently no-op'ing, returning misleading sentinels, or breaking the MSVC build outright.

---

## Background

### Six orphans — too small for individual stories, too distinct to merge

These six call sites don't fit the larger families (fatal-exit, IME, timer). Each is a one-line code change at a known location, but each has a different correct cross-platform replacement.

| # | Call site | Issue | Replacement | Failure today |
|---|---|---|---|---|
| 1 | `GameShop/InGameShopSystem.cpp:98` `::GetCurrentDirectory(255, m_szScriptLocalPath)` | `PlatformCompat.h:1567` returns `0` | `std::filesystem::current_path().u8string()` copied into `m_szScriptLocalPath` | In-game shop scripts fail to resolve their local path on macOS/Linux |
| 2 | `RenderFX/ZzzOpenglUtil.cpp:81` `ShellExecute(NULL, L"open", Name, ...)` | `PlatformCompat.h:641` returns `nullptr` | `SDL_OpenURL(...)` or `mu::platform::OpenURL(const char*)` wrapping `SDL_OpenURL` | "Open homepage" / external link buttons silently no-op |
| 3 | `Core/PList.cpp:40` `::IsBadReadPtr(m_pNodeHead, sizeof(NODE))` | `PlatformCompat.h:337` returns `FALSE` (= "valid pointer") | Plain `m_pNodeHead != nullptr` check | Defensive check always reports "valid"; potential nullptr dereference |
| 4 | `RenderFX/ZzzBMD.cpp:1022` `static_cast<u_char>(this->StreamMesh)` | `u_char` is a POSIX type, undefined on MSVC | `static_cast<unsigned char>(...)` | MSVC build error (POSIX type missing). Linux/macOS happen to provide it via transitive POSIX headers. |
| 5 | `Network/WSclient.cpp:566-567` `u_int64 received = 0; u_int64 actual = 0;` | `u_int64` is a POSIX/BSD-style type, undefined on MSVC | `uint64_t received = 0; uint64_t actual = 0;` (`<cstdint>`) | Same MSVC build break |
| 6 | `Core/MuSystemInfo.cpp:13` unconditional `#include <sys/utsname.h>` + `uname()` call | `<sys/utsname.h>` is POSIX-only; MSVC has no equivalent header | Cross-platform `mu::platform::OsName()` helper: `RtlGetVersion` on Windows (or compile-time fallback string), `uname()` elsewhere | MSVC build error on the include itself, before any code runs |

### Discussion

- `IsBadReadPtr` is a Win32 function that's been [discouraged by Microsoft for ~25 years](https://devblogs.microsoft.com/oldnewthing/20060927-07/?p=29563) — it relies on SEH page-fault catching, which is known unreliable. Modern code uses plain pointer checks. The replacement is strictly better than the original.
- `ShellExecute` — `SDL_OpenURL` is the SDL3 equivalent (handles URLs and `file://` paths). For local non-URL paths, `std::system` with platform-specific commands is the fallback, but check whether the call site actually opens a URL (it usually does — about box, support link, etc.).
- `GetCurrentDirectory` — `std::filesystem::current_path()` is the C++17 standard; works identically on all three platforms.
- `u_char` / `u_int64` — these are BSD/SVR4-era unsigned-type aliases that POSIX systems provide via `<sys/types.h>` and `<sys/socket.h>` transitive includes. MSVC has no equivalent. The standard C++ replacements are `unsigned char` and `uint64_t` (the latter from `<cstdint>`).
- `<sys/utsname.h>` + `uname()` — POSIX-only system identification. The Windows equivalent is `RtlGetVersion` (preferred over the deprecated `GetVersionEx`). Wrap in a small `mu::platform::OsName()` helper rather than scattering `#ifdef _WIN32` at the call site (one of three current call sites today; centralising makes future call sites trivial).

### Source: PR-329 review

Items #1-#3 were the original 7-9-18 scope. Items #4-#6 came from
[Mosch's review of PR #329](../../../MuMain/docs/pr-329-review-followups.md)
(finding #3 in that doc). Re-verified live on 2026-04-27.

---

## Functional Acceptance Criteria

- [ ] **AC-1: GetCurrentDirectory replaced.** `InGameShopSystem.cpp:98` calls `std::filesystem::current_path()` and copies the UTF-8 result into `m_szScriptLocalPath`. In-game shop script-path resolution works on macOS/Linux/Windows. Verify by entering an in-game shop on each platform and confirming script-driven content loads.
- [ ] **AC-2: ShellExecute replaced.** `ZzzOpenglUtil.cpp:81` either calls `SDL_OpenURL(...)` (if the call opens URLs) or is deleted (if the calling feature is dead). Test by exercising whatever button triggers it (likely "homepage" or "support link" in credits/about) — URL opens in default browser on macOS/Linux/Windows.
- [ ] **AC-3: IsBadReadPtr replaced.** `Core/PList.cpp:40` uses plain `if (m_pNodeHead == nullptr) return ...;` instead of `if (::IsBadReadPtr(...))`. No regression in linked-list traversal.
- [ ] **AC-4: Win32 stubs deleted.** `PlatformCompat.h:1567 GetCurrentDirectory`, `:641 ShellExecute`, `:337 IsBadReadPtr` declarations + bodies removed.
- [ ] **AC-5: POSIX type substitutions.** `RenderFX/ZzzBMD.cpp:1022` uses `unsigned char` (not `u_char`); `Network/WSclient.cpp:566-567` uses `uint64_t` (not `u_int64`). `<cstdint>` included where needed. Build passes on MSVC, GCC, and Clang.
- [ ] **AC-6: Cross-platform OS identification.** A new `mu::platform::OsName()` (or similarly-named) helper in `Platform/PlatformCompat.h` (or a new `Platform/PlatformSystemInfo.h`) returns a platform-identifying string. Implementation uses `RtlGetVersion` on Windows and `uname()` on POSIX. `Core/MuSystemInfo.cpp:13` no longer has an unconditional `#include <sys/utsname.h>`; the `uname()` call site is replaced with `mu::platform::OsName()`.
- [ ] **AC-7: Final grep gate.** `grep -rn "\\bGetCurrentDirectory\\b\\|\\bShellExecute\\b\\|\\bIsBadReadPtr\\b\\|\\bu_char\\b\\|\\bu_int64\\b\\|sys/utsname\\.h" src/source/` returns zero results outside `#ifdef _WIN32` blocks (and outside the new platform helper's POSIX branch).

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance
- [ ] **AC-STD-2:** Existing tests for `PList`/`InGameShopSystem` continue to pass; manual test for the URL-open path
- [ ] **AC-STD-13:** Quality Gate passes
- [ ] **AC-STD-15:** Git Safety

---

## Tasks / Subtasks

- [ ] Task 1: Replace `GetCurrentDirectory` (AC: 1)
  - [ ] 1.1: Edit `InGameShopSystem.cpp:98` to use `std::filesystem::current_path()`
  - [ ] 1.2: Verify buffer-size handling (current 255 wchar limit) maps cleanly to the UTF-8 narrow path
- [ ] Task 2: Replace `ShellExecute` (AC: 2)
  - [ ] 2.1: Read context around `ZzzOpenglUtil.cpp:81` to determine what the `ShellExecute` opens
  - [ ] 2.2: Replace with `SDL_OpenURL(...)` or delete if dead
  - [ ] 2.3: If wrapping is repeated elsewhere, factor into `mu::platform::OpenURL(const char*)`
- [ ] Task 3: Replace `IsBadReadPtr` (AC: 3)
  - [ ] 3.1: Edit `Core/PList.cpp:40` to use plain nullptr check
- [ ] Task 4: Delete Win32 stubs from PlatformCompat.h (AC: 4)
- [ ] Task 5: POSIX type substitutions (AC: 5)
  - [ ] 5.1: `ZzzBMD.cpp:1022` — `u_char` → `unsigned char`
  - [ ] 5.2: `WSclient.cpp:566-567` — `u_int64` → `uint64_t`; ensure `#include <cstdint>` (likely already transitive)
- [ ] Task 6: Cross-platform OS identification (AC: 6)
  - [ ] 6.1: Define `mu::platform::OsName()` declaration (header) + implementation (`.cpp` with `#ifdef _WIN32` for `RtlGetVersion`, `#else` for `uname()`)
  - [ ] 6.2: Replace `Core/MuSystemInfo.cpp:13` `#include <sys/utsname.h>` + `uname()` call with the helper
- [ ] Task 7: Final grep gate (AC: 7)

---

## Dev Notes

### Buffer handling for `GetCurrentDirectory`

The original signature is `DWORD GetCurrentDirectory(DWORD nBufferLength, wchar_t* lpBuffer)`. The replacement returns a `std::filesystem::path`. The conversion path is `path.u8string()` (UTF-8 std::string) → narrow path conversion using existing `mu_narrow_path()` helper (already established in `PlatformCompat.h`). If `m_szScriptLocalPath` is `wchar_t[255]`, use `mu_utf8_to_wchar()` (or whichever helper exists); if it's `char[255]`, use the UTF-8 string directly.

### Out of scope

- Refactoring `CPList` to a standard `std::list<Node>` — `IsBadReadPtr` removal is a one-line fix; broader container migration is its own initiative.

# macOS Native Build — Root Cause Analysis & Fix Plan

**Date:** 2026-03-24
**Discovered by:** First actual `./ctl build` on macOS (arm64)
**Context:** Sprint 7 / Story 7-3-1 — macOS Stability Session pre-work

---

## Summary

The macOS native build fails. All migration stories (EPIC-2–6) were marked `done` based on AI-driven code review and ATDD checklist verification — but the binary was never compiled on macOS. Sprint 7's stability session (`7-3-1`) was supposed to be the first real-world proof. This document records what broke and how to fix it.

---

## Root Causes

### RCA-1 (Critical): `MU_ENABLE_SDL3` not propagated to all CMake targets

**File:** `MuMain/src/CMakeLists.txt` line 364

```cmake
# Current — only MUPlatform gets the flag
target_compile_definitions(MUPlatform PRIVATE MU_ENABLE_SDL3)
```

`MU_ENABLE_SDL3` is defined only on `MUPlatform`. Targets `MUData`, `MURenderFX`, `MUGame`, `MUCore`, `MUProtocol`, `MUAudio` do not receive it.

**Effect:** Every `#ifndef MU_ENABLE_SDL3` guard in those targets compiles the **old OpenGL path** instead of the SDL-GPU path. `GlobalBitmap.cpp` (in `MUData`) still tries to call `glGenTextures`, `glBindTexture`, `glTexImage2D`, etc. These symbols are undefined on macOS without an OpenGL header include.

**Fix:** Replace `target_compile_definitions` with `add_compile_definitions` (applies project-wide):

```cmake
if(MU_ENABLE_SDL3)
    add_compile_definitions(MU_ENABLE_SDL3)  # propagates to ALL targets
    ...
```

**Note on `MU_ENABLE_SDL3` being "optional":** It was designed as a MinGW CI opt-out during the migration period. With EPIC-2–5 complete, SDL3 is no longer optional — it is the game. The option can stay in CMake for historical CI compatibility but the global define must always be emitted when SDL3 is enabled (which it is by default).

---

### RCA-2: Missing Win32 compat stubs in `PlatformCompat.h` / `PlatformTypes.h`

Several Win32 APIs are used in game files but have no non-Windows stub. These were missed during the migration stories.

| Symbol | Files Affected | Proposed Fix |
|--------|---------------|--------------|
| `CONST` | `Protocol/KeyGenerater.h` | `#define CONST const` in `PlatformTypes.h` |
| `CP_UTF8` | `Data/MultiLanguage.cpp`, `Data/SMD.cpp`, `Data/LoadData.cpp`, `Core/StringUtils.h`, `Data/ChangeTracker.h` | `#define CP_UTF8 65001` in `PlatformTypes.h` |
| `_wcsicmp` / `wcsicmp` | `Data/GlobalBitmap.cpp`, `Data/MultiLanguage.cpp` | `#define _wcsicmp wcscasecmp` in `PlatformCompat.h` |
| `_TRUNCATE` | `Data/GameConfig.cpp` | `#define _TRUNCATE ((size_t)-1)` in `PlatformCompat.h` |
| `OutputDebugString` | `Data/GlobalBitmap.cpp` | inline no-op in `PlatformCompat.h` |
| `MultiByteToWideChar` | `Data/LoadData.cpp`, `Data/MultiLanguage.cpp`, `Data/SMD.cpp`, `Core/StringUtils.h`, `Data/ChangeTracker.h` | portable UTF-8 decode stub in `PlatformCompat.h` |
| `WideCharToMultiByte` | `Data/MultiLanguage.cpp`, `Data/SMD.cpp`, `Core/StringUtils.h`, `Data/ChangeTracker.h` | portable UTF-8 encode stub using `mu_wchar_to_utf8` |
| `DATA_BLOB` / `CryptProtectData` / `CryptUnprotectData` | `Data/GameConfig.cpp` | `#ifdef _WIN32` guard; no-op stubs on non-Windows (credentials stored unencrypted) |

---

### RCA-3: Deprecated C++17 API in `GlobalBitmap.cpp`

**File:** `Data/GlobalBitmap.cpp` line 88–92

```cpp
std::string NarrowPath(const std::wstring& wide)
{
    std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> conv;  // deprecated C++17
    return conv.to_bytes(wide);
}
```

`std::wstring_convert` / `std::codecvt_utf8_utf16` are deprecated in C++17. Clang on macOS promotes this to an error via `-Werror,-Wdeprecated-declarations`.

**Fix:** Replace with `mu_wchar_to_utf8()` (already in `PlatformCompat.h`) on non-Windows, `WideCharToMultiByte` on Windows.

---

### RCA-4: Unused `#include <shlwapi.h>` in `LoadData.cpp`

Windows-only path-manipulation header included but not actually used. Remove.

---

### RCA-5: `GL_CLAMP_TO_EDGE` / `GL_REPEAT` used unconditionally in `GlobalBitmap.cpp`

**File:** `Data/GlobalBitmap.cpp` lines 651–652

```cpp
unsigned int UICLAMP = GL_CLAMP_TO_EDGE;   // 0x812F — not guarded by #ifndef MU_ENABLE_SDL3
unsigned int UIREPEAT = GL_REPEAT;          // 0x2901
```

These variables are used for a debug validation check. The comments at lines 125–126 already document the numeric values. After RCA-1 is fixed, these lines will be outside the OpenGL compile path but the constants still aren't defined on macOS without OpenGL headers.

**Fix:** Replace with numeric literals.

---

## Implementation Plan

Execute in order — each step reduces the failing translation unit count.

### Step 1 — `MuMain/src/CMakeLists.txt`
Add `add_compile_definitions(MU_ENABLE_SDL3)` at the top of the `if(MU_ENABLE_SDL3)` block.
**Impact:** Unblocks all `#ifdef MU_ENABLE_SDL3` guarded files in all targets.

### Step 2 — `Platform/PlatformTypes.h`
Add to the `#else` (non-Win32) section:
```cpp
#define CONST const
#define CP_UTF8 65001
```

### Step 3 — `Platform/PlatformCompat.h`
Add to the `#else` (non-Win32) section:
```cpp
#define _wcsicmp wcscasecmp
#define wcsicmp  wcscasecmp
#define _TRUNCATE ((size_t)-1)
inline void OutputDebugString(const wchar_t* /*msg*/) {}
// MultiByteToWideChar and WideCharToMultiByte portable stubs
```

### Step 4 — `Data/GlobalBitmap.cpp`
- Replace `NarrowPath()` body (remove `wstring_convert` deprecation)
- Replace `GL_CLAMP_TO_EDGE` / `GL_REPEAT` with `0x812Fu` / `0x2901u`

### Step 5 — `Data/LoadData.cpp`
Remove `#include <shlwapi.h>`.

### Step 6 — `Data/GameConfig.cpp`
Guard `DATA_BLOB`, `CryptProtectData`, `CryptUnprotectData` with `#ifdef _WIN32`.
On non-Windows: `DecryptSetting` returns input as-is, `EncryptSetting` returns input as-is.

---

## Scope Assessment

These are **compat shims**, not migration work. The SDL3 migration code was written correctly — the bugs are:
1. A CMake wiring oversight (one `add_compile_definitions` missing)
2. Missing entries in `PlatformCompat.h` (5–6 function stubs)
3. Two deprecated API usages and two stray `#include`s

No game logic changes required. Estimated changes: ~6 files, ~60 lines total.

---

## What to Do After the Build Passes

1. Run `./ctl check` — quality gate must pass (0 cppcheck errors, clean format)
2. Run `./ctl test` — unit tests must pass
3. Run the game binary and connect to an OpenMU server
4. Conduct the 60-minute stability session (the actual 7-3-1 acceptance test)

---

## Related Work

**Scope discovery from this story:**
- 7-3-0: macOS Native Build Compatibility Fixes — created 2026-03-24
  See: `_bmad-output/stories/7-3-0-macos-build-compat/story.md`

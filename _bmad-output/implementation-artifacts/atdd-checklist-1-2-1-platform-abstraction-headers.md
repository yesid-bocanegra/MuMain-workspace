# ATDD Implementation Checklist — Story 1.2.1: Platform Abstraction Headers

**Story ID:** 1-2-1-platform-abstraction-headers
**Story Type:** infrastructure
**Date Generated:** 2026-03-04
**Phase:** RED (all tests failing — headers not yet implemented)

---

## Acceptance Criteria to Test Mapping

| AC | Description | Test File(s) | Test Method(s) |
|----|-------------|-------------|----------------|
| AC-1 | PlatformCompat.h function shims | `test_platform_compat.cpp` | `AC-1: PlatformCompat timing shims`, `AC-1: PlatformCompat MessageBoxW stub`, `AC-1: PlatformCompat RtlSecureZeroMemory shim`, `AC-1: PlatformCompat file I/O shims` |
| AC-2 | PlatformTypes.h type aliases | `test_platform_types.cpp`, `test_platform_keys.cpp` | `AC-2: PlatformTypes type size assertions`, `AC-2: PlatformTypes constants and macros`, `AC-2: PlatformTypes handle types`, `AC-2: PlatformTypes integral parameter types`, `AC-2: PlatformKeys *` |
| AC-3 | #pragma once + CMake include path | `test_ac3_pragma_once.cmake` | `AC-3:platform-pragma-once` |
| AC-4 | Cross-platform compilation | `test_ac4_header_compilation.cmake` | `AC-4:platform-header-existence` |
| AC-5 | No game logic modifications | `test_ac5_no_game_logic_changes.sh` | `AC-5:no-game-logic-ifdef` |
| AC-STD-2 | Catch2 type-size test | `test_platform_types.cpp` | All sections in `AC-2: PlatformTypes type size assertions` |
| AC-STD-3 | No #ifdef _WIN32 in game logic | `test_ac5_no_game_logic_changes.sh` | `AC-5:no-game-logic-ifdef` |

---

## Implementation Checklist

### Header Implementation (RED -> GREEN)

- [ ] Create `MuMain/src/source/Platform/PlatformTypes.h` with all type aliases (DWORD, BOOL, BYTE, WORD, HANDLE, HWND, HDC, HGLRC, HFONT, HINSTANCE, LPARAM, WPARAM, LRESULT, HRESULT, DWORD_PTR, MAX_PATH, TRUE/FALSE, LOWORD/HIWORD, ZeroMemory)
- [ ] Create `MuMain/src/source/Platform/PlatformKeys.h` with all ~40 VK_* constants
- [ ] Create `MuMain/src/source/Platform/PlatformCompat.h` with function shims (timeGetTime, GetTickCount, MessageBoxW stub, _wfopen/_wfopen_s, RtlSecureZeroMemory)
- [ ] All headers wrapped in `#ifndef _WIN32` (no-op on Windows)
- [ ] All headers use `#pragma once`
- [ ] PlatformCompat.h includes PlatformTypes.h

### CMake Integration

- [ ] Verify `Platform/` is in MUCommon/MUPlatform include path (line 171 of src/CMakeLists.txt)
- [ ] Platform test files registered in `tests/CMakeLists.txt` (MuTests target)
- [ ] `tests/platform/CMakeLists.txt` registered with `add_subdirectory(platform)`

### Test Verification (all must pass after implementation)

- [ ] `AC-2: PlatformTypes type size assertions` — sizeof(DWORD)==4, sizeof(BOOL)==sizeof(int), sizeof(BYTE)==1, sizeof(WORD)==2
- [ ] `AC-2: PlatformTypes constants and macros` — TRUE==1, FALSE==0, MAX_PATH==260, LOWORD/HIWORD
- [ ] `AC-2: PlatformTypes handle types` — all pointer-sized
- [ ] `AC-2: PlatformTypes integral parameter types` — LPARAM, WPARAM, LRESULT, HRESULT sizes
- [ ] `AC-2: PlatformKeys` — all VK_* constants match Windows values
- [ ] `AC-1: PlatformCompat timing shims` — timeGetTime/GetTickCount non-zero and advancing
- [ ] `AC-1: PlatformCompat MessageBoxW stub` — returns IDOK, MB_* constants defined
- [ ] `AC-1: PlatformCompat RtlSecureZeroMemory` — zeroes buffer
- [ ] `AC-1: PlatformCompat file I/O shims` — _wfopen_s error handling
- [ ] `AC-3:platform-pragma-once` — all headers have #pragma once
- [ ] `AC-4:platform-header-existence` — all three headers exist
- [ ] `AC-5:no-game-logic-ifdef` — no new #ifdef _WIN32 in game logic

### Compile Validation

- [ ] `g++ -fsyntax-only -std=c++20 PlatformTypes.h` passes on macOS/Linux
- [ ] `g++ -fsyntax-only -std=c++20 PlatformCompat.h` passes on macOS/Linux
- [ ] `g++ -fsyntax-only -std=c++20 PlatformKeys.h` passes on macOS/Linux
- [ ] MinGW CI build passes with new headers

### Quality Gate

- [ ] `./ctl check` passes (format-check + lint)
- [ ] No clang-tidy warnings in new headers
- [ ] No cppcheck warnings in new headers

### PCC Compliance

- [ ] No prohibited libraries used (no raw new/delete, no NULL, no wprintf)
- [ ] Required patterns followed (#pragma once, std::chrono in timing shims, nullptr)
- [ ] No #ifdef _WIN32 outside Platform/ headers
- [ ] No backslash path literals in new code
- [ ] Conventional commit format: `refactor(platform): add cross-platform type aliases and compat headers`
- [ ] Flow code traceability: commit references VS0-PLAT-ABSTRACT-HEADERS

---

## Test Files Created (RED Phase)

| File | Type | AC Coverage |
|------|------|-------------|
| `MuMain/tests/platform/test_platform_types.cpp` | Catch2 unit | AC-2, AC-STD-2 |
| `MuMain/tests/platform/test_platform_compat.cpp` | Catch2 unit | AC-1 |
| `MuMain/tests/platform/test_platform_keys.cpp` | Catch2 unit | AC-2 (keys) |
| `MuMain/tests/platform/test_ac3_pragma_once.cmake` | CMake script | AC-3 |
| `MuMain/tests/platform/test_ac4_header_compilation.cmake` | CMake script | AC-4 |
| `MuMain/tests/platform/test_ac5_no_game_logic_changes.sh` | Shell script | AC-5, AC-STD-3 |
| `MuMain/tests/platform/CMakeLists.txt` | CMake config | Test registration |

---

## Notes

- All Catch2 tests will fail to compile until the Platform headers are created (RED phase)
- CMake script tests (AC-3, AC-4) will fail because headers don't exist yet
- AC-5 baseline test passes now but measures #ifdef _WIN32 count for regression
- MessageBoxW test validates stub behavior (returns IDOK); full SDL3 impl comes in story 1.3.1
- `std::wstring_convert` deprecation warning must be suppressed in PlatformCompat.h
- On Windows, all platform headers are no-ops (#ifndef _WIN32), so Windows tests rely on <windows.h> types

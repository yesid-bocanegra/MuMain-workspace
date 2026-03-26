# Code Review — Story 7.8.3: Test Compilation Fixes

**Reviewer**: Claude (adversarial)
**Date**: 2026-03-26
**Story Key**: 7-8-3-test-compilation-fixes
**Files Reviewed**: 17 (15 in File List + 2 additional modified)

---

## Quality Gate

**Status**: PASS — run by pipeline (pre-run results)

| Check | Status |
|-------|--------|
| lint | PASS |
| build | PASS |
| coverage | PASS (no coverage configured) |

---

## Findings

### F-1: WZResult::BuildResult double-formatting vulnerability

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/tests/stubs/test_game_stubs.cpp` |
| **Lines** | 232–243 |
| **Category** | Correctness / Undefined Behavior |

**Description**: `BuildResult()` formats user input with `vswprintf(Buffer, ...)`, then passes the formatted `Buffer` to `SetResult(dwErrorCode, dwWindowErrorCode, Buffer)`. Inside `SetResult`, `Buffer` is treated as a *format string* and expanded again via `vswprintf(m_szErrorMessage, MAX_ERROR_MESSAGE, szFormat, va)`. If the original format produces output containing `%` characters (e.g., from `%%` → `%`), the second pass interprets `%` as a format specifier and reads from an empty `va_list` — undefined behavior.

**Suggested Fix**: In `BuildResult`, replace the `SetResult` call with direct member assignment:
```cpp
result.m_dwErrorCode = dwErrorCode;
result.m_dwWindowErrorCode = dwWindowErrorCode;
wcsncpy(result.m_szErrorMessage, Buffer, MAX_ERROR_MESSAGE - 1);
result.m_szErrorMessage[MAX_ERROR_MESSAGE - 1] = L'\0';
```

---

### F-2: mu_swprintf hardcoded 1024 buffer size replicated into PlatformCompat.h

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/src/source/Platform/PlatformCompat.h` |
| **Lines** | 2320–2322 |
| **Category** | Correctness / Buffer Overflow Risk |

**Description**: The `mu_swprintf` template on GCC/Clang passes `1024` as the buffer size to `std::swprintf`, regardless of the actual buffer capacity. This pre-existing design issue (already present in `stdafx.h:336`) is now replicated into PlatformCompat.h, enshrining the bug in two locations. Any caller providing a buffer smaller than 1024 wide characters risks a buffer overflow on non-MSVC platforms.

**Suggested Fix**: Accept a size parameter or use the array-deducing overload pattern:
```cpp
template <size_t N, typename... Args>
inline int mu_swprintf(wchar_t (&buffer)[N], const wchar_t* format, Args... args)
{
    return std::swprintf(buffer, N, format, args...);
}
```
Note: This is a pre-existing design issue. Track as tech debt if not addressable in this story.

---

### F-3: WZResult::operator= missing self-assignment guard

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | `MuMain/tests/stubs/test_game_stubs.cpp` |
| **Lines** | 198–205 |
| **Category** | Correctness / Undefined Behavior |

**Description**: `WZResult::operator=` calls `wcsncpy(m_szErrorMessage, a2.m_szErrorMessage, ...)`. If `this == &a2` (self-assignment), the source and destination buffers overlap. Per the C standard, `wcsncpy` with overlapping buffers is undefined behavior. While unlikely to be triggered in test scenarios, this is a correctness defect in a "real implementation" that tests check return values of.

**Suggested Fix**: Add self-assignment guard:
```cpp
WZResult& WZResult::operator=(const WZResult& a2)
{
    if (this == &a2) return *this;
    // ... rest of copy
}
```

---

### F-4: PadRGBToRGBA does not validate negative dimensions

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/tests/stubs/test_game_stubs.cpp` |
| **Lines** | 380–392 |
| **Category** | Robustness |

**Description**: `PadRGBToRGBA(const uint8_t* rgbData, int width, int height)` casts `width` and `height` to `size_t` without checking they are non-negative. Negative values wrap to very large unsigned values, causing a massive allocation attempt and out-of-bounds reads from `rgbData`. The function is marked as a "real implementation" that is "tested directly by test_texturesystemmigration.cpp".

**Suggested Fix**: Add a precondition check:
```cpp
if (width <= 0 || height <= 0 || rgbData == nullptr) return {};
```

---

### F-5: MuStabilityTests missing test_game_stubs.cpp linkage

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/tests/CMakeLists.txt` |
| **Lines** | 410–417 |
| **Category** | Maintainability |

**Description**: `MuStabilityTests` links the same libraries as `MuTests` (MUCore, MUPlatform, MURenderFX, MUAudio) but does not include `stubs/test_game_stubs.cpp`. Currently builds because the stability test TU doesn't reference the stubbed symbols, but any future stability test that exercises game code paths will hit linker failures with no obvious cause.

**Suggested Fix**: Add `target_sources(MuStabilityTests PRIVATE stubs/test_game_stubs.cpp)` after line 411 for consistency.

---

### F-6: Class stub definitions create parallel maintenance burden

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/tests/stubs/test_game_stubs.cpp` |
| **Lines** | 96–180 |
| **Category** | Maintainability |

**Description**: The stub file contains full class definitions for `CGlobalBitmap`, `Connection`, `CUIRenderText`, `CNewUIMiniMap`, and `CNewUISystem`. These must remain ABI-compatible with their real implementations. If the real class adds or removes a virtual method, changes a method signature, or reorders the vtable, the stubs silently drift, potentially causing ODR violations or subtle test failures. There is no compile-time mechanism to detect this drift.

**Suggested Fix**: Document the dependency in a comment header with the real source file paths, and consider adding a build-system comment that flags these files for review when the real implementations change. Alternatively, investigate whether the real headers can be included without pulling in all game dependencies.

---

### F-7: Out-of-scope formatting change in MiniAudioBackend.cpp

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` |
| **Lines** | 373–374 |
| **Category** | Process |

**Description**: The diff includes a formatting-only change to `ma_sound_set_position` (line joining) that is unrelated to the story's test compilation objectives. This appears to be a `clang-format` side effect when the file was formatted. While harmless, it adds noise to the story's diff and makes change attribution harder in `git blame`.

**Suggested Fix**: No code change needed. Accept as clang-format normalization. Note for future: `./ctl format` should be run before story work begins to avoid incidental formatting changes mixing into story diffs.

---

## ATDD Coverage

| AC | Checklist Status | Verified Against Code | Assessment |
|----|------------------|-----------------------|------------|
| AC-1 | COMPLETE | 10 enum names replaced, kSynthesis removed | **ACCURATE** — diff confirms all 10 replacements match mu_define.h |
| AC-2 | COMPLETE | k_BlendFactor_DstColor line removed | **ACCURATE** — single line deletion verified |
| AC-3 | COMPLETE | Build passes (pre-run QG) | **ACCURATE** — quality gate PASS confirmed |
| AC-4 | COMPLETE | 89/90 tests | **ACCURATE** — 1 pre-existing SIGSEGV (WriteOpenGLInfo) |
| AC-5 | COMPLETE | ./ctl check exits 0 | **ACCURATE** — quality gate PASS confirmed |
| AC-STD-1 | COMPLETE | clang-format clean | **ACCURATE** — lint PASS confirmed |
| AC-STD-2 | COMPLETE | Tests compile and execute | **ACCURATE** — build PASS confirmed |
| AC-STD-13 | COMPLETE | Quality gate exits 0 | **ACCURATE** — matches AC-5 |
| AC-STD-15 | COMPLETE | No force push | **ACCURATE** — git log shows clean history |

**ATDD Assessment**: All checklist items are accurately marked. No false completions detected.

---

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| HIGH | 0 |
| MEDIUM | 3 |
| LOW | 4 |
| **Total** | **7** |

The story achieves its stated objectives: both test compilation errors are fixed, pre-existing cross-platform build blockers are resolved, and all quality gates pass. The MEDIUM findings are all in the newly-created `test_game_stubs.cpp` — specifically in WZResult "real implementations" that could exhibit undefined behavior under edge conditions. The LOW findings are maintenance concerns that don't affect current correctness. No blockers identified.

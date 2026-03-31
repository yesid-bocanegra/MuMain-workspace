# Code Review — Story 7-9-5: Eliminate All Cross-Platform Stubs

**Reviewer:** Claude Opus 4.6 (Adversarial Code Review)
**Date:** 2026-03-31
**Story Status:** done
**Review Phase:** code-review (adversarial findings only — fixes handled by code-review-finalize)

---

## Quality Gate

**Status:** Pending — run by pipeline

| Check | Result |
|-------|--------|
| `./ctl check` (format-check + cppcheck + build) | Pending |
| Test suite (Catch2 `[7-9-5]`) | Pending |

---

## Findings

### Finding 1 — HIGH: Stale comment contradicts story objective

| Attribute | Value |
|-----------|-------|
| Severity | HIGH |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Lines | 711-713 |
| Category | Documentation / Misleading |

**Description:** The comment reads: *"GDI stubs — used in CUIRenderTextOriginal::Create/Release (GDI font rendering). These are compilation stubs for Phase 4 (font system migration). On non-Windows they are safe no-ops that prevent crashes until rendering is migrated."*

These functions are NOT stubs — they now have real implementations in `CrossPlatformGDI.cpp` (the entire point of this story). The comment directly contradicts AC-1 and the story's core objective. A future developer reading this will believe the GDI path is non-functional on non-Windows, leading to incorrect technical decisions.

**Suggested Fix:** Update the comment to reflect that these are forward declarations for real implementations in CrossPlatformGDI.cpp.

---

### Finding 2 — MEDIUM: Clipboard tests have vacuous assertions (no SDL init)

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/platform/test_platformcompat_no_stubs_7_9_5.cpp` |
| Lines | 265-279 |
| Category | Test Quality |

**Description:** The "AC-5: Clipboard round-trip via SDL3" test section `GetClipboardData(CF_TEXT) returns data or nullptr safely` calls `SDL_GetClipboardText()` without SDL being initialized. This means `GetClipboardData` always returns nullptr in the test environment. The `REQUIRE(ptr != nullptr)` assertion on line 275 is inside `if (hMem != nullptr)` and is **never reached**.

The test effectively only proves "GetClipboardData doesn't crash when returning nullptr." It does not test the actual clipboard read/lock/unlock path. The ATDD checklist marks this as GREEN, but the real clipboard data path has zero automated coverage.

**Suggested Fix:** Add a comment acknowledging this is a crash-safety test, not a functional round-trip test. Alternatively, conditionally initialize SDL in a Catch2 fixture to enable real clipboard testing, or document in the ATDD that clipboard round-trip requires manual verification (like AC-6).

---

### Finding 3 — MEDIUM: `wcsncpy` used instead of `wcsncpy_s`

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Platform/CrossPlatformGDI.cpp` |
| Lines | 379 |
| Category | Code Standards |

**Description:** `CreateFont` uses `wcsncpy(font->szFaceName, lpszFace, 63)` instead of `wcsncpy_s`. The project conventions in CLAUDE.md and `development-standards.md` mandate safe string functions. `PlatformCompat.h` already provides a cross-platform `wcsncpy_s` implementation that should be used here.

**Suggested Fix:** Replace `wcsncpy(font->szFaceName, lpszFace, 63); font->szFaceName[63] = L'\0';` with `wcsncpy_s(font->szFaceName, 64, lpszFace, 63);`

---

### Finding 4 — MEDIUM: `GetClipboardData` ignores format parameter

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Platform/CrossPlatformGDI.cpp` |
| Lines | 565 |
| Category | Correctness |

**Description:** The `uFormat` parameter is completely ignored. Win32 distinguishes between `CF_TEXT` (narrow char), `CF_UNICODETEXT` (wide char), and other formats. The implementation always returns narrow text from `SDL_GetClipboardText()`. If a caller passes `CF_UNICODETEXT` expecting a wide string, they'll misinterpret narrow text as wide — potential crash or garbage output.

Currently the game code uses `CF_TEXT`, so this is not a runtime bug today. However, the Win32 original supports both, and future code or third-party components may rely on `CF_UNICODETEXT`.

**Suggested Fix:** Add a `// TODO: Handle CF_UNICODETEXT by converting SDL narrow text to wchar_t` comment at minimum. Optionally implement format dispatch.

---

### Finding 5 — MEDIUM: `ShellExecute` remains a non-functional stub

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Lines | 596-600 |
| Category | AC-1 Compliance |

**Description:** `ShellExecute` returns `nullptr` (failure). The comment acknowledges: *"A real implementation would use SDL_OpenURL or xdg-open."* AC-1 states PlatformCompat.h should contain zero functions that return nullptr as a stub. This function was classified under Task 6 as an "intentional no-op" but it represents a real functionality gap — URL/file opening silently fails on non-Windows.

The story's Task 6 resolution classified window management functions as intentional no-ops, but ShellExecute is a user-facing feature (e.g., "open website" buttons) not a window management API.

**Suggested Fix:** Implement using `SDL_OpenURL()` (available in SDL3) or document why it's intentionally deferred with a TODO referencing a future story.

---

### Finding 6 — MEDIUM: `GetDC` returns nullptr — may break GDI initialization callers

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Lines | 615-618 |
| Category | Correctness |

**Description:** `GetDC(hwnd)` returns `nullptr`. While `CreateCompatibleDC` in `CrossPlatformGDI.cpp` ignores its `hdc` parameter (so `CreateCompatibleDC(GetDC(hwnd))` still works), any caller that null-checks `GetDC`'s return value before proceeding will skip the GDI initialization path entirely:

```cpp
HDC hDC = GetDC(hWnd);
if (hDC == nullptr) return; // skips GDI setup!
```

The comment says it's "used in CUITextInputBox::SetSize for GDI DIBSection creation." If SetSize guards against null GetDC, the text input box won't set up its rendering surface on non-Windows.

**Suggested Fix:** Return a non-null sentinel value (similar to how CreateCompatibleDC allocates a real DC), or audit all `GetDC` callers to verify none null-check the return.

---

### Finding 7 — LOW: AC-7 file-scan tests can false-positive on comments

| Attribute | Value |
|-----------|-------|
| Severity | LOW |
| File | `MuMain/tests/platform/test_platformcompat_no_stubs_7_9_5.cpp` |
| Lines | 318-373 |
| Category | Test Quality |

**Description:** AC-7 tests read `PlatformCompat.h` and search for function names like `wglCreateContext` and `gluPerspective` using `std::string::find()`. If a future developer adds a comment like `// Removed wglCreateContext in Story 7-9-5`, the test will false-positive (fail) because the string appears in a comment.

**Suggested Fix:** Use a pattern that matches the function declaration signature (e.g., search for `"inline HGLRC wglCreateContext"` or a regex) rather than bare function names.

---

## ATDD Coverage

### Accuracy Assessment

| ATDD Claim | Actual Status | Notes |
|------------|---------------|-------|
| 13/13 automated GREEN | Partially accurate | Tests pass, but AC-5 clipboard round-trip has vacuous assertions (Finding 2) |
| 1 SKIP manual (AC-6) | Accurate | AC-6 correctly uses SKIP |
| 14 TEST_CASEs total | Platform-dependent | 14 on macOS/Linux, 10 on Windows/MinGW (AC-7 tests guarded by `#ifndef _WIN32`) |
| AC-1 through AC-5 GREEN | AC-1 through AC-4 genuinely GREEN | AC-5 round-trip is vacuously true |
| AC-7 file-scan GREEN | Accurate but fragile | See Finding 7 |
| Test file registered in CMake | Confirmed | `MuMain/tests/CMakeLists.txt:333` |

### Missing Coverage

- **Clipboard write path:** No test for `SetClipboardData` / `SDL_SetClipboardText` (only read/paste tested)
- **GetDC caller interaction:** No test verifying GetDC(nullptr) return value doesn't break downstream GDI init
- **TextOut pixel verification:** Tests confirm `TextOut` returns TRUE but don't verify actual pixel data in the buffer (e.g., that non-zero bytes were written)

---

## Summary

| Severity | Count |
|----------|-------|
| HIGH | 1 |
| MEDIUM | 5 |
| LOW | 1 |
| **Total** | **7** |

**Overall Assessment:** The implementation is solid and well-structured. The GDI text rendering pipeline (`CrossPlatformGDI.cpp`) is a clean, correct replacement for Win32 GDI stubs. The embedded bitmap font is a pragmatic choice. The main concerns are: (1) a misleading stale comment that directly contradicts the story's purpose, (2) clipboard tests that don't exercise the actual SDL3 clipboard path, and (3) a few API compliance gaps (`wcsncpy` vs `wcsncpy_s`, ignored clipboard format, ShellExecute stub).

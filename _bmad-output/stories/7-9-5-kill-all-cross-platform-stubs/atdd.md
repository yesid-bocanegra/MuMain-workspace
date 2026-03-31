# ATDD Implementation Checklist — Story 7-9-5
# Eliminate All Cross-Platform Stubs — Real SDL3 Implementations
# [VS0-PLAT-COMPAT-KILLSTUBS]

**Generated:** 2026-03-31
**Story Type:** infrastructure
**Test Phase:** RED (all GDI/clipboard/file-scan tests fail until implementation is complete)
**ATDD Checklist Path:** `_bmad-output/stories/7-9-5-kill-all-cross-platform-stubs/atdd.md`

---

## PCC Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Guidelines loaded | ✅ | project-context.md + development-standards.md |
| No prohibited libraries | ✅ | Tests use only PlatformCompat.h, Catch2, stdlib |
| Required testing framework | ✅ | Catch2 v3.7.1 (FetchContent, MuTests target) |
| No mocking framework | ✅ | Pure logic tests, no mocks |
| No Win32 deps in test TU | ✅ | Tests include PlatformCompat.h only (cross-platform) |
| AC-N: prefixes on all test cases | ✅ | All TEST_CASE names include AC-N: prefix |
| Coverage target | ✅ | Threshold=0 (growing incrementally per project-context.md) |
| Existing tests mapped (Step 0.5) | ✅ | No pre-existing 7-9-5 tests found — all ACs new |

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | File | Phase |
|----|-------------|----------------|------|-------|
| AC-1 | Zero stub returns in PlatformCompat.h | `AC-1: CreateCompatibleDC returns a non-null sentinel DC` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-1 | CreateDIBSection allocates real buffer | `AC-1: CreateDIBSection allocates a real pixel buffer` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-1 | SelectObject/DeleteDC/DeleteObject safe | `AC-1: SelectObject, DeleteDC, DeleteObject do not crash` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-2 | CreateFont returns non-null HFONT | `AC-2: CreateFont returns a non-null HFONT` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-3 | GetTextExtentPoint32 accurate | `AC-3: GetTextExtentPoint32 returns non-zero SIZE for non-empty text` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-4 | TextOut rasterizes text | `AC-4: TextOut succeeds when given a valid DC and bitmap` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-4 | SetTextColor/SetBkColor/SetBkMode | `AC-4: SetTextColor, SetBkColor, SetBkMode do not crash` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-5 | OpenClipboard returns TRUE | `AC-5: OpenClipboard returns TRUE on SDL3 path` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-5 | Clipboard round-trip via SDL3 | `AC-5: Clipboard round-trip via SDL3` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-6 | WebzenScene completes | `AC-6: WebzenScene completes — MANUAL verification` | test_platformcompat_no_stubs_7_9_5.cpp | SKIP |
| AC-7 | wglCreateContext removed | `AC-7: wglCreateContext stub is removed from PlatformCompat.h` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-7 | gluPerspective removed | `AC-7: gluPerspective stub is removed from PlatformCompat.h` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-7 | Registry stubs removed | `AC-7: Dead registry stubs removed from PlatformCompat.h` | test_platformcompat_no_stubs_7_9_5.cpp | RED |
| AC-7 | Win32 file I/O stubs removed | `AC-7: Dead Win32 file I/O stubs removed from PlatformCompat.h` | test_platformcompat_no_stubs_7_9_5.cpp | RED |

---

## Implementation Checklist

### Unit Tests — GDI Text Rendering (AC-1, AC-2, AC-3, AC-4)

- [ ] `AC-1: CreateCompatibleDC returns a non-null sentinel DC` — REQUIRE(dc != nullptr)
- [ ] `AC-1: CreateDIBSection allocates a real pixel buffer` — REQUIRE(bmp != nullptr), REQUIRE(bits != nullptr), pixel write/read
- [ ] `AC-1: SelectObject, DeleteDC, DeleteObject do not crash` — SECTION: bitmap selection, null DC, null object
- [ ] `AC-2: CreateFont returns a non-null HFONT` — REQUIRE(font != nullptr) with real size/weight/face params
- [ ] `AC-3: GetTextExtentPoint32 — single char has positive dimensions` — REQUIRE(sz.cx > 0), REQUIRE(sz.cy > 0)
- [ ] `AC-3: GetTextExtentPoint32 — multi-char width > single-char width` — REQUIRE(sz5.cx > sz1.cx)
- [ ] `AC-3: GetTextExtentPoint32 — empty string returns zero width` — REQUIRE(sz.cx == 0)
- [ ] `AC-4: TextOut returns TRUE for non-empty string` — full pipeline DC+bitmap+font+SelectObject
- [ ] `AC-4: TextOut returns TRUE for single character`
- [ ] `AC-4: SetTextColor, SetBkColor, SetBkMode do not crash`

### Unit Tests — Clipboard (AC-5)

- [ ] `AC-5: OpenClipboard returns TRUE on SDL3 path` — REQUIRE(ok == TRUE)
- [ ] `AC-5: Clipboard round-trip — OpenClipboard/CloseClipboard pair` — REQUIRE(opened == TRUE)
- [ ] `AC-5: Clipboard round-trip — GetClipboardData returns data or null safely` — no crash, GlobalLock non-null if data exists

### Manual Test — WebzenScene (AC-6)

- [ ] `AC-6: WebzenScene completes` — MANUAL: launch game, verify title screen renders, scene transitions to LOG_IN_SCENE
  - Verify: OpenFont() does not return nullptr
  - Verify: Progress bar is visible on WebzenScene
  - Verify: All game data loads (ZzzOpenData sequence)
  - Verify: LOG_IN_SCENE appears after loading
  - Verify: Login UI text is readable

### File-Scan Tests — Dead Stub Removal (AC-7, non-Windows only)

- [ ] `AC-7: wglCreateContext stub removed` — content.find("wglCreateContext") == npos
- [ ] `AC-7: gluPerspective stub removed` — content.find("gluPerspective") == npos
- [ ] `AC-7: RegOpenKeyEx stub removed` — content.find("RegOpenKeyEx") == npos
- [ ] `AC-7: RegQueryValueEx stub removed` — content.find("RegQueryValueEx") == npos
- [ ] `AC-7: RegSetValueEx stub removed` — content.find("RegSetValueEx") == npos
- [ ] `AC-7: CreateFile stub removed` — content.find("inline HANDLE CreateFile") == npos
- [ ] `AC-7: ReadFile stub removed` — content.find("inline BOOL ReadFile") == npos

### Standard AC Compliance

- [ ] `AC-STD-1: Code naming conventions` — PascalCase functions, `m_` members, `#pragma once`, no NULL, no raw new/delete
- [ ] `AC-STD-2: Catch2 tests present` — test file exists at `MuMain/tests/platform/test_platformcompat_no_stubs_7_9_5.cpp`
- [ ] `AC-STD-13: Quality gate passes` — `./ctl check` exits 0 (format-check + cppcheck + build)
- [ ] `AC-STD-15: Git safety` — no incomplete rebase, no force push to main
- [ ] `AC-STD-16: Correct test infrastructure` — Catch2 v3.7.1, TEST_CASE/SECTION/REQUIRE, no mocking framework

### PCC Compliance Items

- [ ] No prohibited libraries used (raw new/delete, NULL, wprintf, MessageBoxW direct, GetAsyncKeyState)
- [ ] No `#ifdef _WIN32` in game logic — only in Platform/ abstraction headers
- [ ] No backslash path literals
- [ ] `std::unique_ptr` for new allocations (not raw new/delete)
- [ ] `nullptr` not `NULL` throughout CrossPlatformGDI.cpp
- [ ] `#pragma once` in CrossPlatformGDI.h (not `#ifndef` guard)
- [ ] All new code follows Allman brace style, 4-space indent, 120-col limit
- [ ] Cppcheck passes on new files (`./ctl check` clean)

---

## Test Files Created (RED Phase)

| File | Status | ACs Covered |
|------|--------|-------------|
| `MuMain/tests/platform/test_platformcompat_no_stubs_7_9_5.cpp` | Created — RED | AC-1, AC-2, AC-3, AC-4, AC-5, AC-6 (SKIP), AC-7 |

**Total test methods:** 14 TEST_CASEs (13 automated, 1 SKIP)
**Automated RED:** 13 tests will FAIL until CrossPlatformGDI.cpp is implemented
**Manual:** 1 test (AC-6) uses Catch2 SKIP — manual game session required

---

## Implementation Notes for Dev Agent

### Critical Path

1. **Task 2 first** (GDI text rendering) — unblocks OpenFont() and all text rendering
2. **Task 3** (clipboard) — enables paste operations in chat/UI
3. **Task 4** (delete WGL/GLU stubs) — turns AC-7 file-scan tests GREEN
4. **Task 5** (delete registry/file stubs) — turns remaining AC-7 tests GREEN
5. **Task 8** (WebzenScene manual session) — turns AC-6 GREEN

### Key Files for Implementation

| Action | File |
|--------|------|
| CREATE | `MuMain/src/source/Platform/CrossPlatformGDI.cpp` |
| CREATE | `MuMain/src/source/Platform/CrossPlatformGDI.h` |
| MODIFY | `MuMain/src/source/Platform/PlatformCompat.h` — replace stubs with calls to CrossPlatformGDI |

### CrossPlatformGDI.h Must Declare

```cpp
// Real DC struct — opaque handle used by GDI functions
struct MuGdiDC;
struct MuGdiFont;

// Returns non-null MuGdiDC* — replaces s_stubDC sentinel
HDC  CreateCompatibleDC(HDC hdc);
void DeleteDC(HDC hdc);

// Returns calloc'd pixel buffer — replaces 1x1 stub
HBITMAP CreateDIBSection(HDC hdc, const BITMAPINFO* bmi, UINT usage,
                         void** ppvBits, HANDLE hSection, DWORD offset);

// Returns non-null MuGdiFont* — replaces nullptr stub
HFONT CreateFont(int nHeight, int nWidth, int nEscapement, int nOrientation,
                 int fnWeight, DWORD fdwItalic, DWORD fdwUnderline, DWORD fdwStrikeOut,
                 DWORD fdwCharSet, DWORD fdwOutputPrecision, DWORD fdwClipPrecision,
                 DWORD fdwQuality, DWORD fdwPitchAndFamily, const wchar_t* lpszFace);

// Real glyph measurement from bitmap font atlas
BOOL GetTextExtentPoint32(HDC hdc, const wchar_t* pszText, int cch, SIZE* lpSize);

// Real glyph rasterization into pixel buffer
BOOL TextOut(HDC hdc, int x, int y, const wchar_t* str, int len);
```

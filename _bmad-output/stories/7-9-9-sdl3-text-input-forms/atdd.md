# ATDD Checklist — Story 7-9-9: SDL3 Text Input Forms

**Story Key:** 7-9-9
**Flow Code:** VS1-INPUT-TEXTFORMS-SDL3
**Story Type:** infrastructure
**Test Phase:** RED (pre-implementation — tests written before code)
**Date:** 2026-04-08
**Status:** ready-for-dev

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Guidelines loaded (project-context.md) | ✓ |
| Development standards loaded | ✓ |
| Prohibited libraries used | None |
| Framework | Catch2 v3.7.1 (project standard) |
| Test location | `tests/platform/test_text_input_forms_7_9_9.cpp` |
| Prohibited patterns | None (no Win32 in test logic, no mocking) |
| Coverage threshold | 0 (project standard — growing incrementally) |
| Bruno collection | N/A (infrastructure story — no REST endpoints) |
| Playwright E2E | N/A (infrastructure story — no web frontend) |

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | Phase |
|----|-------------|----------------|-------|
| AC-1 | GiveFocus idempotent | `"AC-1 [7-9-9]: GiveFocus called twice on same box invokes MuStartTextInput once"` | Executable |
| AC-1 | GiveFocus clears other box focus | `"AC-1 [7-9-9]: GiveFocus on box B clears focus from box A"` | Executable |
| AC-2 | SetFont font into memory DC | `"AC-2 [7-9-9]: SetFont stores font handle and uses it in SDL3 render path"` | SKIP — Win32 GDI |
| AC-3 | DoActionSub stable focus guard | `"AC-3 [7-9-9]: DoActionSub consumes SDL text input when box has stable focus"` | Executable |
| AC-3 | WriteText→QueueTextureUpdate pipeline | `"AC-3 [7-9-9]: Render pipeline WriteText→QueueTextureUpdate produces non-zero pixels"` | SKIP — Win32 GDI + GPU |
| AC-4 | g_pSinglePasswdInputBox non-null | `"AC-4 [7-9-9]: g_pSinglePasswdInputBox is non-null after initialization"` | SKIP — requires game init |
| AC-4 | g_pSingleTextInputBox non-null | `"AC-4 [7-9-9]: g_pSingleTextInputBox is non-null after initialization"` | SKIP — requires game init |
| AC-5 | Same-frame press+release edge | `"AC-5 [7-9-9]: Same-frame press+release sets edge flag for ScanAsyncKeyState"` | Executable |
| AC-6 | Chat/popup DoActionSub | `"AC-6 [7-9-9]: Chat input box accepts keyboard input via DoActionSub"` | SKIP — same path as AC-3 |

---

## Generated Test Files

| File | Status | Covers |
|------|--------|--------|
| `MuMain/tests/platform/test_text_input_forms_7_9_9.cpp` | RED | AC-1, AC-2(SKIP), AC-3, AC-4(SKIP), AC-5, AC-6(SKIP) |
| `MuMain/tests/stubs/test_game_stubs.cpp` | UPDATED | Added `CUITextInputBox` forward-declare stubs for AC-4 linker resolution |
| `MuMain/tests/CMakeLists.txt` | UPDATED | Registered new test file in MuTests target |

---

## Implementation Checklist

### AC-1: GiveFocus Idempotency

- [ ] `CUITextInputBox::GiveFocus()` in `ThirdParty/UIControls.cpp` — add early-return guard: `if (m_bSDLHasFocus) return;`
- [ ] Verify: second GiveFocus call on same box does NOT call `MuStartTextInput()` again
- [ ] Investigate call site causing per-frame GiveFocus spam (`UI/Legacy/Win.cpp` `CWin::Update`, tab cycling code)
- [ ] Ensure only ONE box has focus at a time — GiveFocus on box B must clear box A's `m_bSDLHasFocus`
- [ ] Run Catch2 tests: `ctest -R text_input_forms_7_9_9` — AC-1 tests pass (GREEN)

### AC-2: SetFont Font Storage

- [ ] `ThirdParty/UIControls.cpp:4174-4181` — store configured font handle as `m_hConfiguredFont` member
- [ ] `ThirdParty/UIControls.cpp:4013-4016` — SDL3 Render path: use `m_hConfiguredFont` instead of `g_hFont`
- [ ] Remove redundant `SelectObject(m_hMemDC, g_hFont)` from SDL3 Render path (SetFont already selects)
- [ ] Manual verify: `WriteText` finds `white > 0` pixels after TextOut in login box
- [ ] AC-2 test is SKIP — verification is manual (Win32 GDI not available on CI)

### AC-3: Text Capture and Rendering End-to-End

- [ ] Run Catch2 tests: AC-3 DoActionSub logic tests pass (GREEN) — confirms stable focus guard works
- [ ] Verify with AC-1 fix: `DoActionSub()` sets `m_iSDLTextLen > 0` when user types (log check)
- [ ] Verify `QueueTextureUpdate` uploads non-zero pixel data (trace log: `[RENDER] white > 0`)
- [ ] Manual verify: typed text visible in login username/password fields
- [ ] AC-3 render test is SKIP — verification is manual integration test

### AC-4: Global Input Box Initialization

- [ ] `Main/MuMain.cpp:68` — change `g_pSinglePasswdInputBox = nullptr` → allocate with `new CUITextInputBox`
- [ ] Call `Init()`, `SetSize()`, `SetFont(g_hFixFont)` on the new instance (mirroring CLoginWin::Create pattern)
- [ ] Verify `g_pSingleTextInputBox` is also initialized if used (check `UI/Legacy/CharMakeWin.cpp:220`)
- [ ] Add `assert(g_pSinglePasswdInputBox != nullptr)` at init completion point
- [ ] `UI/Legacy/MsgWin.cpp:504-508` — verify password input now works without null pointer access
- [ ] AC-4 test is SKIP — verify via startup log: `[INIT] g_pSinglePasswdInputBox initialized`

### AC-5: GetAsyncKeyState Press Edge Detection

- [ ] `Platform/sdl3/SDLEventLoop.cpp` — add `bool g_bMouseLButtonPressEdge` global flag
- [ ] Set `g_bMouseLButtonPressEdge = true` in `SDL_EVENT_MOUSE_BUTTON_DOWN` handler (do NOT clear on UP)
- [ ] `Platform/PlatformCompat.h:1228-1250` — update `GetAsyncKeyState(VK_LBUTTON)` shim: return `0x8000` if `MouseLButton || g_bMouseLButtonPressEdge`
- [ ] `UI/Framework/NewUICommon.cpp:175-202` or `ScanAsyncKeyState` — clear `g_bMouseLButtonPressEdge` after consumption
- [ ] Run Catch2 tests: `ctest -R text_input_forms_7_9_9` — AC-5 tests pass (GREEN)

### AC-6: Chat and Popup Text Input

- [ ] Confirm `CNewUIChatInputBox::DoActionSub()` calls the SAME code path as `CUITextInputBox::DoActionSub()`
- [ ] Manual verify: type in chat box after login — text appears
- [ ] Manual verify: character name creation popup accepts text input
- [ ] Manual verify: guild name popup accepts text input
- [ ] AC-6 test is SKIP — covered by AC-3 code path and manual integration testing

---

## PCC Compliance Checklist

- [ ] No prohibited libraries (none in project-context.md apply to C++ platform tests)
- [ ] All Catch2 tests use `REQUIRE`/`CHECK` macros (not hand-rolled assertions)
- [ ] Tests use `TEST_CASE`/`SECTION` structure (no `TEST_CASE_METHOD` without justification)
- [ ] No mocking framework used — logic tested inline with local variables
- [ ] No Win32 API calls in executable test bodies (only in SKIP-guarded test bodies)
- [ ] All SKIP tests contain descriptive reason for skip and what verifies the AC
- [ ] Test file compiles clean on macOS/Linux CI (no missing includes, no link errors)
- [ ] `test_game_stubs.cpp` provides `CUITextInputBox` forward-declare for linker resolution
- [ ] `CMakeLists.txt` updated — `platform/test_text_input_forms_7_9_9.cpp` added to MuTests

---

## Build / Quality Gate

- [ ] `./ctl check` passes 0 errors on macOS (format-check + cppcheck)
- [ ] MinGW cross-compile builds successfully (test file compiles with `MU_ENABLE_SDL3`)
- [ ] `ctest -R text_input_forms_7_9_9` — executable tests pass (AC-1 ×3, AC-3 ×3, AC-5 ×4)
- [ ] `ctest -R text_input_forms_7_9_9` — SKIP tests report SKIP (not FAIL): AC-2, AC-3 render, AC-4, AC-6
- [ ] No regressions in existing platform test suite (`ctest -R platform`)

---

## ATDD Output Contract (for dev-story handoff)

| Output | Value |
|--------|-------|
| `atdd_checklist_path` | `_bmad-output/stories/7-9-9-sdl3-text-input-forms/atdd.md` |
| `test_files_created` | `MuMain/tests/platform/test_text_input_forms_7_9_9.cpp` |
| `implementation_checklist_complete` | TRUE (all items `[ ]` — ready for implementation) |
| `ac_test_mapping` | AC-1→2 executable TEST_CASEs; AC-2→SKIP; AC-3→3 TEST_CASEs (1 exec + 1 SKIP); AC-4→2 SKIPs; AC-5→1 TEST_CASE (4 SECTIONs); AC-6→SKIP |

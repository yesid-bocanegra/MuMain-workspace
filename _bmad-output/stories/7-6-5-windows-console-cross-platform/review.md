# Code Review — Story 7.6.5: Cross-Platform Terminal / Console

**Story Key:** 7-6-5-windows-console-cross-platform
**Reviewer:** claude-opus-4-6 (adversarial)
**Date:** 2026-03-25
**Status:** READY — pending code-review-analysis

---

## Pipeline Status

| Step | Status | Date | Duration |
|------|--------|------|----------|
| 1. Quality Gate | **PASSED** | 2026-03-25 | Pre-run results confirm all checks passing |
| 2. Code Review Analysis | **PENDING** | — | — |
| 3. Code Review Finalize | **PENDING** | — | — |

## Quality Gate

**Status:** PASSED (pre-run)
**Component:** mumain (cpp-cmake)

| Check | Result | Details |
|-------|--------|---------|
| lint | **PASS** | 0 cppcheck violations |
| build | **PASS** | Native macOS arm64 build clean |
| coverage | **PASS** | No coverage threshold configured |

---

## Findings

### Finding 1 — Background color leaks between SetTextColor calls

| Attribute | Value |
|-----------|-------|
| Severity | **HIGH** |
| File | `MuMain/src/source/Core/WindowsConsole.cpp` |
| Lines | 183–198 |
| AC | AC-4 (colour uses ANSI) |

**Description:** When `bgColorIndex == COLOR_BLACK` (the default), `SetTextColor()` calls `mu_set_console_text_color(ColorIndexToAnsiFg(textColorIndex))` which emits `\033[%dm` with ONLY the foreground SGR code. If a previous call set a non-black background, that background PERSISTS because a foreground-only SGR does not reset background attributes.

Concrete reproduction path in `muConsoleDebug.cpp:238-252`:
1. `MCD_ERROR` → `SetConsoleTextColor(COLOR_WHITE, COLOR_DARKRED)` → emits `\033[97;41m` (white fg, dark red bg)
2. `MCD_NORMAL` → `SetConsoleTextColor(COLOR_GRAY)` → default bg=`COLOR_BLACK` → emits only `\033[37m`
3. Result: gray text on **dark red background** instead of gray text on black background

**Suggested Fix:** When `bgColorIndex == COLOR_BLACK`, emit an ANSI reset before the foreground code, or always route through `mu_set_console_text_color_with_bg()`:
```cpp
void CConsoleWindow::SetTextColor(int textColorIndex, int bgColorIndex)
{
    m_currentTextColor = textColorIndex;
    m_currentBgColor = bgColorIndex;
    // Always emit both fg + bg to prevent background leaking from prior calls
    mu_set_console_text_color_with_bg(ColorIndexToAnsiFg(textColorIndex), ColorIndexToAnsiBg(bgColorIndex));
}
```

---

### Finding 2 — Missing `#include "WindowsConsole.h"` in test file

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/tests/core/test_console.cpp` |
| Lines | 10, 58, 63–66 |
| AC | AC-STD-2 (tests) |

**Description:** The test file includes only `<catch2/catch_test_macros.hpp>` and `"PlatformCompat.h"` but calls `leaf::SetConsoleTextColor(fg, bg)` on lines 58, 63–66. This function is declared in `WindowsConsole.h` (line 49), not in `PlatformCompat.h`. The test compiles only if `WindowsConsole.h` is resolved through transitive MUCore include paths, which is a fragile dependency — any refactoring of MUCore's include exports could break the test.

**Suggested Fix:** Add `#include "WindowsConsole.h"` to test_console.cpp.

---

### Finding 3 — ANSI escape output not guarded by TTY check

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Lines | 2516–2592 |
| AC | AC-4 (colour), AC-5 (title) |

**Description:** All console output functions (`mu_set_console_title`, `mu_set_console_text_color`, `mu_set_console_text_color_with_bg`, `mu_console_clear`, `mu_console_set_cursor_position`) write raw ANSI escape sequences to stdout unconditionally. The `mu_console_is_tty_ref()` helper was created during this story specifically to track TTY state, but none of the output functions consult it.

When stdout is redirected to a file or pipe (CI log collection, test harnesses, `>output.log`), ANSI escape sequences appear as binary garbage:
```
^[[97;41mERROR: Connection failed^[[37mReconnecting...
```

**Suggested Fix:** Guard each output function with `if (!mu_console_is_tty_ref()) return;`, or centralize the guard in a helper. The title function (`\033]0;...\007`) is especially problematic because the BEL character (`\007`) triggers audible alerts in some terminals when piped.

---

### Finding 4 — Color mapping test uses vacuous SUCCEED() with no assertions

| Attribute | Value |
|-----------|-------|
| Severity | **MEDIUM** |
| File | `MuMain/tests/core/test_console.cpp` |
| Lines | 47–70 |
| AC | AC-STD-2 (tests), AC-4 (colour) |

**Description:** The "AC-4: SetConsoleTextColor all colour indices" test case iterates all 256 fg/bg combinations and boundary values, but the only assertion is `SUCCEED("All colour index combinations handled without crash")`. This is a vacuous assertion — it passes unconditionally regardless of what the functions actually do. The test verifies crash-freedom but provides zero regression protection for:
- `ColorIndexToAnsiFg(0)` returning 30 (black → ANSI dark black)
- `ColorIndexToAnsiFg(15)` returning 97 (white → ANSI bright white)
- Invalid index fallback to 37 (light gray)
- Background offset correctness (fg+10)

The color mapping table (16 entries) is the most complex logic in this story and has no assertion-based coverage.

**Suggested Fix:** `ColorIndexToAnsiFg()` is `static` in WindowsConsole.cpp, making direct testing difficult. Either: (a) expose it via a test-only header, (b) capture stdout to verify ANSI output contains expected escape codes, or (c) add assertions on observable state via `GetTextColorIndex()` which returns the stored color index (verifying the input side of the mapping).

---

### Finding 5 — Close() does not reset cached color state

| Attribute | Value |
|-----------|-------|
| Severity | **LOW** |
| File | `MuMain/src/source/Core/WindowsConsole.cpp` |
| Lines | 141–145 |
| AC | N/A (correctness) |

**Description:** `Close()` resets `m_bVisible` and `m_started` but leaves `m_currentTextColor` and `m_currentBgColor` at their last-set values. If `Close()` is followed by `Open()`, `GetTextColorIndex()` returns stale color indices from the previous session while the terminal is actually in its default state (no ANSI attributes set). This desynchronizes the in-memory color cache from the actual terminal state.

**Suggested Fix:** Reset `m_currentTextColor = COLOR_WHITE; m_currentBgColor = COLOR_BLACK;` in `Close()`.

---

### Finding 6 — mu_console_init() performs redundant OS calls on repeated invocations

| Attribute | Value |
|-----------|-------|
| Severity | **LOW** |
| File | `MuMain/src/source/Platform/PlatformCompat.h` |
| Lines | 2494–2513 |
| AC | AC-3 (console init) |

**Description:** `mu_console_init()` has no idempotency guard. On Windows, every call invokes `GetStdHandle`, `GetConsoleMode`, and `SetConsoleMode`. In tests, it's called 3 times (once per TEST_CASE). In production, multiple `CConsoleWindow::Open()` calls would each trigger the full init sequence. While functionally harmless (SetConsoleMode is idempotent), the repeated kernel calls are unnecessary.

**Suggested Fix:** Add a static guard: `static bool s_inited = false; if (s_inited) return; s_inited = true;`

---

## ATDD Coverage

| Check | Status | Notes |
|-------|--------|-------|
| ATDD checklist accuracy | **PASS** | All 24 implementation items marked [x]; all 11 ACs mapped to verification methods |
| Phantom completions | **PASS** | Every checklist item has real evidence — code exists, tests exist, scripts pass |
| Test quality | **PARTIAL** | 2 of 3 tests have real REQUIRE assertions; 1 test (AC-4 color) relies solely on SUCCEED() |
| AC-to-test traceability | **PASS** | AC-3 → init test, AC-6 → size test, AC-4 → color test (crash-only), AC-1/AC-STD-1 → script, AC-7/AC-STD-13 → quality gate |
| Placeholder code | **PASS** | No TODOs, empty stubs, or unfinished implementations |

---

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 2 |

**Verdict:** One HIGH finding — background color leaking between console messages is a visible runtime bug in the debug console when switching from error (white-on-red) to normal (gray-on-black) message types. The 3 MEDIUM findings cover a fragile test include, unused TTY guard, and vacuous test assertions. The 2 LOW findings are minor correctness and efficiency improvements.

**Recommendation:** Fix Finding 1 (HIGH) before marking story complete. Findings 2–4 should be addressed in this cycle. Findings 5–6 are optional improvements.

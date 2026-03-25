# Test Scenarios: Story 7.6.5 — Cross-Platform Terminal / Console

**Generated:** 2026-03-25
**Story:** 7.6.5 Cross-Platform Terminal / Console
**Flow Code:** VS0-QUAL-WIN32CLEAN-CONSOLE
**Project:** MuMain-workspace

These scenarios cover validation of Story 7.6.5 acceptance criteria.
Automated tests (Catch2 unit tests in `MuMain/tests/core/test_console.cpp`) run on macOS/Linux.
Win32 guard validation via `check-win32-guards.py` script.
Quality gate via `./ctl check`.

---

## AC-1: Win32 Guard Check

### Scenario 1: check-win32-guards.py exits 0 (automated)

- **Prerequisites:** `MuMain/scripts/check-win32-guards.py` available
- **Given:** `Core/WindowsConsole.cpp` has been rewritten to use ANSI abstractions
- **When:** `python3 MuMain/scripts/check-win32-guards.py` is executed
- **Then:** Exit code 0, zero violations reported for `Core/WindowsConsole.cpp`
- **Automated:** Script validation (Task 5.1)
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-2: No Win32 Console APIs

### Scenario 2: WindowsConsole.cpp contains zero Win32 console APIs (code review)

- **Prerequisites:** `Core/WindowsConsole.cpp` readable
- **Given:** File has been rewritten with `mu_*` abstractions
- **When:** File is searched for `AllocConsole`, `SetConsoleMode`, `GetStdHandle`, `SetConsoleTextAttribute`, `FillConsoleOutputCharacter`, `GetConsoleScreenBufferInfo`, `COORD`, `CONSOLE_SCREEN_BUFFER_INFO`, `SMALL_RECT`, `CHAR_INFO`
- **Then:** Zero matches found — all Win32 console APIs removed
- **Automated:** MinGW CI build (compile-time enforcement)
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-3: Console Initialisation Uses ANSI

### Scenario 3: mu_console_init() does not crash (automated)

- **Prerequisites:** `PlatformCompat.h` compiled, `mu_console_init()` defined
- **Given:** Process has stdout available (may or may not be a TTY on CI)
- **When:** `mu_console_init()` is called
- **Then:** Returns cleanly without crash, exception, or assertion
- **Automated:** `TEST_CASE("AC-STD-2: console init does not crash on macOS/Linux")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-4: Colour Output Uses ANSI Escape Sequences

### Scenario 4: All colour index combinations handled without crash (automated)

- **Prerequisites:** Console initialized, `leaf::SetConsoleTextColor()` available
- **Given:** All valid colour indices (0-15) for foreground and background
- **When:** `SetConsoleTextColor(fg, bg)` called for all 256 combinations + invalid indices (-1, 16, 100)
- **Then:** No crash — ANSI codes emitted via `ColorIndexToAnsiFg()`/`ColorIndexToAnsiBg()` mapping table, boundary clamping works for invalid indices
- **Automated:** `TEST_CASE("AC-4: SetConsoleTextColor all colour indices")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-5: Terminal Title via ANSI OSC

### Scenario 5: mu_set_console_title uses ANSI OSC escape (code review)

- **Prerequisites:** `PlatformCompat.h` readable
- **Given:** `mu_set_console_title()` function definition
- **When:** Function is inspected
- **Then:** Uses `\033]0;{title}\007` ANSI OSC escape, same on all platforms. Null guard present.
- **Automated:** Code review verification
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-6: Console Size Cross-Platform

### Scenario 6: mu_get_console_size returns positive dimensions (automated)

- **Prerequisites:** Console initialized
- **Given:** Terminal may or may not be available (CI headless)
- **When:** `mu_get_console_size(&cols, &rows)` is called
- **Then:** `cols > 0` and `rows > 0` — minimum 80x24 fallback enforced
- **Automated:** `TEST_CASE("AC-STD-2: GetConsoleSize returns positive dimensions")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-7: Quality Gate

### Scenario 7: ./ctl check passes (automated)

- **Prerequisites:** Build tools installed (clang-format, cppcheck)
- **Given:** All story changes applied
- **When:** `./ctl check` is executed
- **Then:** Exit code 0 — format-check + lint all green, 723/723 files checked
- **Automated:** Quality gate (Task 5.2)
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-STD-1: Code Standards

### Scenario 8: No #ifdef _WIN32 in WindowsConsole.cpp (script validation)

- **Prerequisites:** `check-win32-guards.py` available
- **Given:** `WindowsConsole.cpp` uses only `mu_*` abstractions from `PlatformCompat.h`
- **When:** Win32 guard script scans `Core/WindowsConsole.cpp`
- **Then:** Zero `#ifdef _WIN32` wrappers found in `.cpp` file; Win32 APIs isolated in `PlatformCompat.h` stubs; clang-format clean
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-STD-2: Tests

### Scenario 9: Catch2 test file exists with required test cases

- **Prerequisites:** `tests/core/test_console.cpp` exists, registered in `tests/CMakeLists.txt`
- **Given:** Test file with `#include <catch2/catch_test_macros.hpp>`
- **When:** Test binary compiled and executed
- **Then:** 3 TEST_CASEs pass: console init no-crash, GetConsoleSize positive dimensions, colour mapping all indices
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## Summary

| AC | Test Method | Status |
|----|-------------|--------|
| AC-1 | Script: `check-win32-guards.py` | PASS |
| AC-2 | Compile-time (MinGW CI) + code review | PASS |
| AC-3 | Unit test: console init no-crash | PASS |
| AC-4 | Unit test: colour indices + code review | PASS |
| AC-5 | Code review: ANSI OSC in `mu_set_console_title` | PASS |
| AC-6 | Unit test: GetConsoleSize positive | PASS |
| AC-7 | Quality gate: `./ctl check` | PASS |
| AC-STD-1 | Script + code review | PASS |
| AC-STD-2 | Unit tests: 3 TEST_CASEs GREEN | PASS |
| AC-STD-13 | Quality gate | PASS |
| AC-STD-15 | Dev discipline | PASS |

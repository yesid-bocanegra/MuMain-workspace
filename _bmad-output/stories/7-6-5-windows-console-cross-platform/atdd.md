# ATDD Checklist — Story 7.6.5: Cross-Platform Terminal / Console

**Story Key:** 7-6-5-windows-console-cross-platform
**Story Type:** infrastructure
**Date Generated:** 2026-03-25
**Phase:** GREEN — all items implemented and verified

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Prohibited libraries | PASS | No banned libraries — Catch2 only |
| Required testing patterns | PASS | Catch2 `TEST_CASE`/`REQUIRE`/`CHECK`, GIVEN/WHEN/THEN comments |
| Test profiles | N/A | Infrastructure story — no server profile required |
| Win32 in tests | PASS | Test TU uses only `PlatformCompat.h` — no `<windows.h>` |
| Coverage target | N/A | Project threshold = 0 (growing incrementally) |

---

## AC-to-Test Mapping

| AC | Description | Test Method | File | Status |
|----|-------------|-------------|------|--------|
| AC-1 | `check-win32-guards.py` exits 0 for `WindowsConsole.cpp` | Script validation (Task 5.1) | Manual | `[x]` |
| AC-2 | No Win32 console API in `WindowsConsole.cpp` | Compile-time — MinGW CI build | CI | `[x]` |
| AC-3 | Console init enables ANSI on all platforms | `TEST_CASE("console init does not crash on macOS/Linux")` | `tests/core/test_console.cpp` | `[x]` |
| AC-4 | Colour/cursor/clear use ANSI sequences | Code review — no Win32 colour API in `WindowsConsole.cpp` | Code review | `[x]` |
| AC-5 | Terminal title via ANSI OSC escape | Code review — `mu_set_console_title` uses `\033]0;` | Code review | `[x]` |
| AC-6 | `mu_get_console_size()` returns positive dimensions | `TEST_CASE("GetConsoleSize returns positive dimensions")` | `tests/core/test_console.cpp` | `[x]` |
| AC-7 | `./ctl check` passes | `./ctl check` exits 0 | Quality gate | `[x]` |
| AC-STD-1 | No `#ifdef _WIN32` in `WindowsConsole.cpp`; Win32 in `PlatformCompat.h` only | `python3 MuMain/scripts/check-win32-guards.py` | Script | `[x]` |
| AC-STD-2 | Catch2 tests in `tests/core/test_console.cpp` — init no-crash + size positive | Both TEST_CASEs exist and pass | `tests/core/test_console.cpp` | `[x]` |
| AC-STD-13 | Quality gate `./ctl check` exits 0 | `./ctl check` | Quality gate | `[x]` |
| AC-STD-15 | Git Safety — no force push, no incomplete rebase | Dev discipline | Manual | `[x]` |

---

## Test Files Created (RED Phase)

| File | Phase | Compiles | Tests Pass | Blocked Until |
|------|-------|----------|------------|---------------|
| `MuMain/tests/core/test_console.cpp` | GREEN | Yes | Yes | All dependencies satisfied |

---

## Implementation Checklist

All items start `[x]` (pending). Mark `[x]` as each is completed during dev-story.

### Task 1: Audit WindowsConsole.cpp

- [x] Read `Core/WindowsConsole.cpp` completely; list every Win32 API, type, and constant used
- [x] Group Win32 usage by functional category: init, colour, cursor, size, clear, title
- [x] Confirm no `mu_console_*` functions exist in `PlatformCompat.h` yet

### Task 2: Add Cross-Platform Abstractions to PlatformCompat.h

- [x] Add `mu_console_init()` — Windows: `SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), ENABLE_VIRTUAL_TERMINAL_PROCESSING | ENABLE_PROCESSED_OUTPUT)`; POSIX: `isatty(STDOUT_FILENO)` + set `g_muConsoleIsTTY`
- [x] Add `mu_set_console_title(const wchar_t* title)` — `printf("\033]0;%s\007", mu_wchar_to_utf8(title))`
- [x] Add `mu_set_console_text_color(int colorCode)` — ANSI escape `\033[{code}m`
- [x] Add `mu_get_console_size(int* cols, int* rows)` — POSIX: `ioctl(STDOUT_FILENO, TIOCGWINSZ)`; Windows: `GetConsoleScreenBufferInfo` fallback inside init only; default 80×24
- [x] Add `mu_console_clear()` — `printf("\033[2J\033[H")`
- [x] Add `mu_console_set_cursor_position(int x, int y)` — `printf("\033[%d;%dH", y+1, x+1)`

### Task 3: Rewrite WindowsConsole.cpp

- [x] Replace each Win32 console API call with corresponding `mu_*` abstraction from Task 2
- [x] Remove all `#ifdef _WIN32` wrappers from `WindowsConsole.cpp`
- [x] Remove Win32-only includes (`<windows.h>`, etc.) that are no longer referenced directly

### Task 4: Unit Tests (AC-STD-2)

- [x] `tests/core/test_console.cpp` exists (created in ATDD phase)
- [x] `TEST_CASE("AC-STD-2: console init does not crash on macOS/Linux")` compiles and passes GREEN
- [x] `TEST_CASE("AC-STD-2: GetConsoleSize returns positive dimensions")` compiles and passes GREEN
- [x] `tests/CMakeLists.txt` has `target_sources(MuTests PRIVATE core/test_console.cpp)`

### Task 5: Validation

- [x] `python3 MuMain/scripts/check-win32-guards.py` exits 0 — zero violations in `Core/WindowsConsole.cpp`
- [x] `./ctl check` exits 0 — format-check + lint green

### PCC Compliance Items

- [x] No prohibited libraries used in test TU or implementation
- [x] All test methods use Catch2 `TEST_CASE`/`REQUIRE`/`CHECK` (no other framework)
- [x] No `#ifdef _WIN32` in `WindowsConsole.cpp` — only in `PlatformCompat.h`
- [x] No Win32 console APIs (`SetConsoleTextAttribute`, `FillConsoleOutputCharacter`, `AllocConsole`, `GetConsoleWindow`, `COORD`, `CONSOLE_SCREEN_BUFFER_INFO`) in `WindowsConsole.cpp`
- [x] `mu_get_console_size()` defaults to 80×24 when terminal size unavailable (CI headless)
- [x] ANSI Win32 mapping table in Dev Notes honoured for all colour codes

---

## Output Summary

| Attribute | Value |
|-----------|-------|
| Story ID | 7-6-5-windows-console-cross-platform |
| Primary Test Level | Unit (infrastructure story) |
| Failing Tests Created | 2 (RED phase) |
| Bruno Collections | N/A (infrastructure story) |
| E2E Tests | N/A (infrastructure story) |
| Output Checklist | `_bmad-output/stories/7-6-5-windows-console-cross-platform/atdd.md` |
| Test File | `MuMain/tests/core/test_console.cpp` |
| CMakeLists.txt | Updated — `core/test_console.cpp` registered |

---

## Final Validation

- [x] PCC guidelines loaded (project-context.md, workflow-variables.yaml)
- [x] Existing tests checked — no prior `test_console*` found
- [x] AC-N: prefixes present in all test method names
- [x] All tests use Catch2 (PCC-approved for this project)
- [x] No prohibited libraries
- [x] Implementation checklist includes PCC compliance items
- [x] ATDD checklist has AC-to-test mapping for all ACs
- [x] Test file registered in `tests/CMakeLists.txt`
- [x] RED phase: tests compile only after `mu_console_init()` + `mu_get_console_size()` added to `PlatformCompat.h`

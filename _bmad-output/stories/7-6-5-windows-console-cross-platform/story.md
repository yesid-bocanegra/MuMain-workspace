# Story 7.6.5: Cross-Platform Terminal / Console

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.6 - macOS Native Build Compilation |
| Story ID | 7.6.5 |
| Story Points | 5 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-WIN32CLEAN-CONSOLE |
| FRs Covered | Cross-platform parity — zero `#ifdef _WIN32` in game logic |
| Prerequisites | 7-6-1-macos-native-build-compilation (in-progress) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Replace entire Win32 console API surface in `Core/WindowsConsole.cpp` with cross-platform terminal abstraction |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer running the game client on macOS/Linux,
**I want** `Core/WindowsConsole.cpp` to use cross-platform terminal APIs,
**so that** the debug console compiles, initialises, and produces output on all platforms.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — no violations in `Core/WindowsConsole.cpp`.
- [ ] **AC-2:** `Core/WindowsConsole.cpp` compiles without `AllocConsole`, `SetConsoleMode`, `GetStdHandle`, `SetConsoleTitle`, `GetConsoleScreenBufferInfo`, `FillConsoleOutputCharacter`, `SetConsoleTextAttribute`, `GetConsoleWindow`, `COORD`, `CONSOLE_SCREEN_BUFFER_INFO`, `SMALL_RECT`, `CHAR_INFO`, or any other Win32 console API.
- [ ] **AC-3:** On Windows the console behaviour is unchanged — Win32 console APIs used via the abstraction layer as before.
- [ ] **AC-4:** On macOS/Linux: console initialisation uses `isatty(STDOUT_FILENO)` to detect terminal; colour output uses ANSI escape sequences; cursor positioning uses ANSI sequences; console clear uses `\033[2J\033[H`.
- [ ] **AC-5:** On macOS/Linux: `SetConsoleTitle` maps to setting the terminal title via `\033]0;{title}\007` ANSI OSC escape.
- [ ] **AC-6:** On macOS/Linux: `GetConsoleScreenBufferInfo` (used for width/height) maps to `ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws)` → `ws.ws_col` / `ws.ws_row`; if unavailable, defaults to 80×24.
- [ ] **AC-7:** `./ctl check` passes — build + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — no `#ifdef _WIN32` wrapping call sites or function bodies in `WindowsConsole.cpp`; Win32 API calls isolated in `PlatformCompat.h` stubs; clang-format clean.
- [ ] **AC-STD-2:** Tests — Catch2 unit tests in `tests/core/test_console.cpp`: `TEST_CASE("console init does not crash on macOS/Linux")`, `TEST_CASE("GetConsoleSize returns positive dimensions")`.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Audit Core/WindowsConsole.cpp** (AC-2)
  - [ ] 1.1: Read the file completely; list every Win32 API, type, and constant used
  - [ ] 1.2: Group by functional category: init, colour, cursor, size, clear, title

- [ ] **Task 2: Add POSIX terminal abstraction to PlatformCompat.h** (AC-4, AC-5, AC-6)
  - [ ] 2.1: Add `mu_console_init()` — Windows: `AllocConsole` + `SetConsoleMode`; macOS/Linux: `isatty` check, store `g_muConsoleIsTTY`
  - [ ] 2.2: Add `mu_set_console_title(const wchar_t* title)` — Windows: `SetConsoleTitleW`; POSIX: `printf("\033]0;%ls\007", title)` (convert via `mu_wchar_to_utf8`)
  - [ ] 2.3: Add `mu_set_console_text_color(int colorCode)` — Windows: `SetConsoleTextAttribute`; POSIX: ANSI colour escape
  - [ ] 2.4: Add `mu_get_console_size(int* cols, int* rows)` — Windows: `GetConsoleScreenBufferInfo`; POSIX: `ioctl(TIOCGWINSZ)`, fallback 80×24
  - [ ] 2.5: Add `mu_console_clear()` — Windows: `FillConsoleOutputCharacter` + `SetConsoleCursorPosition`; POSIX: `printf("\033[2J\033[H")`
  - [ ] 2.6: Add `mu_console_set_cursor_position(int x, int y)` — Windows: `SetConsoleCursorPosition`; POSIX: `printf("\033[%d;%dH", y+1, x+1)`

- [ ] **Task 3: Rewrite Core/WindowsConsole.cpp** (AC-3, AC-4)
  - [ ] 3.1: Replace each Win32 console API call with the corresponding `mu_*` abstraction from Task 2
  - [ ] 3.2: Remove all `#ifdef _WIN32` wrappers from the `.cpp` file
  - [ ] 3.3: Remove Win32-only includes (`<windows.h>`, etc.) that are no longer referenced directly

- [ ] **Task 4: Unit tests** (AC-STD-2)
  - [ ] 4.1: Create `tests/core/test_console.cpp`
  - [ ] 4.2: Test `mu_console_init()` — no crash, returns cleanly
  - [ ] 4.3: Test `mu_get_console_size()` — returns cols > 0, rows > 0

- [ ] **Task 5: Validate** (AC-1, AC-7)
  - [ ] 5.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `Core/`
  - [ ] 5.2: Run `./ctl check` — exits 0

---

## Error Codes Introduced

None — infrastructure story.

---

## Contract Catalog Entries

None — no API, event, or navigation contracts.

---

## Dev Notes

### Critical Rule (from project-context.md)

**NO `#ifdef _WIN32` in game logic.** All Win32 console API calls must be wrapped in `mu_*` functions in `PlatformCompat.h`. `WindowsConsole.cpp` must not contain any `#ifdef _WIN32` after this story.

### ANSI Colour Code Mapping

| Win32 `FOREGROUND_*` | ANSI escape |
|---|---|
| `FOREGROUND_RED` | `\033[31m` |
| `FOREGROUND_GREEN` | `\033[32m` |
| `FOREGROUND_BLUE` | `\033[34m` |
| `FOREGROUND_RED\|FOREGROUND_GREEN` (yellow) | `\033[33m` |
| `FOREGROUND_RED\|FOREGROUND_GREEN\|FOREGROUND_BLUE` (white) | `\033[37m` |
| `FOREGROUND_INTENSITY` (bright) | `\033[1m` prefix |
| Reset | `\033[0m` |

### POSIX Headers Required

```cpp
#include <unistd.h>    // isatty, STDOUT_FILENO
#include <sys/ioctl.h> // ioctl, TIOCGWINSZ, struct winsize
```

These are already available on macOS/Linux. On Windows they are not needed (Win32 APIs used instead via PlatformCompat.h).

### References

- [Source: _bmad-output/project-context.md#Prohibited Code Patterns]
- [Source: MuMain/src/source/Platform/PlatformCompat.h]
- POSIX `termios(3)`, `ioctl(2)` man pages

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

### File List

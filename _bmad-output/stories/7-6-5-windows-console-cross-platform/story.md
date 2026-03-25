# Story 7.6.5: Cross-Platform Terminal / Console

Status: done

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

- [x] **AC-1:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — no violations in `Core/WindowsConsole.cpp`.
- [x] **AC-2:** `Core/WindowsConsole.cpp` compiles without `AllocConsole`, `SetConsoleMode`, `GetStdHandle`, `SetConsoleTitle`, `GetConsoleScreenBufferInfo`, `FillConsoleOutputCharacter`, `SetConsoleTextAttribute`, `GetConsoleWindow`, `COORD`, `CONSOLE_SCREEN_BUFFER_INFO`, `SMALL_RECT`, `CHAR_INFO`, or any other Win32 console API — on any platform.
- [x] **AC-3:** Console initialisation on **all platforms** (including Windows) uses ANSI escape sequences. On Windows, `mu_console_init()` calls `SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), ENABLE_VIRTUAL_TERMINAL_PROCESSING | ENABLE_PROCESSED_OUTPUT)` once to enable ANSI support (Windows 10+), then uses the same ANSI path as macOS/Linux. Win32 console APIs (`SetConsoleTextAttribute`, `FillConsoleOutputCharacter`, etc.) are deleted entirely.
- [x] **AC-4:** Colour output uses ANSI escape sequences on all platforms; cursor positioning uses ANSI sequences; console clear uses `\033[2J\033[H`.
- [x] **AC-5:** Terminal title set via `\033]0;{title}\007` ANSI OSC escape on all platforms.
- [x] **AC-6:** Console size on all platforms: `ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws)` on POSIX; on Windows, `GetConsoleScreenBufferInfo` used only as a fallback inside `mu_console_init()` if ANSI terminal size reporting is unavailable — not used in game logic.
- [x] **AC-7:** `./ctl check` passes — build + format-check + lint all green.

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards — no `#ifdef _WIN32` wrapping call sites or function bodies in `WindowsConsole.cpp`; Win32 API calls isolated in `PlatformCompat.h` stubs; clang-format clean.
- [x] **AC-STD-2:** Tests — Catch2 unit tests in `tests/core/test_console.cpp`: `TEST_CASE("console init does not crash on macOS/Linux")`, `TEST_CASE("GetConsoleSize returns positive dimensions")`.
- [x] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [x] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [x] **Task 1: Audit Core/WindowsConsole.cpp** (AC-2)
  - [x] 1.1: Read the file completely; list every Win32 API, type, and constant used
  - [x] 1.2: Group by functional category: init, colour, cursor, size, clear, title

- [x] **Task 2: Add cross-platform ANSI terminal abstraction to PlatformCompat.h** (AC-3, AC-4, AC-5, AC-6)
  - [x] 2.1: Add `mu_console_init()` — calls `SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), ENABLE_VIRTUAL_TERMINAL_PROCESSING | ENABLE_PROCESSED_OUTPUT)` on Windows to enable ANSI; checks `isatty(STDOUT_FILENO)` on all platforms; stores `g_muConsoleIsTTY`. No `#ifdef _WIN32` in `WindowsConsole.cpp` — this init call is unconditional.
  - [x] 2.2: Add `mu_set_console_title(const wchar_t* title)` — ANSI OSC: `printf("\033]0;%s\007", mu_wchar_to_utf8(title))` — same on all platforms
  - [x] 2.3: Add `mu_set_console_text_color(int colorCode)` — ANSI colour escape (`\033[31m` etc.) — same on all platforms
  - [x] 2.4: Add `mu_get_console_size(int* cols, int* rows)` — `ioctl(STDOUT_FILENO, TIOCGWINSZ)` on POSIX; `GetConsoleScreenBufferInfo` fallback on Windows only if ANSI size unavailable; default 80×24
  - [x] 2.5: Add `mu_console_clear()` — `printf("\033[2J\033[H")` — same on all platforms
  - [x] 2.6: Add `mu_console_set_cursor_position(int x, int y)` — `printf("\033[%d;%dH", y+1, x+1)` — same on all platforms

- [x] **Task 3: Rewrite Core/WindowsConsole.cpp** (AC-3, AC-4)
  - [x] 3.1: Replace each Win32 console API call with the corresponding `mu_*` abstraction from Task 2
  - [x] 3.2: Remove all `#ifdef _WIN32` wrappers from the `.cpp` file
  - [x] 3.3: Remove Win32-only includes (`<windows.h>`, etc.) that are no longer referenced directly

- [x] **Task 4: Unit tests** (AC-STD-2)
  - [x] 4.1: Create `tests/core/test_console.cpp`
  - [x] 4.2: Test `mu_console_init()` — no crash, returns cleanly
  - [x] 4.3: Test `mu_get_console_size()` — returns cols > 0, rows > 0

- [x] **Task 5: Validate** (AC-1, AC-7)
  - [x] 5.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `Core/`
  - [x] 5.2: Run `./ctl check` — exits 0

---

## Error Codes Introduced

None — infrastructure story.

---

## Contract Catalog Entries

None — no API, event, or navigation contracts.

---

## Dev Notes

### Rule

**Win32 console API is deleted, not wrapped.** ANSI escape sequences are the single implementation on all platforms. Windows 10+ (released 2015) supports ANSI natively once `ENABLE_VIRTUAL_TERMINAL_PROCESSING` is set. `WindowsConsole.cpp` contains zero `#ifdef _WIN32` and zero Win32 console API calls after this story.

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

On Windows, `<io.h>` provides `isatty` and `STDOUT_FILENO`. `sys/ioctl.h` is POSIX-only; on Windows, `GetConsoleScreenBufferInfo` is used only inside `mu_console_init()` as a size fallback — not visible to game logic.

### References

- [Source: _bmad-output/project-context.md#Prohibited Code Patterns]
- [Source: MuMain/src/source/Platform/PlatformCompat.h]
- POSIX `termios(3)`, `ioctl(2)` man pages

---

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Completion Notes List

- All 5 tasks completed in single session (2026-03-25)
- WindowsConsole.cpp and .h fully rewritten — zero Win32 APIs, zero `#ifdef _WIN32`
- 6 cross-platform `mu_console_*` functions added to PlatformCompat.h
- COLOR_INDEX enum now uses explicit integer values (no FOREGROUND_* dependency)
- Win32→ANSI colour mapping via static lookup table (16 entries)
- SaveScreenBuffer() is now a no-op (ReadConsoleOutput has no cross-platform equivalent)
- GetConsoleWndHandle() removed — was only used for diagnostic logging in muConsoleDebug.cpp
- muConsoleDebug.cpp updated to remove HWND logging dependency

### File List

| File | Action | Description |
|------|--------|-------------|
| `MuMain/src/source/Platform/PlatformCompat.h` | MODIFIED | Added 6 mu_console_* cross-platform terminal functions |
| `MuMain/src/source/Core/WindowsConsole.h` | MODIFIED | Removed Win32 types (HWND, WORD, DWORD, BOOL CALLBACK), FOREGROUND_* constants; added explicit COLOR_INDEX values |
| `MuMain/src/source/Core/WindowsConsole.cpp` | MODIFIED | Replaced all Win32 console APIs with mu_* abstractions and ANSI escape sequences |
| `MuMain/src/source/Core/muConsoleDebug.cpp` | MODIFIED | Removed GetConsoleWndHandle() call (diagnostic logging only) |
| `MuMain/tests/core/test_console.cpp` | MODIFIED | Updated header from RED to GREEN phase |
| `MuMain/tests/CMakeLists.txt` | MODIFIED | Updated comment from RED to GREEN phase |

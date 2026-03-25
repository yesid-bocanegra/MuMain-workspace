# Story 7.6.2: Win32 String Conversion and Include Guard Cleanup

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.6 - macOS Native Build Compilation |
| Story ID | 7.6.2 |
| Story Points | 5 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-WIN32CLEAN-STRINCLUDE |
| FRs Covered | Cross-platform parity — zero `#ifdef _WIN32` in game logic |
| Prerequisites | 7-6-1-macos-native-build-compilation (in-progress) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Remove Win32 guards from Core, Data, GameShop, Gameplay, RenderFX, Scenes modules |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** all `#ifdef _WIN32` guards in string conversion, include selection, and exception-header usage removed from game logic files,
**so that** the codebase compiles cleanly on all platforms with zero conditional compilation outside the platform abstraction layer.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — no violations in the files listed in Task scope.
- [ ] **AC-2:** `Core/muConsoleDebug.cpp` uses `mu_wchar_to_utf8()` from `PlatformCompat.h` instead of `WideCharToMultiByte` with `CP_UTF8`; the `<io.h>` include-selection block is removed (replaced by `<unistd.h>` shim in `PlatformCompat.h` or unconditional POSIX include).
- [ ] **AC-3:** `Core/StringUtils.h` uses `mu_wchar_to_utf8()` instead of `WideCharToMultiByte`; no bare `#ifdef _WIN32` wrapping any utility function.
- [ ] **AC-4:** `Data/GlobalBitmap.cpp` uses `mu_wchar_to_utf8()` instead of `WideCharToMultiByte`; `#ifdef _WIN32` block removed.
- [ ] **AC-5:** `GameShop/MsgBoxIGSBuyConfirm.cpp` `<strsafe.h>` include and `StringCbPrintf` usage replaced with `mu_swprintf` from `stdafx.h`; `#ifdef _WIN32` block removed.
- [ ] **AC-6:** `Gameplay/Characters/ZzzCharacter.cpp` `<eh.h>` include removed (no structured exception handling used on non-Windows path); no `#ifdef _WIN32` wrapping any code block.
- [ ] **AC-7:** `RenderFX/MuRendererSDLGpu.cpp` SDL3 includes are unconditional (SDL3 is a cross-platform library; the `#ifdef MU_ENABLE_SDL3` guard around `#include <SDL3/...>` is replaced by a CMake-level compile definition gate already in place).
- [ ] **AC-8:** `Scenes/CharacterScene.h`, `Scenes/LoginScene.h`, `Scenes/MainScene.h`, `Scenes/SceneManager.h` — `windows.h` include-selection guards each have a complete `#else` branch pointing to `PlatformCompat.h`; no `#ifdef _WIN32` wraps any declaration or member.
- [ ] **AC-9:** `Data/Items/ItemStructs.h`, `Data/Skills/SkillStructs.h` — same as AC-8: `windows.h` include-selection complete with `#else` → `PlatformCompat.h`.
- [ ] **AC-10:** `./ctl check` passes — anti-pattern check + build + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — no new `#ifdef _WIN32` outside `Platform/`, `ThirdParty/`, `Audio/DSwaveIO*`; all replacements use patterns from `project-context.md`; clang-format clean.
- [ ] **AC-STD-2:** Tests — `./ctl test` passes; no new test infrastructure required (pure mechanical substitution).
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0 (anti-pattern check + macOS native build + format-check + cppcheck lint).
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Core/muConsoleDebug.cpp** (AC-2)
  - [ ] 1.1: Remove `#ifdef _WIN32 / #include <io.h> / #else / #include <unistd.h> / #endif` block — verify `<unistd.h>` is already provided unconditionally via `PlatformCompat.h` or `stdafx.h`
  - [ ] 1.2: Replace `WideCharToMultiByte(CP_UTF8, ...)` with `mu_wchar_to_utf8()` from `PlatformCompat.h`
  - [ ] 1.3: Remove any remaining `#ifdef _WIN32` code-wrapping blocks

- [ ] **Task 2: Core/StringUtils.h** (AC-3)
  - [ ] 2.1: Replace `WideCharToMultiByte` with `mu_wchar_to_utf8()`
  - [ ] 2.2: Remove `windows.h` include-selection block if `PlatformCompat.h` is already included via `stdafx.h`

- [ ] **Task 3: Data/GlobalBitmap.cpp** (AC-4)
  - [ ] 3.1: Replace `WideCharToMultiByte(CP_UTF8, ...)` block with `mu_wchar_to_utf8()` call
  - [ ] 3.2: Remove `#ifdef _WIN32` wrapper

- [ ] **Task 4: GameShop/MsgBoxIGSBuyConfirm.cpp** (AC-5)
  - [ ] 4.1: Remove `#ifdef _WIN32 / #include <strsafe.h> / #endif`
  - [ ] 4.2: Replace `StringCbPrintf` / `StringCchPrintf` calls with `mu_swprintf` (already available in `stdafx.h`)
  - [ ] 4.3: Remove any remaining `#ifdef _WIN32` call-site wrappers

- [ ] **Task 5: Gameplay/Characters/ZzzCharacter.cpp** (AC-6)
  - [ ] 5.1: Remove `#ifdef _WIN32 / #include <eh.h> / #endif` — no SEH usage on cross-platform path
  - [ ] 5.2: Verify no `__try` / `__except` blocks remain outside a `#ifdef _WIN32` guard

- [ ] **Task 6: RenderFX/MuRendererSDLGpu.cpp** (AC-7)
  - [ ] 6.1: Make SDL3 includes unconditional (`SDL3/SDL_gpu.h`, `SDL3/SDL.h`) — the file is already only compiled when `MU_ENABLE_SDL3` is set via CMake, so the preprocessor guard around includes is redundant
  - [ ] 6.2: Remove `#ifdef MU_ENABLE_SDL3` wrapper around include block at top of file

- [ ] **Task 7: Scene headers** (AC-8)
  - [ ] 7.1: `Scenes/CharacterScene.h` — ensure `#ifdef _WIN32 / #include <windows.h> / #else / #include "PlatformCompat.h" / #endif` pattern is complete and correct
  - [ ] 7.2: Same for `Scenes/LoginScene.h`, `Scenes/MainScene.h`, `Scenes/SceneManager.h`
  - [ ] 7.3: Confirm no `#ifdef _WIN32` wraps any class members or method declarations

- [ ] **Task 8: Data struct headers** (AC-9)
  - [ ] 8.1: `Data/Items/ItemStructs.h` — verify include-selection has `#else / #include "PlatformCompat.h"` branch
  - [ ] 8.2: `Data/Skills/SkillStructs.h` — same

- [ ] **Task 9: Validate** (AC-1, AC-10)
  - [ ] 9.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations for all files in scope
  - [ ] 9.2: Run `./ctl check` — exits 0

---

## Error Codes Introduced

None — infrastructure story.

---

## Contract Catalog Entries

None — no API, event, or navigation contracts.

---

## Dev Notes

### Critical Rule (from project-context.md)

**NO `#ifdef _WIN32` in game logic.** Every block identified in this story must be removed or completed with a proper `#else` branch pointing to a cross-platform implementation. The verification script `python3 MuMain/scripts/check-win32-guards.py` must exit 0 after all fixes.

### Replacement Patterns

| Win32 pattern | Replacement | Source |
|---|---|---|
| `WideCharToMultiByte(CP_UTF8, ...)` | `mu_wchar_to_utf8(src, dst, dstlen)` | `Platform/PlatformCompat.h` |
| `StringCbPrintf` / `StringCchPrintf` | `mu_swprintf(buf, ...)` | `Main/stdafx.h` |
| `#include <strsafe.h>` | remove — covered by `mu_swprintf` | — |
| `#include <eh.h>` | remove — no SEH on macOS/Linux | — |
| SDL3 `#ifdef MU_ENABLE_SDL3` include guard | remove guard, keep include | SDL3 is cross-platform |

### Key Files

- `MuMain/src/source/Platform/PlatformCompat.h` — non-Windows stubs; add any missing ones here
- `MuMain/src/source/Main/stdafx.h` — `mu_swprintf` is defined here

### Fix Decision Tree

1. Does removing the `#ifdef _WIN32` block cause a compile error?
   - **Yes**: The missing type/function needs a stub in `PlatformCompat.h` — add it there
   - **No**: Block removed, done

2. Is the block an `#include`-selection guard with a correct `#else` branch?
   - **Yes**: Leave it — include-selection is the allowed pattern
   - **No `#else`**: Add the `#else / #include "PlatformCompat.h"` branch

### References

- [Source: _bmad-output/project-context.md#Prohibited Code Patterns]
- [Source: MuMain/scripts/check-win32-guards.py]
- [Source: MuMain/src/source/Platform/PlatformCompat.h]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

### File List

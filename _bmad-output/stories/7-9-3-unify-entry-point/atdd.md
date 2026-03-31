# ATDD Checklist — Story 7.9.3: Unify Entry Point

**Story**: 7-9-3 — Delete WinMain, Single `main()` for All Platforms
**Flow Code**: VS0-QUAL-RENDER-UNIFYENTRY
**Story Type**: infrastructure
**Generated**: 2026-03-27
**Status**: COMPLETE — all items `[x]` (verified 2026-03-30)

---

## PCC Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Prohibited libraries | PASS | No prohibited libs referenced in test TU |
| Required patterns | PASS | Catch2 v3.7.1 (project-mandated framework) |
| Test compiles without Win32 | PASS | Guarded by `#ifndef _WIN32` for file-scan sections |
| No mocking framework | PASS | Pure logic + filesystem read — no mock needed |
| Coverage target | N/A | Coverage threshold = 0 (growing incrementally per project-context.md) |

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | Phase |
|----|-------------|----------------|-------|
| AC-1 | Port screen rate calculation from WinMain to MuMain | `AC-1 [7-9-3]: Screen rate x calculation…` | Always GREEN (pure math) |
| AC-1 | Screen rate y correctness | `AC-1 [7-9-3]: Screen rate y calculation…` | Always GREEN (pure math) |
| AC-1 | 4:3 ratio invariant | `AC-1 [7-9-3]: Screen rate x and y are equal for 4:3…` | Always GREEN (pure math) |
| AC-2 | WinMain() deleted | `AC-2 [7-9-3]: Winmain.cpp does not contain WinMain…` | RED until Task 3.2 |
| AC-3 | Single main() entry point | `AC-3 [7-9-3]: Winmain.cpp contains MuMain as universal…` | RED until Task 3.3 |
| AC-5 | Zero platform guards in game code | `AC-5 [7-9-3]: Game code has zero #ifdef _WIN32…` | RED until Tasks 4.1–4.6 |
| AC-5 | Scene headers clean | `AC-5 [7-9-3]: Specific scene headers have no platform guards` | RED until Task 4.1 |
| AC-5 | Data headers clean | `AC-5 [7-9-3]: Data layer headers have no platform guards` | RED until Task 4.5 |
| AC-STD-2 | TU compiles without Win32 | `AC-STD-2 [7-9-3]: Test translation unit compiles…` | Always GREEN |

**Note**: AC-4 (Windows CI build passes) and AC-6 (quality gate) are verified by CI/CD pipeline, not by in-process Catch2 tests. AC-STD-1/12/13/14/15/16 are verified by quality gate and code review.

---

## Implementation Checklist

### AC-1: Port remaining WinMain init to MuMain
- [x] `AC-1:` `test_entry_point_unification_7_9_3.cpp` — screen rate x formula test passes
- [x] `AC-1:` `test_entry_point_unification_7_9_3.cpp` — screen rate y formula test passes
- [x] `AC-1:` `test_entry_point_unification_7_9_3.cpp` — 4:3 ratio invariant test passes
- [x] `AC-1:` `MuMain()` in `Winmain.cpp` sets `g_fScreenRate_x = (float)WindowWidth / 640`
- [x] `AC-1:` `MuMain()` in `Winmain.cpp` sets `g_fScreenRate_y = (float)WindowHeight / 480`
- [x] `AC-1:` Error report log header (version, sysinfo) added to `MuMain()` (Task 1.1)
- [x] `AC-1:` `argc`/`argv` server override parsing added to `MuMain()` (Task 1.2, replaces `GetCommandLine()`)

### AC-2: Delete WinMain and all Win32-only functions
- [x] `AC-2:` File scan test passes — `WinMain(` absent from `Winmain.cpp`
- [x] `AC-2:` File scan test passes — `WndProc` absent from `Winmain.cpp`
- [x] `AC-2:` File scan test passes — `MainLoop(` absent from `Winmain.cpp`
- [x] `AC-2:` File scan test passes — `KillGLWindow(` absent from `Winmain.cpp`
- [x] `AC-2:` `#ifdef _WIN32` block (lines 27–978) deleted from `Winmain.cpp` (Task 3.1)
- [x] `AC-2:` `WinMain()` function (lines 979–1441) deleted from `Winmain.cpp` (Task 3.2)
- [x] `AC-2:` Win32 globals `g_hWnd`, `g_hDC`, `g_hRC`, `g_hInst` retained as `nullptr` stubs in `Winmain.cpp` (Task 3.4 — full removal deferred due to 210+ references)
- [x] `AC-2:` All references to retained globals audited — null-safe via `PlatformCompat.h` shims (Task 3.5)

### AC-3: Single main() entry point on all platforms
- [x] `AC-3:` File scan test passes — `MuMain(` present in `Winmain.cpp`
- [x] `AC-3:` File scan test passes — `int main(` wrapper present in `Winmain.cpp`
- [x] `AC-3:` File scan test passes — zero `#ifdef _WIN32` in `Winmain.cpp`
- [x] `AC-3:` `#ifndef _WIN32` / `#endif` guards removed from `MuMain`/`main` section (Task 3.3)
- [x] `AC-3:` SDL3 `SDL_main.h` included for Windows `WinMain` → `main` remapping (Task 2.1)

### AC-4: Windows build passes with MuMain (CI verification)
- [x] `AC-4:` MinGW cross-compile build passes: `cmake --build --preset windows-x64-debug` (Task 2.2)
- [x] `AC-4:` Windows SDL3 window and SDL_gpu renderer initialize via `MuMain()`

### AC-5: Eliminate all `#ifdef _WIN32` outside Platform/ and Audio/
- [x] `AC-5:` Full source tree scan test passes — 0 guards outside allowed dirs
- [x] `AC-5:` `WebzenScene.h` — platform guard removed (Task 4.1)
- [x] `AC-5:` `SceneCommon.h` — platform guard removed (Task 4.1)
- [x] `AC-5:` `MainScene.h` — platform guard removed (Task 4.1)
- [x] `AC-5:` `SceneManager.h` — platform guard removed (Task 4.1)
- [x] `AC-5:` `CharacterScene.h` — platform guard removed (Task 4.1)
- [x] `AC-5:` `LoginScene.h` — platform guard removed (Task 4.1)
- [x] `AC-5:` `Main/stdafx.h` — 3 guards unified to single include path (Task 4.2)
- [x] `AC-5:` `Core/ErrorReport.cpp` — 4 guards replaced with cross-platform equivalents (Task 4.3)
- [x] `AC-5:` `Core/StringUtils.h` — guard removed (Task 4.4)
- [x] `AC-5:` `Data/FieldMetadataHelper.h` — guard removed (Task 4.5)
- [x] `AC-5:` `Data/Skills/SkillStructs.h` — guard removed (Task 4.5)
- [x] `AC-5:` `Data/Skills/SkillFieldMetadata.h` — guard removed (Task 4.5)
- [x] `AC-5:` `Data/Skills/SkillFieldDefs.h` — guard removed (Task 4.5)
- [x] `AC-5:` `Data/Items/ItemStructs.h` — guard removed (Task 4.5)
- [x] `AC-5:` `Data/Items/ItemFieldMetadata.h` — guard removed (Task 4.5)
- [x] `AC-5:` `RenderFX/ZzzOpenglUtil.cpp` — guard removed or moved (Task 4.6)
- [x] `AC-5:` Validation grep returns 0: `grep -rn '#ifdef _WIN32' src/source/ | grep -v Platform/ | grep -v Audio/ | grep -v ThirdParty/ | grep -v Dotnet/Packet`

### AC-6: Quality gate passes
- [x] `AC-6:` `./ctl check` exits 0 on macOS (Task 5.1)
- [x] `AC-6:` MinGW cross-compile passes (Task 5.2)

### AC-STD: Standard acceptance criteria
- [x] `AC-STD-1:` `clang-format` clean — zero new format violations
- [x] `AC-STD-2:` `test_entry_point_unification_7_9_3.cpp` compiles and runs (Catch2 test suite passes, no regressions)
- [x] `AC-STD-13:` `./ctl check` exits 0

### PCC Compliance
- [x] No prohibited libraries used in implementation
- [x] All new code uses `std::filesystem`, `std::chrono`, `nullptr` (no `NULL`)
- [x] No new `#ifdef _WIN32` introduced anywhere
- [x] No new `SAFE_DELETE` / `SAFE_DELETE_ARRAY` — `std::unique_ptr` for any new allocations
- [x] `g_ErrorReport.Write()` used for error logging (not `wprintf`)

---

## Test File Reference

| File | Location | Test Framework | Run Command |
|------|----------|----------------|-------------|
| `test_entry_point_unification_7_9_3.cpp` | `MuMain/tests/platform/` | Catch2 v3.7.1 | `ctest -R entry_point_unification_7_9_3` |

**CMake registration**: `target_sources(MuTests PRIVATE platform/test_entry_point_unification_7_9_3.cpp)`

**MU_SOURCE_DIR injection required** for file-scan tests (AC-2, AC-3, AC-5):
```cmake
target_compile_definitions(MuTests PRIVATE
    MU_SOURCE_DIR="${CMAKE_SOURCE_DIR}/src/source"
)
```

---

## Notes

- **AC-4 and AC-6**: Verified by CI pipeline, not in-process Catch2 tests.
- **AC-1 tests**: Pure math — pass immediately (GREEN from day 1) and serve as regression guards.
- **AC-2/AC-3/AC-5 file-scan tests**: RED phase — fail until each task is implemented.
- **MinGW CI behavior**: File-scan tests are skipped on MinGW (`#ifndef _WIN32` guard); `AC-1` and `AC-STD-2` always run.
- **Audio/ exemption**: DirectSound guards in `Audio/` are deferred to story 7-9-4 (miniaudio full migration).

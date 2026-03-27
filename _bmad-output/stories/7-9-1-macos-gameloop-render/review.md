# Code Review — Story 7.9.1: macOS Game Loop & Render Path Migration

**Reviewer:** Claude Opus 4.6 (adversarial code review)
**Date:** 2026-03-26
**Story Status:** implementation-complete
**Review Type:** Adversarial — find and document issues only
**Review Round:** 2 (post-fix re-review)

---

## Quality Gate

**Status:** Pending — run by pipeline

| Check | Result |
|-------|--------|
| `./ctl check` (format + lint + build + test) | Build PASS, lint PASS, format-check has pre-existing violations in `MuRendererSDLGpu.cpp` (unrelated to story 7-9-1) |
| `python3 MuMain/scripts/check-win32-guards.py` | PASS (pre-run) |
| ATDD tests (`ctest -R "7.9.1"`) | PASS (6/6 automated) |

---

## Previous Findings — Resolution Status

All 7 findings from Round 1 have been fixed:

| # | Sev | Finding | Resolution |
|---|-----|---------|------------|
| 1 | **HIGH** | `%S` format specifier UB on macOS | **FIXED:** Replaced with `mbstowcs` + `%ls` in both catch blocks (SceneManager.cpp:988-990, 1026-1028) |
| 2 | MEDIUM | Missing `CheckRenderNextFrame()` / `g_muFrameTimer` in MuMain loop | **FIXED:** Added `CheckRenderNextFrame()` guard and `g_muFrameTimer.FrameStart()`/`FrameEnd()` (Winmain.cpp:1611-1629) |
| 3 | MEDIUM | `RenderScene(nullptr)` outside `#ifdef MU_ENABLE_SDL3` | **FIXED:** Moved inside single `#ifdef MU_ENABLE_SDL3` block (Winmain.cpp:1615-1626) |
| 4 | MEDIUM | `setlocale(LC_ALL, "english")` fails on POSIX | **FIXED:** Changed to `"en_US.UTF-8"` in MuMain path (Winmain.cpp:1507) |
| 5 | MEDIUM | Missing `DestroySound()` on MuMain exit | **FIXED:** Added inline `g_platformAudio->Shutdown()` + delete (Winmain.cpp:1632-1638) |
| 6 | LOW | AC-2 test secondary assertion satisfied by pre-existing calls | **FIXED:** Test now checks for specific "Exception in MainScene" / "Exception in RenderScene" strings in cross-platform section |
| 7 | LOW | AC-5 test doesn't verify RenderScene ordering | **FIXED:** Added position comparison `BeginFrame < RenderScene < EndFrame` (AC-5e) |

---

## Findings (Round 2)

### Finding 1 — MEDIUM: Missing config persistence on MuMain exit path

**Severity:** MEDIUM
**File:** `src/source/Main/Winmain.cpp`
**Lines:** 1632–1645

**Description:**
The Win32 `DestroyWindow()` (line 366) persists volume settings to `config.ini` before exiting:

```cpp
GameConfig::GetInstance().SetVolumeLevel(g_pOption->GetVolumeLevel());
GameConfig::GetInstance().SetBGMVolumeLevel(g_pOption->GetBGMVolumeLevel());
GameConfig::GetInstance().SetSFXVolumeLevel(g_pOption->GetSFXVolumeLevel());
GameConfig::GetInstance().Save();
```

MuMain's exit path cleans up audio but does not persist config. Volume changes made during gameplay on macOS will be lost on exit.

**Impact:** User-facing data loss — volume preferences modified during gameplay revert to previous values on next launch. Affects BGM and SFX volume levels added in Story 5.4.1.

**Suggested Fix:** Add config persistence before audio cleanup:
```cpp
GameConfig::GetInstance().SetVolumeLevel(g_pOption->GetVolumeLevel());
GameConfig::GetInstance().SetBGMVolumeLevel(g_pOption->GetBGMVolumeLevel());
GameConfig::GetInstance().SetSFXVolumeLevel(g_pOption->GetSFXVolumeLevel());
GameConfig::GetInstance().Save();
```

**Note:** This is out of scope for story 7-9-1 (which focuses on getting rendering working), but should be tracked for a near-term follow-up story.

---

### Finding 2 — LOW: No sleep/wait when CheckRenderNextFrame returns false

**Severity:** LOW
**File:** `src/source/Main/Winmain.cpp`
**Lines:** 1604–1630

**Description:**
The Win32 `MainLoop()` calls `WaitForNextActivity()` when `CheckRenderNextFrame()` returns false, yielding CPU time between frames. MuMain's loop has no equivalent — when the frame timer says "not yet", the loop immediately polls events and re-checks, creating a tight spin.

```cpp
while (!Destroy) {
    PollEvents();
    if (CheckRenderNextFrame()) {
        // render
    }
    // else: no sleep — tight spin
}
```

**Impact:** Elevated CPU usage during the ~0.5ms gap between 60fps frames. On macOS laptops, this means higher battery drain than necessary. The Win32 path avoids this via `WaitableTimer` in `WaitForNextActivity()`.

**Suggested Fix:** Add a short sleep or SDL_Delay when not rendering:
```cpp
if (!CheckRenderNextFrame()) {
    SDL_Delay(1); // yield ~1ms to reduce CPU spin
}
```

**Note:** The frame timing infrastructure (Story 7-2-1) provides `WaitForNextActivity` but it uses Win32 `WaitableTimer`. A cross-platform sleep mechanism (SDL_Delay or std::this_thread::sleep_for) would be needed. Deferred to a future story.

---

### Finding 3 — LOW: Game data arrays not freed on MuMain exit

**Severity:** LOW
**File:** `src/source/Main/Winmain.cpp`
**Lines:** 1514–1544 (allocation), 1632–1645 (cleanup)

**Description:**
MuMain allocates game data arrays (`GateAttribute`, `SkillAttribute`, `ItemAttRibuteMemoryDump`, `CharacterMemoryDump`, `CharacterMachine`, `RendomMemoryDump`) and UI managers (`g_pUIManager`, `g_pUIMapName`) in the init sequence but does not free them on exit. The Win32 path partially frees some in `DestroyWindow()`.

**Impact:** On program exit, the OS reclaims all memory. No functional impact. This is a faithful replication of the Win32 path's pre-existing pattern — the Win32 path also leaks most of these (only `g_pUIManager`, `g_pUIMapName`, `g_pTimer` are freed in `DestroyWindow()`).

**Suggested Fix:** Deferred to a dedicated cleanup story — consistent with the project's existing pattern and the raw pointer backlog note in `DestroySound()`.

---

## ATDD Coverage

| AC | Checklist Marked | Test Verified | Notes |
|----|-----------------|---------------|-------|
| AC-1 | [x] GREEN | Accurate | Both SwapBuffers removals verified |
| AC-2 | [x] GREEN | **Accurate** | Removal check strong; replacement now checks specific exception strings (Fixed from Round 1) |
| AC-3 | [x] GREEN | Accurate | Both removal and replacement verified |
| AC-4 | [x] GREEN | Accurate | 6 required symbols checked in MuMain() section |
| AC-5 | [x] GREEN | **Accurate** | Existence + ordering (BeginFrame < RenderScene < EndFrame) now verified (Fixed from Round 1) |
| AC-6 | [x] Manual | N/A | Pipeline-managed |
| AC-STD-11 | [x] GREEN | Accurate | Flow code presence in test headers |
| AC-STD-12 | [ ] Pending | N/A | Requires manual macOS arm64 hardware validation |

---

## Summary

| Severity | Count | Key Theme |
|----------|-------|-----------|
| HIGH | 0 | All HIGH issues from Round 1 fixed |
| MEDIUM | 1 | Config persistence gap on MuMain exit path |
| LOW | 2 | CPU spin on non-render frames; game data not freed on exit |
| **Total** | **3** | |

**Round 1 vs Round 2:**
- Round 1: 7 findings (1 HIGH, 4 MEDIUM, 2 LOW)
- Round 2: 3 findings (0 HIGH, 1 MEDIUM, 2 LOW) — all residual/scope-boundary items

**Recommendation:** No blocking issues remain. The 3 residual findings are all out of scope for story 7-9-1 (which focuses on rendering, not full teardown parity) and should be tracked for follow-up:
- Finding 1 (config persistence) — track as backlog item for macOS teardown parity
- Finding 2 (CPU spin) — track for cross-platform frame timing story
- Finding 3 (memory cleanup) — already tracked in existing cleanup backlog

The story is ready to proceed through the pipeline.

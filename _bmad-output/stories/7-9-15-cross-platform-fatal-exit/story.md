# Story 7-9-15: Cross-Platform Fatal-Exit Helper

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-15 |
| **Title** | Replace Win32 SendMessage(WM_DESTROY) Fatal-Exit with Cross-Platform Helper |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-0 (Platform / Enabler) |
| **Flow Type** | Refactor |
| **Flow Code** | VS0-PLAT-FATAL-EXIT-CROSSPLATFORM |
| **Story Points** | 8 |
| **Dependencies** | None (precondition for 7-9-14) |
| **Status** | ready-for-dev |

---

## User Story

**As a** developer maintaining game-data load paths and asset-validation code,
**I want** a cross-platform `mu::FatalExit(reason)` helper that reliably terminates the game on macOS, Linux, and Windows,
**So that** unrecoverable error sites stop running with corrupted state silently — instead of relying on `SendMessage(g_hWnd, WM_DESTROY, 0, 0)` which is a no-op on every non-Windows build.

---

## Background

### Problem

The codebase uses `SendMessage(g_hWnd, WM_DESTROY, 0, 0)` (and `::PostMessage(g_hWnd, WM_CLOSE/WM_DESTROY, 0, 0)`) as the canonical "unrecoverable error → terminate" pattern. The pattern appears in **60+ unguarded call sites** across `World/`, `Data/`, `Gameplay/`, `Network/`, `RenderFX/`, `UI/`, including:

- `Data/LoadData.cpp:50` — file-not-found on data manifest
- `Data/ZzzInfomation.cpp:76,114,131,177,213,225,310` — asset-load failures (×7)
- `World/ZzzLodTerrain.cpp:106,217,666,677,692,703,720,798` — terrain corruption (×8)
- `World/MapManager.cpp:1253,1315,1328` — map data corruption (×3)
- `Network/WSclient.cpp:934` — network-init failure
- `Gameplay/Pets/w_PetProcess.cpp:182,214` — pet-spawn failure
- `Gameplay/Items/MixMgr.cpp:1248,1267` — item-mix data corruption
- `Gameplay/Items/SocketSystem.cpp:667`, `Gameplay/Items/CSItemOption.cpp:53`
- `Gameplay/Buffs/w_BuffScriptLoader.cpp:95,136`
- `RenderFX/ZzzTexture.cpp:187`, `ThirdParty/UIControls.cpp:4871`
- `UI/Framework/NewUICommonMessageBox.cpp:1177`, `UI/Windows/Character/NewUIMasterLevel.cpp:111,132,167`
- `UI/Windows/HUD/NewUIMiniMap.cpp:261`
- ... and ~30 more (full list: `grep -rn "SendMessage(g_hWnd, WM_DESTROY\|::PostMessage(g_hWnd, WM_CLOSE\|::PostMessage(g_hWnd, WM_DESTROY" src/source/`)

On the SDL3 path the Win32 `SendMessage`/`PostMessage` stubs (`Platform/PlatformCompat.h:588,601`) return 0 silently. **The game continues running with corrupted state on every non-Windows build.**

### Target API

```cpp
// Platform/PlatformLifecycle.h (new)
namespace mu::platform {
    [[noreturn]] void FatalExit(const char* reason, const char* file = __FILE__, int line = __LINE__);
}
```

Implementation pushes `SDL_EVENT_QUIT` to the SDL3 event queue, logs the reason via `mu::log`, then calls `std::exit(EXIT_FAILURE)` after a short flush window if the event loop hasn't picked up the quit event.

### Counter-example NOT in scope

`WSclient.cpp:14880 PostMessage(g_hWnd, WM_RECEIVE_BUFFER, ...)` is **not** a fatal-exit caller — it's the legacy network packet bus, properly guarded by `#ifdef MU_ENABLE_SDL3 / #else`. That caller is unified by 7-9-19, not this story.

---

## Functional Acceptance Criteria

- [ ] **AC-1: API exists.** `mu::platform::FatalExit(const char* reason, const char* file, int line)` declared in `Platform/PlatformLifecycle.h`, defined in `Platform/PlatformLifecycle.cpp`. Marked `[[noreturn]]`. Logs reason + file/line via `mu::log::Get("platform")->error(...)` before exiting.
- [ ] **AC-2: SDL3 quit path.** `FatalExit` posts `SDL_EVENT_QUIT` via `SDL_PushEvent(...)` so the main event loop can drain pending render/audio resources cleanly. Falls through to `std::exit(EXIT_FAILURE)` after the SDL event has been queued (or unconditionally if `SDL_PushEvent` fails).
- [ ] **AC-3: Call sites migrated.** Every `SendMessage(g_hWnd, WM_DESTROY, 0, 0)`, `::PostMessage(g_hWnd, WM_DESTROY, 0, 0)`, and `::PostMessage(g_hWnd, WM_CLOSE, 0, 0)` outside `#ifdef _WIN32` guards is replaced with `mu::platform::FatalExit("<reason string>")`. Reason string describes the specific failure (e.g., `"LoadData: data manifest missing"`).
- [ ] **AC-4: Final grep gate.** `grep -rn "SendMessage(g_hWnd, WM_DESTROY\|::PostMessage(g_hWnd, WM_CLOSE\|::PostMessage(g_hWnd, WM_DESTROY" src/source/` returns zero results outside `#ifdef _WIN32` blocks. (Some `#ifdef _WIN32` instances may remain temporarily — they get removed by 7-9-19.)
- [ ] **AC-5: Cross-platform smoke.** Trigger one fatal-exit path on each of macOS, Linux, Windows (e.g., rename `Data/MapName1.bmd` to force `LoadData.cpp:50` to fire). Verify the game logs the reason and terminates cleanly with exit code != 0 on every platform. No corrupted-state continuation.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance
- [ ] **AC-STD-2:** Catch2 unit tests for `FatalExit` (capture log output, mock `std::exit` via injected exit-handler for testability)
- [ ] **AC-STD-13:** Quality Gate passes
- [ ] **AC-STD-15:** Git Safety

---

## Tasks / Subtasks

- [ ] Task 1: Implement `mu::platform::FatalExit` (AC: 1, 2)
  - [ ] 1.1: Create `Platform/PlatformLifecycle.h` with the declaration
  - [ ] 1.2: Create `Platform/PlatformLifecycle.cpp` with SDL3 implementation
  - [ ] 1.3: Add CMake source-list entry
- [ ] Task 2: Catch2 unit tests for `FatalExit` (AC: STD-2)
  - [ ] 2.1: Test that reason string is logged
  - [ ] 2.2: Test that `SDL_EVENT_QUIT` is pushed
  - [ ] 2.3: Test that injected exit-handler is invoked
- [ ] Task 3: Migrate call sites (AC: 3)
  - [ ] 3.1: `Data/` directory (~15 sites — `LoadData.cpp`, `ZzzInformation.cpp`, `ZzzOpenData.cpp`)
  - [ ] 3.2: `World/` directory (~14 sites — `ZzzLodTerrain.cpp`, `MapManager.cpp`)
  - [ ] 3.3: `Gameplay/` directory (~10 sites — Buffs, Items, Pets, Social)
  - [ ] 3.4: `Network/` directory (~2 sites)
  - [ ] 3.5: `RenderFX/` directory (~1 site)
  - [ ] 3.6: `UI/` directory (~12 sites)
  - [ ] 3.7: `ThirdParty/UIControls.cpp` (~1 site)
- [ ] Task 4: Final grep gate (AC: 4)
- [ ] Task 5: Cross-platform smoke test (AC: 5)

---

## Dev Notes

### Reason-string discipline

Each call site gets a specific reason string of the form `"<subsystem>: <what failed>"`. The reason is the diff between "log line in production tells operator what to fix" and "log line says `WM_DESTROY` and operator has to grep". Examples:

- `mu::platform::FatalExit("LoadData: data/MapName1.bmd missing or unreadable")`
- `mu::platform::FatalExit("ZzzLodTerrain: terrain mesh checksum mismatch at chunk index 217")`
- `mu::platform::FatalExit("WSclient: TCP socket creation failed (errno preserved in log)")`

### Why not just `std::abort()`

`std::abort()` skips destructors. The SDL3 GPU backend has GPU resources that must be flushed before the process exits or the driver state machine asserts on shutdown. Pushing `SDL_EVENT_QUIT` lets the main loop run one more `EndFrame` + shutdown sweep before `std::exit` runs static destructors. That gives a clean shutdown on macOS/Linux/Windows.

### Out of scope

- `WSclient.cpp:14880 PostMessage(WM_RECEIVE_BUFFER)` — the legacy network packet bus, properly guarded — handled by 7-9-19.
- Crash-handler installation — already covered by 7-1-1, 7-1-2.

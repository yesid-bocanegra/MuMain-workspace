# Story 7-9-17: Cross-Platform Timer for Win32 SetTimer/KillTimer Call Sites

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-17 |
| **Title** | Replace Win32 SetTimer/KillTimer with Cross-Platform Timer |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-0 (Platform / Enabler) |
| **Flow Type** | Refactor |
| **Flow Code** | VS0-PLAT-TIMER-CROSSPLATFORM |
| **Story Points** | 3 |
| **Dependencies** | None |
| **Status** | ready-for-dev |

---

## User Story

**As a** player relying on chat auto-reconnect, UI tooltips, and buff timer expiration,
**I want** the deferred-callback timers (`SetTimer(g_hWnd, ...)` / `KillTimer(g_hWnd, ...)`) replaced with a cross-platform abstraction,
**So that** these features work on macOS and Linux instead of being silently no-op stubs (the Win32 stubs at `PlatformCompat.h:1555,1581` return `0`, which means "timer not created" — callers ignore the return and assume the timer fires).

---

## Background

### Problem

Four call sites use Win32 `SetTimer(g_hWnd, id, ms, callback)` / `KillTimer(g_hWnd, id)` directly, all unguarded by `#ifdef`:

| Site | File:Line | Purpose | Silent failure |
|---|---|---|---|
| Chat auto-reconnect | `UI/Legacy/UIWindows.cpp:50` | Reconnect timer (15s) for disconnected chat | Chat does not auto-reconnect on macOS/Linux |
| UI slide-help tooltip | `ThirdParty/UIControls.cpp:4814` | Delayed tooltip popup | Tooltips never appear |
| Buff expiration timer (set) | `Gameplay/Buffs/w_BuffTimeControl.cpp:114` | Mark buff for expiration callback | Buffs never visually expire client-side |
| Buff expiration timer (kill) | `Gameplay/Buffs/w_BuffTimeControl.cpp:30,125` | Cancel buff timer | No-op (timer wasn't running anyway) |

The Win32 timer model (window-attached, callback-via-WM_TIMER) doesn't translate cleanly to SDL3. Two viable approaches:

1. **`SDL_AddTimer` based** — SDL3 provides `SDL_AddTimer(ms, callback, userdata)` which fires the callback on a worker thread. Requires marshalling work back to the main thread via `SDL_PushEvent`.
2. **`CTimer2`-extension based** — `Core/Timer.cpp` already implements `CTimer2::SetTimer(unsigned int delay)` for game-loop-tick checking. Extend it to accept a callback that fires when checked-and-expired in the per-frame update.

The `CTimer2` approach is preferred — these timers are coarse-grained (15s reconnect, 900ms buff tick) and don't need worker-thread accuracy. Keeping all timer logic on the main thread avoids cross-thread state on existing single-threaded UI code.

### Target API

```cpp
// Core/Timer.h additions
class CTimer2 {
public:
    using Callback = std::function<void()>;
    void SetTimer(unsigned int delayMs, Callback cb);    // fires once after delay
    void SetRepeating(unsigned int periodMs, Callback cb);
    void KillTimer();
    void Tick();  // call from per-frame update; fires callback if expired
};

// Or a freestanding mu::Timer pool if member-per-call-site adds too much state
```

---

## Functional Acceptance Criteria

- [ ] **AC-1: Timer abstraction.** A cross-platform timer mechanism (extended `CTimer2` or new `mu::Timer`) supports one-shot and (optionally) repeating callbacks driven by per-frame ticking on the main thread.
- [ ] **AC-2: Chat reconnect ported.** `UIWindows.cpp:50` no longer calls `SetTimer(g_hWnd, CHATCONNECT_TIMER, 15 * 1000, 0)`. Chat reconnect logic uses the new timer; verified by disconnecting chat (block server port for 30s) and observing client reconnect on macOS/Linux/Windows.
- [ ] **AC-3: Slide-help tooltip ported.** `UIControls.cpp:4814` no longer calls `SetTimer(g_hWnd, SLIDEHELP_TIMER, ...)`. Tooltip appears after the configured delay on macOS/Linux/Windows.
- [ ] **AC-4: Buff expiration timer ported.** `w_BuffTimeControl.cpp:114,30,125` no longer calls `::SetTimer` / `::KillTimer`. Buff icons visually expire on schedule on macOS/Linux/Windows.
- [ ] **AC-5: Win32 stubs deleted.** `PlatformCompat.h:1555 SetTimer` and `KillTimer` declarations + bodies removed.
- [ ] **AC-6: Final grep gate.** `grep -rn "::SetTimer\|::KillTimer\|SetTimer(g_hWnd\|KillTimer(g_hWnd" src/source/` returns zero results outside `#ifdef _WIN32` blocks.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance
- [ ] **AC-STD-2:** Catch2 tests for timer expiration / cancellation / repeat behavior
- [ ] **AC-STD-13:** Quality Gate passes
- [ ] **AC-STD-15:** Git Safety

---

## Tasks / Subtasks

- [ ] Task 1: Choose abstraction approach (AC: 1)
  - [ ] 1.1: Spike: extend `CTimer2` vs. new `mu::Timer` pool — pick based on call-site count and thread-safety needs
- [ ] Task 2: Implement timer (AC: 1)
  - [ ] 2.1: Add callback support
  - [ ] 2.2: Add `Tick()` integration with main loop in `MuMain.cpp`
- [ ] Task 3: Catch2 tests (AC: STD-2)
  - [ ] 3.1: One-shot fire after delay
  - [ ] 3.2: Cancel before fire
  - [ ] 3.3: Repeating fire
- [ ] Task 4: Migrate chat reconnect (AC: 2)
- [ ] Task 5: Migrate slide-help tooltip (AC: 3)
- [ ] Task 6: Migrate buff expiration (AC: 4)
- [ ] Task 7: Delete `SetTimer`/`KillTimer` from `PlatformCompat.h` (AC: 5)
- [ ] Task 8: Final grep gate (AC: 6)

---

## Dev Notes

### Why not `SDL_AddTimer`

`SDL_AddTimer` callbacks fire on a worker thread. The buff/UI/chat code these timers feed is single-threaded main-loop code. Marshalling back via `SDL_PushEvent` works but adds latency and complicates testing. The four current call sites all tolerate per-frame tick granularity, so main-thread polling is simpler.

### Out of scope

- `CTimer2` callers that already work (e.g., `m_UpdateTimer.SetTimer(1000)` at `NewUIItemMng.cpp:76`) — those are not Win32-stub callers; they hit the existing `CTimer2::SetTimer(unsigned int delay)` method, which is fine.
- Replacing the per-frame tick model — that's a Core/Timer architecture change beyond this story's scope.

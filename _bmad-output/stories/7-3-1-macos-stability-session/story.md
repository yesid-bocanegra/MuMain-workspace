# Story 7.3.1: macOS 60-Minute Stability Session

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.3 - Stability Sessions |
| Story ID | 7.3.1 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | infrastructure |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-QUAL-STABILITY-MACOS |
| FRs Covered | FR37, NFR1, NFR3, NFR18 |
| Prerequisites | EPIC-2-6 complete, 7-6-1 through 7-6-7 done, 7-3-0 done, 7-5-1 done |

**Story Types:** `backend_api` | `backend_service` | `frontend_feature` | `infrastructure` | `fullstack`

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | cpp-cmake, backend | Target platform for stability validation session |
| project-docs | documentation | Session log, MuError.log artifacts, validation report |

---

## Story

**[VS-0] [Flow:E]**

**As a** player on macOS,
**I want** to play for 60+ minutes without crashes or disconnects,
**so that** macOS is validated as a stable gameplay platform.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** 60+ minute gameplay session completed on macOS (arm64) without crashes
- [ ] **AC-2:** Session includes: login -> world exploration (3+ maps) -> combat -> inventory -> trading -> chat -> logout
- [ ] **AC-3:** No server disconnects during session
- [ ] **AC-4:** Frame time log shows sustained 30+ FPS with no >50ms hitches
- [ ] **AC-5:** MuError.log shows no ERROR-level entries during session
- [ ] **AC-6:** Memory usage stable (no leaks visible over 60 minutes)

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — any hotfixes during session follow project naming, logging, and error handling conventions
- [ ] **AC-STD-2:** Testing Requirements — if code changes are made, `./ctl check` passes (format + lint, 0 errors)
- [ ] **AC-STD-6:** Conventional commit: `test(platform): macOS 60-minute stability session passed`
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check`) — must pass before session begins AND after any hotfixes
- [ ] **AC-STD-15:** Git Safety — no incomplete rebase, no force push

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Session log: timestamp, activities performed, FPS statistics (min/avg/max/p95)
- [ ] **AC-VAL-2:** MuError.log from the session (attached or referenced in story progress file)
- [ ] **AC-VAL-3:** Memory usage graph or snapshots (start vs end of session)

---

## Tasks / Subtasks

- [ ] Task 1: Pre-session environment validation (AC: 1, 2)
  - [ ] 1.1: Verify macOS arm64 build compiles cleanly (`cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`)
  - [ ] 1.2: Verify `./ctl check` passes (0 errors, 0 format violations)
  - [ ] 1.3: Verify OpenMU server is running and accessible
  - [ ] 1.4: Record baseline system info: macOS version, hardware, RAM, initial memory usage
- [ ] Task 2: Execute 60-minute gameplay session (AC: 1-6)
  - [ ] 2.1: Login to OpenMU server from macOS client
  - [ ] 2.2: Character creation/selection
  - [ ] 2.3: World exploration — visit 3+ different maps (Lorencia, Devias, Noria minimum)
  - [ ] 2.4: Combat — engage monsters, use melee/ranged/skills
  - [ ] 2.5: Inventory management — equip, unequip, move items
  - [ ] 2.6: Trading — initiate trade with another player or NPC shop
  - [ ] 2.7: Chat — send messages in normal, party, and/or guild channels
  - [ ] 2.8: Monitor FPS via frame time instrumentation (MuTimer from story 7-2-1)
  - [ ] 2.9: Record memory snapshots at 0, 15, 30, 45, 60 minutes
  - [ ] 2.10: Logout cleanly
- [ ] Task 3: Post-session validation (AC: 4-6)
  - [ ] 3.1: Extract FPS statistics from frame time log — confirm sustained 30+ FPS, no >50ms hitches
  - [ ] 3.2: Review MuError.log for ERROR-level entries
  - [ ] 3.3: Compare start/end memory usage — confirm no significant growth (leak detection)
  - [ ] 3.4: Document any issues found with severity and reproduction steps
- [ ] Task 4: Hotfix any blockers found during session (AC: 1-6)
  - [ ] 4.1: If crash occurs: capture crash log, diagnose via signal handlers (7-1-2), fix root cause
  - [ ] 4.2: If disconnect occurs: review MuError.log network entries, diagnose and fix
  - [ ] 4.3: If FPS drops below threshold: profile and fix performance bottleneck
  - [ ] 4.4: Re-run `./ctl check` after any code changes
  - [ ] 4.5: Re-run stability session if hotfixes were applied (must pass a clean 60-min run)
- [ ] Task 5: Documentation and artifacts (AC: VAL-1, VAL-2, VAL-3)
  - [ ] 5.1: Create session log with timestamps, activities, FPS stats
  - [ ] 5.2: Attach or reference MuError.log from successful session
  - [ ] 5.3: Include memory usage comparison (start vs end)
  - [ ] 5.4: Commit: `test(platform): macOS 60-minute stability session passed`

---

## Dev Notes

### Session Protocol

This is a **manual validation story**, not a code implementation story. The primary deliverable is evidence that the macOS client runs stably for 60+ minutes under real gameplay conditions.

**Critical context from prerequisite work:**

1. **Build chain:** Stories 7-3-0, 7-5-1, 7-6-1 through 7-6-7 fixed all macOS build issues. The client should now compile cleanly on macOS arm64 via `cmake --preset macos-arm64`.

2. **Build RCA history:** The original attempt at this story (2026-03-24) discovered the macOS build had never been compiled — leading to scope discovery of stories 7-3-0, 7-5-1, and the entire 7-6-x series. All of those are now done.

3. **Frame time instrumentation:** Story 7-2-1 added `mu::MuTimer` in `Core/MuTimer.h/.cpp` using `std::chrono::steady_clock`. Use `FrameStart()`/`FrameEnd()` data to extract FPS statistics.

4. **Error reporting:** Story 7-1-1 established cross-platform `g_ErrorReport.Write()` logging to `MuError.log`. Story 7-6-7 completed the cross-platform diagnostics migration (system info, CPU, GPU backend, audio devices).

5. **Signal handlers:** Story 7-1-2 added POSIX signal handlers for crash diagnostics on macOS/Linux.

6. **Diagnostics available:** `MuError.log` will contain system info (OS, CPU, RAM, GPU backend via SDL3, audio devices via miniaudio) at startup. Monitor this log during the session.

### Server Requirements

- OpenMU server must be running and accessible from the macOS machine
- Server address/port configured in the client (see story 3-4-2 server connection config)
- At least one test account with a character capable of map travel, combat, and trading

### What to Monitor During Session

| Metric | Tool | Threshold | Action if Exceeded |
|--------|------|-----------|-------------------|
| FPS | MuTimer frame log | < 30 FPS sustained | Profile and hotfix |
| Frame hitches | MuTimer frame log | > 50ms single frame | Document, investigate |
| Memory | Activity Monitor / `leaks` tool | > 20% growth over 60 min | Investigate leak |
| MuError.log | `tail -f MuError.log` | Any ERROR entry | Investigate immediately |
| Disconnects | Client behavior | Any disconnect | Check network log, investigate |

### Known Risk Areas (from previous stories)

- **Memory:** `SAFE_DELETE` / raw `new` patterns in legacy code may leak under certain gameplay paths
- **Rendering:** SDL GPU backend (Metal on macOS) — first extended use under real gameplay conditions
- **Audio:** miniaudio backend — first extended use with BGM + SFX simultaneous playback
- **Network:** .NET AOT interop (char16_t encoding) — validated in 3-3-1 but not under sustained load
- **Text input:** SDL3 text input (story 2-2-3) — first extended chat session on macOS

### If Session Fails

1. Capture all logs (MuError.log, crash dump if available, console output)
2. Create a hotfix with conventional commit: `fix(platform): [description]`
3. Run `./ctl check` to validate the fix
4. **Re-run the full 60-minute session** — partial sessions do not count
5. Document the failure and fix in the progress file

### Project Structure Notes

- Build: `MuMain/CMakePresets.json` → `macos-arm64` preset
- Quality gate: `./ctl check` (clang-format + cppcheck, must pass)
- Frame timer: `MuMain/src/source/Core/MuTimer.h` / `MuTimer.cpp`
- Error log: `MuMain/src/source/Core/ErrorReport.h` / `ErrorReport.cpp`
- Signal handlers: `MuMain/src/source/Core/SignalHandler.h` / `SignalHandler.cpp`
- Platform compat: `MuMain/src/source/Platform/PlatformCompat.h`
- SDL event loop: `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp`

### References

- [Source: _bmad-output/stories/7-3-1-macos-stability-session/build-rca.md] — Original build RCA that spawned 7-3-0
- [Source: _bmad-output/planning-artifacts/epics.md#Story-7.3.1] — Epic specification
- [Source: docs/project-context.md] — Project conventions and tech stack
- [Source: docs/development-standards.md] — Code standards and quality gates

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (create-story workflow, 2026-03-25)

### Debug Log References

### Completion Notes List

- Story type: infrastructure (manual validation session)
- No code implementation expected unless hotfixes are needed during the session
- All 7-6-x prerequisite stories are done — macOS build chain is clear
- PCC compliant: SAFe metadata, AC-STD sections, flow code documented

### File List

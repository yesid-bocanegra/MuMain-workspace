# Outbound network backpressure blocks gameplay on the main thread

**Date:** 2026-07-17
**Discovered during:** Dense-combat runtime freeze investigation
**Context:** Release client remains connected and rendering, but movement and skill commands reach OpenMU late and in bursts
**Discovery type:** bug
**Urgency:** this-sprint
**Urgency justification:** Main-thread network waits make movement and combat authority unusable during sustained load while the client appears alive.

## Summary

Every native gameplay send synchronously acquires the OpenMU connection output lock and waits for `PipeWriter.FlushAsync()` on the caller thread. During transport backpressure, the render/game thread stops advancing until the socket pipeline accepts more output; queued movement commands then reach the server together after the stall. This explains local skill animation without authoritative effect and server warnings for stale movement positions despite a healthy incoming packet queue.

## Root Causes

### RCA-1: Gameplay sends synchronously wait for transport progress

**What:** `Send()` and `CreateAndSend()` block their unmanaged caller while acquiring `OutputLock` and synchronously waiting for `FlushAsync()`. OpenMU exposes the output as a `PipeWriter`; flush completion can be delayed by pipeline backpressure and transport consumption.
**Evidence:** `MuMain/ClientLibrary/ConnectionWrapper.cs:120` synchronously locks output and `MuMain/ClientLibrary/ConnectionWrapper.cs:125` calls `WaitAndUnwrapException()` on `FlushAsync()`. Generated packet functions call `CreateAndSend()` directly from native gameplay entry points. OpenMU server logs at `2026-07-17 16:59:53.264` received several stale walk requests together, including `Player requested to walk from "26, 52", but it's currently at "30, 52"`. At the same time, incoming telemetry remained `depth=0`, `oldest<30ms`, and `drain=0.0ms`.
**Affected scope:** Movement, skills, attacks, chat, inventory requests, map requests, and every generated client-to-server packet sent through `ConnectionWrapper`.
**Proposed fix:** Copy each completed packet into owned memory and enqueue it to one bounded, ordered sender per connection. A dedicated async send loop owns `OutputLock`, writes packets sequentially, and awaits `FlushAsync()` away from the render/game thread. Disconnect cleanly on sender failure or queue overflow rather than silently dropping ordered gameplay commands.
**Estimated lines:** ~100 production lines plus one focused test.

### RCA-2: Outbound latency has no targeted telemetry

**What:** Existing diagnostics show connection and receive-loop state but not enqueue delay, output-lock wait, flush duration, or queued outbound bytes.
**Evidence:** `MuMain/ClientLibrary/ConnectionWrapper.cs:159` logs receive-loop lifecycle only. Runtime logs contain incoming `PacketQueue` metrics but no outbound timing around delayed movement bursts.
**Affected scope:** Diagnosis of client-to-server command latency and transport backpressure.
**Proposed fix:** Under `MU_NETWORK_DIAGNOSTICS`, emit low-rate sender queue depth/high-water, oldest age, lock-wait duration, flush duration, and packet length. Keep diagnostics disabled by default.
**Estimated lines:** ~40 production lines.

### RCA-3: Debug and Release share one Native AOT freshness stamp

**What:** `./ctl build` always selects the Debug preset, while `run --release` selects a Release executable. CMake also uses one configuration-independent `DOTNET_DLL_PATH`, allowing one configuration's Native AOT output timestamp to satisfy another configuration's build graph.
**Evidence:** `ctl` assigned `BUILD_PRESET=macos-arm64-debug` in platform detection and accepted no build configuration flag. `MuMain/src/CMakeLists.txt` placed `MUnique.Client.Library.dylib` at one shared path outside `$<CONFIG>` before staging it into Debug or Release.
**Affected scope:** Debug/Release Native AOT library selection and confidence that runtime code matches current source.
**Proposed fix:** Add `build --debug|--release`, pass through rebuild configuration, and use configuration-specific intermediate and staged Native AOT paths.
**Estimated lines:** ~30 lines across build wrapper, CMake, and regression check.

## Implementation Plan

1. Add a focused managed test seam for an ordered outbound queue and a blocked async sink; prove enqueue returns without waiting for sink completion.
2. Change `MuMain/ClientLibrary/ConnectionWrapper.cs` to serialize packet creation into owned buffers before returning to native callers.
3. Add one async sender loop per connection which preserves FIFO order and performs output lock, write, and flush operations.
4. Complete and drain sender state during disconnect/dispose without allowing sends after disposal.
5. Add gated low-rate outbound queue and flush telemetry for runtime verification.

## Post-Fix Verification

1. Run focused managed test; expected: native-facing enqueue completes while the fake sink remains blocked, then packets arrive in exact FIFO order after release.
2. Build the Release Native AOT client; expected: zero warnings and successful `ClientLibrary` publication.
3. Run dense combat for at least 10 minutes while moving and casting AoE skills.
4. Expected: movement remains responsive, AoE effects receive prompt authoritative results, and OpenMU no longer receives old walk commands in one delayed burst.
5. Enable `MU_NETWORK_DIAGNOSTICS=1`; expected: render thread never reports send waits, outbound queue returns toward zero, and flush stalls occur only on the sender task.
6. Disconnect or stop the server during queued output; expected: client disconnect handling runs without crash, deadlock, or silent command loss.

## Scope Assessment

**Type:** bug
**Story count:** 1 story
**Epic home:** Epic 7 — Stability, Diagnostics & Quality Gates
**Milestone relevance:** M5 MVP Complete gameplay responsiveness and network reliability
**Estimated points:** 3

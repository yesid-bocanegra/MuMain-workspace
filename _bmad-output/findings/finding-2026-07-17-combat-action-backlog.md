# Dense monster combat creates a growing action and packet backlog

**Date:** 2026-07-17
**Discovered during:** User-reported dense-combat runtime investigation
**Context:** More than 100 visible monsters with simultaneous monster, pet, and player attacks; observed around 34 FPS and worsening after several minutes
**Discovery type:** bug
**Urgency:** this-sprint
**Urgency justification:** Sustained combat eventually delays authoritative damage and map transitions by minutes while the client remains running.

## Summary

Monster count alone produces only a modest slowdown; the failure begins when monsters generate action, skill, and damage traffic. Every received packet is queued and later processed synchronously on the main thread, and the main loop drains the entire captured queue without measuring queue age, depth, or processing time. Combat handlers also create animation state and transient visual work per packet, so packet processing cost rises with attack rate until old actions are presented long after their server time.

## Root Causes

### RCA-1: Incoming combat packets use an unbounded FIFO with no backlog controls

**What:** The network thread can enqueue packets without a size or age limit. Each main-loop iteration swaps out and processes every pending packet before scene update/render, with no frame-time budget, queue-depth metric, packet-age metric, stale-action replacement, or overload policy.
**Evidence:** `MuMain/src/source/Network/IncomingPacketQueue.cpp:20` pushes every packet; `MuMain/src/source/Network/IncomingPacketQueue.cpp:31` swaps the complete queue; `MuMain/src/source/Network/IncomingPacketQueue.cpp:44` processes until empty; `MuMain/src/source/App/Platform/Windows/Winmain.cpp:1310` performs this drain before frame update. The previous Win32 path handled network packets as individual window messages interleaved with the message-loop limit, while commit `543071b32` replaced it with whole-queue draining.
**Affected scope:** All server packets under load, especially action, skill, damage, movement, and map-change responses.
**Proposed fix:** Add queue depth, oldest-packet age, packets-per-frame, and drain-duration telemetry first. Then introduce packet-class-aware overload handling: never drop session, damage, inventory, map, or character-lifecycle packets; coalesce only superseded presentation/state packets such as repeated action or movement updates for the same entity. Preserve arrival order for non-coalescible packets.
**Estimated lines:** ~120 lines across 4 files

### RCA-2: Combat packet handlers perform presentation work synchronously during queue drain

**What:** Monster action, monster skill, magic, and damage packets directly mutate animations and create damage points/effects while the queue is being drained. High attack rates therefore increase both packet volume and cost per packet before normal scene processing can continue.
**Evidence:** `MuMain/src/source/Network/Server/WSclient.cpp:3487` handles every action and resets animation state; `MuMain/src/source/Network/Server/WSclient.cpp:4005` applies every monster skill; `MuMain/src/source/Network/Server/WSclient.cpp:3423` handles damage; `MuMain/src/source/Network/Server/WSclient.cpp:3255` and nearby branches create one or more damage points per hit. The user's pet-only case remains smooth because monsters die before producing this traffic.
**Affected scope:** Main-thread packet drain, character animation state, damage-number effects, monster skills, player responsiveness.
**Proposed fix:** Separate authoritative state application from optional presentation. Apply damage and critical state immediately; enqueue or coalesce visual action/effect requests by entity and frame, with explicit caps under overload.
**Estimated lines:** ~100 lines across 3 files

### RCA-3: Attack presentation repeatedly scans fixed effect pools

**What:** Damage and attack presentation searches fixed pools for free entries and updates full pools every frame. This is bounded but amplifies cost as combat activity fills pools, unlike static monsters which mostly pay character update/render cost.
**Evidence:** `MuMain/src/source/Render/Effects/ZzzEffectPoint.cpp:29` scans up to `MAX_POINTS` for every damage point; `MuMain/src/source/Render/Effects/ZzzEffectPoint.cpp:93` scans all points during rendering; effect, joint, and particle code similarly loops over `MAX_EFFECTS`, `MAX_JOINTS`, and `MAX_PARTICLES`. Constants are `MAX_POINTS=100`, `MAX_EFFECTS=200`, `MAX_JOINTS=500`, and `MAX_PARTICLES=3000`.
**Affected scope:** Dense combat presentation and main-thread frame time.
**Proposed fix:** After queue telemetry confirms contribution, use free-list/ring allocation for transient pools and degrade optional effects when packet age or frame time exceeds a threshold. Do not increase pool sizes as the first fix.
**Estimated lines:** ~80 lines across 3 files

### RCA-4: FPS scaling does not explain the observed stale-action delay

**What:** Animation movement is scaled against a 25 FPS reference, and the reported 34 FPS remains above that reference. The observed multi-minute delay therefore indicates accumulated work rather than animation speed alone.
**Evidence:** `MuMain/src/source/Engine/AI/ZzzAI.cpp:733` computes `REFERENCE_FPS / FPS`; `MuMain/src/source/Engine/AI/ZzzAI.cpp:735` clamps the factor to at most 1. At 34 FPS the factor is approximately 0.74, maintaining real-time animation speed.
**Affected scope:** Diagnostic classification only.
**Proposed fix:** Treat FPS as a load indicator, but use packet age/depth to prove and control latency.
**Estimated lines:** 0 production lines; covered by telemetry work

## Implementation Plan

1. Add non-allocating queue telemetry to `IncomingPacketQueue`: current depth, high-water mark, oldest age, drained count, and drain duration.
2. Display or log telemetry at a low fixed rate through existing diagnostics so the dense-combat reproduction can confirm packet age growth.
3. Classify packet codes into critical ordered packets and coalescible entity presentation/state packets.
4. Coalesce only repeated action/movement presentation for the same entity while preserving critical packet order and all damage/map/session packets.
5. Move optional effect creation out of critical packet processing and cap it during overload.
6. Optimize transient effect allocation only if profiling shows pool scans remain material after queue latency is controlled.

## Post-Fix Verification

1. Spawn or gather more than 100 monsters and record FPS, incoming queue depth, oldest packet age, packets drained per frame, and drain milliseconds while monsters remain static.
2. Repeat with monsters attacking plus pet and player attacks for at least 10 minutes.
3. Expected: oldest critical-packet age remains below 250 ms, queue depth returns toward zero between bursts, and map-change responses are processed promptly.
4. Walk outside the combat area; expected: no old attack animation or damage presentation continues after its valid server sequence window.
5. Request a map change during peak combat; expected: request and response complete without waiting for accumulated presentation packets.
6. Verify damage totals, death, inventory, buffs, and map transitions remain identical with overload handling enabled.

## Scope Assessment

**Type:** bug
**Story count:** 2 stories
**Epic home:** Epic 7 — Stability, Diagnostics & Quality Gates; Epic 6 — Cross-Platform Gameplay Validation
**Milestone relevance:** M5 MVP Complete stability and gameplay responsiveness
**Estimated points:** 5 + 5

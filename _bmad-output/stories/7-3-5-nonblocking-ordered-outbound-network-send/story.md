# Story 7.3.5: Nonblocking Ordered Outbound Network Send

**Status:** in-progress
**Story Points:** 3
**Priority:** Critical
**Repository:** `MuMain`

## Discovery Context

Source: `_bmad-output/findings/finding-2026-07-17-outbound-network-send-blocks-main-thread.md`

## Acceptance Criteria

- [x] Native gameplay send entry points return without waiting for output-lock acquisition or transport flush completion.
- [x] Packets remain in exact FIFO order for each connection.
- [x] Every packet owns its bytes until async transmission completes.
- [x] Sender failure or queue overload triggers explicit disconnect handling; gameplay commands are never silently dropped.
- [x] Dispose and disconnect stop the sender without deadlock or use-after-dispose.
- [x] `MU_NETWORK_DIAGNOSTICS=1` exposes low-rate outbound queue and flush latency diagnostics.
- [x] Focused managed regression test and Release Native AOT client build pass.
- [x] `./ctl build --release` rebuilds and stages Release-specific runtime artifacts without reusing Debug Native AOT output.

## Tasks

- [x] Add deterministic blocked-sink FIFO regression test.
- [x] Add bounded per-connection outbound channel.
- [x] Move output lock and flush waits to async sender loop.
- [x] Add gated outbound latency telemetry.
- [x] Make build configuration explicit and isolate ClientLibrary artifacts per configuration.
- [ ] Verify dense-combat behavior against live OpenMU server.

## Dev Notes

- Preserve generated packet builders and native ABI.
- Copy built packets before returning to native code.
- Use one reader per connection; no priority reordering or packet coalescing.
- Keep existing unrelated `ConnectionWrapper.cs` diagnostic-log removal.
- Queue capacity must bound memory; overflow must fail connection visibly.

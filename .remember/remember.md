# Handoff

## State
Story 7-9-10 shipped (SDL_ttf input-box rendering). Two follow-up fixes since: `c1df16a0` cleared SDL_ttf bg before text to kill a shadow behind every input, `4904d4ce` fixed caret height (now matches text bbox, not box height) + caret X scale (textSize is already design-units, was being divided twice at Retina DPI). Outer bumps `672ccd1`, `93d2be2`.

## Next
1. **Stories 7-9-11 (Configure struct) and 7-9-12 (SinglePrompt RAII)** still pending. 11 unblocked; 12 depends on 11.
2. **Known, accepted: click-to-focus broken on CUILetterWriteWindow inputs.** User signed off 2026-04-20 as "works, could improve, current approach works." Root cause at `UIControls.cpp:266-275`: `g_dwActiveUIID` gate rejects the click because Friend List (the spawner) still owns active-UIID. Send→error path hits programmatic `GiveFocus` which bypasses the gate — the existing workaround. Fix path if/when revisited: Friend List should `SendUIMessage(UI_MESSAGE_SELECT, letterWriteUIID, 0)` when spawning the modal.
3. **Known, accepted: caret position slightly imperfect** even after `4904d4ce`. User signed off same day; not worth further polish under current approach. Next lever if revisited: tune `textPadY` or probe exact font baseline via TTF metrics.
4. **Pre-existing Dotnet build errors** keep showing in `./ctl check` but gate passes: `dotnet_SendDuelStartResponse`, `SendPlayerShopClose*`, `SendPickupItemRequest*`, etc. Worth separate investigation.

## Context
- `CUIRenderTextSDLTtf::RenderText` returns `lpTextSize->cx/cy` in **design units** (divided by g_fScreenRate at lines 3112-3113). Do NOT divide again at call site.
- `CUIRenderTextSDLTtf` is stateful/global — callers must set BOTH `SetTextColor` AND `SetBgColor` or inherit whatever the prior caller left. This latent exposure affects every `g_pRenderText` consumer, not just input boxes.
- `DoMouseActionSub() {}` on CUILetterWriteWindow means the window's mouse-action path doesn't dispatch to children — children rely on `DoActionSub` being called per-frame with `bMessageOnly=FALSE`, which in turn runs each input's own DoAction gate. The gate at UIControls.cpp:264-275 is where click-focus gets rejected when g_dwActiveUIID is stale.
- `rtk` zsh hook: wrap `git` in `bash -c '...'`.
- Today's commit chain: MuMain `62ef4cbf` → `2f89d70c` → `3911efc4` → `8f886cb1` → `4a67bd68` → `dc085d27` → `c1df16a0` → `4904d4ce`; outer `297b60a` → `221741e` → `2149762` → `1213480` → `7cbbded` → `2b630b3` → `672ccd1` → `93d2be2`.

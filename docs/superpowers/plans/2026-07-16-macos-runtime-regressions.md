# macOS Runtime Regressions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore missing login-world models, persistent ground-item labels, Lorencia blacksmith audio, Release launch ergonomics, and reconnect background capture; then validate SDL UI regressions.

**Architecture:** Keep fixes inside existing platform boundaries: `ctl` selects build configuration, scene code supplies camera bounds, `CNewUINameWindow` owns item-label visibility, `MiniAudioBackend` owns playback diagnostics and channel policy, and `MuRendererSDLGpu` owns frame capture. Do not port commits by hash blindly; compare source-branch behavior, reproduce locally, then apply minimum equivalent change.

**Tech Stack:** C++20, SDL3 GPU, SDL3 input, miniaudio, CMake/Ninja Multi-Config, Catch2, shell launcher.

---

### Task 1: Add Release launcher selection

**Files:**
- Modify: `ctl:141`
- Test: shell assertions against `ctl`

- [ ] **Step 1: Add failing launcher check**

Run:

```bash
./ctl run --release --help
```

Expected before fix: launcher treats `--release` as game argument and resolves `src/Debug/Main`.

- [ ] **Step 2: Parse build configuration in `cmd_run`**

Add one local configuration variable. Consume `--release` or `--debug` before forwarding remaining arguments to `configure_server_args`. Pass selected configuration into `resolve_mumain_exe`; replace hardcoded `Debug` at `ctl:151`.

Required behavior:

```text
./ctl run             => Debug
./ctl run --debug     => Debug
./ctl run --release   => Release
```

- [ ] **Step 3: Improve missing-build message**

Report exact configuration and build command:

```text
Executable not found: .../src/Release/Main
Run 'cmake --build MuMain/out/build/macos-arm64 --config Release --target Main' first.
```

- [ ] **Step 4: Verify launcher paths**

Run:

```bash
zsh -n ctl
./ctl run --release /u127.0.0.1 /p1
```

Expected: syntax passes; startup line points to `src/Release/Main`. Connection failure is acceptable.

- [ ] **Step 5: Commit**

```bash
git add ctl
git commit -m "feat(ctl): support Release game launches"
```

### Task 2: Restore login-world model visibility

**Files:**
- Modify: `MuMain/src/source/Scenes/LoginScene.cpp:368`
- Modify if evidence points there: `MuMain/src/source/Render/Renderer/MuRendererSDLGpu.cpp`
- Test: `MuMain/tests/scenes/test_auth_character_validation.cpp`

- [ ] **Step 1: Capture failing render evidence**

Add temporary `MU_LOGIN_RENDER_DIAG` logging around `NewRenderLogInScene()` for camera `ViewNear`, `ViewFar`, visible character count, visible object count, and render-pass depth state. Run Release and capture one login camera cycle.

Expected failure evidence: models are submitted but rejected by depth/clipping, or model/object visibility count is zero while mist/effects render.

- [ ] **Step 2: Compare source-branch invariant**

Compare current code with commit `4bd18ba2`. Current code already carries its `ViewFar`, `ViewNear`, and full-terrain bounds changes, so do not cherry-pick it. Trace first state difference after `BeginOpengl()` through `RenderCharactersClient()`, `RenderObjects()`, and SDL GPU depth pipeline selection.

- [ ] **Step 3: Add regression assertion**

Extend `MuMain/tests/scenes/test_auth_character_validation.cpp` with source-level checks that login rendering sets camera bounds before `BeginOpengl()` and retains the character/object render calls after terrain rendering.

- [ ] **Step 4: Apply one confirmed fix**

Fix only confirmed state mismatch. Likely candidates, ordered by evidence:

1. Login render command receives stale scissor/viewport.
2. Login opaque model pass receives depth-read-only pipeline.
3. Near-plane clipping rejects tour-camera models.
4. Visibility flags are reset after scene initialization.

Remove temporary diagnostics after verification.

- [ ] **Step 5: Verify visually and with tests**

Run:

```bash
cmake --build MuMain/out/build/macos-arm64 --config Release --target Main -j2
ctest --test-dir MuMain/out/build/macos-arm64 -C Release -R auth_character --output-on-failure
./ctl run --release
```

Expected: mist remains correct; terrain models and animated objects remain visible throughout camera cycle.

- [ ] **Step 6: Commit**

```bash
git add MuMain/src/source/Scenes/LoginScene.cpp MuMain/src/source/Render/Renderer/MuRendererSDLGpu.cpp MuMain/tests/scenes/test_auth_character_validation.cpp
git commit -m "fix(scene): restore login world models"
```

### Task 3: Restore ground-item label hotkey

**Files:**
- Modify: `MuMain/src/source/UI/NewUI/Character/NewUINameWindow.cpp:132`
- Modify if required: `MuMain/src/source/Core/Input/KeyState.cpp`
- Test: `MuMain/tests/ui/test_ground_item_labels.cpp`
- Modify: `MuMain/tests/ui/CMakeLists.txt`

- [ ] **Step 1: Add input-state regression test**

Create a small test covering intended behavior:

```cpp
CHECK(UpdateItemLabelVisibility(false, false) == false);
CHECK(UpdateItemLabelVisibility(false, true) == true);
CHECK(UpdateItemLabelVisibility(true, false) == true);
```

The helper inputs represent persistent toggle state and held Alt state. Keep helper free of SDL globals so test remains headless.

- [ ] **Step 2: Instrument current key path**

Under `MU_ITEM_LABEL_DIAG`, log `IsPress(VK_MENU)`, `IsRepeat(VK_MENU)`, `m_bShowItemName`, live item count, visible item count, cache-build successes, and cache-build failures. Reproduce both Alt hold and Alt tap.

- [ ] **Step 3: Fix confirmed layer**

If `IsPress(VK_MENU)` never fires, correct SDL Alt edge handling in `KeyState.cpp`. If key state works but cached labels fail, trace `RenderGroundItemLabelCached()` and texture registration. Preserve hover path at `NewUINameWindow.cpp:228`.

- [ ] **Step 4: Verify label modes**

Run Release with dropped items:

1. Hover item: one label appears at cursor.
2. Hold Alt: all visible labels appear.
3. Tap Alt: persistent labels toggle on/off.
4. Open/close inventory while Alt held: labels remain stable.

- [ ] **Step 5: Commit**

```bash
git add MuMain/src/source/UI/NewUI/Character/NewUINameWindow.cpp MuMain/src/source/Core/Input/KeyState.cpp MuMain/tests/ui
git commit -m "fix(ui): restore ground item label hotkey"
```

### Task 4: Restore Lorencia blacksmith sound

**Files:**
- Modify: `MuMain/src/source/Core/Platform/Audio/MiniAudioBackend.cpp:209`
- Modify if required: `MuMain/src/source/Engine/Object/ZzzOpenData.cpp:1870`
- Modify if required: `MuMain/src/source/Engine/Object/ZzzCharacter.cpp:6082`
- Test: `MuMain/tests/audio/test_miniaudio_sfx.cpp`

- [ ] **Step 1: Verify asset and load result**

At runtime, confirm `Data/Sound/nBlackSmith.wav` exists with case-insensitive path lookup and capture `ma_sound_init_from_file()` result for `SOUND_NPC_BLACK_SMITH`. Missing asset and playback-policy failures require different fixes.

- [ ] **Step 2: Add focused audio diagnostics**

Under `MU_AUDIO_DIAG`, log only sound ID `SOUND_NPC_BLACK_SMITH`: load success, channel count, 3D flag, play request, dedupe decision, playback start, and current object position.

- [ ] **Step 3: Reproduce animation trigger**

Confirm `MODEL_SMITH` reaches `ZzzCharacter.cpp:6082` and calls `PlayBuffer()` during animation frames `5..10`. Current source already contains source-branch trigger; do not port it again.

- [ ] **Step 4: Fix confirmed audio cause**

Use minimum matching fix:

- Missing/case-mismatched file: correct POSIX asset resolution or asset packaging.
- Loaded but inaudible 3D sound: correct listener/source coordinates or attenuation.
- Dedupe suppresses later hammer cycles: track dedupe per object and permit restart after sound completion rather than suppressing any active channel globally.

- [ ] **Step 5: Add lifecycle test**

Extend `test_miniaudio_sfx.cpp` with a test seam for dedupe decision logic. Assert same object is suppressed while playing, different object is not suppressed, and completed sound may restart.

- [ ] **Step 6: Verify in Lorencia**

Expected: one hammer sound per animation strike, spatial volume changes with distance, no frame-rate-dependent rapid retriggering.

- [ ] **Step 7: Commit**

```bash
git add MuMain/src/source/Core/Platform/Audio/MiniAudioBackend.cpp MuMain/src/source/Engine/Object/ZzzOpenData.cpp MuMain/src/source/Engine/Object/ZzzCharacter.cpp MuMain/tests/audio/test_miniaudio_sfx.cpp
git commit -m "fix(audio): restore Lorencia blacksmith sound"
```

### Task 5: Implement reconnect background capture

**Files:**
- Modify: `MuMain/src/source/Render/Renderer/MuRendererSDLGpu.cpp:2316`
- Modify: `MuMain/src/source/UI/NewUI/Dialogs/ReconnectDialog.cpp:230`
- Test: `MuMain/tests/render/test_frame_pixel_readback.cpp`

- [ ] **Step 1: Add capture lifecycle test**

Test renderer contract with a fake renderer: first capture allocates a nonzero texture ID, repeated capture reuses it when size matches, resize replaces it, and release invalidates it.

- [ ] **Step 2: Create dedicated capture texture**

Add an owned SDL GPU texture sized to `s_swapW`/`s_swapH` with usage required for both blit destination and shader sampling. Do not sample swapchain texture directly. Reuse existing texture ID when dimensions match; release and recreate on resize.

- [ ] **Step 3: Queue end-of-frame blit**

Make `CaptureFrameTexture(textureId)` allocate/reuse texture, set `s_pendingFrameCaptureTextureId`, and return its ID. Keep copy after render pass at `MuRendererSDLGpu.cpp:1750`, before command-buffer submit.

- [ ] **Step 4: Handle one-frame availability**

`ReconnectDialog::CaptureBackground()` currently marks background available immediately. Track capture request separately from capture readiness, or guarantee previous completed frame texture before returning nonzero. Never render an uninitialized texture.

- [ ] **Step 5: Verify reconnect behavior**

Force server disconnect in game. Expected: frozen last frame appears behind reconnect panel, resize remains correct, cancellation works, reconnect success releases capture texture, no GPU validation errors occur.

- [ ] **Step 6: Commit**

```bash
git add MuMain/src/source/Render/Renderer/MuRendererSDLGpu.cpp MuMain/src/source/UI/NewUI/Dialogs/ReconnectDialog.cpp MuMain/tests/render/test_frame_pixel_readback.cpp
git commit -m "feat(render): capture reconnect backdrop"
```

### Task 6: Run focused SDL UI validation sweep

**Files:**
- Modify only when a case fails: relevant UI implementation and adjacent test
- Create: `docs/testing/macos-runtime-validation.md`

- [ ] **Step 1: Record matrix**

Create rows for Release and Debug covering:

1. Guild window open, buttons, close, and text.
2. Friend list, friend-add prompt, submit, cancel, and reopen.
3. Chat Enter focus, typing, Escape, submit, and hotkeys after close.
4. Ground-item hover, Alt hold, and Alt toggle.
5. Music/SFX volume sliders at minimum, midpoint, maximum.
6. Render-distance slider movement and persisted reload value.
7. Forced disconnect, backdrop, cancel, and successful reconnect.

- [ ] **Step 2: Fix one failure per commit**

For each failed row: reproduce, add narrow diagnostic/test, fix root cause, rerun row, remove diagnostics, commit. Do not bundle unrelated UI fixes.

- [ ] **Step 3: Run automated suite**

Run:

```bash
cmake --build MuMain/out/build/macos-arm64 --config Debug --target Main MuMainTests -j2
ctest --test-dir MuMain/out/build/macos-arm64 -C Debug --output-on-failure
cmake --build MuMain/out/build/macos-arm64 --config Release --target Main -j2
git diff --check
```

Expected: all tests pass; both game configurations build; validation matrix has no open failures.

- [ ] **Step 4: Commit validation evidence**

```bash
git add docs/testing/macos-runtime-validation.md
git commit -m "docs(test): record macOS runtime validation"
```

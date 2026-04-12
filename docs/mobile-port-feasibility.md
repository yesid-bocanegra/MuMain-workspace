# Mobile Port Feasibility Assessment (Android / iPadOS)

> Assessment date: 2026-04-11. Based on current SDL3 migration state (Sprint 7, game playable on macOS/Linux).

## Executive Summary

The SDL3 migration completed the hardest 80% of cross-platform portability. Android and iPadOS builds are **feasible** but require **8-12 weeks** of focused work. One hard blocker (.NET Native AOT network layer) must be resolved before any mobile build can link.

**Estimated effort:** 8-12 weeks  
**Critical path:** .NET network rewrite -> Asset I/O abstraction -> Touch input

---

## What's Already Portable

These areas require zero or near-zero changes for mobile:

| Area | Details |
|------|---------|
| **SDL3 GPU Renderer** | Auto-selects Metal (iOS) / Vulkan (Android). No direct GPU API calls in app code. 45 pipelines with 9 blend modes already compiled to SPIR-V + MSL |
| **Shader Pipeline** | HLSL -> SPIR-V -> MSL toolchain already built. Mobile GPU backends covered |
| **Audio (miniaudio)** | `MiniAudioBackend.cpp` fully supports Android + iOS. DirectSound completely removed (Story 7-9-4) |
| **Threading** | `std::thread` throughout; no Win32 thread APIs in game logic |
| **Window Management** | SDL3 handles mobile fullscreen natively. 640x480 virtual coordinate scaling already in place |
| **CMake Build System** | Clean FetchContent design (glslang, spirv-cross, GLM, SDL3_ttf). Needs new toolchain files only |
| **Win32 Cleanup** | 90% complete. Remaining `#ifdef _WIN32` guards are in platform layer (`PlatformCompat.h`) |

---

## Blockers (Ranked by Severity)

### 1. .NET Native AOT Network Layer (HARD BLOCKER)

**Impact:** Game will not compile or link on Android/iOS.

The entire network layer lives in C# compiled via .NET Native AOT:
- `ClientLibrary/ConnectionManager.cs` — connection lifecycle, `[UnmanagedCallersOnly]` exports
- SimpleModulus/Xor encryption pipelines in managed code
- Packet framing and queue management

**.NET Native AOT does not support `android-arm64` or `ios-arm64` runtime identifiers** (as of .NET 10). There is no workaround — the library cannot be produced for mobile targets.

**Resolution options:**

| Option | Effort | Pros | Cons |
|--------|--------|------|------|
| **A. Rewrite in C++20** | 2-4 weeks | Eliminates .NET SDK dependency entirely; simplifies CI and build | Must exactly match server protocol (encryption, framing) |
| **B. Server-side proxy** | 1-2 weeks | No client changes needed | Adds latency; operational complexity; single point of failure |

**Recommended:** Option A. The .NET dependency is the largest remaining build complexity, and removing it benefits all platforms.

**Key files to port:**
- `ClientLibrary/ConnectionManager.cs` (146 lines) — connection lifecycle
- `ClientLibrary/Encryption/` — SimpleModulus, Xor32 encryption
- `src/source/Dotnet/Connection.h` / `.cpp` — C++ side of the interop bridge

### 2. Asset I/O Abstraction (CRITICAL)

**Impact:** Game crashes on startup when loading any `Data/` files.

All asset loading uses `_wfopen()` (20+ call sites across `Data/ZzzInfomation.cpp`, `ZzzOpenData.cpp`, `MoveCommandData.cpp`, `SkillDataLoader.cpp`, `ItemDataLoader.cpp`). These assume a traditional filesystem with path-based file access.

- **Android:** Assets live inside the APK, accessible only via `AAssetManager_open()` or SDL3's `SDL_IOFromFile()` (which handles APK assets transparently)
- **iOS:** Assets bundled in `.app` directory via `NSBundle`; traditional `fopen` works if paths resolve correctly

**Resolution options:**

| Option | Effort | Notes |
|--------|--------|-------|
| **A. Migrate to `SDL_IOFromFile()`** | 1-2 weeks | SDL3 handles Android APK assets transparently; iOS bundle paths work. Replaces `_wfopen` call sites |
| **B. Custom `IPlatformAssets` interface** | 1-2 weeks | More control, but reinvents what SDL3 already provides |
| **C. Extract assets to writable storage on first launch** | 1 week | APK -> internal storage copy; simplest but wastes storage and slows first launch |

**Recommended:** Option A. SDL3's `SDL_IOFromFile()` was designed for exactly this problem, and migrating to it aligns with the existing SDL3 strategy.

**Affected files (primary):**
- `Data/ZzzInfomation.cpp` — 9+ `_wfopen` calls
- `Data/ZzzOpenData.cpp` — 2+ calls
- `Data/MoveCommandData.cpp`, `Skills/SkillDataLoader.cpp`, `Items/ItemDataLoader.cpp`
- `RenderFX/MuRendererSDLGpu.cpp` — font path discovery (lines 388-438, hardcoded system paths)

### 3. Touch Input and Gesture Support (HIGH)

**Impact:** Game is unplayable on mobile without alternate control scheme.

`SDLEventLoop.cpp` handles only `SDL_EVENT_MOUSE_*` and `SDL_EVENT_KEY_*`. Zero `SDL_EVENT_FINGER_*` handling exists. An MMO client needs:

| Control | Desktop | Mobile Equivalent |
|---------|---------|-------------------|
| Left click | Mouse button 1 | Tap |
| Right click | Mouse button 2 | Long press |
| Camera rotation | Right-drag | Two-finger drag |
| Zoom | Mouse wheel | Pinch gesture |
| Movement | Click-to-move / WASD | Tap-to-move / virtual joystick |
| Hotkeys | Keyboard 1-9, F1-F12 | On-screen hotkey bar |
| Chat input | Physical keyboard | On-screen keyboard (SDL3 `SDL_StartTextInput()`) |

**Effort:** 2-3 weeks including UX iteration and gameplay feel testing.

**Implementation approach:**
1. Add `SDL_EVENT_FINGER_DOWN/UP/MOTION` to `SDLEventLoop.cpp`
2. Map single-touch to mouse events (tap = click, drag = mouse move)
3. Detect multi-touch gestures (pinch, two-finger drag) via touch point tracking
4. Build virtual joystick + hotkey bar UI layer
5. The existing 640x480 virtual coordinate mapping already handles screen scaling

---

## Smaller Work Items

| Item | Effort | Notes |
|------|--------|-------|
| Android NDK CMake toolchain file | 3-5 days | `cmake/toolchains/android-arm64.cmake`, new preset in `CMakePresets.json` |
| iOS/iPadOS Xcode CMake toolchain | 2-3 days | `cmake -G Xcode` with code signing configuration |
| Offline shader pre-compilation | 1-2 days | glslang/spirv-cross compile on host, ship blobs. `MU_ENABLE_SHADER_COMPILATION=OFF` already supported |
| Font bundling | 1 day | Bundle fonts in `Data/Font/` instead of searching system paths (`/System/Library/Fonts/`, etc.) |
| Safe area / notch handling | 1-2 days | `SDL_GetDisplayUsableBounds()` for UI layout offsets |
| Orientation lock | Hours | `SDL_HINT_ORIENTATIONS` — landscape-only for this game |
| HWND sentinel removal | Hours | `g_hWnd` sentinel in `MuMain.cpp` needs mobile-safe alternative |
| App lifecycle (background/resume) | 2-3 days | Handle `SDL_EVENT_DID_ENTER_BACKGROUND` / `SDL_EVENT_WILL_ENTER_FOREGROUND` for pause/save state |

---

## Proposed Timeline

```
Phase 1 — Foundation (Weeks 1-4)
  ├── C++ network layer rewrite (replace .NET AOT)         [critical path]
  ├── Android NDK + iOS toolchain setup                     [parallel]
  └── Offline shader compilation pipeline                   [parallel]

Phase 2 — Platform Integration (Weeks 3-6)
  ├── Asset I/O migration to SDL_IOFromFile()               [starts week 3]
  ├── Font bundling + path resolution                       [1 day]
  └── App lifecycle events (background/resume)              [2-3 days]

Phase 3 — Input & UX (Weeks 5-8)
  ├── Touch-to-mouse event mapping                          [2-3 weeks]
  ├── Virtual joystick + hotkey bar                         [included above]
  └── Safe area + orientation handling                      [1-2 days]

Phase 4 — Integration & Polish (Weeks 8-12)
  ├── On-device testing (Android emulator + physical)
  ├── On-device testing (iPad Simulator + physical)
  ├── Performance profiling on mobile GPUs
  └── App store packaging (APK/AAB, IPA)
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| .NET encryption port introduces protocol bugs | Medium | High | Byte-level comparison tests against existing .NET output |
| Mobile GPU tile-deferred rendering artifacts | Low | Medium | SDL3 abstracts away; depth-only passes may need review |
| Touch controls feel unnatural for MMO gameplay | Medium | High | Prototype early (Week 5); iterate with playtesters |
| Asset size exceeds mobile app store limits | Low | Medium | MU Online client is ~1.5 GB; may need asset streaming or expansion files |
| SDL3 mobile bugs on specific devices | Medium | Medium | Test on diverse Android hardware early; SDL3 is still maturing on mobile |

---

## Conclusion

The SDL3 migration was the strategic investment that makes mobile possible. The renderer, audio, threading, and window management are all portable today. The three blockers (.NET network, asset I/O, touch input) are well-scoped and solvable.

**The .NET rewrite is the gate.** Once the network layer is pure C++, the game can link on any platform SDL3 supports — Android, iOS, and potentially even WebAssembly (via Emscripten) in the future.

Estimated total: **8-12 weeks** of focused development to reach a playable mobile build.

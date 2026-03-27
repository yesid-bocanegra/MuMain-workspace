# Story Index

*Auto-generated 2026-03-24 by `reorganize-docs` workflow*

## Stories (46)

### EPIC-1 — Platform Foundation

#### 1.1 CMake Toolchains

| Key | Name | Artifacts |
|-----|------|-----------|
| [1-1-1](1-1-1-macos-cmake-toolchain/) | macOS CMake Toolchain | story, atdd, review, progress, session-summary |
| [1-1-2](1-1-2-linux-cmake-toolchain/) | Linux CMake Toolchain | story, atdd, review, progress, backend-compliance, session-summary |

#### 1.2 Platform Abstraction

| Key | Name | Artifacts |
|-----|------|-----------|
| [1-2-1](1-2-1-platform-abstraction-headers/) | Platform Abstraction Headers | story, atdd, review, progress, backend-compliance, session-summary |
| [1-2-2](1-2-2-platform-library-backends/) | Platform Library Backends | story, atdd, review, backend-compliance, session-summary |

#### 1.3 SDL3 Integration

| Key | Name | Artifacts |
|-----|------|-----------|
| [1-3-1](1-3-1-sdl3-dependency-integration/) | SDL3 Dependency Integration | story, atdd, review, backend-compliance, session-summary |

#### 1.4 Documentation

| Key | Name | Artifacts |
|-----|------|-----------|
| [1-4-1](1-4-1-build-documentation/) | Build Documentation | story, atdd, review, progress |

### EPIC-2 — SDL3 Windowing & Input

#### 2.1 Windowing

| Key | Name | Artifacts |
|-----|------|-----------|
| [2-1-1](2-1-1-sdl3-window-event-loop/) | SDL3 Window & Event Loop | story, atdd, review, progress, session-summary, validation-report |
| [2-1-2](2-1-2-sdl3-window-focus-display/) | SDL3 Window Focus & Display | story, atdd, review, progress, session-summary |

#### 2.2 Input

| Key | Name | Artifacts |
|-----|------|-----------|
| [2-2-1](2-2-1-sdl3-keyboard-input/) | SDL3 Keyboard Input Migration | story, atdd, review, session-summary |
| [2-2-2](2-2-2-sdl3-mouse-input/) | SDL3 Mouse Input Migration | story, atdd, review, progress, session-summary |
| [2-2-3](2-2-3-sdl3-text-input/) | SDL3 Text Input Migration | story, atdd, review, progress, session-summary, validation-report |

### EPIC-3 — .NET Network Bridge

#### 3.1 CMake & RID Detection

| Key | Name | Artifacts |
|-----|------|-----------|
| [3-1-1](3-1-1-cmake-rid-detection/) | CMake RID Detection | story, atdd, review, progress, session-summary |
| [3-1-2](3-1-2-connection-h-crossplatform/) | Connection.h Cross-Platform | story, atdd, review, session-summary, validation-report |

#### 3.2 Encoding

| Key | Name | Artifacts |
|-----|------|-----------|
| [3-2-1](3-2-1-char16t-encoding/) | char16_t Encoding | story, atdd, review, session-summary |

#### 3.3 Server Connectivity

| Key | Name | Artifacts |
|-----|------|-----------|
| [3-3-1](3-3-1-macos-server-connectivity/) | macOS Server Connectivity | story, atdd, review, session-summary, validation-report |
| [3-3-2](3-3-2-linux-server-connectivity/) | Linux Server Connectivity | story, atdd, review, progress, session-summary |

#### 3.4 Error Messaging & Config

| Key | Name | Artifacts |
|-----|------|-----------|
| [3-4-1](3-4-1-connection-error-messaging/) | Connection Error Messaging | story, atdd, review, progress, session-summary, validation-report |
| [3-4-2](3-4-2-server-connection-config/) | Server Connection Config | story, atdd, review, progress, session-summary |

### EPIC-4 — Rendering Migration

#### 4.1 Ground Truth

| Key | Name | Artifacts |
|-----|------|-----------|
| [4-1-1](4-1-1-ground-truth-capture/) | Ground Truth Capture | story, atdd, review, progress, session-summary |

#### 4.2 MuRenderer Abstraction

| Key | Name | Artifacts |
|-----|------|-----------|
| [4-2-1](4-2-1-murenderer-core-api/) | MuRenderer Core API | story, atdd, review, progress, session-summary, validation-report |
| [4-2-2](4-2-2-migrate-renderbitmap-quad2d/) | Migrate RenderBitmap/Quad2D | story, atdd, review, progress, session-summary |
| [4-2-3](4-2-3-migrate-skeletal-mesh/) | Migrate Skeletal Mesh | story, atdd, review, progress, session-summary |
| [4-2-4](4-2-4-migrate-trail-effects/) | Migrate Trail Effects | story, atdd, review, progress, session-summary |
| [4-2-5](4-2-5-migrate-blend-pipeline-state/) | Migrate Blend Pipeline State | story, atdd, progress, session-summary |

#### 4.3 SDL GPU Backend

| Key | Name | Artifacts |
|-----|------|-----------|
| [4-3-1](4-3-1-sdlgpu-backend/) | SDL GPU Backend | story, atdd, progress, validation-report |
| [4-3-2](4-3-2-shader-programs/) | Shader Programs | story, atdd, review, progress, session-summary |

#### 4.4 Texture System

| Key | Name | Artifacts |
|-----|------|-----------|
| [4-4-1](4-4-1-texture-system-migration/) | Texture System Migration | story, atdd, review, progress, session-summary |

### EPIC-5 — Audio Migration

#### 5.1 Audio Abstraction

| Key | Name | Artifacts |
|-----|------|-----------|
| [5-1-1](5-1-1-muaudio-abstraction-layer/) | MuAudio Abstraction Layer | story, atdd, review, progress, session-summary |

#### 5.2 Miniaudio Integration

| Key | Name | Artifacts |
|-----|------|-----------|
| [5-2-1](5-2-1-miniaudio-bgm/) | Miniaudio BGM | story, atdd, review, progress, session-summary, validation-report |
| [5-2-2](5-2-2-miniaudio-sfx/) | Miniaudio SFX | story, atdd, review, progress, session-summary |

#### 5.3 Audio Format Validation

| Key | Name | Artifacts |
|-----|------|-----------|
| [5-3-1](5-3-1-audio-format-validation/) | Audio Format Validation | story, atdd, review, progress, session-summary |

#### 5.4 Volume Controls

| Key | Name | Artifacts |
|-----|------|-----------|
| [5-4-1](5-4-1-volume-controls/) | Volume Controls | story, atdd, review, progress, session-summary |

### EPIC-6 — Cross-Platform Gameplay Validation

#### 6.1 Auth & Navigation

| Key | Name | Artifacts |
|-----|------|-----------|
| [6-1-1](6-1-1-auth-character-validation/) | Auth & Character Validation | story, atdd, review, progress, session-summary |
| [6-1-2](6-1-2-world-navigation-validation/) | World Navigation Validation | story, atdd, review, progress, session-summary |

#### 6.2 Combat & Inventory

| Key | Name | Artifacts |
|-----|------|-----------|
| [6-2-1](6-2-1-combat-system-validation/) | Combat System Validation | story, atdd, review, progress, session-summary, validation-report |
| [6-2-2](6-2-2-inventory-trading-validation/) | Inventory & Trading Validation | story, atdd, review, progress, session-summary, validation |

#### 6.3 Social & Advanced Systems

| Key | Name | Artifacts |
|-----|------|-----------|
| [6-3-1](6-3-1-social-systems-validation/) | Social Systems Validation | story, atdd, review, progress |
| [6-3-2](6-3-2-advanced-systems-validation/) | Advanced Systems Validation | story, atdd, review, progress, session-summary |

#### 6.4 UI Windows

| Key | Name | Artifacts |
|-----|------|-----------|
| [6-4-1](6-4-1-ui-windows-validation/) | UI Windows Validation | story, atdd, review, progress, session-summary |

### EPIC-7 — Cross-Platform Infrastructure

#### 7.1 Error Reporting & Signal Handlers

| Key | Name | Artifacts |
|-----|------|-----------|
| [7-1-1](7-1-1-crossplatform-error-reporting/) | Cross-Platform Error Reporting | story, atdd, review, session-summary, validation-report |
| [7-1-2](7-1-2-posix-signal-handlers/) | POSIX Signal Handlers | story, atdd, review, progress, session-summary, validation-report |

#### 7.2 Frame Time

| Key | Name | Artifacts |
|-----|------|-----------|
| [7-2-1](7-2-1-frame-time-instrumentation/) | Frame Time Instrumentation | story, atdd, review, session-summary |

#### 7.3 Stability Sessions *(Sprint 7 — planned)*

| Key | Name | Artifacts |
|-----|------|-----------|
| 7-3-1 | macOS Stability Session | *(not started)* |
| 7-3-2 | Linux Stability Session | *(not started)* |

#### 7.4 CI Runners

| Key | Name | Artifacts |
|-----|------|-----------|
| [7-4-1](7-4-1-native-ci-runners/) | Native CI Runners | story, atdd, review, progress, session-summary |

#### 7.9 macOS Game Loop & Render Path Migration

| Key | Name | Artifacts |
|-----|------|-----------|
| [7-9-1](7-9-1-macos-gameloop-render/) | macOS Game Loop & Render Path Migration | story |
| [7-9-2](7-9-2-sdl3-2d-scene-sprite-render/) | OpenGL Immediate-Mode → MuRenderer Migration | story |
| [7-9-3](7-9-3-unify-entry-point/) | Unify Entry Point — Delete WinMain | story |

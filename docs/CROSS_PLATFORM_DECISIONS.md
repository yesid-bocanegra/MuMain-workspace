# Cross-Platform Migration Decisions

This document records all research, rationale, rejected alternatives, and validation specifications for the MuMain cross-platform migration. For the implementation plan, see [CROSS_PLATFORM_PLAN.md](CROSS_PLATFORM_PLAN.md).

## Context

MuMain is a C++20 MU Online game client that currently only builds and runs on Windows (GitHub issue #59). The codebase uses OpenGL for rendering but is deeply coupled to Win32 APIs for windowing, input, audio, font rendering, and system utilities. The migration introduces **SDL3** as the platform abstraction layer and **SDL_gpu** as the rendering target, eliminating OpenGL entirely.

**Key choices:** SDL3 (not SDL2), Linux + macOS simultaneously, miniaudio replacing DirectSound + wzAudio on all platforms, SDL_gpu replacing OpenGL.

---

## Issue Register

The original plan was reviewed against the actual codebase and current library ecosystem (February 2026). Critical issues identified:

| # | Issue | Severity | Resolution |
|---|-------|----------|------------|
| 1 | macOS has no OpenGL compatibility profile for GL 3.2+ — `glBegin`/`glEnd` immediate mode (57 calls, 14 files, ~1,176 fixed-function calls, 125+ files) won't work on core profile. OpenGL itself is deprecated (last update 2017). | **Showstopper** | Use GL 2.1 legacy context as scaffolding; SDL_gpu migration eliminates OpenGL entirely |
| 2 | SDL3_mixer has no stable release (prerelease-3.1.2 RC only), not in vcpkg/Homebrew/apt, and lacks built-in 3D spatialization | **High** | Replaced with **miniaudio** (public domain, single header, native 3D spatialization, zero build complexity). See [Audio Library Research](#audio-library-research) for full analysis. |
| 3 | `wchar_t` is 4 bytes on Linux/macOS vs 2 bytes on Windows — 2,089 occurrences across 349 files; `.bmd` binary files assume 2-byte `wchar_t` | **High** | Fix C# interop boundary with `char16_t` (~10 files); fix `.bmd` loaders with `ImportChar16ToWchar` at read sites; defer full migration |
| 4 | `GetAsyncKeyState` is in 8 files (104 calls), not just `NewUICommon.cpp` | **High** | Expanded input replacement to cover all 8 files |
| 5 | `MessageBoxW` — actually 181 Win32 calls across 27 files (original 2,335 count included game's own UI system) | **High** | Inline wrapper in `PlatformCompat.h`, zero call-site changes |
| 6 | `_wfopen` doesn't exist on Linux/macOS — 60 calls across 28 files | **High** | Drop-in `mu_wfopen` wrapper with backslash normalization |
| 7 | File path backslashes hardcoded (`L"Data\\"`) — ~2,050 occurrences | **High** | Normalized inside `mu_wfopen` automatically, zero source changes |
| 8 | Case-sensitive Linux filesystem breaks asset loading | **High** | Case-folding file open with lazy directory cache |
| 9 | `DejaVuSans.ttf` has no Hangul coverage — wrong font for Korean game | **Medium** | Bundle Nanum Gothic (SIL OFL) or Source Han Sans instead |
| 10 | FreeType text metrics differ from GDI by ±1-2px at small sizes | **Medium** | Use `advance.x >> 6` (not `bitmap.width`); screenshot comparison testing |
| 11 | GLEW not actually used for any extension functions in codebase | **Medium** | Remove on non-Windows; use plain `<GL/gl.h>` + SDL3 context |
| 12 | SDL3 not in Ubuntu 24.04 LTS | **Low** | Non-issue: vcpkg/FetchContent for build; AppImage/Flatpak for distribution; Ubuntu 26.04 LTS (April 2026) ships SDL3 natively |
| 13 | ANGLE, MoltenGL, gl4es, Zink — none support immediate-mode GL | **Info** | Confirmed: no translation layer viable. SDL_gpu migration is the correct path |
| 14 | OpenGL is a dead-end API (last update 2017, deprecated on macOS) | **High** | SDL_gpu eliminates OpenGL dependency entirely |

---

## Library Decisions

| Library | Decision | Rationale |
|---------|----------|-----------|
| **SDL3** (3.4.x) | Keep | Stable since Jan 2025, zlib license, solid GL context + input + windowing |
| **SDL3_mixer** | **Replace with miniaudio** | SDL3_mixer 3.1.2 RC is usable but lacks built-in 3D spatialization, has no package manager support (vcpkg/Homebrew/apt), and adds build complexity. miniaudio is a better fit — see [Audio Library Research](#audio-library-research) |
| **miniaudio** (0.11.x) | **New: Primary audio** | Public domain/MIT-0, single file, `ma_engine` API maps 1:1 to `IPlatformAudio`, native WAV/MP3/FLAC, streaming built-in, 3D spatialization built-in. Fully independent of SDL3 — no integration or conflicts. |
| **FreeType2** (2.14.x) | Keep | Battle-tested, FTL license, everywhere via apt/brew/vcpkg |
| **SDL_gpu** (SDL3 built-in) | **New: Rendering target** | Built into SDL3 (zero new deps). Native Vulkan/Metal/D3D12 backends. Eliminates OpenGL entirely. Stable since Jan 2025. FNA ships commercial games via SDL_gpu on PC/Mac/Switch (D3D12/Xbox and PS5 backends in development). HLSL shaders cross-compiled via SDL_shadercross. |
| **GLEW** | **Remove on non-Windows** | No extension functions used in codebase. Replace with plain `<GL/gl.h>` for scaffolding. Eliminated entirely after SDL_gpu migration |
| **OpenAL Soft** | Rejected | LGPL (dynamic linking required), manual decoder integration, overkill for isometric panning |
| **SoLoud** | Rejected | Last release 2020, no vcpkg/Homebrew |
| **FMOD** | Rejected | Proprietary, incompatible with open-source project |
| **bgfx** | Rejected | Metal backend has CPU stall issues, forces threading model change, full rewrite required |
| **sokol_gfx** | Rejected | Single-developer project (bus factor 1), Vulkan backend experimental, separate dependency from SDL3 |
| **OpenGL 3.2 core** | Rejected as target | Still deprecated on macOS — migrating TO a deprecated API is not a solution |

**Removed dependencies:** GLEW (no extension functions used), SDL3_mixer (replaced by miniaudio — see [Audio Library Research](#audio-library-research)), GLM (not needed — SDL_gpu uses uniform buffers with manual matrix math).

---

## Rendering Strategy

OpenGL is a dead-end API (last spec update 2017, deprecated on macOS since 2018). All alternatives were evaluated:

| Option | Immediate Mode? | macOS Native? | Verdict |
|--------|----------------|---------------|---------|
| macOS GL 2.1 legacy context | Yes | No (deprecated GL→Metal shim) | **Scaffolding only** |
| OpenGL 3.2 core profile | N/A (removes it) | No (still deprecated) | Rejected — migrating to a deprecated target |
| **SDL_gpu** | N/A (modern API) | **Yes (native Metal)** | **Target** — built into SDL3, Vulkan/Metal/D3D12 |
| ANGLE | No (ES only) | No | Not viable — wrong API subset |
| MoltenGL | No (ES 2.0 only) | No | Not viable — commercial, semi-abandoned |
| Zink + MoltenVK | Theoretically | No (triple translation) | Not viable — experimental |
| bgfx | N/A | Yes (Metal) | Rejected — CPU stall issues, threading model change |
| sokol_gfx | Has compat layer | Yes (Metal) | Rejected — bus factor 1, Vulkan experimental |

**Adopted strategy:**
1. GL 2.1 legacy context via SDL3 (get the game running on macOS immediately)
2. Migrate rendering from OpenGL to SDL_gpu (Vulkan/Metal/D3D12). Eliminates OpenGL entirely. Native Metal performance on macOS. Uses HLSL shaders cross-compiled via SDL_shadercross.

### Codebase rendering audit

An audit of the 14 rendering files reveals the fixed-function pipeline usage is simpler than expected:

**NOT used by OpenGL (already software-computed):**
- Lighting — `BMD::Lighting()` and `BMD::Chrome()` compute per-vertex colors in software, then pass them via `glColor3f`/`glColor4f`. No `glLight*`, `glMaterial*`, or `GL_LIGHTING` calls exist. HLSL lighting shaders are not needed.
- Clip planes, point/line smoothing, multitexturing — not used anywhere

**Handled as SDL_gpu pipeline state (not shader code):**
- 6 blend modes → `SDL_GPUColorTargetBlendState` pipeline objects
- Depth test modes (LEQUAL, LESS, ALWAYS) → `SDL_GPUDepthStencilState`
- Stencil ops (INCR/DECR/KEEP for shadow volumes) → `SDL_GPUStencilOpState`
- Face culling and winding order → `SDL_GPURasterizerState`
- Color mask (shadow volume passes) → `SDL_GPUColorTargetDescription`

**Requires shader implementation:**

| Feature | Scope | HLSL work |
|---------|-------|-----------|
| Vertex transformation (MVP matrix) | All shaders | ~10 lines per vertex shader |
| Texture sampling × vertex color | basic_textured fragment | `return tex.Sample(s, uv) * vertexColor;` — 1 line |
| Alpha discard | basic_textured fragment | `if (color.a <= threshold) discard;` — 1 line. Thresholds: 0.25 and 0.0 |
| Fog (GL_LINEAR) | basic_textured fragment | `lerp(color, fogColor, fogFactor)` — 3 lines. 8 calls total |
| Chrome/reflection UV generation | Computed in C++ (`BMD::Chrome()`), not GL | **Zero shader work** — already software-computed |

**Total HLSL: ~100-150 lines across 5 shader programs.** The shaders themselves are trivial.

### Required shaders (minimal set)

- **basic_colored** — flat colored geometry (UI lines, debug primitives, SceneManager fades)
- **basic_textured** — textured quads with vertex color multiply, optional alpha discard, optional fog (sprites, UI elements, terrain, water, effects, hair — covers ~80% of rendering)
- **model_mesh** — identical to basic_textured but for `glDrawArrays` path in ZzzBMD.cpp (can share fragment shader)
- **shadow_volume** — transform-only vertex shader, no fragment output (color mask off during stencil passes)
- **shadow_apply** — fullscreen quad with semi-transparent shadow color output

### Per-file GL feature usage

| File | Texturing | Vertex Color | Blend Modes | Stencil | Notes |
|------|-----------|-------------|-------------|---------|-------|
| `ZzzOpenglUtil.cpp` | Yes (41) | Yes (20) | 6 modes + fog | Clear only | Central utility — cascades to 100+ files |
| `Sprite.cpp` | Yes (1) | Yes (2) | None | No | Simple TRIANGLE_FAN, `glColor4ub` |
| `ZzzLodTerrain.cpp` | Yes (27) | Yes (35) | Alpha test | No | TRIANGLE_FAN terrain strips |
| `CSWaterTerrain.cpp` | Yes (3) | Yes (6) | Alpha blend | No | TRIANGLES water effect |
| `ZzzBMD.cpp` | Yes (33) | Yes (42) | Alpha + minus | Yes (3) | Largest file: meshes, chrome, waves, bounding boxes |
| `ZzzObject.cpp` | Yes (24) | Yes (76) | Alpha test | No | Heavy vertex color, debug LINES |
| `ZzzEffectJoint.cpp` | Yes (20) | Yes (16) | Alpha + minus | No | QUADS trail effects |
| `ZzzEffectBlurSpark.cpp` | Yes (10) | Yes (6) | Alpha + minus | No | TRIANGLE_FAN + QUADS |
| `ZzzEffectMagicSkill.cpp` | Yes (2) | Yes (2) | None | No | Minimal, QUADS only |
| `ShadowVolume.cpp` | No | ColorMask | Minus | Yes (9) | Two-pass stencil INCR/DECR + shadow apply |
| `SideHair.cpp` | Yes (16) | Yes (5) | Minus | No | QUADS, `glColor4ub` |
| `SceneManager.cpp` | No | Yes (5) | Basic | No | Minimal, scene fades |
| `PhysicsManager.cpp` | Yes (1) | Yes (4) | None | No | Debug QUADS only |
| `CameraMove.cpp` | No | Yes (2) | None | No | Debug LINE_STRIP |

### Rendering duplication analysis

| Pattern | Files | Instances | LOC wasted |
|---------|-------|-----------|------------|
| 9 `RenderBitmap*` variants (same quad with different params) | ZzzOpenglUtil.cpp | 9 functions | ~250 |
| 7 `Enable*Blend` functions (same structure, different enum) | ZzzOpenglUtil.cpp, called from 7+ files | 7 functions | ~140 |
| Effect quad rendering (95% identical) | ZzzEffectJoint, ZzzEffectBlurSpark, ZzzEffectMagicSkill | 10+ functions | ~120 |
| Terrain `RenderFace*` variants | ZzzLodTerrain.cpp | 4 functions | ~50 |
| Debug draw (colored quads/lines) | PhysicsManager, CameraMove, ZzzObject, ShadowVolume | 6 functions | ~50 |
| **Total** | **14 files** | **111 glBegin sites** | **~600 LOC** |

### SDL_gpu concept mapping

| OpenGL pattern | SDL_gpu replacement |
|---------------|---------------------|
| `glBegin`/`glEnd` | `SDL_GPUCommandBuffer` + `SDL_GPURenderPass` with vertex buffers |
| `glVertex3f`/`glTexCoord2f` | Vertex buffer data uploaded via `SDL_UploadToGPUBuffer` |
| `glBindTexture` | `SDL_BindGPUFragmentSamplers` |
| `glMatrixMode`/`glTranslatef`/`glRotatef` | Uniform buffer with projection/view/model matrices |
| `glOrtho`/`glFrustum` | Manual matrix math in uniform buffers |
| `glEnable(GL_BLEND)` | `SDL_GPUColorTargetBlendState` in pipeline creation |
| `glEnable(GL_DEPTH_TEST)` | `SDL_GPUDepthStencilState` in pipeline creation |
| Stencil operations (shadow volumes) | `SDL_GPUStencilOpState` in pipeline |

### Effort estimate

| Work item | Scope | Effort |
|-----------|-------|--------|
| **MuRenderer abstraction layer** (OpenGL backend) | Consolidate 111 sites → ~5 functions, pure refactor | 2-3 weeks |
| HLSL shaders + SDL_shadercross CMake integration | ~150 lines HLSL, build pipeline | 1 week |
| Matrix math utility (replace GL matrix stack) | ~300 lines C++, 200+ call sites | 2-3 weeks |
| **Swap MuRenderer backend to SDL_gpu** | ~5 functions to reimplement | 2-3 weeks |
| Pipeline state objects (replace blend/depth/stencil) | 6 blend pipelines + depth/stencil variants | 1 week |
| Shadow volume stencil rewrite | ShadowVolume.cpp + ZzzBMD.cpp | 1 week |
| SDL_gpu device init + swap chain setup | Replace SDL_GL_CreateContext | 1 week |
| ImGui backend swap (`imgui_impl_sdlgpu3.cpp`) | Drop-in replacement | 1 day |
| Testing and visual parity validation | Screenshot comparison across all scenes | 1-2 weeks |
| **Total** | | **10-16 weeks** |

The abstraction layer adds 2-3 weeks upfront but reduces SDL_gpu backend work from 3-5 weeks (111 sites) to 2-3 weeks (~5 functions). Net cost is ~0, with far better code quality.

---

## Audio Library Research

SDL3_mixer is the native SDL3 audio library. Replacing it with a third-party library (miniaudio) is a meaningful decision that deserves thorough justification beyond "it's prerelease."

### SDL3_mixer status (February 2026)

- **Version:** 3.1.2 RC ([released January 22, 2026](https://github.com/libsdl-org/SDL_mixer/releases/tag/prerelease-3.1.2)) — first release candidate for SDL_mixer 3.0
- **API:** Complete rewrite from scratch (not an evolution of SDL2_mixer). Introduces `MIX_Mixer`, `MIX_Track`, `MIX_Audio` objects. API "finalized" since July 2025 — shape is locked, breakage unlikely at RC stage.
- **Package managers:** Not in vcpkg, Homebrew, or apt. Gentoo has an ebuild. Must build from source via FetchContent or git submodule.
- **Stable release:** No announced date. Pattern (API finalized July 2025 → RC January 2026) suggests first half of 2026, but SDL team does not commit to timelines.
- **Community adoption:** Minimal. [Lazy Foo SDL3 tutorial](https://lazyfoo.net/tutorials/SDL3/15-sound-effects-and-music/index.php) demonstrates usage from source. Few production projects have shipped with it.

### Does miniaudio need SDL3 integration?

**No.** miniaudio is fully self-contained with zero dependencies. It has its own audio device layer (WASAPI on Windows, CoreAudio on macOS, PulseAudio/ALSA on Linux). You skip `SDL_INIT_AUDIO` and there are no conflicts — SDL3's windowing/GPU and miniaudio's audio operate on completely separate OS subsystems.

SDL3's audio subsystem explicitly supports [multiple independent device opens](https://wiki.libsdl.org/SDL3/CategoryAudio), so even if both were initialized, they would not interfere. miniaudio's repository includes an [official `engine_sdl.c` example](https://miniaud.io/docs/examples/engine_sdl.html) demonstrating two coexistence models:

- **Model A (recommended for MuMain):** miniaudio owns its own audio device. SDL3 handles windowing/rendering. No coupling, no conflicts, simplest approach.
- **Model B:** SDL3 owns the audio device via `SDL_INIT_AUDIO`. miniaudio runs without its device layer (`#define MA_NO_DEVICE_IO`). SDL3's callback pulls PCM frames from miniaudio via `ma_engine_read_pcm_frames()`. Tighter integration but unnecessary for MuMain.

### Head-to-head comparison for MuMain

| Feature | miniaudio 0.11.x | SDL3_mixer 3.1.2 RC |
|---------|-------------------|---------------------|
| **3D spatialization** | **Built-in:** `ma_sound_set_position()`, listener model, distance attenuation, Doppler | **Not built-in.** SDL3_mixer is a 2D mixer. Manual distance/panning calculation required (~50 lines). |
| **WAV playback** | Built-in `dr_wav` | Built-in |
| **MP3 streaming** | Built-in `dr_mp3`, `MA_SOUND_FLAG_STREAM` | Built-in |
| **OGG Vorbis** | Via vendored `stb_vorbis` | Built-in (vendored ogg/vorbis) |
| **FLAC** | Built-in `dr_flac` | Built-in (vendored FLAC) |
| **Polyphonic SFX** | Multiple `ma_sound` instances per ID | `MIX_Track` with `MIX_PlayAudio` auto-allocation |
| **Release status** | Stable, production-proven (SFML 3, Open 3D Engine) | RC prerelease, minimal production usage |
| **Build complexity** | Single `.h` file + one `.c` with `#define MINIAUDIO_IMPLEMENTATION` | CMake FetchContent from source; brings vendored codec libs |
| **Package managers** | vcpkg (also trivially vendored) | Not in vcpkg, Homebrew, or apt |
| **SDL3 integration** | Independent — no integration needed, no conflicts | Native — shares SDL3 audio device, error handling, threading |
| **License** | Public domain / MIT-0 | zlib |
| **API maturity** | Stable, well-documented | New architecture, sparse documentation |

### Advantages of staying in the SDL3 ecosystem

SDL3_mixer does have real benefits:
- **Unified audio device management** — shares SDL3's device infrastructure (enumeration, hotplug, switching)
- **Consistent threading model** — follows SDL3's conventions
- **Shared build patterns** — same CMake approach as SDL3
- **Shared error handling** — `SDL_GetError()` works across all SDL3 libraries

However, these advantages are modest for MuMain. The audio system is isolated behind an `IPlatformAudio` interface. The game does not need device hotplug, runtime device switching, or tight audio-rendering coupling. The abstraction layer means the audio backend is replaceable regardless of which library is chosen.

### Could we just wait for SDL3_mixer stable?

**Yes, but it doesn't change the calculus:**

- No announced stable release date — could be months
- The stable release still won't have built-in 3D spatialization
- Package manager support may lag further behind the stable release
- The RC API is unlikely to break (finalized July 2025), so waiting doesn't reduce API risk significantly

The prerelease status is a secondary concern. An RC from a well-maintained project like SDL is not unreliable. The primary issues are the missing 3D audio and the build complexity of a library with no package manager support.

### Why miniaudio wins for MuMain

Ranked by importance:

1. **Native 3D spatialization.** MuMain is an isometric game with positional audio (NPC sounds, skill effects, environmental audio). miniaudio handles this natively with `ma_sound_set_position()` and `ma_engine_listener_set_position()`. SDL3_mixer requires ~50 lines of manual distance/angle/panning calculations per update.

2. **Zero build complexity.** A single vendored `.h` file versus building an external library from source with no package manager support. In a project already managing SDL3 + FreeType + libjpeg-turbo + SDL_shadercross, minimizing dependency build complexity matters.

3. **Stable, released, proven software.** miniaudio 0.11.x is used in production by SFML 3, Open 3D Engine, and many indie games. SDL3_mixer 3.0 has not shipped a stable release and has minimal community adoption.

4. **Simpler API for this use case.** `ma_engine` + `ma_sound` is a more natural fit than SDL3_mixer's mixer/track/audio architecture for a game that needs "play this WAV at this 3D position."

### Revisit condition

SDL3_mixer would be worth revisiting if a future version adds built-in 3D spatialization AND reaches stable release in package managers. Neither is expected in the near term. The `IPlatformAudio` interface makes a future swap isolated to one file if circumstances change.

---

## Ground Truth Capture Specification

**Goal:** Capture exact baseline behavior from the Windows build BEFORE code changes, creating automated validation data. Phase 9 of the implementation plan captures the essential subset (#1, #2, #10). This section documents the full aspirational spec.

### What to capture

| # | Capture | How | Storage | Validates |
|---|---------|-----|---------|-----------|
| 1 | **Screenshots of ALL UI screens** — every one of the 80+ `CNewUI*` windows, login scene, character select, in-game with default HUD, and every multi-window combination at 640x480, 800x600, 1024x768 | Automate: iterate `CNewUIManager` registered windows, `Show()` each one → `glReadPixels` + PNG + SHA256. Also capture common multi-window states. | `tests/golden/screenshots/*.png` + `.sha256` | Rendering parity, font rendering, design reference |
| 2 | **Text metrics** for all 4 fonts (`g_hFont`, `g_hFontBold`, `g_hFontBig`, `g_hFixFont`) — pixel width/height of reference strings + `CutStr()` word-wrap break points | `GetTextExtentPoint32` on test strings, dump to JSON | `tests/golden/text_metrics.json` | FreeType must match GDI within ±2px |
| 3 | **Audio catalog** — every loaded WAV: filename, sample rate, channels, bit depth, file size + SHA256 of first 1 second of decoded PCM | Instrument `DirectSoundManager::CreateStaticBuffer` | `tests/golden/audio/audio_catalog.csv` | miniaudio must decode identically |
| 4 | **Key mapping table** — all VK_* constants used, numeric values, game action each triggers | Static extraction from input files | `tests/golden/input_mapping.json` | SDL3 scancode→VK mapping completeness |
| 5 | **BMD text fields** — parsed bone names, texture filenames, hex dump of text regions from ALL .bmd files loaded during a play session | Instrument `BMD::Load()` to dump text fields | `tests/golden/bmd/{filename}.txt` | `ImportChar16ToWchar` correctness |
| 6 | **Packet string boundaries** — every `const wchar_t*` field in packet structs: offset, max length, encoding | Static extraction from `PacketBindings_*.h` + `PacketFunctions_*.h` | `tests/golden/network/packet_structure.json` | `char16_t` interop correctness |
| 7 | **Config round-trip** — all INI sections, keys, types, defaults, current values + write→read verification | Instrument `GameConfig::Load()`/`Save()` | `tests/golden/config/config_schema.json` | INI parser replacement |
| 8 | **File access trace** — every `_wfopen` call: path, mode, success/failure, case-corrected path | Wrap `_wfopen` with logging | `tests/golden/file_access.log` | `mu_wfopen` normalization + case folding |
| 9 | **UI layout dump for ALL screens** — for every registered `CNewUI*` window: element position, size, class name, layer depth, children | Instrument `CNewUIManager` — `Show()` → dump tree → `Hide()` | `tests/golden/ui_layouts/{ClassName}.json` | Font metrics, text input, design reference |
| 10 | **GL state snapshots** — blend mode, depth func, stencil state, bound texture, viewport, matrix values at 3 points per frame (after terrain, after models, after UI) | `glGet*` queries at instrumentation points in `SceneManager.cpp` | `tests/golden/opengl/gl_state_*.txt` | SDL_gpu pipeline state equivalence |

### Capture instrumentation

Add `src/source/Platform/GroundTruthCapture.h` with:
- `void InitGroundTruthCapture()` — called once at startup, opens log files
- `void CaptureScreenshot(const char* sceneName)` — called via hotkey or at scene transitions
- `void CaptureTextMetrics()` — called once after fonts are created
- `void CaptureGLState(const char* label)` — called at render checkpoints
- `void FinalizeGroundTruthCapture()` — called at shutdown, closes files

Enable via compile flag: `-DENABLE_GROUND_TRUTH_CAPTURE`. Does not ship in release builds.

### Capture session procedure

1. Build Windows debug with `-DENABLE_GROUND_TRUTH_CAPTURE`
2. Launch game → login screen renders → screenshot + UI layout auto-captured
3. Navigate to character select → auto-captured
4. Enter game at Lorencia → auto-captured (terrain, models, default HUD)
5. **Automated UI sweep:** press capture hotkey → iterates all 80+ registered `CNewUI*` windows: `Show()` → wait 1 frame → `glReadPixels` + PNG + SHA256 + UI layout JSON → `Hide()`
6. **Multi-window combinations:** capture common layouts (inventory+shop, character+party, chat+inventory)
7. Walk around (triggers sound effects + 3D audio) → audio catalog builds
8. Type in chat → text metrics captured
9. Close game → file access trace + config round-trip finalized
10. Commit `tests/golden/` to repository

The automated sweep at step 5 means **every UI screen is captured** regardless of whether we know its importance upfront.

---

## Key Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Apple removes GL 2.1 from macOS | High | SDL_gpu migration eliminates OpenGL entirely; GL 2.1 is temporary scaffolding only |
| SDL_shadercross build pipeline complexity | Medium | Well-documented SDL3 companion tool; HLSL is single source language; build-time compilation |
| VK_* keycode mapping bugs | High | Build comprehensive mapping table; test all 88 files' key usage |
| `wchar_t` 2-byte vs 4-byte at C# boundary | High | Fix with `char16_t` at interop; BMP-only cast is safe |
| `wchar_t` in `.bmd` binary files | High | Fix with `ImportChar16ToWchar` at load sites |
| Case-sensitive file paths on Linux | High | Case-folding open with directory cache in `PlatformCompat.h` |
| Font rendering metric differences | Medium | Calibration testing; use `advance.x >> 6` not `bitmap.width` |
| GL 2.1 performance on Apple Silicon (Phase 1 only) | Medium | Apple's GL→Metal translation acceptable for isometric game; temporary until Phase 2 |
| miniaudio 3D audio fidelity vs DirectSound | Low | Isometric game uses basic distance+angle; inverse attenuation is equivalent |

---

## New Dependencies

| Library | Purpose | License | Phase | Distribution |
|---------|---------|---------|-------|-------------|
| SDL3 (3.4.x) | Window, input, GL context, GPU rendering via SDL_gpu | zlib | 1, 2 | vcpkg, Homebrew, apt (25.04+) |
| SDL_shadercross | HLSL → SPIR-V/MSL/DXIL shader cross-compilation | zlib | 2 | Built with SDL3 or standalone |
| miniaudio (0.11.x) | Audio (effects + music + 3D), replaces DirectSound + wzAudio | Public domain / MIT-0 | 3 | Vendored (single header) |
| stb_vorbis | OGG Vorbis decoding for miniaudio | Public domain | 3 | Vendored (single file) |
| FreeType2 (2.14.x) | Font rendering, replaces GDI | FreeType License (BSD-like) | 4 | vcpkg, Homebrew, apt |
| Nanum Gothic | Korean-capable TTF font | SIL Open Font License | 4 | Vendored |

### Ubuntu LTS note

SDL3 is not in Ubuntu 24.04 apt but this is a non-issue:
- **For builds:** vcpkg or FetchContent handles it on any distro
- **For distribution:** AppImage/Flatpak bundle their own SDL3; Freedesktop SDK 25.08 runtime includes SDL3 for Flatpak
- **Timeline:** Ubuntu 26.04 LTS (April 2026) ships SDL3 natively in apt
- **Binary portability:** SDL3 only links glibc directly; X11/Wayland/ALSA/PipeWire are dlopen'd at runtime

---

## Verification Strategy

### Ground truth regression (against `tests/golden/`)

| Test | Phase | Golden file | Method |
|------|-------|-------------|--------|
| File access parity | 0 | `file_access.log` | All paths open successfully via `mu_wfopen` on Linux/macOS |
| Config round-trip | 5 | `config/config_schema.json` | INI parser reads same values for all keys |
| Text metric parity | 4 | `text_metrics.json` | FreeType `MeasureText` within ±2px of GDI |
| Word wrap parity | 4 | `text_metrics.json` | `CutStr()` breaks at same positions (±1 char) |
| Audio decode parity | 3 | `audio/audio_catalog.csv` | miniaudio PCM SHA256 matches DirectSound |
| Key mapping completeness | 1 | `input_mapping.json` | SDL3 scancode→VK table covers every VK_* code |
| BMD text parsing | 5 | `bmd_text_dump.txt` | `ImportChar16ToWchar` produces identical strings |
| Packet string encoding | 5 | `network/packet_structure.json` | `char16_t` boundary produces identical bytes |
| Screenshot parity | 1, 2 | `screenshots/*.sha256` | Pixel diff within threshold |
| UI layout parity | 4, 6 | `ui_layouts/*.json` | Element positions within ±2px |
| GL state equivalence | 2 | `opengl/gl_state_*.txt` | SDL_gpu pipeline states equivalent |

### Automated CI tests

| Test | Phase | Method |
|------|-------|--------|
| VK_* mapping covers all 87 keys | 1 | Unit test: mapping table completeness |
| Path normalization `\` → `/` | 0 | Unit test: `WcharPathToUtf8` output |
| Case-insensitive file open | 0 | Unit test: create file, open with different case |
| `char16_t` serialization matches Windows `wchar_t` | 5 | Unit test: round-trip Korean/Latin strings |
| `ImportChar16ToWchar` correctness | 5 | Unit test: known .bmd byte sequences |
| FreeType `MeasureText` vs known GDI widths | 4 | Unit test: compare pixel widths |
| INI parser round-trip | 5 | Unit test: read/write cycle |
| WAV loader produces identical PCM | 3 | Unit test: compare miniaudio output |
| SDL_shadercross compiles all HLSL shaders | 2 | CI: shader compilation as build step |
| SDL_gpu renders basic textured quad | 2 | Unit test: render to offscreen target |
| Windows build still compiles | All | CI: `cmake --preset windows-x64 && cmake --build` |

### Manual tests

| Test | Phase | What to check |
|------|-------|---------------|
| Window opens and renders | 1 | 3D scene visible, correct colors/textures |
| Mouse click targets correct position | 1 | Click UI buttons, verify hit detection |
| Double-click works | 1 | Double-click inventory items |
| Mouse wheel scrolls | 1 | Scroll chat, inventory |
| All keyboard shortcuts | 1 | F1-F12, arrows, Ctrl+combos, Enter, Escape, Tab |
| Font rendering fidelity | 4 | Screenshot comparison at 800x600, 1024x768, 1920x1080 |
| Korean text renders (not tofu) | 4 | Display Hangul strings in chat/UI |
| Sound effects play | 3 | Attack, skill cast, item pickup |
| Music loops without gap | 3 | Background music seamless looping |
| 3D audio panning | 3 | Walk around NPCs with sound sources |
| Chat text input | 6 | Type in chat box, cursor, selection, backspace |
| Login screen full flow | 8 | Enter credentials, connect, character select |
| Fullscreen toggle | 1 | Switch windowed/fullscreen |
| SDL_gpu rendering parity | 2 | Identical on Vulkan/Metal/D3D12 vs GL 2.1 reference |
| Shadow volumes via stencil | 2 | Shadows render correctly under SDL_gpu stencil pipeline |
| Config persistence | 5 | Change settings, restart, verify saved |

### Integration tests (requires server)

| Test | Phase | What to check |
|------|-------|---------------|
| Server connection from Linux/macOS | 8 | Connect via .NET bridge |
| Character movement syncs | 8 | Move character, verify server sees position |
| Chat messages round-trip | 8 | Send/receive including Korean characters |
| Game shop loads | 5 | Open in-game shop, verify item list |

---

## UI System Architecture Reference

For Phase 10 (UI Design Reference Capture):

| Property | Value |
|----------|-------|
| Logical resolution | **640x480** (fixed, no dynamic scaling) |
| Standard window size | **190x429px** (inventory, shop, stats, party) |
| Message box size | **230x145px** |
| Inventory grid cell | **20x20px** |
| Coordinate system | Absolute pixels, top-left origin |
| Z-ordering | Float layer depth (2.4 → 10.6) |
| Total UI screens | **80+** across 6 categories |
| Total UI classes | **84 CNewUI* classes** + 27 legacy classes |
| Texture assets | **761 files** in `Data/Interface/` (`newui_*.tga/jpg`) |

### Screen categories

**Inventory & Equipment (6 screens):** CNewUIMyInventory, CNewUIStorageInventory, CNewUIStorageInventoryExt, CNewUINPCShop, CNewUIMyShopInventory, CNewUIMixInventory

**Character & Stats (5 screens):** CNewUICharacterInfoWindow, CNewUIPetInfoWindow, CNewUIMasterLevel, CNewUIBuffWindow, CNewUISkillList

**Quests & Events (15+ screens):** CNewUINPCQuest, CNewUIQuestProgress, Blood Castle, Devil Square, Chaos Castle, Cursed Temple, Cry Wolf, Kanturu, Doppelgänger, Empire Guardian (each 1-3 screens)

**Social & Communication (8 screens):** CNewUIChatLogWindow, CNewUIChatInputBox, CNewUIFriendWindow, CNewUIPartyInfoWindow, CNewUIPartyListWindow, CNewUIGuildMakeWindow, CNewUIGuildInfoWindow, CNewUIGensRanking

**Commerce (4 screens):** CNewUITrade, CNewUIInGameShop, CNewUIRegistrationLuckyCoin, CNewUIExchangeLuckyCoin

**System & HUD (10+ screens):** CNewUIMainFrameWindow, CNewUIOptionWindow, CNewUIMiniMap, CNewUICommonMessageBox, CNewUICustomMessageBox, Help, Window Menu, Commands

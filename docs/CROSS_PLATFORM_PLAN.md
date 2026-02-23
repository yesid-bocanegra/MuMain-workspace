# MuMain Cross-Platform Implementation Plan

Pure implementation spec for porting MuMain to Linux and macOS via SDL3. For research, rationale, rejected alternatives, and full validation specifications, see [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md).

## Iteration Safety Rules

These rules apply to **every session** in this plan:

1. **Never modify Windows behavior + add Linux behavior in the same session.** One change type per session.
2. **Each session leaves the Windows x64 build compilable.** This is the invariant — verified by CI.
3. **Use `#ifdef` wrappers in platform headers** (`PlatformCompat.h`, `PlatformTypes.h`), not scattered `#ifdef` at individual call sites.
4. **Git branch before each session.** The branch is the rollback boundary. If a session fails, revert to the branch point.
5. **Additive sessions before substitutive sessions.** Create new files before modifying existing ones.

## Session Template

Every session follows this format:

```
### Session X.Y: [Name]
**Scope:** What to do / what NOT to do
**Create:** New files
**Modify:** Existing files
**Accept:** Specific command or assertion
**Invariant:** Windows x64 build compiles
```

## Phase Overview

| Phase | Name | Sessions | Depends On |
|-------|------|----------|------------|
| 0 | Platform Compatibility Headers & Build | 7 | — |
| 1 | SDL3 Window, Input & Main Loop | 8 | Phase 0 |
| 2 | SDL_gpu Migration | 10 | Phase 1 |
| 3 | Audio System (miniaudio) | 4 | Phase 1 |
| 4 | Font Rendering (FreeType) | 5 | Phase 1 |
| 5 | Config, Encryption & System Utilities | 6 | Phase 0 |
| 6 | Text Input & IME | 3 | Phase 1 |
| 7 | ImGui Editor | 2 | Phase 1 |
| 8 | .NET Native AOT Cross-Platform | 3 | Phase 0 |
| 9 | CI/CD, Packaging & Ground Truth Essentials | 5 | All others |
| 10 | UI Design Reference Capture | 5 | None (parallel) |

---

## Phase 0: Platform Compatibility Headers & Build

**Goal:** Make the header chain conditionally compile on non-Windows, unblocking all subsequent phases.

### Session 0.1: PlatformTypes.h

**Scope:** Create `PlatformTypes.h` with Windows type aliases (`HWND`, `HDC`, `HGLRC`, `HFONT`, `BOOL`, `DWORD`, `BYTE`, `WORD`, `POINT`, `RECT`, `SIZE`, `HANDLE`, `HINSTANCE`, `LPARAM`, `WPARAM`, `LRESULT`, `HRESULT`, `MAX_PATH`, `TRUE`/`FALSE`, `LOWORD`/`HIWORD`, `ZeroMemory`, etc.) as typedefs/defines on non-Windows. On Windows, this header is a no-op. Do NOT modify any existing files.

**Create:** `src/source/Platform/PlatformTypes.h`
**Modify:** None
**Accept:** `g++ -fsyntax-only -std=c++20 PlatformTypes.h` compiles on Linux/macOS
**Invariant:** Windows x64 build compiles

### Session 0.2: PlatformKeys.h

**Scope:** Create `PlatformKeys.h` defining all ~40 `VK_*` constants used across the codebase (`VK_LBUTTON` through `VK_NUMPAD9`, `VK_F1`-`VK_F12`, `VK_CONTROL`, `VK_SHIFT`, `VK_MENU`, `VK_RETURN`, `VK_ESCAPE`, `VK_TAB`, `VK_SPACE`, `VK_INSERT`, `VK_DELETE`, `VK_HOME`, `VK_END`, `VK_PRIOR`, `VK_NEXT`, arrows). Uses Windows numeric values. Only active on `#ifndef _WIN32`. Do NOT modify any existing files.

**Create:** `src/source/Platform/PlatformKeys.h`
**Modify:** None
**Accept:** Header compiles standalone; grep confirms all VK_* constants used in codebase are defined
**Invariant:** Windows x64 build compiles

### Session 0.3: PlatformCompat.h

**Scope:** Create `PlatformCompat.h` with drop-in replacements requiring zero call-site changes. Do NOT modify any existing files.

Contents:
- **MessageBoxW wrapper** (~80 lines): `MB_OK` → `SDL_ShowSimpleMessageBox`, `MB_YESNO` → `SDL_ShowMessageBox` with custom buttons. Handles `IDOK`, `IDYES`, `IDNO`. UTF-32 `wchar_t` → UTF-8 conversion. `#define MessageBox MessageBoxW` for UNICODE compat.
- **`_wfopen` / `_wfopen_s` wrapper** (~40 lines): Converts `wchar_t*` path to UTF-8, normalizes `\` → `/` during conversion (fixes ~2,050 hardcoded backslash paths). Case-insensitive fallback via `std::filesystem::directory_iterator` with lazy per-directory cache. `#define _wfopen mu_wfopen` for drop-in replacement.
- **Flag constants:** `MB_OK`, `MB_YESNO`, `MB_OKCANCEL`, `MB_ICONERROR`, `MB_ICONWARNING`, `MB_ICONSTOP`, `MB_ICONINFORMATION`, `IDOK`, `IDCANCEL`, `IDYES`, `IDNO`

**Create:** `src/source/Platform/PlatformCompat.h`
**Modify:** None
**Accept:** Header compiles standalone on Linux; backslash normalization unit test passes (`L"Data\\Local\\Item"` → `"Data/Local/Item"`)
**Invariant:** Windows x64 build compiles

### Session 0.4: StringConvert.h

**Scope:** Create `StringConvert.h` with `wchar_t` conversion utilities for the 2-byte vs 4-byte difference. Do NOT modify any existing files.

```cpp
std::string WcharToUtf8(const wchar_t* w);
std::u16string WcharToU16(const wchar_t* w);
void ImportChar16ToWchar(wchar_t* dst, const uint8_t* src, int srcBytes);
```

All conversions are BMP-safe (MU Online text is entirely Basic Multilingual Plane).

**Create:** `src/source/Platform/StringConvert.h`
**Modify:** None
**Accept:** Unit test: Korean string round-trip `wchar_t` → UTF-8 → `wchar_t` matches; `ImportChar16ToWchar` produces correct `wchar_t` from known UTF-16LE bytes
**Invariant:** Windows x64 build compiles

### Session 0.5: stdafx.h + Winmain.h modifications

**Scope:** Modify `stdafx.h` and `Winmain.h` with platform conditionals. Do NOT modify any other files.

Changes to `stdafx.h`:
- Wrap `#include <windows.h>`, `<winsock2.h>`, `<mmsystem.h>`, `<shellapi.h>` in `#ifdef _WIN32`
- Wrap `<tchar.h>`, `<mbstring.h>`, `<conio.h>` in `#ifdef _WIN32`
- Add `PlatformTypes.h`, `PlatformKeys.h`, `PlatformCompat.h` in the `#else` branch
- Fix OpenGL includes: `<gl/glew.h>` → `<GL/gl.h>` on non-Windows (GLEW not needed)
- Wrap `#pragma warning` directives in `#ifdef _MSC_VER`

Changes to `Winmain.h`:
- Wrap `WM_RECEIVE_BUFFER`, `WM_NPROTECT_EXIT_TWO` in `#ifdef _WIN32` (depend on `WM_USER`)
- Wrap `FAKE_CODE` macro in `#ifdef _MSC_VER` (uses `_asm`)

**Create:** None
**Modify:** `src/source/stdafx.h`, `src/source/Winmain.h`
**Accept:** Both headers compile on Windows with identical behavior; non-Windows path resolves all platform headers
**Invariant:** Windows x64 build compiles

### Session 0.6: Wrap Windows-only source files

**Scope:** Wrap the entire body of 6 pure Win32 files in `#ifdef _WIN32`. Do NOT change any logic within these files.

Files:
- `src/source/DSplaysound.cpp` (DirectSound)
- `src/source/DSwaveIO.cpp` (MMIO wave I/O)
- `src/source/Utilities/Log/WindowsConsole.cpp`
- `src/source/Utilities/CpuUsage.cpp` (GetProcessTimes)
- `src/source/ExternalObject/Leaf/regkey.h` (Registry)
- `src/source/ExternalObject/Leaf/CBTMessageBox.h` / `CBTMessageBox.cpp` (Win32 hooks)

**Create:** None
**Modify:** All 7 files listed above
**Accept:** All modified files compile on Windows with no behavioral change; grep confirms each file has `#ifdef _WIN32` wrapping
**Invariant:** Windows x64 build compiles

### Session 0.7: CMakeLists.txt + CMakePresets + vcpkg

**Scope:** Add cross-platform CMake configuration, presets, and dependency management. Do NOT change Windows build behavior.

Changes to `src/CMakeLists.txt`:
- Add `find_package(SDL3 REQUIRED)` for non-Windows
- Add `find_package(OpenGL REQUIRED)` for non-Windows (no GLEW)
- Add Linux/macOS link block: `SDL3::SDL3`, `OpenGL::GL`, `pthread`, `dl`, `m`
- Remove `WIN32_EXECUTABLE TRUE` for non-Windows
- Add asset copying for non-Windows builds

New presets in `CMakePresets.json`:
- `linux-x64` (Ninja Multi-Config)
- `macos-arm64` / `macos-x64` (Ninja Multi-Config)

Dependency management via `vcpkg.json`:
```json
{ "dependencies": ["sdl3", "freetype", "libjpeg-turbo"] }
```

Alternative: CMake FetchContent for SDL3 (builds as part of configure, no apt/vcpkg needed).

miniaudio is vendored (single header), not a vcpkg/FetchContent dependency.

**Create:** `vcpkg.json`
**Modify:** `src/CMakeLists.txt`, `CMakePresets.json`
**Accept:** `cmake --preset linux-x64` configures without errors (on Linux); Windows preset unchanged
**Invariant:** Windows x64 build compiles

---

## Phase 1: SDL3 Window, Input & Main Loop

**Goal:** The game opens a window, creates an OpenGL context, and runs the render loop on Linux/macOS via SDL3. Keyboard and mouse input works.

### Session 1.1: Platform interfaces

**Scope:** Define C++ interfaces for all platform-dependent systems. No implementation — headers only. Do NOT modify any existing files.

Interfaces to define:
- `IPlatformWindow` — Create, Destroy, Show, SwapBuffers, PollEvents, SetFullscreen, RestoreDisplayMode
- `IPlatformInput` — PollState, IsKeyDown, GetMousePosition, SetMousePosition, ShowCursor, CaptureMouse
- `IPlatformAudio` — Initialize, Shutdown, LoadSound, PlaySound, StopSound, SetVolume, Set3DPosition, PlayMusic, StopMusic
- `IPlatformFont` — Initialize, Shutdown, CreateFont, RenderText, MeasureText
- `IPlatformConfig` — ReadInt, WriteInt, ReadString, WriteString, EncryptString, DecryptString
- `PlatformSystem` namespace — OpenURL, GetCpuUsage, SetTimerResolution, GetScreenWidth/Height, GetExecutablePath
- `Platform.h` master header — `extern` global pointers for all interfaces

**Create:** `src/source/Platform/PlatformWindow.h`, `PlatformInput.h`, `PlatformAudio.h`, `PlatformFont.h`, `PlatformSystem.h`, `PlatformConfig.h`, `Platform.h`
**Modify:** None
**Accept:** All interface headers compile standalone; `Platform.h` includes all others
**Invariant:** Windows x64 build compiles

### Session 1.2: SDLWindow.cpp

**Scope:** Implement `IPlatformWindow` using SDL3. Request OpenGL 2.1 compatibility profile on macOS (deprecated but working — gets immediate-mode GL running). Do NOT touch any Win32 code.

Key implementation:
- `SDL_Init(SDL_INIT_VIDEO)` + `SDL_CreateWindow()` with `SDL_WINDOW_OPENGL`
- GL 2.1 context: `SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2)`, minor 1, compatibility profile
- `SDL_GL_SetSwapInterval()` for VSync (replaces `wglSwapIntervalEXT`)
- `PollEvents()` translates SDL3 events to existing game globals (`MouseX`, `MouseY`, `MouseLButton`, `MouseLButtonPop`, `MouseWheel`, etc.)

**Create:** `src/source/Platform/SDL/SDLWindow.cpp`
**Modify:** None
**Accept:** SDLWindow creates a visible window with GL context on Linux/macOS
**Invariant:** Windows x64 build compiles

### Session 1.3: SDLInput.cpp

**Scope:** Implement `IPlatformInput` using SDL3. Map SDL scancodes to VK_* codes (~60 entries). Do NOT touch any Win32 code.

Mapping examples: `SDL_SCANCODE_LCTRL → VK_CONTROL`, `SDL_SCANCODE_RETURN → VK_RETURN`, mouse buttons via `SDL_GetMouseState()`.

**Create:** `src/source/Platform/SDL/SDLInput.cpp`
**Modify:** None
**Accept:** SDLInput returns correct key states for all mapped keys; mapping table covers every VK_* used in codebase
**Invariant:** Windows x64 build compiles

### Session 1.4: Win32 backend extraction

**Scope:** Extract existing Win32 windowing and input code into `IPlatformWindow`/`IPlatformInput` implementations. Extracted code must be functionally identical to current behavior. Do NOT change game logic.

**Create:** `src/source/Platform/Win32/Win32Window.cpp`, `src/source/Platform/Win32/Win32Input.cpp`
**Modify:** None
**Accept:** Win32 implementations wrap existing RegisterClass/CreateWindow/WndProc/GetAsyncKeyState; Windows game behavior unchanged
**Invariant:** Windows x64 build compiles

### Session 1.5: Winmain.cpp refactor

**Scope:** Split entry point into `WinMain`/`main`, create `MuMain()`. Refactor `MainLoop` to use platform interfaces. Do NOT change game logic.

```cpp
#ifdef _WIN32
int APIENTRY WinMain(HINSTANCE hInst, HINSTANCE, PSTR cmd, int show) {
    g_hInst = hInst;
    return MuMain(__argc, __argv);
}
#else
int main(int argc, char* argv[]) {
    return MuMain(argc, argv);
}
#endif

int MuMain(int argc, char* argv[]) {
    g_platformWindow = CreatePlatformWindow();
    g_platformInput  = CreatePlatformInput();
    // ... existing init code ...
    MainLoop();
}
```

**Create:** `src/source/Platform/Platform.cpp` (factory functions)
**Modify:** `src/source/Winmain.cpp`
**Accept:** Windows game launches and runs identically via platform abstraction; Linux/macOS entry point compiles
**Invariant:** Windows x64 build compiles

### Session 1.6: Replace GetAsyncKeyState

**Scope:** Replace all 104 `GetAsyncKeyState` calls across 8 files with `g_platformInput->IsKeyDown()`. Do NOT change any game logic — only the input source.

Files (104 calls total):
- `ZzzInterface.cpp` (22 calls)
- `UIControls.cpp` (8 calls)
- `Camera/CameraUtility.cpp` (4 calls)
- `NewUICommon.cpp` (2 calls — `ScanAsyncKeyState`)
- `Winmain.cpp` (multiple)
- `Scenes/SceneManager.cpp`
- 2 other files

**Create:** None
**Modify:** All 8 files listed above
**Accept:** All keyboard input works identically on Windows; `grep -r "GetAsyncKeyState" src/source/` returns zero matches
**Invariant:** Windows x64 build compiles

### Session 1.7: Replace SwapBuffers + WGL calls

**Scope:** Replace `SwapBuffers(g_hDC)` (~3-4 sites) and all WGL calls in `ZzzOpenglUtil.cpp` with platform abstractions. Do NOT change rendering behavior.

WGL removals:
- `wglGetProcAddress()` → removed (no extensions used)
- `wglSwapIntervalEXT()` → `SDL_GL_SetSwapInterval()`
- `wglChoosePixelFormatARB()` / `wglGetExtensionStringEXT()` → `SDL_GL_SetAttribute()`
- `ChoosePixelFormat()` / `SetPixelFormat()` / `PIXELFORMATDESCRIPTOR` → handled by SDL3 context creation

**Create:** None
**Modify:** `src/source/Scenes/SceneManager.cpp`, `src/source/Scenes/LoadingScene.cpp`, `src/source/Winmain.cpp`, `src/source/ZzzOpenglUtil.cpp`
**Accept:** VSync and buffer swap work identically on Windows; `grep -r "wgl\|SwapBuffers\|ChoosePixelFormat\|SetPixelFormat" src/source/` returns zero matches in cross-platform code
**Invariant:** Windows x64 build compiles

### Session 1.8: Global handles + CMake integration

**Scope:** Update `g_hWnd`, `g_hDC`, `g_hRC` globals for cross-platform use. On SDL3, `g_hWnd` stores `SDL_Window*` cast to `HWND` (`void*` on non-Windows via `PlatformTypes.h`). Add all new Phase 1 source files to `CMakeLists.txt` with platform-conditional compilation. Do NOT change Windows handle types.

**Create:** None
**Modify:** `src/CMakeLists.txt`, files referencing `g_hWnd`/`g_hDC`/`g_hRC` that need platform abstraction
**Accept:** Full game compiles and runs on Windows; `cmake --preset linux-x64 && cmake --build` succeeds
**Invariant:** Windows x64 build compiles

**Phase 1 Outcome:** Game opens a window and renders on Linux/macOS using GL 2.1 legacy context. Keyboard and mouse input works. No audio, no text rendering. On macOS, immediate-mode GL works via compatibility profile.

---

## Phase 2: SDL_gpu Migration

**Goal:** Migrate rendering from OpenGL immediate mode to SDL_gpu (Vulkan/Metal/D3D12), eliminating OpenGL entirely.

This phase can run in parallel with Phases 3-8. The game remains functional on GL 2.1 throughout migration. See [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md) for rendering strategy rationale, per-file GL audit, and shader specifications.

### Session 2.1: MuRenderer API design

**Scope:** Define the `MuRenderer` abstraction API. Do NOT implement backends. Do NOT modify existing code.

API surface:
- `BlendMode` enum consolidating 7 `Enable*Blend` functions into 1 (None, Alpha, Additive, Subtract, InverseColor, Mixed, LightMap)
- `Quad2D` struct consolidating 9 `RenderBitmap*` variants into 1 (`RenderQuad2D`)
- `Vertex3D` struct + `RenderTriangles`, `RenderQuadStrip` for 3D geometry
- State management: `SetBlendMode`, `SetDepthTest`, `SetDepthMask`, `SetAlphaTest`, `SetFog`
- Debug drawing: `DebugDrawLine`, `DebugDrawQuad`
- `MatrixStack` class interface (push, pop, translate, rotate, scale, getModelViewProjection)

**Create:** `src/source/Platform/MuRenderer.h`
**Modify:** None
**Accept:** `MuRenderer.h` compiles standalone; API covers all 6 blend modes, 2D/3D rendering, state management, matrix stack
**Invariant:** Windows x64 build compiles

### Session 2.2: MuRenderer OpenGL backend

**Scope:** Implement `MuRenderer.h` backed by existing OpenGL calls. Pure refactoring target — no behavioral change. Do NOT modify any rendering call sites yet.

**Create:** `src/source/Platform/OpenGL/MuRendererGL.cpp`
**Modify:** None
**Accept:** MuRendererGL compiles and links; all API functions delegate to correct GL calls; unit test: `RenderQuad2D` produces identical GL state to `RenderBitmap`
**Invariant:** Windows x64 build compiles

### Session 2.3: Migrate ZzzOpenglUtil.cpp

**Scope:** Replace the 15 `glBegin` blocks and 7 blend functions in `ZzzOpenglUtil.cpp` with MuRenderer calls. This cascades to fix ~80% of rendering call sites. Do NOT modify other rendering files in this session.

Key changes:
- 9 `RenderBitmap*` variants → `RenderQuad2D` calls
- 7 `Enable*Blend` / `DisableAlphaBlend` → `SetBlendMode(BlendMode::X)`
- Fog setup → `SetFog()`
- `glColor4f`/`glColor3f` vertex colors → `Vertex3D.color`

**Create:** None
**Modify:** `src/source/ZzzOpenglUtil.cpp`
**Accept:** Game renders identically on Windows; all `glBegin` removed from ZzzOpenglUtil.cpp (verified by grep)
**Invariant:** Windows x64 build compiles

### Session 2.4: Matrix stack utility

**Scope:** Implement `MatrixStack` class (~300 lines) replacing `glPushMatrix`/`glPopMatrix`/`glTranslatef`/`glRotatef`/`glLoadIdentity`/`gluPerspective`/`gluOrtho2D`. Do NOT replace call sites yet — this session creates the utility only.

**Create:** `src/source/Platform/MatrixStack.h`, `src/source/Platform/MatrixStack.cpp`
**Modify:** None
**Accept:** Unit tests: `MatrixStack` produces identical 4x4 matrices to GL for perspective, ortho2D, translate+rotate, push/pop sequences
**Invariant:** Windows x64 build compiles

### Session 2.5: Migrate terrain + water

**Scope:** Migrate `ZzzLodTerrain.cpp` (9 `glBegin` blocks, TRIANGLE_FAN terrain strips) and `CSWaterTerrain.cpp` (~2 `glBegin` blocks, TRIANGLES water) to MuRenderer. Replace GL matrix calls with `MatrixStack`.

**Create:** None
**Modify:** `src/source/ZzzLodTerrain.cpp`, `src/source/CSWaterTerrain.cpp`
**Accept:** Terrain and water render identically on Windows (visual inspection); zero `glBegin` in these files
**Invariant:** Windows x64 build compiles

### Session 2.6: Migrate models + objects

**Scope:** Migrate `ZzzBMD.cpp` (4 `glBegin` blocks, 99+ matrix ops — largest file) and `ZzzObject.cpp` (2 `glBegin` blocks, heavy vertex color) to MuRenderer. This is the most complex session due to ZzzBMD's matrix stack depth.

**Create:** None
**Modify:** `src/source/ZzzBMD.cpp`, `src/source/ZzzObject.cpp`
**Accept:** 3D models render identically; stencil operations in ZzzBMD preserved; zero `glBegin` in these files
**Invariant:** Windows x64 build compiles

### Session 2.7: Migrate effects + remaining files

**Scope:** Migrate all remaining rendering files to MuRenderer:
- `ZzzEffectJoint.cpp` (~3 `glBegin`, QUADS trails)
- `ZzzEffectBlurSpark.cpp` (~2 `glBegin`, TRIANGLE_FAN + QUADS)
- `ZzzEffectMagicSkill.cpp` (~2 `glBegin`, QUADS)
- `ShadowVolume.cpp` (~2 `glBegin`, two-pass stencil INCR/DECR)
- `SideHair.cpp` (~1 `glBegin`, QUADS)
- `SceneManager.cpp` (~1 `glBegin`, scene fades)
- `PhysicsManager.cpp` (~1 `glBegin`, debug QUADS)
- `CameraMove.cpp` (~1 `glBegin`, debug LINE_STRIP)

**Create:** None
**Modify:** All 8 files listed
**Accept:** All effects render identically; shadow volumes work; `grep -rn "glBegin\|glEnd\|glVertex\|glColor[34]" src/source/` returns zero matches
**Invariant:** Windows x64 build compiles

### Session 2.8: HLSL shaders + SDL_shadercross

**Scope:** Write all HLSL shaders and set up SDL_shadercross CMake integration. Do NOT swap the rendering backend yet.

Shaders (~100-150 lines total):
- **basic_colored** — flat colored geometry
- **basic_textured** — textured quads with vertex color multiply, optional alpha discard, optional fog
- **model_mesh** — same as basic_textured for `glDrawArrays` path (shares fragment shader)
- **shadow_volume** — transform-only vertex shader, no fragment output
- **shadow_apply** — fullscreen quad with semi-transparent shadow color

**Create:** `src/shaders/*.hlsl`, CMake shader compilation rules
**Modify:** `src/CMakeLists.txt`
**Accept:** `cmake --build` cross-compiles all 5 shaders to SPIR-V, MSL, and DXIL without errors
**Invariant:** Windows x64 build compiles

### Session 2.9: SDL_gpu backend

**Scope:** Implement MuRenderer backed by SDL_gpu. Create GPU device, claim window, set up swap chain and render passes. Replace `SDL_GL_CreateContext` with `SDL_CreateGPUDevice` + `SDL_ClaimWindowForGPUDevice`. Do NOT remove OpenGL backend yet — both coexist via compile flag.

Pipeline objects:
- 6 blend mode pipelines mapping to `SDL_GPUColorTargetBlendState`
- Depth/stencil state variants mapping to `SDL_GPUDepthStencilState`
- Shadow volume stencil pipeline mapping to `SDL_GPUStencilOpState`

**Create:** `src/source/Platform/SDLGpu/MuRendererGpu.cpp`
**Modify:** `src/source/Platform/SDL/SDLWindow.cpp` (GPU device init)
**Accept:** Game renders via SDL_gpu on all three platforms; compile flag toggles between GL and GPU backends
**Invariant:** Windows x64 build compiles

### Session 2.10: Remove OpenGL + visual parity

**Scope:** Remove OpenGL backend, GLEW, GL headers, GL context creation. SDL_gpu is now the only rendering path. Switch ImGui to `imgui_impl_sdlgpu3.cpp`.

Removals:
- `MuRendererGL.cpp` from build
- `<GL/gl.h>`, `<gl/glew.h>` includes
- `SDL_GL_CreateContext`, `SDL_GL_SetAttribute` calls
- GLEW library linking

**Create:** None
**Modify:** Multiple files (GL include removal, CMakeLists.txt)
**Accept:** `grep -rn "glBegin\|glEnd\|GL_\|GLEW\|<GL/" src/source/` returns zero matches; game renders on Vulkan/Metal/D3D12; screenshot comparison passes vs GL reference within threshold
**Invariant:** Windows x64 build compiles

**Phase 2 Outcome:** OpenGL eliminated entirely. Native Vulkan on Linux, Metal on macOS, D3D12 on Windows. Clean `MuRenderer` API replaces 600+ lines of duplicated OpenGL calls.

---

## Phase 3: Audio System (miniaudio)

**Goal:** Full audio on all platforms. Replaces both DirectSound and wzAudio. See [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md) for miniaudio selection rationale.

### Session 3.1: Vendor miniaudio + MiniAudioBackend

**Scope:** Vendor `miniaudio.h` and `stb_vorbis.c`. Implement `IPlatformAudio` using miniaudio. Do NOT modify existing audio code.

Key implementation:
- `ma_engine_init()` for device management
- `ma_sound_init_from_file()` with `MA_SOUND_FLAG_DECODE` for sound effects
- `ma_sound_set_position()` for 3D spatialization (replaces `IDirectSound3DBuffer`)
- `ma_sound_init_from_file()` with `MA_SOUND_FLAG_STREAM` for music (replaces wzAudio)
- Polyphony: `MAX_CHANNEL` duplicate `ma_sound` instances per sound ID

**Create:** `src/dependencies/miniaudio/miniaudio.h`, `src/dependencies/miniaudio/stb_vorbis.c`, `src/source/Platform/MiniAudio/MiniAudioBackend.cpp`, one `.cpp` with `#define MINIAUDIO_IMPLEMENTATION`
**Modify:** `src/CMakeLists.txt`
**Accept:** MiniAudioBackend plays a test WAV file and streams a test MP3
**Invariant:** Windows x64 build compiles

### Session 3.2: Refactor DSplaysound.cpp

**Scope:** Make existing `DSplaysound.cpp` public functions (`InitDirectSound`, `LoadWaveFile`, `PlayBuffer`, `StopBuffer`, etc.) delegate to `g_platformAudio`. Keep DirectSound as Win32 backend. The ~100+ call sites across the codebase need zero changes.

**Create:** None
**Modify:** `src/source/DSplaysound.cpp`, `src/source/DSPlaySound.h`
**Accept:** Sound effects play identically on Windows via platform abstraction; no call site changes needed
**Invariant:** Windows x64 build compiles

### Session 3.3: Remove wzAudio (music streaming)

**Scope:** Replace wzAudio with miniaudio music streaming. Remove `wzAudio.lib`/`wzAudio.dll` dependency.

Changes:
- Rewrite `PlayMp3()`, `StopMp3()`, `IsEndMp3()`, `GetMp3PlayPosition()` in `Winmain.cpp` to call `g_platformAudio` methods
- Remove `wzAudioCreate(g_hWnd)` from initialization
- Remove wzAudio from build system

**Create:** None
**Modify:** `src/source/Winmain.cpp`, `src/CMakeLists.txt`
**Accept:** Background music plays and loops seamlessly; `grep -r "wzAudio" src/` returns zero matches
**Invariant:** Windows x64 build compiles

### Session 3.4: 3D audio + cross-platform testing

**Scope:** Verify 3D audio spatialization works via `ma_sound_set_position`. Test all audio on Linux/macOS.

**Create:** None
**Modify:** `MiniAudioBackend.cpp` (if tuning needed)
**Accept:** 3D audio panning works (distance attenuation, left-right panning); all sound effects and music play on Linux/macOS
**Invariant:** Windows x64 build compiles

**Phase 3 Outcome:** Sound effects and music work on all three platforms. wzAudio eliminated. miniaudio compiled in (no external packaging needed).

---

## Phase 4: Font Rendering (FreeType)

**Goal:** Replace GDI font rendering with FreeType for cross-platform text.

### Session 4.1: FreeTypeFont.cpp

**Scope:** Implement `IPlatformFont` using FreeType. Do NOT modify existing font code.

Critical details:
- `RenderText()` composites glyph bitmaps into RGBA buffer: `dst_rgba = {textColor.r, .g, .b, glyph_alpha}`
- **`MeasureText()` must use `advance.x >> 6`** (26.6 fixed point), NOT `bitmap.width`. GDI's `GetTextExtentPoint32` returns advance widths.
- `FT_LOAD_TARGET_NORMAL` + `FT_RENDER_MODE_NORMAL` (grayscale antialiased, no LCD subpixel)

**Create:** `src/source/Platform/FreeType/FreeTypeFont.cpp`
**Modify:** `src/CMakeLists.txt` (add `find_package(Freetype REQUIRED)`)
**Accept:** FreeTypeFont renders test strings to RGBA buffer; MeasureText returns advance-based widths matching known GDI values within ±2px
**Invariant:** Windows x64 build compiles

### Session 4.2: CUIRenderTextFreeType

**Scope:** Create `CUIRenderTextFreeType` implementing the `IUIRenderText` interface (defined in `UIControls.h:734`). Same interface as `CUIRenderTextOriginal` but uses `IPlatformFont`. Do NOT replace existing renderer.

**Create:** None (within existing files)
**Modify:** `src/source/UIControls.cpp`, `src/source/UIControls.h`
**Accept:** `CUIRenderTextFreeType` renders text matching the `IUIRenderText` interface
**Invariant:** Windows x64 build compiles

### Session 4.3: Replace GetTextExtentPoint32

**Scope:** Add `GetTextExtent()` method to `IUIRenderText`. Replace all `GetTextExtentPoint32` call sites.

**Create:** None
**Modify:** Files using `GetTextExtentPoint32`
**Accept:** Text measurement works via platform abstraction; GDI still used on Windows
**Invariant:** Windows x64 build compiles

### Session 4.4: Replace CreateFont + ship font

**Scope:** Create the 4 global fonts (`g_hFont`, `g_hFontBold`, `g_hFontBig`, `g_hFixFont`) via `g_platformFont->CreateFont()` on non-Windows. Bundle **Nanum Gothic** (SIL OFL, full Hangul coverage). Do NOT use DejaVuSans (zero Hangul coverage — see Issue #9).

Alternative font: Source Han Sans (SIL OFL, excellent CJK, ~15MB vs ~5MB).

**Create:** `src/bin/Data/Fonts/NanumGothic.ttf`
**Modify:** `src/source/Winmain.cpp`, `src/source/CreditWin.cpp`
**Accept:** Korean text renders correctly (no tofu boxes) on Linux/macOS at all 4 font sizes
**Invariant:** Windows x64 build compiles

### Session 4.5: Font metric calibration

**Scope:** Tune FreeType parameters to match GDI within ±2px at all sizes. Use `FT_Set_Char_Size(face, 0, size*64, 96, 96)` to match `CreateFont(-size, ...)`.

**Create:** None
**Modify:** `FreeTypeFont.cpp` (tuning)
**Accept:** MeasureText matches GDI within ±2px for all 4 fonts at reference strings; `CutStr()` word-wrap breaks at same character positions (±1 char); screenshot comparison at 800x600, 1024x768
**Invariant:** Windows x64 build compiles

**Phase 4 Outcome:** All UI text renders correctly on Linux/macOS, including Korean characters.

---

## Phase 5: Config, Encryption & System Utilities

**Goal:** Cross-platform config persistence, credential storage, and misc OS utilities.

### Session 5.1: Cross-platform INI parser

**Scope:** Replace `GetPrivateProfileIntW`/`WritePrivateProfileStringW` in `GameConfig.cpp` (5 occurrences, 1 file) with a portable INI reader/writer. Use `inih` (MIT, single header) or ~150 lines C++.

**Create:** `src/source/Platform/IniFile.h`, `src/source/Platform/IniFile.cpp`
**Modify:** `src/source/GameConfig/GameConfig.cpp`
**Accept:** Config read/write round-trips identically to Windows API for all keys; unit test passes
**Invariant:** Windows x64 build compiles

### Session 5.2: Credential encryption

**Scope:** Replace DPAPI (`CryptProtectData`/`CryptUnprotectData`) in `GameConfig.cpp`. Linux: AES-256 with key from `/etc/machine-id`. macOS: AES-256 with key from system UUID. Windows: keep DPAPI.

**Create:** None
**Modify:** `src/source/GameConfig/GameConfig.cpp`
**Accept:** Encrypted credentials can be stored and retrieved on Linux/macOS; Windows DPAPI unchanged
**Invariant:** Windows x64 build compiles

### Session 5.3: CpuUsage + WindowsConsole + ErrorReport

**Scope:** Create Linux/macOS implementations of CPU usage (`/proc/self/stat`, `getrusage`), console logging (stdout + ANSI escapes), and error reporting (`std::ofstream` replacing `HANDLE`/`WriteFile`).

**Create:** `src/source/Utilities/CpuUsageLinux.cpp`, `src/source/Utilities/CpuUsageMac.cpp`
**Modify:** `src/source/Utilities/Log/WindowsConsole.cpp`, `src/source/Utilities/Log/ErrorReport.cpp`
**Accept:** CPU usage, console logging, and error reporting work on Linux/macOS
**Invariant:** Windows x64 build compiles

### Session 5.4: Misc Win32 API replacements

**Scope:** Replace remaining Win32-only calls:
- `ShellExecute(url)` (2 calls, 2 files) → `xdg-open` (Linux), `open` (macOS)
- `GetModuleFileName` (9 calls, 5 files) → `/proc/self/exe` (Linux), `_NSGetExecutablePath` (macOS)
- `GetSystemMetrics` → `SDL_GetCurrentDisplayMode()`
- `timeBeginPeriod`/`timeEndPeriod` → no-op (not needed on Linux/macOS)
- `SetTimer`/`KillTimer` (20 calls, 10 files) → `std::chrono` checks in main loop
- `_beginthreadex`/`WaitForSingleObject` (4 calls, 2 files) → `std::thread`

**Create:** None
**Modify:** `src/source/Winmain.cpp`, `src/source/ZzzOpenglUtil.cpp`, ~10 other files
**Accept:** All replaced functions work on Linux/macOS; zero Win32-only API calls remain in cross-platform code paths
**Invariant:** Windows x64 build compiles

### Session 5.5: wchar_t in .bmd files

**Scope:** Fix `.bmd` binary file loaders to handle 4-byte `wchar_t` on Linux. Use `ImportChar16ToWchar` from `StringConvert.h` at load sites where `memcpy` reads 2-byte text data into `wchar_t[]`.

**Create:** None
**Modify:** `src/source/ZzzInfomation.cpp`, `src/source/MultiLanguage.cpp`, ~3 other `.bmd` text loader files
**Accept:** BMD text fields (bone names, texture filenames) parse identically on Linux and Windows; unit test with known `.bmd` byte sequences passes
**Invariant:** Windows x64 build compiles

### Session 5.6: wchar_t at C# interop

**Scope:** Fix C++/C# boundary to use `char16_t` on non-Windows. C# marshals as UTF-16; on Linux (4-byte `wchar_t`), `const wchar_t*` causes corruption.

```cpp
#ifdef _WIN32
typedef void(CORECLR_DELEGATE_CALLTYPE* SendChatMessage)(int32_t, const wchar_t*);
#else
typedef void(CORECLR_DELEGATE_CALLTYPE* SendChatMessage)(int32_t, const char16_t*);
#endif
```

With `WcharToU16()` conversion at call sites.

**Create:** None
**Modify:** `src/source/Dotnet/PacketBindings_*.h`, `src/source/Dotnet/PacketFunctions_*.h` (~10 files)
**Accept:** Packet strings round-trip correctly including Korean characters; unit test verifies `char16_t` encoding matches Windows `wchar_t`
**Invariant:** Windows x64 build compiles

**Phase 5 Outcome:** Full feature parity for configuration, logging, and system utilities. Network protocol and binary files handle `wchar_t` size differences correctly.

---

## Phase 6: Text Input & IME

**Goal:** Chat and login text input works on non-Windows platforms.

### Session 6.1: SDL3 text input

**Scope:** Replace `CreateWindowW(L"edit", ...)` Win32 edit control in `CUITextInputBox` with SDL3 text input (`SDL_StartTextInput`/`SDL_StopTextInput`, `SDL_EVENT_TEXT_INPUT`). Cursor rendering and selection handled by existing game UI code.

**Create:** None
**Modify:** `src/source/UIControls.cpp`
**Accept:** Text can be typed in chat and login input boxes on Linux/macOS
**Invariant:** Windows x64 build compiles

### Session 6.2: Basic IME support

**Scope:** Map SDL3 `SDL_EVENT_TEXT_EDITING` for IME composition and `SDL_EVENT_TEXT_EDITING_CANDIDATES` for candidate lists to existing `CheckTextInputBoxIME` pattern. Initial target: `_LANGUAGE_ENG`. Full CJK IME can be deferred.

**Create:** None
**Modify:** `src/source/UIControls.cpp`
**Accept:** IME composition text appears in input boxes on Linux/macOS
**Invariant:** Windows x64 build compiles

### Session 6.3: Replace WM_CHAR handling

**Scope:** Character input currently comes through `WM_CHAR` in WndProc. Translate `SDL_EVENT_TEXT_INPUT` to the existing `SetEnterPressed()` mechanism in the SDL3 event loop.

**Create:** None
**Modify:** `src/source/Winmain.cpp`
**Accept:** Chat input, login fields, and all text inputs work on Linux/macOS (type, backspace, enter)
**Invariant:** Windows x64 build compiles

**Phase 6 Outcome:** Players can type in chat, login fields, and all text inputs on Linux/macOS.

---

## Phase 7: ImGui Editor

**Goal:** The debug editor (conditional `_EDITOR` builds) works on non-Windows platforms.

### Session 7.1: Replace ImGui backends

**Scope:** Switch ImGui from `imgui_impl_win32.cpp` + `imgui_impl_opengl2.cpp` to `imgui_impl_sdl3.cpp` + `imgui_impl_sdlgpu3.cpp` (after Phase 2) on non-Windows. Windows can keep existing backends or switch.

```cmake
if(ENABLE_EDITOR)
  if(WIN32)
    set(IMGUI_BACKEND "imgui_impl_win32.cpp")
  else()
    set(IMGUI_BACKEND "imgui_impl_sdl3.cpp")
  endif()
endif()
```

**Create:** None
**Modify:** `src/CMakeLists.txt`
**Accept:** ImGui renders in editor builds on Linux/macOS
**Invariant:** Windows x64 build compiles

### Session 7.2: Update MuEditorCore

**Scope:** Change `MuEditorCore.Initialize()` to accept `void*` window handle (SDL_Window* on non-Windows, HWND on Windows).

**Create:** None
**Modify:** `src/MuEditor/Core/MuEditorCore.cpp`, `src/source/Winmain.cpp`
**Accept:** Editor initializes, renders, and accepts input on all platforms
**Invariant:** Windows x64 build compiles

**Phase 7 Outcome:** In-game debug editor works on all platforms.

---

## Phase 8: .NET Native AOT Cross-Platform

**Goal:** The game can connect to servers from Linux/macOS.

### Session 8.1: CMake RID selection

**Scope:** Add linux-x64, osx-arm64, osx-x64 Runtime Identifier detection to CMake.

```cmake
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(DOTNET_RID "linux-x64")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(DOTNET_RID "osx-arm64")
    else()
        set(DOTNET_RID "osx-x64")
    endif()
endif()
```

**Create:** None
**Modify:** `src/CMakeLists.txt`
**Accept:** Correct RID selected on each platform; Windows RID unchanged
**Invariant:** Windows x64 build compiles

### Session 8.2: Shared library loading

**Scope:** Fix `Connection.h` to load `.so` (Linux) / `.dylib` (macOS) instead of `.dll`.

```cpp
#ifdef __linux__
    dlopen("libMUnique.Client.Library.so", RTLD_LAZY)
#elif __APPLE__
    dlopen("libMUnique.Client.Library.dylib", RTLD_LAZY)
#endif
```

**Create:** None
**Modify:** `src/source/Dotnet/Connection.h`
**Accept:** `dlopen` loads the .NET library on Linux/macOS
**Invariant:** Windows x64 build compiles

### Session 8.3: ClientLibrary + integration testing

**Scope:** Update `.csproj` if needed for cross-platform Native AOT output. Test full connection flow.

**Create:** None
**Modify:** `ClientLibrary/MUnique.Client.Library.csproj` (if needed)
**Accept:** Game connects to server and completes login flow from Linux/macOS
**Invariant:** Windows x64 build compiles

**Phase 8 Outcome:** Full server connectivity on Linux/macOS.

---

## Phase 9: CI/CD, Packaging & Ground Truth Essentials

**Goal:** Automated builds, distribution packaging, and essential baseline capture. See [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md) for full Ground Truth spec (all 10 captures). This phase implements the essential subset.

### Session 9.1: GitHub Actions workflows

**Scope:** Create CI workflows for Linux and macOS builds.

**Create:** `.github/workflows/linux-build.yml`, `.github/workflows/macos-build.yml`
**Modify:** None
**Accept:** CI builds pass on Ubuntu (with `apt-get install -y libltdl-dev` for vcpkg) and macOS
**Invariant:** Windows x64 build compiles

### Session 9.2: Asset case verification + MSVC string replacements

**Scope:** Add CI script to verify all asset references match actual filenames (case-sensitive). Replace 14 MSVC-specific safe string functions (`sprintf_s`, `wcscpy_s`, `_snprintf`, `strcpy_s`) across 8 files with `std::snprintf()` or `std::format()` (C++20).

**Create:** Asset case verification script
**Modify:** 8 files with MSVC-only string functions
**Accept:** Zero MSVC-only string functions in cross-platform code; asset case check passes
**Invariant:** Windows x64 build compiles

### Session 9.3: Packaging

**Scope:** Create distributable packages.
- **Linux:** AppImage (bundles SDL3 + all deps) or Flatpak
- **macOS:** `.app` bundle with `Info.plist`

**Create:** Packaging configuration files
**Modify:** `src/CMakeLists.txt` (install targets)
**Accept:** Distributable packages launch and run the game on clean systems
**Invariant:** Windows x64 build compiles

### Session 9.4: Ground Truth essentials

**Scope:** Implement capture for the 3 essential Ground Truth items only (full spec: [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md)):
1. **Screenshots** (#1) — automated sweep of all 80+ UI screens via `CNewUIManager` + `glReadPixels` + PNG + SHA256. Validates Phases 1, 2, 4.
2. **Text metrics** (#2) — `GetTextExtentPoint32` on reference strings for all 4 fonts, dump to JSON. Validates Phase 4.
3. **GL state snapshots** (#10) — blend, depth, stencil, viewport, matrix at render checkpoints. Validates Phase 2.

Enable via `-DENABLE_GROUND_TRUTH_CAPTURE`. Does not ship in release builds.

**Create:** `src/source/Platform/GroundTruthCapture.h`
**Modify:** `src/source/Scenes/SceneManager.cpp` (instrumentation points)
**Accept:** Capture hotkey produces `tests/golden/screenshots/*.png`, `tests/golden/text_metrics.json`, and `tests/golden/opengl/gl_state_*.txt`
**Invariant:** Windows x64 build compiles

### Session 9.5: README + documentation

**Scope:** Update README.md with build instructions for all three platforms.

**Create:** None
**Modify:** `README.md`
**Accept:** A new developer can build on Windows, Linux, or macOS following the instructions
**Invariant:** Windows x64 build compiles

**Phase 9 Outcome:** Automated CI, distributable packages, and essential baseline data for regression testing.

---

## Phase 10: UI Design Reference Capture

**Goal:** Create design reference documents for all 80+ UI screens. This phase has no code dependencies — it runs in parallel with any other phase. Only requires a working Windows build for screenshots.

See [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md) for UI system architecture reference (screen categories, dimensions, class listing).

### Session 10.1: Screenshot reference capture

**Scope:** Run Windows build and capture pixel-perfect screenshots of every UI screen at 640x480.

Captures:
- Each screen in isolation (clean background)
- Common multi-window layouts (inventory+shop, character+party)
- All button states (normal, hover, pressed, disabled)

**Create:** `docs/ui-reference/screenshots/` directory with all captures
**Modify:** None
**Accept:** Screenshots exist for all 80+ `CNewUI*` windows, login scene, character select, and 5+ multi-window combinations

### Session 10.2: Layout specification extraction

**Scope:** Extract layout data from source code into structured documents.

Data to extract:
- Window positions (x, y) and sizes (width, height) from `Create()` calls
- Grid dimensions and cell sizes from inventory constants
- Button positions relative to parent windows
- Font sizes and text positions
- Color values (ARGB) for backgrounds, borders, text

**Create:** `docs/ui-reference/layouts/` directory with per-screen JSON/markdown
**Modify:** None
**Accept:** Layout specs exist for all Tier 1 and Tier 2 screens (12 screens minimum)

### Session 10.3: Design files for major screens

**Scope:** Create `.pen` design files for the top 22 screens ranked by interaction frequency:

**Tier 1 (always visible, highest validation risk):** CNewUIMainFrameWindow, CNewUIMyInventory, CNewUIChatLogWindow + CNewUIChatInputBox, CNewUIMiniMap, CNewUISkillList

**Tier 2 (opened every session):** CNewUICharacterInfoWindow, CNewUINPCShop, CNewUIStorageInventory, CNewUITrade, CNewUIMixInventory, CNewUIOptionWindow, CNewUIBuffWindow

**Tier 3 (important but less frequent):** CNewUIPartyInfoWindow, CNewUIFriendWindow, CNewUIGuildInfoWindow, CNewUIQuestProgress, CNewUINPCDialogue, CNewUICommonMessageBox, CNewUIInGameShop, CNewUIGensRanking

**Login flow:** LoginScene, CharacterScene

Each design file includes pixel-accurate layouts, component annotations, and interaction notes.

**Create:** `docs/ui-reference/designs/*.pen`
**Modify:** None
**Accept:** Design files exist for all 22 screens with pixel-accurate layouts matching source constants

### Session 10.4: Component library

**Scope:** Document reusable UI components as a design reference:
- `CNewUIButton` — dimensions, states, texture references
- `CNewUIScrollBar` — parts (up/down/track/thumb), dimensions
- `CNewUITextBox` — text input field layout
- `CNewUIInventoryCtrl` — grid system (20x20 cells)
- `CNewUIRenderNumber` — number display
- Window frame structure (top/middle/bottom, borders)
- Standard 190x429 window template

**Create:** `docs/ui-reference/components/` directory
**Modify:** None
**Accept:** Component documentation covers all 7 reusable components with dimensions, states, and texture references

### Session 10.5: Texture asset catalog

**Scope:** Organize the 761 texture files in `Data/Interface/`:
- Map each `BITMAP_INTERFACE_NEW_*` constant to its texture file
- Group by UI screen
- Document dimensions and usage
- Identify shared vs screen-specific assets

**Create:** `docs/ui-reference/texture-catalog.md`
**Modify:** None
**Accept:** Catalog maps all `BITMAP_INTERFACE_NEW_*` constants to files; textures grouped by screen

**Phase 10 Outcome:** Complete visual reference for the entire UI system. Design files serve as regression baseline for Phases 2 and 4.

---

## Dependency Graph

```
Phase 0 (headers/build/compat) ─── required by everything
    │
    ├── Phase 5 (config/utils/wchar_t) ─── can start after Phase 0
    ├── Phase 8 (.NET AOT) ─── can start after Phase 0
    │
    Phase 1 (SDL3 window/input/GL 2.1) ─── required by 2, 3, 4, 6, 7
        │
        ├── Phase 2 (SDL_gpu migration) ─── PARALLEL, long-running
        │       Sessions 2.1-2.7: MuRenderer abstraction (OpenGL backend)
        │       Sessions 2.8-2.10: Swap backend to SDL_gpu
        ├── Phase 3 (audio/miniaudio) ─── independent after Phase 1
        ├── Phase 4 (fonts/FreeType) ─── independent after Phase 1
        ├── Phase 6 (text input) ─── after Phase 1
        └── Phase 7 (editor) ─── after Phase 1
             │
             Phase 9 (CI/packaging/GT essentials) ─── after all others
    │
    Phase 10 (UI design capture) ─── PARALLEL, no code deps, can start anytime
```

Phases 2, 3, 4, 5, 6, 7, 8, 10 can be worked on in parallel after Phase 1 lands. Phase 10 can start immediately (only needs a working Windows build).

# Troubleshooting & FAQ

Common build issues, runtime problems, and their solutions across all supported environments.

For build setup instructions, see [Development Guide](development-guide.md). For build system details, see the [Build Guide](../MuMain/docs/build-guide.md).

---

## Build Issues

### MinGW (WSL)

**Problem:** `mingw-w64` not found or wrong architecture
```
-- The C compiler identification is unknown
```
**Solution:** Install the i686 (32-bit) cross-compiler:
```bash
sudo apt-get update && sudo apt-get install -y mingw-w64 g++-mingw-w64-i686 cmake ninja-build
```

**Problem:** `libturbojpeg.a` not found
```
Could not find MU_TURBOJPEG_STATIC_LIB
```
**Solution:** The CI workflow builds libjpeg-turbo from source. Point to the pre-built library:
```bash
cmake ... -DMU_TURBOJPEG_STATIC_LIB=_deps/mingw-i686/lib/libturbojpeg.a
```

**Problem:** `swprintf` conflicts with MinGW
```
error: too many arguments to function 'int swprintf(wchar_t*, const wchar_t*, ...)'
```
**Solution:** Already handled in `stdafx.h` — the `#undef swprintf` workaround should apply. If you see this, ensure `stdafx.h` is included as the PCH.

**Problem:** Build is slow on `/mnt/c/` path
**Solution:** Keep the repo on the WSL filesystem (`/home/<user>/...`), not on the Windows mount. The `/mnt/c/` path goes through a slow translation layer.

### MSVC

**Problem:** `ilc.exe` fails when repo is on WSL Z: drive
```
fatal error: Failed to load MUnique.Client.Library assembly
```
**Solution:** Override the NuGet cache to a Windows-native path:
```
cmake ... -DMU_NUGET_CACHE_DIR=C:/.mu-nuget
```

**Problem:** Git "dubious ownership" warning with Z: drive
```
fatal: detected dubious ownership in repository at '//wsl.localhost/...'
```
**Solution:** Add safe directory entries (one-time, PowerShell):
```powershell
git config --global --add safe.directory '%(prefix)///wsl.localhost/Ubuntu/home/<user>/MuMain'
git config --global --add safe.directory '%(prefix)///wsl.localhost/Ubuntu/home/<user>/MuMain/src/ThirdParty/imgui'
```

**Problem:** `dotnet` not found during CMake configure
**Solution:** Install .NET SDK 10 on Windows. WSL builds find `dotnet.exe` via WSL interop at `/mnt/c/Program Files/dotnet/dotnet.exe`.

### General CMake

**Problem:** Wrong CMake preset
**Solution:** Use presets from `CMakePresets.json`:
```bash
cmake --list-presets        # List available presets
cmake --preset windows-x64  # Use a specific preset
```
Do not pass raw `-DCMAKE_...` flags when a preset exists.

**Problem:** Submodule not initialized (empty `src/ThirdParty/imgui/`)
**Solution:**
```bash
git submodule update --init --recursive
```

---

## Runtime Issues

**Problem:** Game crashes immediately — missing DLLs or assets
**Solution:** Run from the build output directory, not the source tree. The post-build step copies assets:
```bash
cd build-mingw/src && ./Main.exe   # MinGW
# or for MSVC: out/build/windows-x86/src/Debug/
```

**Problem:** Game launches but cannot connect to server
**Solution:** Check `config.ini` for correct server IP/port. The .NET Native AOT DLL (`MUnique.Client.Library.dll`) must be in the same directory as `Main.exe`. On pure Linux (no WSL), the DLL cannot be built — CMake prints a warning and skips the .NET build.

**Problem:** Textures are black or missing
**Solution:** Ensure `Data/` directory is properly copied to the build output. Check that file paths in code use the expected case — Linux filesystems are case-sensitive.

**Problem:** No audio / sound effects
**Solution:** Ensure `wzAudio.dll`, `ogg.dll`, and `vorbisfile.dll` are in the executable directory. These are proprietary DLLs required for the current audio system (will be replaced by miniaudio in Phase 3).

---

## CI Issues

**Problem:** CI build fails but local build succeeds
**Solution:** MinGW and MSVC have different warning/error behaviors. Common differences:
- MinGW is stricter about implicit conversions
- MinGW uses different `swprintf` signatures (handled by `stdafx.h` workaround)
- MSVC-specific functions (`sprintf_s`, `_snprintf`) don't exist on MinGW

**Problem:** CI cache miss for libjpeg-turbo
**Solution:** The CI workflow caches the pre-built static library with versioned key (`libjpeg-turbo-mingw-i686-3.1.3-v1`). If the version changes, update the cache key in `ci.yml`.

---

## Cross-Platform Migration Issues

**Problem:** `wchar_t` corruption on Linux
**Cause:** `wchar_t` is 4 bytes on Linux vs 2 bytes on Windows. Code assuming 2-byte `wchar_t` will produce garbage.
**Solution:** Use `char16_t` at interop boundaries. Use `ImportChar16ToWchar()` from `StringConvert.h` for `.bmd` binary data. See [development standards](development-standards.md#wchar_t-portability).

**Problem:** File not found on Linux (works on Windows)
**Cause:** Linux filesystems are case-sensitive. `Data\\Player\\player.bmd` won't find `Player.bmd`.
**Solution:** The `mu_wfopen` shim includes case-folding fallback with lazy directory cache. See Phase 0, Session 0.3.

**Problem:** Backslash paths fail on Linux
**Cause:** ~2,050 hardcoded backslash paths in the codebase (`L"Data\\Local\\"`).
**Solution:** The `mu_wfopen` shim auto-normalizes `\` → `/` during conversion. Zero call-site changes needed.

**Problem:** `#pragma warning` causes errors on GCC/Clang
**Solution:** Wrap all `#pragma warning` directives in `#ifdef _MSC_VER`. See [development standards](development-standards.md#precompiled-headers).

---

## FAQ

**Q: Which build environment should I use?**
A: Depends on your OS:
- **macOS** — Quality gates only (`./ctl check`, `./ctl format`). Cannot compile the game (Win32/DirectX dependency).
- **Linux / WSL** (Recommended) — Full MinGW cross-compile build + quality gates. WSL is fastest for daily dev with Claude Code.
- **Windows** — MSVC presets for native builds. Use Visual Studio or CLion when you need the debugger.

**Q: Can I build on native Linux (no WSL)?**
A: The C++ client builds via MinGW cross-compile, but the .NET DLL requires Windows `dotnet.exe` for Native AOT. Without it, the game compiles but cannot connect to servers.

**Q: Why can't I build on macOS?**
A: The game client includes `windows.h` in its precompiled header (`stdafx.h`) and uses Win32/DirectX APIs throughout. The .NET layer also targets `win-x64` for Native AOT. Until the SDL3 cross-platform migration is complete, macOS is limited to quality gates (formatting, linting, static analysis).

**Q: Why is MuMain a git submodule?**
A: The workspace repo (`MuMain-workspace`) wraps the game client repo (`MuMain`) as a submodule. This separates documentation and planning from the game client code.

**Q: Can I edit generated files?**
A: No. `PacketBindings_*`, `PacketFunctions_*` in `src/source/Dotnet/` are XSLT-generated. Changes are overwritten on regeneration. Modify the XML packet definitions in `ClientLibrary/` instead. See [development standards](development-standards.md#4-generated-code).

**Q: What's the minimum C++ standard?**
A: C++20. The codebase uses `constexpr`, `std::chrono`, `std::filesystem`, range-based for, structured bindings, and `std::format` in places.

**Q: Where do I add feature flags?**
A: `MuMain/src/source/Defined_Global.h`. Prefix with your initials (e.g., `ABC_ADD_FEATURE`). Document hierarchical dependencies. See [development standards](development-standards.md#feature-flags).

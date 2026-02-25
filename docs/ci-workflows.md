# CI Workflows (GitHub Actions)

The project uses a single GitHub Actions workflow for continuous integration, running MinGW-w64 cross-compilation and code quality checks on Ubuntu. It lives at `MuMain/.github/workflows/ci.yml`.

## Workflow Overview

| Job | Runs On | Purpose |
|-----|---------|---------|
| **Quality Gates** | All pushes + PRs | `make format-check` + `make lint` |
| **MinGW Build** | All pushes + PRs | Cross-compile to Windows x86 |

```
Push to main ──────────┐
PR to main ────────────┼──► ci.yml ──┬── Quality Gates (make format-check + make lint)
Push to other branch ──┘             └── MinGW Build ──► Upload artifact (push only)
```

Both jobs run in **parallel** — a formatting failure won't block the build job or vice versa. Branch protection rules can require both to pass before merging.

## Quality Gates Job

Delegates entirely to Makefile targets — the Makefile is the single source of truth for tool configuration:

**Step 1 — clang-format:** `make format-check`
- Checks all C++ source files under `src/source/` (excluding `ThirdParty/`)
- Fails if any file has formatting violations
- Run `make format` locally to fix

**Step 2 — cppcheck:** `make lint`
- Runs static analysis on all source files
- Uses `--inline-suppr` to respect `// cppcheck-suppress` comments
- See `docs/cppcheck-guidance.md` for suppression policy
- Fails on any warning not covered by global or inline suppressions

### No Config Drift

Previous CI workflows duplicated cppcheck configuration inline, causing drift from the Makefile. The consolidated workflow avoids this by calling `make lint` directly — suppressions are managed only in the Makefile.

## Build Job

| Setting | Value |
|---------|-------|
| Runner | `ubuntu-latest` |
| Target | Windows x86 (i686) |
| Toolchain | `cmake/toolchains/mingw-w64-i686.cmake` |
| Generator | Ninja |
| Build type | Release |
| libjpeg-turbo | 3.1.3, static, no SIMD |

Build steps:

1. **Checkout** — `actions/checkout@v4`
2. **Install toolchain** — `mingw-w64`, `g++-mingw-w64-i686`, `cmake`, `ninja-build`
3. **Cache libjpeg-turbo** — `actions/cache@v4` with key `libjpeg-turbo-mingw-i686-3.1.3-v1`
4. **Build libjpeg-turbo** — Static i686 build (skipped if cache hit)
5. **Configure CMake** — Ninja generator, `mingw-w64-i686.cmake` toolchain, Release mode
6. **Build** — `cmake --build build-mingw -j$(nproc)`
7. **Upload artifact** — `main-exe-mingw-{branch}` containing `Main.exe` (push only, not PR)

### Dependency Caching

libjpeg-turbo is cached to avoid rebuilding on every run:
- **Cache path:** `_deps/mingw-i686`
- **Cache key:** `libjpeg-turbo-mingw-i686-3.1.3-v1`
- **Cache hit check:** Tests for `_deps/mingw-i686/lib/libturbojpeg.a`
- **To bust the cache** (e.g., version bump): change the `-v1` suffix in the key

### Artifact Naming

Artifacts include the branch name: `main-exe-mingw-{branch}` (e.g., `main-exe-mingw-main`, `main-exe-mingw-feature-xyz`). Artifacts are only uploaded on push events, not on PRs.

## Running Locally

To replicate what CI does before pushing:

```bash
cd MuMain

# Quality gates (same checks as CI)
make format-check    # clang-format dry run
make lint            # cppcheck static analysis

# Full build (same as CI)
cmake -S . -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DMU_TURBOJPEG_STATIC_LIB=_deps/mingw-i686/lib/libturbojpeg.a
cmake --build build-mingw -j$(nproc)
```

## Future Plans

Per the [cross-platform plan](CROSS_PLATFORM_PLAN.md), additional CI jobs are planned:

- **Linux native build** (Phase 7) — `cmake --preset linux-x64`
- **macOS native build** (Phase 8) — `cmake --preset macos-arm64`
- **Shader compilation** (Phase 2) — SDL_shadercross HLSL compilation as a build step
- **Ground truth tests** (Phase 2+) — Golden file comparison for rendering, audio, assets

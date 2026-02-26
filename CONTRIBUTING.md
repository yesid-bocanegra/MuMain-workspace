# Contributing to MuMain

MU Online game client (Season 5.2-6) — C++20 monolithic game loop + .NET 10 Native AOT network bridge.

## Getting Started

### Prerequisites

| Platform | Toolchain | Use Case |
|----------|-----------|----------|
| **WSL / Linux** | MinGW-w64, CMake 3.25+, Ninja | Full build + quality gates (recommended) |
| **Windows** | VS2022 / MSVC, CMake 3.25+, .NET 10 | Full build + .NET AOT |
| **macOS** | clang-format, cppcheck (via Homebrew) | Quality gates only |

### Setup

```bash
git clone --recurse-submodules <repo-url>
cd MuMain-workspace

# Install quality tools (all platforms)
# macOS: brew install clang-format cppcheck
# Linux: sudo apt-get install clang-format cppcheck

# Install pre-commit hook
cd MuMain && make hooks && cd ..

# Run quality gates
./ctl check
```

See `docs/development-guide.md` for full build instructions per platform.

## Development Workflow

### Branch Naming

| Prefix | Purpose |
|--------|---------|
| `feature/` | New functionality |
| `fix/` | Bug fixes |
| `refactor/` | Restructuring (no behavior change) |

### Commit Messages (Conventional Commits)

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning via semantic-release.

```
<type>(<scope>): <description>
```

| Type | Release | Example |
|------|---------|---------|
| `feat` | minor | `feat(ui): add inventory sorting` |
| `fix` | patch | `fix(network): handle disconnect during login` |
| `perf` | patch | `perf(render): batch terrain draw calls` |
| `refactor` | patch | `refactor(input): extract key binding table` |
| `docs` | none | `docs: update build guide for macOS` |
| `style` | none | `style: fix clang-format violations` |
| `test` | none | `test: add packet encoding round-trip` |
| `build` | none | `build: update libjpeg-turbo to v3.2` |
| `ci` | none | `ci: add cppcheck portability checks` |
| `chore` | none | `chore(codegen): regenerate packet bindings` |

- Imperative mood: "add input mapping", not "added input mapping"
- Reference issues in footer: `Closes #42`
- Separate generated file commits from manual code changes

See `docs/development-standards.md` §6 for full details including scopes and breaking changes.

### Before Submitting a PR

1. **Run quality gates:** `./ctl check` (format-check + lint)
2. **Auto-format if needed:** `./ctl format`
3. **Verify MinGW build** (Linux/WSL): `cmake --build build-mingw`
4. **Review the portability checklist** (see PR template)

## Coding Standards

### C++ Conventions

- **Formatting:** Allman braces, 4-space indent, UTF-8, LF (enforced by `.clang-format`)
- **Naming:** PascalCase functions, `m_` prefix + Hungarian hints for members, `CNewUI*` for UI classes, UPPER_SNAKE for constants
- **Memory:** `std::unique_ptr` / `std::shared_ptr` — no raw `new`/`delete`
- **Error handling:** Return codes in game loop (no exceptions), `[[nodiscard]]` on fallible functions
- **Timing:** `std::chrono` (not `timeGetTime`)
- **Paths:** `std::filesystem` with forward slashes (not Win32 APIs)
- **Null:** `nullptr` (not `NULL`)
- **Strings:** `GAME_TEXT("key")` for all user-facing text

### What NOT to Do

- No new Win32 API calls (see banned API table in `docs/development-standards.md`)
- No `#ifdef _WIN32` in game logic (only in platform abstraction layer)
- No backslash path literals or `wchar_t` in new serialization
- No edits to generated files in `src/source/Dotnet/`
- No project headers in `stdafx.h` (system/library includes only)
- No `wprintf` in new code

### C# Conventions (.NET Network Layer)

- StyleCop enforced
- `[UnmanagedCallersOnly]` for Native AOT exports
- `unsafe` only in marshaling layer
- Zero-allocation in hot paths (`Span<byte>`, `stackalloc`)
- VSTHRD103 (async-in-async) is error-level

## Quality Gates

All of these must pass before merge:

| Gate | Tool | Scope |
|------|------|-------|
| Formatting | clang-format | Changed C++ files (all files on `main`) |
| Static analysis | cppcheck | Changed files: warning, performance, portability |
| Build | MinGW `-Wall -Wextra -Werror` | Full project |

## Testing

- **Framework:** Catch2 v3.7.1 (opt-in with `-DBUILD_TESTING=ON`)
- **Test location:** `tests/` mirroring `src/source/` structure
- **What to test:** Pure logic, data loading, protocol encoding/decoding, cross-platform regressions

See `docs/testing-strategy.md` for the full testing approach.

## Documentation

- Update relevant docs when changing behavior
- Load `docs/index.md` for the full documentation map
- Architecture docs live in `docs/` — update them when making structural changes

## Feature Flags

New features use author-prefixed `#define` in `Defined_Global.h`:
```cpp
#define ASG_ADD_GENS_SYSTEM  // Author prefix + feature name
```

## Questions?

Open an issue or check existing documentation in `docs/`.

# Testing Strategy

Testing approach for the MuMain game client covering code quality enforcement, unit testing, and the cross-platform migration validation plan.

For the full ground truth capture specification, see [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md). For phase-specific test criteria, see [CROSS_PLATFORM_PLAN.md](CROSS_PLATFORM_PLAN.md). For daily workflow and setup, see [Development Guide](development-guide.md#code-quality-tooling).

---

## Current State

- **Unit test framework:** Catch2 v3.7.1 via FetchContent (`tests/`, opt-in with `-DBUILD_TESTING=ON`)
- **Code quality gates:** clang-format, cppcheck, `-Wall -Wextra -Werror` (all enforced)
- **Static analysis:** clang-tidy available locally (`make tidy`)
- **CI validation:** MinGW cross-compile + code quality checks on every PR
- **Manual testing:** Launch game, connect to OpenMU server, verify gameplay

---

## Quality Gates

Every PR must pass two CI jobs before merging:

### 1. Code Quality Gates (parallel job)

| Check | Tool | Scope | Blocks? |
|-------|------|-------|---------|
| Formatting | clang-format | Changed C++ files | Yes |
| Static analysis | cppcheck | Changed C++ files | Yes |

### 2. Build (parallel job)

```
cmake --build build-mingw -j$(nproc)
```

Compiles with `-Wall -Wextra -Werror` — every warning is a build error. This is the **single most important test**. If MinGW compilation breaks, the change is rejected.

### 3. Local Enforcement

| Gate | When |
|------|------|
| Pre-commit hook | Blocks commits with unformatted C++ (install via `make hooks`) |
| clang-tidy | Manual (`make tidy`), requires `compile_commands.json` from build |

### Configuration Files

| File | Purpose |
|------|---------|
| `.clang-format` | Allman braces, 4-space indent, no include reordering (PCH safety) |
| `.clang-tidy` | bugprone-\*, modernize-\*, performance-\*, `WarningsAsErrors: '*'` |
| `.cppcheck` | warning, performance, portability; suppresses PCH-related noise |
| `.editorconfig` | C++ indent/encoding rules alongside existing C#/XML rules |

---

## Unit Testing

### Framework

**Catch2 v3.7.1** — fetched via CMake `FetchContent`. Opt-in build:

```bash
cmake -S . -B build-test -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build-test --target MuTests -j$(nproc)
ctest --test-dir build-test --output-on-failure

# Or: make test
```

### Test Structure

Tests live in `tests/` mirroring the `src/source/` module structure:

```
tests/
  core/
    test_timer.cpp      # CTimer, CTimer2
  # Future:
  # data/
  #   test_smd_parser.cpp
  # protocol/
  #   test_packet_encode.cpp
```

### What to Test

Priority order for adding tests to the existing codebase:

1. **Pure logic** — Timer, math utilities, string helpers, config parsing
2. **Data loading** — SMD/BMD parsers, texture validation, INI reader
3. **Protocol** — Packet encoding/decoding, encryption round-trips
4. **Cross-platform migration** — Each SDL3 migration phase adds regression tests (see below)

---

## CI Build Invariant

This invariant is referenced in the [development standards](development-standards.md) and [cross-platform plan](CROSS_PLATFORM_PLAN.md).

---

## Ground Truth Capture (Phase 9)

Baseline data captured from the Windows build BEFORE cross-platform code changes. Enables automated regression testing.

### Essential Captures (Phase 9, Session 9.4)

| # | Capture | Method | Output | Validates |
|---|---------|--------|--------|-----------|
| 1 | **Screenshots** of all 80+ UI screens | Automated sweep via `CNewUIManager`: `Show()` → `glReadPixels` → PNG + SHA256 | `tests/golden/screenshots/*.png` | Rendering parity (Phases 1, 2, 4) |
| 2 | **Text metrics** for all 4 fonts | `GetTextExtentPoint32` on reference strings | `tests/golden/text_metrics.json` | FreeType ±2px match (Phase 4) |
| 10 | **GL state snapshots** at render checkpoints | `glGet*` queries after terrain, models, UI | `tests/golden/opengl/gl_state_*.txt` | SDL_gpu pipeline equivalence (Phase 2) |

Enable via `-DENABLE_GROUND_TRUTH_CAPTURE`. Does not ship in release builds.

### Full Capture Specification (Aspirational)

| # | Capture | Output | Validates |
|---|---------|--------|-----------|
| 3 | Audio catalog (WAV metadata + PCM SHA256) | `tests/golden/audio/audio_catalog.csv` | miniaudio decode parity |
| 4 | Key mapping table (VK_* → game actions) | `tests/golden/input_mapping.json` | SDL3 scancode mapping completeness |
| 5 | BMD text fields (bone names, texture filenames) | `tests/golden/bmd/{filename}.txt` | `ImportChar16ToWchar` correctness |
| 6 | Packet string boundaries | `tests/golden/network/packet_structure.json` | `char16_t` interop correctness |
| 7 | Config round-trip (INI keys, types, defaults) | `tests/golden/config/config_schema.json` | INI parser replacement |
| 8 | File access trace (all `_wfopen` calls) | `tests/golden/file_access.log` | `mu_wfopen` normalization + case folding |
| 9 | UI layout dump for all screens | `tests/golden/ui_layouts/{ClassName}.json` | Font metrics, layout parity |

### Capture Procedure

1. Build Windows debug with `-DENABLE_GROUND_TRUTH_CAPTURE`
2. Launch → login screen auto-captured
3. Character select → auto-captured
4. Enter game at Lorencia → auto-captured
5. Automated UI sweep: all 80+ registered `CNewUI*` windows
6. Walk around (triggers audio + 3D positioning)
7. Type in chat (text metrics captured)
8. Close game → file traces finalized
9. Commit `tests/golden/` to repository

---

## Automated CI Tests (Per Phase)

| Test | Phase | Method |
|------|-------|--------|
| VK_* mapping covers all keys | 1 | Unit test: mapping table completeness |
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

---

## Ground Truth Regression Tests

Run against `tests/golden/` baseline data:

| Test | Phase | Golden File | Pass Criteria |
|------|-------|-------------|---------------|
| File access parity | 0 | `file_access.log` | All paths open via `mu_wfopen` on Linux/macOS |
| Config round-trip | 5 | `config/config_schema.json` | INI parser reads same values for all keys |
| Text metric parity | 4 | `text_metrics.json` | FreeType within ±2px of GDI |
| Word wrap parity | 4 | `text_metrics.json` | `CutStr()` breaks at same positions (±1 char) |
| Audio decode parity | 3 | `audio/audio_catalog.csv` | miniaudio PCM SHA256 matches DirectSound |
| Key mapping completeness | 1 | `input_mapping.json` | SDL3 covers every VK_* code |
| BMD text parsing | 5 | `bmd_text_dump.txt` | `ImportChar16ToWchar` identical strings |
| Screenshot parity | 1, 2 | `screenshots/*.sha256` | Pixel diff within threshold |
| UI layout parity | 4, 6 | `ui_layouts/*.json` | Element positions within ±2px |
| GL state equivalence | 2 | `opengl/gl_state_*.txt` | SDL_gpu pipeline states equivalent |

---

## Manual Test Checklist

### Phase 1 (Window, Input)

- [ ] Window opens and renders 3D scene
- [ ] Mouse click targets correct position
- [ ] Double-click works (inventory items)
- [ ] Mouse wheel scrolls (chat, inventory)
- [ ] All keyboard shortcuts (F1–F12, arrows, Ctrl+combos, Enter, Escape, Tab)
- [ ] Fullscreen toggle

### Phase 2 (SDL_gpu)

- [ ] SDL_gpu rendering identical to GL 2.1 reference
- [ ] Shadow volumes render correctly
- [ ] All 6 blend modes work
- [ ] Screenshot comparison passes

### Phase 3 (Audio)

- [ ] Sound effects play (attack, skill, item pickup)
- [ ] Music loops without gap
- [ ] 3D audio panning (walk around NPC sound sources)

### Phase 4 (Fonts)

- [ ] Korean text renders (no tofu boxes)
- [ ] Font rendering matches at 800x600, 1024x768, 1920x1080
- [ ] Word wrap breaks at same positions

### Phase 5 (Config, Utils)

- [ ] Config persistence (change settings, restart, verify)
- [ ] Shop script and banner downloads work

### Phase 6 (Text Input)

- [ ] Chat text input (type, backspace, enter)
- [ ] Login field input
- [ ] Clipboard paste works

### Phase 8 (.NET)

- [ ] Server connection from Linux/macOS
- [ ] Character movement syncs
- [ ] Chat messages round-trip (including Korean)
- [ ] Game shop loads

---

## Integration Tests (Requires OpenMU Server)

| Test | Phase | Verify |
|------|-------|--------|
| Server connection from Linux/macOS | 8 | TCP connect via .NET bridge |
| Character movement syncs | 8 | Move character, server sees position |
| Chat messages round-trip | 8 | Send/receive including Korean characters |
| Game shop loads | 5 | Open in-game shop, verify item list |

---

## Developer Quick Reference

```bash
make format        # Format all C++ files in-place
make format-check  # Check formatting (same as CI)
make lint          # Run cppcheck
make tidy          # Run clang-tidy (needs build dir)
make hooks         # Install pre-commit hook
make test          # Build + run unit tests
```

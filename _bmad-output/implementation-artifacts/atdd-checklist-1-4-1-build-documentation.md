# ATDD Implementation Checklist: Story 1-4-1-build-documentation

**Story:** 1.4.1 — Build Documentation Per Platform
**Story Type:** infrastructure (documentation-only)
**Generated:** 2026-03-05
**Primary Test Level:** Manual validation (no compiled tests — documentation story)

---

## AC-to-Verification Mapping

| AC | Description | Verification Method | Status |
|----|-------------|---------------------|--------|
| AC-1 | macOS build section in development-guide.md | Manual: verify section exists with prerequisites, cmake preset command, run instructions | Pending |
| AC-2 | Linux native build section in development-guide.md | Manual: verify section exists, distinct from MinGW/WSL section | Pending |
| AC-3 | Toolchain requirements and versions per platform | Manual: verify Clang version (macOS), GCC version (Linux), SDL3 FetchContent notes | Pending |
| AC-4 | Troubleshooting section updated per platform | Manual: verify macOS and Linux failure modes documented | Pending |
| AC-5 | CLAUDE.md build commands updated | Manual: verify macos-arm64, linux-x64 presets added | Pending |
| AC-STD-1 | Documentation follows existing style | Manual: verify Markdown tables, header hierarchy, tone consistency | Pending |
| AC-STD-4 | CI quality gate remains green | Automated: `./ctl check` passes | Pending |
| AC-STD-5 | Conventional commit format | Manual: verify commit message matches `docs(platform): ...` | Pending |
| AC-STD-13 | Quality gate passes | Automated: `./ctl check` (format-check + lint) | Pending |
| AC-STD-15 | Git safety | Manual: no incomplete rebase, no force push | Pending |
| AC-STD-20 | Contract reachability — no API/event entries | Manual: verify no API/event catalog entries produced | Pending |
| AC-VAL-1 | Fresh clone macOS arm64 configure succeeds | Manual: `cmake --preset macos-arm64` on fresh clone following updated docs | Pending |
| AC-VAL-2 | Fresh clone Linux x64 configure succeeds | Manual: `cmake --preset linux-x64` on fresh clone following updated docs | Pending |

---

## Implementation Checklist

### Task 1: Update docs/development-guide.md — macOS section (AC-1, AC-3)

- [ ] 1.1 Add "macOS — Native Build (arm64 + x64)" subsection after existing "macOS — Quality Gates Only" section
- [ ] 1.2 List prerequisites: Xcode CLI tools (Clang 15+ for C++20), cmake, ninja via brew
- [ ] 1.3 Document `cmake --preset macos-arm64` and `cmake --preset macos-x64` configure commands
- [ ] 1.4 Document `cmake --build --preset macos-arm64-debug` build step
- [ ] 1.5 Note SDL3 FetchContent behavior (internet required, ~30 sec on first configure)
- [ ] 1.6 Note .NET SDK requirement for server connectivity

### Task 2: Update docs/development-guide.md — Linux native section (AC-2, AC-3)

- [ ] 2.1 Add "Linux — Native Build (x64)" subsection distinct from existing MinGW section
- [ ] 2.2 List prerequisites: cmake, ninja-build, gcc (12+), g++, libgl1-mesa-dev
- [ ] 2.3 Document `cmake --preset linux-x64` and `cmake --build --preset linux-x64-debug`
- [ ] 2.4 Note SDL3 FetchContent behavior
- [ ] 2.5 Note native Linux binary output (not .exe), Win32 includes guarded by cross-platform headers

### Task 3: Update troubleshooting section (AC-4)

- [ ] 3.1 Add macOS troubleshooting: SDL3 FetchContent slow/fails, cannot find framework
- [ ] 3.2 Add Linux troubleshooting: libGL not found, C++20 features unavailable (GCC 12+), SDL3 FetchContent
- [ ] 3.3 Preserve all existing troubleshooting entries

### Task 4: Update CLAUDE.md build commands (AC-5)

- [ ] 4.1 Add macOS native build commands to "Build Commands (by OS)" section
- [ ] 4.2 Add Linux native build commands alongside existing MinGW WSL commands
- [ ] 4.3 Note macOS native build uses `cmake --preset macos-arm64` (not `./ctl check`)
- [ ] 4.4 Verify all existing CLAUDE.md content preserved (additive only)

### Task 5: Quality gate (AC-STD-4, AC-STD-13)

- [ ] 5.1 Run `./ctl check` (format-check + lint) — must pass
- [ ] 5.2 Verify CMakePresets.json was NOT modified (documentation only)

### Verification Prerequisites

- [ ] Verify exact preset names in `MuMain/CMakePresets.json` before writing docs
- [ ] Verify existing development-guide.md structure and style before adding sections

---

## PCC Compliance

| Check | Status |
|-------|--------|
| No prohibited libraries used | N/A (documentation story) |
| Testing patterns follow project standards | N/A (no compiled tests) |
| Quality gate command verified | `./ctl check` |
| Coverage target met | N/A (documentation story, no code changes) |
| Conventional commit format | `docs(platform): add macOS and Linux build instructions` |
| No Win32 API calls introduced | N/A (no C++ changes) |
| CI (MinGW) build remains green | Required — verify no CMake/C++ files changed |

---

## Output Summary

- **Story ID:** 1-4-1-build-documentation
- **Story Type:** infrastructure (documentation-only)
- **Primary Test Level:** Manual validation
- **Compiled tests created:** 0 (documentation story — no C++ code changes)
- **Checklist items:** 17 task items + 2 verification prerequisites
- **AC coverage:** All 13 ACs (5 functional + 4 standard + 2 NFR + 2 validation) mapped to verification methods
- **Output file:** `_bmad-output/implementation-artifacts/atdd-checklist-1-4-1-build-documentation.md`

---
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
lastSaved: '2026-02-28'
workflowType: 'testarch-test-design'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - docs/testing-strategy.md
---

# Test Design for QA: MuMain Cross-Platform Migration

**Purpose:** Test execution recipe defining what to test, how to test it, and what must be ready before testing begins.

**Date:** 2026-02-28
**Author:** Murat (TEA) / Paco
**Status:** Draft
**Project:** MuMain-workspace

**Related:** See Architecture doc (`test-design-architecture.md`) for testability concerns and architectural blockers.

---

## Executive Summary

**Scope:** Validate the 10-phase SDL3 migration of a C++20 game client across Windows, macOS, and Linux. Three migration paths: rendering (SDL_gpu), networking (.NET AOT), and audio (miniaudio).

**Risk Summary:**

- Total Risks: 12 (1 critical score 9, 4 high score >= 6, 5 medium, 2 low)
- Critical Categories: TECH (rendering parity, .NET interop, marshaling), OPS (no regression suite, no ground truth)

**Coverage Summary:**

- P0 tests: 11 (critical paths, platform loading, shader compilation)
- P1 tests: 14 (abstraction layers, audio, input, manual sessions)
- P2 tests: 10 (format spot-checks, UI regression, debug infra)
- P3 tests: 6 (benchmarks, completeness)
- **Total**: 41 scenarios (~70-110 hours solo developer)

---

## Not in Scope

| Item | Reasoning | Mitigation |
|---|---|---|
| **OpenMU server testing** | Server is a separate open-source project | Document compatible version; test client-side only |
| **Font rendering (FreeType)** | Explicitly post-MVP per PRD | Platform fallbacks initially; Phase 7 |
| **Pre-built binary distribution** | MVP is build-from-source | No installer testing needed |
| **Non-showstopper legacy bugs** | Triaged to Phase 2 backlog per PRD | Fix only if blocking core gameplay |
| **Mobile/tablet platforms** | Post-MVP vision feature | SDL3 touch input deferred |

---

## Dependencies & Test Blockers

### Dev Dependencies (Pre-Implementation)

**Source:** See Architecture doc "Quick Guide" for detailed mitigation plans.

1. **Ground truth capture mechanism (R5)** - Dev - Before Phase 3
   - QA needs baselines in `tests/golden/` to validate rendering migration
   - Blocks all visual regression testing

2. **macOS/Linux CMake build (ASR-5)** - Dev - Phase 0
   - QA needs buildable binaries on target platforms
   - Blocks all platform-specific integration and manual tests

3. **mu::MuTimer instrumentation (R6)** - Dev - Phase 0
   - QA needs frame time data to validate NFR1-NFR3
   - Blocks performance benchmarks

### Test Infrastructure Setup

1. **Catch2 test expansion**
   - Extend `tests/` directory structure mirroring `src/source/` modules
   - Add test files per abstraction layer: `tests/platform/`, `tests/renderfx/`, `tests/audio/`, `tests/protocol/`

2. **Ground truth test data**
   - Windows debug build with `-DENABLE_GROUND_TRUTH_CAPTURE`
   - Baseline screenshots, text metrics, GL state committed to `tests/golden/`

3. **OpenMU test instance**
   - Local OpenMU server for integration tests (FR6-FR11)
   - Document compatible version and setup steps

**Example Catch2 test pattern:**

```cpp
#include <catch2/catch_test_macros.hpp>
#include "Platform/PlatformLibrary.h"

TEST_CASE("PlatformLibrary loads .NET AOT library", "[platform][p0]")
{
    auto lib = mu::PlatformLibrary::Load("ClientLibrary");
    REQUIRE(lib != nullptr);

    auto initFn = mu::PlatformLibrary::GetSymbol(lib, "Initialize");
    REQUIRE(initFn != nullptr);

    mu::PlatformLibrary::Close(lib);
}

TEST_CASE("PlatformLibrary returns null on missing library", "[platform][p0]")
{
    auto lib = mu::PlatformLibrary::Load("NonExistentLibrary");
    REQUIRE(lib == nullptr);
    // Verify error was logged
}
```

---

## Risk Assessment

**Full risk details in Architecture doc. Summary relevant to QA test planning:**

### High-Priority Risks (Score >= 6)

| Risk ID | Category | Description | Score | QA Test Coverage |
|---|---|---|---|---|
| **R1** | TECH | SDL_gpu rendering differs from OpenGL baseline | **9** | Ground truth screenshot comparison (SSIM > 0.99) per migration PR |
| **R2** | TECH | .NET AOT dlopen fails on macOS/Linux | **6** | Catch2 smoke test: load + symbol resolve + ping |
| **R3** | TECH | char16_t marshaling corrupts packets | **6** | Catch2 round-trip with Korean/Latin test vectors |
| **R4** | OPS | No automated regression suite | **6** | Progressive Catch2 expansion per migration phase |
| **R5** | OPS | Ground truth capture not implemented | **6** | Validate capture mechanism produces PNG + SHA256 |

### Medium/Low-Priority Risks

| Risk ID | Category | Description | Score | QA Test Coverage |
|---|---|---|---|---|
| R6 | PERF | Frame time regression on macOS Metal | 4 | mu::MuTimer benchmarks |
| R7 | OPS | No macOS/Linux CI | 4 | Manual builds until native CI runners |
| R8 | OPS | No crash reporting on macOS/Linux | 4 | POSIX signal handler validation |
| R9 | TECH | miniaudio decode differences | 4 | WAV PCM SHA256 + OGG/MP3 spot-checks |
| R10 | TECH | OpenMU protocol mismatch | 3 | Handshake test in Phase 2.5 |
| R11 | SEC | Encryption cross-platform divergence | 3 | Round-trip with known test vectors |
| R12 | TECH | Global state pollution in tests | 2 | Sequential Catch2 execution |

---

## Entry Criteria

- [ ] macOS and Linux CMake builds produce executable binaries
- [ ] Catch2 test infrastructure extended with module directories
- [ ] Ground truth baselines captured and committed (for rendering phases)
- [ ] OpenMU server instance available (for network phases)
- [ ] Pre-implementation blockers resolved (see Dependencies)
- [ ] Migration phase code deployed to test branch

## Exit Criteria

- [ ] All P0 tests passing on all three platforms
- [ ] All P1 tests passing (or failures triaged and accepted)
- [ ] No crashes during 60-minute gameplay sessions on macOS and Linux
- [ ] Ground truth screenshot comparison passes (SSIM > 0.99)
- [ ] CI quality gates green (clang-format + cppcheck + build) on all platforms
- [ ] .NET AOT loads and connects to OpenMU on macOS and Linux

---

## Test Coverage Plan

**IMPORTANT:** P0/P1/P2/P3 = **priority and risk level** (what to focus on if time-constrained), NOT execution timing. See "Execution Strategy" for when tests run.

### P0 (Critical)

**Criteria:** Blocks core functionality + High risk (>= 6) + No workaround

| Test ID | Requirement | Test Level | Risk Link | Notes |
|---|---|---|---|---|
| **P0-01** | FR6, FR9 | Unit (Catch2) | R2 | PlatformLibrary dlopen .NET AOT on macOS |
| **P0-02** | FR7, FR9 | Unit (Catch2) | R2 | PlatformLibrary dlopen .NET AOT on Linux |
| **P0-03** | NFR9 | Unit (Catch2) | R3 | char16_t round-trip Korean + Latin strings |
| **P0-04** | NFR6 | Unit (Catch2) | R11 | SimpleModulus + XOR3 encryption round-trip |
| **P0-05** | FR12-14 | Unit (Catch2) | R1 | MuRenderer::RenderQuad2D offscreen output |
| **P0-06** | FR12-14 | Build/CI | R1 | All 5 HLSL shaders compile via SDL_shadercross |
| **P0-07** | FR15 | Integration | R5 | Ground truth capture produces PNG + SHA256 |
| **P0-08** | FR6, FR23 | Integration | R2 | OpenMU handshake from macOS |
| **P0-09** | FR1 | Build/CI | R7 | CMake builds on macOS (native Clang) |
| **P0-10** | FR2 | Build/CI | R7 | CMake builds on Linux (native GCC) |
| **P0-11** | FR10 | Unit (Catch2) | R2 | Graceful error when .NET library not found |

**Total P0:** 11 tests

---

### P1 (High)

**Criteria:** Critical paths + Medium/high risk + Common workflows

| Test ID | Requirement | Test Level | Risk Link | Notes |
|---|---|---|---|---|
| **P1-01** | FR12-16 | Unit (Catch2) | R1 | MuRenderer all 5 core functions |
| **P1-02** | FR17-19 | Unit (Catch2) | R9 | MuAudio Init/PlayBGM/PlaySFX/Shutdown lifecycle |
| **P1-03** | FR19 | Unit (Catch2) | R9 | WAV decode parity (PCM SHA256 comparison) |
| **P1-04** | FR16 | Integration | R7 | SDL3 window create/resize/minimize/focus macOS |
| **P1-05** | FR16 | Integration | R7 | SDL3 window create/resize/minimize/focus Linux |
| **P1-06** | FR20 | Integration | — | SDL3 keyboard input (F1-F12, arrows, Ctrl+combos) |
| **P1-07** | FR21 | Integration | — | SDL3 mouse input (click, double-click, wheel, drag) |
| **P1-08** | NFR12 | Unit (Catch2) | — | Path normalization backslash -> forward slash |
| **P1-09** | FR39, NFR18 | Unit (Catch2) | R8 | Error taxonomy all 7 prefixes write to MuError.log |
| **P1-10** | NFR1-3 | Unit (Catch2) | R6 | mu::MuTimer accuracy within 1ms |
| **P1-11** | FR15 | Integration | R1 | Screenshot comparison SSIM > 0.99 between platforms |
| **P1-12** | FR37 | System/Manual | R1 | Full gameplay session macOS (60+ min) |
| **P1-13** | FR38 | System/Manual | R1 | Full gameplay session Linux (60+ min) |
| **P1-14** | FR39 | Integration | R8 | POSIX signal handlers write diagnostics before exit |

**Total P1:** 14 tests

---

### P2 (Medium)

**Criteria:** Secondary features + Low/medium risk + Edge cases

| Test ID | Requirement | Test Level | Risk Link | Notes |
|---|---|---|---|---|
| **P2-01** | FR19 | Unit (Catch2) | R9 | OGG Vorbis decode spot-check (5 files) |
| **P2-02** | FR19 | Unit (Catch2) | R9 | MP3 decode spot-check (5 files) |
| **P2-03** | FR12 | Integration | — | Texture loading via SDL_gpu (CGlobalBitmap) |
| **P2-04** | FR35 | Visual Regression | — | All 84 UI windows render without crash |
| **P2-05** | FR22 | Integration/Manual | — | SDL3 text input in chat and login fields |
| **P2-06** | — | Unit (Catch2) | — | INI config read/write round-trip |
| **P2-07** | NFR9 | Unit (Catch2) | — | BMD ImportChar16ToWchar correct strings |
| **P2-08** | FR39 | Integration | — | Network packet tracing (debug flag) |
| **P2-09** | NFR15 | CI | — | clang-tidy clean on new abstraction files |
| **P2-10** | NFR11 | CI | — | No #ifdef _WIN32 in game logic (static check) |

**Total P2:** 10 tests

---

### P3 (Low)

**Criteria:** Nice-to-have + Exploratory + Benchmarks

| Test ID | Requirement | Test Level | Notes |
|---|---|---|---|
| **P3-01** | NFR1 | Benchmark | FPS benchmark: sustained 30+ FPS macOS/Linux |
| **P3-02** | NFR3 | Benchmark | Frame time variance: no >50ms hitches in 60-min session |
| **P3-03** | FR20 | Unit (Catch2) | VK_* to SDL3 scancode mapping completeness |
| **P3-04** | NFR12 | Unit (Catch2) | File access trace: all wfopen paths via mu_wfopen |
| **P3-05** | FR35 | Visual Regression | UI layout dump comparison (positions within +/-2px) |
| **P3-06** | FR18 | Manual | Audio 3D panning around NPC sound sources |

**Total P3:** 6 tests

---

## Execution Strategy

**Philosophy:** Run all automated tests on every PR when possible. Defer only manual sessions and performance benchmarks.

### Every PR: Catch2 Unit + Integration Tests (< 10 min)

All Catch2 tests run automatically via CMake CTest:
- Platform abstraction, protocol, audio decode, path normalization, error taxonomy
- Build/CI: clang-format + cppcheck + MinGW build + Catch2 tests
- Total: all P0/P1/P2 automated tests

### Per-Phase Completion: Ground Truth Comparison (< 30 min)

- Screenshot comparison (SSIM) against `tests/golden/` baselines
- SDL3 integration tests (window, input) on each target platform
- .NET AOT loading validation on macOS/Linux
- Run manually by developer on each target platform

### Pre-MVP Gate: Manual Sessions + Benchmarks (~4 hours)

- Full gameplay sessions (60+ min) on macOS and Linux
- Performance benchmarks (FPS, frame time variance)
- Visual regression sweep of all 84 UI windows
- Audio parity spot-checks

---

## QA Effort Estimate

| Priority | Count | Effort Range | Notes |
|---|---|---|---|
| P0 | 11 | ~20-30 hours | Ground truth mechanism, .NET smoke tests, shader CI |
| P1 | 14 | ~30-45 hours | Abstraction layer tests, audio, SDL3 integration, manual sessions |
| P2 | 10 | ~15-25 hours | Format checks, UI sweep, config round-trip, static analysis |
| P3 | 6 | ~5-10 hours | Benchmarks, completeness, layout comparison |
| **Total** | **41** | **~70-110 hours** | **Solo developer, spread across migration phases** |

**Assumptions:**

- Includes test design, implementation, debugging, CI integration
- Effort is spread across the multi-phase migration timeline (not contiguous)
- Ground truth capture and comparison tooling is the largest single investment

---

## Implementation Planning Handoff

| Work Item | Owner | Target Phase | Dependencies |
|---|---|---|---|
| Ground truth capture mechanism | Dev | Before Phase 3 | Windows debug build available |
| Catch2 test directory expansion | Dev | Phase 0 | CMake build works with -DBUILD_TESTING=ON |
| PlatformLibrary smoke tests | Dev | Phase 0 | MUPlatform module scaffolded |
| char16_t marshaling tests | Dev | Phase 2.5 | .NET AOT builds for macOS/Linux |
| MuRenderer unit tests | Dev | Phase 3 | MuRenderer abstraction API defined |
| Screenshot comparison utility | Dev | Phase 3 | Ground truth baselines committed |
| MuAudio unit tests | Dev | Phase 6 | MuAudio abstraction API defined |
| macOS CI runner | Dev | Post-migration | Full macOS build working |
| Linux CI runner | Dev | Post-migration | Full Linux build working |

---

## Tooling & Access

| Tool | Purpose | Status |
|---|---|---|
| Catch2 3.7.1 | Unit + integration tests | Ready (FetchContent) |
| CMake + Ninja | Build system | Ready |
| clang-format 21.1.8 | Code formatting | Ready |
| cppcheck | Static analysis | Ready |
| clang-tidy | Extended analysis | Ready (local) |
| OpenMU server | Integration testing | Pending (local instance needed) |
| SSIM comparison tool | Visual regression | Pending (needs implementation or library selection) |

---

## Interworking & Regression

| Service/Component | Impact | Regression Scope | Validation |
|---|---|---|---|
| **OpenMU Server** | Client connects via .NET AOT bridge | Protocol handshake, packet encoding/decoding | Handshake test in Phase 2.5 |
| **SDL3 / SDL_gpu** | Core rendering, windowing, input | Window creation, shader compilation, input handling | Catch2 integration tests per phase |
| **miniaudio** | Audio playback | WAV/OGG/MP3 decoding | PCM SHA256 comparison |
| **.NET Native AOT** | Network packet handling | Library loading, function binding, string marshaling | Smoke test + char16_t round-trip |
| **Existing Windows build** | Must not regress | All gameplay functionality | CI MinGW build + manual Windows session |

**Regression strategy:**

- MinGW CI build ensures Windows compilation never breaks
- Ground truth baselines captured from Windows build serve as regression reference
- Each migration phase validates parity against Windows baseline

---

## Appendix A: Test Tagging Convention

Catch2 tag convention for selective execution:

```cpp
// Priority tags
TEST_CASE("test name", "[platform][p0]")     // P0 critical
TEST_CASE("test name", "[renderfx][p1]")     // P1 high
TEST_CASE("test name", "[audio][p2]")        // P2 medium

// Module tags
// [platform] [renderfx] [audio] [protocol] [core] [game]

// Run specific priorities
// ctest --test-dir build-test -L p0           # P0 only
// ctest --test-dir build-test -L "p0|p1"      # P0 + P1
// ctest --test-dir build-test                  # All tests
```

---

## Appendix B: Knowledge Base References

- **Risk Governance**: `risk-governance.md` — Risk scoring methodology (P x I = 1-9)
- **Test Levels Framework**: `test-levels-framework.md` — Unit vs Integration vs E2E selection
- **Test Quality**: `test-quality.md` — Definition of Done (deterministic, isolated, focused)
- **ADR Quality Readiness**: `adr-quality-readiness-checklist.md` — 29-criteria testability framework

---

**Generated by:** BMad TEA Agent
**Workflow:** `_bmad/tea/testarch/test-design`

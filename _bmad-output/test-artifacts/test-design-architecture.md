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

# Test Design for Architecture: MuMain Cross-Platform Migration

**Purpose:** Architectural testability concerns, risk assessment, and NFR requirements for the SDL3 cross-platform migration. Serves as a contract between QA and Dev on what must be addressed before test development begins.

**Date:** 2026-02-28
**Author:** Murat (TEA) / Paco
**Status:** Architecture Review Pending
**Project:** MuMain-workspace
**PRD Reference:** `_bmad-output/planning-artifacts/prd.md`
**ADR Reference:** `_bmad-output/planning-artifacts/architecture.md`

---

## Executive Summary

**Scope:** 10-phase SDL3 migration of a 692-file C++20 game client from Windows-only to cross-platform (macOS, Linux, Windows). Three critical migration paths: rendering (SDL_gpu), networking (.NET Native AOT), and audio (miniaudio).

**Architecture:**

- **Decision 1:** MuRenderer abstraction layer with SDL_gpu backend (111 glBegin sites consolidated to ~5 functions)
- **Decision 2:** Compile-time CMake platform backends (MUPlatform/win32/ and MUPlatform/posix/)
- **Decision 3:** .NET AOT cross-platform library loading with char16_t encoding
- **Decision 4:** MuAudio abstraction with miniaudio backend
- **Decision 5:** Phased CI expansion (MinGW now, native runners post-migration)
- **Decision 6:** .NET AOT moved to Phase 2.5 for early end-to-end validation

**Risk Summary:**

- **Total risks**: 12
- **Critical (score 9)**: 1 risk requiring immediate mitigation (rendering parity)
- **High-priority (score >= 6)**: 4 additional risks requiring mitigation plans
- **Test effort**: ~41 scenarios (~70-110 hours for solo developer)

---

## Quick Guide

### BLOCKERS - Must Be Completed Before Testing

1. **R5: Ground Truth Capture** - Implement screenshot + SHA256 baseline mechanism (`-DENABLE_GROUND_TRUTH_CAPTURE`) before Phase 3 MuRenderer abstraction begins. Without this, rendering migration is blind. (Owner: Dev)
2. **R1: Rendering Validation Pipeline** - Ground truth baselines must be captured from Windows OpenGL build and committed to `tests/golden/` before any SDL_gpu conversion starts. (Owner: Dev, depends on R5)
3. **ASR-5: macOS/Linux Build Validation** - CMake must successfully produce a binary on macOS and Linux before platform-specific integration tests can be written. (Owner: Dev, Phase 0)

### HIGH PRIORITY - Validate Early

1. **R2: .NET AOT Loading** - Validate `dlopen`/`dlsym` loads ClientLibrary on macOS/Linux in Phase 2.5. Build a smoke test: load library, call ping function, verify response. (Owner: Dev)
2. **R3: char16_t Marshaling** - Unit test round-trip of Korean + Latin strings through the C++/.NET boundary before any network testing on macOS/Linux. (Owner: Dev)
3. **R4: Automated Regression** - Catch2 unit tests for all new abstraction layer functions (MuRenderer, MuAudio, PlatformLibrary) must exist before the corresponding migration phase begins. (Owner: Dev)

### INFO ONLY - Solutions Provided

1. **Test framework**: Catch2 3.7.1 (unit + integration), ground truth comparison (visual regression), manual gameplay sessions (system)
2. **CI quality gates**: clang-format + cppcheck + MinGW build (existing), native platform builds added post-migration
3. **Coverage**: 41 test scenarios prioritized P0-P3 with risk-based classification
4. **Quality gates**: P0 100% pass, P1 >= 95% pass, all 3 platforms CI green before MVP

---

## Risk Assessment

**Total risks identified**: 12 (1 critical, 4 high, 5 medium, 2 low)

### High-Priority Risks (Score >= 6) - IMMEDIATE ATTENTION

| Risk ID | Category | Description | P | I | Score | Mitigation | Owner | Timeline |
|---|---|---|---|---|---|---|---|---|
| **R1** | **TECH** | SDL_gpu rendering differs from OpenGL baseline across 111 call sites in 14 files | 3 | 3 | **9** | Ground truth capture first; migrate one function at a time with screenshot comparison | Dev | Before Phase 3 |
| **R2** | **TECH** | .NET AOT dlopen fails on macOS/Linux (untested platforms) | 2 | 3 | **6** | Smoke test: load -> ping -> verify. Validate early in Phase 2.5 | Dev | Phase 2.5 |
| **R3** | **TECH** | char16_t marshaling produces corrupt packet data (wchar_t is 4 bytes on Linux/macOS) | 2 | 3 | **6** | Unit test: round-trip Korean/Latin strings, compare byte output to Windows baseline | Dev | Phase 2.5 |
| **R4** | **OPS** | No automated regression suite; silent breakage during multi-phase migration | 3 | 2 | **6** | Prioritize Catch2 tests for abstraction layers before each migration phase | Dev | Ongoing |
| **R5** | **OPS** | Ground truth capture mechanism not implemented; no baseline for visual comparison | 3 | 2 | **6** | Implement `-DENABLE_GROUND_TRUTH_CAPTURE`, capture from Windows build, commit to tests/golden/ | Dev | Before Phase 3 |

### Medium-Priority Risks (Score 3-5)

| Risk ID | Category | Description | P | I | Score | Mitigation | Owner |
|---|---|---|---|---|---|---|---|
| R6 | PERF | Frame time regression (>50ms hitches) on macOS Metal | 2 | 2 | 4 | Implement mu::MuTimer instrumentation | Dev |
| R7 | OPS | Platform-specific bugs with no macOS/Linux CI coverage | 2 | 2 | 4 | Developer-validated native builds until CI runners added | Dev |
| R8 | OPS | No crash reporting on macOS/Linux (no stack traces) | 2 | 2 | 4 | Add POSIX signal handlers writing to MuError.log | Dev |
| R9 | TECH | miniaudio decode differences vs DirectSound for 30K audio assets | 2 | 2 | 4 | WAV PCM SHA256 comparison; OGG/MP3 spot-checks | Dev |
| R12 | OPS | Platform-specific bugs only manifest on target OS | 2 | 2 | 4 | Manual testing on each target platform per phase | Dev |

### Low-Priority Risks (Score 1-2)

| Risk ID | Category | Description | P | I | Score | Action |
|---|---|---|---|---|---|---|
| R10 | TECH | OpenMU protocol version mismatch | 1 | 3 | 3 | Document compatible version; handshake test |
| R11 | SEC | Packet encryption (SimpleModulus + XOR3) cross-platform divergence | 1 | 3 | 3 | Unit test with known test vectors |

---

## Testability Concerns and Architectural Gaps

### ACTIONABLE CONCERNS

#### 1. Blockers to Fast Feedback

| Concern | Impact | What Architecture Must Provide | Owner | Timeline |
|---|---|---|---|---|
| **No ground truth baselines** | Cannot validate rendering migration | Implement capture mechanism + commit baselines to tests/golden/ | Dev | Before Phase 3 |
| **No frame time instrumentation** | Cannot validate NFR1-NFR3 performance requirements | Implement mu::MuTimer in MUCore (std::chrono wrapper) | Dev | Phase 0 |
| **No crash diagnostics on macOS/Linux** | Cannot diagnose failures on target platforms | POSIX signal handlers for SIGSEGV/SIGABRT writing to MuError.log | Dev | Phase 0 |

#### 2. Architectural Improvements Needed

1. **Perceptual image comparison (not SHA256 exact match)**
   - **Current**: Testing strategy specifies SHA256 for screenshot comparison
   - **Required**: Use perceptual diff (SSIM > 0.99) — GPU rendering is not pixel-exact across Metal/Vulkan/D3D
   - **Impact if not fixed**: Every platform comparison fails, rendering migration cannot be validated
   - **Owner**: Dev

2. **.NET library load failure graceful degradation**
   - **Current**: Architecture doc mentions graceful degradation (FR10), but mechanism is unspecified
   - **Required**: Clear error message identifying failure type + specific corrective action per platform
   - **Impact if not fixed**: Users on macOS/Linux get cryptic failures when .NET library missing
   - **Owner**: Dev

3. **Dependency inversion for new abstraction layers**
   - **Current**: Codebase uses concrete GetInstance() singletons throughout. New abstractions (MuRenderer, MuAudio, PlatformLibrary) are being designed from scratch.
   - **Required**: New abstraction layers must define abstract interfaces (e.g., `IMuRenderer`, `IMuAudio`) with concrete implementations (e.g., `SdlGpuRenderer`, `MiniaudioBackend`). This enables test doubles without requiring GPU/audio hardware.
   - **Impact if not fixed**: Unit tests for game logic that renders or plays audio require real hardware, making CI-level testing impractical and slowing feedback loops.
   - **Boy scout rule**: When modifying existing code during migration, apply dependency inversion where practical — extract interfaces from touched classes, accept abstractions via constructor/factory rather than calling GetInstance() directly. Progressive improvement, not a big-bang refactor.
   - **Owner**: Dev
   - **Timeline**: Phase 0 onward (design interfaces before implementing backends)

---

### Testability Assessment Summary

#### What Works Well

- New abstraction layers (MuRenderer, MuAudio, PlatformLibrary) have clean, testable interfaces with ~5-8 functions each
- CMake modular targets (MUCore, MUProtocol, MURenderFX, MUAudio) allow independent compilation and testing
- Catch2 3.7.1 integrated and working with opt-in `-DBUILD_TESTING=ON`
- Error taxonomy (7 domain prefixes: PLAT, RENDER, AUDIO, NET, ASSET, GAME, INPUT) enables structured diagnostics
- Protocol layer (packet encoding/decoding/encryption) is deterministic and independently testable
- Ground truth capture plan is well-documented in testing-strategy.md (just needs implementation)

#### Architecture Context (Testing Implications)

- **Single-threaded game loop** — Tests run sequentially via Catch2. No thread-safety concerns for test isolation.
- **Existing singletons (GetInstance() pattern)** — Not retrofitting the entire codebase. Existing 692 files stay as-is. Boy scout rule applies when code is touched during migration.
- **New abstractions use dependency inversion** — MuRenderer, MuAudio, PlatformLibrary designed with abstract interfaces from day one. Enables test doubles, hardware-free unit testing, and true isolation.

---

## Risk Mitigation Plans (High-Priority Risks >= 6)

### R1: SDL_gpu Rendering Parity (Score: 9) - CRITICAL

**Mitigation Strategy:**

1. Implement ground truth capture mechanism (R5 dependency)
2. Capture baseline screenshots from Windows OpenGL build for all 80+ UI screens
3. Migrate one RenderBitmap function at a time (not entire files)
4. After each migration, run ground truth comparison using SSIM perceptual diff
5. Mandatory screenshot comparison in each migration PR

**Owner:** Dev
**Timeline:** Ground truth before Phase 3; ongoing validation through Phases 3-4
**Status:** Planned
**Verification:** SSIM > 0.99 for all captured screens on macOS and Linux

### R2: .NET AOT dlopen on macOS/Linux (Score: 6) - HIGH

**Mitigation Strategy:**

1. Build ClientLibrary with correct RID (osx-arm64, linux-x64)
2. Create Catch2 smoke test: PlatformLibrary::Load("ClientLibrary") + symbol resolution
3. Validate in Phase 2.5 before any network-dependent testing

**Owner:** Dev
**Timeline:** Phase 2.5
**Status:** Planned
**Verification:** Smoke test passes on macOS and Linux in CI

### R3: char16_t Marshaling (Score: 6) - HIGH

**Mitigation Strategy:**

1. Create Catch2 unit test with known Korean + Latin test strings
2. Marshal through char16_t boundary, compare byte output to Windows wchar_t baseline
3. Test packet encoding round-trip with SimpleModulus encryption

**Owner:** Dev
**Timeline:** Phase 2.5
**Status:** Planned
**Verification:** Byte-level output matches Windows baseline for all test vectors

### R4: No Automated Regression Suite (Score: 6) - HIGH

**Mitigation Strategy:**

1. Write Catch2 tests for each new abstraction layer function before the migration phase that uses it
2. Add tests to CI (run on every PR via `-DBUILD_TESTING=ON`)
3. Progressive expansion: MUPlatform (Phase 0) -> MuRenderer (Phase 3) -> MuAudio (Phase 6)

**Owner:** Dev
**Timeline:** Ongoing, before each migration phase
**Status:** In Progress (1 test file exists)
**Verification:** Catch2 test count grows with each phase; CI runs all tests

### R5: Ground Truth Capture Not Implemented (Score: 6) - HIGH

**Mitigation Strategy:**

1. Implement `-DENABLE_GROUND_TRUTH_CAPTURE` build flag
2. Automated sweep: Show() each CNewUI* window, capture via glReadPixels -> PNG + SHA256
3. Capture text metrics, GL state, audio catalog from Windows debug build
4. Commit baselines to tests/golden/

**Owner:** Dev
**Timeline:** Before Phase 3
**Status:** Planned (documented in testing-strategy.md, not yet implemented)
**Verification:** tests/golden/ directory populated with baseline data

---

## Assumptions and Dependencies

### Assumptions

1. OpenMU server is available for integration testing (local instance or accessible remote)
2. macOS arm64 and Linux x64 are the primary non-Windows targets (no 32-bit cross-platform)
3. Perceptual image diff (SSIM) is acceptable for rendering comparison (not pixel-exact SHA256)
4. Solo developer workflow means sequential phase execution (no parallel team work)

### Dependencies

1. SDL3 stable release with SDL_gpu API — Required before Phase 3
2. .NET 10 Native AOT supports macOS arm64 and Linux x64 — Required for Phase 2.5
3. OpenMU compatible version documented — Required for Phase 2.5 integration testing

### Risks to Plan

- **Risk**: SDL3 SDL_gpu API changes before migration completes
  - **Impact**: MuRenderer backend code needs rework
  - **Contingency**: Pin SDL3 version in CMake FetchContent; update only between phases

---

**End of Architecture Document**

**Next Steps for Dev:**

1. Implement ground truth capture mechanism (R5 — highest priority)
2. Capture baselines from Windows build before any rendering changes
3. Build macOS/Linux CMake successfully (Phase 0 prerequisite)
4. Write Catch2 smoke test for .NET AOT loading (Phase 2.5)

**Next Steps for QA/Testing:**

1. Refer to companion QA doc (`test-design-qa.md`) for test scenarios and execution plan
2. Begin with P0 tests as each migration phase completes

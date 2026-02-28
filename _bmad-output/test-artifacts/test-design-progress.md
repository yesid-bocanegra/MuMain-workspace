---
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
status: 'complete'
completedAt: '2026-02-28'
lastSaved: '2026-02-28'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - docs/testing-strategy.md
  - _bmad/tea/testarch/knowledge/adr-quality-readiness-checklist.md
  - _bmad/tea/testarch/knowledge/test-levels-framework.md
  - _bmad/tea/testarch/knowledge/risk-governance.md
  - _bmad/tea/testarch/knowledge/test-quality.md
---

# Step 1: Mode Detection & Prerequisites

## Mode Decision
- **Selected Mode**: System-Level (Phase 3)
- **Rationale**: PRD + Architecture docs available, no epic/story artifacts present
- **User Confirmation**: User selected option (A) — System-Level

## Prerequisites Verified
- PRD: `_bmad-output/planning-artifacts/prd.md`
- Architecture (planning): `_bmad-output/planning-artifacts/architecture.md`
- Architecture docs: 5 files in `docs/` (mumain, clientlibrary, constantsreplacer, mueditor, rendering)

## Outputs
- Architecture testability doc: `_bmad-output/test-artifacts/test-design-architecture.md`
- QA coverage doc: `_bmad-output/test-artifacts/test-design-qa.md`

# Step 2: Context & Knowledge Base

## Configuration
- Stack type: backend (C++20, .NET AOT, CMake)
- Browser automation: N/A (desktop game client)
- Test framework: Catch2 v3.7.1

## Artifacts Loaded
- PRD: 40 FRs, 18 NFRs
- Architecture: 6 decisions, 7 implementation patterns
- Testing Strategy: CI gates, ground truth capture plan, 1 existing test file

## Knowledge Fragments (System-Level)
- adr-quality-readiness-checklist.md
- test-levels-framework.md
- risk-governance.md
- test-quality.md

## Key Extractions
- Tech: C++20, SDL3/SDL_gpu, .NET 10 Native AOT, miniaudio, CMake, Catch2
- Integration: OpenMU server (TCP), .NET AOT interop, SDL3 platform backends
- Existing coverage: 1 unit test, CI quality gates, manual checklists
- NFRs: Performance, Security, Integration, Portability, Maintainability

# Step 3: Testability & Risk Assessment

## Testability Concerns
- Controllability: No frame time instrumentation yet; ground truth capture mechanism not implemented; new abstraction layers need dependency inversion (abstract interfaces) to enable test doubles
- Controllability (Boy Scout): Existing singletons stay as-is, but apply dependency inversion progressively when touching code during migration
- Observability: No crash reporting on macOS/Linux (no stack traces in MuError.log)
- Reliability: Non-deterministic GPU rendering across Metal/Vulkan/D3D requires perceptual diff, not exact match

## Testability Strengths
- New abstraction layers (MuRenderer, MuAudio, PlatformLibrary) being designed with abstract interfaces from day one
- CMake modular targets allow independent module testing
- Catch2 integrated, error taxonomy defined, ground truth capture plan documented

## ASRs
- ASR-1 (ACTIONABLE): .NET AOT library loading on macOS/Linux
- ASR-2 (ACTIONABLE): SDL_gpu rendering parity (111 sites)
- ASR-3 (ACTIONABLE): char16_t encoding at .NET boundary
- ASR-4 (ACTIONABLE): miniaudio format support (30K assets)
- ASR-5 (ACTIONABLE): CI quality gates on macOS/Linux
- ASR-6 (FYI): Single-threaded game loop
- ASR-7 (FYI): Global singleton architecture

## Risk Matrix (Top Risks)
- R1 (CRITICAL/9): SDL_gpu rendering differs from OpenGL baseline
- R2 (HIGH/6): .NET AOT dlopen fails on macOS/Linux
- R3 (HIGH/6): char16_t marshaling corrupts packets
- R4 (HIGH/6): No automated regression suite
- R5 (HIGH/6): Ground truth capture not implemented

## Gate Recommendation
CONCERNS — proceed with mitigation plan. R1+R5 dependency chain is priority #1.

# Step 4: Coverage Plan & Execution Strategy

## Coverage Summary
- 41 total scenarios: 11 P0, 14 P1, 10 P2, 6 P3
- Test levels: Unit (Catch2), Integration (Catch2 + deps), System/Manual, Visual Regression, Build/CI
- No duplicate coverage across levels

## Execution Strategy
- Every PR: CI gates + Catch2 unit tests (<10 min)
- Per-Phase: Integration + ground truth comparison (<30 min)
- Pre-MVP: Manual gameplay sessions + visual regression + benchmarks (~4 hours)

## Resource Estimates
- P0: ~20-30h | P1: ~30-45h | P2: ~15-25h | P3: ~5-10h | Total: ~70-110h

## Quality Gates
- P0: 100% pass rate | P1: ≥95% | Catch2 coverage: ≥80% new code
- R1 mitigated before Phase 3 | R2-R5 mitigated before Phase 2.5 completion
- All 3 platforms CI green + 60-min stable session before MVP

# Step 5: Output Generation & Validation

## Documents Generated
1. `_bmad-output/test-artifacts/test-design-architecture.md` — Architecture testability doc
2. `_bmad-output/test-artifacts/test-design-qa.md` — QA execution recipe
3. `_bmad-output/test-artifacts/test-design/MuMain-workspace-handoff.md` — BMAD integration handoff

## Workflow Complete

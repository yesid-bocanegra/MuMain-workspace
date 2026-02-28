---
title: 'TEA Test Design → BMAD Handoff Document'
version: '1.0'
workflowType: 'testarch-test-design-handoff'
inputDocuments:
  - _bmad-output/test-artifacts/test-design-architecture.md
  - _bmad-output/test-artifacts/test-design-qa.md
sourceWorkflow: 'testarch-test-design'
generatedBy: 'TEA Master Test Architect'
generatedAt: '2026-02-28'
projectName: 'MuMain-workspace'
---

# TEA → BMAD Integration Handoff

## Purpose

This document bridges TEA's test design outputs with BMAD's epic/story decomposition workflow (`create-epics-and-stories`). It provides structured integration guidance so that quality requirements, risk assessments, and test strategies flow into implementation planning.

## TEA Artifacts Inventory

| Artifact | Path | BMAD Integration Point |
|---|---|---|
| Architecture Test Design | `_bmad-output/test-artifacts/test-design-architecture.md` | Epic quality requirements, phase gating criteria |
| QA Test Design | `_bmad-output/test-artifacts/test-design-qa.md` | Story acceptance criteria, test scenarios |
| Risk Assessment | (embedded in both documents above) | Epic risk classification, story priority |
| Coverage Strategy | (embedded in QA document) | 41 scenarios across P0-P3 with risk linkage |

## Epic-Level Integration Guidance

### Risk References

The following P0/P1 risks should appear as epic-level quality gates:

| Risk ID | Score | Epic Impact | Quality Gate |
|---|---|---|---|
| R1 (CRITICAL) | 9 | Rendering migration (Phases 3-4) | Ground truth baselines captured before phase starts; SSIM > 0.99 after each migration PR |
| R2 | 6 | .NET AOT cross-platform (Phase 2.5) | dlopen smoke test passes on macOS + Linux before declaring phase complete |
| R3 | 6 | .NET AOT cross-platform (Phase 2.5) | char16_t marshaling round-trip passes with Korean + Latin test vectors |
| R4 | 6 | All migration phases | Catch2 tests exist for abstraction layer before corresponding migration begins |
| R5 | 6 | Rendering migration (Phases 3-4) | Ground truth capture mechanism implemented and baselines committed |

### Quality Gates

| Epic/Phase | Gate Criteria |
|---|---|
| Phase 0 (CMake scaffolding) | macOS + Linux CMake build produces binary; PlatformLibrary tests pass |
| Phase 1-2 (Windowing + Input) | SDL3 window + input integration tests pass on all platforms |
| Phase 2.5 (.NET AOT) | dlopen smoke test + char16_t round-trip + OpenMU handshake on macOS |
| Phase 3-4 (Rendering) | Ground truth SSIM > 0.99 for all captured screens; MuRenderer unit tests pass |
| Phase 6 (Audio) | MuAudio lifecycle test + WAV PCM SHA256 parity |
| MVP Gate | 60-min stable session on macOS + Linux; all P0 tests 100%; all P1 tests >= 95% |

## Story-Level Integration Guidance

### P0/P1 Test Scenarios → Story Acceptance Criteria

When decomposing migration phases into stories, embed these as acceptance criteria:

**Phase 0 stories should include:**
- "PlatformLibrary::Load returns valid handle on macOS/Linux" (P0-01, P0-02)
- "PlatformLibrary::Load returns nullptr with error log when library missing" (P0-11)
- "mu::MuTimer::GetFrameTimeMs() accurate within 1ms" (P1-10)
- "New abstraction layers (MuRenderer, MuAudio, PlatformLibrary) define abstract interfaces enabling test doubles" (Dependency Inversion)

**All phases — Boy Scout Rule:**
- When modifying existing code during migration, apply dependency inversion where practical (extract interfaces, accept abstractions via constructor/factory instead of GetInstance())

**Phase 2.5 stories should include:**
- "char16_t marshal round-trip produces identical bytes to Windows wchar_t baseline" (P0-03)
- "OpenMU handshake succeeds from macOS client" (P0-08)
- "Server connection failure shows diagnostic error message with corrective action" (P0-11)

**Phase 3-4 stories should include:**
- "MuRenderer::RenderQuad2D produces non-empty offscreen output" (P0-05)
- "All 5 HLSL shaders compile via SDL_shadercross" (P0-06)
- "Screenshot SSIM > 0.99 compared to ground truth baseline" (P1-11)

**Phase 6 stories should include:**
- "MuAudio Init/PlayBGM/PlaySFX/Shutdown lifecycle completes without error" (P1-02)
- "WAV decode PCM SHA256 matches DirectSound baseline" (P1-03)

### Data-TestId Requirements

Not applicable — MuMain is a C++ desktop game client, not a web application. Testability is achieved through Catch2 unit tests on abstraction layer APIs, not DOM element selectors.

## Risk-to-Story Mapping

| Risk ID | Category | P x I | Recommended Story/Epic | Test Level |
|---|---|---|---|---|
| R1 | TECH | 9 | Phase 3-4: Rendering Migration | Unit + Visual Regression |
| R2 | TECH | 6 | Phase 2.5: .NET AOT Cross-Platform | Unit (Catch2) |
| R3 | TECH | 6 | Phase 2.5: .NET AOT Cross-Platform | Unit (Catch2) |
| R4 | OPS | 6 | Phase 0+: Test Infrastructure | Unit (Catch2) |
| R5 | OPS | 6 | Pre-Phase 3: Ground Truth Capture | Integration |
| R6 | PERF | 4 | Phase 0: Timer Instrumentation | Unit (Catch2) |
| R7 | OPS | 4 | Post-Migration: CI Expansion | Build/CI |
| R8 | OPS | 4 | Phase 0: Crash Diagnostics | Integration |
| R9 | TECH | 4 | Phase 6: Audio Migration | Unit (Catch2) |
| R10 | TECH | 3 | Phase 2.5: OpenMU Compatibility | Integration |
| R11 | SEC | 3 | Phase 2.5: Encryption Parity | Unit (Catch2) |
| R12 | TECH | 2 | All Phases: Test Isolation | Unit (Catch2) |

## Recommended BMAD → TEA Workflow Sequence

1. **TEA Test Design** (`TD`) → produces this handoff document ← **DONE**
2. **BMAD Create Epics & Stories** → consumes this handoff, embeds quality requirements
3. **TEA ATDD** (`AT`) → generates acceptance tests per story (Catch2 test stubs)
4. **BMAD Implementation** → developers implement with test-first guidance
5. **TEA Automate** (`TA`) → generates full test suite per story
6. **TEA Trace** (`TR`) → validates coverage completeness before MVP gate

## Phase Transition Quality Gates

| From Phase | To Phase | Gate Criteria |
|---|---|---|
| Test Design | Epic/Story Creation | All P0 risks have mitigation strategy (done) |
| Epic/Story Creation | ATDD | Stories have acceptance criteria from test design |
| ATDD | Implementation | Failing Catch2 tests exist for P0/P1 scenarios |
| Implementation | Test Automation | All Catch2 acceptance tests pass |
| Test Automation | Release | Trace matrix shows >= 80% coverage of P0/P1 requirements |

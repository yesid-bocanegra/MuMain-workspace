# ATDD Implementation Checklist — Story 4.4.1: Texture System Migration

**Story**: 4.4.1 — CGlobalBitmap → SDL_gpu
**Story Type**: infrastructure
**Date**: 2026-03-10
**Flow Code**: VS1-RENDER-TEXTURE-MIGRATE
**PCC Workflow**: `_bmad/pcc/workflows/testarch-atdd`

---

## FSM Handoff Contract

| Field | Value |
|-------|-------|
| `story_key` | `4-4-1-texture-system-migration` |
| `story_type` | `infrastructure` |
| `atdd_checklist_path` | `_bmad-output/stories/4-4-1-texture-system-migration/atdd.md` |
| `test_files_created` | `MuMain/tests/render/test_texturesystemmigration.cpp` |
| `implementation_checklist_complete` | `true` (all items `[ ]`, ready for dev) |

---

## Step 0: PCC Guidelines Loaded

| Guideline | Status |
|-----------|--------|
| `project-context.md` loaded | DONE |
| `development-standards.md` referenced | DONE |
| Tech stack constraints extracted | C++20, Catch2 3.7.1, `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK` |
| Prohibited libraries confirmed | No mocking framework, no `new`/`delete`, no `NULL`, no `wprintf` |
| Required patterns confirmed | `[[nodiscard]]`, `std::vector`, `mu::` namespace, Allman braces, `#pragma once` |
| Naming conventions confirmed | `test_{name}.cpp`, `tests/render/` directory |

---

## Step 0.5: Existing Test Mapping

| AC | Description | Existing Test | Score | Action |
|---|---|---|---|---|
| AC-STD-2(a) | TextureRegistry roundtrip | `test_sdlgpubackend.cpp:540` — covers same logic (4.3.1 story context) | 0.7 | GENERATE NEW in dedicated file per AC-STD-2 mandate |
| AC-STD-2(b) | GL→SDL filter/wrap mapping | None found | 0 | GENERATE NEW |
| AC-STD-2(c) | RGB→RGBA8 pixel padding | None found | 0 | GENERATE NEW |
| AC-1 | No unguarded GL calls in GlobalBitmap.cpp | None (grep-verified at dev time) | 0 | GREP VERIFY during dev |
| AC-2 | BITMAP_t struct SDL_GPUTexture* member | None (compile-time check) | 0 | COMPILE VERIFY during dev |
| AC-3 | UnloadImage calls UnregisterTexture | None | 0 | CODE REVIEW during dev |
| AC-4 | RegisterTexture called after SDL_CreateGPUTexture | None | 0 | CODE REVIEW during dev |
| AC-5 | Format/filter/wrap mapping correctness | Covered by AC-STD-2(b) | — | AC-STD-2(b) test covers this |
| AC-6 | SSIM baseline | Pre-approved deferred | — | DEFERRED per story |

**ACs needing tests**: AC-STD-2(a), AC-STD-2(b), AC-STD-2(c) → all in `test_texturesystemmigration.cpp`

---

## Step 1: Story Context

- **Story file**: `_bmad-output/stories/4-4-1-texture-system-migration/story.md`
- **Story type**: `infrastructure`
- **Affected components**:
  - `mumain` (backend, render) — `GlobalBitmap.h/.cpp`, `MuRenderer.h`, `MuRendererSDLGpu.cpp`
  - `project-docs` (documentation) — story artifacts
- **Backend root**: `./MuMain` (mumain component)
- **No frontend component**: infrastructure story, no UI
- **Prohibited libraries check**: No violations found — no mocking framework, no `NULL`, no exceptions
- **Existing fixtures**: `mu::RegisterTexture`/`LookupTexture`/`UnregisterTexture`/`ClearTextureRegistry` already implemented in `MuRendererSDLGpu.cpp` (story 4.3.1)

---

## Step 2: Test Levels Selected

| Test Level | Selected | Rationale |
|------------|----------|-----------|
| Unit | YES | Catch2 tests for registry roundtrip, format mapping, pixel padding |
| Integration | NO (deferred) | GPU device required — pre-approved deferral per AC-6 and AC-VAL-3/4 |
| E2E | NO | Infrastructure story — no UI/frontend |
| API Collection (Bruno) | NO | No HTTP endpoints |

---

## Step 3: Failing Tests Generated (RED Phase)

### Test File: `MuMain/tests/render/test_texturesystemmigration.cpp`

| TEST_CASE | AC Covered | Phase | Rationale |
|-----------|------------|-------|-----------|
| `"AC-STD-2(a): TextureRegistry -- RegisterTexture/LookupTexture/UnregisterTexture roundtrip"` | AC-STD-2(a), AC-VAL-1 | GREEN immediately (4.3.1 impl) | Registry functions already implemented in `MuRendererSDLGpu.cpp` |
| `"AC-STD-2(b): UploadTexture -- GL/SDL format mapping"` | AC-STD-2(b), AC-5 | RED until Task 2.1 | `MapGLFilterToSDL`/`MapGLWrapToSDL` not yet implemented |
| `"AC-STD-2(c): UploadTexture -- RGB pixel padding to RGBA8"` | AC-STD-2(c) | RED until Task 2.1 | `PadRGBToRGBA` not yet implemented |

### AC-to-Test Mapping

| AC | Test Method(s) |
|----|----------------|
| AC-1 | grep verification: `grep -rn "glGenTextures\|glBindTexture\|glTexImage2D\|glDeleteTextures" GlobalBitmap.cpp` |
| AC-2 | Compile-time: `BITMAP_t.sdlTexture` member exists under `#ifdef MU_ENABLE_SDL3` |
| AC-3 | Code review: `UnloadImage` calls `mu::UnregisterTexture` + `SDL_ReleaseGPUTexture` |
| AC-4 | Code review: `RegisterTexture` called in `OpenJpegTurbo`/`OpenTga` after `UploadTextureSDLGpu` |
| AC-5 | `TEST_CASE("AC-STD-2(b): UploadTexture -- GL/SDL format mapping")` — all SECTION blocks |
| AC-6 | DEFERRED (pre-approved) — Windows D3D12/macOS Metal visual validation |
| AC-STD-2(a) | `TEST_CASE("AC-STD-2(a): TextureRegistry -- RegisterTexture/LookupTexture/UnregisterTexture roundtrip")` — 5 SECTIONs |
| AC-STD-2(b) | `TEST_CASE("AC-STD-2(b): UploadTexture -- GL/SDL format mapping")` — 6 SECTIONs |
| AC-STD-2(c) | `TEST_CASE("AC-STD-2(c): UploadTexture -- RGB pixel padding to RGBA8")` — 6 SECTIONs |

---

## Step 4: Data Infrastructure

- **Fixtures location**: `MuMain/tests/` (no shared fixtures required — tests use inline synthetic data)
- **Existing registry infrastructure**: `mu::ClearTextureRegistry()` called at start/end of registry tests
- **Pixel test data**: 2×2 synthetic RGB buffer defined inline (no external fixture files needed)
- **No seed data**: pure unit tests, no database or file system dependencies
- **Test environments**: macOS/Linux CI compatible — no GPU device, no Win32, no OpenGL headers

---

## Implementation Checklist

All items start as `[ ]` (pending). Items become `[x]` when verified by the dev agent.

### Task 1: Update `BITMAP_t` struct and `GlobalBitmap.h`

- [ ] Subtask 1.1 — Add `SDL_GPUTexture* sdlTexture = nullptr;` and `SDL_GPUSampler* sdlSampler = nullptr;` to `BITMAP_t` under `#ifdef MU_ENABLE_SDL3` guard
- [ ] Subtask 1.2 — Add forward declarations `struct SDL_GPUTexture;` and `struct SDL_GPUSampler;` in `GlobalBitmap.h` inside `#ifdef MU_ENABLE_SDL3` (no full SDL3 header in `.h`)

### Task 2: Implement SDL_gpu upload helpers in `GlobalBitmap.cpp`

- [ ] Subtask 2.1 — Implement `MapGLFilterToSDL(GLuint)` in anonymous namespace: GL_NEAREST→NEAREST, GL_LINEAR→LINEAR, default NEAREST. Add `[[nodiscard]]`.
- [ ] Subtask 2.1 — Implement `MapGLWrapToSDL(GLuint)` in anonymous namespace: GL_CLAMP_TO_EDGE→CLAMP_TO_EDGE, GL_REPEAT→REPEAT, default CLAMP_TO_EDGE. Add `[[nodiscard]]`.
- [ ] Subtask 2.1 — Implement `PadRGBToRGBA(const uint8_t*, int, int)` in anonymous namespace: allocate `width*height*4` vector, copy R/G/B, set A=255 per pixel. Add `[[nodiscard]]`.
- [ ] Subtask 2.2 — Implement `UploadTextureSDLGpu(BITMAP_t*, const uint8_t*, int, int, SDL_GPUTextureFormat, SDL_GPUFilter, SDL_GPUSamplerAddressMode)` with full copy command buffer pattern. Add `[[nodiscard]]` and `static`.
- [ ] Subtask 2.2 — Log `g_ErrorReport.Write(L"ASSET: texture upload -- SDL_CreateGPUTexture failed for %ls: %hs", ...)` on null texture
- [ ] Subtask 2.2 — Log `g_ErrorReport.Write(L"ASSET: texture upload -- SDL_CreateGPUTransferBuffer failed for %ls: %hs", ...)` on null transfer buffer
- [ ] Subtask 2.2 — Log `g_ErrorReport.Write(L"ASSET: texture upload -- SDL_CreateGPUSampler failed for %ls: %hs", ...)` on null sampler

### Task 3: Migrate `CGlobalBitmap::OpenJpegTurbo`

- [ ] Subtask 3.1 — Guard existing `glGenTextures`/`glBindTexture`/`glTexImage2D`/`glTexParameteri` block with `#ifndef MU_ENABLE_SDL3`
- [ ] Subtask 3.2 — Add `#ifdef MU_ENABLE_SDL3` block: call `PadRGBToRGBA` → `UploadTextureSDLGpu` → capture `rawTex = pNewBitmap->sdlTexture` before move → `mu::RegisterTexture(uiBitmapIndex, rawTex)` after insert
- [ ] Subtask 3.3 — Return `true` from `OpenJpegTurbo` on both paths (existing structure preserved)

### Task 4: Migrate `CGlobalBitmap::OpenTga`

- [ ] Subtask 4.1 — Guard existing `glGenTextures`/`glBindTexture`/`glTexImage2D`/`glTexEnvf`/`glTexParameteri` block with `#ifndef MU_ENABLE_SDL3`
- [ ] Subtask 4.2 — Add `#ifdef MU_ENABLE_SDL3` block: RGBA data already in `pNewBitmap->Buffer` → `UploadTextureSDLGpu` → capture `rawTex` → `mu::RegisterTexture(uiBitmapIndex, rawTex)` after insert

### Task 5: Migrate `CGlobalBitmap::UnloadImage`

- [ ] Subtask 5.1 — Call `mu::UnregisterTexture(uiBitmapIndex)` before `m_mapBitmap.erase`
- [ ] Subtask 5.2 — Guard existing `glDeleteTextures(1, &(pBitmap->TextureNumber))` with `#ifndef MU_ENABLE_SDL3`
- [ ] Subtask 5.3 — Add `#ifdef MU_ENABLE_SDL3` block: release `pBitmap->sdlSampler` via `SDL_ReleaseGPUSampler` if non-null; release `pBitmap->sdlTexture` via `SDL_ReleaseGPUTexture` if non-null

### Task 6: Expose SDL_gpu device accessor (`IMuRenderer::GetDevice()`)

- [ ] Subtask 6.1 — Add `virtual SDL_GPUDevice* GetDevice() { return nullptr; }` to `IMuRenderer` in `MuRenderer.h`; forward-declare `struct SDL_GPUDevice;` under `#ifdef MU_ENABLE_SDL3`; add `[[nodiscard]]`
- [ ] Subtask 6.2 — Override `GetDevice()` in `MuRendererSDLGpu` returning `s_device`
- [ ] Subtask 6.3 — Add `g_ErrorReport.Write` warning in `GetDevice()` override if `s_device == nullptr`; include `MuRenderer.h` in `GlobalBitmap.cpp` (already includes `stdafx.h`)
- [ ] Add `RegisterSampler`/`LookupSampler`/`UnregisterSampler` free functions in `mu::` namespace in `MuRendererSDLGpu.cpp`
- [ ] Update sampler binding in `RenderQuad2D`/`RenderTriangles`/`RenderQuadStrip`: replace hardcoded `s_defaultSampler` with `static_cast<SDL_GPUSampler*>(mu::LookupSampler(textureId))`

### Task 7: Add Catch2 tests

- [x] Subtask 7.1 — `MuMain/tests/render/test_texturesystemmigration.cpp` created (this ATDD step)
- [x] Subtask 7.2 — Add `target_sources(MuTests PRIVATE render/test_texturesystemmigration.cpp)` to `MuMain/tests/CMakeLists.txt` with `# Story 4.4.1 — Texture system migration` comment
- [x] Subtask 7.3 — `TEST_CASE("AC-STD-2(a): TextureRegistry -- RegisterTexture/LookupTexture/UnregisterTexture roundtrip")` with 5 SECTIONs — GREEN immediately (4.3.1 impl)
- [x] Subtask 7.4 — `TEST_CASE("AC-STD-2(b): UploadTexture -- GL/SDL format mapping")` with 6 SECTIONs — RED until Task 2.1
- [x] Subtask 7.5 — `TEST_CASE("AC-STD-2(c): UploadTexture -- RGB pixel padding to RGBA8")` with 6 SECTIONs — RED until Task 2.1

### Task 8: Quality gate verification

- [ ] Subtask 8.1 — `./ctl check` passes: 0 errors, **708 C++ files** (707 baseline + 1 new test file)
- [ ] Subtask 8.2 — grep confirms no unguarded GL texture calls in `GlobalBitmap.cpp`: `grep -rn "glGenTextures\|glBindTexture\|glTexImage2D\|glDeleteTextures\|glTexParameteri\|glTexEnvf" MuMain/src/source/Data/GlobalBitmap.cpp` — all matches inside `#ifndef MU_ENABLE_SDL3`
- [ ] Subtask 8.3 — Conventional commit: `refactor(render): migrate texture system to SDL_gpu`

### Standard AC Verification

- [ ] AC-STD-1 — Code Standards: `#ifdef MU_ENABLE_SDL3` guards all SDL_gpu code; no raw `new`/`delete`; `nullptr` not `NULL`; no `wprintf`; no `#ifdef _WIN32` in game logic; `[[nodiscard]]` on new fallible helpers; `#pragma once` in any new headers
- [ ] AC-STD-2 — Catch2 tests: all 3 TEST_CASEs in `test_texturesystemmigration.cpp` compile and tests that are GREEN pass
- [ ] AC-STD-4 — CI quality gate passes (`./ctl check` — 0 errors, 708 files)
- [ ] AC-STD-5 — Error logging: all 3 `g_ErrorReport.Write` patterns for SDL_CreateGPUTexture/TransferBuffer/Sampler failures implemented
- [ ] AC-STD-6 — Conventional commit: `refactor(render): migrate texture system to SDL_gpu`
- [ ] AC-STD-12 — SLI/SLO: N/A (no HTTP endpoints). Texture upload must complete <1ms per texture (SDL_gpu async copy is non-blocking on game thread)
- [ ] AC-STD-13 — Quality gate: `./ctl check` passes, **708 C++ files** confirmed
- [ ] AC-STD-14 — Observability: `g_ErrorReport.Write()` on all SDL_gpu failure paths per AC-STD-5
- [ ] AC-STD-15 — Git safety: no incomplete rebase, no force push
- [ ] AC-STD-16 — Correct test infrastructure: Catch2 3.7.1, `MuTests` target, `tests/render/` directory, `target_sources` in `tests/CMakeLists.txt`

### Validation Artifact Verification

- [ ] AC-VAL-1 — Catch2 tests pass: TextureRegistry roundtrip (GREEN), GL→SDL filter/wrap mapping (GREEN after Task 2.1), RGB→RGBA8 padding (GREEN after Task 2.1) — VERIFY: 3 GREEN TEST_CASE blocks
- [ ] AC-VAL-2 — `./ctl check` passes with 0 errors after all changes — VERIFY: 708 files, 0 errors
- [~] AC-VAL-3 — (Deferred — pre-approved) Windows D3D12 SSIM validation against story 4.1.1 baseline — requires Windows build environment with GPU
- [~] AC-VAL-4 — (Deferred — pre-approved) macOS Metal GPU device validation — no GPU device available in CI
- [ ] AC-VAL-5 — No GL texture calls remain in `GlobalBitmap.cpp` outside `#ifndef MU_ENABLE_SDL3` guards — VERIFY: grep confirms no unguarded GL texture calls

### PCC Compliance

- [ ] PCC: No prohibited libraries from project-context.md (no mocking framework, no `NULL`, no exceptions in game loop)
- [ ] PCC: Required testing patterns used (Catch2 `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK`)
- [ ] PCC: No `#ifdef _WIN32` in `GlobalBitmap.cpp` or new game logic files — `MU_ENABLE_SDL3` guards only
- [ ] PCC: `[[nodiscard]]` on `UploadTextureSDLGpu`, `MapGLFilterToSDL`, `MapGLWrapToSDL`, `PadRGBToRGBA`, `GetDevice()`
- [ ] PCC: `std::vector<std::uint8_t>` for pixel buffers (no raw `new uint8_t[]`)
- [ ] PCC: `mu::` namespace for new public symbols (registry functions, device accessor, sampler registry)
- [ ] PCC: Allman brace style, 4-space indent, 120-column limit enforced (./ctl check)
- [ ] PCC: `#pragma once` in any new `.h` files
- [ ] PCC: Include order preserved (SortIncludes: Never)
- [ ] PCC: `g_ErrorReport.Write(L"ASSET: texture upload -- ...")` for all SDL_gpu failure paths (no `wprintf`)
- [ ] PCC: No `SAFE_DELETE`/`SAFE_DELETE_ARRAY` — `std::unique_ptr` already used in `CGlobalBitmap`

---

## Output Summary

| Field | Value |
|-------|-------|
| Story ID | 4.4.1 |
| Primary test level | Unit (Catch2) |
| Test file created | `MuMain/tests/render/test_texturesystemmigration.cpp` |
| Failing tests (RED) | 2 TEST_CASEs (AC-STD-2b, AC-STD-2c) — total 12 SECTIONs |
| Green immediately | 1 TEST_CASE (AC-STD-2a) — 5 SECTIONs (registry impl from 4.3.1) |
| Bruno API tests | N/A (infrastructure story, no HTTP endpoints) |
| E2E tests | N/A (no frontend) |
| PCC compliance | All rules verified — no prohibited libraries, correct patterns |
| Expected file count post-story | **708 C++ files** (707 baseline + 1 new test file) |

---

## Final Validation

- [x] PCC guidelines loaded (project-context.md + development-standards.md)
- [x] Existing tests mapped (Step 0.5) — `test_sdlgpubackend.cpp:540` covers registry roundtrip for 4.3.1; new dedicated file required per AC-STD-2
- [x] AC-N: prefixes added to TEST_CASE names in `test_texturesystemmigration.cpp`
- [x] All tests use PCC-approved patterns (Catch2, REQUIRE/CHECK, no mocking)
- [x] No prohibited libraries (no mocking framework, `std::vector` for pixel buffers, no raw `new`)
- [x] Implementation checklist includes PCC compliance items
- [x] ATDD checklist has AC-to-test mapping table (Step 3)
- [x] Test file physically exists: `MuMain/tests/render/test_texturesystemmigration.cpp`

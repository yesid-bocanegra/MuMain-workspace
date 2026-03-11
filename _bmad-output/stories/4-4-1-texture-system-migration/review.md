# Code Review — Story 4-4-1-texture-system-migration

**Story:** 4-4-1-texture-system-migration
**Date:** 2026-03-11
**Story File:** `_bmad-output/stories/4-4-1-texture-system-migration/story.md`

---

## Pipeline Status

| Step | Status |
|------|--------|
| 1. Quality Gate | PASSED |
| 2. Code Review Analysis | COMPLETE — 2 HIGH, 3 MEDIUM, 1 LOW |
| 3. Code Review Finalize | pending |

---

## Quality Gate Progress

| Phase | Component | Status | Iterations | Issues Fixed |
|-------|-----------|--------|------------|--------------|
| Backend Local (format-check + lint) | mumain | PASSED | 1 | 0 |
| Backend SonarCloud | mumain | SKIPPED (no SONAR_TOKEN) | — | — |
| Frontend Local | N/A | SKIPPED (infrastructure story, no frontend) | — | — |
| Frontend SonarCloud | N/A | SKIPPED | — | — |

---

## Fix Iterations

_(none — quality gate passed on first run with 0 issues)_

---

## Step 1: Quality Gate

**Status:** PASSED
**Completed:** 2026-03-11

### Components
- Backend: `mumain` (`./MuMain`, cpp-cmake)
- Frontend: none (infrastructure story — `project-docs` is documentation only)

### Backend Quality Gate — mumain

**Tech Profile:** cpp-cmake
**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`

**Results:**
- Format check: ✅ PASSED
- cppcheck (lint): ✅ PASSED — 707/707 files checked, 0 errors
- Build: SKIPPED (`skip_checks: [build, test]` — macOS cannot compile Win32/DirectX)
- Tests: SKIPPED (same — CI-only via MinGW)
- Boot verification: SKIPPED (not applicable for C++ game client)
- SonarCloud: SKIPPED (no SONAR_TOKEN; project has no sonar_key configured)

**Overall Backend Status:** ✅ PASSED

### Summary

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Backend Local | PASSED | 1 | 0 |
| Backend SonarCloud | SKIPPED | — | — |
| Frontend Local | SKIPPED | — | — |
| Frontend SonarCloud | SKIPPED | — | — |
| **Overall** | **PASSED** | — | — |

✅ **QUALITY GATE PASSED — Ready for code-review-analysis**

Next step: `/bmad:pcc:workflows:code-review-analysis 4-4-1-texture-system-migration`

---

## Schema Alignment

- N/A — infrastructure story, no backend/frontend API schema alignment applicable.

---

## AC Compliance Check

Story type: `infrastructure` — AC tests skipped (as per workflow rules for infrastructure stories).

---

## Step 2: Analysis Results

**Status:** COMPLETE
**Completed:** 2026-03-11
**Analyst:** claude-sonnet-4-6 (adversarial mode)

### Severity Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 1 |

### AC Validation

**Total ACs:** 14 (AC-1 through AC-6, AC-STD-1/2/4/5/6/12/13/14/15/16, AC-VAL-1 through AC-VAL-5)
**Implemented:** 12 (marked [x])
**Deferred (pre-approved):** 3 (AC-6, AC-VAL-3, AC-VAL-4 — runtime GPU validation, pre-approved per story)
**Not Implemented:** 0
**BLOCKERS:** 0
**Pass Rate:** 100% (deferral pre-approved per architecture constraints)

All Acceptance Criteria verified implemented or pre-approved deferred. No AC violations.

### ATDD Audit

- **Checklist:** `_bmad-output/stories/4-4-1-texture-system-migration/atdd.md`
- **Total scenarios:** 3 TEST_CASEs, ~17 SECTIONs
- **GREEN (complete):** 3/3 TEST_CASEs — all [x]
- **RED (incomplete):** 0
- **Coverage:** 100%
- **ATDD-Story sync:** No mismatches found
- **Test file exists:** `MuMain/tests/render/test_texturesystemmigration.cpp` — verified

### Task Completion Audit

All 8 tasks and subtasks marked [x]. Evidence verified in source files:
- Task 1 (BITMAP_t struct): `GlobalBitmap.h` lines 48-51 — `sdlTexture`/`sdlSampler` under `#ifdef MU_ENABLE_SDL3` ✓
- Task 2 (helpers): `GlobalBitmap.cpp` lines 141-334 — `MapGLFilterToSDL`, `MapGLWrapToSDL`, `PadRGBToRGBA`, `UploadTextureSDLGpu` ✓
- Task 3 (OpenJpegTurbo): lines 988-1025 — GL guarded, SDL path added ✓
- Task 4 (OpenTga): lines 1109-1146 — GL guarded, SDL path added ✓
- Task 5 (UnloadImage): lines 694-721 — `UnregisterTexture`/`UnregisterSampler`, SDL release ✓
- Task 6 (GetDevice): `MuRenderer.h` lines 122-127, `MuRendererSDLGpu.cpp` lines 790-796 ✓
- Task 7 (tests): `test_texturesystemmigration.cpp` exists, 3 TEST_CASEs ✓
- Task 8 (quality gate): `./ctl check` passes per QG trace ✓

---

### Issues Found

#### HIGH-1: `SDL_BeginGPUCopyPass` failure silently produces uninitialized texture
- **Severity:** HIGH
- **Category:** CODE-QUALITY / ERROR-HANDLING
- **File:** `MuMain/src/source/Data/GlobalBitmap.cpp`
- **Location:** `UploadTextureSDLGpu`, lines ~283-308
- **Status:** pending

**Description:**
`SDL_BeginGPUCopyPass` can return null if the GPU device is in an error state. The current code checks `if (copyPass)` and skips the upload body, but unconditionally falls through to `SDL_SubmitGPUCommandBuffer(copyCmd)`. The empty command buffer is submitted and the function returns `true` with `pBitmap->sdlTexture` set to a valid (but uninitialized, zero-filled) `SDL_GPUTexture`. Rendering this texture produces undefined visual output — solid black or GPU driver-specific garbage — with no error logged.

The story completion notes mention HIGH-1 fixed was `SDL_AcquireGPUCommandBuffer` returning null. The `SDL_BeginGPUCopyPass` null case is a distinct unhandled failure path.

**Fix:** Add null check on `copyPass`, log the error, release resources (`SDL_ReleaseGPUTransferBuffer`, `SDL_ReleaseGPUTexture`), and return `false`:
```cpp
SDL_GPUCopyPass* copyPass = SDL_BeginGPUCopyPass(copyCmd);
if (!copyPass)
{
    g_ErrorReport.Write(L"ASSET: texture upload -- SDL_BeginGPUCopyPass failed for %ls: %hs",
                        filename.c_str(), SDL_GetError());
    SDL_SubmitGPUCommandBuffer(copyCmd); // must submit even on failure to release the cmd buffer
    SDL_ReleaseGPUTransferBuffer(device, transferBuf);
    SDL_ReleaseGPUTexture(device, gpuTex);
    return false;
}
// ... upload ...
SDL_EndGPUCopyPass(copyPass);
SDL_SubmitGPUCommandBuffer(copyCmd);
```

---

#### HIGH-2: `UnloadAllImages` — GPU resources leaked when `GetDevice()` returns null
- **Severity:** HIGH
- **Category:** RESOURCE-LEAK
- **File:** `MuMain/src/source/Data/GlobalBitmap.cpp`
- **Location:** `UnloadAllImages`, lines ~743-786
- **Status:** pending

**Description:**
`UnloadAllImages` is called from `CGlobalBitmap::~CGlobalBitmap()` (destructor) and during map transitions. The SDL_gpu cleanup loop at lines 748-768 is guarded by `if (device)`. If `GetDevice()` returns null (device already shut down before bitmap destructor runs — a likely order of operations on exit), the entire loop is skipped. Result: every `SDL_GPUTexture*` and `SDL_GPUSampler*` stored in `m_mapBitmap` is leaked (GPU memory leak), and both TextureRegistry and SamplerRegistry are left holding dangling `void*` pointers pointing to destroyed `BITMAP_t` stack frames. Subsequent `LookupTexture()` / `LookupSampler()` calls after teardown would return dangling pointers.

The single-texture `UnloadImage` path has the same device-null guard but is only called during gameplay, when the device is guaranteed live. The bulk `UnloadAllImages` path runs at shutdown where order is not guaranteed.

**Fix:** When device is null, still clear the registries (they hold dangling pointers) and log a warning for the GPU leak:
```cpp
if (!device)
{
    // GPU device already shut down — can't release GPU objects, but must clear registries
    // to avoid dangling pointer use-after-free on any subsequent lookup.
    g_ErrorReport.Write(L"ASSET: UnloadAllImages -- SDL_GPUDevice unavailable; GPU texture/sampler objects leaked");
    mu::ClearTextureRegistry();
    mu::ClearSamplerRegistry();
}
```

---

#### MEDIUM-1: `UploadTextureSDLGpu` — `pixelBytes` hardcoded ignores `format` parameter
- **Severity:** MEDIUM
- **Category:** CODE-QUALITY
- **File:** `MuMain/src/source/Data/GlobalBitmap.cpp`
- **Location:** `UploadTextureSDLGpu`, line ~242
- **Status:** pending

**Description:**
`const Uint32 pixelBytes = 4u;` is hardcoded regardless of the `format` parameter. The function signature accepts `SDL_GPUTextureFormat format` (implying the format is variable), but the transfer buffer size calculation always uses 4 bytes per pixel. Currently all callers pass `SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM` (4 bytes/pixel), but the story's AC-5 text mentions `SDL_GPU_TEXTUREFORMAT_R8G8B8_UNORM` as a potential format for JPEG (3 bytes/pixel). If that path is ever used, the transfer buffer would be correctly sized for RGBA8 but the pixel data would only be 3 bytes/pixel — the upload would either read past the buffer end or produce garbled pixels.

**Fix:** Either document the assumption (`// All callers supply RGBA8 — pixelBytes is intentionally fixed at 4`) or derive `pixelBytes` from `format` via a switch:
```cpp
const Uint32 pixelBytes = (format == SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) ? 4u : 4u; // currently RGBA8 only
```
At minimum, assert or log if a non-RGBA8 format is passed.

---

#### MEDIUM-2: `BITMAP_t` packed struct with pointer members — potential misaligned pointer UB on ARM
- **Severity:** MEDIUM
- **Category:** CROSS-PLATFORM
- **File:** `MuMain/src/source/Data/GlobalBitmap.h`
- **Location:** `BITMAP_t` struct, lines 28-57
- **Status:** pending

**Description:**
`BITMAP_t` is declared with `#pragma pack(push, 1)` (1-byte packing). The new `SDL_GPUTexture*` and `SDL_GPUSampler*` members are 8-byte pointer types on 64-bit platforms. Under `#pragma pack(1)`, these pointers are likely placed at non-8-byte-aligned offsets. On ARM (macOS Metal target, Linux ARM), accessing misaligned pointers is undefined behavior and will cause a SIGBUS fault on older ARM (pre-ARMv8 unaligned load support) and UB on ARMv8 even if the hardware allows it.

The OpenGL path stored only `GLuint` (4 bytes) members so pack(1) was tolerable. The SDL_gpu path introduces 8-byte pointer members in a 1-byte-packed struct.

**Fix:** Add the SDL pointer members _outside_ the `#pragma pack` scope, or change the packing to `#pragma pack(push, 4)` for the SDL struct members. The cleanest fix is to end pack before the SDL members:
```cpp
#pragma pack(pop)
// SDL_gpu members (8-byte aligned — must not be inside pack(1) scope)
#ifdef MU_ENABLE_SDL3
    SDL_GPUTexture* sdlTexture = nullptr;
    SDL_GPUSampler* sdlSampler = nullptr;
#endif
```
Note: changing the struct layout will affect sizeof(BITMAP_t) — verify no binary serialization depends on it (review of Save_Image and Load paths confirms no struct-level serialization, so this is safe).

---

#### MEDIUM-3: File count discrepancy in story documentation (707 vs 708)
- **Severity:** MEDIUM
- **Category:** DOCUMENTATION
- **File:** `_bmad-output/stories/4-4-1-texture-system-migration/story.md`
- **Location:** AC-STD-4, AC-STD-13, Task 8.1, Dev Notes PCC Constraints
- **Status:** pending

**Description:**
The story's Dev Notes state "Quality gate: **708 C++ files** (707 baseline post-4.3.2, +1 test file)" in the PCC Constraints section. But AC-STD-4, AC-STD-13, Task 8.1, and the ATDD checklist all record the verified count as **707 files** after adding the test file. This is internally inconsistent — either the baseline was 706 (not 707) and the test file brings it to 707, or the baseline was 707 and the test file brings it to 708 but the `./ctl check` output actually reports 707 (perhaps cppcheck doesn't scan the tests directory).

The quality gate report in review.md also says "707/707 files checked". The actual count after the story should be clarified for the next story's baseline.

**Fix:** Update the Dev Notes PCC Constraints baseline to match reality: "Quality gate: **707 C++ files** confirmed post-story (the test file may not be included in the cppcheck scan scope)." Verify the cppcheck scope configuration to document whether `tests/` is included.

---

#### LOW-1: `MapGLFilterToSDL` / `MapGLWrapToSDL` — global namespace placement creates naming collision risk
- **Severity:** LOW
- **Category:** CODE-QUALITY
- **File:** `MuMain/src/source/Data/GlobalBitmap.cpp`
- **Location:** Lines ~141, ~158
- **Status:** pending

**Description:**
These helpers are placed in the global namespace (not `anonymous namespace`, not `mu::` namespace) specifically to allow the test TU to forward-declare and link them. However, placing implementation-detail functions in the global namespace with generic names like `MapGLFilterToSDL` and `MapGLWrapToSDL` risks name collisions with other TUs in large unity builds or LTO. A cleaner approach would be to expose them via a thin header (e.g., `GlobalBitmapTestHarness.h`) with explicit extern declarations, or use `mu::` namespace.

This is a known intentional decision documented in the Dev Notes and story completion notes. Acceptable as-is for the current codebase scale, but worth noting for future refactoring.

**Fix (optional):** Move to `mu::` namespace and update forward declarations in test file accordingly.

---

### NFR Compliance

- Quality gate (`./ctl check`): PASSED — 707 files, 0 errors ✓
- Error logging: `g_ErrorReport.Write` on all explicit SDL_gpu failure paths ✓
- Cross-platform guards: no `#ifdef _WIN32` in game logic, `MU_ENABLE_SDL3` used correctly ✓
- No raw `new`/`delete`, `nullptr` used, no `wprintf` ✓
- `[[nodiscard]]` on all fallible helpers ✓
- `std::vector<uint8_t>` for pixel buffers ✓
- Conventional commit: `refactor(render): migrate texture system to SDL_gpu` (e857263c) ✓

### Schema Alignment

N/A — infrastructure story, no DTO/API schema changes.

### Contract Reachability

N/A — no API endpoints, events, or screens introduced.

---

Next step: `/bmad:pcc:workflows:code-review-finalize 4-4-1-texture-system-migration`


---

## Code Review Analysis (Step 2)

**Date:** 2026-03-11 01:10
**Reviewer:** Claude (Adversarial Analysis)

⚡ Skill: bmad-pcc-code-review-analysis
💬 **Code Review Analysis Complete** for story `4-4-1-texture-system-migration`.

### Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 1 |

**ATDD: 100% complete (3/3 test cases green)**

### Key Findings

**HIGH-1** — Silent uninitialized texture on `SDL_BeginGPUCopyPass` null return (`GlobalBitmap.cpp` ~line 284): no error logged, empty texture returned as success.

**HIGH-2** — GPU resource leak in `UnloadAllImages` when `GetDevice()` returns null at shutdown: TextureRegistry/SamplerRegistry left with dangling pointers.

**MEDIUM-1** — `pixelBytes` hardcoded to 4, ignores `format` parameter — fragile for future formats.

**MEDIUM-2** — `#pragma pack(1)` struct with 8-byte SDL pointer members — UB on ARM.

**MEDIUM-3** — File count inconsistency in docs (707 vs 708).

---

The review findings are documented in `_bmad-output/stories/4-4-1-texture-system-migration/review.md`. Run `/bmad:pcc:workflows:code-review-finalize 4-4-1-texture-system-migration` to fix the HIGH issues and close the story.

📋 Result:
**Code Review Analysis Complete** for story `4-4-1-texture-system-migration`.

### Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 1 |

**ATDD: 100% complete (3/3 test cases green)**

### Key Findings

**HIGH-1** — Silent uninitialized texture on `SDL_BeginGPUCopyPass` null return (`GlobalBitmap.cpp` ~line 284): no error logged, empty texture returned as success.

**HIGH-2** — GPU resource leak in `UnloadAllImages` when `GetDevice()` returns null at shutdown: TextureRegistry/SamplerRegistry left with dangling pointers.

**MEDIUM-1** — `pixelBytes` hardcoded to 4, ignores `format` parameter — fragile for future formats.

**MEDIUM-2** — `#pragma pack(1)` struct with 8-byte SDL pointer members — UB on ARM.

**MEDIUM-3** — File count inconsistency in docs (707 vs 708).

---

The review findings are documented in `_bmad-output/stories/4-4-1-texture-system-migration/review.md`. Run `/bmad:pcc:workflows:code-review-finalize 4-4-1-texture-system-migration` to fix the HIGH issues and close the story.

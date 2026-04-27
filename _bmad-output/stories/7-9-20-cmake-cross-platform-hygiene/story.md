# Story 7-9-20: CMake Cross-Platform Hygiene — Graceful CURL + Preset Toolchain Cleanup

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-20 |
| **Title** | CMake Cross-Platform Hygiene — Graceful CURL Fallback + Preset Toolchain Cleanup |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-0 (Platform / Enabler) |
| **Flow Type** | Refactor |
| **Flow Code** | VS0-PLAT-CMAKE-HYGIENE |
| **Story Points** | 3 |
| **Dependencies** | None |
| **Status** | ready-for-dev |

---

## User Story

**As a** new contributor or local developer cloning the repo on Windows in CLion or Visual Studio,
**I want** the project to configure cleanly without requiring a specific package manager (vcpkg) or a specific generator (Ninja Multi-Config),
**So that** I can build immediately after `git clone` instead of debugging CMake-preset interactions or installing curl globally.

---

## Background

[Mosch's review of PR #329](../../../MuMain/docs/pr-329-review-followups.md)
flagged two CMake patterns that work in CI but trip non-CI configurations.
Both were *sidestepped* by `2aefc9ef` (which added vcpkg + chained
`VCPKG_CHAINLOAD_TOOLCHAIN_FILE`), not fixed in the form Mosch preferred.
This story closes the loop with the preferred fixes.

### Issue 1 — `find_package(CURL REQUIRED)` blocks configure (PR-329 #8)

`src/CMakeLists.txt` has `find_package(CURL REQUIRED)` near the top of the
build graph. On any system without curl installed *or* without a vcpkg
manifest mode active, configure fails before producing a build tree. Other
optional dependencies in the codebase already follow a graceful-degradation
pattern — the existing OpenSSL handling at `src/CMakeLists.txt:298` falls
back to identity-`mu_encrypt_blob` if OpenSSL is absent.

Mosch's preferred fix mirrors that pattern: drop `REQUIRED`, define a stub
`CURL::libcurl` interface library on `find_package` failure, and have
`ShopListManager` log "downloads disabled" at runtime. Lets contributors
without vcpkg/system curl `clone-and-configure` immediately.

### Issue 2 — Preset's `toolchainFile` overrides downstream vcpkg (PR-329 #9)

The Windows base preset sets `toolchainFile` directly (pointing at
`toolchain-x64.cmake`). When a leaf preset wants to add vcpkg's
`vcpkg.cmake` toolchain, the inheritance ordering means the leaf can't
override — `toolchainFile` is set in the parent.

The CI workaround (`2aefc9ef`) is to use `VCPKG_CHAINLOAD_TOOLCHAIN_FILE` on
the CMake CLI, chain-loading `toolchain-x64.cmake` through `vcpkg.cmake`.
Mosch classified that as *"option 3 — ugly but non-breaking"*. He prefers:

- **Option 1**: move `toolchainFile` to a leaf preset
  (`windows-x64-default-toolchain`) so other leaves
  (`windows-x64-vcpkg`, `windows-x64-mingw`) can override freely.
- **Option 2**: delete the toolchain files entirely; they only set
  `CMAKE_GENERATOR_PLATFORM`, which Ninja Multi-Config ignores.

Either option unblocks local CLion / Visual Studio users on Windows. CI
isn't affected; CI uses Ninja Multi-Config which ignored the toolchain
files all along.

---

## Functional Acceptance Criteria

- [ ] **AC-1: Graceful CURL fallback.** `src/CMakeLists.txt` calls `find_package(CURL)` (no `REQUIRED`). On success, the existing CURL link path is unchanged. On failure, a stub `INTERFACE` library named `CURL::libcurl` is defined that satisfies the `target_link_libraries` line, and a `MU_CURL_DISABLED` (or similarly named) compile definition is emitted to `MUCommon`.
- [ ] **AC-2: Runtime no-op when CURL absent.** `Network/ShopListManager` (or whichever consumer of CURL exists) checks `MU_CURL_DISABLED` and logs `"network: ShopListManager downloads disabled (CURL not found at configure time)"` once at startup, then short-circuits any download attempt. No crash, no nullptr deref.
- [ ] **AC-3: Preset toolchain cleanup.** `CMakePresets.json` no longer sets `toolchainFile` at a level that prevents leaf presets from overriding. Pick **Option 2** (delete toolchain files) if `CMAKE_GENERATOR_PLATFORM` is not actually needed by any active preset; otherwise **Option 1** (move to a leaf preset). Document the choice in the commit message.
- [ ] **AC-4: VCPKG_CHAINLOAD removable.** With AC-3 in place, the CI's `VCPKG_CHAINLOAD_TOOLCHAIN_FILE` workaround is no longer needed. Remove it from the workflow (or note it's redundant if leaving for safety). If retained, comment why.
- [ ] **AC-5: Local-developer happy path.** Cloning fresh on Windows, opening in Visual Studio (or CLion), and selecting the Windows preset configures successfully **without** a pre-installed system curl and **without** a configured vcpkg manifest. Verified by walking through that exact flow once.
- [ ] **AC-6: CI continues to pass.** All CI jobs (Linux Native, macOS Native, Windows Native, Quality Gates) remain green after the changes. No regression in vcpkg-based Windows build.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (CMake style consistent with existing files)
- [ ] **AC-STD-2:** No new unit tests required (build-system change)
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check`)
- [ ] **AC-STD-15:** Git Safety

---

## Tasks / Subtasks

- [ ] Task 1: Graceful CURL fallback (AC: 1, 2)
  - [ ] 1.1: In `src/CMakeLists.txt`, replace `find_package(CURL REQUIRED)` with `find_package(CURL)`
  - [ ] 1.2: Wrap the link path in `if (CURL_FOUND)`; in the `else` branch, `add_library(CURL::libcurl INTERFACE IMPORTED)` and `target_compile_definitions(MUCommon PRIVATE MU_CURL_DISABLED=1)`
  - [ ] 1.3: At the `ShopListManager` (or equivalent consumer) entry point, gate the download path on `#ifndef MU_CURL_DISABLED`; emit a single `mu::log::Get("network")->info(...)` on the disabled branch
- [ ] Task 2: Preset toolchain cleanup (AC: 3, 4)
  - [ ] 2.1: Verify whether `CMAKE_GENERATOR_PLATFORM` from `toolchain-x64.cmake` is actually needed by any active preset. Greps in active CMake code; check `CMakePresets.json` consumers
  - [ ] 2.2: If unused → **Option 2**: `git rm` the toolchain files, remove `toolchainFile` from `CMakePresets.json` parent presets
  - [ ] 2.3: If still needed → **Option 1**: rename parent preset to a non-toolchain base; create `windows-x64-default-toolchain` leaf that sets `toolchainFile`; update CI to use the leaf
  - [ ] 2.4: Either way, remove `VCPKG_CHAINLOAD_TOOLCHAIN_FILE` from `.github/workflows/ci.yml` (if redundant) or comment it out with a note
- [ ] Task 3: Local Windows developer test (AC: 5)
  - [ ] 3.1: On a clean Windows checkout *without* vcpkg pre-configured, attempt `cmake --preset windows-x64-vcpkg` (or equivalent leaf). Configure should succeed
  - [ ] 3.2: Open in Visual Studio (or CLion) and verify the preset is selectable + configures
- [ ] Task 4: CI verification (AC: 6)
  - [ ] 4.1: Push branch; verify all four CI jobs pass
  - [ ] 4.2: Confirm Windows job still picks up vcpkg manifest curl correctly (i.e., AC-1's fallback only triggers when curl is genuinely absent)

---

## Dev Notes

### Why graceful fallback matters even with vcpkg in CI

The vcpkg manifest path makes the CI build deterministic, but it doesn't
help the contributor flow. Anyone cloning the repo for the first time —
without a global vcpkg install, without setting `VCPKG_ROOT`, without
running `bootstrap-vcpkg.bat` — currently can't configure on Windows.
The graceful fallback lets them get to a working build with downloads
disabled, then opt into vcpkg later if they need full functionality.

The OpenSSL precedent at `src/CMakeLists.txt:298` has been working that
way for the project; this story extends the same pattern to CURL.

### Why option 2 is preferred for the toolchain cleanup

Mosch's note on the toolchain files: *"they only set
`CMAKE_GENERATOR_PLATFORM`, which Ninja Multi-Config ignores"*. CI uses
Ninja Multi-Config, so the toolchain files are already a no-op there.
Local Visual Studio users get the platform from the preset's
`architecture` field instead. Deleting the toolchain files entirely
avoids the inheritance-override headache and reduces the build-system
surface.

If a future contributor needs `CMAKE_GENERATOR_PLATFORM` set explicitly
(e.g., for a non-VS, non-Ninja generator), it can be added back at the
leaf level then.

### Out of scope

- Other optional-dependency cleanups (e.g., the OpenSSL pattern is already
  graceful; this story only adds the CURL parallel)
- Migrating to Conan or another package manager — orthogonal initiative
- The `find_package` ordering issues elsewhere in `src/CMakeLists.txt` —
  if any surface during work, file a follow-up

### Source

[`MuMain/docs/pr-329-review-followups.md`](../../../MuMain/docs/pr-329-review-followups.md)
items #8 and #9 (Mosch's preferred fixes — sidestepped by `2aefc9ef`,
not fixed).

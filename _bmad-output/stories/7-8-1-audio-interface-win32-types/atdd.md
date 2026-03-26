# ATDD Checklist — Story 7.8.1: Audio Interface Win32 Type Cleanup

**Story:** `7-8-1-audio-interface-win32-types`
**Flow Code:** `VS0-QUAL-BUILD-AUDIO`
**Story Type:** infrastructure
**Date Generated:** 2026-03-26
**State:** STATE_1_ATDD_READY

---

## Test Summary

| Layer | Tests | Status | Files |
|-------|-------|--------|-------|
| CMake static analysis | 5 tests | RED | `tests/build/test_ac*_7_8_1.cmake` |
| Catch2 unit (runtime) | 4 TEST_CASEs | RED (AC-2 sizeof check) / compile-GREEN | `tests/audio/test_audio_interface_portable_types_7_8_1.cpp` |
| E2E | N/A (infrastructure story) | — | — |
| Bruno API collection | N/A (no API endpoints) | — | — |

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File | Phase |
|----|-------------|-------------|-----------|-------|
| AC-1 | DSPlaySound.h HRESULT/HWND/OBJECT* wrapped in `#ifdef _WIN32` | `7.8.1-AC-1:dsplaysound-win32-guard` (CMake) | `test_ac1_dsplaysound_win32_guard_7_8_1.cmake` | RED |
| AC-2 | IPlatformAudio.h uses only portable types | `7.8.1-AC-2:iplatformaudio-portable-types` (CMake) + `AC-2: IPlatformAudio::PlaySound return type is bool` (Catch2) | `test_ac2_iplatformaudio_portable_types_7_8_1.cmake` + `test_audio_interface_portable_types_7_8_1.cpp` | RED |
| AC-3 | MiniAudioBackend.h overrides have no Win32 types | `7.8.1-AC-3:miniaudiobackend-no-win32-types` (CMake) | `test_ac3_miniaudiobackend_no_win32_types_7_8_1.cmake` | RED |
| AC-4 | All call sites compile with new signatures | `AC-4: Affected method call sites compile` (Catch2) | `test_audio_interface_portable_types_7_8_1.cpp` | compile-GREEN |
| AC-5 | check-win32-guards.py exits 0 | `7.8.1-AC-5:check-win32-guards-audio` (CMake) | `test_ac5_check_win32_guards_audio_7_8_1.cmake` | RED |
| AC-6 | `./ctl check` passes | `./ctl check` quality gate (manual) | N/A (build verification) | N/A |
| AC-STD-1 | Code standards: no HRESULT/BOOL/HWND outside guards, clang-format | CMake AC-2 + AC-3 tests | CMake tests | RED |
| AC-STD-2 | Modified headers compile on all platforms | `AC-STD-2: Audio interface headers compile` (Catch2) | `test_audio_interface_portable_types_7_8_1.cpp` | compile-GREEN |
| AC-STD-11 | Flow code traceability | `7.8.1-AC-STD-11:flow-code-traceability` (CMake) | `test_ac_std11_flow_code_7_8_1.cmake` | GREEN |
| AC-STD-13 | Quality gate: `./ctl check` exits 0 | `./ctl check` quality gate (manual) | N/A | N/A |
| AC-STD-15 | Git safety: no force push, no incomplete rebase | Manual / CI | N/A | N/A |

---

## Implementation Checklist

### Pre-Implementation

- [ ] Story AC-to-test mapping reviewed and understood
- [ ] Existing tests in `tests/audio/test_muaudio_abstraction.cpp` reviewed (Story 5.1.1) — these must remain GREEN after type changes
- [ ] Current Win32 types in affected headers confirmed:
  - [ ] `IPlatformAudio.h`: `HRESULT PlaySound(...)`, `BOOL looped`, `BOOL resetPosition`, `BOOL enforce`, `OBJECT* pObject`
  - [ ] `MiniAudioBackend.h`: Same types in override declarations + `const OBJECT*` in `m_soundObjects`
  - [ ] `DSPlaySound.h`: `HRESULT InitDirectSound(HWND)`, `HRESULT PlayBuffer(OBJECT*, BOOL)`, `HRESULT ReleaseBuffer`, `HRESULT RestoreBuffers`, `void StopBuffer(ESound, BOOL)`

### Task 1: Audit (no code changes)

- [ ] Task 1.1: Read `Audio/DSPlaySound.h` — identify all HRESULT/HWND/BOOL/OBJECT* declarations
- [ ] Task 1.2: Read `Platform/IPlatformAudio.h` — map virtual method signatures to Win32 types
- [ ] Task 1.3: Read `Platform/MiniAudio/MiniAudioBackend.h` — confirm override signatures match

### Task 2: Fix `Platform/IPlatformAudio.h` (AC-2)

- [ ] Task 2.1: Replace `virtual HRESULT PlaySound(ESound buffer, OBJECT* pObject = nullptr, BOOL looped = false) = 0` with `[[nodiscard]] virtual bool PlaySound(ESound buffer, void* pObject = nullptr, bool looped = false) = 0`
- [ ] Task 2.2: Replace `virtual void StopSound(ESound buffer, BOOL resetPosition)` with `virtual void StopSound(ESound buffer, bool resetPosition)`
- [ ] Task 2.3: Replace `virtual void PlayMusic(const char* name, BOOL enforce)` with `virtual void PlayMusic(const char* name, bool enforce)`
- [ ] Task 2.4: Replace `virtual void StopMusic(const char* name, BOOL enforce)` with `virtual void StopMusic(const char* name, bool enforce)`
- [ ] Verify CMake test `7.8.1-AC-2:iplatformaudio-portable-types` now passes

### Task 3: Fix `Platform/MiniAudio/MiniAudioBackend.h` (AC-3)

- [ ] Task 3.1: Update `PlaySound` override signature to `[[nodiscard]] bool PlaySound(ESound buffer, void* pObject = nullptr, bool looped = false) override`
- [ ] Task 3.2: Update `StopSound` override to `void StopSound(ESound buffer, bool resetPosition) override`
- [ ] Task 3.3: Update `PlayMusic` override to `void PlayMusic(const char* name, bool enforce) override`
- [ ] Task 3.4: Update `StopMusic` override to `void StopMusic(const char* name, bool enforce) override`
- [ ] Task 3.5: Replace `std::array<const OBJECT*, MAX_BUFFER> m_soundObjects{}` with `std::array<const void*, MAX_BUFFER> m_soundObjects{}`
- [ ] Verify CMake test `7.8.1-AC-3:miniaudiobackend-no-win32-types` now passes

### Task 4: Fix `Audio/DSPlaySound.h` (AC-1)

- [ ] Task 4.1: Wrap DirectSound-only declarations in `#ifdef _WIN32` guard:
  ```cpp
  #ifdef _WIN32
  HRESULT InitDirectSound(HWND hDlg);
  HRESULT PlayBuffer(ESound Buffer, OBJECT* Object = NULL, BOOL bLooped = false);
  void StopBuffer(ESound Buffer, BOOL bResetPosition);
  HRESULT ReleaseBuffer(int Buffer);
  HRESULT RestoreBuffers(int Buffer, int Channel);
  #endif // _WIN32
  ```
- [ ] Verify CMake test `7.8.1-AC-1:dsplaysound-win32-guard` now passes

### Task 5: Fix all call sites (AC-4)

- [ ] Task 5.1: Grep for callers of changed virtual methods:
  ```bash
  grep -rn "PlaySound\|StopSound\|PlayMusic\|StopMusic" MuMain/src/source/ --include="*.cpp"
  ```
- [ ] Task 5.2: Update `MiniAudioBackend.cpp` implementations:
  - `HRESULT MiniAudioBackend::PlaySound(...)` → `bool MiniAudioBackend::PlaySound(...)`
  - `S_OK` / `S_FALSE` returns → `true` / `false`
  - `BOOL looped` params → `bool looped`
  - `BOOL resetPosition`, `BOOL enforce` params → `bool`
  - `m_soundObjects` element accesses: `const OBJECT*` → `const void*`
- [ ] Task 5.3: Verify Winmain.cpp call sites compile with new signatures
- [ ] Verify Catch2 test `AC-2: IPlatformAudio::PlaySound return type is bool` now passes (sizeof check)

### Task 6: Verify quality gate (AC-5, AC-6)

- [ ] Task 6.1: Run `python3 MuMain/scripts/check-win32-guards.py`
  - Expected: exits 0, no violations reported for audio headers
- [ ] Task 6.2: Run `./ctl check` (build + test + format-check + lint)
  - Expected: all green on macOS arm64 native build
- [ ] Verify CMake test `7.8.1-AC-5:check-win32-guards-audio` now passes

### PCC Compliance

- [ ] No prohibited libraries used (no mocking frameworks, no Win32 APIs in test TUs)
- [ ] Required testing patterns: Catch2 `TEST_CASE`/`SECTION`, `REQUIRE`/`CHECK` — used correctly
- [ ] No `#ifdef _WIN32` added to game logic files (only platform abstraction layer)
- [ ] `[[nodiscard]]` added to `PlaySound()` return value in updated interface
- [ ] All modified files pass `clang-format` (Allman braces, 4-space, 120-col)
- [ ] All Catch2 tests compile on macOS/Linux/Windows (MinGW CI)

### Story Completion

- [ ] All CMake tests in `tests/build/` for story 7-8-1 pass (`ctest -R 7.8.1`)
- [ ] All Catch2 tests in `test_audio_interface_portable_types_7_8_1.cpp` pass
- [ ] Existing Story 5.1.1 tests in `test_muaudio_abstraction.cpp` still GREEN
- [ ] `./ctl check` exits 0 (AC-6 / AC-STD-13)
- [ ] Story status updated to `done`
- [ ] Sprint status updated in `_bmad-output/implementation-artifacts/sprint-status.yaml`

---

## Test Files Created

| File | Type | Tests | Status |
|------|------|-------|--------|
| `MuMain/tests/build/test_ac1_dsplaysound_win32_guard_7_8_1.cmake` | CMake static | AC-1 (3 checks) | RED |
| `MuMain/tests/build/test_ac2_iplatformaudio_portable_types_7_8_1.cmake` | CMake static | AC-2 (4 checks) | RED |
| `MuMain/tests/build/test_ac3_miniaudiobackend_no_win32_types_7_8_1.cmake` | CMake static | AC-3 (4 checks) | RED |
| `MuMain/tests/build/test_ac5_check_win32_guards_audio_7_8_1.cmake` | CMake static | AC-5 (3 checks) | RED |
| `MuMain/tests/build/test_ac_std11_flow_code_7_8_1.cmake` | CMake static | AC-STD-11 | GREEN |
| `MuMain/tests/audio/test_audio_interface_portable_types_7_8_1.cpp` | Catch2 unit | AC-2/AC-3/AC-4/AC-STD-2 (4 TEST_CASEs) | RED (AC-2 sizeof), compile-GREEN |

**CMakeLists.txt updated:**
- `MuMain/tests/build/CMakeLists.txt` — 5 new `add_test()` entries for story 7.8.1
- `MuMain/tests/CMakeLists.txt` — 1 new `target_sources()` for Catch2 test file

---

## Notes for Developer

### RED Phase Indicator Test
The primary RED/GREEN indicator is the `sizeof` check in `test_audio_interface_portable_types_7_8_1.cpp`:
```cpp
auto result = backend.PlaySound(static_cast<ESound>(0), nullptr, false);
REQUIRE(sizeof(result) == sizeof(bool)); // sizeof(HRESULT=long) != sizeof(bool)
```
- **RED**: `sizeof(long)` = 8 (macOS 64-bit) or 4 (Win32) ≠ 1 → FAILS
- **GREEN**: `sizeof(bool)` = 1 → PASSES

### Implementation Order
Fix IPlatformAudio.h (Task 2) FIRST — it's the contract. Then update MiniAudioBackend.h (Task 3) to match. Then update DSPlaySound.h (Task 4) and call sites (Task 5). This order prevents cascading compile errors.

### `OBJECT*` → `void*` Migration
The `OBJECT` type is defined in `World/w_ObjectInfo.h` and forward-declared in `Core/mu_struct.h`. Using `void*` in the audio interface is safe because the MiniAudio backend never dereferences `pObject` directly — it uses it only for 3D position lookup via `m_soundObjects`. The cast `reinterpret_cast<const void*>(pObject)` at call sites, and `reinterpret_cast<const OBJECT*>(m_soundObjects[i])` in Set3DSoundPosition are the correct migration pattern.

### S_OK / S_FALSE → true / false
- `S_OK` (0) = success → `true`
- `S_FALSE` (1) = "no-op success" (e.g., already playing) → `false`
- `FAILED(hr)` (negative HRESULT) → `false`
Follow the semantic that `true` = operation performed, `false` = operation not performed or failed.

# Code Review — Story 7.3.2: Linux 60-Minute Stability Session

**Reviewer:** Claude Opus 4.6 (adversarial code review)
**Date:** 2026-03-30
**Story Status:** review
**Review Type:** Adversarial code review (find and document issues)

---

## Quality Gate

**Status:** Pending — run by pipeline

| Check | Component | Result |
|-------|-----------|--------|
| lint | mumain | PASS |
| build | mumain | FAIL → FIXED (see Finding #1) |

---

## Findings

### Finding #1 — BLOCKER

**Severity:** BLOCKER
**File:** `MuMain/src/source/Main/Winmain.cpp:255-256`
**Category:** Build failure

**Description:** `g_aszMLSelection` is used but never declared. This variable was a `wchar_t[]` buffer in the old WinMain code that was removed during story 7-9-3 (entry point unification). The code at line 255 copies a language string into this deleted buffer, then assigns to `g_strSelectedML`.

**Fix applied (build gate):** Replaced the intermediate buffer copy with a direct assignment:
```cpp
// Before (broken):
std::wstring langSelection = GameConfig::GetInstance().GetLanguageSelection();
wcsncpy_s(g_aszMLSelection, langSelection.c_str(), MAX_LANGUAGE_NAME_LENGTH - 1);
g_strSelectedML = g_aszMLSelection;

// After (fixed):
g_strSelectedML = GameConfig::GetInstance().GetLanguageSelection();
```

**Note:** This build break is from story 7-9-3, not 7-3-2. Fixed as a build gate prerequisite.

---

### Finding #2 — HIGH

**Severity:** HIGH
**File:** `MuMain/tests/stability/test_linux_stability_session.cpp:180-200`
**Category:** Incorrect assumption / false confidence

**Description:** The `CountErrorLogEntries()` function scans log files for the `[ERROR]` tag. However, `CErrorReport::Write()` is a raw `wprintf`-style formatter — **callers never emit `[ERROR]` tags**. Grepping the entire `src/source/` tree for `[ERROR]` returns zero matches. The actual error log format uses free-form strings like `"Connecting error."`, `"InitDirectSound - SetCooperativeLevel failed"`, etc.

This means the AC-5 infrastructure tests validate a scanner that will **always return 0** against real production logs, regardless of how many actual errors were logged. The tests pass, but they provide false confidence that the monitoring tool works correctly.

**Impact:** During a real 60-minute stability session, `CountErrorLogEntries()` will report 0 errors even if the log is full of actual error messages, defeating the purpose of AC-5 validation.

**Suggested fix:** Either:
- (a) Update `CountErrorLogEntries()` to match the actual `CErrorReport::Write()` output format (grep for keywords like `"error"`, `"failed"`, `"FAILED"`, case-insensitive), or
- (b) Introduce a structured `[ERROR]` tag in `CErrorReport::Write()` for new log entries and update the scanner to match, or
- (c) Document this as a known limitation and have the manual operator visually inspect MuError.log during the session (which is the current de facto approach).

**Note:** This issue also exists in the macOS sibling `test_macos_stability_session.cpp:181-199` (story 7-3-1). Both stories inherited the same incorrect assumption.

---

### Finding #3 — MEDIUM

**Severity:** MEDIUM
**File:** `MuMain/tests/stability/test_linux_stability_session.cpp:129-167`
**Category:** Test reliability / CI flakiness

**Description:** The MuTimer infrastructure tests rely on `std::this_thread::sleep_for()` for timing:
- Line 136: `sleep_for(10ms)` — expects no hitch (< 50ms)
- Line 144: `sleep_for(60ms)` — expects hitch detected (> 50ms)
- Line 159: `sleep_for(16ms)` — expects FPS > 30

On a heavily loaded CI runner or VM, OS scheduling jitter can cause a 10ms sleep to take 60ms+, triggering false hitch detection. The FPS test has no upper bound tolerance documented (comment says "15-100 FPS" but only checks `> 30`). While this is acceptable for local development, it introduces CI flakiness risk.

**Suggested fix:** Add a comment documenting that these tests may be flaky under heavy load and should be run on dedicated runners, or increase the sleep gap between "normal" and "hitch" frames (e.g., 5ms vs 200ms) to reduce false positive risk.

**Note:** Inherited from sibling story 7-3-1. Not a regression introduced by 7-3-2.

---

### Finding #4 — MEDIUM

**Severity:** MEDIUM
**File:** `MuMain/tests/stability/test_linux_stability_session.cpp` (entire file)
**Category:** Code duplication

**Description:** The Linux test file is a near-verbatim copy of `test_macos_stability_session.cpp` (~350 lines). The only differences are:
1. `[[maybe_unused]]` (Linux) vs `#pragma clang diagnostic` (macOS) for unused variable suppression
2. Temp file suffix `7_3_2` vs `7_3_1`
3. Catch2 tags `[7-3-2]` vs `[7-3-1]`
4. Log entry platform strings (`"Linux x64"` vs `"macOS arm64"`)

Both files define identical `CountErrorLogEntries()` functions, identical test logic, and identical constant definitions. This 350-line duplication means any fix to Finding #2 (log format mismatch) must be applied in both files.

**Suggested fix:** Extract shared infrastructure (constants, `CountErrorLogEntries`, `TempLogPath`, `RemoveQuiet`) into a shared header like `tests/stability/stability_test_common.h`. Platform-specific tests would include the shared header and only define their platform-tagged test cases.

**Note:** Acceptable for now given the story's infrastructure scope, but should be addressed before adding a third platform stability session (e.g., Windows).

---

### Finding #5 — LOW

**Severity:** LOW
**File:** `MuMain/tests/stability/test_linux_stability_session.cpp:206-224`
**Category:** Resource leak on test failure

**Description:** `RemoveQuiet(logPath)` is called at the end of each AC-5 test case to clean up temp files. However, if a `REQUIRE` assertion fails before the cleanup line, the temp file is leaked in `/tmp/`. Catch2 does not call post-test cleanup on assertion failure by default.

**Suggested fix:** Use RAII cleanup (e.g., a simple destructor-based guard) or Catch2's `SECTION` + event listener for temp file cleanup. Alternatively, call `RemoveQuiet` at the start of each test (before creating the file) as a belt-and-suspenders approach — which is already done, so this is mitigated.

**Actual impact:** Minimal. The files are in `/tmp/` and are tiny. The `RemoveQuiet` at test start means stale files from a previous failed run get cleaned up on the next run.

---

### Finding #6 — LOW

**Severity:** LOW
**File:** `MuMain/tests/CMakeLists.txt:452-454`
**Category:** Unnecessary link dependencies

**Description:** The `MuLinuxStabilityTests` target links `MURenderFX` and `MUAudio`:
```cmake
target_link_libraries(MuLinuxStabilityTests PRIVATE Catch2::Catch2WithMain MUCore MUPlatform MURenderFX MUAudio)
```
The test file only uses `MuTimer.h` from `MUCore`. The `MURenderFX` and `MUAudio` libraries are linked because `MUCore` has transitive symbol dependencies on them (via the PCH and global objects). The test doesn't test any rendering or audio functionality.

**Suggested fix:** No action needed now. This is a consequence of the monolithic legacy architecture. When module boundaries are refined (per the cross-platform migration plan), these transitive dependencies should be eliminated.

---

### Finding #7 — LOW

**Severity:** LOW
**File:** `docs/stories/7-3-2-linux-stability-session/progress.md:9`
**Category:** Misleading status

**Description:** The progress file header says `status: complete` but the story is in `review` status. The "complete" refers to automated task completion (10/10 tasks), but could be misread as the story itself being done. The manual validation phase hasn't started.

**Suggested fix:** Change to `status: review` or `status: automated-tasks-complete` to avoid ambiguity.

---

## ATDD Coverage

### Infrastructure Tests (Automated)

| AC | Test | Verdict | Notes |
|----|------|---------|-------|
| AC-4 | Threshold constants consistent | ✅ Accurate | Pure arithmetic, no external deps |
| AC-4 | MuTimer hitch detection | ✅ Accurate | Exercises real API, sleep-based timing |
| AC-4 | MuTimer FPS measurement | ✅ Accurate | Exercises real API, sleep-based timing |
| AC-5 | Log scan: clean log → 0 | ⚠️ Misleading | Scanner uses `[ERROR]` format not emitted by production code (Finding #2) |
| AC-5 | Log scan: error log → 1 | ⚠️ Misleading | Same format mismatch — test creates synthetic `[ERROR]` entries |
| AC-5 | Log scan: missing file → -1 | ✅ Accurate | File-not-found sentinel works correctly |

### Manual Tests (SKIP — RED Phase)

| AC | Test | SKIP Present | Stub Correct |
|----|------|-------------|--------------|
| AC-1 | 60+ min session | ✅ | ✅ Commented REQUIRE matches AC |
| AC-2 | Required activities | ✅ | ✅ Activities documented |
| AC-3 | No disconnects | ✅ | ✅ SESSION_DISCONNECT_COUNT check |
| AC-4 | Session FPS/hitches | ✅ | ✅ SESSION_MIN_FPS + SESSION_HITCH_COUNT |
| AC-5 | Session error log | ✅ | ⚠️ Will use same broken scanner (Finding #2) |
| AC-6 | Memory stable | ✅ | ✅ SESSION_MEMORY_GROWTH_PCT check |
| AC-VAL-1 | Session log artifact | ✅ | ✅ Documentation assertion |
| AC-VAL-2 | MuError.log reference | ✅ | ✅ Documentation assertion |
| AC-VAL-3 | Memory snapshots | ✅ | ✅ Documentation assertion |

### ATDD Checklist Accuracy

The ATDD checklist at `_bmad-output/stories/7-3-2-linux-stability-session/atdd.md` is **mostly accurate** with one caveat:

- All 6 infrastructure tests are marked GREEN ✓ — tests do pass
- All 9 manual tests are correctly marked RED with SKIP — verified in source
- **Caveat:** AC-5 infrastructure tests are marked GREEN but validate against a log format (`[ERROR]`) that production code never emits (Finding #2). The tests pass vacuously.

---

## Summary

| Severity | Count | Key Issue |
|----------|-------|-----------|
| BLOCKER | 1 | Build failure from 7-9-3 (`g_aszMLSelection`) — **FIXED** |
| HIGH | 1 | `CountErrorLogEntries` searches for `[ERROR]` never emitted by production code |
| MEDIUM | 2 | Sleep-based test flakiness risk; 350-line code duplication with macOS sibling |
| LOW | 3 | Temp file leak on assertion failure; unnecessary link deps; misleading progress status |

**Recommendation:** Finding #2 (HIGH) should be resolved before the manual GREEN phase, as the error log scanner will provide false confidence during the real stability session. The BLOCKER has been fixed. MEDIUM and LOW findings are acceptable for this story's scope.

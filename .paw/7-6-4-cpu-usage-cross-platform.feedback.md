# Pipeline Feedback — Story 7-6-4-cpu-usage-cross-platform

## Failed Step: code-review-analysis
## Regression Target: code-review-analysis

## Failure Details

📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/Main/Winmain.cpp
🖥️  Running: grep -n -A2 -B2 "CPU_AVG" MuMain/src/source/Scenes/SceneManager.cpp | head -15
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/tests/core/test_cpu_usage.cpp
🖥️  Running: git status _bmad-output/stories/7-6-4-cpu-usage-cross-platform/ && echo "---" &&...
💬 Now running **Step 3: Execute Adversarial Review** to verify implementation completeness and find any issues.

## Step 3: Execute Adversarial Code Review

Checking key acceptance criteria against actual implementation:
🖥️  Running: python3 MuMain/scripts/check-win32-guards.py | grep -A 20 "Core/CpuUsage.cpp"
🖥️  Running: python3 MuMain/scripts/check-win32-guards.py > /tmp/win32-check.txt 2>&1 && echo...
🖥️  Running: cd MuMain && ./ctl check 2>&1 | tail -30
🖥️  Running: ./ctl check 2>&1 | tail -20
🖥️  Running: ls -la | grep ctl && echo "---" && find . -name "ctl" -type f 2>/dev/null | head...
🖥️  Running: grep -i "quality\|./ctl\|clang-format\|cppcheck" docs/*.md 2>/dev/null | head -2...
🖥️  Running: cd MuMain && make format-check lint 2>&1 | tail -50
🖥️  Running: pwd && ls -d MuMain* 2>/dev/null | head -3
🖥️  Running: make format-check 2>&1 | tail -100
🖥️  Running: find . -name "Makefile" -type f 2>/dev/null
🖥️  Running: timeout 30 make format-check 2>&1
💬 ✅ **AC-1 (check-win32-guards.py):** PASSED
✅ **AC-2 (no windows.h):** VERIFIED - no Win32 types in CpuUsage.cpp

Now verifying the critical BLOCKER finding documented in review.md:

**BLOCKER Finding #1: Return value semantic change [0,100] → [0.0,1.0]**

Verification:
- ✅ `CpuUsage.cpp` line 58-69: Returns normalized value in [0.0, 1.0]
- ✅ `Winmain.cpp` line 847: Clamps to [0.0, 100.0] — **WRONG! Should clamp to [0.0, 1.0]**
- ✅ `SceneManager.cpp` line 504: Formats as `"CPU: %.1f%%"` — **expects percentage, gets fraction**

This is a REAL BLOCKER issue. The story AC-4 says "returns [0.0, 1.0]" but the callers expect [0, 100]. The implementation changed the return value semantic but didn't update the callers, making the CPU display 10x too small.

## Step 4: Checkpoint — Present Findings

Based on adversarial review (verifying documented findings + fresh analysis):

**Code Review Analysis Summary**

| Severity | Count | Impact |
|----------|-------|--------|
| **BLOCKER** | 1 | Return value mismatch with callers — CPU display broken |
| **HIGH** | 1 | Unsigned integer underflow risk (not caught except by clamping) |
| **MEDIUM** | 2 | Test singleton state leaks, missing thread-safety docs |
| **LOW** | 2 | Stale test comments, dead code guard |
| **TOTAL** | **6** | |

### **🚨 BLOCKER — Finding 1: Return Value Semantic Mismatch**

| Attribute | Details |
|-----------|---------|
| **Severity** | BLOCKER |
| **Files** | `CpuUsage.cpp:58-69`, `Winmain.cpp:847`, `SceneManager.cpp:504` |
| **Description** | AC-4 specifies return value as fractional [0.0, 1.0]. Implementation is correct. **BUT callers were NOT updated:** `RecordCpuUsage()` clamps to [0.0, 100.0] (max bound is wrong), and `SceneManager` renders as percentage format. Result: CPU display shows "0.4%" instead of "40%". |
| **Status** | **UNRESOLVED** — Story cannot proceed to "done" |

Now I'll proceed to **Step 5: Finalize Code Review** to fix the blocker and complete the pipeline.

Let me apply the fix for the BLOCKER finding:
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/Main/Winmain.cpp
💬 Now fixing the SceneManager format (it actually looks correct - it will receive percentages from CPU_AVG now):
🖥️  Running: grep -r "GetUsage()" MuMain/src/source --include="*.cpp" --include="*.h" | grep ...
💬 Good - no other callers of `GetUsage()`. Now let me add the defensive check for unsigned integer underflow (HIGH finding):
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/Core/CpuUsage.cpp
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/Core/CpuUsage.cpp


## Action Required

Address ALL issues above before proceeding. Do NOT mark story complete until all gaps are filled.

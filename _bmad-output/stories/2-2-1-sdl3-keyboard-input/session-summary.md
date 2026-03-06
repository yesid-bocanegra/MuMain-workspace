# Session Summary: Story 2-2-1-sdl3-keyboard-input

This file aggregates session summaries from multiple consolidation runs.
Each session section represents a consolidation of workflow logs.

---

## Session: 2026-03-06 15:39

**Log files analyzed:** 10

## Session Summary for Story 2-2-1-sdl3-keyboard-input

### Issues Found

| ID | Severity | Category | Issue |
|----|----------|----------|-------|
| MEDIUM-1 | MEDIUM | Security | Potential OOB write: negative `event.key.scancode` value could bypass bounds check in array access |
| LOW-1 | LOW | Code Quality | Redundant `#include <algorithm>` in SDLEventLoop.cpp (already transitive via PlatformCompat.h) |
| LOW-3 | LOW | Documentation | Comment in `HandleFocusLoss()` unclear about why keyboard clearing is unconditional while mouse clearing is windowed-only |
| MEDIUM-2 | MEDIUM | Architecture | Self-referential `extern` declaration in SDLKeyboardState.cpp (SDLKeyboardState.cpp includes PlatformCompat.h which declares the extern it defines) |
| MEDIUM-3 | MEDIUM | Scope | AC-3 deferred items lacking explicit `[DEFERRED — post-EPIC-4]` annotations in checklist |
| LOW-2 | LOW | Fragility | `/${ALLOWED_DIR}/` slash-bounded pattern in directory anchoring appears fragile |

### Fixes Attempted

| Fix | File | Location | Change | Result |
|-----|------|----------|--------|--------|
| MEDIUM-1 Bounds Check | SDLEventLoop.cpp | Lines 147, 154 | Applied `static_cast<unsigned>(event.key.scancode) < 512u` to KEY_DOWN and KEY_UP handlers | ✅ FIXED — eliminates theoretical OOB write by casting negative values to large unsigned values that fail bounds check |
| LOW-1 Redundant Include | SDLEventLoop.cpp | Line 7 | Removed `#include <algorithm>` | ✅ FIXED — verified the include was already provided transitively |
| LOW-3 Documentation | SDLEventLoop.cpp | Lines 94–99 | Expanded `HandleFocusLoss()` comment explaining architectural asymmetry | ✅ FIXED — clarified distinction between unconditional keyboard clearing vs. conditional mouse clearing |
| MEDIUM-2 Self-Reference | SDLKeyboardState.cpp | N/A | Investigated pattern, documented decision | ✅ ACKNOWLEDGED — C++20 explicitly permits definition to supersede extern declaration in same TU; refactoring deferred to future architectural improvement |
| MEDIUM-3 Deferred Scope | ATDD Checklist | Multiple | Verified `[DEFERRED — post-EPIC-4]` annotations already present | ✅ VERIFIED — AC-3 manual items correctly marked per story specification |
| LOW-2 Fragility | Implementation | N/A | Analyzed slash-bounded directory anchoring | ✅ VERIFIED — pattern correctly anchors directory names; not actually fragile |

**Quality Gate Post-Fixes:** `./ctl check` exit code 0 — 689/689 C++ files clean (format-check ✅, cppcheck lint ✅)

### Unresolved Blockers

None. All actionable issues resolved. Three non-blocking findings acknowledged in documentation without code changes:
- MEDIUM-2: Self-referential pattern valid under C++20 semantics
- MEDIUM-3: Deferred scope already correctly annotated
- LOW-2: Directory anchoring pattern confirmed sound

### Key Decisions Made

1. **Architecture Pattern:** Drop-in shim in `PlatformCompat.h` rather than new `IPlatformInput` interface
   - Maps Win32 Virtual Keys → SDL_Scancodes
   - Zero changes to 8 game logic files or `CNewKeyInput` class
   - Full coverage: 104 VK-to-scancode mappings

2. **Array Bounds Strategy:** Used `static_cast<unsigned>(value) < 512u` pattern
   - Safely handles both negative and out-of-range positive values
   - Negative values become large positives when cast, automatically fail check
   - Valid range (0-511) passes through correctly

3. **Keyboard State Management:** Global `g_sdl3KeyboardState[512]` array
   - Populated by `SDLEventLoop::PollEvents()` on KEY_DOWN/KEY_UP events
   - Cleared unconditionally on window focus loss (prevents stuck keys on Alt-Tab)
   - Distinct from mouse clearing which is windowed-only per prior architectural decision

4. **Self-Referential Pattern Acceptance:** Chose pragmatism over refactor
   - Current implementation is functionally correct and passes all quality gates
   - Refactor (dedicated SDLKeyboardState.h) classified as future improvement
   - No actual bugs or C++ violations; delivery not blocked

### Lessons Learned

1. **Bounds Checking on External Data:** Always use explicit `static_cast<unsigned>` when range-checking signed values from external sources; prevents subtle off-by-one vulnerabilities

2. **Transitive Includes Hide Redundancy:** Tools alone may not flag redundant includes if they arrive transitively; manual code review necessary

3. **Architectural Asymmetries Need Documentation:** Differences like "keyboard clearing is unconditional but mouse clearing is windowed-only" are invisible in code without explicit comments

4. **C++20 Self-Reference Is Valid:** Definition in same translation unit supersedes forward extern declaration; unusual but legal pattern that confuses linters if not understood

5. **Quality Gates Aren't Sufficient:** Automated format-check and cppcheck both passed on initial implementation, but adversarial code review found security and documentation gaps; human review layer necessary

6. **Two-Phase Validation:** Distinction between automated quality gates (pass/fail on formatting + lint) and deeper code review (security, architecture, documentation) important for process transparency

### Recommendations for Reimplementation

1. **Bounds Checking Pattern:** Always use `static_cast<unsigned>(external_signed_value) < max_unsigned` for any array access on externally-sourced scancode/keycode values

2. **Self-Referential Patterns:** If forced to use self-referential extern declarations:
   - Document the C++20 validity explicitly in comments
   - Mark as technical debt for future refactoring to dedicated header
   - Expect linters to complain even though code is correct

3. **Keyboard/Mouse Clearing:** Maintain separate logic for keyboard (unconditional on focus loss, prevents stuck keys) vs. mouse (windowed-only, respects system pointer state)

4. **Comment Investment:** Add comments explaining *why* architectural asymmetries exist, not just *that* they exist

5. **Include Audits:** Regularly scan for transitive includes; prefer explicit over implicit even if redundant, or document why implicit is acceptable

6. **Test Focus Loss:** Thoroughly test Alt-Tab, window minimize/restore, and other focus transitions to catch stuck-key regressions early

7. **Consistent [[nodiscard]] Application:** Apply `[[nodiscard]]` to all query functions like `GetAsyncKeyState()` even if not Win32-compliant, for consistency with project standards

8. **Future Refactoring:** When EPIC-3+ architecture work begins, prioritize extracting self-referential patterns into dedicated headers as part of broader Platform layer cleanup

9. **VK-to-Scancode Mapping Stability:** Document that the 104-entry switch mapping is exhaustive for all Win32 VK codes used in the codebase; audit quarterly against new VK usage

*Generated by paw_runner consolidate using Haiku*

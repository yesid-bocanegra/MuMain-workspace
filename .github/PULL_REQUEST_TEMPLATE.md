## Summary

<!-- Brief description of what this PR does and why -->

## Changes

<!-- Bullet list of specific changes -->

-

## Portability Checklist

<!-- Check all that apply. If a box is unchecked, explain why in the comments. -->

- [ ] No new Win32 API calls (checked against [banned API table](docs/development-standards.md))
- [ ] No `#ifdef _WIN32` in game logic (platform abstraction only)
- [ ] No backslash path literals — forward slashes / `std::filesystem::path`
- [ ] No raw `new`/`delete` — uses `std::unique_ptr` or `std::shared_ptr`
- [ ] No `NULL` — uses `nullptr`
- [ ] No `wchar_t` in new serialization
- [ ] No unguarded `#pragma` — wrapped in `#ifdef _MSC_VER`
- [ ] No edits to generated files (`src/source/Dotnet/PacketBindings_*`, `PacketFunctions_*`)
- [ ] No hardcoded user-facing strings — uses `GAME_TEXT("key")`
- [ ] No new headers added to `stdafx.h`
- [ ] No case-sensitivity assumptions in file paths
- [ ] CI (MinGW) build passes
- [ ] Windows build invariant maintained

## Quality Gates

- [ ] `./ctl check` passes (format-check + lint)
- [ ] MinGW build compiles without warnings (`-Wall -Wextra -Werror`)

## Testing

<!-- Describe how you tested these changes -->

- [ ] Unit tests added/updated (if applicable)
- [ ] Manual testing performed (describe below)

### Manual Test Results

<!-- For UI/rendering/input/audio changes, check applicable items -->

- [ ] Window opens and 3D scene renders correctly
- [ ] Input: mouse targeting, keyboard shortcuts work
- [ ] Audio: sound effects and music play correctly
- [ ] Network: connects to OpenMU, login flow works
- [ ] UI: affected windows display and function correctly

## Related Issues

<!-- Link related issues: Fixes #123, Related to #456 -->

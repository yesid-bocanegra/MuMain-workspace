## Summary

<!-- Brief description of changes. Reference issue numbers if applicable. -->

## Platform Portability Checklist

<!-- Check all that apply. See docs/development-standards.md for details. -->

- [ ] No new Win32 API calls introduced (check against [banned API table](docs/development-standards.md#banned-win32-api-table))
- [ ] No backslash path literals
- [ ] No `wchar_t` in new serialization or storage code
- [ ] No platform conditionals (`#ifdef _WIN32`) in game logic (only in platform abstraction layer)
- [ ] No `NULL` — use `nullptr`
- [ ] No raw `new`/`delete` — use smart pointers or RAII
- [ ] No unguarded `#pragma` — wrap in `#ifdef _MSC_VER`
- [ ] No case-sensitivity assumptions in file paths
- [ ] No edits to generated files (`PacketBindings_*`, `PacketFunctions_*`)
- [ ] No hardcoded user-facing strings (use `GAME_TEXT()` / i18n system)
- [ ] CI (MinGW) build passes
- [ ] Windows build invariant maintained

## Test Plan

<!-- How was this tested? What scenarios were verified? -->

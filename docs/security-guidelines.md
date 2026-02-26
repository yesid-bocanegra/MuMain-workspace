# Security Guidelines

Security considerations for the MuMain game client codebase.

## Vulnerability Reporting

Report security vulnerabilities privately via GitHub issue (mark as confidential) or direct contact with maintainers. Do not open public issues for security bugs.

## Input Validation

### Network Packets

All packet data arrives from the server via the .NET Native AOT bridge. Validate at the boundary:

- **Buffer bounds:** Verify packet length before accessing fields. Never trust length fields from the network.
- **String fields:** Ensure null termination. Use `strncpy_s` or bounded copies — never unbounded `strcpy`.
- **Enum ranges:** Validate enum values fall within expected ranges before using as array indices.
- **Array indices:** Bounds-check all indices derived from packet data before array access.

```cpp
// Good: bounds-checked access
if (index < MAX_ITEMS)
    m_Items[index] = ParseItem(data);

// Bad: trusting network data
m_Items[packet->index] = ParseItem(data);  // potential buffer overflow
```

### File I/O (Asset Loading)

Assets are loaded from disk and may be user-modifiable:

- Validate file headers and magic numbers before parsing
- Use size limits when reading variable-length data
- Follow the asset loading severity escalation (see `development-standards.md` section 2)
- Use `std::filesystem::path` for path construction — never string concatenation with user input

### Configuration Files

- `config.ini` is user-editable — validate all values and clamp to valid ranges
- Translation JSON files: validate structure before accessing keys
- Never use configuration values directly in format strings

## Memory Safety

### Current Codebase (Legacy)

The legacy codebase uses manual memory management with `SAFE_DELETE` macros. When modifying legacy code:

- Do not introduce new raw `new`/`delete` — use `std::unique_ptr`
- Check for double-free in cleanup paths when modifying destructors
- Audit `SAFE_DELETE` usage — ensure pointer is not used after deletion

### New Code Requirements

- **Smart pointers only:** `std::unique_ptr` for ownership, `std::shared_ptr` when shared
- **No raw arrays for buffers:** Use `std::vector` or `std::array`
- **RAII everywhere:** Resources acquired in constructors, released in destructors
- **`[[nodiscard]]` on fallible functions:** Prevent ignored error codes

## Cryptography

### DPAPI Migration (Planned)

The client currently uses Windows DPAPI for credential storage. The cross-platform migration will replace this:

- **Current:** `CryptProtectData` / `CryptUnprotectData` (Windows-only)
- **Target:** Platform-appropriate keychain (macOS Keychain, Linux Secret Service) or portable crypto library
- **Transition rule:** Do not add new DPAPI calls. New credential handling should use the platform abstraction layer once available.

### Network Security

- The .NET network layer handles encryption — do not implement crypto in C++ game code
- Do not log packet contents containing credentials (username, password, auth tokens)
- Use `RtlSecureZeroMemory` (or `memset_s` cross-platform) to clear sensitive buffers

## Logging Security

### What NOT to Log

- Player credentials (username, password, auth tokens)
- Raw packet data containing sensitive fields
- Full file paths that reveal system structure (use relative paths)

### Safe Logging Practices

- Use `g_ErrorReport.Write()` for diagnostic data — it writes to a local file, not transmitted
- `g_ConsoleDebug->Write()` is debug-only (`_DEBUG` + `FOR_WORK` builds) — still avoid logging sensitive data
- Never use `wprintf` or console output for error handling in new code

## Third-Party Dependencies

| Dependency | Risk Mitigation |
|-----------|-----------------|
| Dear ImGui | Vendored in `ThirdParty/`, pinned version, editor-only builds |
| libjpeg-turbo | Pinned v3.1.3, integrity-checked in CI |
| GLEW | Vendored, OpenGL 1.x subset only |
| OGG Vorbis | Vendored audio codec |
| .NET Packets | NuGet package with version lock |

- Vendored dependencies are checked into the repo — review before updating
- NuGet packages use version pinning in `.csproj` files
- CI builds from pinned dependency versions, not latest

## Build Security

- CI enforces `-Wall -Wextra -Werror` — warnings often indicate security issues
- `cppcheck` runs portability and performance checks — catches buffer overflows, null dereferences
- `clang-tidy` (when enabled) includes `bugprone-*` checks for common vulnerability patterns
- Pre-commit hooks prevent committing unformatted code that might bypass review

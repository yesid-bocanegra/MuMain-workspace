# Performance Guidelines

Performance considerations for the MuMain game client — a real-time 3D game running a monolithic game loop.

## Game Loop Constraints

The game loop runs at a fixed tick rate. All per-frame code must complete within the frame budget:

- **No exceptions in the game loop** — exception handling has unpredictable cost. Use return codes.
- **No heap allocation in hot paths** — prefer stack allocation, pre-allocated pools, or `std::array`
- **No blocking I/O in the render path** — file loads and network calls happen asynchronously or during loading screens
- **No `std::string` construction in per-frame code** — use `std::string_view` or pre-allocated buffers

## Timing

Use `std::chrono` for all timing in new code:

```cpp
// Good: std::chrono
auto now = std::chrono::steady_clock::now();
auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - m_LastTick);

// Bad: Win32 timing
DWORD tick = timeGetTime();  // banned — not portable, wraps at 49.7 days
```

- `steady_clock` for gameplay timing (monotonic, not affected by system clock changes)
- `system_clock` only when wall-clock time is needed (logging timestamps)
- Never mix clock types

## Memory Management

### New Code

- `std::unique_ptr` for single ownership (default choice)
- `std::shared_ptr` only when ownership is genuinely shared — has atomic refcount overhead
- `std::vector` with `.reserve()` when size is known ahead of time
- `std::array` for fixed-size collections
- Stack allocation for small, short-lived buffers

### Legacy Code Patterns

The legacy codebase uses `SAFE_DELETE` macros and raw `new`/`delete`. When modifying:

- Do not convert working legacy memory management during unrelated changes
- When refactoring a module, convert to smart pointers as part of that work
- Pre-allocated arrays (e.g., `CHARACTER m_Characters[MAX_CHARACTERS]`) are intentional — do not convert to dynamic allocation

## Rendering Performance

### OpenGL 1.x (Current)

- Batch draw calls where possible — minimize state changes
- Texture atlasing reduces bind calls
- Avoid `glGet*` in the render loop (forces GPU sync)
- Pre-compute matrices on the CPU — the fixed-function pipeline is CPU-bound

### SDL_gpu (Migration Target)

- Prefer GPU-side compute for particle systems and terrain
- Use persistent mapped buffers for frequently updated data
- Minimize pipeline state changes by sorting draw calls

## Network Performance (.NET Layer)

The .NET Native AOT network bridge has specific performance requirements:

- **Zero-allocation hot paths:** Use `Span<byte>` and `stackalloc` for packet construction
- **No LINQ in packet handlers** — hidden allocations from enumerators
- **`ConfigureAwait(false)`** in all library async methods
- **Buffer pooling:** Use `ArrayPool<byte>` for variable-size packet buffers

```csharp
// Good: zero-allocation packet read
Span<byte> buffer = stackalloc byte[PacketHeader.Size];
stream.Read(buffer);

// Bad: allocation per packet
byte[] buffer = new byte[PacketHeader.Size];  // GC pressure
```

## Static Analysis for Performance

cppcheck runs with `--enable=performance` in CI, catching:

- Unnecessary copies (pass by const reference)
- Redundant container operations
- Inefficient string concatenation
- Missing `reserve()` calls on vectors

clang-tidy `performance-*` checks (when enabled) catch:

- `performance-unnecessary-copy-initialization`
- `performance-move-const-arg`
- `performance-inefficient-string-concatenation`

## Profiling

### When to Profile

- After implementing a new system (particle effects, UI windows, network handlers)
- When frame rate drops are reported
- Before and after optimization work (measure, don't guess)

### Tools

| Platform | Tool | Use Case |
|----------|------|----------|
| Windows | Visual Studio Profiler | CPU, memory, GPU |
| Windows | RenderDoc | GPU frame analysis |
| Linux/WSL | perf + flamegraph | CPU profiling |
| All | ImGui overlay (`$fps`, `$fpscounter`) | Runtime monitoring |

### In-Game Debug Commands

```
$fps         — toggle FPS display
$fpscounter  — toggle detailed frame counter
$vsync       — toggle vertical sync
$details     — toggle detail level
```

## Anti-Patterns

| Pattern | Problem | Alternative |
|---------|---------|-------------|
| `std::map` in hot path | Tree traversal per lookup | `std::unordered_map` or sorted `std::vector` |
| `std::string` concatenation in loops | Repeated allocation | `std::string::reserve()` or `fmt::format` |
| Virtual calls in inner loops | Branch prediction miss per call | CRTP or template dispatch |
| `shared_ptr` by default | Atomic refcount overhead | `unique_ptr` unless sharing is required |
| `dynamic_cast` in game loop | RTTI overhead | Type enum + static_cast |
| Allocating in render loop | GC pressure / fragmentation | Pre-allocate, pool, or stack |

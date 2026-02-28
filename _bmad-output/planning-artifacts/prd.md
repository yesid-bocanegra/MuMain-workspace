---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish']
classification:
  projectType: 'Desktop Application / Platform'
  domain: 'Gaming / Open-Source Community Platform'
  complexity: 'HIGH'
  projectContext: 'brownfield'
inputDocuments:
  - _bmad-output/planning-artifacts/product-brief-MuMain-workspace-2026-02-26.md
  - _bmad-output/planning-artifacts/research/domain-ethical-mmo-ecosystem-research-2026-02-26.md
  - _bmad-output/project-context.md
  - docs/index.md
  - docs/project-overview.md
  - docs/architecture-mumain.md
  - docs/architecture-clientlibrary.md
  - docs/architecture-rendering.md
  - docs/integration-architecture.md
  - docs/game-systems-reference.md
  - docs/modular-reorganization.md
  - docs/CROSS_PLATFORM_PLAN.md
  - docs/CROSS_PLATFORM_DECISIONS.md
  - docs/packet-protocol-reference.md
  - docs/asset-pipeline.md
  - docs/testing-strategy.md
  - docs/development-standards.md
  - docs/feature-impact-maps.md
  - docs/security-guidelines.md
  - docs/performance-guidelines.md
workflowType: 'prd'
documentCounts:
  briefs: 1
  research: 1
  projectContext: 1
  projectDocs: 17
---

# Product Requirements Document - MuMain-workspace

**Author:** Paco
**Date:** 2026-02-27

## Executive Summary

MuMain is an open-source, cross-platform game client for MU Online (Season 5.2–6) that connects to OpenMU servers. The immediate goal is simple: **a player should be able to download a native client on Windows, macOS, or Linux, connect to a community server, and play — no patching, no workarounds, no legal gray areas.**

The project addresses a specific gap in the MU Online ecosystem. Official servers (Webzen) have pushed pay-to-win monetization to extremes. Private servers rely on legally questionable patched clients locked to Windows. No legitimate, cross-platform, open-source client-server combination exists. MuMain fills that gap by pairing with OpenMU — the leading open-source MU server — to deliver a complete, legal, community-owned stack.

The primary audience is nostalgic veterans (30s, played MU Online in the early 2000s) who want to return to the game without the pay-to-win treadmill or platform restrictions. Secondary audiences include community server hosts who need a clean client to distribute, and open-source developers attracted to a well-documented, real-world game codebase. New players may arrive organically as community servers go live.

The long-term vision extends beyond the MVP: an extensible codebase that could evolve into an original game, built on the game development expertise and community insights gained through this project. Character portability (SSO), ethical monetization frameworks, and mobile clients are north-star features that become viable once the desktop foundation is solid and a player community exists.

### What Makes This Special

**Ecosystem credibility no one else has.** MuMain comes from the same author ecosystem as OpenMU — the only serious clean-room MU server. This means native client-server compatibility without reverse engineering, giving it a legal and technical moat that private server clients cannot match.

**Three competitive advantages in one package:** (1) Legal clarity — clean-room codebase, not patched binaries; (2) Cross-platform — native Windows, macOS, and Linux from a single codebase via SDL3 migration; (3) Community ownership — open source, transparent, no predatory monetization.

**A real codebase, not a toy.** 692 C++ source files, 84 UI windows, 82 world maps, 200+ network packet types, a .NET Native AOT bridge, and comprehensive documentation. This is a production-grade game client being modernized, not a prototype.

**An unoccupied niche.** Domain research confirms: no competitor currently offers a legal, cross-platform, ethical MU Online client. The $28B+ MMORPG market's nostalgia segment is growing (not declining), and cross-platform expectations are now industry standard.

## Project Classification

| Dimension | Value |
|-----------|-------|
| **Project Type** | Desktop Application / Platform (cross-platform native game client with ecosystem vision) |
| **Domain** | Gaming / Open-Source Community Platform |
| **Complexity** | HIGH — 10-phase SDL3 migration, C++/.NET interop, 692-file legacy modernization, multi-platform targets |
| **Project Context** | Brownfield — existing codebase with 20+ architecture and planning documents |
| **Primary Language** | C++20 with .NET 10 Native AOT bridge |
| **Build Targets** | Windows (MSVC), Linux/macOS (SDL3 migration in progress), CI via MinGW cross-compile |

## Success Criteria

### User Success

The primary user is Paco — the developer-player who wants to play MU Online natively on macOS without workarounds. User success is defined by a single concrete scenario:

1. **"Mac to MU" test** — Launch MuMain on macOS, connect to an OpenMU server, and complete a full gameplay session: login → character select → enter world → combat → inventory management → voluntary logout. No crashes, no disconnects, no platform-specific workarounds required.
2. **Cross-platform parity** — The same binary codebase produces functional clients on Windows, macOS, and Linux. A session that works on Windows works identically on macOS and Linux.
3. **Self-service setup** — Clone the repo, build on any of the three platforms, and connect to a local or remote OpenMU server in under 30 minutes (including build time) with documented steps.

### Business Success

This project is not a business. It is a personal learning platform and a foundation for future experiments. Business success means:

1. **Platform readiness** — A stable, buildable, cross-platform codebase that can serve as the base for new projects (bug fixing sprints, telemetry experiments, gameplay modifications, potentially an original game).
2. **Experiment velocity** — After MVP, new experiments (adding telemetry, modifying game systems, testing ideas) can be started without fighting the build system or platform compatibility. The "tax" of starting a new experiment is low.
3. **Open-source optionality** — The codebase remains open source and well-documented enough that *if* community interest emerges organically, contributors can onboard. This is not a goal — it's an option kept open.

### Technical Success

1. **Single codebase, three platforms** — One CMake build system producing native executables for Windows (MSVC), macOS, and Linux without platform-specific forks or hacks.
2. **.NET network layer on all platforms** — ClientLibrary (.NET Native AOT) builds and loads on Windows, macOS, and Linux. Server connectivity is not Windows-only.
3. **CI green on all changes** — MinGW cross-compile, clang-format, cppcheck, and clang-tidy pass on every push. Quality gates are non-negotiable.
4. **No Win32 leakage** — SDL3 migration phases 0–2 complete. No `#ifdef _WIN32` in game logic, no banned Win32 API calls outside the platform abstraction layer.

### Measurable Outcomes

| Outcome | Measurement | Target |
|---------|-------------|--------|
| macOS gameplay session | Full loop without crash/disconnect | 60+ minute session |
| Linux gameplay session | Full loop without crash/disconnect | 60+ minute session |
| Build from source (any platform) | Clone → build → run time | < 30 minutes |
| .NET network layer | Connects to OpenMU on Mac/Linux | Yes/No gate |
| CI quality gates | Pass rate on main branch | 100% |
| SDL3 migration phases 0–2 | Complete and merged | Yes/No gate |
| Platform-specific code | `#ifdef _WIN32` only in abstraction headers | Zero in game logic |

## User Journeys

### Journey 1: Paco — Developer-Player (Primary, MVP)

**Who:** Paco, experienced software developer and team lead, lifelong MU Online fan. Has a Mac as his daily driver. Dreams of game development. Found MuMain and OpenMU — the first legal, open-source client-server combination for MU Online.

**Opening Scene:** Paco sits at his Mac. He's been reading MuMain's architecture docs and cross-platform plan for weeks. The codebase is real — 692 C++ files, a .NET network bridge, comprehensive documentation. But it only runs on Windows. He wants to play on *this* machine, not maintain a Windows box for one game.

**Rising Action:** He clones the repo, follows the macOS build instructions, and runs `cmake`. The SDL3 migration has replaced Win32 windowing and input. The .NET Native AOT bridge loads on macOS — `.dylib` instead of `.dll`, `char16_t` instead of `wchar_t`. He hits build. It compiles. He spins up a local OpenMU server instance (some rough edges there too, but it starts). He launches MuMain and sees the server list.

**Climax:** He connects. Character select loads. He picks Dark Knight — the class he mained as a teenager. The world renders. Lorencia appears. He walks to the town square, kills a few monsters outside town, opens inventory, equips a sword. It works. On his Mac. No Wine, no VM, no hacks.

**Resolution:** He plays for an hour and logs out voluntarily. The next morning he's already thinking about what to experiment with next — maybe telemetry to understand frame timing, maybe fixing that UI element that looked off. The platform works. The *real* project can begin.

**What could go wrong:**
- Build fails due to undocumented dependency — needs clear build docs per platform
- .NET bridge doesn't load — platform-specific library loading is the critical path
- Rendering glitches (OpenGL differences between platforms) — need ground truth screenshots for comparison
- Server connection drops — network stability across platforms must be validated
- Existing bugs surface (unrelated to cross-platform) — need triage process to separate migration bugs from legacy bugs

**Requirements revealed:** Cross-platform build system, .NET AOT on macOS/Linux, SDL3 windowing/input/rendering, build documentation, error reporting for diagnosing platform-specific issues.

### Journey 2: Paco — Server Host (Primary, MVP)

**Who:** Same Paco, now wearing the server operator hat.

**Opening Scene:** MuMain compiles on macOS. But there's nothing to connect to. He needs an OpenMU server running — likely on his Mac or a local Linux box.

**Rising Action:** He pulls the OpenMU repo, gets it running (.NET server, probably in Docker or directly). Configures it to accept connections. Checks that the default port (44406) is listening. Points MuMain at `localhost:44406`.

**Climax:** The handshake works. Client authenticates, loads character data, enters the world. The client and server are both running on his hardware, both open source, both legal.

**Resolution:** He now has a complete local development environment — client and server — for any experiment he wants to run. He can modify game systems, test changes, break things safely.

**What could go wrong:**
- OpenMU has its own rough edges and setup friction
- Protocol mismatches between client version and server version
- Database setup for OpenMU (player data persistence)

**Requirements revealed:** Documentation of compatible OpenMU version/setup, default connection configuration, clear error messages when server connection fails.

### Journey 3: Marco — The Nostalgic Veteran (Future, Post-MVP)

**Who:** Marco, mid-30s, played MU Online as a teenager. Tried going back to official servers — pay-to-win ruined it. Tried a private server — it died and he lost everything. Uses a MacBook for work.

**Opening Scene:** Marco sees a Reddit post or GitHub link: "Open-source MU Online client — runs on Mac, Linux, Windows. Connects to OpenMU servers." He's skeptical — he's been burned before.

**Rising Action:** He downloads a pre-built binary (no patching, no sketchy installers). Finds a community server running OpenMU. Launches the client, creates an account, picks a class. The UI is familiar — it's MU Online, the one he remembers.

**Climax:** He's grinding in Devias, grouped with two other players. He finds a decent drop, trades with someone in Lorencia. The core loop works — the *feeling* is right. And he's on his Mac.

**Resolution:** He plays a few sessions a week. It becomes his wind-down routine. The game isn't pay-to-win. The server is run by people who care. If this server dies, he's heard there might eventually be character portability. But for now, he's just happy to be back.

**Requirements revealed:** Easy distribution (downloadable binary), server discovery or clear connection instructions, gameplay parity with the MU Online experience veterans remember.

### Journey 4: Sven — The OSS Contributor (Future, Post-MVP)

**Who:** Sven, open-source developer interested in game engines and cross-platform C++. Finds MuMain through the OpenMU ecosystem or GitHub trending.

**Opening Scene:** Sven browses the repo. He sees: comprehensive docs, modular CMake architecture, CI passing, conventional commits, clear contribution path. This isn't a dead fork — it's actively maintained.

**Rising Action:** He clones, builds on Linux, and it works. He reads the architecture docs, picks a small issue (maybe a rendering glitch or a modernization task). He opens a PR with proper formatting and tests.

**Climax:** PR gets reviewed, merged. He sees his code running in an actual game client that real people use.

**Resolution:** He sticks around. Contributes more. Learns the rendering pipeline, the .NET interop, the packet protocol. He's now part of a real open-source game project — not a toy.

**Requirements revealed:** Build-from-source on Linux, good documentation, CI that validates contributions, clear contribution guidelines, modular architecture that's approachable.

### Journey Requirements Summary

| Journey | Key Capabilities Required |
|---------|--------------------------|
| **Paco: Developer-Player** | Cross-platform build, SDL3 migration, .NET AOT on all platforms, build docs, error diagnostics |
| **Paco: Server Host** | OpenMU compatibility docs, connection config, clear error messages on connection failure |
| **Marco: Nostalgic Veteran** | Downloadable binaries, server connection UX, gameplay parity, stability |
| **Sven: OSS Contributor** | Linux build, documentation, CI pipeline, contribution guidelines, modular architecture |

**MVP-critical journeys:** Paco Developer-Player and Paco Server Host. The other two are post-MVP and will emerge organically if the platform is solid.

## Desktop Application Requirements

### Platform Support Matrix

| Platform | Build Toolchain | Rendering Backend | .NET AOT | Status |
|----------|----------------|-------------------|----------|--------|
| **Windows** | MSVC (x86 + x64) | Direct3D via SDL_gpu | `.dll` | Working (current state) |
| **macOS** | Clang/CMake | Metal via SDL_gpu | `.dylib` | MVP target |
| **Linux** | GCC/CMake + MinGW cross-compile (CI) | Vulkan via SDL_gpu | `.so` | MVP target |

### Rendering Architecture

The existing codebase uses OpenGL 1.x immediate mode (111 `glBegin` call sites across 14 files). The SDL3 migration (Phases 0–2) replaces this with SDL_gpu, which abstracts per-platform rendering backends:
- **macOS:** Metal (OpenGL deprecated by Apple since macOS 10.14)
- **Linux:** Vulkan (with OpenGL fallback possible)
- **Windows:** Direct3D 11/12 (with Vulkan option)

This is critical path for cross-platform — without SDL_gpu, macOS rendering would depend on Apple's deprecated and increasingly broken OpenGL support.

### System Integration

- **Server connectivity:** .NET Native AOT library loaded at runtime via platform-specific dynamic library (`.dll`/`.dylib`/`.so`). Function pointer binding from C++ through `Dotnet/Connection.h`.
- **File system:** Game assets loaded from relative paths using `std::filesystem::path`. Forward slashes only, no platform-specific path separators.
- **Audio:** Currently DirectSound/wzAudio (Windows-only). MVP includes miniaudio migration for cross-platform audio on all three platforms.

### Distribution Strategy

**MVP (build from source):**
- Clone, build, run. No installer needed. Paco is the user.
- Build documentation per platform is the distribution mechanism.

**Post-MVP (if community forms):**
- **macOS:** DMG or `.app` bundle. Will require code signing and notarization for Gatekeeper. HiDPI/Retina display scaling to be addressed.
- **Linux:** AppImage or Flatpak for distro-agnostic distribution.
- **Windows:** Installer or portable `.zip`.

### Offline Capability

Not applicable. MuMain is an MMO client — gameplay requires an active connection to an OpenMU server. There is no offline mode and none is planned.

### Auto-Update

Not in scope. MVP is build-from-source. Post-MVP packaging may include update mechanisms, but this is a future concern.

## Product Scope & Phased Development

### MVP — Minimum Viable Product

**Definition:** Paco can play MU Online on his Mac by connecting to an OpenMU server — no patching, no Wine, no workarounds.

**MVP Approach:** Experience MVP — prove the core experience works for the primary user (Paco) on macOS. Success is binary: either MuMain runs on Mac with full gameplay and audio, connecting to OpenMU, or it doesn't.

**Resource Model:** Solo developer + AI agents. No team staffing constraints, no external deadlines. The limiting factor is technical complexity, not resources or time pressure.

**MVP is done when:** Paco launches MuMain on his Mac, connects to OpenMU, plays for an hour with audio, and logs out voluntarily.

**Core User Journeys Supported:**
- Paco: Developer-Player (build from source, play on Mac)
- Paco: Server Host (run OpenMU locally, connect MuMain)

**Must-Have Capabilities:**

| Capability | Rationale | Done When |
|-----------|-----------|-----------|
| SDL3 migration (Phases 0–2) | Without this, no macOS/Linux windowing, input, or rendering | SDL_gpu rendering on all 3 platforms |
| .NET Native AOT cross-platform | Without this, no server connectivity on macOS/Linux | ClientLibrary loads and connects on all 3 platforms |
| Audio migration (miniaudio) | Audio is integral to the MU Online experience — no sound means not really playing | Background music + sound effects working on all 3 platforms |
| Full gameplay parity | The goal is to *play MU Online*, not a demo | All 84 UI windows, combat, inventory, trading, guilds, PvP, world exploration functional |
| Stability (60+ min sessions) | Crashes make it unusable | Hour-long session without crash on macOS |
| Showstopper bug fixes | Legacy bugs that break core loops must be fixed | No crashes, no data loss, no broken core gameplay |
| Build documentation | Can't build = can't play | Documented build steps for Win/Mac/Linux |
| CI quality gates | Prevents regressions | MinGW + clang-format + cppcheck passing |

**Note on legacy bugs:** The current codebase may contain undiscovered bugs unrelated to cross-platform migration. These will surface during testing and gameplay. Not all need fixing for MVP, but showstoppers (crashes, data loss, broken core loops) do.

**Explicitly Not MVP:**
- Pre-built binaries/installers (build from source is fine)
- Non-showstopper bug fixes (triage, fix later)
- Community features (contribution guidelines, onboarding)
- Any form of distribution packaging
- Font rendering migration (FreeType) — can use platform fallbacks initially

### Growth Features (Phase 2)

Experiments that become possible once the platform works:

1. Bug fixing sprint — systematic triage of non-showstopper issues
2. Telemetry integration — runtime behavior and performance instrumentation
3. Font rendering (FreeType) — cross-platform text replacing GDI
4. Config & system utilities — cross-platform file handling, HTTP, encryption
5. CI/CD packaging — AppImage, DMG, installer

### Vision (Phase 3+)

Experiments that become interesting once the platform is mature and learnings accumulate:

1. Community distribution — trivial download-and-connect experience
2. SSO / character portability — player identity across servers
3. Ethical monetization framework — "pay to enjoy" models
4. Mobile/tablet client — SDL3 touch input, responsive UI
5. Original IP exploration — new game built on accumulated expertise

### Risk Mitigation Strategy

**Technical Risks:**

| Risk | Impact | Mitigation |
|------|--------|------------|
| SDL_gpu migration scope (111 glBegin sites, 14 files) | Highest-volume code change in MVP | Existing 10-phase migration plan with ground truth capture for visual regression testing |
| .NET AOT on macOS/Linux (untested) | No server connectivity = no game | Isolated, well-scoped: CMake RID detection + library extension + `char16_t` fix. Can be validated early |
| miniaudio migration | No audio = degraded experience | DirectSound/wzAudio replacement is well-documented; miniaudio is a mature, battle-tested library |
| Undiscovered legacy bugs | Unknown scope of breakage | Triage discipline: only showstoppers block MVP. Non-critical bugs go to Phase 2 backlog |
| OpenMU server compatibility | Protocol mismatch = connection failure | Document compatible OpenMU version. Test handshake early in development |
| Apple deprecating OpenGL further | Rendering breaks on future macOS | SDL_gpu with Metal backend eliminates OpenGL dependency entirely |

**Market Risks:** None. Primary user is the developer. No market validation needed for MVP.

**Resource Risks:** Solo developer — no bus factor mitigation needed for personal project. AI agents reduce implementation burden. No deadline pressure allows methodical execution.

## Functional Requirements

### Platform & Build

- **FR1:** Developer can build MuMain from source on macOS using CMake and standard toolchain
- **FR2:** Developer can build MuMain from source on Linux using CMake and standard toolchain
- **FR3:** Developer can build MuMain from source on Windows using MSVC presets (existing capability, must not regress)
- **FR4:** Developer can follow documented build instructions per platform to go from clone to running binary in under 30 minutes
- **FR5:** Developer can push changes knowing CI validates every commit against cross-platform quality gates (build, formatting, static analysis)

### Server Connectivity

- **FR6:** Player can connect to an OpenMU server from macOS
- **FR7:** Player can connect to an OpenMU server from Linux
- **FR8:** Player can connect to an OpenMU server from Windows (existing capability, must not regress)
- **FR9:** Player can connect to servers from any platform via the .NET Native AOT network library loading and initializing on all three platforms (`.dll`/`.dylib`/`.so`)
- **FR10:** Player receives error messages that identify the failure type (unreachable, protocol mismatch, authentication failure) and suggest corrective action when server connection fails
- **FR11:** Player can configure server connection target (address and port)

### Rendering & Display

- **FR12:** Player can see the game world rendered via SDL_gpu on macOS (Metal backend)
- **FR13:** Player can see the game world rendered via SDL_gpu on Linux (Vulkan backend)
- **FR14:** Player can see the game world rendered via SDL_gpu on Windows (Direct3D backend)
- **FR15:** Player can see all visual elements (terrain, models, effects, UI) rendered with parity to the Windows OpenGL baseline, validated through ground truth screenshot comparison
- **FR16:** Player can interact with the game window (resize, minimize, focus) using SDL3 windowing on all platforms

### Audio

- **FR17:** Player hears background music on all three platforms via miniaudio
- **FR18:** Player hears sound effects (combat, UI interactions, environment) on all three platforms via miniaudio
- **FR19:** Player can hear all existing game audio assets (WAV, OGG, MP3 formats) on all three platforms

### Input

- **FR20:** Player can control their character using keyboard input on all three platforms via SDL3
- **FR21:** Player can interact with UI elements using mouse input on all three platforms via SDL3
- **FR22:** Player can type in chat and text fields using SDL3 text input on all three platforms

### Gameplay Systems

- **FR23:** Player can authenticate and log in to an OpenMU server
- **FR24:** Player can create, select, and manage characters
- **FR25:** Player can navigate the game world across all 82 maps
- **FR26:** Player can engage in combat (melee, ranged, skills) with monsters and other players
- **FR27:** Player can manage inventory (equip, unequip, move, drop items across 120 slots)
- **FR28:** Player can trade items with other players
- **FR29:** Player can join and manage guilds
- **FR30:** Player can participate in party gameplay
- **FR31:** Player can use the quest system
- **FR32:** Player can manage pets and companions
- **FR33:** Player can use NPC shops and services
- **FR34:** Player can participate in PvP (duels, guild wars, castle siege)
- **FR35:** Player can use all 84 UI windows (inventory, character info, skills, map, chat, etc.)
- **FR36:** Player can chat with other players (normal, party, guild, whisper channels)

### Stability & Error Handling

- **FR37:** Player can play a 60+ minute session on macOS without crashes or disconnects
- **FR38:** Player can play a 60+ minute session on Linux without crashes or disconnects
- **FR39:** Developer can diagnose platform-specific issues using diagnostic logs written to `MuError.log` on all platforms
- **FR40:** Player can play without encountering bugs that crash the client, corrupt player data, or prevent core gameplay (combat, inventory, trading, navigation)

*Note: FRs 23–36 represent existing gameplay functionality that must continue working after the cross-platform migration — they are regression requirements, not new features.*

## Non-Functional Requirements

### Performance

- **NFR1:** Game renders at 30+ FPS sustained on macOS and Linux with equivalent hardware to the Windows baseline (target: 60 FPS on modern hardware), as measured by built-in frame time instrumentation
- **NFR2:** Input latency (keyboard/mouse to visible response) adds no more than 5ms over the existing Windows client behavior, as measured by input-to-frame timing instrumentation
- **NFR3:** No frame hitches (>50ms frame time) or stuttering during 60+ minute gameplay sessions including world traversal, combat, and UI interaction, as measured by frame time variance logging

### Security

- **NFR4:** All network packet data from the server is validated before use — never trust external data
- **NFR5:** No `assert()` on network, file, or user input data — validation uses explicit error handling
- **NFR6:** Packet encryption (SimpleModulus + XOR3) functions correctly on all platforms
- **NFR7:** No credentials stored in plaintext on disk

### Integration

- **NFR8:** Client maintains protocol compatibility with the current stable release of OpenMU
- **NFR9:** .NET Native AOT interop boundary handles data marshaling correctly on all platforms (string encoding, byte buffers, function pointer binding)
- **NFR10:** Compatible OpenMU version is documented and tested as part of the build/release process

### Portability

- **NFR11:** Zero platform-specific code (`#ifdef _WIN32`) in game logic — all platform differences isolated to abstraction headers (`PlatformCompat.h`, `PlatformTypes.h`)
- **NFR12:** File paths use forward slashes and `std::filesystem::path` — no backslash literals
- **NFR13:** New serialization code uses `char` + UTF-8, not `wchar_t`
- **NFR14:** All three platform builds produced from a single codebase and CMake build system with no platform-specific forks

### Maintainability

- **NFR15:** All code changes pass CI quality gates for formatting consistency, static analysis, and correctness (specific tools and configurations defined in development-standards.md)
- **NFR16:** New code follows modern C++ memory safety and error handling conventions as defined in project-context.md — no manual memory management, no null pointer ambiguity
- **NFR17:** All commits use structured messages enabling automated versioning and changelog generation
- **NFR18:** Diagnostic logging for post-mortem debugging is available on all three platforms, writing to a persistent log file

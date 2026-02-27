---
stepsCompleted: [1, 2, 3, 4, 5, 6]
status: complete
inputDocuments:
  - docs/CROSS_PLATFORM_PLAN.md
  - docs/project-overview.md
  - docs/CROSS_PLATFORM_DECISIONS.md
  - docs/architecture-mumain.md
  - docs/modular-reorganization.md
  - docs/feature-impact-maps.md
date: 2026-02-26
author: Paco
---

# Product Brief: MuMain-workspace

## Executive Summary

MuMain is an open-source, cross-platform game client for MU Online — a nostalgic MMORPG with a passionate global community trapped between predatory monetization from official publishers and legally questionable private servers running patched clients. Built by the same ecosystem behind OpenMU (the leading open-source MU server), MuMain provides the missing piece: a clean, legal, community-owned client that works natively on Windows, macOS, Linux — with a path to tablets and mobile devices.

The project's immediate goal is delivering a fully functional OSS client-server stack that empowers anyone to host and play MU Online on their own terms. The long-term vision is bolder: an interoperable community where players own their character data — able to transfer between servers, back up their progress, and choose their experience without lock-in. This positions MuMain not just as a client, but as the foundation for an ethical, player-first evolution of the MU Online experience — and potentially, a spiritual successor free of original IP constraints.

---

## Core Vision

### Problem Statement

MU Online players face a lose-lose choice: pay thousands of dollars on official servers where "pay-to-win" mechanics destroy the core gameplay loop, or join private servers running patched clients of dubious legality that often replicate the same predatory monetization at a smaller scale. There is no official open-source client-server combination that gives communities genuine control over their game experience.

### Problem Impact

- **Players** are forced into ecosystems that exploit nostalgia through aggressive microtransactions, selling power that undermines the game's core appeal — the journey to becoming "untouchable" through time and skill investment
- **Community hosts** must distribute legally gray patched clients (watered-down versions of the Korean original) with no ability to offer a clean, native, cross-platform experience
- **The broader community** fragments across incompatible private servers with no character portability — when a server dies or turns toxic, players lose everything they've invested
- **Mobile players** face the worst of it, with aggressive monetization targeting a growing but underserved segment

### Why Existing Solutions Fall Short

- **Webzen (official):** Has refined monetization mechanics well, but pushed them to extremes — rewards that would take centuries to earn in-game can be purchased instantly, destroying game balance and the sense of achievement
- **Private servers:** Rely on patched Korean clients (legally questionable), often replicate predatory monetization at smaller scale, and offer no interoperability or character portability
- **Past OSS attempts:** Source releases and scattered repos have existed but never gained traction due to lack of sustained development and community backing
- **Spinoffs (e.g., Lemuria Origin):** Attempted to create something new from the MU formula but failed to attract and retain players

### Proposed Solution

An open-source, cross-platform MuMain client paired with OpenMU servers that provides:

1. **Clean legal client** — No patched binaries, no reverse engineering; a native application built for Windows, macOS, and Linux with a path to mobile/tablet
2. **Ethical "pay to enjoy" monetization** — Everything earnable for free; paying accelerates progress (10x, not 1000x) without breaking game balance. The journey remains the reward
3. **Character portability and interoperability** — A centralized player data service (SSO-like) that hosts verified character data, enabling transfers between servers, progress backups, and solo-to-multiplayer transitions — all while preventing duplication and abuse. Players own their journey; servers compete for their presence
4. **Community empowerment** — Anyone can host a server, build a community, and offer a complete experience without legal gray areas or dependency on patched binaries
5. **Foundation for evolution** — Starting with the beloved MU formula, learning what truly attracts and retains players, with the potential to evolve into an original IP free of legacy constraints

### Key Differentiators

- **Ecosystem credibility:** Same author ecosystem as OpenMU — the leading open-source MU server — ensuring native client-server compatibility without reverse engineering
- **Player sovereignty with trust infrastructure:** Character data belongs to the player via a centralized SSO/identity service that hosts player data — preventing abuse (duplication, tampering) while enabling portability across any participating server. Think of it as a passport system: your identity is verified centrally, but where you travel is your choice
- **Ethical monetization philosophy:** "Pay to enjoy, not pay to win" — a direct counter to the predatory models that plague both official and private servers
- **Cross-platform from the ground up:** A 10-phase SDL3 migration delivering native performance on PC, Mac, Linux, with mobile as a realistic stretch goal
- **Open source transparency:** Community-auditable code, no hidden mechanics, no exploitative dark patterns

## Target Users

### Primary Users

**"Marco" — The Nostalgic Veteran**
- 30s, played MU Online as a teenager in the early 2000s
- Tried returning to official servers but was repelled by pay-to-win escalation where competing requires heavy spending
- Tried private servers but lost everything when the server died
- Dreams of building a character through time and skill, earning respect, becoming untouchable — not through a credit card
- Wants to play on Mac/Linux without maintaining a Windows machine for one game
- **Core need:** A fair, nostalgic MU experience on any platform where investment (time) is respected

### Secondary Users

**"Diana" — The Community Host**
- Runs a small gaming community (50-200 people), wants to host an MU server
- Current path requires distributing legally questionable patched clients
- Wants a clean "download and connect" experience she can confidently share
- Cares about fairness — ethical monetization (cosmetics, accelerators) to cover hosting costs
- **Core need:** A legitimate, easy-to-distribute client paired with a configurable server

**"Luis" — The Mobile Gamer (Future Phase)**
- Plays MU-like games on phone during commute and breaks
- Has spent money on mobile MU clones but always feels exploited by progression walls
- Wants the same character on mobile and PC
- **Core need:** A mobile MU experience that respects his time and wallet, with cross-device progression

**"Sven" — The OSS Developer**
- Contributes to open-source game projects, interested in the OpenMU ecosystem
- Wants clean architecture, good documentation, welcoming contribution process
- Motivated by building something the community actually uses
- **Core need:** A well-architected, documented OSS project worth investing time in

### User Journeys

**Marco (Primary):**
Discovery → Downloads native client (no patching) → Connects to community server in minutes → Grinds, PvPs, builds guild life on Mac/Linux → Realizes he can back up and transfer his character between servers → Becomes a community fixture, potentially hosts his own server

**Diana (Secondary):**
Finds MuMain via OpenMU ecosystem → Spins up server, shares clean download link → Manages balanced monetization, builds healthy community → Players are happy, hosting costs covered ethically → Server becomes a destination attracting players from dying servers

**Luis (Future Phase):**
Finds MuMain in app store → Logs in with SSO, same character as PC → Quick mobile sessions, longer PC sessions, seamless progression → Realizes he's not being squeezed for money → Becomes an evangelist for ethical mobile gaming

**Sven (Secondary):**
Finds repo through OpenMU/GitHub → Builds on Linux/macOS, reads docs, submits first PR → Contributes features, participates in architecture decisions → Sees code running in a real game players enjoy → Becomes core maintainer, shapes evolution toward original IP

## Success Metrics

### User Success Metrics

- **Return rate:** Players who leave and come back within 30/90 days — the "home" metric. For a nostalgia-driven game, this matters more than daily active users
- **Session quality:** Average session length and voluntary logout (vs. rage-quit or disconnect) — are players enjoying their time?
- **Character progression:** Players reaching meaningful milestones (level thresholds, gear tiers) through gameplay, not purchases
- **Server switching/transfers:** Players using the portability feature — indicates trust in the ecosystem and healthy server competition
- **Cross-platform usage:** Players who play on multiple platforms (PC + mobile) — validates the cross-platform investment

### Business Objectives

**Phase 1 (0-12 months) — Build the Foundation:**
- Functional cross-platform client (Windows + Linux + macOS)
- Active community servers running OpenMU + MuMain
- Growing GitHub engagement (stars, forks, contributors, PRs)

**Phase 2 (12-24 months) — Grow the Community:**
- Measurable player base across ecosystem (active players per month)
- New features shipping regularly driven by community feedback
- Server host ecosystem growing organically

**Phase 3 (24+ months) — Sustain and Evolve:**
- Ethical monetization generating revenue to sustain development
- Community size and activity supporting consideration of original IP spinoff
- Mobile/tablet client driving new audience growth

### Key Performance Indicators

| KPI | Metric | Phase |
|---|---|---|
| GitHub Stars | Growth trend (not absolute number) | 1 |
| Active Contributors | PRs merged per month | 1 |
| Active Community Servers | Servers with 10+ active players | 1-2 |
| Monthly Active Players | Unique logins across ecosystem | 2 |
| Return Rate | % of players returning after 30+ day absence | 2 |
| Feature Velocity | New features/improvements shipped per quarter | 1-2 |
| Cross-Platform Adoption | % of players on non-Windows platforms | 2 |
| Revenue (when applicable) | Monthly revenue vs. hosting/development costs | 3 |
| Community Sentiment | Qualitative — forum/Discord health, toxicity levels | 1-2-3 |

## MVP Scope

### Core Features

**MVP Definition: Stable cross-platform MuMain client on Windows, macOS, and Linux connected to OpenMU**

1. **Cross-platform client** — Complete the SDL3 migration (Phases 0-2 minimum) to deliver native builds on Windows, macOS, and Linux
2. **OpenMU compatibility** — Stable, reliable connection to OpenMU servers with full gameplay functionality
3. **Gameplay parity** — All existing game features working correctly across platforms (combat, inventory, trading, guilds, PvP, world exploration)
4. **Stability and polish** — Address unknown gaps and bugs that early adopters haven't surfaced yet due to limited testing; establish a baseline of quality that power users can trust
5. **Easy distribution** — Clean downloadable binaries for all three platforms — no patching, no workarounds, no legal gray areas
6. **Quality gates** — CI pipeline validating builds across platforms, static analysis, and format checks on every change

### Out of Scope for MVP

- **Mobile/tablet clients** — Future phase, dependent on stable desktop foundation
- **SSO/player data portability** — Visionary feature deferred until community ecosystem exists to use it
- **Ethical monetization system** — No revenue model needed yet; community and stability first
- **Original IP / custom assets** — Requires understanding what attracts players first, which requires an active player base
- **Audio migration (miniaudio)** — Phase 3 of migration plan; can ship with existing audio on Windows, platform-appropriate fallback on Linux/macOS
- **ImGui editor cross-platform** — Phase 7; developer tooling, not player-facing
- **.NET AOT cross-platform** — Phase 8; may require Windows for server connectivity initially, with cross-platform interop as a follow-up
- **Advanced rendering (SDL_gpu)** — Phase 2 is in MVP scope but full shader pipeline optimization is not

### MVP Success Criteria

- **Builds and runs natively** on Windows, macOS, and Linux from a single codebase
- **Connects to OpenMU** and delivers stable gameplay sessions without crashes or disconnects
- **Early adopters confirm** core gameplay loop works: login → character select → world → combat → inventory → trading → logout
- **Community servers emerge** — at least a handful of hosts distributing MuMain to their players
- **Contributors onboard** — developers can clone, build, and contribute on any of the three platforms
- **No known showstoppers** — power users can play extended sessions without data loss or critical bugs

### Future Vision

**Post-MVP Roadmap (in priority order):**

1. **Audio migration (miniaudio)** — Full cross-platform audio replacing DirectSound/wzAudio
2. **Font rendering (FreeType)** — Cross-platform text replacing GDI
3. **Config, encryption & system utilities** — Cross-platform file handling, HTTP, config
4. **Text input & IME** — SDL3 text events for international input
5. **ImGui editor cross-platform** — Developer tooling on all platforms
6. **.NET AOT cross-platform** — `dlopen` on Linux/macOS for full server connectivity
7. **CI/CD & packaging** — AppImage (Linux), DMG (macOS), installer (Windows)
8. **SSO / player data portability** — The passport system for character sovereignty
9. **Ethical monetization framework** — "Pay to enjoy" accelerators and cosmetics
10. **Mobile/tablet client** — SDL3 touch input, responsive UI scaling
11. **Original IP exploration** — When community insights reveal what truly retains players

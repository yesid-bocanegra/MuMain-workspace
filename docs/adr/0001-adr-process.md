# ADR-0001: Adopt ADR Process

- **Status:** Accepted
- **Date:** 2026-02-25
- **Authors:** MuMain team

## Context

The MuMain project is undergoing a 10-phase cross-platform migration from Win32/DirectX to SDL3/SDL_gpu/miniaudio. This involves hundreds of architectural decisions across windowing, rendering, input, audio, networking, and build systems.

Architectural decisions have been documented implicitly in `CROSS_PLATFORM_DECISIONS.md` and scattered across development docs, but there is no structured process for recording individual decisions with their context and alternatives.

## Decision

Adopt a lightweight Architecture Decision Record (ADR) process:

- Each significant architectural decision gets a numbered ADR in `docs/adr/`
- ADRs follow a standard template capturing context, decision, consequences, and alternatives
- ADRs are immutable once accepted — superseded decisions link to their replacement
- ADRs are submitted as part of the PR implementing the decision

**Scope:** ADRs are for architecturally significant decisions — things that affect multiple modules, introduce new dependencies, or establish patterns used across the codebase. Routine implementation choices do not need ADRs.

## Consequences

### Positive

- Decisions and their rationale are discoverable by future contributors
- Forces explicit consideration of alternatives and tradeoffs
- Creates a historical record for the cross-platform migration

### Negative

- Small overhead per decision (writing the ADR)
- Risk of over-documentation if scope is not maintained

### Neutral

- Existing decisions in `CROSS_PLATFORM_DECISIONS.md` remain valid — no need to retroactively create ADRs for them

## Alternatives Considered

### Alternative 1: Continue with Informal Documentation

Keep documenting decisions in existing markdown files. Rejected because decisions are hard to find and lack structured context/alternatives analysis.

### Alternative 2: Full RFC Process

Formal request-for-comments with review periods. Rejected as too heavyweight for the current team size.

## References

- [Michael Nygard's ADR article](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- `docs/CROSS_PLATFORM_DECISIONS.md` — existing informal decision log

# Decision: Git Operation Policy for CloneWatch

Date: 2026-04-14

## Context

CloneWatch development is being run with active assistant collaboration. The workspace now has functional SSH auth for GitHub pushes.

## Decision

Adopt a default assistant Git flow:

1. implement agreed change
2. run relevant checks
3. update memory artifacts when applicable
4. commit with clear message
5. push to `origin` automatically

Unless the user explicitly requests no push.

## Safety boundaries

- Pause for confirmation before push when risk is non-obvious:
  - destructive storage behavior
  - unresolved CI/test failures
  - broad refactors with unclear blast radius
- Keep commit scope intentional and readable.
- Keep memory discipline enforced (`clonewatch.md` and/or `docs/project-memory.md` updates when required).

## Rationale

This policy reduces user friction, improves delivery velocity, and keeps repository state synchronized without requiring repetitive manual push steps.

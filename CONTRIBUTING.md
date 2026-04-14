# Contributing to CloneWatch

Thanks for helping with CloneWatch.

## Core workflow

1. Create a branch from `main`
2. Make a focused change
3. Run:

```bash
swift build
swift test
```

4. If the PDF transcript pipeline changed, also run:

```bash
swift run CloneWatchDocsTool
```

5. Commit with a clear message
6. Open a Pull Request

## Branch naming

- `feature/...` for new capabilities
- `fix/...` for bug fixes
- `docs/...` for documentation-only work

## Rules

- Do not add destructive disk behavior without explicit safety checks
- Keep macOS permission realities documented
- Treat iCloud and File Provider paths as special cases
- Update docs when architecture or behavior changes

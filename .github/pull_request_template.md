## Summary

- What changed?
- Why does it matter?

## Checks

- [ ] `swift build`
- [ ] `swift test`
- [ ] If chat-history inputs changed, `swift run CloneWatchDocsTool`
- [ ] Documentation updated when behavior changed

## Risk Review

- [ ] No destructive storage behavior was added without new safety gates
- [ ] Permissions / macOS constraints were considered
- [ ] iCloud / File Provider implications were considered when relevant

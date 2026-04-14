# CloneWatch v2 Architecture

## Product Shape

CloneWatch is no longer just a clone verifier. It is a macOS-first migration platform with five pillars:

1. Clone
2. Verify
3. Document
4. Migrate
5. DiskOps

## macOS Architecture

The app is split conceptually into these layers:

- `SwiftUI app`: guides the user, explains risk, and renders evidence.
- `Core engines`: preflight, inventory, copy, verification, ledger, transcript reconstruction.
- `Permission coordinator`: decides what the app can ask for directly and what must be guided manually.
- `Privileged helper`:
  Future component for mount/unmount, delete volume, repartition, and other administrator-only operations.

The GUI itself should not run as root. Instead:

- normal file operations run as the user when possible
- user-selected file access is requested through native panels
- privileged storage operations are delegated to a narrow helper
- Full Disk Access is detected and explained, not silently granted

## Platform Realities

### Full Disk Access

macOS does not let an app auto-grant Full Disk Access to itself. CloneWatch must:

- detect when a path likely needs it
- explain why
- block or downgrade risky workflows until the user grants it manually

### System Integrity Protection

Root is not the same as unlimited power on modern macOS. CloneWatch should not assume it can safely mutate sealed system areas, even when privileged.

### iCloud / File Provider

iCloud-backed paths require special handling because:

- files may be placeholders
- sync may still be in progress
- shared folders may change while the clone runs

CloneWatch should mark these paths as higher-risk and treat hydration/stability as part of preflight.

## Destructive Operations Model

Disk Utility-like powers belong in a separate capability band:

- `Read-only topology`
- `Safe operations`
- `Destructive operations`

Destructive actions such as deleting a cloned volume, resizing containers, or repartitioning a device must require:

- topology discovery
- disk identity checks
- explicit confirmation boundaries
- durable audit logging
- a rollback-aware plan where possible

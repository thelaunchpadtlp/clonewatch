# CloneWatch Project Memory

## Current Direction

CloneWatch v2 is evolving from a Python comparison script into a native macOS platform for cloning, reinforcement, verification, storage migration, disk-topology awareness, and documentary evidence.

## Major Requirements Captured So Far

- support folder-to-folder, folder-to-volume, volume-to-folder, and volume-to-volume workflows
- generate durable audit bundles in central storage and mirror them into source and destination
- preserve the original ChatGPT project history by copying PDFs, extracting them, and reconstructing a canonical transcript
- support efficient reinforcement of an existing clone by transferring only changed files
- keep web-readable reports so evidence can be opened from another device
- become storage-topology aware, closer in spirit to Disk Utility plus migration safety

## New Platform Constraints

- the app should ask for what it can ask for directly, especially file-system access through native pickers
- Full Disk Access cannot be silently granted by the app and must be explained/guided
- future destructive operations must go through a privileged helper rather than running the full GUI as root
- iCloud Drive and shared iCloud folders need special risk handling because hydration and sync state can break strict clone assumptions
- using `/` directly as a clone root is too dangerous and should be blocked or heavily constrained

## Strategic Direction

CloneWatch should become a storage migration orchestrator with five power bands:

1. clone
2. verify
3. document
4. migrate
5. DiskOps

DiskOps should itself be split into:

- read-only topology inspection
- safe operations
- destructive operations

## Evidence Philosophy

Every important operation should leave behind enough evidence to answer:

- what existed before
- what was copied
- what changed
- what risks were known
- what permissions were needed
- whether the source can be archived or deleted safely

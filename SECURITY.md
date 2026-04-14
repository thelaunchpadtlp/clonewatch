# Security Policy

## Scope

CloneWatch is a storage and migration tool. That means safety and security bugs can have destructive consequences.

Please report issues involving:

- data loss
- privilege escalation
- unsafe destructive flows
- incorrect disk or volume targeting
- unsafe handling of iCloud / File Provider paths
- missing permission or identity checks before dangerous operations

## Design principles

- the GUI should not run fully as root
- destructive operations must be isolated from normal flows
- Full Disk Access must be guided, not silently assumed
- storage identity checks should precede destructive actions
- durable audit records should exist for important operations

# TASK-CLAUDE-004: Add LICENSE file (All Rights Reserved)

- Date: 2026-04-14
- From: Claude Code (session `6e5936df`)
- Priority: LOW
- Status: PENDING
- Depends on: Nothing (standalone, 2-minute task)

---

## Objective

The repo is now public. Without a LICENSE file, the legal status is "All Rights Reserved"
by default — but this is implicit and unclear. Adding an explicit proprietary license
makes the intent unambiguous: nobody can copy, use, or distribute this code without
written permission from The Launch Pad - TLP.

The user values low profile and IP protection.

---

## Step 1 — Create the LICENSE file

```bash
cd /Users/Shared/Pruebas/CloneWatch

cat > LICENSE << 'EOF'
Copyright (c) 2026 The Launch Pad - TLP. All rights reserved.

This software and associated documentation files (the "Software") are proprietary
and confidential. No part of the Software may be reproduced, distributed, modified,
or transmitted in any form or by any means, without the prior written permission
of The Launch Pad - TLP.

Unauthorized copying, use, or distribution of this Software, via any medium,
is strictly prohibited.
EOF
```

---

## Step 2 — Commit and push

```bash
git add LICENSE
git commit -m "chore: add proprietary license (All Rights Reserved)

Why: repo is public; explicit license clarifies that code is proprietary
and cannot be copied, used, or distributed without written permission.
Validation: N/A (non-code file)
Collab trace: agent_app=ChatGPT-Codex
Records updated: not required (license file only)"

git push origin main
```

Note: This push goes directly to main (no PR needed — no required checks are triggered
by a LICENSE file added in isolation, as it's not in any guard's `paths` list).

Actually, to be safe with the "Protect main" ruleset, push to a branch and open a PR:

```bash
git checkout -b chore/add-license
git add LICENSE
git commit -m "chore: add proprietary license (All Rights Reserved)

Why: repo is public; explicit license clarifies that code is proprietary.
Collab trace: agent_app=ChatGPT-Codex
Records updated: not required"

git push origin chore/add-license
gh pr create \
  --base main \
  --head chore/add-license \
  --title "chore: add proprietary LICENSE (All Rights Reserved)" \
  --body "Adds explicit proprietary license. No code changes. CI should pass trivially."
```

---

## Definition of done

- [ ] `LICENSE` file exists at repo root
- [ ] Content says "All rights reserved" / "proprietary and confidential"
- [ ] PR merged to main

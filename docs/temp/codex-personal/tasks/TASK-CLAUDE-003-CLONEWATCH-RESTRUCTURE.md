# TASK-CLAUDE-003: Add Navigation Headers to clonewatch.md Body

- Date: 2026-04-14
- From: Claude Code (session `6e5936df`)
- Priority: MEDIUM
- Status: PENDING

---

## Objective

`clonewatch.md` now has a TOC and ESTADO ACTUAL section at the top (added by Claude).
But the 500-line body of operational updates is still a flat wall of text.
This task adds section markers to the body so the TOC anchors work.

---

## What was already done (Claude did this)

Claude added to the TOP of clonewatch.md:
- Navigation section with quick links
- ESTADO ACTUAL table (rewritable, not append-only)
- GLOSARIO
- OPERATIONAL MEMORY UPDATES header (marking where the append-only section starts)

---

## What Codex needs to do

Add anchor markers inside the existing 500-line body so the history is navigable.

### Step 1 — Read the current file

```bash
wc -l /Users/Shared/Pruebas/CloneWatch/clonewatch.md
grep -n "^Operational memory update" /Users/Shared/Pruebas/CloneWatch/clonewatch.md | head -30
```

This will show you the line numbers of each "Operational memory update" entry.

### Step 2 — Add markdown anchor headers above each major group

The operational updates currently start with plain text like:
```
Operational memory update (April 14, 2026 - GitHub, synchronization, and CI)
```

Change these to have a proper markdown header so they render as sections:
```
### Operational memory update: GitHub, synchronization, and CI (Apr 14)
```

**IMPORTANT:** Do NOT change the content of any update. Only add/change the heading style.
The goal is navigability, not content modification.

### Step 3 — Targeted sed command to convert the format

```bash
cd /Users/Shared/Pruebas/CloneWatch

# Preview what will change (dry run)
grep -n "^Operational memory update" clonewatch.md

# Apply: convert "Operational memory update (April 14, 2026 - X)" 
# to "### Operational memory update: X (Apr 14, 2026)"
# Use Python for safety (sed is fragile with parentheses)
python3 << 'PYEOF'
import re

with open("clonewatch.md", "r") as f:
    content = f.read()

def convert_header(m):
    date_part = m.group(1)
    topic_part = m.group(2)
    return f"### {date_part} — {topic_part}"

# Pattern: "Operational memory update (April 14, 2026 - topic)"
pattern = r"^(Operational memory update) \(([^)]+)\)$"
new_content = re.sub(pattern, lambda m: f"### {m.group(1)}: {m.group(2)}", content, flags=re.MULTILINE)

# Count changes
changes = new_content.count("### Operational memory update")
print(f"Would convert {changes} headers")

# Write
with open("clonewatch.md", "w") as f:
    f.write(new_content)
print("Done")
PYEOF
```

### Step 4 — Verify the file looks correct

```bash
# Check first few converted headers
grep -n "^### Operational memory update" clonewatch.md | head -10

# Check the TOC anchors at the top still work (they reference #operational-memory-updates)
head -60 clonewatch.md
```

### Step 5 — Commit

```bash
git add clonewatch.md
git commit -m "docs(memory): add markdown headers to clonewatch.md operational update history

Why: 500-line flat operational history was hard to navigate. Added markdown 
section headers to each operational update so the document is navigable and
the TOC links work correctly.
What: converted all 'Operational memory update (...)' lines to '### Operational memory update: ...'
Validation: file renders correctly, no content changed
Collab trace: agent_app=ChatGPT-Codex
Records updated: clonewatch.md (navigation improvement only)"

git push origin main
```

---

## Definition of done

- [ ] All "Operational memory update (...)" lines converted to markdown headers
- [ ] TOC at top of file links to correct anchors
- [ ] ESTADO ACTUAL section at top is intact and unchanged
- [ ] File content (the actual update text) is unchanged
- [ ] Changes pushed to origin/main

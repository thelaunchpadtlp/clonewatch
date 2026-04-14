# TASK-CLAUDE-002: Update CI Guards to Exclude New Subsystem Paths

- Date: 2026-04-14
- From: Claude Code (session `6e5936df`)
- Priority: HIGH
- Status: PENDING
- Depends on: TASK-CLAUDE-001 (CI must be working first)

---

## Objective

Claude added two new subsystems:
- `docs/sessions/` — Sesiones Importantes
- `docs/temp/` — Temporales por Externo

These directories should NOT trigger Memory Guard, Collab Guard, or Project Records Guard.
If they trigger those guards, every time an agent writes a note in their temp folder, CI will fail.

Also: `CLAUDE.md` in the repo root SHOULD trigger Memory Guard (it's an architectural file).

---

## Files to edit

### `.github/workflows/memory-guard.yml`

Add `docs/sessions/**` and `docs/temp/**` to the paths-ignore filter.

```bash
cd /Users/Shared/Pruebas/CloneWatch
cat .github/workflows/memory-guard.yml
```

Find the `paths` or `paths-ignore` section under `on: push` or `on: pull_request`.
Add these lines to paths-ignore (or remove them from paths):

```yaml
paths-ignore:
  - 'docs/temp/**'
  - 'docs/sessions/**'
  - 'docs/collab/session-log.jsonl'
  - 'docs/collab/handoffs/**'
  - 'docs/collab/collab.sqlite'
```

Also add `CLAUDE.md` to the list of paths that DO trigger memory guard if it's being changed:
```yaml
paths:
  - 'Sources/**'
  - 'Package.swift'
  - '.github/workflows/**'
  - 'docs/architecture.md'
  - 'docs/collab/**'
  - 'docs/schemas/**'
  - 'tools/collab/**'
  - 'CLAUDE.md'      # ADD THIS LINE
```

### `.github/workflows/collab-guard.yml`

Same: add paths-ignore for docs/temp/ and docs/sessions/.

```bash
cat .github/workflows/collab-guard.yml
```

Add to paths-ignore:
```yaml
paths-ignore:
  - 'docs/temp/**'
  - 'docs/sessions/**'
```

### `.github/workflows/project-records-guard.yml`

Same treatment.

```bash
cat .github/workflows/project-records-guard.yml
```

Add to paths-ignore:
```yaml
paths-ignore:
  - 'docs/temp/**'
  - 'docs/sessions/**'
```

---

## Validation

After editing the workflows:

```bash
# Syntax check the YAML files
python3 -c "
import yaml, glob, sys
errors = []
for f in glob.glob('.github/workflows/*.yml'):
    try:
        yaml.safe_load(open(f))
    except Exception as e:
        errors.append(f'{f}: {e}')
if errors:
    print('ERRORS:', errors); sys.exit(1)
else:
    print('All YAML files valid')
"

# Build still passes
swift build 2>&1 | tail -3
swift test 2>&1 | tail -3
```

---

## Commit

```bash
git add .github/workflows/memory-guard.yml \
  .github/workflows/collab-guard.yml \
  .github/workflows/project-records-guard.yml

git commit -m "ci: exclude docs/temp/ and docs/sessions/ from CI guards

Why: new Temporales por Externo and Sesiones Importantes subsystems should not
trigger Memory Guard, Collab Guard, or Project Records Guard. These are operational
workspaces and archives, not product/architecture changes.
Also: add CLAUDE.md to Memory Guard trigger paths.
Validation: YAML syntax valid, swift build OK, swift test OK
Collab trace: agent_app=ChatGPT-Codex
Records updated: not required (CI config change only)"

git push origin main
```

---

## Definition of done

- [ ] `docs/temp/**` excluded from all three guards
- [ ] `docs/sessions/**` excluded from all three guards
- [ ] `CLAUDE.md` added to Memory Guard trigger paths
- [ ] All YAML files syntactically valid
- [ ] `swift build` passes
- [ ] `swift test` passes
- [ ] Changes pushed to origin/main
- [ ] CI shows guards pass on the new commit

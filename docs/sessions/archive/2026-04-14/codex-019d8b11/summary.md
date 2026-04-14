# Session Summary: ChatGPT Codex — 019d8b11

**Agent:** ChatGPT Codex (0.119.0-alpha.28)
**Format:** codex-jsonl-v1
**Date:** 2026-04-14
**Session ID:** `019d8b11-6cb8-7290-b66a-9015d83bdd23`
**Source app:** vscode
**Working directory:** `/Users/Shared/Pruebas/CloneWatch`
**Harvested:** 2026-04-14T23:09:01Z

## Source File

```
/Users/piqui/.codex/sessions/2026/04/14/rollout-2026-04-14T02-17-48-019d8b11-6cb8-7290-b66a-9015d83bdd23.jsonl
```

- **Size:** 209M  ← Large files; not copied by default
- **Lines:** 6365
- **Session start:** 2026-04-14T08:17:48.245Z
- **Session end:** 2026-04-14T22:27:47.230Z

## Conversation Statistics

| Type | Count |
|------|-------|
| Human turns | 0 |
| Assistant turns | 0 |
| Tool calls | 0 |

## First Human Message (preview)

> 

## How to Access Full Transcript

```bash
# View raw (large file — pipe through less)
less "/Users/piqui/.codex/sessions/2026/04/14/rollout-2026-04-14T02-17-48-019d8b11-6cb8-7290-b66a-9015d83bdd23.jsonl"

# Extract just human messages
grep '"type":"human_turn"' "/Users/piqui/.codex/sessions/2026/04/14/rollout-2026-04-14T02-17-48-019d8b11-6cb8-7290-b66a-9015d83bdd23.jsonl" | python3 -c "
import sys, json
for line in sys.stdin:
    d = json.loads(line)
    content = d.get('payload', {}).get('content', '')
    if isinstance(content, list):
        for c in content:
            if isinstance(c, dict) and c.get('type') == 'text':
                print('USER:', c.get('text', '')[:300])
                break
    else:
        print('USER:', str(content)[:300])
"

# Copy raw to permanent archive:
cp "/Users/piqui/.codex/sessions/2026/04/14/rollout-2026-04-14T02-17-48-019d8b11-6cb8-7290-b66a-9015d83bdd23.jsonl" /path/to/permanent/archive/codex-2026-04-14-019d8b11.jsonl

# Re-harvest with raw copy:
tools/sessions/harvest-sessions.sh --agent codex --copy-raw --since 2026-04-14
```

## Notes

- Codex sessions do not have a cleanup period — files persist until manually deleted.
- The SQLite log at `~/.codex/logs_2.sqlite` also contains indexed session data.
- `~/.codex/session_index.jsonl` provides a lightweight index of all sessions.

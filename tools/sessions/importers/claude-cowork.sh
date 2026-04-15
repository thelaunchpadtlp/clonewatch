#!/usr/bin/env bash
# =============================================================================
# importers/claude-cowork.sh — Claude Cowork (Agent mode) session importer
# =============================================================================
# Discovers Claude Cowork sessions in:
#   ~/Library/Application Support/Claude/local-agent-mode-sessions/
#
# Each session directory contains:
#   audit.jsonl       — full transcript (tool calls, model output, chain-of-thought)
#   screenshot-*.jpg  — screenshots taken during the session
#   .claude.json      — session configuration
#
# Security note: audit.jsonl has global read permissions and contains the
# model's chain-of-thought. Handle with care.
# =============================================================================

set -euo pipefail

ARCHIVE_DIR="" SINCE="" REPO_ROOT="" COPY_RAW=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-json) shift 2 ;;
    --archive-dir) ARCHIVE_DIR="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --copy-raw) COPY_RAW=true; shift ;;
    *) shift ;;
  esac
done

TODAY="$(date -u +%Y-%m-%d)"
SESSIONS_BASE="${HOME}/Library/Application Support/Claude/local-agent-mode-sessions"

if [[ ! -d "$SESSIONS_BASE" ]]; then
  echo "[claude-cowork] Source not found: $SESSIONS_BASE — skipping."
  exit 0
fi

HARVESTED=0

for session_dir in "$SESSIONS_BASE"/*/; do
  [[ -d "$session_dir" ]] || continue

  audit_file="$session_dir/audit.jsonl"
  [[ -f "$audit_file" ]] || continue

  session_id="$(basename "$session_dir")"
  file_date="$(date -r "$session_dir" +%Y-%m-%d 2>/dev/null || echo "$TODAY")"
  short_id="${session_id:0:8}"

  if [[ -n "$SINCE" && "$file_date" < "$SINCE" ]]; then
    continue
  fi

  dest_dir="$ARCHIVE_DIR/$file_date/claude-cowork-${short_id}"
  if [[ -d "$dest_dir" ]]; then
    echo "[claude-cowork] Already harvested: $short_id (skip)"
    continue
  fi

  mkdir -p "$dest_dir"

  file_size="$(du -sh "$audit_file" 2>/dev/null | cut -f1)"
  line_count="$(wc -l < "$audit_file" 2>/dev/null | tr -d ' ')"
  screenshot_count="$(find "$session_dir" -name "screenshot-*.jpg" | wc -l | tr -d ' ')"

  # Extract first task message
  first_task="$(head -5 "$audit_file" | python3 -c "
import sys,json
for line in sys.stdin:
    try:
        d=json.loads(line)
        if d.get('type') in ('task_start','human_turn','input'):
            content = d.get('data',{}).get('content', d.get('payload',{}).get('content',''))
            if content: print(str(content)[:120]); break
    except: pass
" 2>/dev/null || echo "")"

  # Write reference
  echo "$audit_file" > "$dest_dir/raw-ref.txt"
  echo "Session dir: $session_dir" >> "$dest_dir/raw-ref.txt"
  echo "Size: $file_size | Lines: $line_count | Screenshots: $screenshot_count" >> "$dest_dir/raw-ref.txt"
  echo "⚠ Security: audit.jsonl has global read permissions — contains chain-of-thought" >> "$dest_dir/raw-ref.txt"

  cat > "$dest_dir/metadata.json" << EOF
{
  "schema_version": "1.0",
  "agent_id": "claude-cowork",
  "agent_display_name": "Claude Cowork (Agent mode)",
  "format_id": "claude-cowork-jsonl-v1",
  "session_id": "${session_id}",
  "date": "${file_date}",
  "harvested_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "raw_path": "${audit_file}",
  "raw_size": "${file_size}",
  "raw_lines": ${line_count},
  "screenshots": ${screenshot_count},
  "summary_one_line": "Cowork session — ${first_task:0:80}",
  "cleanup_risk": "LOW — persists until manually deleted (even after UI deletion)",
  "security_note": "audit.jsonl has global read permissions"
}
EOF

  cat > "$dest_dir/summary.md" << EOF
# Session Summary: Claude Cowork — ${short_id}

**Agent:** Claude Cowork (Agent mode)
**Format:** claude-cowork-jsonl-v1
**Date:** ${file_date}
**Session ID:** \`${session_id}\`
**Harvested:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Source

\`\`\`
${session_dir}
├── audit.jsonl          ← Full transcript (${file_size}, ${line_count} lines)
└── screenshot-*.jpg     ← ${screenshot_count} screenshots captured during session
\`\`\`

## First Task (preview)

> ${first_task}

## Security Notes

- \`audit.jsonl\` contains the model's **chain-of-thought** and all tool invocations.
- File has **global read permissions** — any user on this Mac can read it.
- The file **persists even if you delete the session from the Cowork UI**.
- To securely delete: \`rm -rf "${session_dir}"\`

## Access

\`\`\`bash
# View transcript
less "${audit_file}"

# View screenshots
open "${session_dir}"
\`\`\`
EOF

  echo "[claude-cowork] Harvested: $short_id ($file_date, $file_size, $screenshot_count screenshots)"
  HARVESTED=$((HARVESTED+1))
done

echo "[claude-cowork] Total harvested: $HARVESTED session(s)"

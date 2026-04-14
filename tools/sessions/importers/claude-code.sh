#!/usr/bin/env bash
# =============================================================================
# importers/claude-code.sh — Claude Code session importer
# =============================================================================
# Discovers Claude Code sessions in ~/.claude/projects/ and generates
# structured summaries for the Sesiones Importantes subsystem.
#
# Format: claude-code-jsonl-v1
# Source: ~/.claude/projects/{project-dir}/{session-uuid}.jsonl
# Cleanup: sessions auto-deleted after cleanupPeriodDays (default 30)
#
# Called by harvest-sessions.sh with:
#   --agent-json '{...}'   (agent config from sessions-config.json)
#   --archive-dir PATH     (docs/sessions/archive absolute path)
#   --since DATE           (YYYY-MM-DD or empty for all)
#   --repo-root PATH       (repo root absolute path)
# =============================================================================

set -euo pipefail

ARCHIVE_DIR="" SINCE="" REPO_ROOT="" AGENT_JSON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-json) AGENT_JSON="$2"; shift 2 ;;
    --archive-dir) ARCHIVE_DIR="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

TODAY="$(date -u +%Y-%m-%d)"
PROJECTS_DIR="${HOME}/.claude/projects"

if [[ ! -d "$PROJECTS_DIR" ]]; then
  echo "[claude-code] Source not found: $PROJECTS_DIR — skipping."
  exit 0
fi

HARVESTED=0

# Iterate over all project directories
for project_dir in "$PROJECTS_DIR"/*/; do
  [[ -d "$project_dir" ]] || continue
  project_name="$(basename "$project_dir")"

  # Look for .jsonl session files
  for session_file in "$project_dir"*.jsonl; do
    [[ -f "$session_file" ]] || continue

    session_uuid="$(basename "$session_file" .jsonl)"
    file_date="$(date -r "$session_file" +%Y-%m-%d 2>/dev/null || echo "$TODAY")"

    # Filter by date if --since was given
    if [[ -n "$SINCE" && "$file_date" < "$SINCE" ]]; then
      continue
    fi

    # Destination directory
    dest_dir="$ARCHIVE_DIR/$file_date/claude-code-${session_uuid:0:8}"
    if [[ -d "$dest_dir" ]]; then
      echo "[claude-code] Already harvested: $session_uuid (skip)"
      continue
    fi

    mkdir -p "$dest_dir"

    # ── Extract key information ────────────────────────────────────────────
    file_size="$(du -sh "$session_file" 2>/dev/null | cut -f1)"
    line_count="$(wc -l < "$session_file" 2>/dev/null | tr -d ' ')"

    # Extract user messages (queue-operation enqueue)
    user_messages="$(grep -o '"content":"[^"]*"' "$session_file" 2>/dev/null | head -20 | sed 's/"content":"//;s/"$//' | head -5 || echo "")"
    first_user_msg="$(echo "$user_messages" | head -1 | cut -c1-120)"

    # Count message types
    assistant_count="$(grep -c '"type":"assistant"' "$session_file" 2>/dev/null || echo 0)"
    tool_count="$(grep -c '"type":"tool_result"' "$session_file" 2>/dev/null || echo 0)"

    # Get session start timestamp from first line
    first_ts="$(head -1 "$session_file" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('timestamp',''))" 2>/dev/null || echo "")"
    last_ts="$(tail -1 "$session_file" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('timestamp',''))" 2>/dev/null || echo "")"

    # ── Write raw reference (not a copy — file can be 200MB+) ─────────────
    echo "$session_file" > "$dest_dir/raw-ref.txt"
    echo "Size: $file_size | Lines: $line_count" >> "$dest_dir/raw-ref.txt"
    echo "Note: raw file stays in ~/.claude/projects/ (auto-deleted in 30 days)" >> "$dest_dir/raw-ref.txt"

    # ── Write metadata.json ───────────────────────────────────────────────
    cat > "$dest_dir/metadata.json" << EOF
{
  "schema_version": "1.0",
  "agent_id": "claude-code",
  "agent_display_name": "Claude Code",
  "format_id": "claude-code-jsonl-v1",
  "session_id": "${session_uuid}",
  "project_dir": "${project_name}",
  "date": "${file_date}",
  "harvested_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "raw_path": "${session_file}",
  "raw_size": "${file_size}",
  "raw_lines": ${line_count},
  "first_timestamp": "${first_ts}",
  "last_timestamp": "${last_ts}",
  "assistant_turns": ${assistant_count},
  "tool_calls": ${tool_count},
  "summary_one_line": "Claude Code session — ${first_user_msg:0:80}",
  "cleanup_risk": "HIGH — auto-deleted in 30 days from ~/.claude"
}
EOF

    # ── Write summary.md ──────────────────────────────────────────────────
    cat > "$dest_dir/summary.md" << EOF
# Session Summary: Claude Code — ${session_uuid:0:8}

**Agent:** Claude Code
**Format:** claude-code-jsonl-v1
**Date:** ${file_date}
**Session ID:** \`${session_uuid}\`
**Project directory:** \`${project_name}\`
**Harvested:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Source File

\`\`\`
${session_file}
\`\`\`

- **Size:** ${file_size}
- **Lines:** ${line_count}
- **First timestamp:** ${first_ts}
- **Last timestamp:** ${last_ts}
- **⚠ Cleanup risk:** This file is auto-deleted after 30 days by Claude Code.

## Message Statistics

| Type | Count |
|------|-------|
| Assistant turns | ${assistant_count} |
| Tool calls/results | ${tool_count} |

## First User Message (preview)

> ${first_user_msg}

## Notes

- Full transcript available at raw path above while within 30-day retention window.
- To preserve permanently: \`cp "${session_file}" /path/to/permanent/archive/\`
- To convert to HTML: \`uvx claude-code-transcripts\`
- To read with SDK: \`listSessions()\` / \`getSessionMessages("${session_uuid}")\`

## Import Command

\`\`\`bash
# Re-harvest this specific session:
tools/sessions/harvest-sessions.sh --agent claude-code --since ${file_date}
\`\`\`
EOF

    echo "[claude-code] Harvested: $session_uuid ($file_date, $file_size, $line_count lines)"
    HARVESTED=$((HARVESTED+1))
  done
done

echo "[claude-code] Total harvested: $HARVESTED session(s)"

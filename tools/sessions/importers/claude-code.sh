#!/usr/bin/env bash
# =============================================================================
# importers/claude-code.sh — Claude Code session importer
# =============================================================================
# Supports incremental updates: detects when a previously harvested session
# has grown (more content added during an ongoing conversation) and re-harvests.
#
# Format: claude-code-jsonl-v1
# Source: ~/.claude/projects/{project-dir}/{session-uuid}.jsonl
# Cleanup: sessions auto-deleted after cleanupPeriodDays (default 30)
# =============================================================================

set -euo pipefail

ARCHIVE_DIR="" SINCE="" REPO_ROOT="" FORCE="false" TARGET_SESSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-json) shift 2 ;;
    --archive-dir) ARCHIVE_DIR="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --force) FORCE="$2"; shift 2 ;;
    --target-session) TARGET_SESSION="$2"; shift 2 ;;
    *) shift ;;
  esac
done

TODAY="$(date -u +%Y-%m-%d)"
NOW_UNIX="$(date -u +%s)"
PROJECTS_DIR="${HOME}/.claude/projects"
NEW=0; UPDATED=0

file_mtime()       { stat -f %m "$1" 2>/dev/null || echo 0; }
file_size_bytes()  { stat -f %z "$1" 2>/dev/null || echo 0; }

harvest_session() {
  local session_file="$1"
  local dest_dir="$2"
  local is_update="${3:-false}"

  local session_uuid
  session_uuid="$(basename "$session_file" .jsonl)"
  local project_name
  project_name="$(basename "$(dirname "$session_file")")"

  local file_date
  file_date="$(date -r "$session_file" +%Y-%m-%d 2>/dev/null || echo "$TODAY")"
  local file_size
  file_size="$(du -sh "$session_file" 2>/dev/null | cut -f1)"
  local file_size_bytes
  file_size_bytes="$(file_size_bytes "$session_file")"
  local file_mtime
  file_mtime="$(file_mtime "$session_file")"
  local line_count
  line_count="$(wc -l < "$session_file" 2>/dev/null | tr -d ' ')"

  # Get existing harvest count
  local harvest_count=1
  if [[ -f "$dest_dir/metadata.json" ]]; then
    harvest_count="$(jq -r '.harvest_count // 1' "$dest_dir/metadata.json" 2>/dev/null)"
    [[ "$is_update" == "true" ]] && harvest_count=$((harvest_count + 1))
  fi

  # Calculate cleanup window
  local age_days=$(( (NOW_UNIX - file_mtime) / 86400 ))
  local days_remaining=$((30 - age_days))
  local cleanup_risk
  if [[ $days_remaining -le 5 ]]; then
    cleanup_risk="CRITICAL — only $days_remaining days left before auto-delete"
  elif [[ $days_remaining -le 10 ]]; then
    cleanup_risk="HIGH — $days_remaining days remaining"
  else
    cleanup_risk="NORMAL — $days_remaining days remaining (30-day window)"
  fi

  # Session status
  local status
  if [[ $(( NOW_UNIX - file_mtime )) -lt 3600 ]]; then
    status="active"
  elif [[ $(( NOW_UNIX - file_mtime )) -lt 86400 ]]; then
    status="recent"
  elif [[ $days_remaining -le 0 ]]; then
    status="expired"
  elif [[ $days_remaining -le 10 ]]; then
    status="aging"
  else
    status="completed"
  fi

  # Extract info from file
  local assistant_count
  assistant_count="$(grep -c '"type":"assistant"' "$session_file" 2>/dev/null; true)"
  assistant_count="${assistant_count//[$'\n\r ']/}"; assistant_count="${assistant_count:-0}"
  local tool_count
  tool_count="$(grep -c '"type":"tool_result"' "$session_file" 2>/dev/null; true)"
  tool_count="${tool_count//[$'\n\r ']/}"; tool_count="${tool_count:-0}"

  local first_ts last_ts first_user_msg
  first_ts="$(head -1 "$session_file" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('timestamp',''))" 2>/dev/null || echo "")"
  last_ts="$(tail -1 "$session_file" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('timestamp',''))" 2>/dev/null || echo "")"
  first_user_msg="$(grep '"operation":"enqueue"' "$session_file" 2>/dev/null | head -1 | python3 -c "
import sys,json
try:
  d=json.loads(sys.stdin.read())
  c=d.get('content','')
  if isinstance(c,str): print(c[:120])
  elif isinstance(c,list):
    for item in c:
      if isinstance(item,dict) and item.get('type')=='text':
        print(item.get('text','')[:120]); break
except: pass
" 2>/dev/null || echo "")"

  mkdir -p "$dest_dir"

  # Write raw-ref.txt
  cat > "$dest_dir/raw-ref.txt" << EOF
${session_file}
Size: ${file_size} (${file_size_bytes} bytes) | Lines: ${line_count}
Status: ${status} | Harvest count: ${harvest_count}
Last modified: $(date -r "$session_file" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
⚠ Auto-deleted by Claude Code after 30 days (~${days_remaining} days remaining)
EOF

  # Write metadata.json (overwrites on update — tracks evolution)
  cat > "$dest_dir/metadata.json" << EOF
{
  "schema_version": "1.1",
  "agent_id": "claude-code",
  "agent_display_name": "Claude Code",
  "format_id": "claude-code-jsonl-v1",
  "session_id": "${session_uuid}",
  "project_dir": "${project_name}",
  "date": "${file_date}",
  "harvested_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "harvest_count": ${harvest_count},
  "session_status": "${status}",
  "raw_path": "${session_file}",
  "raw_size": "${file_size}",
  "raw_size_bytes": ${file_size_bytes},
  "raw_mtime_unix": ${file_mtime},
  "raw_lines": ${line_count},
  "first_timestamp": "${first_ts}",
  "last_timestamp": "${last_ts}",
  "assistant_turns": ${assistant_count},
  "tool_calls": ${tool_count},
  "cleanup_risk": "${cleanup_risk}",
  "days_until_cleanup": ${days_remaining},
  "summary_one_line": "Claude Code session — ${first_user_msg:0:80}"
}
EOF

  # Write summary.md
  local action_label
  [[ "$is_update" == "true" ]] && action_label="**Updated harvest ×${harvest_count}**" || action_label="First harvest"

  cat > "$dest_dir/summary.md" << EOF
# Session: Claude Code — ${session_uuid:0:8}

**Agent:** Claude Code | **Status:** ${status}
**Date:** ${file_date} | **Session ID:** \`${session_uuid}\`
**${action_label}** — $(date -u "+%Y-%m-%d %H:%M UTC")

---

## Source

\`\`\`
${session_file}
\`\`\`

| Field | Value |
|-------|-------|
| Size | ${file_size} (${file_size_bytes} bytes) |
| Lines | ${line_count} |
| First message | ${first_ts} |
| Last message | ${last_ts} |
| Assistant turns | ${assistant_count} |
| Tool calls | ${tool_count} |
| Harvest count | ${harvest_count} |

## ⚠ Cleanup Risk

**${cleanup_risk}**

\`\`\`bash
# Preserve permanently before auto-delete:
cp "${session_file}" ~/Documents/clonewatch-sessions/claude-code-${file_date}-${session_uuid:0:8}.jsonl

# Convert to HTML:
uvx claude-code-transcripts
\`\`\`

## First User Message

> ${first_user_msg}

## Re-harvest

\`\`\`bash
# Run at any time to update this record:
tools/sessions/harvest-sessions.sh --agent claude-code
\`\`\`
EOF
}

# ── Main: iterate sessions ────────────────────────────────────────────────────
[[ -d "$PROJECTS_DIR" ]] || { echo "[claude-code] Not found: $PROJECTS_DIR — skip."; exit 0; }

for project_dir in "$PROJECTS_DIR"/*/; do
  [[ -d "$project_dir" ]] || continue
  for session_file in "$project_dir"*.jsonl; do
    [[ -f "$session_file" ]] || continue

    session_uuid="$(basename "$session_file" .jsonl)"

    # If targeting a specific session
    if [[ -n "$TARGET_SESSION" && "$session_uuid" != "$TARGET_SESSION" ]]; then
      continue
    fi

    file_date="$(date -r "$session_file" +%Y-%m-%d 2>/dev/null || echo "$TODAY")"

    # Date filter
    if [[ -n "$SINCE" && "$file_date" < "$SINCE" ]]; then
      continue
    fi

    dest_dir="$ARCHIVE_DIR/$file_date/claude-code-${session_uuid:0:8}"

    if [[ -d "$dest_dir" && "$FORCE" != "true" ]]; then
      # Check staleness: compare stored vs current file stats
      current_size="$(file_size_bytes "$session_file")"
      current_mtime="$(file_mtime "$session_file")"
      stored_size="$(jq -r '.raw_size_bytes // 0' "$dest_dir/metadata.json" 2>/dev/null)"
      stored_mtime="$(jq -r '.raw_mtime_unix // 0' "$dest_dir/metadata.json" 2>/dev/null)"

      if [[ "$current_size" -gt "$stored_size" || "$current_mtime" -gt "$stored_mtime" ]]; then
        echo "[claude-code] [updated] ${session_uuid:0:8}: grew from ${stored_size}B to ${current_size}B ($(( (current_size - stored_size) / 1024 ))KB added)"
        harvest_session "$session_file" "$dest_dir" "true"
        UPDATED=$((UPDATED+1))
      else
        echo "[claude-code] [current] ${session_uuid:0:8}: unchanged (skip)"
      fi
    else
      echo "[claude-code] [new] ${session_uuid:0:8}: $file_date"
      harvest_session "$session_file" "$dest_dir" "false"
      NEW=$((NEW+1))
    fi
  done
done

echo "[claude-code] Done — new=$NEW updated=$UPDATED"

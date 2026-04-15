#!/usr/bin/env bash
# =============================================================================
# importers/codex.sh — ChatGPT Codex session importer
# =============================================================================
# Discovers Codex sessions in ~/.codex/sessions/ and generates structured
# summaries for the Sesiones Importantes subsystem.
#
# Format: codex-jsonl-v1
# Source: ~/.codex/sessions/YYYY/MM/DD/rollout-{timestamp}-{uuid}.jsonl
# Also:   ~/.codex/session_index.jsonl (index of all sessions)
#         ~/.codex/logs_2.sqlite (structured log database)
#
# NOTE: Codex session files are often 50-500MB. This importer does NOT copy
# the raw files — it creates a reference + summary. To copy a specific file,
# use the --copy-raw flag.
#
# Called by harvest-sessions.sh with standard --agent-json, --archive-dir,
# --since, --repo-root flags.
# =============================================================================

set -euo pipefail

ARCHIVE_DIR="" SINCE="" REPO_ROOT="" AGENT_JSON="" COPY_RAW=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-json) AGENT_JSON="$2"; shift 2 ;;
    --archive-dir) ARCHIVE_DIR="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --copy-raw) COPY_RAW=true; shift ;;
    *) shift ;;
  esac
done

TODAY="$(date -u +%Y-%m-%d)"
SESSIONS_DIR="${HOME}/.codex/sessions"
INDEX_FILE="${HOME}/.codex/session_index.jsonl"

if [[ ! -d "$SESSIONS_DIR" ]]; then
  echo "[codex] Source not found: $SESSIONS_DIR — skipping."
  exit 0
fi

HARVESTED=0
# Use process substitution to avoid subshell variable scope issue
# Walk by date: YYYY/MM/DD/rollout-*.jsonl
while read -r session_file; do
  # Extract date from path: sessions/YYYY/MM/DD/rollout-...
  # Path looks like: ~/.codex/sessions/2026/04/14/rollout-2026-04-14T02-17-48-uuid.jsonl
  rel_path="${session_file#$SESSIONS_DIR/}"
  IFS='/' read -r year month day rest <<< "$rel_path"
  file_date="${year}-${month}-${day}"

  # Filter by date
  if [[ -n "$SINCE" && "$file_date" < "$SINCE" ]]; then
    continue
  fi

  # Extract session UUID from filename: rollout-TIMESTAMP-UUID.jsonl
  filename="$(basename "$session_file" .jsonl)"
  # UUID is after the last -group-of-8-chars pattern
  session_uuid="$(echo "$filename" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | tail -1 || echo "$filename")"
  short_id="${session_uuid:0:8}"

  dest_dir="$ARCHIVE_DIR/$file_date/codex-${short_id}"
  if [[ -d "$dest_dir" ]]; then
    echo "[codex] Already harvested: $short_id (skip)"
    continue
  fi

  mkdir -p "$dest_dir"

  # ── Extract metadata from first line (session_meta) ──────────────────────
  file_size="$(du -sh "$session_file" 2>/dev/null | cut -f1)"
  line_count="$(wc -l < "$session_file" 2>/dev/null | tr -d ' ')"

  first_line="$(head -1 "$session_file" 2>/dev/null || echo '{}')"
  session_start="$(echo "$first_line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('payload',{}).get('timestamp', d.get('timestamp','')))" 2>/dev/null || echo "")"
  cwd="$(echo "$first_line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('payload',{}).get('cwd',''))" 2>/dev/null || echo "")"
  cli_version="$(echo "$first_line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('payload',{}).get('cli_version',''))" 2>/dev/null || echo "")"
  source_app="$(echo "$first_line" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('payload',{}).get('source',''))" 2>/dev/null || echo "")"

  # Get last timestamp
  last_ts="$(tail -1 "$session_file" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('timestamp',''))" 2>/dev/null || echo "")"

  # Count turn types (grep -c always prints count; don't add || echo 0 which causes double output)
  human_turns="$(grep -c '"type":"human_turn"' "$session_file" 2>/dev/null; true)"
  assistant_turns="$(grep -c '"type":"assistant_turn"' "$session_file" 2>/dev/null; true)"
  tool_calls="$(grep -c '"type":"tool_call"' "$session_file" 2>/dev/null; true)"
  # Strip any trailing whitespace/newlines
  human_turns="${human_turns//[$'\n\r ']/}"
  assistant_turns="${assistant_turns//[$'\n\r ']/}"
  tool_calls="${tool_calls//[$'\n\r ']/}"
  # Default to 0 if empty
  human_turns="${human_turns:-0}"
  assistant_turns="${assistant_turns:-0}"
  tool_calls="${tool_calls:-0}"

  # Extract first human message for summary
  first_human_msg="$(grep '"type":"human_turn"' "$session_file" 2>/dev/null | head -1 | python3 -c "
import sys,json
try:
  d=json.loads(sys.stdin.read())
  content=d.get('payload',{}).get('content','')
  if isinstance(content,list):
    for c in content:
      if isinstance(c,dict) and c.get('type')=='text':
        print(c.get('text','')[:120]); break
  else:
    print(str(content)[:120])
except: print('')
" 2>/dev/null || echo "")"

  # ── Write raw reference ───────────────────────────────────────────────────
  cat > "$dest_dir/raw-ref.txt" << EOF
${session_file}
Size: ${file_size}
Lines: ${line_count}
Note: Codex sessions are typically 50-500MB. Raw file NOT copied.
To copy: cp "${session_file}" /path/to/archive/
EOF

  # Copy raw if requested
  if [[ "$COPY_RAW" == true ]]; then
    echo "[codex] Copying raw file (this may take a while for large sessions)..."
    cp "$session_file" "$dest_dir/raw.jsonl"
    echo "[codex] Raw copy complete."
  fi

  # ── Write metadata.json ───────────────────────────────────────────────────
  cat > "$dest_dir/metadata.json" << EOF
{
  "schema_version": "1.0",
  "agent_id": "codex",
  "agent_display_name": "ChatGPT Codex",
  "format_id": "codex-jsonl-v1",
  "session_id": "${session_uuid}",
  "short_id": "${short_id}",
  "date": "${file_date}",
  "harvested_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "raw_path": "${session_file}",
  "raw_size": "${file_size}",
  "raw_lines": ${line_count},
  "session_start": "${session_start}",
  "session_end": "${last_ts}",
  "cwd": "${cwd}",
  "cli_version": "${cli_version}",
  "source_app": "${source_app}",
  "human_turns": ${human_turns},
  "assistant_turns": ${assistant_turns},
  "tool_calls": ${tool_calls},
  "summary_one_line": "Codex session — ${first_human_msg:0:80}",
  "cleanup_risk": "LOW — Codex does not auto-delete sessions",
  "raw_copied": ${COPY_RAW}
}
EOF

  # ── Write summary.md ──────────────────────────────────────────────────────
  cat > "$dest_dir/summary.md" << EOF
# Session Summary: ChatGPT Codex — ${short_id}

**Agent:** ChatGPT Codex (${cli_version})
**Format:** codex-jsonl-v1
**Date:** ${file_date}
**Session ID:** \`${session_uuid}\`
**Source app:** ${source_app}
**Working directory:** \`${cwd}\`
**Harvested:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Source File

\`\`\`
${session_file}
\`\`\`

- **Size:** ${file_size}  ← Large files; not copied by default
- **Lines:** ${line_count}
- **Session start:** ${session_start}
- **Session end:** ${last_ts}

## Conversation Statistics

| Type | Count |
|------|-------|
| Human turns | ${human_turns} |
| Assistant turns | ${assistant_turns} |
| Tool calls | ${tool_calls} |

## First Human Message (preview)

> ${first_human_msg}

## How to Access Full Transcript

\`\`\`bash
# View raw (large file — pipe through less)
less "${session_file}"

# Extract just human messages
grep '"type":"human_turn"' "${session_file}" | python3 -c "
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
cp "${session_file}" /path/to/permanent/archive/codex-${file_date}-${short_id}.jsonl

# Re-harvest with raw copy:
tools/sessions/harvest-sessions.sh --agent codex --copy-raw --since ${file_date}
\`\`\`

## Notes

- Codex sessions do not have a cleanup period — files persist until manually deleted.
- The SQLite log at \`~/.codex/logs_2.sqlite\` also contains indexed session data.
- \`~/.codex/session_index.jsonl\` provides a lightweight index of all sessions.
EOF

  echo "[codex] Harvested: ${short_id} (${file_date}, ${file_size}, ${line_count} lines)"
  HARVESTED=$((HARVESTED+1))
done < <(find "$SESSIONS_DIR" -name "rollout-*.jsonl" | sort)

echo "[codex] Total harvested: $HARVESTED session(s)"

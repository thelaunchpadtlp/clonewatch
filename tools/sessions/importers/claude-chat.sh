#!/usr/bin/env bash
# =============================================================================
# importers/claude-chat.sh — Claude Chat (Desktop / Web) session importer
# =============================================================================
# Claude Chat is cloud-only. No local session files are created automatically.
# Export requires a manual action: Settings > Privacy > Export data.
#
# This importer processes a manually downloaded export ZIP:
#   tools/sessions/harvest-sessions.sh --agent claude-chat --input ~/Downloads/claude-export-*.zip
#
# If no --input is provided, it prints instructions and exits cleanly.
# =============================================================================

set -euo pipefail

ARCHIVE_DIR="" SINCE="" INPUT_ZIP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-json) shift 2 ;;
    --archive-dir) ARCHIVE_DIR="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --repo-root) shift 2 ;;
    --input) INPUT_ZIP="$2"; shift 2 ;;
    *) shift ;;
  esac
done

TODAY="$(date -u +%Y-%m-%d)"

if [[ -z "$INPUT_ZIP" ]]; then
  echo "[claude-chat] No --input ZIP provided."
  echo ""
  echo "Claude Chat is cloud-only. To export:"
  echo "  1. Open Claude Desktop"
  echo "  2. Click avatar/initials (bottom left)"
  echo "  3. Settings > Privacy > Export data"
  echo "  4. Download the ZIP within 24 hours"
  echo "  5. Re-run with:"
  echo "     tools/sessions/harvest-sessions.sh --agent claude-chat --input ~/Downloads/claude-export-YYYY-MM-DD.zip"
  echo ""
  echo "[claude-chat] Skipping (no input)."
  exit 0
fi

if [[ ! -f "$INPUT_ZIP" ]]; then
  echo "[claude-chat] Input file not found: $INPUT_ZIP"
  exit 1
fi

export_date="$(basename "$INPUT_ZIP" .zip | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || echo "$TODAY")"
dest_dir="$ARCHIVE_DIR/$export_date/claude-chat-export-${export_date}"
mkdir -p "$dest_dir"

# Extract ZIP
tmp_dir="$(mktemp -d)"
unzip -q "$INPUT_ZIP" -d "$tmp_dir"

# Find conversation files
conv_count="$(find "$tmp_dir" -name "*.json" | wc -l | tr -d ' ')"
zip_size="$(du -sh "$INPUT_ZIP" | cut -f1)"

# Copy extracted content
cp -r "$tmp_dir/." "$dest_dir/extracted/"
rm -rf "$tmp_dir"

cat > "$dest_dir/metadata.json" << EOF
{
  "schema_version": "1.0",
  "agent_id": "claude-chat",
  "agent_display_name": "Claude Chat",
  "format_id": "claude-chat-export-v1",
  "session_id": "export-${export_date}",
  "date": "${export_date}",
  "harvested_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source_zip": "${INPUT_ZIP}",
  "zip_size": "${zip_size}",
  "conversation_files": ${conv_count},
  "summary_one_line": "Claude Chat export — ${conv_count} conversation files",
  "cleanup_risk": "NONE — export was manually created; original data is in Anthropic cloud"
}
EOF

cat > "$dest_dir/summary.md" << EOF
# Session Export: Claude Chat — ${export_date}

**Agent:** Claude Chat (Desktop / Web)
**Format:** claude-chat-export-v1
**Export date:** ${export_date}
**Source ZIP:** \`${INPUT_ZIP}\`
**Harvested:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Contents

- ZIP size: ${zip_size}
- Conversation files found: ${conv_count}
- Extracted to: \`${dest_dir}/extracted/\`

## Notes

- Claude Chat exports include all conversations from your Anthropic account.
- The original data remains in the Anthropic cloud.
- Re-export periodically to keep this archive current.
- Export does NOT include Claude Code or Cowork sessions.
EOF

echo "[claude-chat] Import complete: ${conv_count} conversation files from $export_date export"

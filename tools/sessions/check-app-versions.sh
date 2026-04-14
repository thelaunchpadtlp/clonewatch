#!/usr/bin/env bash
# =============================================================================
# check-app-versions.sh — Agent app version change detector
# =============================================================================
# Reads currently installed versions of all registered agent apps and compares
# them against the last-known versions stored in sessions-config-versions.json.
#
# When an app updates, its session format may change. This script alerts so the
# corresponding importer can be inspected and updated if needed.
#
# Usage:
#   ./check-app-versions.sh
#   ./check-app-versions.sh --config /path/to/sessions-config.json
#   ./check-app-versions.sh --save     # save current versions as baseline
#   ./check-app-versions.sh --report   # just print versions, no comparison
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/sessions-config.json"
VERSIONS_FILE="${SCRIPT_DIR}/sessions-versions.json"
SAVE=false
ACTION="check"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[versions]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[changed]${NC} $*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --save) SAVE=true; shift ;;
    --report) ACTION="report"; shift ;;
    *) shift ;;
  esac
done

# ── Version probes (macOS-specific, extensible) ───────────────────────────────
get_claude_desktop_version() {
  defaults read "/Applications/Claude.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "not-installed"
}

get_codex_cli_version() {
  # From the most recent session_meta line in ~/.codex/sessions
  find "${HOME}/.codex/sessions" -name "rollout-*.jsonl" 2>/dev/null | sort | tail -1 | \
    xargs -I{} head -1 {} 2>/dev/null | \
    python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('payload',{}).get('cli_version','unknown'))" 2>/dev/null || echo "unknown"
}

get_codex_model() {
  grep "^model = " "${HOME}/.codex/config.toml" 2>/dev/null | sed 's/model = "//;s/"//' || echo "unknown"
}

get_xcode_version() {
  xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown"
}

get_xcode_beta_version() {
  defaults read "/Applications/Xcode-beta.app/Contents/version.plist" CFBundleShortVersionString 2>/dev/null || echo "not-installed"
}

get_cursor_version() {
  defaults read "/Applications/Cursor.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "not-installed"
}

# ── Read current versions ─────────────────────────────────────────────────────
read_current_versions() {
  python3 - << 'PYEOF'
import json, subprocess, os
from datetime import datetime, timezone

def run(cmd):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return r.stdout.strip() or r.stderr.strip() or "unknown"
    except Exception as e:
        return f"error: {e}"

versions = {
    "checked_at": datetime.now(timezone.utc).isoformat(),
    "agents": {
        "claude-code": {
            "app": "Claude Desktop (Code mode)",
            "app_version": run("defaults read '/Applications/Claude.app/Contents/Info.plist' CFBundleShortVersionString 2>/dev/null"),
            "probe": "defaults read /Applications/Claude.app"
        },
        "codex": {
            "app": "ChatGPT Codex Desktop",
            "cli_version": run("""find ~/.codex/sessions -name 'rollout-*.jsonl' 2>/dev/null | sort | tail -1 | xargs -I{} head -1 {} 2>/dev/null | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('payload',{}).get('cli_version','unknown'))" 2>/dev/null || echo unknown"""),
            "model": run("grep '^model = ' ~/.codex/config.toml 2>/dev/null | sed 's/model = \"//;s/\"//' || echo unknown"),
            "probe": "~/.codex/config.toml + session_meta"
        },
        "claude-cowork": {
            "app": "Claude Desktop (Cowork mode)",
            "app_version": run("defaults read '/Applications/Claude.app/Contents/Info.plist' CFBundleShortVersionString 2>/dev/null"),
            "probe": "defaults read /Applications/Claude.app"
        },
        "xcode": {
            "app": "Xcode",
            "version": run("xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}'"),
            "probe": "xcodebuild -version"
        },
        "xcode-beta": {
            "app": "Xcode Beta",
            "version": run("defaults read '/Applications/Xcode-beta.app/Contents/version.plist' CFBundleShortVersionString 2>/dev/null || echo not-installed"),
            "probe": "defaults read /Applications/Xcode-beta.app"
        }
    }
}
print(json.dumps(versions, indent=2))
PYEOF
}

# ── Report mode ───────────────────────────────────────────────────────────────
if [[ "$ACTION" == "report" ]]; then
  log "Current installed versions:"
  echo ""
  read_current_versions | python3 -c "
import sys, json
d = json.loads(sys.stdin.read())
for agent, info in d.get('agents', {}).items():
    print(f'  {agent}:')
    for k, v in info.items():
        if k not in ('probe',):
            print(f'    {k}: {v}')
    print()
"
  exit 0
fi

# ── Save baseline ──────────────────────────────────────────────────────────────
if [[ "$SAVE" == true ]]; then
  log "Saving current versions as baseline..."
  read_current_versions > "$VERSIONS_FILE"
  ok "Saved to: $VERSIONS_FILE"
  cat "$VERSIONS_FILE"
  exit 0
fi

# ── Compare ───────────────────────────────────────────────────────────────────
log "Checking for app version changes..."

if [[ ! -f "$VERSIONS_FILE" ]]; then
  warn "No baseline found. Run with --save first to establish baseline."
  warn "Saving current versions as first baseline..."
  read_current_versions > "$VERSIONS_FILE"
  ok "Baseline saved: $VERSIONS_FILE"
  exit 0
fi

CURRENT="$(read_current_versions)"
CHANGES=0

python3 - << PYEOF
import json, sys

baseline = json.load(open("$VERSIONS_FILE"))
current = json.loads("""$CURRENT""")

baseline_agents = baseline.get("agents", {})
current_agents = current.get("agents", {})

print()
any_change = False
for agent in set(list(baseline_agents.keys()) + list(current_agents.keys())):
    b = baseline_agents.get(agent, {})
    c = current_agents.get(agent, {})
    changed_fields = []
    for field in set(list(b.keys()) + list(c.keys())):
        if field in ("probe",):
            continue
        bv = b.get(field, "—")
        cv = c.get(field, "—")
        if bv != cv:
            changed_fields.append((field, bv, cv))
    if changed_fields:
        any_change = True
        print(f"  ⚠  {agent}: VERSION CHANGE DETECTED")
        for field, bv, cv in changed_fields:
            print(f"      {field}: {bv} → {cv}")
        print(f"      ↳ Inspect importer: tools/sessions/importers/{agent}.sh")
        print(f"      ↳ Check format: docs/sessions/protocols/format-registry.md")
        print()
    else:
        version_str = c.get("app_version") or c.get("version") or c.get("cli_version") or "?"
        print(f"  ✅ {agent}: {version_str} (unchanged)")

if not any_change:
    print()
    print("All agent versions match baseline. No format changes expected.")
sys.exit(1 if any_change else 0)
PYEOF
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  echo ""
  warn "Version changes detected. Review importers before next harvest."
  warn "After verifying importers work: ./check-app-versions.sh --save"
  echo ""
  exit 1
fi

exit 0

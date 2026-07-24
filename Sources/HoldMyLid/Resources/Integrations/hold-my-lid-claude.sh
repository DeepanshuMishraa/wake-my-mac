#!/bin/sh
# Managed by StayRunning. Claude Code passes hook JSON on stdin.
set -eu
dir="$HOME/Library/Application Support/Hold My Lid/Sessions"
mkdir -p "$dir"
input=$(cat || true)
event=$(printf '%s' "$input" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin).get("hook_event_name", "SessionStart"))' 2>/dev/null || printf 'SessionStart')
status=working
case "$event" in
  Stop|SessionEnd) status=idle ;;
esac
/usr/bin/python3 - "$dir" "$status" <<'PY'
import json, os, sys, datetime
directory, status = sys.argv[1:]
session_id = os.environ.get("CLAUDE_CODE_SESSION_ID", str(os.getpid()))
path = os.path.join(directory, "claude-" + session_id + ".json")
payload = {
    "id": "claude-" + session_id,
    "agent": "Claude Code",
    "title": "Claude Code",
    "status": status,
    "lastUpdated": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
    "pid": os.getpid(),
    "source": "hook",
}
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(payload, f)
os.replace(tmp, path)
PY

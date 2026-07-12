#!/usr/bin/env python3
"""Managed Antigravity hook adapter for Wake My Mac."""
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


def main() -> None:
    payload = json.load(sys.stdin)
    conversation = str(payload.get("conversationId") or "unknown")
    mode = sys.argv[1] if len(sys.argv) > 1 else "working"
    status = "working"
    if mode == "stop" and bool(payload.get("fullyIdle", True)):
        status = "idle"

    directory = Path.home() / "Library" / "Application Support" / "Hold My Lid" / "Sessions"
    directory.mkdir(parents=True, exist_ok=True)
    session_id = f"antigravity-{conversation}"
    target = directory / f"{session_id}.json"
    temporary = directory / f".{session_id}.{os.getpid()}.tmp"
    record = {
        "id": session_id,
        "agent": "Antigravity",
        "title": "Antigravity",
        "status": status,
        "lastUpdated": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "pid": None,
        "source": "antigravity-adapter",
        "sequence": time.time_ns(),
    }
    temporary.write_text(json.dumps(record), encoding="utf-8")
    temporary.replace(target)
    print("{}")


if __name__ == "__main__":
    main()

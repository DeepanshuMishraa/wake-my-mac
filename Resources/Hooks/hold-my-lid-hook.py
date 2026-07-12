#!/usr/bin/env python3
import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path

AGENTS = {
    "claude": "Claude Code",
    "claude-code": "Claude Code",
    "codex": "OpenAI Codex CLI",
    "opencode": "OpenCode",
    "open-code": "OpenCode",
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Report an agent lifecycle state to Wake My Mac.")
    parser.add_argument("--agent", required=True, choices=sorted(AGENTS.keys()))
    parser.add_argument("--session", default=os.environ.get("HOLD_MY_LID_SESSION") or os.environ.get("PWD") or "default")
    parser.add_argument("--status", required=True, choices=["working", "idle"])
    parser.add_argument("--title", default="")
    parser.add_argument("--pid", type=int, default=os.getppid())
    args = parser.parse_args()

    base = Path.home() / "Library" / "Application Support" / "Hold My Lid" / "Sessions"
    base.mkdir(parents=True, exist_ok=True)

    safe_session = "".join(ch if ch.isalnum() or ch in "-_." else "-" for ch in args.session)[-120:]
    path = base / f"{args.agent}-{safe_session}.json"

    payload = {
        "id": f"{args.agent}-{safe_session}",
        "agent": AGENTS[args.agent],
        "title": args.title or AGENTS[args.agent],
        "status": args.status,
        "lastUpdated": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "pid": args.pid,
        "source": "hook",
    }

    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()

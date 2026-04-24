#!/usr/bin/env python3
"""
decision_logger.py — append-only decision event writer.

Usage (library):
    from decision_logger import DecisionLogger, new_event_id

    logger = DecisionLogger(
        log_dir=Path("docs/research/routellm-phase3/logs/"),
        recorded_by="router.js",
    )
    event_id = new_event_id()
    logger.emit({
        "event_id": event_id,
        "parent_event_id": None,
        "event_type": "router.classification",
        "context": {"session_id": "...", "project_id": "agent-manifesto"},
        "input": {"prompt": "...", "prompt_sha256": "..."},
        "decision": {"kind": "classification", "predicted_label": "cloud_required", ...},
    })

Usage (CLI test):
    python3 decision_logger.py --self-test

Schema: decision-log-schema.md (v1.0.0), decision_event.schema.json.

Design goals:
  - best-effort: write failures never raise to caller
  - atomic per-line: each event is one JSON line, newline-terminated
  - daily partitioned: one file per UTC date
  - extensible: unknown sections are written through unchanged
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "1.0.0"
LOGGER_VERSION = "1.0.0"


def new_event_id() -> str:
    return str(uuid.uuid4())


def sha256_hex(text: str | bytes) -> str:
    if isinstance(text, str):
        text = text.encode("utf-8")
    return hashlib.sha256(text).hexdigest()


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def build_context(
    *,
    session_id: str,
    project_id: str = "agent-manifesto",
    project_path: str | None = None,
    working_directory: str | None = None,
    git_branch: str | None = None,
    git_commit_sha: str | None = None,
    git_worktree: bool | None = None,
    turn_id: int | None = None,
    sequence_id: int | None = None,
    tz: str | None = None,
    machine_id: str | None = None,
    os_id: str | None = None,
    cli_version: str | None = None,
    model_version: str | None = None,
) -> dict[str, Any]:
    ctx: dict[str, Any] = {
        "session_id": session_id,
        "project_id": project_id,
    }
    for key, value in [
        ("project_path", project_path),
        ("working_directory", working_directory),
        ("git_branch", git_branch),
        ("git_commit_sha", git_commit_sha),
        ("git_worktree", git_worktree),
        ("turn_id", turn_id),
        ("sequence_id", sequence_id),
        ("tz", tz),
        ("machine_id", machine_id),
        ("os", os_id),
        ("cli_version", cli_version),
        ("model_version", model_version),
    ]:
        if value is not None:
            ctx[key] = value
    return ctx


class DecisionLogger:
    """Append-only JSONL writer for decision events.

    Thread-safety: single-writer file-append-only is atomic on POSIX for lines
    under PIPE_BUF. We keep events small; callers that need strict ordering
    across processes should serialize calls themselves.
    """

    def __init__(
        self,
        log_dir: Path,
        *,
        recorded_by: str,
        hook_id: str | None = None,
        redaction_level: str = "none",
    ) -> None:
        self.log_dir = log_dir
        self.recorded_by = recorded_by
        self.hook_id = hook_id
        self.redaction_level = redaction_level
        self.log_dir.mkdir(parents=True, exist_ok=True)

    def _path_for(self, ts: datetime) -> Path:
        return self.log_dir / f"decisions-{ts.strftime('%Y-%m-%d')}.jsonl"

    def emit(self, event: dict[str, Any]) -> str:
        """Normalize + append one event. Returns the event_id (generating if missing).

        Never raises on I/O failure — logs to stderr and returns the id.
        """
        now = datetime.now(timezone.utc)
        event.setdefault("schema_version", SCHEMA_VERSION)
        event.setdefault("event_id", new_event_id())
        event.setdefault("parent_event_id", None)
        event.setdefault("timestamp_utc", now.replace(microsecond=0).isoformat().replace("+00:00", "Z"))
        event.setdefault("provenance", {})

        prov = event["provenance"]
        prov.setdefault("schema_version", SCHEMA_VERSION)
        prov.setdefault("logger_version", LOGGER_VERSION)
        prov.setdefault("recorded_by", self.recorded_by)
        if self.hook_id is not None:
            prov.setdefault("hook_id", self.hook_id)
        prov.setdefault("redaction_level", self.redaction_level)

        if self.redaction_level == "prompt_sha_only":
            inp = event.get("input") or {}
            if "prompt" in inp:
                if inp.get("prompt") is not None and not inp.get("prompt_sha256"):
                    inp["prompt_sha256"] = sha256_hex(inp["prompt"])
                inp["prompt"] = None
                event["input"] = inp

        path = self._path_for(now)
        line = json.dumps(event, ensure_ascii=False, separators=(",", ":"))

        try:
            with path.open("a", encoding="utf-8") as f:
                f.write(line + "\n")
        except OSError as exc:
            print(f"[decision_logger] write failure to {path}: {exc}", file=sys.stderr)

        return event["event_id"]


def _self_test() -> int:
    tmp = Path(os.environ.get("TMPDIR", "/tmp")) / "decision-logger-selftest"
    if tmp.exists():
        for f in tmp.iterdir():
            f.unlink()
    tmp.mkdir(parents=True, exist_ok=True)

    logger = DecisionLogger(tmp, recorded_by="decision_logger.selftest", redaction_level="none")

    # user.turn
    turn_id = logger.emit({
        "event_type": "user.turn",
        "context": build_context(
            session_id="test-session",
            project_id="agent-manifesto",
            git_branch="main",
            turn_id=1,
        ),
        "input": {
            "prompt": "/research issue を整理して",
            "prompt_sha256": sha256_hex("/research issue を整理して"),
            "prompt_length": 22,
            "prompt_language": "ja",
            "prompt_source": "user",
        },
    })

    # router.classification
    cls_id = logger.emit({
        "event_type": "router.classification",
        "parent_event_id": turn_id,
        "context": build_context(
            session_id="test-session", project_id="agent-manifesto",
            turn_id=1, sequence_id=0,
        ),
        "input": {
            "prompt_sha256": sha256_hex("/research issue を整理して"),
            "prompt_length": 22,
        },
        "decision": {
            "kind": "classification",
            "classifier_id": "mdeberta-v3-base-agent-manifesto",
            "classifier_version": "2026-04-23T12:00Z",
            "probs": {
                "local_confident": 0.10,
                "local_probable": 0.17,
                "cloud_required": 0.48,
                "hybrid": 0.20,
                "unknown": 0.05,
            },
            "predicted_label": "cloud_required",
            "predicted_confidence": 0.48,
            "p_local": 0.27,
            "p_cloud": 0.73,
            "latency_ms": 80.4,
        },
    })

    # router.decision
    dec_id = logger.emit({
        "event_type": "router.decision",
        "parent_event_id": cls_id,
        "context": build_context(
            session_id="test-session", project_id="agent-manifesto",
            turn_id=1, sequence_id=1,
        ),
        "decision": {
            "kind": "routing",
            "action": "route_to_cloud",
            "rule_applied": "utility_max",
            "rule_inputs": {"cost_safety": 1.8, "cost_cloud": 1.0, "oov_threshold": 0.3,
                            "force_cloud_prefix": None, "circuit_breaker": "closed"},
            "rule_outputs": {"utility_local": -0.27, "utility_cloud": 0.70, "margin": 0.97},
            "target": {"provider": "anthropic", "model": "claude-opus-4-7",
                       "endpoint": "https://api.anthropic.com/v1/messages",
                       "model_tier": "frontier"},
            "rationale_human": "utility_cloud > utility_local; no force prefix; cb closed.",
        },
    })

    # late: outcome.verify
    logger.emit({
        "event_type": "outcome.verify",
        "parent_event_id": dec_id,
        "context": build_context(
            session_id="test-session", project_id="agent-manifesto",
            turn_id=1,
        ),
        "outcome": {
            "horizon": "late",
            "subsequent_verify": {"status": "PASS", "findings_count": 0, "addressable": 0},
        },
    })

    path = next(tmp.glob("decisions-*.jsonl"))
    lines = path.read_text().splitlines()
    assert len(lines) == 4, f"expected 4 events got {len(lines)}"
    for line in lines:
        event = json.loads(line)
        assert event["schema_version"] == SCHEMA_VERSION
        assert "event_id" in event
        assert "context" in event
        assert event["provenance"]["logger_version"] == LOGGER_VERSION

    # Check parent chain
    events = [json.loads(l) for l in lines]
    assert events[1]["parent_event_id"] == events[0]["event_id"]
    assert events[2]["parent_event_id"] == events[1]["event_id"]
    assert events[3]["parent_event_id"] == events[2]["event_id"]

    print(f"PASS decision_logger self-test ({path})")
    print(f"  events: {len(lines)}")
    print(f"  bytes: {path.stat().st_size}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return _self_test()
    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

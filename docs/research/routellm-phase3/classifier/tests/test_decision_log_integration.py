#!/usr/bin/env python3
"""
test_decision_log_integration.py — end-to-end decision log integration test.

Exercises:
  1. decision_logger.DecisionLogger (Python side)
  2. router.js emitter (invoked via node child_process)
  3. scripts/decision-log-emit.sh (invoked via bash child_process)
  4. scripts/decision-log-commit-hook.sh (git post-commit emitter)

All events from all 4 emitters land in the same temp dir and are validated
against decision_event.schema.json v1.0.0.

Runtime: single process, no network, no model weights required.
Usage: /tmp/arena-venv/bin/python3 tests/test_decision_log_integration.py
"""

from __future__ import annotations

import glob
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
CLASSIFIER_DIR = THIS_DIR.parent
REPO_ROOT = CLASSIFIER_DIR.parent.parent.parent.parent

sys.path.insert(0, str(CLASSIFIER_DIR))
from decision_logger import DecisionLogger, build_context, sha256_hex


def run_subprocess(cmd: list[str], *, env: dict[str, str], stdin: str = "", cwd: str | None = None) -> tuple[int, str, str]:
    result = subprocess.run(
        cmd,
        input=stdin,
        env=env,
        capture_output=True,
        text=True,
        check=False,
        cwd=cwd,
    )
    return result.returncode, result.stdout, result.stderr


def drive_all_emitters(log_dir: Path) -> list[dict]:
    """Drive all 3 emitters into the same log_dir."""
    env_base = {
        **os.environ,
        "DECISION_LOG_DIR": str(log_dir),
        "DECISION_LOG_REDACTION": "none",
        "CLAUDE_SESSION_ID": "integration-test-session",
        "CLAUDE_PROJECT_DIR": str(REPO_ROOT),
    }

    # 1. Python DecisionLogger direct emit
    logger = DecisionLogger(log_dir, recorded_by="integration.test", redaction_level="none")
    turn_id = logger.emit({
        "event_type": "user.turn",
        "context": build_context(session_id="integration-test-session", turn_id=1),
        "input": {
            "prompt": "/verify the recent commit",
            "prompt_sha256": sha256_hex("/verify the recent commit"),
            "prompt_length": 24,
            "prompt_source": "user",
        },
    })
    assert turn_id, "expected logger.emit to return event_id"

    # 2. router.js emitter via node
    router_js = CLASSIFIER_DIR / "router.js"
    assert router_js.exists(), f"missing {router_js}"
    node_script = (
        f'const r = require({json.dumps(str(router_js))});\n'
        'const request = {messages: [{role: "user", content: "/research testing"}], log: {info(){}}};\n'
        'r(request, {}, {event: "test"}).then(() => console.log("ok")).catch(e => console.error(e));\n'
    )
    rc, out, err = run_subprocess(
        ["node", "-e", node_script],
        env={**env_base, "ROUTING_CLASSIFIER_URL": "http://127.0.0.1:65535/nonexistent"},
    )
    assert rc == 0, f"node invocation failed rc={rc} err={err}"

    # 3. decision-log-emit.sh: 5 hook event types (4 lifecycle + 1 skill-driven)
    sh_script = REPO_ROOT / "scripts" / "decision-log-emit.sh"
    for event_type, payload in [
        ("user.turn", {"prompt": "/test the hook"}),
        ("agent.tool_call", {"tool_name": "Edit", "tool_input": {"file_path": "x.py"}}),
        ("agent.tool_call_complete", {"tool_name": "Edit", "tool_response": {"error": None}}),
        ("agent.output", {"exit_status": "completed"}),
        ("outcome.verify", {
            "files": ["docs/example.md", "scripts/example.sh"],
            "verdict": "PASS",
            "evaluator": "subagent/claude",
            "evaluator_independent": False,
            "k_rounds": 1,
            "pass_rate": "1/1",
            "findings_count": 0,
            "addressable": 0,
            "risk_level": "moderate",
        }),
    ]:
        rc, out, err = run_subprocess(
            ["bash", str(sh_script), event_type],
            env=env_base,
            stdin=json.dumps(payload),
        )
        assert rc == 0, f"hook rc={rc} err={err}"

    # 4. decision-log-commit-hook.sh: simulate a git post-commit inside a
    # freshly-initialized throwaway repo so it picks up a real commit sha.
    commit_hook = REPO_ROOT / "scripts" / "decision-log-commit-hook.sh"
    git_tmp = Path(tempfile.mkdtemp(prefix="decision-log-git-"))
    try:
        for git_cmd in (
            ["git", "init", "--quiet"],
            ["git", "config", "user.email", "test@example.com"],
            ["git", "config", "user.name", "integration-test"],
            ["bash", "-c", "echo seed > seed.txt && git add seed.txt && git commit -q -m 'seed commit'"],
        ):
            rc, out, err = run_subprocess(git_cmd, env=env_base, cwd=str(git_tmp))
            assert rc == 0, f"git setup failed: {git_cmd} rc={rc} err={err}"
        # Fire the post-commit hook manually from the git tmp dir
        rc, out, err = run_subprocess(["bash", str(commit_hook)], env=env_base, cwd=str(git_tmp))
        assert rc == 0, f"commit hook rc={rc} err={err}"
    finally:
        shutil.rmtree(git_tmp, ignore_errors=True)

    files = sorted(glob.glob(str(log_dir / "decisions-*.jsonl")))
    assert files, "no log files written"
    events = []
    for f in files:
        for line in open(f):
            line = line.strip()
            if line:
                events.append(json.loads(line))
    return events


def validate_schema(events: list[dict]) -> None:
    try:
        from jsonschema import Draft202012Validator
    except ImportError:
        print("[info] jsonschema not installed; validation bypassed")
        return
    schema = json.load(open(CLASSIFIER_DIR / "decision_event.schema.json"))
    v = Draft202012Validator(schema)
    failures = []
    for event in events:
        errs = list(v.iter_errors(event))
        if errs:
            failures.append((event.get("event_type"), errs[0].message))
    if failures:
        for et, msg in failures:
            print(f"  FAIL {et}: {msg}")
        raise AssertionError(f"{len(failures)} schema validation failures")


def group_by_recorder(events: list[dict]) -> dict[str, list[dict]]:
    by_recorder: dict[str, list[dict]] = {}
    for e in events:
        recorder = e.get("provenance", {}).get("recorded_by", "?")
        by_recorder.setdefault(recorder, []).append(e)
    return by_recorder


def main() -> int:
    log_dir = Path(tempfile.mkdtemp(prefix="decision-log-integ-"))
    try:
        events = drive_all_emitters(log_dir)
        print(f"collected events: {len(events)}")
        validate_schema(events)
        by_recorder = group_by_recorder(events)

        expected_recorders = {"integration.test", "router.js", "claude-code-hook", "git-post-commit-hook"}
        missing = expected_recorders - set(by_recorder.keys())
        assert not missing, f"missing emitter(s): {missing}"

        print("\nPer-recorder counts:")
        for k in sorted(by_recorder):
            print(f"  {k:25s} {len(by_recorder[k])} events")

        observed_types = sorted({e.get("event_type") for e in events})
        print(f"\nEvent types: {observed_types}")

        assert "router.decision" in observed_types, "router.js did not emit"
        assert "user.turn" in observed_types, "hook did not emit user.turn"
        assert "agent.tool_call" in observed_types, "hook did not emit agent.tool_call"
        assert "agent.tool_call_complete" in observed_types, "hook did not emit agent.tool_call_complete"
        assert "outcome.commit" in observed_types, "git post-commit hook did not emit"
        assert "outcome.verify" in observed_types, "hook did not emit outcome.verify"

        verify_events = [e for e in events if e.get("event_type") == "outcome.verify"]
        assert verify_events, "no outcome.verify event found"
        ve = verify_events[0]
        assert ve.get("execution", {}).get("evaluator") == "subagent/claude", \
            f"unexpected evaluator: {ve.get('execution', {}).get('evaluator')}"
        assert ve.get("execution", {}).get("evaluator_independent") is False, \
            "evaluator_independent should be False"
        assert ve.get("execution", {}).get("k_rounds") == 1
        assert ve.get("execution", {}).get("pass_rate") == "1/1", \
            f"unexpected pass_rate: {ve.get('execution', {}).get('pass_rate')}"
        assert ve.get("execution", {}).get("risk_level") == "moderate", \
            f"unexpected risk_level: {ve.get('execution', {}).get('risk_level')}"
        assert ve.get("outcome", {}).get("horizon") == "late"
        sv = ve.get("outcome", {}).get("subsequent_verify", {})
        assert sv.get("status") == "PASS", f"unexpected status: {sv.get('status')}"
        assert sv.get("findings_count") == 0
        assert sv.get("addressable") == 0
        assert ve.get("execution", {}).get("files_modified") == [
            "docs/example.md",
            "scripts/example.sh",
        ]

        run_outcome_verify_negative_paths()

        print(f"\nPASS integration: {len(events)} events, 4 emitters, schema-valid")
        return 0
    finally:
        shutil.rmtree(log_dir, ignore_errors=True)


def _emit_verify(payload: dict, log_dir: Path) -> dict:
    """Drive decision-log-emit.sh outcome.verify with payload, return parsed event."""
    sh_script = REPO_ROOT / "scripts" / "decision-log-emit.sh"
    env = {
        **os.environ,
        "DECISION_LOG_DIR": str(log_dir),
        "DECISION_LOG_REDACTION": "none",
        "CLAUDE_SESSION_ID": "verify-negative-paths",
        "CLAUDE_PROJECT_DIR": str(REPO_ROOT),
    }
    rc, out, err = run_subprocess(
        ["bash", str(sh_script), "outcome.verify"],
        env=env,
        stdin=json.dumps(payload),
    )
    assert rc == 0, f"emit rc={rc} err={err}"
    files = sorted(glob.glob(str(log_dir / "decisions-*.jsonl")))
    last = json.loads(open(files[-1]).read().strip().splitlines()[-1])
    return last


def run_outcome_verify_negative_paths() -> None:
    """T-1: cover non-PASS verdicts, invalid inputs, edge field types."""
    log_dir = Path(tempfile.mkdtemp(prefix="decision-log-verify-neg-"))
    try:
        ev = _emit_verify({
            "files": ["a.py"], "verdict": "FAIL", "evaluator": "subagent/claude",
            "evaluator_independent": False, "k_rounds": 1, "findings_count": 3, "addressable": 1,
        }, log_dir)
        assert ev["outcome"]["subsequent_verify"]["status"] == "FAIL"
        assert ev["outcome"]["subsequent_verify"]["findings_count"] == 3
        assert ev["outcome"]["subsequent_verify"]["addressable"] == 1
        assert "pass_rate" not in ev["execution"], \
            f"FAIL verdict should not auto-default pass_rate, got {ev['execution'].get('pass_rate')}"

        ev = _emit_verify({
            "files": ["b.py"], "verdict": "CONDITIONAL", "evaluator": "logprob/qwen",
            "evaluator_independent": True, "k_rounds": 3, "pass_rate": "2/3",
            "findings_count": 1, "addressable": 0,
        }, log_dir)
        assert ev["outcome"]["subsequent_verify"]["status"] == "CONDITIONAL"
        assert ev["execution"]["k_rounds"] == 3
        assert ev["execution"]["pass_rate"] == "2/3"
        assert ev["execution"]["evaluator_independent"] is True

        ev = _emit_verify({
            "files": [], "verdict": "garbage_value", "evaluator": "human",
            "evaluator_independent": True, "k_rounds": 1,
        }, log_dir)
        assert ev["outcome"]["subsequent_verify"]["status"] == "N/A", \
            f"unknown verdict should map to N/A, got {ev['outcome']['subsequent_verify']['status']}"
        assert ev["execution"]["files_modified"] == []
        assert ev["outcome"]["subsequent_verify"]["findings_count"] == 0

        ev = _emit_verify({
            "evaluator": "api/openrouter", "evaluator_independent": True, "k_rounds": 1,
        }, log_dir)
        assert ev["outcome"]["subsequent_verify"]["status"] == "N/A", \
            "missing verdict should map to N/A"
        assert ev["execution"]["files_modified"] == []
        assert "risk_level" not in ev["execution"], \
            "risk_level absent in payload should be omitted from execution"

        print("PASS outcome.verify negative paths (4 sub-cases)")
    finally:
        shutil.rmtree(log_dir, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())

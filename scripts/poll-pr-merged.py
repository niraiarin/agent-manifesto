#!/usr/bin/env python3
"""
poll-pr-merged.py — emit `outcome.pr_merged` decision events for newly-merged PRs.

For each PR that merged since the last poll:
  1. Try to find the originating `outcome.commit` event in the decision log
     (parent_event_id) by joining on:
        (a) PR commits API → match SHA against `outcome.commit.git_commit_hash`
        (b) commit_subject regex `(#NNN)` → match PR number, fallback
  2. Emit `outcome.pr_merged` with parent_event_id (or null when not found).
  3. Persist the PR number in state file to ensure idempotency.

Cutoff: PRs merged before the first decision log file (`decisions-YYYY-MM-DD.jsonl`)
are skipped — backfill is intentionally not done because the parent
`outcome.commit` events do not exist for older PRs.

State file: `<log_dir>/.pr-poll-state.json`
  {
    "schema_version": "1.0.0",
    "last_polled_at": "2026-04-25T17:00:00Z",
    "seen_pr_numbers": [675, 679, 680, 681, 682, 683, 684]
  }

Best-effort: any subprocess / network failure is logged to stderr; the script
exits 0 to keep cron silent. Set DECISION_LOG_POLL_DEBUG=1 for verbose logs.

Usage (manual / from cron):
  python3 scripts/poll-pr-merged.py [--repo OWNER/REPO] [--limit N] [--dry-run]

Cron (1h cadence, recommended):
  5 * * * * cd /path/to/agent-manifesto && python3 scripts/poll-pr-merged.py
"""

from __future__ import annotations

import argparse
import gzip
import json
import os
import re
import subprocess
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Optional


PR_NUMBER_RE = re.compile(r"\(#(\d+)\)")
DEFAULT_LIMIT = 30


def log(message: str) -> None:
    if os.environ.get("DECISION_LOG_POLL_DEBUG") == "1":
        print(f"[poll-pr-merged] {message}", file=sys.stderr)


def repo_root() -> Path:
    env = os.environ.get("CLAUDE_PROJECT_DIR")
    if env:
        return Path(env).resolve()
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL
        ).decode().strip()
        return Path(out)
    except Exception:
        return Path.cwd()


def detect_repo_slug() -> Optional[str]:
    """Return 'owner/repo' from gh remote, or None on failure."""
    try:
        out = subprocess.check_output(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
        return out or None
    except Exception:
        return None


def gh_api(path: str, paginate: bool = False) -> Optional[list | dict]:
    """Call `gh api <path>`, return parsed JSON or None on failure.

    paginate=False: single request (recent-N usage). paginate=True: follow
    Link headers (only for joins like PR commits where total may exceed
    per_page). Avoid paginate for closed-PR list — we only care about
    recently-updated PRs above the cutoff.
    """
    cmd = ["gh", "api", path]
    if paginate:
        cmd.append("--paginate")
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.PIPE).decode()
    except subprocess.CalledProcessError as e:
        log(f"gh api {path} failed: {e.stderr.decode(errors='ignore')[:200]}")
        return None
    out = out.strip()
    if not out:
        return None
    if out.startswith("["):
        return json.loads(out)
    if out.startswith("{"):
        return json.loads(out)
    parts = []
    for line in out.splitlines():
        line = line.strip()
        if line:
            parts.append(json.loads(line))
    return parts


def list_recently_closed_prs(repo: str, limit: int) -> list[dict]:
    """Fetch the N most-recently-updated closed PRs (single API call, no pagination)."""
    per_page = max(1, min(limit, 100))
    data = gh_api(
        f"repos/{repo}/pulls?state=closed&base=main&sort=updated&direction=desc&per_page={per_page}",
        paginate=False,
    )
    if isinstance(data, list):
        return [item for item in data if isinstance(item, dict)]
    return []


def list_pr_commit_shas(repo: str, pr_number: int) -> list[str]:
    """Fetch all commits on a PR (paginated when commit count > 100)."""
    data = gh_api(f"repos/{repo}/pulls/{pr_number}/commits?per_page=100", paginate=True)
    if not isinstance(data, list):
        return []
    shas: list[str] = []
    for entry in data:
        if isinstance(entry, list):
            for c in entry:
                if isinstance(c, dict) and "sha" in c:
                    shas.append(c["sha"])
        elif isinstance(entry, dict) and "sha" in entry:
            shas.append(entry["sha"])
    return shas


def open_log_file(path: Path):
    if path.suffix == ".gz":
        return gzip.open(path, "rt", encoding="utf-8")
    return open(path, "r", encoding="utf-8")


def iter_decision_logs(log_dir: Path) -> Iterable[Path]:
    if not log_dir.is_dir():
        return []
    yield from sorted(log_dir.glob("decisions-*.jsonl"))
    yield from sorted(log_dir.glob("decisions-*.jsonl.gz"))


def index_outcome_commits(log_dir: Path) -> tuple[dict[str, str], dict[int, str]]:
    """
    Returns:
      sha_to_event_id: {git_commit_hash: event_id}
      pr_to_event_id:  {pr_number: event_id}  via subject regex
    """
    sha_to_event_id: dict[str, str] = {}
    pr_to_event_id: dict[int, str] = {}
    for path in iter_decision_logs(log_dir):
        try:
            with open_log_file(path) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        event = json.loads(line)
                    except Exception:
                        continue
                    if event.get("event_type") != "outcome.commit":
                        continue
                    event_id = event.get("event_id")
                    if not event_id:
                        continue
                    outcome = event.get("outcome") or {}
                    sha = outcome.get("git_commit_hash")
                    if sha:
                        sha_to_event_id.setdefault(sha, event_id)
                    subject = outcome.get("commit_subject") or ""
                    for match in PR_NUMBER_RE.finditer(subject):
                        try:
                            n = int(match.group(1))
                            pr_to_event_id.setdefault(n, event_id)
                        except ValueError:
                            continue
        except OSError as exc:
            log(f"failed to read {path}: {exc}")
    return sha_to_event_id, pr_to_event_id


def determine_cutoff(log_dir: Path) -> Optional[datetime]:
    """The first decision log file's date defines the backfill cutoff."""
    first: Optional[Path] = None
    for path in sorted(log_dir.glob("decisions-*.jsonl*")):
        first = path
        break
    if first is None:
        return None
    name = first.name
    match = re.match(r"decisions-(\d{4})-(\d{2})-(\d{2})", name)
    if not match:
        return None
    y, m, d = (int(x) for x in match.groups())
    return datetime(y, m, d, tzinfo=timezone.utc)


def load_state(state_path: Path) -> dict:
    if not state_path.exists():
        return {"schema_version": "1.0.0", "last_polled_at": None, "seen_pr_numbers": []}
    try:
        with open(state_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return {"schema_version": "1.0.0", "last_polled_at": None, "seen_pr_numbers": []}
        data.setdefault("schema_version", "1.0.0")
        data.setdefault("last_polled_at", None)
        seen = data.setdefault("seen_pr_numbers", [])
        if not isinstance(seen, list):
            data["seen_pr_numbers"] = []
        return data
    except Exception as exc:
        log(f"failed to load state {state_path}: {exc}")
        return {"schema_version": "1.0.0", "last_polled_at": None, "seen_pr_numbers": []}


def save_state(state_path: Path, state: dict) -> None:
    state_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = state_path.with_suffix(state_path.suffix + ".tmp")
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2, sort_keys=True)
    tmp_path.replace(state_path)


def emit_pr_merged(
    repo_root_path: Path,
    log_dir: Path,
    payload: dict,
) -> bool:
    """Pipe payload into decision-log-emit.sh outcome.pr_merged. Return True if emit script returned 0."""
    emit_script = repo_root_path / "scripts" / "decision-log-emit.sh"
    if not emit_script.exists():
        log(f"emit script not found: {emit_script}")
        return False
    env = {
        **os.environ,
        "DECISION_LOG_DIR": str(log_dir),
        "CLAUDE_PROJECT_DIR": str(repo_root_path),
    }
    # Only set DECISION_LOG_PARENT_ID when non-null so the emit script's
    # `payload or env` chain falls through to None (preserves schema-valid null).
    parent_id = payload.get("parent_event_id")
    if parent_id:
        env["DECISION_LOG_PARENT_ID"] = parent_id
    try:
        result = subprocess.run(
            ["bash", str(emit_script), "outcome.pr_merged"],
            input=json.dumps(payload),
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            log(f"emit failed rc={result.returncode}: {result.stderr[:200]}")
            return False
        return True
    except Exception as exc:
        log(f"emit subprocess error: {exc}")
        return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    parser.add_argument("--repo", help="owner/repo (default: gh detect)")
    parser.add_argument(
        "--log-dir",
        type=Path,
        default=None,
        help="decision log directory (default: <repo>/docs/research/routellm-phase3/logs)",
    )
    parser.add_argument(
        "--limit", type=int, default=DEFAULT_LIMIT,
        help=f"max PRs to fetch per poll (default: {DEFAULT_LIMIT})",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="do not emit events or update state",
    )
    args = parser.parse_args()

    root = repo_root()
    log_dir = args.log_dir or root / "docs" / "research" / "routellm-phase3" / "logs"
    log(f"repo_root={root}, log_dir={log_dir}")

    repo = args.repo or detect_repo_slug()
    if not repo:
        print("error: could not detect repo (use --repo OWNER/REPO)", file=sys.stderr)
        return 0

    cutoff = determine_cutoff(log_dir)
    if cutoff is None:
        log("no decision log files yet; skipping (cutoff undefined)")
        return 0
    log(f"cutoff={cutoff.isoformat()}")

    state_path = log_dir / ".pr-poll-state.json"
    state = load_state(state_path)
    seen: set[int] = set(state.get("seen_pr_numbers") or [])

    sha_to_event_id, pr_to_event_id = index_outcome_commits(log_dir)
    log(f"indexed {len(sha_to_event_id)} commit SHAs, {len(pr_to_event_id)} PR-tagged commits")

    prs = list_recently_closed_prs(repo, args.limit)
    log(f"fetched {len(prs)} closed PRs from {repo}")

    emitted = 0
    skipped_old = 0
    skipped_seen = 0
    no_parent = 0
    for pr in prs:
        if not isinstance(pr, dict):
            continue
        merged_at = pr.get("merged_at")
        if not merged_at:
            continue
        pr_number = pr.get("number")
        if pr_number is None:
            continue
        try:
            pr_number = int(pr_number)
        except Exception:
            continue
        try:
            merged_dt = datetime.strptime(merged_at, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        except ValueError:
            try:
                merged_dt = datetime.fromisoformat(merged_at.replace("Z", "+00:00"))
            except Exception:
                continue
        if merged_dt < cutoff:
            skipped_old += 1
            continue
        if pr_number in seen:
            skipped_seen += 1
            continue

        merge_commit_sha = pr.get("merge_commit_sha")
        head_sha = (pr.get("head") or {}).get("sha")
        base_ref = (pr.get("base") or {}).get("ref") or "main"
        pr_title = pr.get("title")

        # Resolve parent_event_id by joining the PR against `outcome.commit` events.
        # The local git post-commit hook records `outcome.commit` for feature-branch
        # commits BEFORE push (so `sha_to_event_id` typically holds feature-branch
        # SHAs, not the squash-merge SHA on main). Strategies, in priority order:
        #   1. merge_commit_sha — covers merge-commit / rebase-merge cases where the
        #      hook fired for the merge SHA locally (e.g. main worktree pulled it).
        #   2. PR commits API (feature-branch SHAs) — primary for squash-merge.
        #   3. (#NNN) regex fallback in commit_subject — last resort if subject
        #      already carried the PR number.
        parent_event_id: Optional[str] = None
        if merge_commit_sha and merge_commit_sha in sha_to_event_id:
            parent_event_id = sha_to_event_id[merge_commit_sha]
        if not parent_event_id:
            for sha in list_pr_commit_shas(repo, pr_number):
                if sha in sha_to_event_id:
                    parent_event_id = sha_to_event_id[sha]
                    break
        if not parent_event_id and pr_number in pr_to_event_id:
            parent_event_id = pr_to_event_id[pr_number]

        if not parent_event_id:
            no_parent += 1

        payload = {
            "pr_number": pr_number,
            "merge_commit_sha": merge_commit_sha,
            "pr_title": pr_title,
            "merged_at_utc": merged_at,
            "head_sha": head_sha,
            "base_branch": base_ref,
            "parent_event_id": parent_event_id,
        }

        if args.dry_run:
            print(f"[dry-run] would emit: PR #{pr_number} (parent={parent_event_id or 'null'})")
        else:
            if emit_pr_merged(root, log_dir, payload):
                emitted += 1
                seen.add(pr_number)

    if not args.dry_run:
        state["last_polled_at"] = (
            datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        )
        state["seen_pr_numbers"] = sorted(seen)
        save_state(state_path, state)

    print(
        f"poll-pr-merged: emitted={emitted} seen={len(seen)} "
        f"skipped_old={skipped_old} skipped_seen={skipped_seen} no_parent={no_parent}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

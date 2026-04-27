#!/usr/bin/env bash
# decision-log-commit-hook.sh — Git post-commit hook that emits outcome.commit.
#
# Installs into .git/hooks/post-commit (symlink or copy). For worktrees,
# install into the main repo's .git/hooks/ so all worktrees share.
#
# Install (idempotent):
#   bash scripts/install-decision-log-hooks.sh
#
# Environment overrides:
#   DECISION_LOG_DIR        — destination dir (default: <repo>/docs/research/routellm-phase3/logs)
#   DECISION_LOG_REDACTION  — "none" | "prompt_sha_only" (default: prompt_sha_only)
#   DECISION_LOG_PARENT_ID  — parent event to link to (if Claude Code session id
#                              tracking is in place; otherwise null)
#
# Best-effort: any failure is logged to stderr and exit 0 is returned so git
# commit is never blocked.

set -u

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  exit 0
fi

LOG_DIR="${DECISION_LOG_DIR:-$REPO_ROOT/docs/research/routellm-phase3/logs}"
REDACTION="${DECISION_LOG_REDACTION:-prompt_sha_only}"

mkdir -p "$LOG_DIR" 2>/dev/null || true
DATE=$(date -u +%Y-%m-%d)
LOG_FILE="$LOG_DIR/decisions-$DATE.jsonl"

COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null)
COMMIT_SUBJECT=$(git log -1 --pretty=%s 2>/dev/null)
COMMIT_AUTHOR=$(git log -1 --pretty=%an 2>/dev/null)
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
GIT_WORKTREE=$([ "$(git rev-parse --git-dir)" != "$REPO_ROOT/.git" ] && echo "true" || echo "false")

CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | tr '\n' ' ')

DECISION_LOG_COMMIT_SHA="$COMMIT_SHA" \
DECISION_LOG_COMMIT_SUBJECT="$COMMIT_SUBJECT" \
DECISION_LOG_COMMIT_AUTHOR="$COMMIT_AUTHOR" \
DECISION_LOG_BRANCH="$BRANCH" \
DECISION_LOG_GIT_WORKTREE="$GIT_WORKTREE" \
DECISION_LOG_CHANGED_FILES="$CHANGED_FILES" \
DECISION_LOG_PARENT_ID="${DECISION_LOG_PARENT_ID:-}" \
DECISION_LOG_REPO_ROOT="$REPO_ROOT" \
python3 -c "$(cat <<'PY'
import hashlib
import json
import os
import sys
import uuid
from datetime import datetime, timezone

log_file, redaction = sys.argv[1], sys.argv[2]
commit_sha = os.environ.get("DECISION_LOG_COMMIT_SHA", "")
if not commit_sha:
    sys.exit(0)

commit_subject = os.environ.get("DECISION_LOG_COMMIT_SUBJECT", "")
commit_author = os.environ.get("DECISION_LOG_COMMIT_AUTHOR", "")
branch = os.environ.get("DECISION_LOG_BRANCH", "")
git_worktree = os.environ.get("DECISION_LOG_GIT_WORKTREE", "false") == "true"
changed_files = [f for f in os.environ.get("DECISION_LOG_CHANGED_FILES", "").split() if f]
parent_id = os.environ.get("DECISION_LOG_PARENT_ID") or None
session_id = (
    os.environ.get("CLAUDE_SESSION_ID")
    or os.environ.get("DECISION_LOG_SESSION_ID")
    or f"git-post-commit-{commit_sha[:16]}"
)
project_path = os.environ.get("DECISION_LOG_REPO_ROOT", os.getcwd())

envelope = {
    "schema_version": "1.0.0",
    "event_id": str(uuid.uuid4()),
    "parent_event_id": parent_id,
    "event_type": "outcome.commit",
    "timestamp_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "context": {
        "session_id": session_id,
        "project_id": os.environ.get("DECISION_LOG_PROJECT_ID", "agent-manifesto"),
        "project_path": project_path,
        "git_branch": branch,
        "git_commit_sha": commit_sha,
        "git_worktree": git_worktree,
    },
    "execution": {
        "files_modified": changed_files,
    },
    "outcome": {
        "horizon": "late",
        "git_commit_hash": commit_sha,
    },
    "provenance": {
        "schema_version": "1.0.0",
        "logger_version": "1.0.0",
        "recorded_by": "git-post-commit-hook",
        "hook_id": "post-commit.decision-log-emit",
        "redaction_level": redaction,
    },
}
if commit_subject:
    envelope["outcome"]["commit_subject"] = commit_subject
if commit_author:
    envelope["outcome"]["commit_author"] = commit_author

try:
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(json.dumps(envelope, ensure_ascii=False, separators=(",", ":")) + "\n")
except OSError as exc:
    print(f"[decision-log-commit-hook] write failure: {exc}", file=sys.stderr)
PY
)" "$LOG_FILE" "$REDACTION" >/dev/null 2>&1

exit 0

#!/usr/bin/env bash
# Setup script: add SessionStart hook for pwd/branch/worktree context check.
# Addresses #571 (CLAUDE.MD-ONLY item #1).
#
# Creates:
#   - .claude/hooks/session-context-check.sh (hook body)
#   - appends entry to .claude/settings.json SessionStart hooks array
#
# Execute manually (L1: governance config requires human approval):
#   bash scripts/setup-session-context-hook.sh

set -euo pipefail

REPO="$(git rev-parse --show-toplevel)"
HOOK_DIR="$REPO/.claude/hooks"
HOOK_FILE="$HOOK_DIR/session-context-check.sh"
SETTINGS="$REPO/.claude/settings.json"

if [ -f "$HOOK_FILE" ]; then
  echo "ERROR: $HOOK_FILE already exists. Aborting."
  exit 1
fi

# --- 1. write hook body ---
cat > "$HOOK_FILE" <<'HOOK_EOF'
#!/usr/bin/env bash
# @traces D1, T2
# Session start: emit pwd / git branch / worktree count as additional context.
# Structurally enforces CLAUDE.md session startup check (D1).

set -uo pipefail

PWD_VAL=$(pwd)
BRANCH=$(git branch --show-current 2>/dev/null || echo "not-a-repo")
WORKTREE_COUNT=$(git worktree list 2>/dev/null | wc -l | tr -d ' ')

echo "[session] pwd=$PWD_VAL"
echo "[session] branch=$BRANCH"
if [ "$WORKTREE_COUNT" -gt 0 ] 2>/dev/null; then
  echo "[session] worktrees=$WORKTREE_COUNT"
fi

# Traceability:
# D1: 構造的強制 — セッション開始時の位置確認を hook で保証
# T2: 構造永続性 — 確認事項を LLM 判断ではなく構造が提供
HOOK_EOF

chmod +x "$HOOK_FILE"
echo "Created: $HOOK_FILE"

# --- 2. register in settings.json ---
# Append {"type":"command","command":"bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-context-check.sh"}
# to the first SessionStart entry's hooks array.
python3 - <<PY_EOF
import json, sys
from pathlib import Path
p = Path("$SETTINGS")
d = json.loads(p.read_text())
hooks = d.setdefault("hooks", {})
session_start = hooks.setdefault("SessionStart", [])
if not session_start:
    session_start.append({"matcher": "", "hooks": []})
entry = session_start[0].setdefault("hooks", [])
cmd = "bash \$CLAUDE_PROJECT_DIR/.claude/hooks/session-context-check.sh"
if any(h.get("command") == cmd for h in entry):
    print(f"Already registered in {p}")
    sys.exit(0)
entry.append({"type": "command", "command": cmd})
p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print(f"Registered hook in {p}")
PY_EOF

# --- 3. verify ---
echo ""
echo "Verification:"
ls -l "$HOOK_FILE"
echo "---"
python3 -c "
import json
with open('$SETTINGS') as f:
    d = json.load(f)
for e in d.get('hooks', {}).get('SessionStart', []):
    for h in e.get('hooks', []):
        print('  ', h.get('command'))
"
echo ""
echo "Done. Start a new Claude Code session to see [session] pwd/branch/worktrees in additional context."

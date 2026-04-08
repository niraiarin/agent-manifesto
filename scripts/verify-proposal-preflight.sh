#!/usr/bin/env bash
# verify-proposal-preflight.sh — 改善案の決定論的事前検証
#
# Hypothesizer チェックリスト A-D, F の決定論的部分をスクリプト化。
# E（概念の妥当性）は judgmental のため対象外。
#
# Usage:
#   echo '<proposal_json>' | bash scripts/verify-proposal-preflight.sh
#   bash scripts/verify-proposal-preflight.sh --file proposal.json
#
# Input JSON format:
#   {
#     "title": "Proposal title",
#     "target_files": ["path/to/file1", "path/to/file2"],
#     "lean_names": ["theorem_name", "def_name"],
#     "proposed_names": ["new_theorem_name"],
#     "grep_patterns": ["pattern to check duplicates"]
#   }
#
# Output: JSON verification result
# Exit: 0 = all pass, 1 = some checks failed
#
# G2 (#233) / Parent: #230

set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
LEAN_DIR="$BASE/lean-formalization"
HISTORY="$BASE/.claude/metrics/evolve-history.jsonl"

# --- Read input ---
if [[ "${1:-}" == "--file" ]]; then
  INPUT=$(cat "$2")
elif [[ -t 0 ]]; then
  echo '{"error": "No input. Pipe JSON or use --file"}' >&2
  exit 2
else
  INPUT=$(cat)
fi

# Validate JSON
if ! echo "$INPUT" | jq . >/dev/null 2>&1; then
  echo '{"error": "Invalid JSON input"}' >&2
  exit 2
fi

# --- Run all checks via Python for robust JSON handling ---
export BASE
export PROPOSAL_INPUT="$INPUT"
python3 << 'PYEOF'
import json, sys, os, subprocess, re

base = os.environ.get("BASE", os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
lean_dir = os.path.join(base, "lean-formalization")
history_path = os.path.join(base, ".claude/metrics/evolve-history.jsonl")
input_json = os.environ.get("PROPOSAL_INPUT", "")

try:
    proposal = json.loads(input_json)
except Exception:
    print(json.dumps({"error": "Failed to parse proposal JSON"}))
    sys.exit(2)

results = {
    "title": proposal.get("title", ""),
    "checks": {},
    "summary": {"pass": 0, "fail": 0, "skip": 0}
}

def add_check(category, name, passed, detail=""):
    if category not in results["checks"]:
        results["checks"][category] = []
    status = "PASS" if passed else "FAIL"
    results["checks"][category].append({"name": name, "status": status, "detail": detail})
    if passed:
        results["summary"]["pass"] += 1
    else:
        results["summary"]["fail"] += 1

# --- A. File existence checks ---
target_files = proposal.get("target_files", [])
for f in target_files:
    path = f if os.path.isabs(f) else os.path.join(base, f)
    exists = os.path.exists(path)
    add_check("A_file_existence", f, exists,
              "exists" if exists else "NOT FOUND")

# --- B. Duplicate name checks ---
proposed_names = proposal.get("proposed_names", [])
for name in proposed_names:
    # Search in Lean files for existing definitions with same name
    found = False
    detail = ""
    try:
        result = subprocess.run(
            ["grep", "-rn", f"^\\(theorem\\|def\\|axiom\\|lemma\\|structure\\|class\\|inductive\\|opaque\\) {re.escape(name)}",
             os.path.join(lean_dir, "Manifest")],
            capture_output=True, text=True, timeout=10
        )
        if result.stdout.strip():
            found = True
            detail = result.stdout.strip().split("\n")[0][:120]
    except Exception as e:
        detail = f"grep error: {e}"

    add_check("B_duplicate_check", name, not found,
              f"no duplicate found" if not found else f"DUPLICATE: {detail}")

# Also check grep_patterns for broader duplicate detection
grep_patterns = proposal.get("grep_patterns", [])
for pattern in grep_patterns:
    found = False
    detail = ""
    try:
        result = subprocess.run(
            ["grep", "-rn", pattern, base,
             "--include=*.lean", "--include=*.md", "--include=*.sh"],
            capture_output=True, text=True, timeout=10
        )
        matches = [l for l in result.stdout.strip().split("\n") if l.strip()]
        if len(matches) > 0:
            found = True
            detail = f"{len(matches)} match(es): {matches[0][:100]}"
        else:
            detail = "no matches"
    except Exception as e:
        detail = f"grep error: {e}"

    add_check("B_grep_duplicate", pattern, not found, detail)

# --- C. Impact scope (count affected files for target patterns) ---
# For each target file, verify it actually contains content that would be changed
for f in target_files:
    path = f if os.path.isabs(f) else os.path.join(base, f)
    if os.path.exists(path):
        try:
            size = os.path.getsize(path)
            add_check("C_file_readable", f, True, f"{size} bytes")
        except Exception as e:
            add_check("C_file_readable", f, False, str(e))

# --- D. Past failure pattern matching ---
past_failures = []
if os.path.exists(history_path):
    title = proposal.get("title", "").lower()
    title_words = set(re.findall(r'\w+', title)) - {"the", "a", "an", "to", "of", "in", "for", "and", "or", "is"}

    with open(history_path) as f:
        for line in f:
            try:
                rec = json.loads(line.strip())
            except Exception:
                continue
            rejected = rec.get("rejected", [])
            if not isinstance(rejected, list):
                continue
            for rej in rejected:
                rej_title = (rej.get("title") or "").lower()
                rej_words = set(re.findall(r'\w+', rej_title))
                # Check for significant word overlap (>50% of proposal title words)
                if title_words and len(title_words & rej_words) > len(title_words) * 0.5:
                    past_failures.append({
                        "run": rec.get("run"),
                        "title": rej.get("title"),
                        "failure_type": rej.get("failure_type"),
                        "reason": (rej.get("reason") or "")[:150]
                    })

    # Check unresolved failure_type counts
    failure_type_counts = {}
    with open(history_path) as f:
        for line in f:
            try:
                rec = json.loads(line.strip())
            except Exception:
                continue
            for rej in (rec.get("rejected") or []):
                if not isinstance(rej, dict):
                    continue
                if rej.get("resolved"):
                    continue
                ft = rej.get("failure_type", "none")
                failure_type_counts[ft] = failure_type_counts.get(ft, 0) + 1

if past_failures:
    for pf in past_failures[:5]:
        add_check("D_past_failure", pf["title"][:80],
                  False,
                  f"Similar rejected proposal (Run {pf['run']}, type={pf['failure_type']}): {pf['reason']}")
else:
    add_check("D_past_failure", "no_similar_rejections", True, "No similar past failures found")

# Add failure_type summary
if os.path.exists(history_path):
    results["D_failure_type_summary"] = failure_type_counts

# --- F. Lean name validation ---
lean_names = proposal.get("lean_names", [])
for name in lean_names:
    found = False
    detail = ""
    manifest_dir = os.path.join(lean_dir, "Manifest")
    if os.path.isdir(manifest_dir):
        try:
            result = subprocess.run(
                ["grep", "-rn", f"\\b{re.escape(name)}\\b", manifest_dir,
                 "--include=*.lean"],
                capture_output=True, text=True, timeout=10
            )
            if result.stdout.strip():
                found = True
                first_match = result.stdout.strip().split("\n")[0]
                detail = first_match[:120]
        except Exception as e:
            detail = f"grep error: {e}"
    else:
        detail = f"Manifest dir not found: {manifest_dir}"

    add_check("F_lean_name", name, found,
              detail if found else f"NOT FOUND in Manifest/*.lean")

# --- Output ---
results["summary"]["total"] = results["summary"]["pass"] + results["summary"]["fail"]
results["verdict"] = "PASS" if results["summary"]["fail"] == 0 else "FAIL"
print(json.dumps(results, indent=2, ensure_ascii=False))
sys.exit(0 if results["summary"]["fail"] == 0 else 1)
PYEOF

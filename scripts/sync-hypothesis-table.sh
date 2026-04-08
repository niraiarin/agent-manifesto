#!/usr/bin/env bash
# sync-hypothesis-table.sh — SKILL.md 仮説テーブルの deterministic な数値を
# evolve-history.jsonl から自動同期する。
# 評価文言（"未反証", "支持傾向" 等）は judgmental であり、更新しない。
#
# Usage:
#   bash scripts/sync-hypothesis-table.sh [--dry-run]
#
# Options:
#   --dry-run   変更を適用せず差分のみ表示
#
# 依存: python3, jq
# G4 (#235) / Parent: #230

set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$BASE/.claude/skills/evolve/SKILL.md"
HISTORY="$BASE/.claude/metrics/evolve-history.jsonl"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

if [[ ! -f "$SKILL" ]]; then
  echo "ERROR: SKILL.md not found: $SKILL" >&2
  exit 1
fi
if [[ ! -f "$HISTORY" ]]; then
  echo "ERROR: evolve-history.jsonl not found: $HISTORY" >&2
  exit 1
fi

# --- Compute all deterministic stats from evolve-history.jsonl ---
UPDATED=$(python3 << 'PYEOF'
import json, re, sys, os

base = os.environ.get("BASE", ".")
skill_path = os.path.join(base, ".claude/skills/evolve/SKILL.md")
history_path = os.path.join(base, ".claude/metrics/evolve-history.jsonl")

# --- Parse evolve-history.jsonl ---
success = partial = observation = 0
ver_pass = ver_fail = 0
max_run = 0
ce = cc = bc = other = 0
costs = []
cpi_vals = []
total_improvements = 0

with open(history_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except Exception:
            continue

        # Run outcomes (H1)
        r = rec.get("result", "")
        if r == "success":
            success += 1
        elif r == "partial":
            partial += 1
        elif r == "observation":
            observation += 1

        # Max run number
        run = rec.get("run")
        if isinstance(run, (int, float)) and run > max_run:
            max_run = int(run)

        # Verifier stats (H1)
        vp = (rec.get("phases") or {}).get("verifier") or {}
        ver_pass += vp.get("pass_count") or 0
        ver_fail += vp.get("fail_count") or 0

        # Compatibility classes (H4)
        imps = rec.get("improvements", [])
        if isinstance(imps, list):
            total_improvements += len(imps)
            for imp in imps:
                compat = (imp.get("compatibility") or "").strip()
                if "conservative extension" in compat:
                    ce += 1
                elif "compatible change" in compat:
                    cc += 1
                elif "breaking change" in compat:
                    bc += 1
                else:
                    other += 1

        # Cost stats (H5/H6)
        cost = rec.get("cost") or {}
        if cost.get("session_cost_usd") is not None:
            costs.append(cost["session_cost_usd"])
            if cost.get("cost_per_improvement_usd") is not None:
                cpi_vals.append(cost["cost_per_improvement_usd"])

# Derived values
ver_total = ver_pass + ver_fail
ver_rate = (ver_pass * 100 // ver_total) if ver_total > 0 else 0
h4_total = ce + cc + bc + other
data_points = len(costs)
mean_cost = round(sum(costs) / len(costs), 2) if costs else 0
median_cost = round(sorted(costs)[len(costs) // 2], 2) if costs else 0
min_cost = round(min(costs), 2) if costs else 0
max_cost = round(max(costs), 2) if costs else 0
mean_cpi = round(sum(cpi_vals) / len(cpi_vals), 2) if cpi_vals else 0
median_cpi = round(sorted(cpi_vals)[len(cpi_vals) // 2], 2) if cpi_vals else 0
min_cpi = round(min(cpi_vals), 2) if cpi_vals else 0
max_cpi = round(max(cpi_vals), 2) if cpi_vals else 0

# --- Read and update SKILL.md ---
with open(skill_path) as f:
    content = f.read()

original = content

# Header: "N回実行データ、Run M で更新"
content = re.sub(
    r'\d+回実行データ、Run \d+ で更新',
    f'{max_run}回実行データ、Run {max_run} で更新',
    content
)

# H1: "N回 success / N回 partial / N回 observation"
content = re.sub(
    r'(\d+)回 success / (\d+)回 partial / (\d+)回 observation',
    f'{success}回 success / {partial}回 partial / {observation}回 observation',
    content
)

# H1: "全期間 N/N PASS（N%）"
content = re.sub(
    r'全期間 \d+/\d+ PASS（\d+%）',
    f'全期間 {ver_pass}/{ver_total} PASS（{ver_rate}%）',
    content
)

# H4: "全期間N改善統合（N conservative extension, N compatible change, N breaking change, N other）"
content = re.sub(
    r'全期間\d+改善統合（\d+ conservative extension, \d+ compatible change, \d+ breaking change, \d+ other）',
    f'全期間{h4_total}改善統合（{ce} conservative extension, {cc} compatible change, {bc} breaking change, {other} other）',
    content
)

# H5: data points count
content = re.sub(
    r'(\| H5:.*?未反証。)\d+ データポイント',
    lambda m: f'{m.group(1)}{data_points} データポイント',
    content
)

# H5: session cost stats "mean N USD, median N USD, range N-N USD"
content = re.sub(
    r'session cost: mean [\d.]+ USD, median [\d.]+ USD, range [\d.]+-[\d.]+ USD',
    f'session cost: mean {mean_cost} USD, median {median_cost} USD, range {min_cost}-{max_cost} USD',
    content
)

# H6: data points count
content = re.sub(
    r'(\| H6:.*?)\d+ データポイント',
    lambda m: f'{m.group(1)}{len(cpi_vals)} データポイント',
    content
)

# H6: "CPI mean N USD/improvement, median N USD"
content = re.sub(
    r'CPI mean [\d.]+ USD/improvement, median [\d.]+ USD \(range [\d.]+-[\d.]+ USD\)',
    f'CPI mean {mean_cpi} USD/improvement, median {median_cpi} USD (range {min_cpi}-{max_cpi} USD)',
    content
)

if content == original:
    print("NO_CHANGE")
else:
    print(content, end="")
PYEOF
)

if [[ "$UPDATED" == "NO_CHANGE" ]]; then
  echo "No changes needed — SKILL.md is already up to date."
  exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "--- Dry run: showing diff ---"
  diff <(cat "$SKILL") <(echo "$UPDATED") || true
  echo "--- End dry run ---"
else
  echo "$UPDATED" > "$SKILL"
  echo "SKILL.md hypothesis table updated successfully."
fi

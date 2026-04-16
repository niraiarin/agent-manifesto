#!/usr/bin/env bash
# evaluate.sh — Cloud vs Local の出力を評価する
#
# 新方式: run-comparison.sh が claude -p --output-format json で生成した出力を評価
#
# Usage:
#   bash evaluate.sh --run-id <run-id>
#   bash evaluate.sh --run-id M-interp-001 --judge-model claude
#
# 評価方法:
#   (a) judge 独立スコアリング: 各出力を GQM 基準で 1-5 スコア付け
#   (b) 機械的一致度: 構造化出力の一致を計測
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATASET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RUN_ID=""
TASK_TYPE=""
JUDGE_MODEL="claude"  # claude or ollama

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --task) TASK_TYPE="$2"; shift 2 ;;
    --judge-model) JUDGE_MODEL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$RUN_ID" ]; then
  echo "Usage: bash evaluate.sh --run-id <run-id> [--judge-model claude|ollama]"
  exit 1
fi

mkdir -p "$DATASET_DIR/evaluations"

# 出力ファイルの検出（複数 run 対応: RUN_ID.json or RUN_ID-run1.json）
find_output() {
  local label="$1"  # cloud or local
  local dir="$DATASET_DIR/outputs/${label}"
  # 単一 run
  if [ -f "$dir/${RUN_ID}.json" ]; then
    echo "$dir/${RUN_ID}.json"
    return
  fi
  # 複数 run — run1 を返す（majority vote は別途）
  if [ -f "$dir/${RUN_ID}-run1.json" ]; then
    echo "$dir/${RUN_ID}-run1.json"
    return
  fi
  echo ""
}

CLOUD_FILE=$(find_output "cloud")
LOCAL_FILE=$(find_output "local")

if [ -z "$CLOUD_FILE" ] || [ ! -f "$CLOUD_FILE" ]; then
  echo "ERROR: Cloud output not found for $RUN_ID in $DATASET_DIR/outputs/cloud/"
  exit 1
fi
if [ -z "$LOCAL_FILE" ] || [ ! -f "$LOCAL_FILE" ]; then
  echo "ERROR: Local output not found for $RUN_ID in $DATASET_DIR/outputs/local/"
  exit 1
fi

# タスク種別を自動検出
if [ -z "$TASK_TYPE" ]; then
  TASK_TYPE=$(python3 -c "import json; print(json.load(open('$CLOUD_FILE')).get('task_type', '$RUN_ID'.split('-')[0] + '-' + '$RUN_ID'.split('-')[1] if '-' in '$RUN_ID' else 'unknown'))" 2>/dev/null)
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== Evaluating $RUN_ID (task: $TASK_TYPE) ==="
echo "  Cloud: $CLOUD_FILE"
echo "  Local: $LOCAL_FILE"
echo "  Judge: $JUDGE_MODEL"
echo ""

# 出力テキストの抽出
extract_output() {
  local file="$1"
  python3 -c "
import json
data = json.load(open('$file'))
output = data.get('output', '')
if isinstance(output, list):
    # content blocks 形式
    texts = [b.get('text', '') for b in output if b.get('type') == 'text']
    print(''.join(texts))
else:
    print(str(output))
"
}

# === (a) judge 独立スコアリング ===
judge_score() {
  local output_file="$1"
  local label="$2"

  local output_text
  output_text=$(extract_output "$output_file")

  local judge_prompt
  case "$TASK_TYPE" in
    M-interp)
      judge_prompt="あなたは独立した品質評価者です。以下は agent-manifesto プロジェクトの V1-V7 メトリクス分析結果です。

---
$output_text
---

この分析を以下の 5 つの基準で 1-5 のスコア（5が最高）で評価してください:

C1. 正確性: メトリクス値の解釈が正確か（数値の引用、傾向の読み取り）
C2. 網羅性: V1-V7 の主要指標を漏れなくカバーしているか
C3. 実行可能性: 提案されたアクションが具体的で実行可能か
C4. 構造化: レポートが構造化されており読みやすいか
C5. ドメイン知識: agent-manifesto 固有の概念（P3, D4, non_triviality 等）を正しく理解しているか

以下の JSON 形式のみで出力してください（説明文は不要）:
{\"c1\": <score>, \"c2\": <score>, \"c3\": <score>, \"c4\": <score>, \"c5\": <score>, \"overall\": <weighted_average>, \"rationale\": \"<one-line reason>\"}"
      ;;
    T-interp)
      judge_prompt="あなたは独立した品質評価者です。以下は agent-manifesto プロジェクトのトレーサビリティ分析結果です。

---
$output_text
---

この分析を以下の 5 つの基準で 1-5 のスコア（5が最高）で評価してください:

C1. 正確性: カバレッジ率やギャップの特定が正確か
C2. 網羅性: 重要なギャップを漏れなく特定しているか
C3. 実行可能性: 提案されたアクションが具体的で実行可能か
C4. 構造化: レポートが構造化されており読みやすいか
C5. ドメイン知識: D13 影響波及等の概念を正しく理解しているか

以下の JSON 形式のみで出力してください（説明文は不要）:
{\"c1\": <score>, \"c2\": <score>, \"c3\": <score>, \"c4\": <score>, \"c5\": <score>, \"overall\": <weighted_average>, \"rationale\": \"<one-line reason>\"}"
      ;;
    *)
      echo '{"error": "unknown task type for judge scoring"}' >&2
      return 1
      ;;
  esac

  local judge_result
  if [ "$JUDGE_MODEL" = "claude" ]; then
    # Claude を judge として使用
    local prompt_file
    prompt_file=$(mktemp "${TMPDIR:-/tmp}/judge-prompt-XXXXXX")
    printf '%s' "$judge_prompt" > "$prompt_file"
    judge_result=$(claude -p --output-format json < "$prompt_file" 2>/dev/null)
    rm -f "$prompt_file"
    # result フィールドから JSON を抽出
    echo "$judge_result" | python3 -c "
import sys, json, re
raw = json.load(sys.stdin)
text = raw.get('result', str(raw))
match = re.search(r'\{[^{}]*\"c1\"[^{}]*\}', text, re.DOTALL)
if match:
    print(match.group(0))
else:
    print(json.dumps({'raw': text[:500], 'parse_error': True}))
" 2>/dev/null
  else
    # Ollama を judge として使用
    local prompt_file request_file
    prompt_file=$(mktemp "${TMPDIR:-/tmp}/judge-prompt-XXXXXX")
    request_file=$(mktemp "${TMPDIR:-/tmp}/judge-request-XXXXXX")
    printf '%s' "$judge_prompt" > "$prompt_file"
    python3 -c "
import json, sys
prompt = open(sys.argv[1]).read()
req = {
    'model': 'gemma4:e4b-128k',
    'messages': [{'role': 'user', 'content': prompt}],
    'stream': False
}
json.dump(req, open(sys.argv[2], 'w'), ensure_ascii=False)
" "$prompt_file" "$request_file" 2>/dev/null
    rm -f "$prompt_file"

    judge_result=$(curl -s http://127.0.0.1:11434/api/chat \
      -H "Content-Type: application/json" \
      -d @"$request_file" 2>/dev/null)
    rm -f "$request_file"

    echo "$judge_result" | python3 -c "
import sys, json, re
raw = json.load(sys.stdin)
text = raw.get('message', {}).get('content', '')
match = re.search(r'\{[^{}]*\"c1\"[^{}]*\}', text, re.DOTALL)
if match:
    print(match.group(0))
else:
    print(json.dumps({'raw': text[:500], 'parse_error': True}))
" 2>/dev/null
  fi
}

echo "--- (a) Judge Independent Scoring ---"
echo ""

echo "  Scoring Cloud output..."
CLOUD_JUDGE=$(judge_score "$CLOUD_FILE" "cloud")
echo "  Cloud: $CLOUD_JUDGE"
echo ""

echo "  Scoring Local output..."
LOCAL_JUDGE=$(judge_score "$LOCAL_FILE" "local")
echo "  Local: $LOCAL_JUDGE"
echo ""

# === (b) 機械的一致度 ===
echo "--- (b) Mechanical Agreement ---"
echo ""

CLOUD_TEXT=$(extract_output "$CLOUD_FILE")
LOCAL_TEXT=$(extract_output "$LOCAL_FILE")

MECHANICAL=$(python3 -c "
import json, sys, re

cloud = sys.argv[1]
local_out = sys.argv[2]

results = {}

# 1. 全体評価の一致 (HEALTHY/WARNING/DEGRADED)
def extract_assessment(text):
    text_upper = text.upper()
    for label in ['DEGRADED', 'WARNING', 'HEALTHY']:
        if label in text_upper:
            return label
    if '要注意' in text or '注意' in text:
        return 'WARNING'
    if '劣化' in text or '不健全' in text:
        return 'DEGRADED'
    if '良好' in text or '健全' in text:
        return 'HEALTHY'
    return 'UNKNOWN'

cloud_assessment = extract_assessment(cloud)
local_assessment = extract_assessment(local_out)
results['assessment_match'] = cloud_assessment == local_assessment
results['cloud_assessment'] = cloud_assessment
results['local_assessment'] = local_assessment

# 2. V 指標の言及カバレッジ
v_metrics = ['V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7']
cloud_vs = [v for v in v_metrics if v in cloud]
local_vs = [v for v in v_metrics if v in local_out]
results['v_coverage_cloud'] = len(cloud_vs)
results['v_coverage_local'] = len(local_vs)
results['v_coverage_match'] = set(cloud_vs) == set(local_vs)

# 3. 改善提案数の類似性
def count_proposals(text):
    patterns = [r'^\d+\.\s+\*\*', r'^-\s+\*\*', r'^\*\*\d+\.']
    count = 0
    for line in text.split('\n'):
        line = line.strip()
        for p in patterns:
            if re.match(p, line):
                count += 1
                break
    return max(count, 1)

cloud_proposals = count_proposals(cloud)
local_proposals = count_proposals(local_out)
results['proposal_count_cloud'] = cloud_proposals
results['proposal_count_local'] = local_proposals
results['proposal_count_similar'] = abs(cloud_proposals - local_proposals) <= 1

# 4. non_triviality 問題の検出
cloud_nontrivial = 'non_triviality' in cloud.lower() or ('trivial' in cloud.lower() and 'non' in cloud.lower()) or '停滞' in cloud
local_nontrivial = 'non_triviality' in local_out.lower() or ('trivial' in local_out.lower() and 'non' in local_out.lower()) or '停滞' in local_out
results['key_insight_nontriviality_cloud'] = cloud_nontrivial
results['key_insight_nontriviality_local'] = local_nontrivial
results['key_insight_match'] = cloud_nontrivial == local_nontrivial

# 総合一致度スコア
checks = [
    results['assessment_match'],
    results['v_coverage_match'],
    results['proposal_count_similar'],
    results['key_insight_match']
]
results['agreement_score'] = sum(checks) / len(checks)

print(json.dumps(results, indent=2, ensure_ascii=False))
" "$CLOUD_TEXT" "$LOCAL_TEXT")

echo "$MECHANICAL"
echo ""

# === 結果を統合して保存 ===
echo "--- Saving evaluation results ---"

python3 -c "
import json

cloud_judge_raw = '''$CLOUD_JUDGE'''
local_judge_raw = '''$LOCAL_JUDGE'''
mechanical_raw = '''$MECHANICAL'''

def parse_json_safe(raw, label):
    try:
        return json.loads(raw)
    except:
        return {'raw': raw[:500], 'parse_error': True, 'label': label}

result = {
    'run_id': '$RUN_ID',
    'task_type': '$TASK_TYPE',
    'timestamp': '$TIMESTAMP',
    'judge_model': '$JUDGE_MODEL',
    'cloud_file': '$CLOUD_FILE',
    'local_file': '$LOCAL_FILE',
    'judge_scoring': {
        'cloud': parse_json_safe(cloud_judge_raw, 'cloud'),
        'local': parse_json_safe(local_judge_raw, 'local')
    },
    'mechanical_agreement': parse_json_safe(mechanical_raw, 'mechanical'),
    'delta': None
}

# delta 計算
try:
    cloud_overall = result['judge_scoring']['cloud'].get('overall', None)
    local_overall = result['judge_scoring']['local'].get('overall', None)
    if cloud_overall is not None and local_overall is not None:
        result['delta'] = round(float(cloud_overall) - float(local_overall), 2)
except:
    pass

out_path = '$DATASET_DIR/evaluations/${RUN_ID}.json'
json.dump(result, open(out_path, 'w'), indent=2, ensure_ascii=False)
print(f'  Saved: {out_path}')

# サマリー出力
print()
print('=== Evaluation Summary ===')
print(f'Run: $RUN_ID  Task: $TASK_TYPE  Judge: $JUDGE_MODEL')
if result['delta'] is not None:
    print(f\"Judge delta (Cloud - Local): {result['delta']}\")
    if abs(result['delta']) <= 0.5:
        print('  -> Within threshold (delta <= 0.5): Local may be sufficient')
    else:
        print(f'  -> Outside threshold: Cloud is significantly better')
else:
    print('Judge delta: could not compute (parse error)')

mech = result.get('mechanical_agreement', {})
if 'agreement_score' in mech:
    print(f\"Mechanical Agreement: {mech['agreement_score']:.0%}\")
    print(f\"  Assessment: {mech.get('cloud_assessment','?')} vs {mech.get('local_assessment','?')} ({'match' if mech.get('assessment_match') else 'mismatch'})\")
    print(f\"  V-coverage: Cloud {mech.get('v_coverage_cloud',0)}/7, Local {mech.get('v_coverage_local',0)}/7\")
"

echo ""
echo "=== Evaluation complete ==="

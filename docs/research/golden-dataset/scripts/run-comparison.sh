#!/usr/bin/env bash
# run-comparison.sh — Claude (Cloud) vs Local LLM の比較実行
#
# #595 の発見に基づく新方式:
#   Cloud: claude -p (通常 Anthropic API)
#   Local: eval "$(ccr activate)" && claude -p (ccr が Local LLM にルーティング)
#
# 両方とも Claude Code agent framework 内で動作するため、
# CLAUDE.md/rules/memory/tools (~32K tokens) が同一条件で注入される。
#
# Usage:
#   bash run-comparison.sh --input <input-file> --task <task-type>
#   bash run-comparison.sh --input <file> --task M-interp --local-model gemma4:e4b-128k --runs 3
#
# Task types: M-interp (metrics 解釈), T-interp (trace 解釈)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATASET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT_FILE=""
TASK_TYPE=""
LOCAL_MODEL="gemma4:e4b-128k"
RUNS=1
CLOUD_ONLY=false
LOCAL_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) INPUT_FILE="$2"; shift 2 ;;
    --task) TASK_TYPE="$2"; shift 2 ;;
    --local-model) LOCAL_MODEL="$2"; shift 2 ;;
    --runs) RUNS="$2"; shift 2 ;;
    --cloud-only) CLOUD_ONLY=true; shift ;;
    --local-only) LOCAL_ONLY=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$INPUT_FILE" ] || [ -z "$TASK_TYPE" ]; then
  echo "Usage: bash run-comparison.sh --input <file> --task <M-interp|T-interp> [--local-model <model>] [--runs N]"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: Input file not found: $INPUT_FILE"
  exit 1
fi

# 出力ディレクトリの確保
mkdir -p "$DATASET_DIR/outputs/cloud" "$DATASET_DIR/outputs/local"

# 入力 ID を抽出
INPUT_ID=$(python3 -c "import json; print(json.load(open('$INPUT_FILE'))['meta']['id'])" 2>/dev/null || basename "$INPUT_FILE" .json)
RUN_ID="${TASK_TYPE}-${INPUT_ID##*-}"

# ccr が利用可能か確認
check_ccr() {
  if ! command -v ccr &>/dev/null; then
    echo "ERROR: ccr (claude-code-router) not found. Install from: https://github.com/musistudio/claude-code-router"
    exit 1
  fi
  # ccr config でモデルが設定されているか
  local ccr_model
  ccr_model=$(python3 -c "
import json
cfg = json.load(open('$HOME/.claude-code-router/config.json'))
print(cfg.get('Router', {}).get('default', 'NOT_SET'))
" 2>/dev/null)
  echo "  ccr default route: $ccr_model"
}

# プロンプト生成（ドメイン知識注入は不要 — Claude Code が自動転送する）
generate_prompt() {
  local input_data
  input_data=$(python3 -c "import json; print(json.dumps(json.load(open('$INPUT_FILE'))['data'], indent=2))" 2>/dev/null)

  case "$TASK_TYPE" in
    M-interp)
      cat <<PROMPT
以下は agent-manifesto プロジェクトの V1-V7 メトリクス (observe.sh の出力) です。

\`\`\`json
$input_data
\`\`\`

このメトリクスを分析し、以下を日本語で簡潔に報告してください:

1. **全体評価**: システムの健全性を一言で（HEALTHY / WARNING / DEGRADED）
2. **V1-V7 各指標の解釈**: 各メトリクスの現在値が良好か、注意が必要か
3. **改善提案**: 最も優先度の高い改善アクション（最大3件）

構造化された形式で出力してください。
PROMPT
      ;;
    T-interp)
      cat <<PROMPT
以下は agent-manifesto プロジェクトのトレーサビリティレポート (manifest-trace json の出力) です。

\`\`\`json
$input_data
\`\`\`

このレポートを分析し、以下を日本語で簡潔に報告してください:

1. **カバレッジ状況**: 全体のカバレッジ率と未カバー命題のリスト
2. **ギャップ分析**: 最も重要なカバレッジギャップとその影響（D13 影響波及の観点）
3. **改善提案**: 優先度順の改善アクション（最大3件）

構造化された形式で出力してください。
PROMPT
      ;;
    *)
      echo "Unknown task type: $TASK_TYPE" >&2
      exit 1
      ;;
  esac
}

PROMPT=$(generate_prompt)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# === claude -p 実行のラッパー ===
# $1: label (cloud/local)
# $2: run number
# $3: env setup command (empty for cloud, ccr activate for local)
run_claude_p() {
  local label="$1"
  local run_num="$2"
  local env_setup="$3"
  local suffix=""
  [ "$RUNS" -gt 1 ] && suffix="-run${run_num}"
  local out_file="$DATASET_DIR/outputs/${label}/${RUN_ID}${suffix}.json"

  local start_ms
  start_ms=$(python3 -c "import time; print(int(time.time()*1000))")

  # プロンプトをファイル経由で渡す（シェルエスケープの問題を回避）
  local prompt_file
  prompt_file=$(mktemp "${TMPDIR:-/tmp}/comparison-prompt-XXXXXX")
  printf '%s' "$PROMPT" > "$prompt_file"

  local raw_output exit_code
  if [ -n "$env_setup" ]; then
    # Local: ccr 環境を有効化してから claude -p 実行
    raw_output=$(bash -c "$env_setup && claude -p --output-format json < \"$prompt_file\"" 2>/dev/null)
    exit_code=$?
  else
    # Cloud: 通常の claude -p 実行
    raw_output=$(claude -p --output-format json < "$prompt_file" 2>/dev/null)
    exit_code=$?
  fi
  rm -f "$prompt_file"

  local end_ms
  end_ms=$(python3 -c "import time; print(int(time.time()*1000))")
  local latency_ms=$((end_ms - start_ms))

  if [ $exit_code -eq 0 ] && [ -n "$raw_output" ]; then
    echo "$raw_output" | python3 -c "
import sys, json

raw = json.load(sys.stdin)
result = {
    'id': '${RUN_ID}${suffix}',
    'task_type': '${TASK_TYPE}',
    'input_file': '$(basename "$INPUT_FILE")',
    'label': '${label}',
    'model': raw.get('model', 'unknown'),
    'output': raw.get('result', raw.get('content', str(raw))),
    'tokens_in': raw.get('usage', {}).get('input_tokens', -1),
    'tokens_out': raw.get('usage', {}).get('output_tokens', -1),
    'latency_ms': ${latency_ms},
    'timestamp': '${TIMESTAMP}',
    'run_number': ${run_num},
    'exit_code': 0
}
json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
" > "$out_file"
    echo "  OK: $out_file ($latency_ms ms)"
  else
    echo "  FAILED (exit=$exit_code)"
    python3 -c "
import json, sys
result = {
    'id': '${RUN_ID}${suffix}',
    'label': '${label}',
    'model': 'unknown',
    'error': 'exit_code=$exit_code',
    'latency_ms': ${latency_ms},
    'timestamp': '${TIMESTAMP}',
    'run_number': ${run_num},
    'exit_code': $exit_code
}
json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
" > "$out_file"
  fi
}

echo "=== Comparison: $RUN_ID ==="
echo "  Task: $TASK_TYPE"
echo "  Input: $INPUT_FILE"
echo "  Local model: $LOCAL_MODEL"
echo "  Runs: $RUNS"
echo ""

# === Cloud 実行 ===
if [ "$LOCAL_ONLY" = false ]; then
  echo "--- Cloud (Anthropic API via claude -p) ---"
  for i in $(seq 1 "$RUNS"); do
    echo "  Run $i/$RUNS..."
    run_claude_p "cloud" "$i" ""
  done
  echo ""
fi

# === Local 実行 ===
if [ "$CLOUD_ONLY" = false ]; then
  echo "--- Local ($LOCAL_MODEL via ccr + claude -p) ---"
  check_ccr

  # ccr config でモデルを一時的に切り替え
  CCR_ACTIVATE='eval "$(ccr activate)"'
  for i in $(seq 1 "$RUNS"); do
    echo "  Run $i/$RUNS..."
    run_claude_p "local" "$i" "$CCR_ACTIVATE"
  done
  echo ""
fi

echo "=== Comparison complete: $RUN_ID ==="
echo "Cloud outputs: $DATASET_DIR/outputs/cloud/${RUN_ID}*.json"
echo "Local outputs: $DATASET_DIR/outputs/local/${RUN_ID}*.json"

#!/usr/bin/env bash
# Phase 6 sprint 3 A #2: spec generation evaluation harness (Day 204)
#
# 目的: docs/research/.../spec-gen/benchmark.json から prompt を読み込み、
#       subagent dispatch を script 化、statement parity を機械評価。
#
# 注意: 本 script は **subagent dispatch の wrapper を提供**するが、
#       実 dispatch は Claude Code Agent tool 経由で manual 実行が必要。
#       script は prompt 表示 + 期待値比較の補助。

set -uo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
BENCHMARK="$REPO_ROOT/docs/research/new-foundation-survey/spec-gen/benchmark.json"

if [ ! -f "$BENCHMARK" ]; then
  echo "ERROR: benchmark.json not found at $BENCHMARK" >&2
  exit 2
fi

CMD="${1:-list}"

case "$CMD" in
  list)
    echo "=== Spec Generation Benchmark (Phase 6 sprint 3 A) ==="
    jq -r '.benchmarks[] | "\(.id) [\(.difficulty), expect \(.expected_pass_rate)%]: \(.natural_language_requirement)"' "$BENCHMARK"
    ;;
  prompt)
    ID="${2:-}"
    if [ -z "$ID" ]; then
      echo "Usage: $0 prompt <benchmark-id>" >&2
      exit 64
    fi
    REQ=$(jq -r --arg id "$ID" '.benchmarks[] | select(.id == $id) | .natural_language_requirement' "$BENCHMARK")
    if [ -z "$REQ" ]; then
      echo "ERROR: benchmark id '$ID' not found" >&2
      exit 1
    fi
    echo "=== Subagent dispatch prompt for '$ID' ==="
    cat <<PROMPT
Lean 4 axiom / theorem statement 生成 (PI-19 vocabulary 利用)。

## 自然言語要件
$REQ

## vocabulary
docs/research/new-foundation-survey/usecases/03-spec-generation-prompt-template.md 参照。

## 出力
theorem statement のみ \`\`\` ブロック、proof = \`:= by sorry\`。説明 1 文。
PROMPT
    ;;
  evaluate)
    # Compare a generated statement against expected (PI-19 registry)
    # usage: echo "<generated statement>" | $0 evaluate <benchmark-id>
    ID="${2:-}"
    if [ -z "$ID" ]; then
      echo "Usage: $0 evaluate <benchmark-id> < generated.lean" >&2
      exit 64
    fi
    INPUT=$(cat)
    EXPECTED_DEPS=$(jq -r --arg id "$ID" '.benchmarks[] | select(.id == $id) | .expected_axiom_deps' "$BENCHMARK")
    echo "Generated:"
    echo "$INPUT" | head -10
    echo ""
    echo "Expected axiom deps: $EXPECTED_DEPS"
    echo "(Manual review: statement byte parity vs PI-19 expected)"
    ;;
  *)
    cat <<USAGE
Usage:
  $0 list                       # benchmark 一覧表示
  $0 prompt <id>                # 指定 benchmark の subagent prompt 出力
  $0 evaluate <id> < gen.lean   # 生成結果と期待値の比較

例:
  $0 list
  $0 prompt v1_measurable
  echo 'theorem foo : Measurable skillQuality := by sorry' | $0 evaluate v1_measurable
USAGE
    exit 0
    ;;
esac

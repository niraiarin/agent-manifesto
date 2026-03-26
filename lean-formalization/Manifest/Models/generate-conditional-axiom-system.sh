#!/usr/bin/env bash
# generate-conditional-axiom-system.sh
#
# ModelSpec (JSON) から ConditionalAxiomSystem.lean を生成する。
# B+C ハイブリッドの「B（スクリプト）」側。
#
# 入力: ModelSpec JSON (stdin または -f オプション)
# 出力: ConditionalAxiomSystem.lean (stdout または -o オプション)
#
# ModelSpec JSON フォーマット:
# {
#   "namespace": "Manifest.Models",
#   "layers": [
#     {"name": "foundation", "ordValue": 2, "definition": "覆らない前提", "derivedFrom": ["C1","C2"]},
#     {"name": "derived",    "ordValue": 1, "definition": "前提から導出",  "derivedFrom": ["H1"]},
#     {"name": "applied",    "ordValue": 0, "definition": "環境依存の設計判断", "derivedFrom": ["H2"]}
#   ],
#   "assignments": [
#     {"proposition": "t1", "layerName": "foundation", "justification": ["C1"]},
#     ...
#   ]
# }
#
# Usage:
#   bash generate-conditional-axiom-system.sh -f model-spec.json -o ConditionalAxiomSystem.lean
#   cat model-spec.json | bash generate-conditional-axiom-system.sh > ConditionalAxiomSystem.lean

set -euo pipefail

# ============================================================
# オプション解析
# ============================================================

INPUT_FILE=""
OUTPUT_FILE=""
VERIFY=true

while [[ $# -gt 0 ]]; do
  case $1 in
    -f) INPUT_FILE="$2"; shift 2 ;;
    -o) OUTPUT_FILE="$2"; shift 2 ;;
    --no-verify) VERIFY=false; shift ;;
    -h|--help)
      echo "Usage: $0 [-f input.json] [-o output.lean] [--no-verify]"
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# 入力の読み込み
if [ -n "$INPUT_FILE" ]; then
  JSON=$(cat "$INPUT_FILE")
else
  JSON=$(cat)
fi

# jq の存在確認
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed" >&2
  exit 1
fi

# ============================================================
# JSON のパース
# ============================================================

NAMESPACE=$(echo "$JSON" | jq -r '.namespace // "Manifest.Models"')
NUM_LAYERS=$(echo "$JSON" | jq '.layers | length')
NUM_ASSIGNMENTS=$(echo "$JSON" | jq '.assignments | length')

# 層の情報を配列に展開
declare -a LAYER_NAMES LAYER_ORDS LAYER_DEFS LAYER_SOURCES
for i in $(seq 0 $((NUM_LAYERS - 1))); do
  LAYER_NAMES[$i]=$(echo "$JSON" | jq -r ".layers[$i].name")
  LAYER_ORDS[$i]=$(echo "$JSON" | jq -r ".layers[$i].ordValue")
  LAYER_DEFS[$i]=$(echo "$JSON" | jq -r ".layers[$i].definition")
  LAYER_SOURCES[$i]=$(echo "$JSON" | jq -r ".layers[$i].derivedFrom | join(\", \")")
done

# bottom（ord 最小）と top（ord 最大）を特定
min_ord=999999; max_ord=0; bottom_name=""; top_name=""
for i in $(seq 0 $((NUM_LAYERS - 1))); do
  ord=${LAYER_ORDS[$i]}
  if [ "$ord" -lt "$min_ord" ]; then min_ord=$ord; bottom_name=${LAYER_NAMES[$i]}; fi
  if [ "$ord" -gt "$max_ord" ]; then max_ord=$ord; top_name=${LAYER_NAMES[$i]}; fi
done

# ============================================================
# Lean コード生成
# ============================================================

generate_lean() {

cat <<LEAN_HEADER
import Manifest.EpistemicLayer

/-!
# 条件付き公理体系（生成済み）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。

手動で編集しないでください。仮定の変更は Assumptions/ 以下で行い、
再生成してください。

## 層構造

LEAN_HEADER

# 層の一覧を doc comment に出力
for i in $(seq 0 $((NUM_LAYERS - 1))); do
  echo "- **${LAYER_NAMES[$i]}** (ord=${LAYER_ORDS[$i]}): ${LAYER_DEFS[$i]} [${LAYER_SOURCES[$i]}]"
done

cat <<LEAN_NS
-/

namespace ${NAMESPACE}

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
LEAN_NS

for i in $(seq 0 $((NUM_LAYERS - 1))); do
  echo "  /-- ${LAYER_DEFS[$i]} (ord=${LAYER_ORDS[$i]}) -/"
  echo "  | ${LAYER_NAMES[$i]}"
done

echo "  deriving BEq, Repr, DecidableEq"
echo ""

# ord 関数
cat <<LEAN_ORD
-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
LEAN_ORD

for i in $(seq 0 $((NUM_LAYERS - 1))); do
  echo "  | .${LAYER_NAMES[$i]} => ${LAYER_ORDS[$i]}"
done

echo ""

# EpistemicLayerClass instance
cat <<LEAN_INSTANCE
instance : EpistemicLayerClass ConcreteLayer where
  ord := ConcreteLayer.ord
  bottom := .${bottom_name}
  nontrivial := ⟨.${top_name}, .${bottom_name}, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨${max_ord}, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

LEAN_INSTANCE

# classify 関数
cat <<LEAN_CLASSIFY_HEADER
-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。各ケースの根拠は Assumptions に記録。 -/
def classify : PropositionId → ConcreteLayer
LEAN_CLASSIFY_HEADER

# assignments を層ごとにグループ化して出力
for i in $(seq 0 $((NUM_LAYERS - 1))); do
  layer_name=${LAYER_NAMES[$i]}
  props=""
  justifications=""
  for j in $(seq 0 $((NUM_ASSIGNMENTS - 1))); do
    a_layer=$(echo "$JSON" | jq -r ".assignments[$j].layerName")
    if [ "$a_layer" = "$layer_name" ]; then
      a_prop=$(echo "$JSON" | jq -r ".assignments[$j].proposition")
      a_just=$(echo "$JSON" | jq -r ".assignments[$j].justification | join(\", \")")
      if [ -n "$props" ]; then
        props="$props | .$a_prop"
      else
        props="  | .$a_prop"
      fi
    fi
  done
  if [ -n "$props" ]; then
    echo "  -- ${layer_name}"
    echo "${props} => .${layer_name}"
  fi
done

echo ""

# 証明
cat <<LEAN_PROOFS
-- ============================================================
-- 4. 証明
-- ============================================================

/-- classify は依存関係の単調性を尊重する。 -/
theorem classify_monotone :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      ConcreteLayer.ord (classify b) ≥ ConcreteLayer.ord (classify a) := by
  intro a b h; cases a <;> cases b <;> revert h <;> native_decide

/-- classify は全域関数。 -/
theorem classify_total :
    ∀ (p : PropositionId), ∃ (l : ConcreteLayer), classify p = l :=
  fun p => ⟨classify p, rfl⟩

-- ============================================================
-- 5. LayerAssignment
-- ============================================================

/-- 生成されたモデルに基づく LayerAssignment。 -/
def generatedAssignment : LayerAssignment ConcreteLayer where
  assign := classify
  monotone := classify_monotone
  bounded := ⟨${max_ord}, fun d => by cases d <;> simp [classify, ConcreteLayer.ord, EpistemicLayerClass.ord]⟩

end ${NAMESPACE}
LEAN_PROOFS

}

# ============================================================
# 出力
# ============================================================

if [ -n "$OUTPUT_FILE" ]; then
  generate_lean > "$OUTPUT_FILE"
  echo "Generated: $OUTPUT_FILE" >&2

  # 自動検証
  if $VERIFY; then
    echo "Verifying with lake build..." >&2
    # lakefile.lean のあるディレクトリを探す
    LEAN_ROOT="$(cd "$(dirname "$OUTPUT_FILE")" && while [ ! -f lakefile.lean ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)"
    # 出力ファイルの絶対パスから相対パスを算出してモジュール名に変換
    ABS_OUTPUT="$(cd "$(dirname "$OUTPUT_FILE")" && pwd)/$(basename "$OUTPUT_FILE")"
    REL_PATH="${ABS_OUTPUT#${LEAN_ROOT}/}"
    MODULE_NAME=$(echo "$REL_PATH" | sed 's|/|.|g' | sed 's|\.lean$||')
    export PATH="$HOME/.elan/bin:$PATH"
    if (cd "$LEAN_ROOT" && lake build "$MODULE_NAME" 2>&1); then
      echo "✓ Verification passed" >&2
    else
      echo "✗ Verification failed — check for monotonicity violations" >&2
      echo "  Run: #eval findViolations in CheckMonotone.lean" >&2
      exit 1
    fi
  fi
else
  generate_lean
fi

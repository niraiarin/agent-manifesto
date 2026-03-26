#!/usr/bin/env bash
# generate-conditional-axiom-system.sh
#
# ModelSpec (JSON) から ConditionalAxiomSystem.lean を生成する。
#
# 2 つのモードを持つ:
#   1. 統合モード: "assignments" フィールドあり → 既存の PropositionId を使用
#   2. スタンドアロンモード: "propositions" フィールドあり → PropositionId も生成
#
# Usage:
#   bash generate-conditional-axiom-system.sh -f model-spec.json -o Output.lean
#   bash generate-conditional-axiom-system.sh -f model-spec.json --no-verify > Output.lean

set -euo pipefail

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

if [ -n "$INPUT_FILE" ]; then
  JSON=$(cat "$INPUT_FILE")
else
  JSON=$(cat)
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed" >&2
  exit 1
fi

# ============================================================
# モード判定
# ============================================================

HAS_PROPOSITIONS=$(echo "$JSON" | jq 'has("propositions")')
HAS_ASSIGNMENTS=$(echo "$JSON" | jq 'has("assignments")')

if [ "$HAS_PROPOSITIONS" = "true" ]; then
  MODE="standalone"
elif [ "$HAS_ASSIGNMENTS" = "true" ]; then
  MODE="integrated"
else
  echo "Error: JSON must have either 'propositions' or 'assignments' field" >&2
  exit 1
fi

# ============================================================
# 共通: 層の情報をパース
# ============================================================

NAMESPACE=$(echo "$JSON" | jq -r '.namespace // "Manifest.Models"')
NUM_LAYERS=$(echo "$JSON" | jq '.layers | length')

declare -a LAYER_NAMES LAYER_ORDS LAYER_DEFS LAYER_SOURCES
for i in $(seq 0 $((NUM_LAYERS - 1))); do
  LAYER_NAMES[$i]=$(echo "$JSON" | jq -r ".layers[$i].name")
  LAYER_ORDS[$i]=$(echo "$JSON" | jq -r ".layers[$i].ordValue")
  LAYER_DEFS[$i]=$(echo "$JSON" | jq -r ".layers[$i].definition")
  LAYER_SOURCES[$i]=$(echo "$JSON" | jq -r ".layers[$i].derivedFrom | join(\", \")")
done

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

# --- ヘッダー ---
if [ "$MODE" = "standalone" ]; then
cat <<LEAN_HEADER
/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

LEAN_HEADER
else
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
fi

for i in $(seq 0 $((NUM_LAYERS - 1))); do
  echo "- **${LAYER_NAMES[$i]}** (ord=${LAYER_ORDS[$i]}): ${LAYER_DEFS[$i]} [${LAYER_SOURCES[$i]}]"
done

cat <<LEAN_NS
-/

namespace ${NAMESPACE}

LEAN_NS

if [ "$MODE" = "integrated" ]; then
  echo "open Manifest"
  echo "open Manifest.EpistemicLayer"
  echo ""
fi

# --- スタンドアロンモード: PropositionId + 依存関係の生成 ---
if [ "$MODE" = "standalone" ]; then
  NUM_PROPS=$(echo "$JSON" | jq '.propositions | length')

  echo "-- ============================================================"
  echo "-- 0. PropositionId (プロジェクト固有)"
  echo "-- ============================================================"
  echo ""
  echo "/-- プロジェクト固有の命題識別子。 -/"
  echo "inductive PropositionId where"

  for j in $(seq 0 $((NUM_PROPS - 1))); do
    prop_id=$(echo "$JSON" | jq -r ".propositions[$j].id")
    echo "  | ${prop_id}"
  done

  echo "  deriving BEq, Repr, DecidableEq"
  echo ""

  # 依存関係
  echo "/-- 命題の直接依存先。 -/"
  echo "def PropositionId.dependencies : PropositionId → List PropositionId"

  for j in $(seq 0 $((NUM_PROPS - 1))); do
    prop_id=$(echo "$JSON" | jq -r ".propositions[$j].id")
    deps=$(echo "$JSON" | jq -r ".propositions[$j].dependencies | map(\".\" + .) | join(\", \")")
    if [ -z "$deps" ] || [ "$deps" = "" ]; then
      echo "  | .${prop_id} => []"
    else
      echo "  | .${prop_id} => [${deps}]"
    fi
  done

  echo ""
  echo "/-- 命題が別の命題に直接依存する。 -/"
  echo "def propositionDependsOn (a b : PropositionId) : Bool :="
  echo "  a.dependencies.contains b"
  echo ""
fi

# --- ConcreteLayer ---
echo "-- ============================================================"
echo "-- 1. ConcreteLayer inductive"
echo "-- ============================================================"
echo ""
echo "/-- 認識論的層。 -/"
echo "inductive ConcreteLayer where"

for i in $(seq 0 $((NUM_LAYERS - 1))); do
  echo "  /-- ${LAYER_DEFS[$i]} (ord=${LAYER_ORDS[$i]}) -/"
  echo "  | ${LAYER_NAMES[$i]}"
done

echo "  deriving BEq, Repr, DecidableEq"
echo ""

# --- ord + instance ---
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

# EpistemicLayerClass — スタンドアロンではインライン定義
if [ "$MODE" = "standalone" ]; then
cat <<LEAN_TYPECLASS
/-- 認識論的層構造の typeclass（スタンドアロン版）。 -/
class EpistemicLayerClass (α : Type) where
  ord : α → Nat
  bottom : α
  nontrivial : ∃ (a b : α), ord a ≠ ord b
  ord_injective : ∀ (a b : α), ord a = ord b → a = b
  ord_bounded : ∃ (n : Nat), ∀ (a : α), ord a ≤ n
  bottom_minimum : ∀ (a : α), ord bottom ≤ ord a

LEAN_TYPECLASS
fi

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

# --- classify ---
echo "-- ============================================================"
echo "-- 3. classify"
echo "-- ============================================================"
echo ""
echo "/-- 全命題の層分類。 -/"
echo "def classify : PropositionId → ConcreteLayer"

if [ "$MODE" = "standalone" ]; then
  NUM_PROPS=$(echo "$JSON" | jq '.propositions | length')
  for i in $(seq 0 $((NUM_LAYERS - 1))); do
    layer_name=${LAYER_NAMES[$i]}
    props=""
    for j in $(seq 0 $((NUM_PROPS - 1))); do
      a_layer=$(echo "$JSON" | jq -r ".propositions[$j].layerName")
      if [ "$a_layer" = "$layer_name" ]; then
        a_prop=$(echo "$JSON" | jq -r ".propositions[$j].id")
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
else
  NUM_ASSIGNMENTS=$(echo "$JSON" | jq '.assignments | length')
  for i in $(seq 0 $((NUM_LAYERS - 1))); do
    layer_name=${LAYER_NAMES[$i]}
    props=""
    for j in $(seq 0 $((NUM_ASSIGNMENTS - 1))); do
      a_layer=$(echo "$JSON" | jq -r ".assignments[$j].layerName")
      if [ "$a_layer" = "$layer_name" ]; then
        a_prop=$(echo "$JSON" | jq -r ".assignments[$j].proposition")
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
fi

echo ""

# --- 証明 ---
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

end ${NAMESPACE}
LEAN_PROOFS

}

# ============================================================
# 出力
# ============================================================

if [ -n "$OUTPUT_FILE" ]; then
  generate_lean > "$OUTPUT_FILE"
  echo "Generated: $OUTPUT_FILE (mode: $MODE)" >&2

  if $VERIFY; then
    echo "Verifying with lake build..." >&2
    LEAN_ROOT="$(cd "$(dirname "$OUTPUT_FILE")" && while [ ! -f lakefile.lean ] && [ "$(pwd)" != "/" ]; do cd ..; done; pwd)"
    ABS_OUTPUT="$(cd "$(dirname "$OUTPUT_FILE")" && pwd)/$(basename "$OUTPUT_FILE")"
    REL_PATH="${ABS_OUTPUT#${LEAN_ROOT}/}"
    MODULE_NAME=$(echo "$REL_PATH" | sed 's|/|.|g' | sed 's|\.lean$||')
    export PATH="$HOME/.elan/bin:$PATH"
    if (cd "$LEAN_ROOT" && lake build "$MODULE_NAME" 2>&1); then
      echo "✓ Verification passed" >&2
    else
      echo "✗ Verification failed" >&2
      exit 1
    fi
  fi
else
  generate_lean
fi

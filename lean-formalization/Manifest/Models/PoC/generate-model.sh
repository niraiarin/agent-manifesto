#!/usr/bin/env bash
# PoC B: ModelSpec 相当の入力からConditionalAxiomSystem を生成するスクリプト
#
# 入力: 層定義と分類をシェル変数で受け取る
# 出力: Lean ファイルを stdout に出力
#
# Usage: bash generate-model.sh > OutputModel.lean

set -euo pipefail

# ============================================================
# 入力パラメータ（ModelSpec 相当）
# ============================================================

# 層定義: "name:ordValue" の配列（ordValue 降順）
LAYERS=(
  "foundation:2"
  "derived:1"
  "applied:0"
)

# 分類: "propositionId:layerName" の配列
ASSIGNMENTS=(
  "t1:foundation" "t2:foundation" "t3:foundation" "t4:foundation"
  "t5:foundation" "t6:foundation" "t7:foundation" "t8:foundation"
  "e1:foundation" "e2:foundation"
  "p1:derived" "p2:derived" "p3:derived" "p4:derived" "p5:derived" "p6:derived"
  "l1:derived" "l2:derived" "l3:derived" "l4:derived" "l5:derived" "l6:derived"
  "d8:derived"
  "d1:applied" "d2:applied" "d3:applied" "d4:applied" "d5:applied" "d6:applied" "d7:applied"
  "d9:applied" "d10:applied" "d11:applied" "d12:applied" "d13:applied" "d14:applied"
)

# ============================================================
# Lean コード生成
# ============================================================

MODULE_NAME="Manifest.Models.PoC.ThreeLayerGenerated"
NAMESPACE="Manifest.Models.PoC.ThreeLayerGenerated"

cat <<LEAN_HEADER
import Manifest.EpistemicLayer

/-!
# 生成された条件付き公理体系

このファイルは generate-model.sh によって自動生成されました。
手動で編集しないでください。
-/

namespace ${NAMESPACE}

open Manifest
open Manifest.EpistemicLayer

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
LEAN_HEADER

for layer_spec in "${LAYERS[@]}"; do
  name="${layer_spec%%:*}"
  echo "  | ${name}"
done

echo "  deriving BEq, Repr, DecidableEq"
echo ""

# ord 関数
echo "-- ============================================================"
echo "-- 2. EpistemicLayerClass instance"
echo "-- ============================================================"
echo ""
echo "/-- ConcreteLayer の順序値。 -/"
echo "def ConcreteLayer.ord : ConcreteLayer → Nat"

first=true
for layer_spec in "${LAYERS[@]}"; do
  name="${layer_spec%%:*}"
  ord="${layer_spec##*:}"
  if $first; then
    echo "  | .${name} => ${ord}"
    first=false
  else
    echo "  | .${name} => ${ord}"
  fi
done

echo ""

# bottom（ord 最小の層を特定）
min_ord=999
bottom_name=""
for layer_spec in "${LAYERS[@]}"; do
  name="${layer_spec%%:*}"
  ord="${layer_spec##*:}"
  if [ "$ord" -lt "$min_ord" ]; then
    min_ord=$ord
    bottom_name=$name
  fi
done

# max ord
max_ord=0
for layer_spec in "${LAYERS[@]}"; do
  ord="${layer_spec##*:}"
  if [ "$ord" -gt "$max_ord" ]; then
    max_ord=$ord
  fi
done

cat <<LEAN_INSTANCE
instance : EpistemicLayerClass ConcreteLayer where
  ord := ConcreteLayer.ord
  bottom := .${bottom_name}
  nontrivial := by
    exact ⟨.${LAYERS[0]%%:*}, .${bottom_name}, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨${max_ord}, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

LEAN_INSTANCE

# classify 関数
echo "-- ============================================================"
echo "-- 3. classify"
echo "-- ============================================================"
echo ""
echo "/-- 全命題の層分類。 -/"
echo "def classify : PropositionId → ConcreteLayer"

for assignment in "${ASSIGNMENTS[@]}"; do
  prop="${assignment%%:*}"
  layer="${assignment##*:}"
  echo "  | .${prop} => .${layer}"
done

echo ""

# 証明
cat <<LEAN_PROOFS
-- ============================================================
-- 4. classify_monotone
-- ============================================================

/-- classify は依存関係の単調性を尊重する。 -/
theorem classify_monotone :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      ConcreteLayer.ord (classify b) ≥ ConcreteLayer.ord (classify a) := by
  intro a b h; cases a <;> cases b <;> revert h <;> native_decide

-- ============================================================
-- 5. classify_total
-- ============================================================

/-- classify は全域関数。 -/
theorem classify_total :
    ∀ (p : PropositionId), ∃ (l : ConcreteLayer), classify p = l :=
  fun p => ⟨classify p, rfl⟩

-- ============================================================
-- 6. LayerAssignment
-- ============================================================

/-- 生成されたモデルに基づく LayerAssignment。 -/
def generatedAssignment : LayerAssignment ConcreteLayer where
  assign := classify
  monotone := classify_monotone
  bounded := ⟨${max_ord}, fun d => by cases d <;> simp [classify, ConcreteLayer.ord, EpistemicLayerClass.ord]⟩

end ${NAMESPACE}
LEAN_PROOFS

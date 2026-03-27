/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulatory_constraint** (ord=5): 電波法規・国際条約に基づく不変制約 [C1]
- **safety_requirement** (ord=4): 安全・緊急通信に関する要件 [C2]
- **qos_standard** (ord=3): 通信品質に関する基準 [C3, H1]
- **allocation_policy** (ord=2): 帯域配分に関する方針 [C4, C5]
- **optimization_method** (ord=1): 最適化手法の選択 [H3, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | ITU_f73a11
  | prop_a71e3a
  | prop_826ef4
  | SLA_54bb2d
  | prop_923aef
  | prop_bbafe8
  | prop_ea0baa
  | prop_03b3eb
  | LSTM_4cd0f5
  | prop_755b34
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .ITU_f73a11 => []
  | .prop_a71e3a => []
  | .prop_826ef4 => []
  | .SLA_54bb2d => []
  | .prop_923aef => []
  | .prop_bbafe8 => []
  | .prop_ea0baa => []
  | .prop_03b3eb => []
  | .LSTM_4cd0f5 => []
  | .prop_755b34 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 電波法規・国際条約に基づく不変制約 (ord=5) -/
  | regulatory_constraint
  /-- 安全・緊急通信に関する要件 (ord=4) -/
  | safety_requirement
  /-- 通信品質に関する基準 (ord=3) -/
  | qos_standard
  /-- 帯域配分に関する方針 (ord=2) -/
  | allocation_policy
  /-- 最適化手法の選択 (ord=1) -/
  | optimization_method
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulatory_constraint => 5
  | .safety_requirement => 4
  | .qos_standard => 3
  | .allocation_policy => 2
  | .optimization_method => 1

/-- 認識論的層構造の typeclass（スタンドアロン版）。 -/
class EpistemicLayerClass (α : Type) where
  ord : α → Nat
  bottom : α
  nontrivial : ∃ (a b : α), ord a ≠ ord b
  ord_injective : ∀ (a b : α), ord a = ord b → a = b
  ord_bounded : ∃ (n : Nat), ∀ (a : α), ord a ≤ n
  bottom_minimum : ∀ (a : α), ord bottom ≤ ord a

instance : EpistemicLayerClass ConcreteLayer where
  ord := ConcreteLayer.ord
  bottom := .optimization_method
  nontrivial := ⟨.regulatory_constraint, .optimization_method, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- regulatory_constraint
  | .ITU_f73a11 | .prop_a71e3a => .regulatory_constraint
  -- safety_requirement
  | .prop_826ef4 => .safety_requirement
  -- qos_standard
  | .SLA_54bb2d | .prop_923aef | .prop_755b34 => .qos_standard
  -- allocation_policy
  | .prop_bbafe8 | .prop_ea0baa => .allocation_policy
  -- optimization_method
  | .prop_03b3eb | .LSTM_4cd0f5 => .optimization_method

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

end Manifest.Models

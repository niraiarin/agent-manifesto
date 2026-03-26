/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyOperationInvariant** (ord=3): 過充電・過放電・熱暴走リスクに関する蓄電池安全運用の絶対制約 [C1, C2]
- **DegradationModelPolicy** (ord=2): SOH（健全性指標）・容量劣化曲線に基づく予測モデルの方針 [C3, C4]
- **PredictionAccuracyHypothesis** (ord=1): 充放電サイクル数・温度履歴・使用パターンからの残寿命予測精度仮説 [H1, H2, H3, H4, H5, H6]
-/

namespace TestCoverage.S397

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s397_p01
  | s397_p02
  | s397_p03
  | s397_p04
  | s397_p05
  | s397_p06
  | s397_p07
  | s397_p08
  | s397_p09
  | s397_p10
  | s397_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s397_p01 => []
  | .s397_p02 => []
  | .s397_p03 => [.s397_p01, .s397_p02]
  | .s397_p04 => [.s397_p01]
  | .s397_p05 => [.s397_p02]
  | .s397_p06 => [.s397_p04, .s397_p05]
  | .s397_p07 => [.s397_p03]
  | .s397_p08 => [.s397_p04]
  | .s397_p09 => [.s397_p06]
  | .s397_p10 => [.s397_p07, .s397_p08]
  | .s397_p11 => [.s397_p09, .s397_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 過充電・過放電・熱暴走リスクに関する蓄電池安全運用の絶対制約 (ord=3) -/
  | SafetyOperationInvariant
  /-- SOH（健全性指標）・容量劣化曲線に基づく予測モデルの方針 (ord=2) -/
  | DegradationModelPolicy
  /-- 充放電サイクル数・温度履歴・使用パターンからの残寿命予測精度仮説 (ord=1) -/
  | PredictionAccuracyHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyOperationInvariant => 3
  | .DegradationModelPolicy => 2
  | .PredictionAccuracyHypothesis => 1

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
  bottom := .PredictionAccuracyHypothesis
  nontrivial := ⟨.SafetyOperationInvariant, .PredictionAccuracyHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyOperationInvariant
  | .s397_p01 | .s397_p02 | .s397_p03 => .SafetyOperationInvariant
  -- DegradationModelPolicy
  | .s397_p04 | .s397_p05 | .s397_p06 => .DegradationModelPolicy
  -- PredictionAccuracyHypothesis
  | .s397_p07 | .s397_p08 | .s397_p09 | .s397_p10 | .s397_p11 => .PredictionAccuracyHypothesis

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

end TestCoverage.S397

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FairnessInvariant** (ord=5): 人種・性別・宗教等による差別禁止の絶対不変条件 [C1]
- **RegulatoryCompliance** (ord=4): 金融庁規制・貸金業法・公正信用報告法への適合 [C2, C3]
- **RiskPolicy** (ord=3): デフォルトリスク許容・担保評価・与信限度方針 [C4, H1]
- **ModelGovernance** (ord=2): モデル説明可能性・ドリフト検知・再学習方針 [C5, H2, H3]
- **PredictionHypothesis** (ord=1): 返済能力・行動特徴に基づく信用予測の推論仮説 [H4, H5, H6]
-/

namespace TestCoverage.S342

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s342_p01
  | s342_p02
  | s342_p03
  | s342_p04
  | s342_p05
  | s342_p06
  | s342_p07
  | s342_p08
  | s342_p09
  | s342_p10
  | s342_p11
  | s342_p12
  | s342_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s342_p01 => []
  | .s342_p02 => [.s342_p01]
  | .s342_p03 => [.s342_p01]
  | .s342_p04 => [.s342_p02]
  | .s342_p05 => [.s342_p03]
  | .s342_p06 => [.s342_p04]
  | .s342_p07 => [.s342_p05]
  | .s342_p08 => [.s342_p06, .s342_p07]
  | .s342_p09 => [.s342_p06]
  | .s342_p10 => [.s342_p07]
  | .s342_p11 => [.s342_p09]
  | .s342_p12 => [.s342_p08, .s342_p10]
  | .s342_p13 => [.s342_p11, .s342_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人種・性別・宗教等による差別禁止の絶対不変条件 (ord=5) -/
  | FairnessInvariant
  /-- 金融庁規制・貸金業法・公正信用報告法への適合 (ord=4) -/
  | RegulatoryCompliance
  /-- デフォルトリスク許容・担保評価・与信限度方針 (ord=3) -/
  | RiskPolicy
  /-- モデル説明可能性・ドリフト検知・再学習方針 (ord=2) -/
  | ModelGovernance
  /-- 返済能力・行動特徴に基づく信用予測の推論仮説 (ord=1) -/
  | PredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FairnessInvariant => 5
  | .RegulatoryCompliance => 4
  | .RiskPolicy => 3
  | .ModelGovernance => 2
  | .PredictionHypothesis => 1

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
  bottom := .PredictionHypothesis
  nontrivial := ⟨.FairnessInvariant, .PredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FairnessInvariant
  | .s342_p01 => .FairnessInvariant
  -- RegulatoryCompliance
  | .s342_p02 | .s342_p03 => .RegulatoryCompliance
  -- RiskPolicy
  | .s342_p04 | .s342_p05 => .RiskPolicy
  -- ModelGovernance
  | .s342_p06 | .s342_p07 | .s342_p08 => .ModelGovernance
  -- PredictionHypothesis
  | .s342_p09 | .s342_p10 | .s342_p11 | .s342_p12 | .s342_p13 => .PredictionHypothesis

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

end TestCoverage.S342

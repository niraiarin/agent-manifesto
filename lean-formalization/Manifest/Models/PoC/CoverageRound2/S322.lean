/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **clinical_safety** (ord=4): 臨床判断の安全性に関する絶対不変条件 [C1, C5]
- **regulatory_standard** (ord=3): ACMG/AMP基準・データ保護規制への適合 [C2, C3]
- **pipeline_policy** (ord=2): パイプライン運用方針・再現性・パフォーマンス要件 [C4, C6, H1, H3]
- **inference_model** (ord=1): 変異分類・スコアリングのMLモデル仮説 [H2, H4, H5]
-/

namespace TestCoverage.S322

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s322_p01
  | s322_p02
  | s322_p03
  | s322_p04
  | s322_p05
  | s322_p06
  | s322_p07
  | s322_p08
  | s322_p09
  | s322_p10
  | s322_p11
  | s322_p12
  | s322_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s322_p01 => []
  | .s322_p02 => [.s322_p01]
  | .s322_p03 => [.s322_p02]
  | .s322_p04 => [.s322_p01]
  | .s322_p05 => []
  | .s322_p06 => [.s322_p04, .s322_p05]
  | .s322_p07 => [.s322_p04]
  | .s322_p08 => [.s322_p07]
  | .s322_p09 => [.s322_p03]
  | .s322_p10 => [.s322_p07, .s322_p08]
  | .s322_p11 => [.s322_p09]
  | .s322_p12 => [.s322_p05]
  | .s322_p13 => [.s322_p11, .s322_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 臨床判断の安全性に関する絶対不変条件 (ord=4) -/
  | clinical_safety
  /-- ACMG/AMP基準・データ保護規制への適合 (ord=3) -/
  | regulatory_standard
  /-- パイプライン運用方針・再現性・パフォーマンス要件 (ord=2) -/
  | pipeline_policy
  /-- 変異分類・スコアリングのMLモデル仮説 (ord=1) -/
  | inference_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .clinical_safety => 4
  | .regulatory_standard => 3
  | .pipeline_policy => 2
  | .inference_model => 1

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
  bottom := .inference_model
  nontrivial := ⟨.clinical_safety, .inference_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- clinical_safety
  | .s322_p01 | .s322_p02 | .s322_p03 => .clinical_safety
  -- regulatory_standard
  | .s322_p04 | .s322_p05 | .s322_p06 => .regulatory_standard
  -- pipeline_policy
  | .s322_p07 | .s322_p08 | .s322_p09 | .s322_p10 => .pipeline_policy
  -- inference_model
  | .s322_p11 | .s322_p12 | .s322_p13 => .inference_model

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

end TestCoverage.S322

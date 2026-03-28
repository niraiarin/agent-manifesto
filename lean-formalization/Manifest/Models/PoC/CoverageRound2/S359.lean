/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ConstructionSafetyInvariant** (ord=4): 作業員の生命安全・重大事故防止の絶対的工事安全制約 [C1, C2]
- **RegulatoryCompliance** (ord=3): 建設業法・労働安全衛生法・建築基準法への適合要件 [C3, C4]
- **ProjectManagementPolicy** (ord=2): 工程計画・資材調達・サブコン管理・品質検査の施工管理方針 [C5, H1, H2]
- **ProgressForecastHypothesis** (ord=1): 完工予測・遅延リスク・コスト超過に関する進捗予測仮説 [H3, H4, H5]
-/

namespace TestCoverage.S359

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s359_p01
  | s359_p02
  | s359_p03
  | s359_p04
  | s359_p05
  | s359_p06
  | s359_p07
  | s359_p08
  | s359_p09
  | s359_p10
  | s359_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s359_p01 => []
  | .s359_p02 => [.s359_p01]
  | .s359_p03 => [.s359_p01]
  | .s359_p04 => [.s359_p02]
  | .s359_p05 => [.s359_p03]
  | .s359_p06 => [.s359_p04]
  | .s359_p07 => [.s359_p03, .s359_p04]
  | .s359_p08 => [.s359_p05]
  | .s359_p09 => [.s359_p06]
  | .s359_p10 => [.s359_p07, .s359_p08]
  | .s359_p11 => [.s359_p09, .s359_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 作業員の生命安全・重大事故防止の絶対的工事安全制約 (ord=4) -/
  | ConstructionSafetyInvariant
  /-- 建設業法・労働安全衛生法・建築基準法への適合要件 (ord=3) -/
  | RegulatoryCompliance
  /-- 工程計画・資材調達・サブコン管理・品質検査の施工管理方針 (ord=2) -/
  | ProjectManagementPolicy
  /-- 完工予測・遅延リスク・コスト超過に関する進捗予測仮説 (ord=1) -/
  | ProgressForecastHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ConstructionSafetyInvariant => 4
  | .RegulatoryCompliance => 3
  | .ProjectManagementPolicy => 2
  | .ProgressForecastHypothesis => 1

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
  bottom := .ProgressForecastHypothesis
  nontrivial := ⟨.ConstructionSafetyInvariant, .ProgressForecastHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ConstructionSafetyInvariant
  | .s359_p01 | .s359_p02 => .ConstructionSafetyInvariant
  -- RegulatoryCompliance
  | .s359_p03 | .s359_p04 => .RegulatoryCompliance
  -- ProjectManagementPolicy
  | .s359_p05 | .s359_p06 | .s359_p07 => .ProjectManagementPolicy
  -- ProgressForecastHypothesis
  | .s359_p08 | .s359_p09 | .s359_p10 | .s359_p11 => .ProgressForecastHypothesis

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

end TestCoverage.S359

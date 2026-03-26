/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **MaritimeLaw** (ord=5): 海上運送法・国際海事条約。法的義務として不変 [C1]
- **CustomsCompliance** (ord=4): 通関手続き・関税法規。各国規制に基づく [C2, H1]
- **CarrierContract** (ord=3): 船会社との契約条件。商業的合意に基づく [C3, H2]
- **RoutingOptimization** (ord=2): 航路最適化・ETA予測の運用ルール [C4, H3, H4]
- **VisibilityHypothesis** (ord=1): リアルタイム可視化・異常検知の技術的仮説 [C5, H5, H6]
-/

namespace TestCoverage.S106

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s106_p01
  | s106_p02
  | s106_p03
  | s106_p04
  | s106_p05
  | s106_p06
  | s106_p07
  | s106_p08
  | s106_p09
  | s106_p10
  | s106_p11
  | s106_p12
  | s106_p13
  | s106_p14
  | s106_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s106_p01 => []
  | .s106_p02 => []
  | .s106_p03 => [.s106_p01]
  | .s106_p04 => [.s106_p01, .s106_p02]
  | .s106_p05 => [.s106_p03]
  | .s106_p06 => [.s106_p03, .s106_p04]
  | .s106_p07 => [.s106_p04]
  | .s106_p08 => [.s106_p05]
  | .s106_p09 => [.s106_p06]
  | .s106_p10 => [.s106_p05, .s106_p07]
  | .s106_p11 => [.s106_p08]
  | .s106_p12 => [.s106_p09]
  | .s106_p13 => [.s106_p10]
  | .s106_p14 => [.s106_p11, .s106_p12]
  | .s106_p15 => [.s106_p08, .s106_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海上運送法・国際海事条約。法的義務として不変 (ord=5) -/
  | MaritimeLaw
  /-- 通関手続き・関税法規。各国規制に基づく (ord=4) -/
  | CustomsCompliance
  /-- 船会社との契約条件。商業的合意に基づく (ord=3) -/
  | CarrierContract
  /-- 航路最適化・ETA予測の運用ルール (ord=2) -/
  | RoutingOptimization
  /-- リアルタイム可視化・異常検知の技術的仮説 (ord=1) -/
  | VisibilityHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .MaritimeLaw => 5
  | .CustomsCompliance => 4
  | .CarrierContract => 3
  | .RoutingOptimization => 2
  | .VisibilityHypothesis => 1

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
  bottom := .VisibilityHypothesis
  nontrivial := ⟨.MaritimeLaw, .VisibilityHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- MaritimeLaw
  | .s106_p01 | .s106_p02 => .MaritimeLaw
  -- CustomsCompliance
  | .s106_p03 | .s106_p04 => .CustomsCompliance
  -- CarrierContract
  | .s106_p05 | .s106_p06 | .s106_p07 => .CarrierContract
  -- RoutingOptimization
  | .s106_p08 | .s106_p09 | .s106_p10 => .RoutingOptimization
  -- VisibilityHypothesis
  | .s106_p11 | .s106_p12 | .s106_p13 | .s106_p14 | .s106_p15 => .VisibilityHypothesis

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

end TestCoverage.S106

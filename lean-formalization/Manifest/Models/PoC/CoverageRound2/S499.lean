/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LifeSafetyInvariant** (ord=4): 建物倒壊・人命損失を防ぐ耐震安全性の絶対不変条件 [C1, C2]
- **BuildingCodeCompliance** (ord=3): 建築基準法・耐震改修促進法・国土交通省告示への準拠要件 [C3, C4]
- **DiagnosticPolicy** (ord=2): 診断手法選択・調査項目・評点算定に関する診断ポリシー [C5, H1, H2]
- **RecommendationHeuristic** (ord=1): 補強優先度・費用対効果・工法選択に関する推奨ヒューリスティック [H3, H4, H5]
-/

namespace TestCoverage.S499

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s499_p01
  | s499_p02
  | s499_p03
  | s499_p04
  | s499_p05
  | s499_p06
  | s499_p07
  | s499_p08
  | s499_p09
  | s499_p10
  | s499_p11
  | s499_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s499_p01 => []
  | .s499_p02 => [.s499_p01]
  | .s499_p03 => [.s499_p01]
  | .s499_p04 => [.s499_p02]
  | .s499_p05 => [.s499_p03, .s499_p04]
  | .s499_p06 => [.s499_p03]
  | .s499_p07 => [.s499_p04]
  | .s499_p08 => [.s499_p05, .s499_p06]
  | .s499_p09 => [.s499_p06]
  | .s499_p10 => [.s499_p08]
  | .s499_p11 => [.s499_p09, .s499_p10]
  | .s499_p12 => [.s499_p07, .s499_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 建物倒壊・人命損失を防ぐ耐震安全性の絶対不変条件 (ord=4) -/
  | LifeSafetyInvariant
  /-- 建築基準法・耐震改修促進法・国土交通省告示への準拠要件 (ord=3) -/
  | BuildingCodeCompliance
  /-- 診断手法選択・調査項目・評点算定に関する診断ポリシー (ord=2) -/
  | DiagnosticPolicy
  /-- 補強優先度・費用対効果・工法選択に関する推奨ヒューリスティック (ord=1) -/
  | RecommendationHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LifeSafetyInvariant => 4
  | .BuildingCodeCompliance => 3
  | .DiagnosticPolicy => 2
  | .RecommendationHeuristic => 1

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
  bottom := .RecommendationHeuristic
  nontrivial := ⟨.LifeSafetyInvariant, .RecommendationHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LifeSafetyInvariant
  | .s499_p01 | .s499_p02 => .LifeSafetyInvariant
  -- BuildingCodeCompliance
  | .s499_p03 | .s499_p04 | .s499_p05 => .BuildingCodeCompliance
  -- DiagnosticPolicy
  | .s499_p06 | .s499_p07 | .s499_p08 => .DiagnosticPolicy
  -- RecommendationHeuristic
  | .s499_p09 | .s499_p10 | .s499_p11 | .s499_p12 => .RecommendationHeuristic

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

end TestCoverage.S499

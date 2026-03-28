/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PrivacyInvariant** (ord=3): 個人識別情報の完全削除・再識別不可能性の絶対保証（GDPR・個人情報保護法準拠） [C1, C2]
- **DataUtilityPolicy** (ord=2): 匿名化後データの統計的有用性・分析適合性を維持する方針 [C3, C4, C5]
- **AnonymizationTechHypothesis** (ord=1): k-匿名性・差分プライバシー・擬似匿名化手法の有効性に関する仮説 [H1, H2, H3, H4, H5, H6]
-/

namespace TestCoverage.S395

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s395_p01
  | s395_p02
  | s395_p03
  | s395_p04
  | s395_p05
  | s395_p06
  | s395_p07
  | s395_p08
  | s395_p09
  | s395_p10
  | s395_p11
  | s395_p12
  | s395_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s395_p01 => []
  | .s395_p02 => []
  | .s395_p03 => [.s395_p01, .s395_p02]
  | .s395_p04 => [.s395_p01]
  | .s395_p05 => [.s395_p02]
  | .s395_p06 => [.s395_p03]
  | .s395_p07 => [.s395_p04, .s395_p05, .s395_p06]
  | .s395_p08 => [.s395_p04]
  | .s395_p09 => [.s395_p05]
  | .s395_p10 => [.s395_p07]
  | .s395_p11 => [.s395_p08]
  | .s395_p12 => [.s395_p09]
  | .s395_p13 => [.s395_p10, .s395_p11, .s395_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 個人識別情報の完全削除・再識別不可能性の絶対保証（GDPR・個人情報保護法準拠） (ord=3) -/
  | PrivacyInvariant
  /-- 匿名化後データの統計的有用性・分析適合性を維持する方針 (ord=2) -/
  | DataUtilityPolicy
  /-- k-匿名性・差分プライバシー・擬似匿名化手法の有効性に関する仮説 (ord=1) -/
  | AnonymizationTechHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PrivacyInvariant => 3
  | .DataUtilityPolicy => 2
  | .AnonymizationTechHypothesis => 1

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
  bottom := .AnonymizationTechHypothesis
  nontrivial := ⟨.PrivacyInvariant, .AnonymizationTechHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PrivacyInvariant
  | .s395_p01 | .s395_p02 | .s395_p03 => .PrivacyInvariant
  -- DataUtilityPolicy
  | .s395_p04 | .s395_p05 | .s395_p06 | .s395_p07 => .DataUtilityPolicy
  -- AnonymizationTechHypothesis
  | .s395_p08 | .s395_p09 | .s395_p10 | .s395_p11 | .s395_p12 | .s395_p13 => .AnonymizationTechHypothesis

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

end TestCoverage.S395

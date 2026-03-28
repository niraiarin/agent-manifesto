/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ContentIntegrityInvariant** (ord=3): 翻訳内容の意味的正確性・有害コンテンツ排除の不変制約 [C1, C2]
- **QualityStandardPolicy** (ord=2): 翻訳品質基準・レビュープロセス・承認ゲート。事業基準に基づくポリシー [C3, H1, H2]
- **AdaptationHypothesis** (ord=1): ドメイン特化モデル改善・文脈適応の仮説。フィードバックで更新 [H3, H4, H5]
-/

namespace TestCoverage.S403

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s403_p01
  | s403_p02
  | s403_p03
  | s403_p04
  | s403_p05
  | s403_p06
  | s403_p07
  | s403_p08
  | s403_p09
  | s403_p10
  | s403_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s403_p01 => []
  | .s403_p02 => []
  | .s403_p03 => [.s403_p01, .s403_p02]
  | .s403_p04 => [.s403_p01]
  | .s403_p05 => [.s403_p02]
  | .s403_p06 => [.s403_p03]
  | .s403_p07 => [.s403_p04, .s403_p05]
  | .s403_p08 => [.s403_p04]
  | .s403_p09 => [.s403_p05]
  | .s403_p10 => [.s403_p06]
  | .s403_p11 => [.s403_p07, .s403_p08, .s403_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 翻訳内容の意味的正確性・有害コンテンツ排除の不変制約 (ord=3) -/
  | ContentIntegrityInvariant
  /-- 翻訳品質基準・レビュープロセス・承認ゲート。事業基準に基づくポリシー (ord=2) -/
  | QualityStandardPolicy
  /-- ドメイン特化モデル改善・文脈適応の仮説。フィードバックで更新 (ord=1) -/
  | AdaptationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ContentIntegrityInvariant => 3
  | .QualityStandardPolicy => 2
  | .AdaptationHypothesis => 1

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
  bottom := .AdaptationHypothesis
  nontrivial := ⟨.ContentIntegrityInvariant, .AdaptationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ContentIntegrityInvariant
  | .s403_p01 | .s403_p02 | .s403_p03 => .ContentIntegrityInvariant
  -- QualityStandardPolicy
  | .s403_p04 | .s403_p05 | .s403_p06 | .s403_p07 => .QualityStandardPolicy
  -- AdaptationHypothesis
  | .s403_p08 | .s403_p09 | .s403_p10 | .s403_p11 => .AdaptationHypothesis

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

end TestCoverage.S403

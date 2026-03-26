/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AccessibilityRight** (ord=5): 障害者の情報アクセス権。障害者権利条約・障害者差別解消法に基づく不可侵の権利 [C1, C2]
- **LinguisticIntegrity** (ord=4): 手話の言語学的正確性。手話は独立した言語であり、日本語の単純変換ではない [C3, H1]
- **CulturalNorm** (ord=3): ろう文化の規範と慣習。コミュニティの承認に基づく [C4, H2]
- **TranslationPolicy** (ord=2): 翻訳品質・速度のトレードオフに関する運用方針 [C5, H3]
- **TechnicalHypothesis** (ord=1): 未検証の技術的仮説。精度改善のための実験的アプローチ [C6, H4, H5]
-/

namespace TestCoverage.S101

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s101_p01
  | s101_p02
  | s101_p03
  | s101_p04
  | s101_p05
  | s101_p06
  | s101_p07
  | s101_p08
  | s101_p09
  | s101_p10
  | s101_p11
  | s101_p12
  | s101_p13
  | s101_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s101_p01 => []
  | .s101_p02 => []
  | .s101_p03 => []
  | .s101_p04 => [.s101_p01]
  | .s101_p05 => [.s101_p02]
  | .s101_p06 => [.s101_p04]
  | .s101_p07 => [.s101_p04, .s101_p05]
  | .s101_p08 => [.s101_p06]
  | .s101_p09 => [.s101_p07]
  | .s101_p10 => [.s101_p06, .s101_p07]
  | .s101_p11 => [.s101_p08]
  | .s101_p12 => [.s101_p09]
  | .s101_p13 => [.s101_p10]
  | .s101_p14 => [.s101_p11, .s101_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 障害者の情報アクセス権。障害者権利条約・障害者差別解消法に基づく不可侵の権利 (ord=5) -/
  | AccessibilityRight
  /-- 手話の言語学的正確性。手話は独立した言語であり、日本語の単純変換ではない (ord=4) -/
  | LinguisticIntegrity
  /-- ろう文化の規範と慣習。コミュニティの承認に基づく (ord=3) -/
  | CulturalNorm
  /-- 翻訳品質・速度のトレードオフに関する運用方針 (ord=2) -/
  | TranslationPolicy
  /-- 未検証の技術的仮説。精度改善のための実験的アプローチ (ord=1) -/
  | TechnicalHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AccessibilityRight => 5
  | .LinguisticIntegrity => 4
  | .CulturalNorm => 3
  | .TranslationPolicy => 2
  | .TechnicalHypothesis => 1

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
  bottom := .TechnicalHypothesis
  nontrivial := ⟨.AccessibilityRight, .TechnicalHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AccessibilityRight
  | .s101_p01 | .s101_p02 | .s101_p03 => .AccessibilityRight
  -- LinguisticIntegrity
  | .s101_p04 | .s101_p05 => .LinguisticIntegrity
  -- CulturalNorm
  | .s101_p06 | .s101_p07 => .CulturalNorm
  -- TranslationPolicy
  | .s101_p08 | .s101_p09 | .s101_p10 => .TranslationPolicy
  -- TechnicalHypothesis
  | .s101_p11 | .s101_p12 | .s101_p13 | .s101_p14 => .TechnicalHypothesis

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

end TestCoverage.S101

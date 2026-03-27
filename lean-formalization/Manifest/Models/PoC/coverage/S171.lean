/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AccessibilityRight** (ord=4): 情報アクセス権に関わる不変制約。障害者権利条約に基づく [C1, C2]
- **LinguisticRule** (ord=3): 点字表記の言語学的規則。標準化団体の規定に準拠 [C3, H1]
- **TranslationDesign** (ord=2): 翻訳エンジンの設計選択。精度と速度のトレードオフ [C4, H2, H3]
- **OutputHypothesis** (ord=1): 出力品質に関する未検証の仮説 [C5, H4, H5]
-/

namespace TestCoverage.S171

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s171_p01
  | s171_p02
  | s171_p03
  | s171_p04
  | s171_p05
  | s171_p06
  | s171_p07
  | s171_p08
  | s171_p09
  | s171_p10
  | s171_p11
  | s171_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s171_p01 => []
  | .s171_p02 => []
  | .s171_p03 => []
  | .s171_p04 => [.s171_p01]
  | .s171_p05 => [.s171_p02]
  | .s171_p06 => [.s171_p01, .s171_p03]
  | .s171_p07 => [.s171_p04]
  | .s171_p08 => [.s171_p05]
  | .s171_p09 => [.s171_p04, .s171_p06]
  | .s171_p10 => [.s171_p07]
  | .s171_p11 => [.s171_p08, .s171_p09]
  | .s171_p12 => [.s171_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 情報アクセス権に関わる不変制約。障害者権利条約に基づく (ord=4) -/
  | AccessibilityRight
  /-- 点字表記の言語学的規則。標準化団体の規定に準拠 (ord=3) -/
  | LinguisticRule
  /-- 翻訳エンジンの設計選択。精度と速度のトレードオフ (ord=2) -/
  | TranslationDesign
  /-- 出力品質に関する未検証の仮説 (ord=1) -/
  | OutputHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AccessibilityRight => 4
  | .LinguisticRule => 3
  | .TranslationDesign => 2
  | .OutputHypothesis => 1

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
  bottom := .OutputHypothesis
  nontrivial := ⟨.AccessibilityRight, .OutputHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AccessibilityRight
  | .s171_p01 | .s171_p02 | .s171_p03 => .AccessibilityRight
  -- LinguisticRule
  | .s171_p04 | .s171_p05 | .s171_p06 => .LinguisticRule
  -- TranslationDesign
  | .s171_p07 | .s171_p08 | .s171_p09 => .TranslationDesign
  -- OutputHypothesis
  | .s171_p10 | .s171_p11 | .s171_p12 => .OutputHypothesis

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

end TestCoverage.S171

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ethical_constraint** (ord=5): 倫理・プライバシー制約。翻訳の中立性とデータ保護 [C1, C2]
- **linguistic_postulate** (ord=4): 言語学的前提。対応言語と翻訳品質の基盤 [C3, H1]
- **interaction_principle** (ord=2): 対話設計の原則。UXとコンテキスト管理 [C4, C5, H2]
- **feature_hypothesis** (ord=0): 機能仮説。検証により変更可能 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | translation_neutrality
  | user_data_privacy
  | supported_language_pairs
  | translation_quality_baseline
  | context_window_size
  | fallback_to_human_translator
  | slang_handling
  | emoji_translation
  | conversation_summary
  | no_harmful_content_translation
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .translation_neutrality => []
  | .user_data_privacy => []
  | .supported_language_pairs => []
  | .translation_quality_baseline => []
  | .context_window_size => []
  | .fallback_to_human_translator => []
  | .slang_handling => []
  | .emoji_translation => []
  | .conversation_summary => []
  | .no_harmful_content_translation => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 倫理・プライバシー制約。翻訳の中立性とデータ保護 (ord=5) -/
  | ethical_constraint
  /-- 言語学的前提。対応言語と翻訳品質の基盤 (ord=4) -/
  | linguistic_postulate
  /-- 対話設計の原則。UXとコンテキスト管理 (ord=2) -/
  | interaction_principle
  /-- 機能仮説。検証により変更可能 (ord=0) -/
  | feature_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ethical_constraint => 5
  | .linguistic_postulate => 4
  | .interaction_principle => 2
  | .feature_hypothesis => 0

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
  bottom := .feature_hypothesis
  nontrivial := ⟨.ethical_constraint, .feature_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ethical_constraint
  | .translation_neutrality | .user_data_privacy | .no_harmful_content_translation => .ethical_constraint
  -- linguistic_postulate
  | .supported_language_pairs | .translation_quality_baseline => .linguistic_postulate
  -- interaction_principle
  | .context_window_size | .fallback_to_human_translator => .interaction_principle
  -- feature_hypothesis
  | .slang_handling | .emoji_translation | .conversation_summary => .feature_hypothesis

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

end Manifest.Models

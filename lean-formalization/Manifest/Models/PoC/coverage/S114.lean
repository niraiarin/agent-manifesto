/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **math_syntax** (ord=3): 数学記法の構文規則。LaTeX/MathML 仕様に基づく不変制約 [C1, C2]
- **recognition_model** (ord=2): ストローク認識・記号分類の学習済みモデル知見 [C4, H1, H3]
- **pipeline** (ord=1): 前処理・セグメンテーション・後処理のパイプライン構成 [C3, H4, H5]
- **hypothesis** (ord=0): 未検証の認識改善仮説 [H6, H7]
-/

namespace HandwrittenMathOCR

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | syn_latex_valid
  | syn_operator_prec
  | syn_structure
  | rec_cnn_base
  | rec_spatial
  | rec_context
  | rec_augment
  | pip_segment
  | pip_postproc
  | pip_feedback
  | pip_realtime
  | pip_batch
  | hyp_transformer
  | hyp_few_shot
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .syn_latex_valid => []
  | .syn_operator_prec => []
  | .syn_structure => []
  | .rec_cnn_base => []
  | .rec_spatial => [.rec_cnn_base]
  | .rec_context => [.syn_operator_prec]
  | .rec_augment => [.rec_cnn_base]
  | .pip_segment => [.rec_spatial]
  | .pip_postproc => [.syn_latex_valid, .rec_context]
  | .pip_feedback => [.pip_segment, .pip_postproc]
  | .pip_realtime => [.rec_cnn_base]
  | .pip_batch => [.pip_segment, .syn_structure]
  | .hyp_transformer => [.rec_cnn_base, .rec_spatial]
  | .hyp_few_shot => [.rec_augment, .pip_feedback]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 数学記法の構文規則。LaTeX/MathML 仕様に基づく不変制約 (ord=3) -/
  | math_syntax
  /-- ストローク認識・記号分類の学習済みモデル知見 (ord=2) -/
  | recognition_model
  /-- 前処理・セグメンテーション・後処理のパイプライン構成 (ord=1) -/
  | pipeline
  /-- 未検証の認識改善仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .math_syntax => 3
  | .recognition_model => 2
  | .pipeline => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.math_syntax, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- math_syntax
  | .syn_latex_valid | .syn_operator_prec | .syn_structure => .math_syntax
  -- recognition_model
  | .rec_cnn_base | .rec_spatial | .rec_context | .rec_augment => .recognition_model
  -- pipeline
  | .pip_segment | .pip_postproc | .pip_feedback | .pip_realtime | .pip_batch => .pipeline
  -- hypothesis
  | .hyp_transformer | .hyp_few_shot => .hypothesis

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

end HandwrittenMathOCR

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **editorial_invariant** (ord=4): 言論の自由・中立性・表現保護に関する絶対不変条件 [C1, C2, C6]
- **transparency_standard** (ord=3): 根拠明示・異議申し立て・説明可能性の要件 [C3, C4]
- **operational_policy** (ord=2): リアルタイム処理・キュレーター監督・異議対応の運用方針 [C5, H3, H5]
- **learning_model** (ord=1): 知識グラフ照合・アンサンブル・フィードバック学習の仮説 [H1, H2, H4]
-/

namespace TestCoverage.S327

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s327_p01
  | s327_p02
  | s327_p03
  | s327_p04
  | s327_p05
  | s327_p06
  | s327_p07
  | s327_p08
  | s327_p09
  | s327_p10
  | s327_p11
  | s327_p12
  | s327_p13
  | s327_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s327_p01 => []
  | .s327_p02 => []
  | .s327_p03 => [.s327_p01, .s327_p02]
  | .s327_p04 => [.s327_p01]
  | .s327_p05 => [.s327_p04]
  | .s327_p06 => [.s327_p04, .s327_p05]
  | .s327_p07 => [.s327_p04]
  | .s327_p08 => [.s327_p02, .s327_p03]
  | .s327_p09 => [.s327_p05, .s327_p07]
  | .s327_p10 => [.s327_p07, .s327_p08]
  | .s327_p11 => [.s327_p04, .s327_p07]
  | .s327_p12 => [.s327_p01, .s327_p02]
  | .s327_p13 => [.s327_p02]
  | .s327_p14 => [.s327_p11, .s327_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 言論の自由・中立性・表現保護に関する絶対不変条件 (ord=4) -/
  | editorial_invariant
  /-- 根拠明示・異議申し立て・説明可能性の要件 (ord=3) -/
  | transparency_standard
  /-- リアルタイム処理・キュレーター監督・異議対応の運用方針 (ord=2) -/
  | operational_policy
  /-- 知識グラフ照合・アンサンブル・フィードバック学習の仮説 (ord=1) -/
  | learning_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .editorial_invariant => 4
  | .transparency_standard => 3
  | .operational_policy => 2
  | .learning_model => 1

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
  bottom := .learning_model
  nontrivial := ⟨.editorial_invariant, .learning_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- editorial_invariant
  | .s327_p01 | .s327_p02 | .s327_p03 => .editorial_invariant
  -- transparency_standard
  | .s327_p04 | .s327_p05 | .s327_p06 => .transparency_standard
  -- operational_policy
  | .s327_p07 | .s327_p08 | .s327_p09 | .s327_p10 => .operational_policy
  -- learning_model
  | .s327_p11 | .s327_p12 | .s327_p13 | .s327_p14 => .learning_model

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

end TestCoverage.S327

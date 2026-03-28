/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **legal_invariant** (ord=4): 法的責任・人間最終判断の絶対要件 [C1, C5]
- **security_compliance** (ord=3): データ保護・法域対応の規制遵守要件 [C2, C6]
- **review_model** (ord=2): 契約書解析・リスク検出・説明生成のモデル [C3, C4, H1]
- **adoption_hypothesis** (ord=1): 弁護士採用・ワークフロー統合の仮説 [H2, H3, H4]
-/

namespace TestCoverage.S315

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s315_p01
  | s315_p02
  | s315_p03
  | s315_p04
  | s315_p05
  | s315_p06
  | s315_p07
  | s315_p08
  | s315_p09
  | s315_p10
  | s315_p11
  | s315_p12
  | s315_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s315_p01 => []
  | .s315_p02 => [.s315_p01]
  | .s315_p03 => []
  | .s315_p04 => [.s315_p03]
  | .s315_p05 => [.s315_p02, .s315_p04]
  | .s315_p06 => [.s315_p05]
  | .s315_p07 => [.s315_p05]
  | .s315_p08 => [.s315_p06]
  | .s315_p09 => [.s315_p04, .s315_p08]
  | .s315_p10 => [.s315_p06, .s315_p09]
  | .s315_p11 => [.s315_p07, .s315_p10]
  | .s315_p12 => [.s315_p02, .s315_p08]
  | .s315_p13 => [.s315_p10, .s315_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法的責任・人間最終判断の絶対要件 (ord=4) -/
  | legal_invariant
  /-- データ保護・法域対応の規制遵守要件 (ord=3) -/
  | security_compliance
  /-- 契約書解析・リスク検出・説明生成のモデル (ord=2) -/
  | review_model
  /-- 弁護士採用・ワークフロー統合の仮説 (ord=1) -/
  | adoption_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .legal_invariant => 4
  | .security_compliance => 3
  | .review_model => 2
  | .adoption_hypothesis => 1

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
  bottom := .adoption_hypothesis
  nontrivial := ⟨.legal_invariant, .adoption_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- legal_invariant
  | .s315_p01 | .s315_p02 => .legal_invariant
  -- security_compliance
  | .s315_p03 | .s315_p04 => .security_compliance
  -- review_model
  | .s315_p05 | .s315_p06 | .s315_p07 | .s315_p08 | .s315_p12 => .review_model
  -- adoption_hypothesis
  | .s315_p09 | .s315_p10 | .s315_p11 | .s315_p13 => .adoption_hypothesis

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

end TestCoverage.S315

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_core** (ord=4): 衝突回避・フォールバック手順の絶対安全要件 [C1, C2, C4]
- **regulatory_compliance** (ord=3): ICAO/RASA規制への適合要件 [C2, C7]
- **operational_support** (ord=2): 管制官支援・気象統合・容量管理の運用機能 [C3, C5, C6, H1]
- **learning_hypothesis** (ord=1): AIモデル更新・フィードバック利用の仮説 [H2, H3, H4]
-/

namespace TestCoverage.S313

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s313_p01
  | s313_p02
  | s313_p03
  | s313_p04
  | s313_p05
  | s313_p06
  | s313_p07
  | s313_p08
  | s313_p09
  | s313_p10
  | s313_p11
  | s313_p12
  | s313_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s313_p01 => []
  | .s313_p02 => []
  | .s313_p03 => [.s313_p02]
  | .s313_p04 => [.s313_p01]
  | .s313_p05 => [.s313_p02]
  | .s313_p06 => [.s313_p05]
  | .s313_p07 => [.s313_p04]
  | .s313_p08 => [.s313_p01, .s313_p05]
  | .s313_p09 => [.s313_p08]
  | .s313_p10 => [.s313_p06, .s313_p07]
  | .s313_p11 => [.s313_p05, .s313_p08]
  | .s313_p12 => [.s313_p09, .s313_p11]
  | .s313_p13 => [.s313_p06, .s313_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 衝突回避・フォールバック手順の絶対安全要件 (ord=4) -/
  | safety_core
  /-- ICAO/RASA規制への適合要件 (ord=3) -/
  | regulatory_compliance
  /-- 管制官支援・気象統合・容量管理の運用機能 (ord=2) -/
  | operational_support
  /-- AIモデル更新・フィードバック利用の仮説 (ord=1) -/
  | learning_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_core => 4
  | .regulatory_compliance => 3
  | .operational_support => 2
  | .learning_hypothesis => 1

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
  bottom := .learning_hypothesis
  nontrivial := ⟨.safety_core, .learning_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_core
  | .s313_p01 | .s313_p02 | .s313_p03 | .s313_p04 => .safety_core
  -- regulatory_compliance
  | .s313_p05 | .s313_p06 => .regulatory_compliance
  -- operational_support
  | .s313_p07 | .s313_p08 | .s313_p09 | .s313_p10 => .operational_support
  -- learning_hypothesis
  | .s313_p11 | .s313_p12 | .s313_p13 => .learning_hypothesis

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

end TestCoverage.S313

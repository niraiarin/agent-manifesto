/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LifeSafetyInvariant** (ord=4): 要救助者の生命を最優先する絶対不変条件 [C1, C2]
- **EvacuationPolicy** (ord=3): 避難経路決定・優先順位付け・情報発信の方針 [C3, C4, H1]
- **ResourceModel** (ord=2): 救助資源・避難所キャパシティ・輸送手段の配分モデル [C5, H2, H3]
- **DisasterHypothesis** (ord=1): 被災規模推定・二次災害リスク予測に関する仮説 [H4, H5]
-/

namespace TestCoverage.S306

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s306_p01
  | s306_p02
  | s306_p03
  | s306_p04
  | s306_p05
  | s306_p06
  | s306_p07
  | s306_p08
  | s306_p09
  | s306_p10
  | s306_p11
  | s306_p12
  | s306_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s306_p01 => []
  | .s306_p02 => []
  | .s306_p03 => [.s306_p01]
  | .s306_p04 => [.s306_p02]
  | .s306_p05 => [.s306_p03]
  | .s306_p06 => [.s306_p03]
  | .s306_p07 => [.s306_p04]
  | .s306_p08 => [.s306_p05, .s306_p06]
  | .s306_p09 => [.s306_p06]
  | .s306_p10 => [.s306_p07]
  | .s306_p11 => [.s306_p08, .s306_p09]
  | .s306_p12 => [.s306_p10]
  | .s306_p13 => [.s306_p11, .s306_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 要救助者の生命を最優先する絶対不変条件 (ord=4) -/
  | LifeSafetyInvariant
  /-- 避難経路決定・優先順位付け・情報発信の方針 (ord=3) -/
  | EvacuationPolicy
  /-- 救助資源・避難所キャパシティ・輸送手段の配分モデル (ord=2) -/
  | ResourceModel
  /-- 被災規模推定・二次災害リスク予測に関する仮説 (ord=1) -/
  | DisasterHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LifeSafetyInvariant => 4
  | .EvacuationPolicy => 3
  | .ResourceModel => 2
  | .DisasterHypothesis => 1

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
  bottom := .DisasterHypothesis
  nontrivial := ⟨.LifeSafetyInvariant, .DisasterHypothesis, by simp [ConcreteLayer.ord]⟩
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
  | .s306_p01 | .s306_p02 => .LifeSafetyInvariant
  -- EvacuationPolicy
  | .s306_p03 | .s306_p04 | .s306_p05 => .EvacuationPolicy
  -- ResourceModel
  | .s306_p06 | .s306_p07 | .s306_p08 => .ResourceModel
  -- DisasterHypothesis
  | .s306_p09 | .s306_p10 | .s306_p11 | .s306_p12 | .s306_p13 => .DisasterHypothesis

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

end TestCoverage.S306

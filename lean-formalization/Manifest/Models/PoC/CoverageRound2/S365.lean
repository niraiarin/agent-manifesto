/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ServiceAvailability** (ord=2): サービス可用性・正規ユーザーアクセス保護の絶対不変条件 [C1, C2, C3]
- **MitigationHypothesis** (ord=1): 攻撃トラフィック識別・レート制限・トラフィック迂回の推論仮説 [C4, H1, H2, H3, H4, H5]
-/

namespace TestCoverage.S365

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s365_p01
  | s365_p02
  | s365_p03
  | s365_p04
  | s365_p05
  | s365_p06
  | s365_p07
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s365_p01 => []
  | .s365_p02 => [.s365_p01]
  | .s365_p03 => [.s365_p01]
  | .s365_p04 => [.s365_p02]
  | .s365_p05 => [.s365_p03]
  | .s365_p06 => [.s365_p04, .s365_p05]
  | .s365_p07 => [.s365_p03, .s365_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- サービス可用性・正規ユーザーアクセス保護の絶対不変条件 (ord=2) -/
  | ServiceAvailability
  /-- 攻撃トラフィック識別・レート制限・トラフィック迂回の推論仮説 (ord=1) -/
  | MitigationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ServiceAvailability => 2
  | .MitigationHypothesis => 1

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
  bottom := .MitigationHypothesis
  nontrivial := ⟨.ServiceAvailability, .MitigationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ServiceAvailability
  | .s365_p01 | .s365_p02 => .ServiceAvailability
  -- MitigationHypothesis
  | .s365_p03 | .s365_p04 | .s365_p05 | .s365_p06 | .s365_p07 => .MitigationHypothesis

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

end TestCoverage.S365

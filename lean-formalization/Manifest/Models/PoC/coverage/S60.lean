/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **compliance** (ord=4): 法規制・倫理の絶対条件 [C2, C4, C5]
- **accountability** (ord=3): 説明責任・監査に関する制約 [C1, C3, H2]
- **riskPolicy** (ord=2): リスク管理の運用方針 [C6, C7, H4]
- **modeling** (ord=1): AIモデルの学習・評価戦略 [H1, H3, H5]
- **hypothesis** (ord=0): 未検証の仮説 [H6]
-/

namespace CreditRisk

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | comp1
  | comp2
  | comp3
  | acc1
  | acc2
  | acc3
  | risk1
  | risk2
  | risk3
  | mod1
  | mod2
  | mod3
  | mod4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .comp1 => []
  | .comp2 => []
  | .comp3 => []
  | .acc1 => [.comp1]
  | .acc2 => [.comp2]
  | .acc3 => [.comp3]
  | .risk1 => [.acc1]
  | .risk2 => [.acc2]
  | .risk3 => [.acc3, .comp3]
  | .mod1 => [.risk1]
  | .mod2 => [.comp3, .risk3]
  | .mod3 => [.risk1, .risk2]
  | .mod4 => [.mod1]
  | .hyp1 => [.mod1]
  | .hyp2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法規制・倫理の絶対条件 (ord=4) -/
  | compliance
  /-- 説明責任・監査に関する制約 (ord=3) -/
  | accountability
  /-- リスク管理の運用方針 (ord=2) -/
  | riskPolicy
  /-- AIモデルの学習・評価戦略 (ord=1) -/
  | modeling
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .compliance => 4
  | .accountability => 3
  | .riskPolicy => 2
  | .modeling => 1
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
  nontrivial := ⟨.compliance, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- compliance
  | .comp1 | .comp2 | .comp3 => .compliance
  -- accountability
  | .acc1 | .acc2 | .acc3 => .accountability
  -- riskPolicy
  | .risk1 | .risk2 | .risk3 => .riskPolicy
  -- modeling
  | .mod1 | .mod2 | .mod3 | .mod4 => .modeling
  -- hypothesis
  | .hyp1 | .hyp2 => .hypothesis

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

end CreditRisk

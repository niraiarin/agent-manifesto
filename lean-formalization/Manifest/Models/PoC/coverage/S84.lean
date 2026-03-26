/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulation** (ord=3): 道路運送車両法・リコール届出に基づく法的義務 [C1, C2, C3]
- **supply_chain** (ord=2): 部品サプライチェーン・車両登録データの外部依存 [H1, H2, H5]
- **policy** (ord=1): メーカーが設定する優先順位・通知方針 [C4, C5, H3]
- **hypothesis** (ord=0): 未検証の影響範囲推定仮説 [H4, H6, H7]
-/

namespace RecallAnalysis

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | reg1
  | reg2
  | reg3
  | sc1
  | sc2
  | sc3
  | pol1
  | pol2
  | pol3
  | pol4
  | pol5
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  | hyp5
  | hyp6
  | hyp7
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .reg1 => []
  | .reg2 => []
  | .reg3 => []
  | .sc1 => []
  | .sc2 => []
  | .sc3 => [.reg1]
  | .pol1 => [.reg1, .reg2]
  | .pol2 => [.reg3, .sc1]
  | .pol3 => [.sc2]
  | .pol4 => [.sc3]
  | .pol5 => [.reg2, .sc1, .sc2]
  | .hyp1 => [.sc1, .sc2, .pol1]
  | .hyp2 => [.pol2, .pol3]
  | .hyp3 => [.pol4, .pol5]
  | .hyp4 => [.hyp1, .hyp2]
  | .hyp5 => [.hyp1]
  | .hyp6 => [.hyp3, .hyp4]
  | .hyp7 => [.hyp5, .hyp6]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 道路運送車両法・リコール届出に基づく法的義務 (ord=3) -/
  | regulation
  /-- 部品サプライチェーン・車両登録データの外部依存 (ord=2) -/
  | supply_chain
  /-- メーカーが設定する優先順位・通知方針 (ord=1) -/
  | policy
  /-- 未検証の影響範囲推定仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulation => 3
  | .supply_chain => 2
  | .policy => 1
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
  nontrivial := ⟨.regulation, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- regulation
  | .reg1 | .reg2 | .reg3 => .regulation
  -- supply_chain
  | .sc1 | .sc2 | .sc3 => .supply_chain
  -- policy
  | .pol1 | .pol2 | .pol3 | .pol4 | .pol5 => .policy
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 | .hyp4 | .hyp5 | .hyp6 | .hyp7 => .hypothesis

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

end RecallAnalysis

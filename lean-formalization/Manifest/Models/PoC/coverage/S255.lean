/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physics** (ord=3): 太陽物理と地球磁気圏の物理法則に基づく制約。 [C1, C5]
- **regulation** (ord=2): 国際規格と業界要件に基づく運用制約。 [C2, C4]
- **modeling** (ord=1): 予測モデルの設計判断。科学的知見の蓄積に応じて改善可能。 [C3, H1, H2]
- **hypothesis** (ord=0): 未検証の仮説。観測データとの照合で検証が必要。 [H3]
-/

namespace Scenario255

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | phy1
  | phy2
  | phy3
  | rul1
  | rul2
  | rul3
  | mod1
  | mod2
  | mod3
  | mod4
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .phy1 => []
  | .phy2 => []
  | .phy3 => []
  | .rul1 => [.phy2]
  | .rul2 => []
  | .rul3 => [.rul1, .rul2]
  | .mod1 => [.phy1, .phy3]
  | .mod2 => [.phy2, .rul1]
  | .mod3 => [.phy1]
  | .mod4 => [.mod1, .mod2]
  | .hyp1 => [.mod3]
  | .hyp2 => [.mod1, .mod4]
  | .hyp3 => [.rul3, .hyp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 太陽物理と地球磁気圏の物理法則に基づく制約。 (ord=3) -/
  | physics
  /-- 国際規格と業界要件に基づく運用制約。 (ord=2) -/
  | regulation
  /-- 予測モデルの設計判断。科学的知見の蓄積に応じて改善可能。 (ord=1) -/
  | modeling
  /-- 未検証の仮説。観測データとの照合で検証が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physics => 3
  | .regulation => 2
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
  nontrivial := ⟨.physics, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physics
  | .phy1 | .phy2 | .phy3 => .physics
  -- regulation
  | .rul1 | .rul2 | .rul3 => .regulation
  -- modeling
  | .mod1 | .mod2 | .mod3 | .mod4 => .modeling
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 => .hypothesis

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

end Scenario255

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **standard** (ord=3): 食品安全基準・規格の絶対制約 [C1, C2]
- **sensor** (ord=2): センサー・測定系の外部依存 [H1, H2]
- **evaluation** (ord=1): 評価アルゴリズム・判定基準 [C3, H3, H4]
- **hypothesis** (ord=0): 未検証の仮説 [H5]
-/

namespace FoodTextureEvaluation

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | std1
  | std2
  | sns1
  | sns2
  | sns3
  | evl1
  | evl2
  | evl3
  | hyp1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .std1 => []
  | .std2 => []
  | .sns1 => []
  | .sns2 => [.sns1]
  | .sns3 => [.std1]
  | .evl1 => [.std1, .sns1]
  | .evl2 => [.std2, .sns2]
  | .evl3 => [.sns3]
  | .hyp1 => [.evl1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品安全基準・規格の絶対制約 (ord=3) -/
  | standard
  /-- センサー・測定系の外部依存 (ord=2) -/
  | sensor
  /-- 評価アルゴリズム・判定基準 (ord=1) -/
  | evaluation
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .standard => 3
  | .sensor => 2
  | .evaluation => 1
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
  nontrivial := ⟨.standard, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- standard
  | .std1 | .std2 => .standard
  -- sensor
  | .sns1 | .sns2 | .sns3 => .sensor
  -- evaluation
  | .evl1 | .evl2 | .evl3 => .evaluation
  -- hypothesis
  | .hyp1 => .hypothesis

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

end FoodTextureEvaluation

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **medical_safety** (ord=4): 医学的安全・禁忌事項の絶対条件 [C1, C2]
- **physiology** (ord=3): 運動生理学の外部知識・前提 [H1, H2]
- **user_goal** (ord=2): ユーザが設定する目標・制約 [C3, C4]
- **program** (ord=1): AIが生成するトレーニングプログラム [H3, H4]
-/

namespace TestCoverage.S19

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | ms1
  | ms2
  | phy1
  | phy2
  | ug1
  | ug2
  | ug3
  | prg1
  | prg2
  | prg3
  | prg4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .ms1 => []
  | .ms2 => []
  | .phy1 => []
  | .phy2 => [.ms1]
  | .ug1 => [.ms1, .phy1]
  | .ug2 => [.ms2]
  | .ug3 => [.phy2]
  | .prg1 => [.ug1, .phy1]
  | .prg2 => [.ug2]
  | .prg3 => [.ug3, .phy2]
  | .prg4 => [.prg1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医学的安全・禁忌事項の絶対条件 (ord=4) -/
  | medical_safety
  /-- 運動生理学の外部知識・前提 (ord=3) -/
  | physiology
  /-- ユーザが設定する目標・制約 (ord=2) -/
  | user_goal
  /-- AIが生成するトレーニングプログラム (ord=1) -/
  | program
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .medical_safety => 4
  | .physiology => 3
  | .user_goal => 2
  | .program => 1

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
  bottom := .program
  nontrivial := ⟨.medical_safety, .program, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- medical_safety
  | .ms1 | .ms2 => .medical_safety
  -- physiology
  | .phy1 | .phy2 => .physiology
  -- user_goal
  | .ug1 | .ug2 | .ug3 => .user_goal
  -- program
  | .prg1 | .prg2 | .prg3 | .prg4 => .program

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

end TestCoverage.S19

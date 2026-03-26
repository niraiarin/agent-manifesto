/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **medical** (ord=3): 医療倫理と患者安全に関する不可侵の原則。 [C1, C2, C4]
- **clinical** (ord=2): 臨床評価基準と計測プロトコル。専門家の合意で設定。 [C3, C5]
- **algorithm** (ord=1): AI評価アルゴリズムの設計判断。データで改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。臨床データで検証が必要。 [H1, H3]
-/

namespace Scenario284

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | med1
  | med2
  | med3
  | cln1
  | cln2
  | cln3
  | alg1
  | alg2
  | alg3
  | alg4
  | alg5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .med1 => []
  | .med2 => []
  | .med3 => []
  | .cln1 => [.med1]
  | .cln2 => [.med2]
  | .cln3 => [.med1, .med2]
  | .alg1 => [.cln1, .cln3]
  | .alg2 => [.cln2, .cln3]
  | .alg3 => [.med1, .cln1]
  | .alg4 => [.alg1, .alg2]
  | .alg5 => [.cln2, .alg3]
  | .hyp1 => [.alg1, .alg4]
  | .hyp2 => [.alg3, .alg5]
  | .hyp3 => [.hyp1, .hyp2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医療倫理と患者安全に関する不可侵の原則。 (ord=3) -/
  | medical
  /-- 臨床評価基準と計測プロトコル。専門家の合意で設定。 (ord=2) -/
  | clinical
  /-- AI評価アルゴリズムの設計判断。データで改善可能。 (ord=1) -/
  | algorithm
  /-- 未検証の仮説。臨床データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .medical => 3
  | .clinical => 2
  | .algorithm => 1
  | .hyp => 0

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
  bottom := .hyp
  nontrivial := ⟨.medical, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- medical
  | .med1 | .med2 | .med3 => .medical
  -- clinical
  | .cln1 | .cln2 | .cln3 => .clinical
  -- algorithm
  | .alg1 | .alg2 | .alg3 | .alg4 | .alg5 => .algorithm
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 => .hyp

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

end Scenario284

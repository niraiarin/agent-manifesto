/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulation** (ord=3): 医療機器規制・放射線防護に関する不変条件。法規制で強制。 [C1, C4]
- **clinical** (ord=2): 臨床的な診断品質基準。エビデンスに基づく。 [C2, C3]
- **detection** (ord=1): AI検出アルゴリズムの設計方針。モデル改良で変更可能。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。臨床データで検証が必要。 [H3]
-/

namespace Scenario211

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | reg1
  | reg2
  | reg3
  | clin1
  | clin2
  | clin3
  | clin4
  | det1
  | det2
  | det3
  | det4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .reg1 => []
  | .reg2 => []
  | .reg3 => []
  | .clin1 => [.reg1]
  | .clin2 => [.reg1]
  | .clin3 => [.reg2]
  | .clin4 => [.reg1, .reg3]
  | .det1 => [.reg1, .clin1]
  | .det2 => [.clin1, .clin3]
  | .det3 => [.clin2, .clin4]
  | .det4 => [.clin2]
  | .hyp1 => [.det3]
  | .hyp2 => [.det1, .det4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医療機器規制・放射線防護に関する不変条件。法規制で強制。 (ord=3) -/
  | regulation
  /-- 臨床的な診断品質基準。エビデンスに基づく。 (ord=2) -/
  | clinical
  /-- AI検出アルゴリズムの設計方針。モデル改良で変更可能。 (ord=1) -/
  | detection
  /-- 未検証の仮説。臨床データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulation => 3
  | .clinical => 2
  | .detection => 1
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
  nontrivial := ⟨.regulation, .hyp, by simp [ConcreteLayer.ord]⟩
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
  -- clinical
  | .clin1 | .clin2 | .clin3 | .clin4 => .clinical
  -- detection
  | .det1 | .det2 | .det3 | .det4 => .detection
  -- hyp
  | .hyp1 | .hyp2 => .hyp

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

end Scenario211

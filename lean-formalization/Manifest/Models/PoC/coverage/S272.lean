/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **standard** (ord=3): 茶業界の確立された分類体系と鑑定権限。不変。 [C1, C3]
- **regulation** (ord=2): 組合が年度ごとに改定する等級基準。変更は人間主導。 [C2, C4]
- **method** (ord=1): AIの判定手法。技術進歩に応じて改善可能。 [H1, H2]
- **hyp** (ord=0): 未検証の仮説。運用データで確認が必要。 [H3]
-/

namespace Scenario272

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | std1
  | std2
  | std3
  | reg1
  | reg2
  | reg3
  | met1
  | met2
  | met3
  | met4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .std1 => []
  | .std2 => []
  | .std3 => []
  | .reg1 => [.std1]
  | .reg2 => [.std1, .std2]
  | .reg3 => [.reg1, .reg2]
  | .met1 => [.std2, .reg1]
  | .met2 => [.reg2]
  | .met3 => [.met1, .met2]
  | .met4 => [.std3, .reg3]
  | .hyp1 => [.reg1, .met1]
  | .hyp2 => [.met3, .met4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 茶業界の確立された分類体系と鑑定権限。不変。 (ord=3) -/
  | standard
  /-- 組合が年度ごとに改定する等級基準。変更は人間主導。 (ord=2) -/
  | regulation
  /-- AIの判定手法。技術進歩に応じて改善可能。 (ord=1) -/
  | method
  /-- 未検証の仮説。運用データで確認が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .standard => 3
  | .regulation => 2
  | .method => 1
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
  nontrivial := ⟨.standard, .hyp, by simp [ConcreteLayer.ord]⟩
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
  | .std1 | .std2 | .std3 => .standard
  -- regulation
  | .reg1 | .reg2 | .reg3 => .regulation
  -- method
  | .met1 | .met2 | .met3 | .met4 => .method
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

end Scenario272

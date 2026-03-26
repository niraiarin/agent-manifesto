/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physics** (ord=4): 海洋物理と気象の自然法則。変更不可。 [C3]
- **regulation** (ord=3): IMO Polar Codeと環境規制。国際合意に基づく。 [C1, C4]
- **operational** (ord=2): 船長と運航会社の運用判断。航海ごとに設定。 [C2, C5, C6]
- **prediction** (ord=1): AIの予測・最適化手法。改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 検証待ちの仮説。航海データで確認。 [H3]
-/

namespace Scenario275

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | phy1
  | phy2
  | reg1
  | reg2
  | reg3
  | opr1
  | opr2
  | opr3
  | opr4
  | prd1
  | prd2
  | prd3
  | prd4
  | prd5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .phy1 => []
  | .phy2 => []
  | .reg1 => []
  | .reg2 => []
  | .reg3 => [.reg1, .reg2]
  | .opr1 => [.reg1]
  | .opr2 => [.phy1]
  | .opr3 => [.reg3]
  | .opr4 => [.opr1, .opr3]
  | .prd1 => [.phy1, .phy2, .reg1]
  | .prd2 => [.phy2, .opr2]
  | .prd3 => [.reg2, .opr4]
  | .prd4 => [.prd1, .prd2]
  | .prd5 => [.prd2, .prd3]
  | .hyp1 => [.prd3]
  | .hyp2 => [.prd4, .prd5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋物理と気象の自然法則。変更不可。 (ord=4) -/
  | physics
  /-- IMO Polar Codeと環境規制。国際合意に基づく。 (ord=3) -/
  | regulation
  /-- 船長と運航会社の運用判断。航海ごとに設定。 (ord=2) -/
  | operational
  /-- AIの予測・最適化手法。改善可能。 (ord=1) -/
  | prediction
  /-- 検証待ちの仮説。航海データで確認。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physics => 4
  | .regulation => 3
  | .operational => 2
  | .prediction => 1
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
  nontrivial := ⟨.physics, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physics
  | .phy1 | .phy2 => .physics
  -- regulation
  | .reg1 | .reg2 | .reg3 => .regulation
  -- operational
  | .opr1 | .opr2 | .opr3 | .opr4 => .operational
  -- prediction
  | .prd1 | .prd2 | .prd3 | .prd4 | .prd5 => .prediction
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

end Scenario275

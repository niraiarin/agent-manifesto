/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_constraint** (ord=4): 人体安全・環境汚染防止の不変制約 [C1, C2]
- **recognition_postulate** (ord=3): 画像認識・素材判定の前提となる仮定 [C3, H1]
- **sorting_principle** (ord=2): 分別ルールの原則（自治体基準・汚染度判定） [C4, C5, H2]
- **operation_design** (ord=1): ロボット動作・ライン制御の設計判断 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_864d79
  | prop_8102a4
  | prop_06e30c
  | prop_dc9d15
  | prop_4fedcf
  | prop_aa746c
  | prop_2cd30c
  | prop_dcfbc9
  | prop_b64e6a
  | prop_991650
  | prop_0ca9a0
  | prop_c30e66
  | prop_ecaf66
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_864d79 => []
  | .prop_8102a4 => []
  | .prop_06e30c => []
  | .prop_dc9d15 => []
  | .prop_4fedcf => []
  | .prop_aa746c => []
  | .prop_2cd30c => []
  | .prop_dcfbc9 => []
  | .prop_b64e6a => []
  | .prop_991650 => []
  | .prop_0ca9a0 => []
  | .prop_c30e66 => []
  | .prop_ecaf66 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人体安全・環境汚染防止の不変制約 (ord=4) -/
  | safety_constraint
  /-- 画像認識・素材判定の前提となる仮定 (ord=3) -/
  | recognition_postulate
  /-- 分別ルールの原則（自治体基準・汚染度判定） (ord=2) -/
  | sorting_principle
  /-- ロボット動作・ライン制御の設計判断 (ord=1) -/
  | operation_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_constraint => 4
  | .recognition_postulate => 3
  | .sorting_principle => 2
  | .operation_design => 1

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
  bottom := .operation_design
  nontrivial := ⟨.safety_constraint, .operation_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_constraint
  | .prop_864d79 | .prop_8102a4 | .prop_06e30c => .safety_constraint
  -- recognition_postulate
  | .prop_dc9d15 | .prop_4fedcf | .prop_aa746c => .recognition_postulate
  -- sorting_principle
  | .prop_2cd30c | .prop_dcfbc9 | .prop_b64e6a => .sorting_principle
  -- operation_design
  | .prop_991650 | .prop_0ca9a0 | .prop_c30e66 | .prop_ecaf66 => .operation_design

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

end Manifest.Models

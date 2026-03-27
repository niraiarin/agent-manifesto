/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulatory_constraint** (ord=4): 車両安全基準・環境規制の不変制約 [C1, C2]
- **engineering_postulate** (ord=3): 空力・構造・製造性の工学的前提 [C3, H1]
- **design_principle** (ord=2): デザインの原則（ブランドアイデンティティ・人間工学・美的調和） [C4, C5, H2]
- **rendering_design** (ord=1): レンダリング・プレゼンテーションの設計判断 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | NCAP_2a730d
  | prop_945e4d
  | prop_ce7271
  | Cd_8f86a1
  | prop_415844
  | prop_52d4f6
  | DNA_e9d32e
  | prop_16d4d0
  | prop_38a9fe
  | K_68d54e
  | prop_1f369c
  | CFD_f6ddd6
  | VR_361d9e
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .NCAP_2a730d => []
  | .prop_945e4d => []
  | .prop_ce7271 => []
  | .Cd_8f86a1 => []
  | .prop_415844 => []
  | .prop_52d4f6 => []
  | .DNA_e9d32e => []
  | .prop_16d4d0 => []
  | .prop_38a9fe => []
  | .K_68d54e => []
  | .prop_1f369c => []
  | .CFD_f6ddd6 => []
  | .VR_361d9e => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 車両安全基準・環境規制の不変制約 (ord=4) -/
  | regulatory_constraint
  /-- 空力・構造・製造性の工学的前提 (ord=3) -/
  | engineering_postulate
  /-- デザインの原則（ブランドアイデンティティ・人間工学・美的調和） (ord=2) -/
  | design_principle
  /-- レンダリング・プレゼンテーションの設計判断 (ord=1) -/
  | rendering_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulatory_constraint => 4
  | .engineering_postulate => 3
  | .design_principle => 2
  | .rendering_design => 1

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
  bottom := .rendering_design
  nontrivial := ⟨.regulatory_constraint, .rendering_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- regulatory_constraint
  | .NCAP_2a730d | .prop_945e4d | .prop_ce7271 => .regulatory_constraint
  -- engineering_postulate
  | .Cd_8f86a1 | .prop_415844 | .prop_52d4f6 => .engineering_postulate
  -- design_principle
  | .DNA_e9d32e | .prop_16d4d0 | .prop_38a9fe => .design_principle
  -- rendering_design
  | .K_68d54e | .prop_1f369c | .CFD_f6ddd6 | .VR_361d9e => .rendering_design

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

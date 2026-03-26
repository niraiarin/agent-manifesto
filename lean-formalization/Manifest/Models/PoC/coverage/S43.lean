/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **grading_standard** (ord=4): JAS規格・等級基準など公的に定められた判定基準 [C1, C2]
- **visual_model** (ord=3): 画像認識モデルの精度仮定・学習データの品質前提 [C3, H1]
- **sorting_policy** (ord=2): 判定フロー・人間レビュー基準・ライン制御方針 [C4, H2, H3]
- **line_parameter** (ord=1): ベルトコンベア速度・カメラ位置・照明条件などの現場パラメータ [C5, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | t1
  | t4
  | t6
  | e1
  | e2
  | p1
  | p2
  | l1
  | l2
  | d1
  | d8
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .t1 => []
  | .t4 => []
  | .t6 => []
  | .e1 => []
  | .e2 => []
  | .p1 => []
  | .p2 => []
  | .l1 => []
  | .l2 => []
  | .d1 => []
  | .d8 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- JAS規格・等級基準など公的に定められた判定基準 (ord=4) -/
  | grading_standard
  /-- 画像認識モデルの精度仮定・学習データの品質前提 (ord=3) -/
  | visual_model
  /-- 判定フロー・人間レビュー基準・ライン制御方針 (ord=2) -/
  | sorting_policy
  /-- ベルトコンベア速度・カメラ位置・照明条件などの現場パラメータ (ord=1) -/
  | line_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .grading_standard => 4
  | .visual_model => 3
  | .sorting_policy => 2
  | .line_parameter => 1

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
  bottom := .line_parameter
  nontrivial := ⟨.grading_standard, .line_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- grading_standard
  | .t1 | .t4 | .t6 => .grading_standard
  -- visual_model
  | .e1 | .e2 | .p1 => .visual_model
  -- sorting_policy
  | .p2 | .l1 | .l2 => .sorting_policy
  -- line_parameter
  | .d1 | .d8 => .line_parameter

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

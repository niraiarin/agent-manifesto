/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **biological_constraint** (ord=4): 植物の生理学的限界・安全基準・食品衛生法の制約 [C1, C2]
- **growth_model** (ord=3): 光合成効率・成長曲線・環境応答に関する経験的モデル [C3, H1, H2]
- **control_policy** (ord=2): 環境制御アルゴリズム・収穫タイミング・異常時対応方針 [C4, H3, H4]
- **actuator_parameter** (ord=1): LED照度・温湿度設定値・養液濃度など直接制御パラメータ [C5, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | t1
  | t6
  | t7
  | e1
  | e2
  | p1
  | p4
  | p5
  | l1
  | l3
  | d1
  | d3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .t1 => []
  | .t6 => []
  | .t7 => []
  | .e1 => []
  | .e2 => []
  | .p1 => []
  | .p4 => []
  | .p5 => []
  | .l1 => []
  | .l3 => []
  | .d1 => []
  | .d3 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 植物の生理学的限界・安全基準・食品衛生法の制約 (ord=4) -/
  | biological_constraint
  /-- 光合成効率・成長曲線・環境応答に関する経験的モデル (ord=3) -/
  | growth_model
  /-- 環境制御アルゴリズム・収穫タイミング・異常時対応方針 (ord=2) -/
  | control_policy
  /-- LED照度・温湿度設定値・養液濃度など直接制御パラメータ (ord=1) -/
  | actuator_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .biological_constraint => 4
  | .growth_model => 3
  | .control_policy => 2
  | .actuator_parameter => 1

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
  bottom := .actuator_parameter
  nontrivial := ⟨.biological_constraint, .actuator_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- biological_constraint
  | .t1 | .t6 | .t7 => .biological_constraint
  -- growth_model
  | .e1 | .e2 | .p1 => .growth_model
  -- control_policy
  | .p4 | .p5 | .l1 | .l3 => .control_policy
  -- actuator_parameter
  | .d1 | .d3 => .actuator_parameter

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

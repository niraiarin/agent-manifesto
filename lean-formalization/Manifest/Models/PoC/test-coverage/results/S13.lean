/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physical_safety** (ord=5): 人身安全・衝突回避の絶対条件 [C1, C2]
- **hardware** (ord=4): ロボットハードウェアの物理制約 [H1, H2]
- **warehouse_layout** (ord=3): 倉庫レイアウト・棚配置への依存 [H3, C3]
- **dispatch_policy** (ord=2): 管理者が設定するタスク割当方針 [C4, C5]
- **path_optimization** (ord=1): AIが最適化する経路・動作計画 [H4, H5]
-/

namespace TestCoverage.S13

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | ps1
  | ps2
  | hw1
  | hw2
  | wl1
  | wl2
  | dp1
  | dp2
  | dp3
  | po1
  | po2
  | po3
  | po4
  | po5
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .ps1 => []
  | .ps2 => []
  | .hw1 => []
  | .hw2 => [.ps1]
  | .wl1 => []
  | .wl2 => [.hw1]
  | .dp1 => [.ps1, .wl1]
  | .dp2 => [.ps2, .hw2]
  | .dp3 => [.wl2]
  | .po1 => [.dp1, .hw1]
  | .po2 => [.dp2, .wl1]
  | .po3 => [.dp3]
  | .po4 => [.po1, .po2]
  | .po5 => [.dp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人身安全・衝突回避の絶対条件 (ord=5) -/
  | physical_safety
  /-- ロボットハードウェアの物理制約 (ord=4) -/
  | hardware
  /-- 倉庫レイアウト・棚配置への依存 (ord=3) -/
  | warehouse_layout
  /-- 管理者が設定するタスク割当方針 (ord=2) -/
  | dispatch_policy
  /-- AIが最適化する経路・動作計画 (ord=1) -/
  | path_optimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physical_safety => 5
  | .hardware => 4
  | .warehouse_layout => 3
  | .dispatch_policy => 2
  | .path_optimization => 1

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
  bottom := .path_optimization
  nontrivial := ⟨.physical_safety, .path_optimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physical_safety
  | .ps1 | .ps2 => .physical_safety
  -- hardware
  | .hw1 | .hw2 => .hardware
  -- warehouse_layout
  | .wl1 | .wl2 => .warehouse_layout
  -- dispatch_policy
  | .dp1 | .dp2 | .dp3 => .dispatch_policy
  -- path_optimization
  | .po1 | .po2 | .po3 | .po4 | .po5 => .path_optimization

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

end TestCoverage.S13

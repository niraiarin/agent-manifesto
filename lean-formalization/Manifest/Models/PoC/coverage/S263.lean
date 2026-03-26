/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **hydraulic_law** (ord=4): 水理学・土砂水理の基本法則。連続方程式・運動方程式 [C1]
- **dam_constraint** (ord=3): ダム構造・運用の物理的制約。堆砂容量・排砂設備仕様 [C2, C3]
- **sediment_model** (ord=2): 堆砂予測モデル。流出土砂量推定・堆積分布計算 [H1, H2]
- **operational** (ord=1): 排砂運用最適化。フラッシング・浚渫計画 [H3, C4]
- **forecast** (ord=0): 将来予測・気候変動影響の仮説 [H4]
-/

namespace TestScenario.S263

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | hl1
  | hl2
  | dc1
  | dc2
  | dc3
  | sm1
  | sm2
  | sm3
  | op1
  | op2
  | fc1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .hl1 => []
  | .hl2 => []
  | .dc1 => [.hl1]
  | .dc2 => []
  | .dc3 => [.hl2]
  | .sm1 => [.hl1, .dc1]
  | .sm2 => [.dc2, .dc3]
  | .sm3 => [.sm1]
  | .op1 => [.sm1, .dc1]
  | .op2 => [.sm2]
  | .fc1 => [.sm3, .op1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 水理学・土砂水理の基本法則。連続方程式・運動方程式 (ord=4) -/
  | hydraulic_law
  /-- ダム構造・運用の物理的制約。堆砂容量・排砂設備仕様 (ord=3) -/
  | dam_constraint
  /-- 堆砂予測モデル。流出土砂量推定・堆積分布計算 (ord=2) -/
  | sediment_model
  /-- 排砂運用最適化。フラッシング・浚渫計画 (ord=1) -/
  | operational
  /-- 将来予測・気候変動影響の仮説 (ord=0) -/
  | forecast
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .hydraulic_law => 4
  | .dam_constraint => 3
  | .sediment_model => 2
  | .operational => 1
  | .forecast => 0

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
  bottom := .forecast
  nontrivial := ⟨.hydraulic_law, .forecast, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- hydraulic_law
  | .hl1 | .hl2 => .hydraulic_law
  -- dam_constraint
  | .dc1 | .dc2 | .dc3 => .dam_constraint
  -- sediment_model
  | .sm1 | .sm2 | .sm3 => .sediment_model
  -- operational
  | .op1 | .op2 => .operational
  -- forecast
  | .fc1 => .forecast

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

end TestScenario.S263

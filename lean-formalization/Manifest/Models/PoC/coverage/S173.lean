/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicalSafety** (ord=5): 人身事故防止に関わる安全制約。道路交通法に準拠 [C1, C2]
- **VehicleRegulation** (ord=4): 車両基準・型式認証に関わる法規制 [C3, H1]
- **ParkingPolicy** (ord=3): 駐車場運用のルール。施設管理者の方針 [C4, H2]
- **ControlAlgorithm** (ord=2): 経路計画・制御アルゴリズムの設計選択 [C5, H3, H4]
- **SensorHypothesis** (ord=1): センサー性能に関する未検証の仮説 [C6, H5, H6]
-/

namespace TestCoverage.S173

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s173_p01
  | s173_p02
  | s173_p03
  | s173_p04
  | s173_p05
  | s173_p06
  | s173_p07
  | s173_p08
  | s173_p09
  | s173_p10
  | s173_p11
  | s173_p12
  | s173_p13
  | s173_p14
  | s173_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s173_p01 => []
  | .s173_p02 => []
  | .s173_p03 => []
  | .s173_p04 => [.s173_p01]
  | .s173_p05 => [.s173_p02]
  | .s173_p06 => [.s173_p04]
  | .s173_p07 => [.s173_p04, .s173_p05]
  | .s173_p08 => [.s173_p03]
  | .s173_p09 => [.s173_p06]
  | .s173_p10 => [.s173_p07]
  | .s173_p11 => [.s173_p06, .s173_p08]
  | .s173_p12 => [.s173_p09]
  | .s173_p13 => [.s173_p10]
  | .s173_p14 => [.s173_p11]
  | .s173_p15 => [.s173_p09, .s173_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人身事故防止に関わる安全制約。道路交通法に準拠 (ord=5) -/
  | PhysicalSafety
  /-- 車両基準・型式認証に関わる法規制 (ord=4) -/
  | VehicleRegulation
  /-- 駐車場運用のルール。施設管理者の方針 (ord=3) -/
  | ParkingPolicy
  /-- 経路計画・制御アルゴリズムの設計選択 (ord=2) -/
  | ControlAlgorithm
  /-- センサー性能に関する未検証の仮説 (ord=1) -/
  | SensorHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicalSafety => 5
  | .VehicleRegulation => 4
  | .ParkingPolicy => 3
  | .ControlAlgorithm => 2
  | .SensorHypothesis => 1

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
  bottom := .SensorHypothesis
  nontrivial := ⟨.PhysicalSafety, .SensorHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicalSafety
  | .s173_p01 | .s173_p02 | .s173_p03 => .PhysicalSafety
  -- VehicleRegulation
  | .s173_p04 | .s173_p05 => .VehicleRegulation
  -- ParkingPolicy
  | .s173_p06 | .s173_p07 | .s173_p08 => .ParkingPolicy
  -- ControlAlgorithm
  | .s173_p09 | .s173_p10 | .s173_p11 => .ControlAlgorithm
  -- SensorHypothesis
  | .s173_p12 | .s173_p13 | .s173_p14 | .s173_p15 => .SensorHypothesis

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

end TestCoverage.S173

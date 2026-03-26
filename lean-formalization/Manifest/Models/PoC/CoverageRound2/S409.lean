/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **StructuralSafetyInvariant** (ord=4): 橋梁・建物の崩壊リスク閾値超過時の即時警告・避難指示の不変制約 [C1, C2]
- **EngineeringStandardsCompliance** (ord=3): 建築基準法・ASCE規格・耐震基準への準拠。工学的安全基準 [C3, H1]
- **MaintenancePolicy** (ord=2): 点検スケジュール・補修優先度・予算配分ポリシー。インフラ管理規則 [C4, H2, H3]
- **SensorFusionHypothesis** (ord=1): 多種センサーデータ融合・劣化モデル予測の仮説。機械学習で精度改善中 [H4, H5]
-/

namespace TestCoverage.S409

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s409_p01
  | s409_p02
  | s409_p03
  | s409_p04
  | s409_p05
  | s409_p06
  | s409_p07
  | s409_p08
  | s409_p09
  | s409_p10
  | s409_p11
  | s409_p12
  | s409_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s409_p01 => []
  | .s409_p02 => []
  | .s409_p03 => [.s409_p01, .s409_p02]
  | .s409_p04 => [.s409_p01]
  | .s409_p05 => [.s409_p02]
  | .s409_p06 => [.s409_p03]
  | .s409_p07 => [.s409_p04]
  | .s409_p08 => [.s409_p05]
  | .s409_p09 => [.s409_p06]
  | .s409_p10 => [.s409_p07, .s409_p08]
  | .s409_p11 => [.s409_p07]
  | .s409_p12 => [.s409_p08]
  | .s409_p13 => [.s409_p09, .s409_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 橋梁・建物の崩壊リスク閾値超過時の即時警告・避難指示の不変制約 (ord=4) -/
  | StructuralSafetyInvariant
  /-- 建築基準法・ASCE規格・耐震基準への準拠。工学的安全基準 (ord=3) -/
  | EngineeringStandardsCompliance
  /-- 点検スケジュール・補修優先度・予算配分ポリシー。インフラ管理規則 (ord=2) -/
  | MaintenancePolicy
  /-- 多種センサーデータ融合・劣化モデル予測の仮説。機械学習で精度改善中 (ord=1) -/
  | SensorFusionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .StructuralSafetyInvariant => 4
  | .EngineeringStandardsCompliance => 3
  | .MaintenancePolicy => 2
  | .SensorFusionHypothesis => 1

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
  bottom := .SensorFusionHypothesis
  nontrivial := ⟨.StructuralSafetyInvariant, .SensorFusionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- StructuralSafetyInvariant
  | .s409_p01 | .s409_p02 | .s409_p03 => .StructuralSafetyInvariant
  -- EngineeringStandardsCompliance
  | .s409_p04 | .s409_p05 | .s409_p06 => .EngineeringStandardsCompliance
  -- MaintenancePolicy
  | .s409_p07 | .s409_p08 | .s409_p09 | .s409_p10 => .MaintenancePolicy
  -- SensorFusionHypothesis
  | .s409_p11 | .s409_p12 | .s409_p13 => .SensorFusionHypothesis

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

end TestCoverage.S409

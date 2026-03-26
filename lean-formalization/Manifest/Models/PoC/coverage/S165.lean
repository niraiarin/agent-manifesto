/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **buildingCode** (ord=3): 建築基準法・労働安全衛生法の最低照度要件 [C1]
- **occupantWellbeing** (ord=2): 在室者の健康・快適性に関する照明要件 [C2, H1]
- **energyOptimization** (ord=1): 電力消費最小化のための制御戦略 [H2, H3]
- **ambientAdaptation** (ord=0): 外光・天候に応じた動的調光 [H4]
-/

namespace TestScenario.S165

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | minLuxStandard
  | emergencyLighting
  | exitSignVisibility
  | circadianRhythm
  | glarePrevention
  | colorTempRange
  | occupancySensing
  | zoneDimming
  | peakShaving
  | daylightHarvest
  | cloudTransientSmooth
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .minLuxStandard => []
  | .emergencyLighting => []
  | .exitSignVisibility => []
  | .circadianRhythm => [.minLuxStandard]
  | .glarePrevention => [.minLuxStandard]
  | .colorTempRange => [.circadianRhythm]
  | .occupancySensing => [.minLuxStandard, .circadianRhythm]
  | .zoneDimming => [.occupancySensing, .glarePrevention]
  | .peakShaving => [.zoneDimming]
  | .daylightHarvest => [.occupancySensing, .zoneDimming]
  | .cloudTransientSmooth => [.daylightHarvest, .glarePrevention]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 建築基準法・労働安全衛生法の最低照度要件 (ord=3) -/
  | buildingCode
  /-- 在室者の健康・快適性に関する照明要件 (ord=2) -/
  | occupantWellbeing
  /-- 電力消費最小化のための制御戦略 (ord=1) -/
  | energyOptimization
  /-- 外光・天候に応じた動的調光 (ord=0) -/
  | ambientAdaptation
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .buildingCode => 3
  | .occupantWellbeing => 2
  | .energyOptimization => 1
  | .ambientAdaptation => 0

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
  bottom := .ambientAdaptation
  nontrivial := ⟨.buildingCode, .ambientAdaptation, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- buildingCode
  | .minLuxStandard | .emergencyLighting | .exitSignVisibility => .buildingCode
  -- occupantWellbeing
  | .circadianRhythm | .glarePrevention | .colorTempRange => .occupantWellbeing
  -- energyOptimization
  | .occupancySensing | .zoneDimming | .peakShaving => .energyOptimization
  -- ambientAdaptation
  | .daylightHarvest | .cloudTransientSmooth => .ambientAdaptation

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

end TestScenario.S165

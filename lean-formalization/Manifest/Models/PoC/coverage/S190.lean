/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyRegulation** (ord=6): 鉄道営業法・車両検査規程に基づく安全義務。変更不可 [C1]
- **InspectionStandard** (ord=5): 国交省通達・JIS規格に基づく検査基準 [C2, H1]
- **MaintenancePolicy** (ord=4): 鉄道事業者の保全方針。経営判断で調整可能 [C3, H2]
- **DiagnosticDesign** (ord=3): 診断システムの設計選択。技術進歩で更新 [C4, C5, H3]
- **SensorIntegration** (ord=2): センサーデータ統合の設計 [C6, H4]
- **AlgorithmChoice** (ord=1): 異常検知アルゴリズムの選択。比較評価で更新 [H5, H6]
- **EfficiencyHypothesis** (ord=0): 効率改善に関する未検証仮説 [H7]
-/

namespace TestCoverage.S190

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s190_p01
  | s190_p02
  | s190_p03
  | s190_p04
  | s190_p05
  | s190_p06
  | s190_p07
  | s190_p08
  | s190_p09
  | s190_p10
  | s190_p11
  | s190_p12
  | s190_p13
  | s190_p14
  | s190_p15
  | s190_p16
  | s190_p17
  | s190_p18
  | s190_p19
  | s190_p20
  | s190_p21
  | s190_p22
  | s190_p23
  | s190_p24
  | s190_p25
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s190_p01 => []
  | .s190_p02 => []
  | .s190_p03 => [.s190_p01]
  | .s190_p04 => [.s190_p01, .s190_p02]
  | .s190_p05 => [.s190_p02]
  | .s190_p06 => [.s190_p03]
  | .s190_p07 => [.s190_p03, .s190_p04]
  | .s190_p08 => [.s190_p04, .s190_p05]
  | .s190_p09 => [.s190_p06]
  | .s190_p10 => [.s190_p06, .s190_p07]
  | .s190_p11 => [.s190_p07]
  | .s190_p12 => [.s190_p08]
  | .s190_p13 => [.s190_p09]
  | .s190_p14 => [.s190_p09, .s190_p10]
  | .s190_p15 => [.s190_p11]
  | .s190_p16 => [.s190_p12]
  | .s190_p17 => [.s190_p13]
  | .s190_p18 => [.s190_p14]
  | .s190_p19 => [.s190_p13, .s190_p15]
  | .s190_p20 => [.s190_p15, .s190_p16]
  | .s190_p21 => [.s190_p17]
  | .s190_p22 => [.s190_p18]
  | .s190_p23 => [.s190_p19, .s190_p20]
  | .s190_p24 => [.s190_p17, .s190_p20]
  | .s190_p25 => [.s190_p18, .s190_p19]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 鉄道営業法・車両検査規程に基づく安全義務。変更不可 (ord=6) -/
  | SafetyRegulation
  /-- 国交省通達・JIS規格に基づく検査基準 (ord=5) -/
  | InspectionStandard
  /-- 鉄道事業者の保全方針。経営判断で調整可能 (ord=4) -/
  | MaintenancePolicy
  /-- 診断システムの設計選択。技術進歩で更新 (ord=3) -/
  | DiagnosticDesign
  /-- センサーデータ統合の設計 (ord=2) -/
  | SensorIntegration
  /-- 異常検知アルゴリズムの選択。比較評価で更新 (ord=1) -/
  | AlgorithmChoice
  /-- 効率改善に関する未検証仮説 (ord=0) -/
  | EfficiencyHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyRegulation => 6
  | .InspectionStandard => 5
  | .MaintenancePolicy => 4
  | .DiagnosticDesign => 3
  | .SensorIntegration => 2
  | .AlgorithmChoice => 1
  | .EfficiencyHypothesis => 0

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
  bottom := .EfficiencyHypothesis
  nontrivial := ⟨.SafetyRegulation, .EfficiencyHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyRegulation
  | .s190_p01 | .s190_p02 => .SafetyRegulation
  -- InspectionStandard
  | .s190_p03 | .s190_p04 | .s190_p05 => .InspectionStandard
  -- MaintenancePolicy
  | .s190_p06 | .s190_p07 | .s190_p08 => .MaintenancePolicy
  -- DiagnosticDesign
  | .s190_p09 | .s190_p10 | .s190_p11 | .s190_p12 => .DiagnosticDesign
  -- SensorIntegration
  | .s190_p13 | .s190_p14 | .s190_p15 | .s190_p16 => .SensorIntegration
  -- AlgorithmChoice
  | .s190_p17 | .s190_p18 | .s190_p19 | .s190_p20 => .AlgorithmChoice
  -- EfficiencyHypothesis
  | .s190_p21 | .s190_p22 | .s190_p23 | .s190_p24 | .s190_p25 => .EfficiencyHypothesis

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

end TestCoverage.S190

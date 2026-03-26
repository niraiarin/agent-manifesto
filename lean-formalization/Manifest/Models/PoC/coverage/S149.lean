/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ScientificPrinciple** (ord=6): 海洋化学の基本原理。CO2溶解平衡・pH測定の物理化学的基礎 [C1]
- **MeasurementStandard** (ord=5): 国際的な海洋観測の計測標準。GOOS/IOC準拠 [C2, C3]
- **DataQuality** (ord=4): データ品質管理の基準。較正・バリデーション手順 [C4, H1]
- **MonitoringProtocol** (ord=3): 監視運用の手順。観測頻度・地点配置 [C5, H2]
- **AnalysisPipeline** (ord=2): データ解析パイプラインの設計。前処理・統合方法 [C6, H3]
- **PredictionModel** (ord=1): 酸性化予測モデルの手法選択。シナリオに応じて変更可能 [H4]
- **EcologicalImpact** (ord=0): 生態系影響に関する仮説。長期観測で検証が必要 [H5]
-/

namespace TestCoverage.S149

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s149_p01
  | s149_p02
  | s149_p03
  | s149_p04
  | s149_p05
  | s149_p06
  | s149_p07
  | s149_p08
  | s149_p09
  | s149_p10
  | s149_p11
  | s149_p12
  | s149_p13
  | s149_p14
  | s149_p15
  | s149_p16
  | s149_p17
  | s149_p18
  | s149_p19
  | s149_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s149_p01 => []
  | .s149_p02 => [.s149_p01]
  | .s149_p03 => [.s149_p01]
  | .s149_p04 => [.s149_p01]
  | .s149_p05 => [.s149_p02]
  | .s149_p06 => [.s149_p03]
  | .s149_p07 => [.s149_p02, .s149_p04]
  | .s149_p08 => [.s149_p05]
  | .s149_p09 => [.s149_p06]
  | .s149_p10 => [.s149_p05, .s149_p07]
  | .s149_p11 => [.s149_p08]
  | .s149_p12 => [.s149_p09]
  | .s149_p13 => [.s149_p08, .s149_p10]
  | .s149_p14 => [.s149_p11]
  | .s149_p15 => [.s149_p12]
  | .s149_p16 => [.s149_p11, .s149_p13]
  | .s149_p17 => [.s149_p14]
  | .s149_p18 => [.s149_p15]
  | .s149_p19 => [.s149_p14, .s149_p16]
  | .s149_p20 => [.s149_p17, .s149_p18]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋化学の基本原理。CO2溶解平衡・pH測定の物理化学的基礎 (ord=6) -/
  | ScientificPrinciple
  /-- 国際的な海洋観測の計測標準。GOOS/IOC準拠 (ord=5) -/
  | MeasurementStandard
  /-- データ品質管理の基準。較正・バリデーション手順 (ord=4) -/
  | DataQuality
  /-- 監視運用の手順。観測頻度・地点配置 (ord=3) -/
  | MonitoringProtocol
  /-- データ解析パイプラインの設計。前処理・統合方法 (ord=2) -/
  | AnalysisPipeline
  /-- 酸性化予測モデルの手法選択。シナリオに応じて変更可能 (ord=1) -/
  | PredictionModel
  /-- 生態系影響に関する仮説。長期観測で検証が必要 (ord=0) -/
  | EcologicalImpact
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ScientificPrinciple => 6
  | .MeasurementStandard => 5
  | .DataQuality => 4
  | .MonitoringProtocol => 3
  | .AnalysisPipeline => 2
  | .PredictionModel => 1
  | .EcologicalImpact => 0

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
  bottom := .EcologicalImpact
  nontrivial := ⟨.ScientificPrinciple, .EcologicalImpact, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ScientificPrinciple
  | .s149_p01 => .ScientificPrinciple
  -- MeasurementStandard
  | .s149_p02 | .s149_p03 | .s149_p04 => .MeasurementStandard
  -- DataQuality
  | .s149_p05 | .s149_p06 | .s149_p07 => .DataQuality
  -- MonitoringProtocol
  | .s149_p08 | .s149_p09 | .s149_p10 => .MonitoringProtocol
  -- AnalysisPipeline
  | .s149_p11 | .s149_p12 | .s149_p13 => .AnalysisPipeline
  -- PredictionModel
  | .s149_p14 | .s149_p15 | .s149_p16 => .PredictionModel
  -- EcologicalImpact
  | .s149_p17 | .s149_p18 | .s149_p19 | .s149_p20 => .EcologicalImpact

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

end TestCoverage.S149

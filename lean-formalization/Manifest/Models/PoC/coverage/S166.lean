/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **foodSafetyLaw** (ord=5): 食品衛生法・HACCP義務に基づく安全基準 [C1]
- **traceabilityStandard** (ord=4): ISO 22005準拠のトレーサビリティ要件 [C2, H1]
- **supplyChainIntegrity** (ord=3): サプライチェーン各段階のデータ完全性保証 [H2]
- **qualityGrading** (ord=2): 品質等級判定と格付けロジック [H3, H4]
- **consumerInterface** (ord=1): 消費者向け産地・履歴情報の提示方式 [H5]
- **analyticsLayer** (ord=0): 流通効率化・需要予測のための分析 [H6]
-/

namespace TestScenario.S166

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | haccpCompliance
  | recallCapability
  | coldChainIntegrity
  | lotIdentification
  | originCertification
  | slaughterRecord
  | transportLog
  | tamperDetection
  | blockchainAnchor
  | marblingScore
  | agingDuration
  | gradeLabelAssign
  | qrCodeDisplay
  | allergenDisclosure
  | demandForecast
  | wasteReduction
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .haccpCompliance => []
  | .recallCapability => []
  | .coldChainIntegrity => []
  | .lotIdentification => [.haccpCompliance]
  | .originCertification => [.lotIdentification]
  | .slaughterRecord => [.haccpCompliance, .lotIdentification]
  | .transportLog => [.coldChainIntegrity, .lotIdentification]
  | .tamperDetection => [.transportLog]
  | .blockchainAnchor => [.tamperDetection, .originCertification]
  | .marblingScore => [.slaughterRecord]
  | .agingDuration => [.coldChainIntegrity, .marblingScore]
  | .gradeLabelAssign => [.marblingScore, .agingDuration]
  | .qrCodeDisplay => [.blockchainAnchor, .gradeLabelAssign]
  | .allergenDisclosure => [.haccpCompliance, .qrCodeDisplay]
  | .demandForecast => [.transportLog, .gradeLabelAssign]
  | .wasteReduction => [.demandForecast, .agingDuration]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品衛生法・HACCP義務に基づく安全基準 (ord=5) -/
  | foodSafetyLaw
  /-- ISO 22005準拠のトレーサビリティ要件 (ord=4) -/
  | traceabilityStandard
  /-- サプライチェーン各段階のデータ完全性保証 (ord=3) -/
  | supplyChainIntegrity
  /-- 品質等級判定と格付けロジック (ord=2) -/
  | qualityGrading
  /-- 消費者向け産地・履歴情報の提示方式 (ord=1) -/
  | consumerInterface
  /-- 流通効率化・需要予測のための分析 (ord=0) -/
  | analyticsLayer
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .foodSafetyLaw => 5
  | .traceabilityStandard => 4
  | .supplyChainIntegrity => 3
  | .qualityGrading => 2
  | .consumerInterface => 1
  | .analyticsLayer => 0

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
  bottom := .analyticsLayer
  nontrivial := ⟨.foodSafetyLaw, .analyticsLayer, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- foodSafetyLaw
  | .haccpCompliance | .recallCapability | .coldChainIntegrity => .foodSafetyLaw
  -- traceabilityStandard
  | .lotIdentification | .originCertification | .slaughterRecord => .traceabilityStandard
  -- supplyChainIntegrity
  | .transportLog | .tamperDetection | .blockchainAnchor => .supplyChainIntegrity
  -- qualityGrading
  | .marblingScore | .agingDuration | .gradeLabelAssign => .qualityGrading
  -- consumerInterface
  | .qrCodeDisplay | .allergenDisclosure => .consumerInterface
  -- analyticsLayer
  | .demandForecast | .wasteReduction => .analyticsLayer

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

end TestScenario.S166

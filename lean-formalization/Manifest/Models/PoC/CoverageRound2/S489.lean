/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicalSafetyInvariant** (ord=6): 火災・感電・ガス漏れ等の物理的危険を防ぐ絶対不変条件 [C1]
- **PrivacyDataProtectionInvariant** (ord=5): 居住者行動データ・映像の漏洩を防ぐプライバシー絶対要件 [C2]
- **DeviceInteroperabilityPolicy** (ord=4): Matter/Zigbee互換性・ファームウェア更新・認証方針 [C3, C4]
- **EnergyOptimizationPolicy** (ord=3): 電力消費削減・ピークシフト・再生可能エネルギー優先方針 [C5]
- **UserBehaviorModel** (ord=2): 生活パターン・嗜好・季節変動に基づく行動モデル [H1, H2, H3, H4]
- **AutomationPredictionHypothesis** (ord=1): 先読み制御・異常検知・コスト最適化に関する予測仮説 [H5, H6, H7, H8]
-/

namespace TestCoverage.S489

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s489_p01
  | s489_p02
  | s489_p03
  | s489_p04
  | s489_p05
  | s489_p06
  | s489_p07
  | s489_p08
  | s489_p09
  | s489_p10
  | s489_p11
  | s489_p12
  | s489_p13
  | s489_p14
  | s489_p15
  | s489_p16
  | s489_p17
  | s489_p18
  | s489_p19
  | s489_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s489_p01 => []
  | .s489_p02 => []
  | .s489_p03 => [.s489_p01]
  | .s489_p04 => [.s489_p01]
  | .s489_p05 => [.s489_p02]
  | .s489_p06 => [.s489_p04, .s489_p05]
  | .s489_p07 => [.s489_p03]
  | .s489_p08 => [.s489_p06]
  | .s489_p09 => [.s489_p04]
  | .s489_p10 => [.s489_p07]
  | .s489_p11 => [.s489_p08]
  | .s489_p12 => [.s489_p09, .s489_p10]
  | .s489_p13 => [.s489_p10, .s489_p11, .s489_p12]
  | .s489_p14 => [.s489_p09]
  | .s489_p15 => [.s489_p10]
  | .s489_p16 => [.s489_p11, .s489_p14]
  | .s489_p17 => [.s489_p12, .s489_p15]
  | .s489_p18 => [.s489_p14, .s489_p15]
  | .s489_p19 => [.s489_p16, .s489_p17]
  | .s489_p20 => [.s489_p18, .s489_p19]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 火災・感電・ガス漏れ等の物理的危険を防ぐ絶対不変条件 (ord=6) -/
  | PhysicalSafetyInvariant
  /-- 居住者行動データ・映像の漏洩を防ぐプライバシー絶対要件 (ord=5) -/
  | PrivacyDataProtectionInvariant
  /-- Matter/Zigbee互換性・ファームウェア更新・認証方針 (ord=4) -/
  | DeviceInteroperabilityPolicy
  /-- 電力消費削減・ピークシフト・再生可能エネルギー優先方針 (ord=3) -/
  | EnergyOptimizationPolicy
  /-- 生活パターン・嗜好・季節変動に基づく行動モデル (ord=2) -/
  | UserBehaviorModel
  /-- 先読み制御・異常検知・コスト最適化に関する予測仮説 (ord=1) -/
  | AutomationPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicalSafetyInvariant => 6
  | .PrivacyDataProtectionInvariant => 5
  | .DeviceInteroperabilityPolicy => 4
  | .EnergyOptimizationPolicy => 3
  | .UserBehaviorModel => 2
  | .AutomationPredictionHypothesis => 1

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
  bottom := .AutomationPredictionHypothesis
  nontrivial := ⟨.PhysicalSafetyInvariant, .AutomationPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicalSafetyInvariant
  | .s489_p01 | .s489_p03 => .PhysicalSafetyInvariant
  -- PrivacyDataProtectionInvariant
  | .s489_p02 => .PrivacyDataProtectionInvariant
  -- DeviceInteroperabilityPolicy
  | .s489_p04 | .s489_p05 | .s489_p06 => .DeviceInteroperabilityPolicy
  -- EnergyOptimizationPolicy
  | .s489_p07 | .s489_p08 => .EnergyOptimizationPolicy
  -- UserBehaviorModel
  | .s489_p09 | .s489_p10 | .s489_p11 | .s489_p12 | .s489_p13 => .UserBehaviorModel
  -- AutomationPredictionHypothesis
  | .s489_p14 | .s489_p15 | .s489_p16 | .s489_p17 | .s489_p18 | .s489_p19 | .s489_p20 => .AutomationPredictionHypothesis

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

end TestCoverage.S489

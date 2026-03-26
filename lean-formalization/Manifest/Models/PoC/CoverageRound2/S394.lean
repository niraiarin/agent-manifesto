/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LifeSafetyInvariant** (ord=5): 作業員の生命・身体安全に関わる絶対不変条件（労働安全衛生法準拠） [C1]
- **HazardDetectionPolicy** (ord=4): 危険区域への立入禁止・ヘルメット着用の強制的検知方針 [C2, C3]
- **EmergencyResponse** (ord=3): 事故発生時の即時通報・作業停止・救急要請に関する対応原則 [C4, C5]
- **RiskAssessmentPolicy** (ord=2): 日常的リスクアセスメント・ヒヤリハット記録の方針 [C6, H1, H2]
- **PredictiveSafetyHypothesis** (ord=1): 過去事故データ・天候・作業疲労度から事故予測する仮説モデル [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S394

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s394_p01
  | s394_p02
  | s394_p03
  | s394_p04
  | s394_p05
  | s394_p06
  | s394_p07
  | s394_p08
  | s394_p09
  | s394_p10
  | s394_p11
  | s394_p12
  | s394_p13
  | s394_p14
  | s394_p15
  | s394_p16
  | s394_p17
  | s394_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s394_p01 => []
  | .s394_p02 => [.s394_p01]
  | .s394_p03 => [.s394_p01]
  | .s394_p04 => [.s394_p02, .s394_p03]
  | .s394_p05 => [.s394_p02]
  | .s394_p06 => [.s394_p03]
  | .s394_p07 => [.s394_p05, .s394_p06]
  | .s394_p08 => [.s394_p04]
  | .s394_p09 => [.s394_p07]
  | .s394_p10 => [.s394_p08]
  | .s394_p11 => [.s394_p09, .s394_p10]
  | .s394_p12 => [.s394_p08]
  | .s394_p13 => [.s394_p09]
  | .s394_p14 => [.s394_p11]
  | .s394_p15 => [.s394_p12]
  | .s394_p16 => [.s394_p13]
  | .s394_p17 => [.s394_p14, .s394_p15]
  | .s394_p18 => [.s394_p16, .s394_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 作業員の生命・身体安全に関わる絶対不変条件（労働安全衛生法準拠） (ord=5) -/
  | LifeSafetyInvariant
  /-- 危険区域への立入禁止・ヘルメット着用の強制的検知方針 (ord=4) -/
  | HazardDetectionPolicy
  /-- 事故発生時の即時通報・作業停止・救急要請に関する対応原則 (ord=3) -/
  | EmergencyResponse
  /-- 日常的リスクアセスメント・ヒヤリハット記録の方針 (ord=2) -/
  | RiskAssessmentPolicy
  /-- 過去事故データ・天候・作業疲労度から事故予測する仮説モデル (ord=1) -/
  | PredictiveSafetyHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LifeSafetyInvariant => 5
  | .HazardDetectionPolicy => 4
  | .EmergencyResponse => 3
  | .RiskAssessmentPolicy => 2
  | .PredictiveSafetyHypothesis => 1

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
  bottom := .PredictiveSafetyHypothesis
  nontrivial := ⟨.LifeSafetyInvariant, .PredictiveSafetyHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LifeSafetyInvariant
  | .s394_p01 => .LifeSafetyInvariant
  -- HazardDetectionPolicy
  | .s394_p02 | .s394_p03 | .s394_p04 => .HazardDetectionPolicy
  -- EmergencyResponse
  | .s394_p05 | .s394_p06 | .s394_p07 => .EmergencyResponse
  -- RiskAssessmentPolicy
  | .s394_p08 | .s394_p09 | .s394_p10 | .s394_p11 => .RiskAssessmentPolicy
  -- PredictiveSafetyHypothesis
  | .s394_p12 | .s394_p13 | .s394_p14 | .s394_p15 | .s394_p16 | .s394_p17 | .s394_p18 => .PredictiveSafetyHypothesis

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

end TestCoverage.S394

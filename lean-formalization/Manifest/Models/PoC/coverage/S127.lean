/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalObligation** (ord=6): 法令遵守義務。個人情報保護法・特商法等 [C1]
- **FraudPolicy** (ord=5): 不正対策ポリシー。経営レベルで設定 [C2, C3]
- **RiskFramework** (ord=4): リスク評価フレームワーク。業界基準に基づく [C4, H1]
- **DetectionRule** (ord=3): 検知ルールの設計。精度と再現率のバランス [C5, H2, H3]
- **FeatureEngineering** (ord=2): 特徴量エンジニアリング。データに基づく技術選択 [C6, H4, H5]
- **ModelSelection** (ord=1): モデル選択。性能評価に基づく技術判断 [H6]
- **ThresholdTuning** (ord=0): 閾値の微調整。運用データで継続的に最適化 [H7]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s127_p01
  | s127_p02
  | s127_p03
  | s127_p04
  | s127_p05
  | s127_p06
  | s127_p07
  | s127_p08
  | s127_p09
  | s127_p10
  | s127_p11
  | s127_p12
  | s127_p13
  | s127_p14
  | s127_p15
  | s127_p16
  | s127_p17
  | s127_p18
  | s127_p19
  | s127_p20
  | s127_p21
  | s127_p22
  | s127_p23
  | s127_p24
  | s127_p25
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s127_p01 => []
  | .s127_p02 => []
  | .s127_p03 => [.s127_p01]
  | .s127_p04 => [.s127_p01]
  | .s127_p05 => [.s127_p01, .s127_p02]
  | .s127_p06 => [.s127_p03]
  | .s127_p07 => [.s127_p04]
  | .s127_p08 => [.s127_p03, .s127_p05]
  | .s127_p09 => [.s127_p06]
  | .s127_p10 => [.s127_p04, .s127_p20]
  | .s127_p11 => [.s127_p07]
  | .s127_p12 => [.s127_p06, .s127_p08]
  | .s127_p13 => [.s127_p07]
  | .s127_p14 => [.s127_p09]
  | .s127_p15 => [.s127_p11]
  | .s127_p16 => [.s127_p09, .s127_p12]
  | .s127_p17 => [.s127_p13]
  | .s127_p18 => [.s127_p14]
  | .s127_p19 => [.s127_p15, .s127_p16]
  | .s127_p20 => [.s127_p04]
  | .s127_p21 => [.s127_p18]
  | .s127_p22 => [.s127_p19]
  | .s127_p23 => [.s127_p20, .s127_p21]
  | .s127_p24 => [.s127_p17]
  | .s127_p25 => [.s127_p22, .s127_p24]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法令遵守義務。個人情報保護法・特商法等 (ord=6) -/
  | LegalObligation
  /-- 不正対策ポリシー。経営レベルで設定 (ord=5) -/
  | FraudPolicy
  /-- リスク評価フレームワーク。業界基準に基づく (ord=4) -/
  | RiskFramework
  /-- 検知ルールの設計。精度と再現率のバランス (ord=3) -/
  | DetectionRule
  /-- 特徴量エンジニアリング。データに基づく技術選択 (ord=2) -/
  | FeatureEngineering
  /-- モデル選択。性能評価に基づく技術判断 (ord=1) -/
  | ModelSelection
  /-- 閾値の微調整。運用データで継続的に最適化 (ord=0) -/
  | ThresholdTuning
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalObligation => 6
  | .FraudPolicy => 5
  | .RiskFramework => 4
  | .DetectionRule => 3
  | .FeatureEngineering => 2
  | .ModelSelection => 1
  | .ThresholdTuning => 0

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
  bottom := .ThresholdTuning
  nontrivial := ⟨.LegalObligation, .ThresholdTuning, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalObligation
  | .s127_p01 | .s127_p02 => .LegalObligation
  -- FraudPolicy
  | .s127_p03 | .s127_p04 | .s127_p05 => .FraudPolicy
  -- RiskFramework
  | .s127_p06 | .s127_p07 | .s127_p08 | .s127_p10 | .s127_p20 => .RiskFramework
  -- DetectionRule
  | .s127_p09 | .s127_p11 | .s127_p12 | .s127_p13 => .DetectionRule
  -- FeatureEngineering
  | .s127_p14 | .s127_p15 | .s127_p16 | .s127_p17 => .FeatureEngineering
  -- ModelSelection
  | .s127_p18 | .s127_p19 => .ModelSelection
  -- ThresholdTuning
  | .s127_p21 | .s127_p22 | .s127_p23 | .s127_p24 | .s127_p25 => .ThresholdTuning

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

end Manifest.Models

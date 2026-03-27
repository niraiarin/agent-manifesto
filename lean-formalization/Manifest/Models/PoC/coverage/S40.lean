/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **insurance_regulation** (ord=4): 保険業法・個人情報保護法・料率算定基準の法的制約 [C1, C2]
- **actuarial_standard** (ord=3): アクチュアリー基準・リスク評価手法・公平性要件 [C3, C4, H1]
- **scoring_model** (ord=2): 運転スコアリングモデル・特徴量設計・閾値設定 [C5, H2]
- **product_config** (ord=1): 商品設定・割引率・通知・レポート形式 [C6, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | rate_filing_compliance
  | driver_data_privacy
  | loss_ratio_target
  | risk_factor_fairness
  | credibility_weighting_model
  | driving_behavior_score
  | trip_segmentation_algorithm
  | harsh_event_detection
  | premium_discount_schedule
  | driver_feedback_frequency
  | renewal_pricing_algorithm
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .rate_filing_compliance => []
  | .driver_data_privacy => []
  | .loss_ratio_target => []
  | .risk_factor_fairness => []
  | .credibility_weighting_model => []
  | .driving_behavior_score => []
  | .trip_segmentation_algorithm => []
  | .harsh_event_detection => []
  | .premium_discount_schedule => []
  | .driver_feedback_frequency => []
  | .renewal_pricing_algorithm => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 保険業法・個人情報保護法・料率算定基準の法的制約 (ord=4) -/
  | insurance_regulation
  /-- アクチュアリー基準・リスク評価手法・公平性要件 (ord=3) -/
  | actuarial_standard
  /-- 運転スコアリングモデル・特徴量設計・閾値設定 (ord=2) -/
  | scoring_model
  /-- 商品設定・割引率・通知・レポート形式 (ord=1) -/
  | product_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .insurance_regulation => 4
  | .actuarial_standard => 3
  | .scoring_model => 2
  | .product_config => 1

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
  bottom := .product_config
  nontrivial := ⟨.insurance_regulation, .product_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- insurance_regulation
  | .rate_filing_compliance | .driver_data_privacy => .insurance_regulation
  -- actuarial_standard
  | .loss_ratio_target | .risk_factor_fairness | .credibility_weighting_model => .actuarial_standard
  -- scoring_model
  | .driving_behavior_score | .trip_segmentation_algorithm | .harsh_event_detection => .scoring_model
  -- product_config
  | .premium_discount_schedule | .driver_feedback_frequency | .renewal_pricing_algorithm => .product_config

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

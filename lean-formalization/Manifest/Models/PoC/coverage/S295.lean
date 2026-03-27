/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **detection_invariant** (ord=4): CME見逃し防止の不変制約 [C1]
- **coordination_rule** (ord=3): NICT連携・多分野配信の制度ルール [C2, C4]
- **forecast_spec** (ord=2): 予測精度・不確実性表示の品質基準 [C3, H3]
- **model_choice** (ord=1): 検知・伝搬モデルの選択仮説 [H1, H2]
-/

namespace CMEPrediction

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | no_miss_cme
  | sensitivity_max
  | nict_alignment
  | multi_sector_push
  | arrival_uncertainty
  | historical_stats
  | sdo_soho_pipeline
  | drag_based_model
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .no_miss_cme => []
  | .sensitivity_max => []
  | .nict_alignment => [.no_miss_cme]
  | .multi_sector_push => [.no_miss_cme]
  | .arrival_uncertainty => [.nict_alignment]
  | .historical_stats => [.arrival_uncertainty]
  | .sdo_soho_pipeline => [.sensitivity_max]
  | .drag_based_model => [.arrival_uncertainty, .sdo_soho_pipeline]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- CME見逃し防止の不変制約 (ord=4) -/
  | detection_invariant
  /-- NICT連携・多分野配信の制度ルール (ord=3) -/
  | coordination_rule
  /-- 予測精度・不確実性表示の品質基準 (ord=2) -/
  | forecast_spec
  /-- 検知・伝搬モデルの選択仮説 (ord=1) -/
  | model_choice
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .detection_invariant => 4
  | .coordination_rule => 3
  | .forecast_spec => 2
  | .model_choice => 1

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
  bottom := .model_choice
  nontrivial := ⟨.detection_invariant, .model_choice, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- detection_invariant
  | .no_miss_cme | .sensitivity_max => .detection_invariant
  -- coordination_rule
  | .nict_alignment | .multi_sector_push => .coordination_rule
  -- forecast_spec
  | .arrival_uncertainty | .historical_stats => .forecast_spec
  -- model_choice
  | .sdo_soho_pipeline | .drag_based_model => .model_choice

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

end CMEPrediction

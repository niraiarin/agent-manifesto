/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **master_authority** (ord=6): 刀匠の判断・経験が最上位である不変原則 [C1]
- **cultural_boundary** (ord=5): 流派尊重・データ権限の文化的制約 [C3, C4]
- **workspace_rule** (ord=4): 作業環境への非干渉ルール [C2, C5]
- **measurement_method** (ord=3): 計測方式・ノイズ処理の設計 [H1, H4]
- **analysis_model** (ord=2): 温度解析・プロファイルモデル [H2, H3]
- **material_hypothesis** (ord=1): 玉鋼特性に関する仮説 [H3]
-/

namespace SwordForgingTempControl

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | smith_overrides
  | no_single_optimum
  | data_confidential
  | non_interference
  | smoke_tolerance
  | ir_thermography
  | noise_filter
  | school_profile
  | quench_temp_est
  | tamahagane_model
  | carbon_variance
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .smith_overrides => []
  | .no_single_optimum => [.smith_overrides]
  | .data_confidential => [.smith_overrides]
  | .non_interference => [.smith_overrides]
  | .smoke_tolerance => [.non_interference]
  | .ir_thermography => [.non_interference, .smoke_tolerance]
  | .noise_filter => [.smoke_tolerance]
  | .school_profile => [.no_single_optimum, .ir_thermography]
  | .quench_temp_est => [.ir_thermography]
  | .tamahagane_model => [.quench_temp_est]
  | .carbon_variance => [.tamahagane_model, .school_profile]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 刀匠の判断・経験が最上位である不変原則 (ord=6) -/
  | master_authority
  /-- 流派尊重・データ権限の文化的制約 (ord=5) -/
  | cultural_boundary
  /-- 作業環境への非干渉ルール (ord=4) -/
  | workspace_rule
  /-- 計測方式・ノイズ処理の設計 (ord=3) -/
  | measurement_method
  /-- 温度解析・プロファイルモデル (ord=2) -/
  | analysis_model
  /-- 玉鋼特性に関する仮説 (ord=1) -/
  | material_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .master_authority => 6
  | .cultural_boundary => 5
  | .workspace_rule => 4
  | .measurement_method => 3
  | .analysis_model => 2
  | .material_hypothesis => 1

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
  bottom := .material_hypothesis
  nontrivial := ⟨.master_authority, .material_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- master_authority
  | .smith_overrides => .master_authority
  -- cultural_boundary
  | .no_single_optimum | .data_confidential => .cultural_boundary
  -- workspace_rule
  | .non_interference | .smoke_tolerance => .workspace_rule
  -- measurement_method
  | .ir_thermography | .noise_filter => .measurement_method
  -- analysis_model
  | .school_profile | .quench_temp_est => .analysis_model
  -- material_hypothesis
  | .tamahagane_model | .carbon_variance => .material_hypothesis

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

end SwordForgingTempControl

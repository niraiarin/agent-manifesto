/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **building_code** (ord=4): 建築基準法・省エネ法に基づく法的要件。改正まで不変 [C1, C2]
- **physics** (ord=3): 熱力学・流体力学の物理法則。変わらない自然法則 [H1, H3]
- **simulation** (ord=2): BEM シミュレーションモデルの構成・パラメータ [C4, C5, H4]
- **optimization** (ord=1): 省エネ改修・HVAC 制御の最適化推奨 [C6, H6, H7]
- **hypothesis** (ord=0): 新素材・新技術による性能改善の未検証仮説 [H8]
-/

namespace BuildingEnergyPerformance

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | code_insulation
  | code_hvac_std
  | code_certification
  | phys_heat_transfer
  | phys_ventilation
  | phys_solar_gain
  | sim_envelope
  | sim_hvac
  | sim_occupancy
  | sim_weather
  | opt_retrofit
  | opt_control
  | opt_renewable
  | opt_cost_benefit
  | hyp_phase_change
  | hyp_ai_hvac
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .code_insulation => []
  | .code_hvac_std => []
  | .code_certification => []
  | .phys_heat_transfer => []
  | .phys_ventilation => [.phys_heat_transfer]
  | .phys_solar_gain => []
  | .sim_envelope => [.code_insulation, .phys_heat_transfer]
  | .sim_hvac => [.code_hvac_std, .phys_ventilation]
  | .sim_occupancy => [.sim_envelope]
  | .sim_weather => [.phys_solar_gain]
  | .opt_retrofit => [.sim_envelope, .sim_hvac, .code_certification]
  | .opt_control => [.sim_hvac, .sim_occupancy]
  | .opt_renewable => [.sim_weather, .phys_solar_gain]
  | .opt_cost_benefit => [.opt_retrofit, .opt_renewable]
  | .hyp_phase_change => [.sim_envelope, .phys_heat_transfer]
  | .hyp_ai_hvac => [.opt_control, .sim_occupancy]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 建築基準法・省エネ法に基づく法的要件。改正まで不変 (ord=4) -/
  | building_code
  /-- 熱力学・流体力学の物理法則。変わらない自然法則 (ord=3) -/
  | physics
  /-- BEM シミュレーションモデルの構成・パラメータ (ord=2) -/
  | simulation
  /-- 省エネ改修・HVAC 制御の最適化推奨 (ord=1) -/
  | optimization
  /-- 新素材・新技術による性能改善の未検証仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .building_code => 4
  | .physics => 3
  | .simulation => 2
  | .optimization => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.building_code, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- building_code
  | .code_insulation | .code_hvac_std | .code_certification => .building_code
  -- physics
  | .phys_heat_transfer | .phys_ventilation | .phys_solar_gain => .physics
  -- simulation
  | .sim_envelope | .sim_hvac | .sim_occupancy | .sim_weather => .simulation
  -- optimization
  | .opt_retrofit | .opt_control | .opt_renewable | .opt_cost_benefit => .optimization
  -- hypothesis
  | .hyp_phase_change | .hyp_ai_hvac => .hypothesis

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

end BuildingEnergyPerformance

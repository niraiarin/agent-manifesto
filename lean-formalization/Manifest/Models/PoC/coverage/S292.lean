/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **craft_authority** (ord=4): 職人の技と判断が最上位である不変原則 [C1]
- **ethical_boundary** (ord=3): データ所有権・公開範囲の倫理的制約 [C3, C4]
- **sensing_policy** (ord=2): センシング配置・方式の運用方針 [C2, H1]
- **analysis_method** (ord=1): 解析手法・モデルの選択 [H2, H3]
-/

namespace WashiCraftAnalysis

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | artisan_primacy
  | no_ai_instruction
  | data_ownership
  | disclosure_control
  | non_intrusive_sensor
  | camera_placement
  | water_temp_model
  | skeleton_estimation
  | fiber_density_corr
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .artisan_primacy => []
  | .no_ai_instruction => []
  | .data_ownership => [.artisan_primacy]
  | .disclosure_control => [.artisan_primacy, .data_ownership]
  | .non_intrusive_sensor => [.artisan_primacy]
  | .camera_placement => [.non_intrusive_sensor]
  | .water_temp_model => [.non_intrusive_sensor]
  | .skeleton_estimation => [.camera_placement]
  | .fiber_density_corr => [.water_temp_model]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 職人の技と判断が最上位である不変原則 (ord=4) -/
  | craft_authority
  /-- データ所有権・公開範囲の倫理的制約 (ord=3) -/
  | ethical_boundary
  /-- センシング配置・方式の運用方針 (ord=2) -/
  | sensing_policy
  /-- 解析手法・モデルの選択 (ord=1) -/
  | analysis_method
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .craft_authority => 4
  | .ethical_boundary => 3
  | .sensing_policy => 2
  | .analysis_method => 1

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
  bottom := .analysis_method
  nontrivial := ⟨.craft_authority, .analysis_method, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- craft_authority
  | .artisan_primacy | .no_ai_instruction => .craft_authority
  -- ethical_boundary
  | .data_ownership | .disclosure_control => .ethical_boundary
  -- sensing_policy
  | .non_intrusive_sensor | .camera_placement => .sensing_policy
  -- analysis_method
  | .water_temp_model | .skeleton_estimation | .fiber_density_corr => .analysis_method

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

end WashiCraftAnalysis

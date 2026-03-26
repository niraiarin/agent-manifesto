/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **biosafety** (ord=4): 農薬使用規制・検疫法規・食品安全基準。法的不変条件 [C1, C2]
- **pathology** (ord=3): 植物病理学の確立知見。病原体同定・感染メカニズム [C4, H1, H3]
- **diagnosis** (ord=2): 画像診断モデル・症状分類の方法論 [C5, H4, H5]
- **treatment** (ord=1): 防除推奨・薬剤選択のアルゴリズム的判断 [C6, C7, H6]
- **hypothesis** (ord=0): 新規病害・耐性変異に関する未検証仮説 [H7, H8]
-/

namespace CropDiseaseDiagnosis

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | bio_pesticide_reg
  | bio_quarantine
  | bio_food_safety
  | path_taxonomy
  | path_lifecycle
  | path_env_factor
  | path_resistance
  | diag_image_cls
  | diag_symptom_map
  | diag_severity
  | diag_multi_crop
  | treat_recommend
  | treat_organic
  | treat_schedule
  | treat_rotation
  | hyp_new_strain
  | hyp_climate_shift
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .bio_pesticide_reg => []
  | .bio_quarantine => []
  | .bio_food_safety => []
  | .path_taxonomy => []
  | .path_lifecycle => [.path_taxonomy]
  | .path_env_factor => []
  | .path_resistance => [.path_taxonomy, .path_lifecycle]
  | .diag_image_cls => [.path_taxonomy]
  | .diag_symptom_map => [.path_lifecycle, .path_env_factor]
  | .diag_severity => [.diag_image_cls, .diag_symptom_map]
  | .diag_multi_crop => [.diag_image_cls]
  | .treat_recommend => [.bio_pesticide_reg, .diag_severity]
  | .treat_organic => [.bio_food_safety, .treat_recommend]
  | .treat_schedule => [.path_env_factor, .diag_severity]
  | .treat_rotation => [.path_resistance, .treat_recommend]
  | .hyp_new_strain => [.diag_image_cls, .path_taxonomy]
  | .hyp_climate_shift => [.path_env_factor, .diag_symptom_map]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 農薬使用規制・検疫法規・食品安全基準。法的不変条件 (ord=4) -/
  | biosafety
  /-- 植物病理学の確立知見。病原体同定・感染メカニズム (ord=3) -/
  | pathology
  /-- 画像診断モデル・症状分類の方法論 (ord=2) -/
  | diagnosis
  /-- 防除推奨・薬剤選択のアルゴリズム的判断 (ord=1) -/
  | treatment
  /-- 新規病害・耐性変異に関する未検証仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .biosafety => 4
  | .pathology => 3
  | .diagnosis => 2
  | .treatment => 1
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
  nontrivial := ⟨.biosafety, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- biosafety
  | .bio_pesticide_reg | .bio_quarantine | .bio_food_safety => .biosafety
  -- pathology
  | .path_taxonomy | .path_lifecycle | .path_env_factor | .path_resistance => .pathology
  -- diagnosis
  | .diag_image_cls | .diag_symptom_map | .diag_severity | .diag_multi_crop => .diagnosis
  -- treatment
  | .treat_recommend | .treat_organic | .treat_schedule | .treat_rotation => .treatment
  -- hypothesis
  | .hyp_new_strain | .hyp_climate_shift => .hypothesis

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

end CropDiseaseDiagnosis

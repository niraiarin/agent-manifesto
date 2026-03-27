/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **pharmacological_law** (ord=4): 薬事法・臨床試験規制・安全性基準 [C1, C2]
- **therapeutic_constraint** (ord=3): 治療域・毒性閾値・薬物動態パラメータ [C3, C4, H1]
- **delivery_design** (ord=2): デリバリーシステム設計・製剤パラメータ [C5, C6, H2]
- **manufacturing_config** (ord=1): 製造条件・品質管理パラメータ・ログ設定 [C7, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | regulatory_approval_pathway
  | gmp_compliance
  | therapeutic_window_definition
  | maximum_toxicity_threshold
  | pharmacokinetic_model
  | nanoparticle_size_range
  | release_profile_target
  | targeting_ligand_selection
  | batch_size_specification
  | temperature_control_range
  | quality_control_sampling
  | stability_test_protocol
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .regulatory_approval_pathway => []
  | .gmp_compliance => []
  | .therapeutic_window_definition => []
  | .maximum_toxicity_threshold => []
  | .pharmacokinetic_model => []
  | .nanoparticle_size_range => []
  | .release_profile_target => []
  | .targeting_ligand_selection => []
  | .batch_size_specification => []
  | .temperature_control_range => []
  | .quality_control_sampling => []
  | .stability_test_protocol => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 薬事法・臨床試験規制・安全性基準 (ord=4) -/
  | pharmacological_law
  /-- 治療域・毒性閾値・薬物動態パラメータ (ord=3) -/
  | therapeutic_constraint
  /-- デリバリーシステム設計・製剤パラメータ (ord=2) -/
  | delivery_design
  /-- 製造条件・品質管理パラメータ・ログ設定 (ord=1) -/
  | manufacturing_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .pharmacological_law => 4
  | .therapeutic_constraint => 3
  | .delivery_design => 2
  | .manufacturing_config => 1

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
  bottom := .manufacturing_config
  nontrivial := ⟨.pharmacological_law, .manufacturing_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- pharmacological_law
  | .regulatory_approval_pathway | .gmp_compliance => .pharmacological_law
  -- therapeutic_constraint
  | .therapeutic_window_definition | .maximum_toxicity_threshold | .pharmacokinetic_model => .therapeutic_constraint
  -- delivery_design
  | .nanoparticle_size_range | .release_profile_target | .targeting_ligand_selection => .delivery_design
  -- manufacturing_config
  | .batch_size_specification | .temperature_control_range | .quality_control_sampling | .stability_test_protocol => .manufacturing_config

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

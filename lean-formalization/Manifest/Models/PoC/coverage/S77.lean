/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **airworthiness_constraint** (ord=5): 耐空性・航空安全に関する絶対的制約（人命直結） [C1, C2]
- **regulatory_postulate** (ord=4): 航空局規制・整備基準への準拠前提 [C3, H1]
- **prediction_principle** (ord=3): 故障予測アルゴリズムの原則（精度・リードタイム・説明可能性） [C4, C5, H2]
- **data_boundary** (ord=2): センサーデータ・運航データの制約条件 [C6, H3]
- **maintenance_design** (ord=1): 整備計画・通知フローの設計判断 [H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_6b2b0d
  | prop_a4d658
  | ADSB_aa7896
  | EASAFAA_5a5c5c
  | MSG_c0eb2b
  | prop_102cdf
  | prop_b0963d
  | prop_0ef57c
  | FADEC_2dbc11
  | prop_a479ed
  | prop_ca534b
  | MROAPI_5d1c52
  | prop_bca176
  | prop_40c509
  | prop_754363
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_6b2b0d => []
  | .prop_a4d658 => []
  | .ADSB_aa7896 => []
  | .EASAFAA_5a5c5c => []
  | .MSG_c0eb2b => []
  | .prop_102cdf => []
  | .prop_b0963d => []
  | .prop_0ef57c => []
  | .FADEC_2dbc11 => []
  | .prop_a479ed => []
  | .prop_ca534b => []
  | .MROAPI_5d1c52 => []
  | .prop_bca176 => []
  | .prop_40c509 => []
  | .prop_754363 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 耐空性・航空安全に関する絶対的制約（人命直結） (ord=5) -/
  | airworthiness_constraint
  /-- 航空局規制・整備基準への準拠前提 (ord=4) -/
  | regulatory_postulate
  /-- 故障予測アルゴリズムの原則（精度・リードタイム・説明可能性） (ord=3) -/
  | prediction_principle
  /-- センサーデータ・運航データの制約条件 (ord=2) -/
  | data_boundary
  /-- 整備計画・通知フローの設計判断 (ord=1) -/
  | maintenance_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .airworthiness_constraint => 5
  | .regulatory_postulate => 4
  | .prediction_principle => 3
  | .data_boundary => 2
  | .maintenance_design => 1

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
  bottom := .maintenance_design
  nontrivial := ⟨.airworthiness_constraint, .maintenance_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- airworthiness_constraint
  | .prop_6b2b0d | .prop_a4d658 | .ADSB_aa7896 => .airworthiness_constraint
  -- regulatory_postulate
  | .EASAFAA_5a5c5c | .MSG_c0eb2b => .regulatory_postulate
  -- prediction_principle
  | .prop_102cdf | .prop_b0963d | .prop_0ef57c => .prediction_principle
  -- data_boundary
  | .FADEC_2dbc11 | .prop_a479ed | .prop_ca534b => .data_boundary
  -- maintenance_design
  | .MROAPI_5d1c52 | .prop_bca176 | .prop_40c509 | .prop_754363 => .maintenance_design

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

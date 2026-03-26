/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_constraint** (ord=5): 人命・環境に関わる安全上の不変制約 [C1, C2]
- **regulatory_postulate** (ord=4): 法規制・基準への準拠前提 [C3, H1]
- **detection_principle** (ord=3): 漏洩検知アルゴリズムの原則（感度・特異度・応答時間） [C4, C5, H2]
- **monitoring_boundary** (ord=2): センサー網・通信インフラの制約条件 [C6, H3, H4]
- **alert_design** (ord=1): アラート通知・対応フローの設計判断 [H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_c5b707
  | prop_18d100
  | prop_cf7447
  | prop_5b5940
  | API_99d60b
  | prop_3f6911
  | prop_21dca5
  | prop_c98b18
  | ms_f0fb3d
  | prop_4f76c1
  | DTS_aabe30
  | prop_d3bbc6
  | KPI_da254c
  | prop_442e2b
  | prop_d1092f
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_c5b707 => []
  | .prop_18d100 => []
  | .prop_cf7447 => []
  | .prop_5b5940 => []
  | .API_99d60b => []
  | .prop_3f6911 => []
  | .prop_21dca5 => []
  | .prop_c98b18 => []
  | .ms_f0fb3d => []
  | .prop_4f76c1 => []
  | .DTS_aabe30 => []
  | .prop_d3bbc6 => []
  | .KPI_da254c => []
  | .prop_442e2b => []
  | .prop_d1092f => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人命・環境に関わる安全上の不変制約 (ord=5) -/
  | safety_constraint
  /-- 法規制・基準への準拠前提 (ord=4) -/
  | regulatory_postulate
  /-- 漏洩検知アルゴリズムの原則（感度・特異度・応答時間） (ord=3) -/
  | detection_principle
  /-- センサー網・通信インフラの制約条件 (ord=2) -/
  | monitoring_boundary
  /-- アラート通知・対応フローの設計判断 (ord=1) -/
  | alert_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_constraint => 5
  | .regulatory_postulate => 4
  | .detection_principle => 3
  | .monitoring_boundary => 2
  | .alert_design => 1

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
  bottom := .alert_design
  nontrivial := ⟨.safety_constraint, .alert_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_constraint
  | .prop_c5b707 | .prop_18d100 | .prop_cf7447 => .safety_constraint
  -- regulatory_postulate
  | .prop_5b5940 | .API_99d60b => .regulatory_postulate
  -- detection_principle
  | .prop_3f6911 | .prop_21dca5 | .prop_c98b18 => .detection_principle
  -- monitoring_boundary
  | .ms_f0fb3d | .prop_4f76c1 | .DTS_aabe30 => .monitoring_boundary
  -- alert_design
  | .prop_d3bbc6 | .KPI_da254c | .prop_442e2b | .prop_d1092f => .alert_design

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

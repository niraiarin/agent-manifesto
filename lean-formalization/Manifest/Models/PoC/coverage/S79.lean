/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ethical_constraint** (ord=5): 公衆衛生倫理・プライバシー・差別防止の不変制約 [C1, C2]
- **epidemiological_postulate** (ord=4): 疫学モデルの前提（感染力・潜伏期間・免疫動態） [C3, H1]
- **simulation_principle** (ord=3): シミュレーションの原則（不確実性表現・シナリオ比較・検証可能性） [C4, C5, H2]
- **data_boundary** (ord=2): データソース・粒度・更新頻度の制約条件 [C6, H3, H4]
- **visualization_design** (ord=1): 可視化・レポート・意思決定支援の設計判断 [H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_b7342f
  | prop_8ccb9a
  | prop_6c10c0
  | R_9867a5
  | prop_7a64f4
  | prop_7d1c75
  | prop_dc2b1b
  | prop_8e78db
  | prop_48a3ca
  | reportingd_f1e209
  | prop_878c8f
  | prop_132910
  | prop_ca9ce4
  | beforeafter_89a941
  | prop_63b546
  | prop_f2003e
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_b7342f => []
  | .prop_8ccb9a => []
  | .prop_6c10c0 => []
  | .R_9867a5 => []
  | .prop_7a64f4 => []
  | .prop_7d1c75 => []
  | .prop_dc2b1b => []
  | .prop_8e78db => []
  | .prop_48a3ca => []
  | .reportingd_f1e209 => []
  | .prop_878c8f => []
  | .prop_132910 => []
  | .prop_ca9ce4 => []
  | .beforeafter_89a941 => []
  | .prop_63b546 => []
  | .prop_f2003e => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 公衆衛生倫理・プライバシー・差別防止の不変制約 (ord=5) -/
  | ethical_constraint
  /-- 疫学モデルの前提（感染力・潜伏期間・免疫動態） (ord=4) -/
  | epidemiological_postulate
  /-- シミュレーションの原則（不確実性表現・シナリオ比較・検証可能性） (ord=3) -/
  | simulation_principle
  /-- データソース・粒度・更新頻度の制約条件 (ord=2) -/
  | data_boundary
  /-- 可視化・レポート・意思決定支援の設計判断 (ord=1) -/
  | visualization_design
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ethical_constraint => 5
  | .epidemiological_postulate => 4
  | .simulation_principle => 3
  | .data_boundary => 2
  | .visualization_design => 1

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
  bottom := .visualization_design
  nontrivial := ⟨.ethical_constraint, .visualization_design, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ethical_constraint
  | .prop_b7342f | .prop_8ccb9a | .prop_6c10c0 => .ethical_constraint
  -- epidemiological_postulate
  | .R_9867a5 | .prop_7a64f4 | .prop_7d1c75 => .epidemiological_postulate
  -- simulation_principle
  | .prop_dc2b1b | .prop_8e78db | .prop_48a3ca => .simulation_principle
  -- data_boundary
  | .reportingd_f1e209 | .prop_878c8f | .prop_132910 => .data_boundary
  -- visualization_design
  | .prop_ca9ce4 | .beforeafter_89a941 | .prop_63b546 | .prop_f2003e => .visualization_design

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

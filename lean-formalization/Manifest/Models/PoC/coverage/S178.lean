/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyStandard** (ord=4): 建築基準法・エレベーター安全規格に基づく安全基準 [C1, C2]
- **MaintenanceEvidence** (ord=3): 保守実績から得られた経験則 [C3, H1]
- **PredictionDesign** (ord=2): 予測モデルの設計選択 [C4, H2, H3]
- **CostHypothesis** (ord=1): コスト効果に関する未検証の仮説 [C5, H4, H5]
-/

namespace TestCoverage.S178

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s178_p01
  | s178_p02
  | s178_p03
  | s178_p04
  | s178_p05
  | s178_p06
  | s178_p07
  | s178_p08
  | s178_p09
  | s178_p10
  | s178_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s178_p01 => []
  | .s178_p02 => []
  | .s178_p03 => [.s178_p01]
  | .s178_p04 => [.s178_p01, .s178_p02]
  | .s178_p05 => [.s178_p03]
  | .s178_p06 => [.s178_p03, .s178_p04]
  | .s178_p07 => [.s178_p04]
  | .s178_p08 => [.s178_p05]
  | .s178_p09 => [.s178_p06]
  | .s178_p10 => [.s178_p07]
  | .s178_p11 => [.s178_p05, .s178_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 建築基準法・エレベーター安全規格に基づく安全基準 (ord=4) -/
  | SafetyStandard
  /-- 保守実績から得られた経験則 (ord=3) -/
  | MaintenanceEvidence
  /-- 予測モデルの設計選択 (ord=2) -/
  | PredictionDesign
  /-- コスト効果に関する未検証の仮説 (ord=1) -/
  | CostHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyStandard => 4
  | .MaintenanceEvidence => 3
  | .PredictionDesign => 2
  | .CostHypothesis => 1

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
  bottom := .CostHypothesis
  nontrivial := ⟨.SafetyStandard, .CostHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyStandard
  | .s178_p01 | .s178_p02 => .SafetyStandard
  -- MaintenanceEvidence
  | .s178_p03 | .s178_p04 => .MaintenanceEvidence
  -- PredictionDesign
  | .s178_p05 | .s178_p06 | .s178_p07 => .PredictionDesign
  -- CostHypothesis
  | .s178_p08 | .s178_p09 | .s178_p10 | .s178_p11 => .CostHypothesis

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

end TestCoverage.S178

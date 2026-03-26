/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EcologicalConstraint** (ord=3): 海洋生態学の確立された知見と国際条約に基づく制約 [C1, C2]
- **MonitoringEvidence** (ord=2): 観測データから得られた経験的知見。新データで更新 [C3, C4, H1, H2]
- **ModelDesign** (ord=1): 予測モデルの設計選択。計算手法に依存 [C5, H3, H4]
- **BleachingHypothesis** (ord=0): 白化メカニズムに関する未検証の仮説 [H5, H6]
-/

namespace TestCoverage.S189

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s189_p01
  | s189_p02
  | s189_p03
  | s189_p04
  | s189_p05
  | s189_p06
  | s189_p07
  | s189_p08
  | s189_p09
  | s189_p10
  | s189_p11
  | s189_p12
  | s189_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s189_p01 => []
  | .s189_p02 => []
  | .s189_p03 => [.s189_p01]
  | .s189_p04 => [.s189_p01]
  | .s189_p05 => [.s189_p01, .s189_p02]
  | .s189_p06 => [.s189_p03]
  | .s189_p07 => [.s189_p03, .s189_p04]
  | .s189_p08 => [.s189_p04, .s189_p05]
  | .s189_p09 => [.s189_p05]
  | .s189_p10 => [.s189_p06]
  | .s189_p11 => [.s189_p07, .s189_p08]
  | .s189_p12 => [.s189_p09]
  | .s189_p13 => [.s189_p06, .s189_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋生態学の確立された知見と国際条約に基づく制約 (ord=3) -/
  | EcologicalConstraint
  /-- 観測データから得られた経験的知見。新データで更新 (ord=2) -/
  | MonitoringEvidence
  /-- 予測モデルの設計選択。計算手法に依存 (ord=1) -/
  | ModelDesign
  /-- 白化メカニズムに関する未検証の仮説 (ord=0) -/
  | BleachingHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EcologicalConstraint => 3
  | .MonitoringEvidence => 2
  | .ModelDesign => 1
  | .BleachingHypothesis => 0

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
  bottom := .BleachingHypothesis
  nontrivial := ⟨.EcologicalConstraint, .BleachingHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EcologicalConstraint
  | .s189_p01 | .s189_p02 => .EcologicalConstraint
  -- MonitoringEvidence
  | .s189_p03 | .s189_p04 | .s189_p05 => .MonitoringEvidence
  -- ModelDesign
  | .s189_p06 | .s189_p07 | .s189_p08 | .s189_p09 => .ModelDesign
  -- BleachingHypothesis
  | .s189_p10 | .s189_p11 | .s189_p12 | .s189_p13 => .BleachingHypothesis

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

end TestCoverage.S189

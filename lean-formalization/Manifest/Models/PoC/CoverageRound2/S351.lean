/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PublicHealthSafety** (ord=4): 市民の生命・健康を守る最上位安全制約。感染拡大防止のための絶対条件 [C1, C2]
- **EpidemiologicalLaw** (ord=3): 感染症法・隔離指針・報告義務など法的・規制的要件 [C3, C4]
- **ModelingPolicy** (ord=2): SIRモデルパラメータ選定・データ収集方針・シミュレーション精度基準 [C5, H1, H2]
- **TransmissionHypothesis** (ord=1): 接触率・潜伏期間・免疫持続期間に関する推論仮説。観察データで更新可能 [H3, H4, H5, H6]
-/

namespace TestCoverage.S351

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s351_p01
  | s351_p02
  | s351_p03
  | s351_p04
  | s351_p05
  | s351_p06
  | s351_p07
  | s351_p08
  | s351_p09
  | s351_p10
  | s351_p11
  | s351_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s351_p01 => []
  | .s351_p02 => [.s351_p01]
  | .s351_p03 => [.s351_p01]
  | .s351_p04 => [.s351_p02]
  | .s351_p05 => [.s351_p03]
  | .s351_p06 => [.s351_p04]
  | .s351_p07 => [.s351_p03, .s351_p04]
  | .s351_p08 => [.s351_p05]
  | .s351_p09 => [.s351_p06]
  | .s351_p10 => [.s351_p07]
  | .s351_p11 => [.s351_p08]
  | .s351_p12 => [.s351_p09, .s351_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 市民の生命・健康を守る最上位安全制約。感染拡大防止のための絶対条件 (ord=4) -/
  | PublicHealthSafety
  /-- 感染症法・隔離指針・報告義務など法的・規制的要件 (ord=3) -/
  | EpidemiologicalLaw
  /-- SIRモデルパラメータ選定・データ収集方針・シミュレーション精度基準 (ord=2) -/
  | ModelingPolicy
  /-- 接触率・潜伏期間・免疫持続期間に関する推論仮説。観察データで更新可能 (ord=1) -/
  | TransmissionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PublicHealthSafety => 4
  | .EpidemiologicalLaw => 3
  | .ModelingPolicy => 2
  | .TransmissionHypothesis => 1

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
  bottom := .TransmissionHypothesis
  nontrivial := ⟨.PublicHealthSafety, .TransmissionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PublicHealthSafety
  | .s351_p01 | .s351_p02 => .PublicHealthSafety
  -- EpidemiologicalLaw
  | .s351_p03 | .s351_p04 => .EpidemiologicalLaw
  -- ModelingPolicy
  | .s351_p05 | .s351_p06 | .s351_p07 => .ModelingPolicy
  -- TransmissionHypothesis
  | .s351_p08 | .s351_p09 | .s351_p10 | .s351_p11 | .s351_p12 => .TransmissionHypothesis

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

end TestCoverage.S351

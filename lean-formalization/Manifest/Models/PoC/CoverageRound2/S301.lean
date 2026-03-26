/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyInvariant** (ord=4): 乗客・歩行者の生命安全に関する絶対不変条件 [C1, C2]
- **RegulatoryCompliance** (ord=3): 道路交通法・自動運転安全基準への適合要件 [C3, C4]
- **OperationalPolicy** (ord=2): 運行管理・緊急停止・監視員介入の方針 [C5, H1, H2]
- **PredictionHypothesis** (ord=1): 障害物検知・経路予測に関する推論仮説 [H3, H4, H5]
-/

namespace TestCoverage.S301

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s301_p01
  | s301_p02
  | s301_p03
  | s301_p04
  | s301_p05
  | s301_p06
  | s301_p07
  | s301_p08
  | s301_p09
  | s301_p10
  | s301_p11
  | s301_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s301_p01 => []
  | .s301_p02 => []
  | .s301_p03 => [.s301_p01]
  | .s301_p04 => [.s301_p01]
  | .s301_p05 => [.s301_p02]
  | .s301_p06 => [.s301_p04]
  | .s301_p07 => [.s301_p05]
  | .s301_p08 => [.s301_p03, .s301_p06]
  | .s301_p09 => [.s301_p06]
  | .s301_p10 => [.s301_p07]
  | .s301_p11 => [.s301_p09]
  | .s301_p12 => [.s301_p08, .s301_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 乗客・歩行者の生命安全に関する絶対不変条件 (ord=4) -/
  | SafetyInvariant
  /-- 道路交通法・自動運転安全基準への適合要件 (ord=3) -/
  | RegulatoryCompliance
  /-- 運行管理・緊急停止・監視員介入の方針 (ord=2) -/
  | OperationalPolicy
  /-- 障害物検知・経路予測に関する推論仮説 (ord=1) -/
  | PredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyInvariant => 4
  | .RegulatoryCompliance => 3
  | .OperationalPolicy => 2
  | .PredictionHypothesis => 1

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
  bottom := .PredictionHypothesis
  nontrivial := ⟨.SafetyInvariant, .PredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyInvariant
  | .s301_p01 | .s301_p02 | .s301_p03 => .SafetyInvariant
  -- RegulatoryCompliance
  | .s301_p04 | .s301_p05 => .RegulatoryCompliance
  -- OperationalPolicy
  | .s301_p06 | .s301_p07 | .s301_p08 => .OperationalPolicy
  -- PredictionHypothesis
  | .s301_p09 | .s301_p10 | .s301_p11 | .s301_p12 => .PredictionHypothesis

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

end TestCoverage.S301

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **HousingRightInvariant** (ord=5): 住宅確保要配慮者への支援義務・居住の安定確保の絶対的法的制約 [C1]
- **AntiDiscriminationCompliance** (ord=4): 住宅入居差別禁止・外国人・障害者・高齢者への平等取扱い義務 [C2, C3]
- **AllocationFairnessPolicy** (ord=3): 抽選・ポイント制・優先順位の透明性と公平性確保の行政方針 [C4, H1, H2]
- **NeedAssessmentRule** (ord=2): 所得・世帯構成・住宅困窮度・緊急性スコアリングの評価ルール [C5, H3, H4]
- **InventoryMatchingHypothesis** (ord=1): 空き物件予測・世帯ニーズマッチング・長期待機最小化の仮説 [C6, H5]
-/

namespace TestCoverage.S458

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s458_p01
  | s458_p02
  | s458_p03
  | s458_p04
  | s458_p05
  | s458_p06
  | s458_p07
  | s458_p08
  | s458_p09
  | s458_p10
  | s458_p11
  | s458_p12
  | s458_p13
  | s458_p14
  | s458_p15
  | s458_p16
  | s458_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s458_p01 => []
  | .s458_p02 => [.s458_p01]
  | .s458_p03 => [.s458_p01]
  | .s458_p04 => [.s458_p02, .s458_p03]
  | .s458_p05 => [.s458_p02]
  | .s458_p06 => [.s458_p03, .s458_p04]
  | .s458_p07 => [.s458_p05, .s458_p06]
  | .s458_p08 => [.s458_p05, .s458_p06]
  | .s458_p09 => [.s458_p05]
  | .s458_p10 => [.s458_p07]
  | .s458_p11 => [.s458_p08, .s458_p09]
  | .s458_p12 => [.s458_p10, .s458_p11]
  | .s458_p13 => [.s458_p09]
  | .s458_p14 => [.s458_p10, .s458_p12]
  | .s458_p15 => [.s458_p13, .s458_p14]
  | .s458_p16 => [.s458_p11]
  | .s458_p17 => [.s458_p15, .s458_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 住宅確保要配慮者への支援義務・居住の安定確保の絶対的法的制約 (ord=5) -/
  | HousingRightInvariant
  /-- 住宅入居差別禁止・外国人・障害者・高齢者への平等取扱い義務 (ord=4) -/
  | AntiDiscriminationCompliance
  /-- 抽選・ポイント制・優先順位の透明性と公平性確保の行政方針 (ord=3) -/
  | AllocationFairnessPolicy
  /-- 所得・世帯構成・住宅困窮度・緊急性スコアリングの評価ルール (ord=2) -/
  | NeedAssessmentRule
  /-- 空き物件予測・世帯ニーズマッチング・長期待機最小化の仮説 (ord=1) -/
  | InventoryMatchingHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .HousingRightInvariant => 5
  | .AntiDiscriminationCompliance => 4
  | .AllocationFairnessPolicy => 3
  | .NeedAssessmentRule => 2
  | .InventoryMatchingHypothesis => 1

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
  bottom := .InventoryMatchingHypothesis
  nontrivial := ⟨.HousingRightInvariant, .InventoryMatchingHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- HousingRightInvariant
  | .s458_p01 => .HousingRightInvariant
  -- AntiDiscriminationCompliance
  | .s458_p02 | .s458_p03 | .s458_p04 => .AntiDiscriminationCompliance
  -- AllocationFairnessPolicy
  | .s458_p05 | .s458_p06 | .s458_p07 | .s458_p08 => .AllocationFairnessPolicy
  -- NeedAssessmentRule
  | .s458_p09 | .s458_p10 | .s458_p11 | .s458_p12 => .NeedAssessmentRule
  -- InventoryMatchingHypothesis
  | .s458_p13 | .s458_p14 | .s458_p15 | .s458_p16 | .s458_p17 => .InventoryMatchingHypothesis

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

end TestCoverage.S458

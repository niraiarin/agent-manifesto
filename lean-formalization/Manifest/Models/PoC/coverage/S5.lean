/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LifeSafety** (ord=5): 人命最優先。全判断の不動点 [C1]
- **EmergencyProtocol** (ord=4): 災害対策基本法・自治体防災計画に基づく手順 [C2, H1]
- **SituationalAssessment** (ord=3): リアルタイム状況判断。センサー・通報データに基づく [C3, H2]
- **RouteOptimization** (ord=2): 避難経路の最適化。混雑・通行止め情報を反映 [H3, H4]
- **IndividualAccommodation** (ord=1): 個人の身体能力・特別なニーズへの対応 [C5, H5]
-/

namespace TestCoverage.S5

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s5_p01
  | s5_p02
  | s5_p03
  | s5_p04
  | s5_p05
  | s5_p06
  | s5_p07
  | s5_p08
  | s5_p09
  | s5_p10
  | s5_p11
  | s5_p12
  | s5_p13
  | s5_p14
  | s5_p15
  | s5_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s5_p01 => []
  | .s5_p02 => []
  | .s5_p03 => [.s5_p01]
  | .s5_p04 => [.s5_p02]
  | .s5_p05 => [.s5_p01, .s5_p02]
  | .s5_p06 => [.s5_p03]
  | .s5_p07 => [.s5_p04]
  | .s5_p08 => [.s5_p03, .s5_p05]
  | .s5_p09 => [.s5_p06]
  | .s5_p10 => [.s5_p07]
  | .s5_p11 => [.s5_p06, .s5_p08]
  | .s5_p12 => [.s5_p09]
  | .s5_p13 => [.s5_p10]
  | .s5_p14 => [.s5_p11]
  | .s5_p15 => [.s5_p12, .s5_p13]
  | .s5_p16 => [.s5_p05]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人命最優先。全判断の不動点 (ord=5) -/
  | LifeSafety
  /-- 災害対策基本法・自治体防災計画に基づく手順 (ord=4) -/
  | EmergencyProtocol
  /-- リアルタイム状況判断。センサー・通報データに基づく (ord=3) -/
  | SituationalAssessment
  /-- 避難経路の最適化。混雑・通行止め情報を反映 (ord=2) -/
  | RouteOptimization
  /-- 個人の身体能力・特別なニーズへの対応 (ord=1) -/
  | IndividualAccommodation
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LifeSafety => 5
  | .EmergencyProtocol => 4
  | .SituationalAssessment => 3
  | .RouteOptimization => 2
  | .IndividualAccommodation => 1

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
  bottom := .IndividualAccommodation
  nontrivial := ⟨.LifeSafety, .IndividualAccommodation, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LifeSafety
  | .s5_p01 | .s5_p02 => .LifeSafety
  -- EmergencyProtocol
  | .s5_p03 | .s5_p04 | .s5_p05 => .EmergencyProtocol
  -- SituationalAssessment
  | .s5_p06 | .s5_p07 | .s5_p08 | .s5_p16 => .SituationalAssessment
  -- RouteOptimization
  | .s5_p09 | .s5_p10 | .s5_p11 => .RouteOptimization
  -- IndividualAccommodation
  | .s5_p12 | .s5_p13 | .s5_p14 | .s5_p15 => .IndividualAccommodation

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

end TestCoverage.S5

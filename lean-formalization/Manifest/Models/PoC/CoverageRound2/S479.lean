/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FoodSafetyAndCertificationInvariant** (ord=4): 農薬残留基準・有機認証・食品安全管理の絶対条件 [C1, C2]
- **ResourceManagementPolicy** (ord=3): 水・肥料・エネルギー使用量の適正管理ポリシー [C3, C4]
- **CultivationControlPolicy** (ord=2): センサーデータ連携・環境制御・生育記録管理の方針 [H1, H2, H3]
- **YieldPredictionHypothesis** (ord=1): 気象・土壌・生育データから収量・品質を予測する仮説 [H4, H5, H6, H7]
-/

namespace TestCoverage.S479

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s479_p01
  | s479_p02
  | s479_p03
  | s479_p04
  | s479_p05
  | s479_p06
  | s479_p07
  | s479_p08
  | s479_p09
  | s479_p10
  | s479_p11
  | s479_p12
  | s479_p13
  | s479_p14
  | s479_p15
  | s479_p16
  | s479_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s479_p01 => []
  | .s479_p02 => []
  | .s479_p03 => [.s479_p01, .s479_p02]
  | .s479_p04 => [.s479_p01]
  | .s479_p05 => [.s479_p02]
  | .s479_p06 => [.s479_p04, .s479_p05]
  | .s479_p07 => [.s479_p03]
  | .s479_p08 => [.s479_p05]
  | .s479_p09 => [.s479_p06, .s479_p07]
  | .s479_p10 => [.s479_p07]
  | .s479_p11 => [.s479_p08]
  | .s479_p12 => [.s479_p09, .s479_p10]
  | .s479_p13 => [.s479_p11, .s479_p12]
  | .s479_p14 => [.s479_p07, .s479_p08]
  | .s479_p15 => [.s479_p10, .s479_p11]
  | .s479_p16 => [.s479_p06]
  | .s479_p17 => [.s479_p14, .s479_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 農薬残留基準・有機認証・食品安全管理の絶対条件 (ord=4) -/
  | FoodSafetyAndCertificationInvariant
  /-- 水・肥料・エネルギー使用量の適正管理ポリシー (ord=3) -/
  | ResourceManagementPolicy
  /-- センサーデータ連携・環境制御・生育記録管理の方針 (ord=2) -/
  | CultivationControlPolicy
  /-- 気象・土壌・生育データから収量・品質を予測する仮説 (ord=1) -/
  | YieldPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FoodSafetyAndCertificationInvariant => 4
  | .ResourceManagementPolicy => 3
  | .CultivationControlPolicy => 2
  | .YieldPredictionHypothesis => 1

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
  bottom := .YieldPredictionHypothesis
  nontrivial := ⟨.FoodSafetyAndCertificationInvariant, .YieldPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FoodSafetyAndCertificationInvariant
  | .s479_p01 | .s479_p02 | .s479_p03 => .FoodSafetyAndCertificationInvariant
  -- ResourceManagementPolicy
  | .s479_p04 | .s479_p05 | .s479_p06 | .s479_p16 => .ResourceManagementPolicy
  -- CultivationControlPolicy
  | .s479_p07 | .s479_p08 | .s479_p09 | .s479_p14 | .s479_p17 => .CultivationControlPolicy
  -- YieldPredictionHypothesis
  | .s479_p10 | .s479_p11 | .s479_p12 | .s479_p13 | .s479_p15 => .YieldPredictionHypothesis

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

end TestCoverage.S479

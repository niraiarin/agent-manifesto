/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **StatutoryObligation** (ord=4): 法定報告義務・金融規制当局への提出要件。違反は刑事・行政罰の対象 [C1, C2]
- **DataAccuracyStandard** (ord=3): 報告データの正確性・完全性・一貫性に関する品質基準 [C3, C4]
- **ProcessAutomation** (ord=2): データ収集・変換・検証・提出プロセスの自動化方針 [C5, H1, H2, H3]
- **EfficiencyOptimization** (ord=1): 処理速度・コスト削減・人的エラー低減に向けた最適化仮説 [H4, H5, H6]
-/

namespace TestCoverage.S412

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s412_p01
  | s412_p02
  | s412_p03
  | s412_p04
  | s412_p05
  | s412_p06
  | s412_p07
  | s412_p08
  | s412_p09
  | s412_p10
  | s412_p11
  | s412_p12
  | s412_p13
  | s412_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s412_p01 => []
  | .s412_p02 => []
  | .s412_p03 => [.s412_p01, .s412_p02]
  | .s412_p04 => [.s412_p01]
  | .s412_p05 => [.s412_p02]
  | .s412_p06 => [.s412_p03, .s412_p04]
  | .s412_p07 => [.s412_p04]
  | .s412_p08 => [.s412_p05, .s412_p06]
  | .s412_p09 => [.s412_p07, .s412_p08]
  | .s412_p10 => [.s412_p07]
  | .s412_p11 => [.s412_p08]
  | .s412_p12 => [.s412_p09]
  | .s412_p13 => [.s412_p10, .s412_p11]
  | .s412_p14 => [.s412_p12, .s412_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法定報告義務・金融規制当局への提出要件。違反は刑事・行政罰の対象 (ord=4) -/
  | StatutoryObligation
  /-- 報告データの正確性・完全性・一貫性に関する品質基準 (ord=3) -/
  | DataAccuracyStandard
  /-- データ収集・変換・検証・提出プロセスの自動化方針 (ord=2) -/
  | ProcessAutomation
  /-- 処理速度・コスト削減・人的エラー低減に向けた最適化仮説 (ord=1) -/
  | EfficiencyOptimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .StatutoryObligation => 4
  | .DataAccuracyStandard => 3
  | .ProcessAutomation => 2
  | .EfficiencyOptimization => 1

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
  bottom := .EfficiencyOptimization
  nontrivial := ⟨.StatutoryObligation, .EfficiencyOptimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- StatutoryObligation
  | .s412_p01 | .s412_p02 | .s412_p03 => .StatutoryObligation
  -- DataAccuracyStandard
  | .s412_p04 | .s412_p05 | .s412_p06 => .DataAccuracyStandard
  -- ProcessAutomation
  | .s412_p07 | .s412_p08 | .s412_p09 => .ProcessAutomation
  -- EfficiencyOptimization
  | .s412_p10 | .s412_p11 | .s412_p12 | .s412_p13 | .s412_p14 => .EfficiencyOptimization

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

end TestCoverage.S412

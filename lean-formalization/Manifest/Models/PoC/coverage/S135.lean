/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicalLaw** (ord=7): 物理法則に基づく気候制約。覆らない自然法則 [C1]
- **ObservationalRecord** (ord=6): 観測データに基づく経験的事実。計測精度に依存 [C2, C3]
- **ScientificConsensus** (ord=5): IPCCレベルの科学的合意。新知見で修正されうる [C4, H1]
- **RegionalProjection** (ord=4): 地域スケールの気候予測。ダウンスケーリング手法に依存 [H2, H3]
- **ImpactAssessment** (ord=3): 社会経済的影響評価。シナリオ選択に依存 [C5, H4]
- **AdaptationStrategy** (ord=2): 適応策の設計。政策判断で変更可能 [C6, H5]
- **UncertaintyBound** (ord=1): 不確実性の定量化。モデルアンサンブルで推定 [H6]
-/

namespace TestCoverage.S135

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s135_p01
  | s135_p02
  | s135_p03
  | s135_p04
  | s135_p05
  | s135_p06
  | s135_p07
  | s135_p08
  | s135_p09
  | s135_p10
  | s135_p11
  | s135_p12
  | s135_p13
  | s135_p14
  | s135_p15
  | s135_p16
  | s135_p17
  | s135_p18
  | s135_p19
  | s135_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s135_p01 => []
  | .s135_p02 => [.s135_p01]
  | .s135_p03 => [.s135_p01]
  | .s135_p04 => [.s135_p02]
  | .s135_p05 => [.s135_p02, .s135_p03]
  | .s135_p06 => [.s135_p01]
  | .s135_p07 => [.s135_p04]
  | .s135_p08 => [.s135_p05]
  | .s135_p09 => [.s135_p04, .s135_p06]
  | .s135_p10 => [.s135_p07]
  | .s135_p11 => [.s135_p08]
  | .s135_p12 => [.s135_p07, .s135_p09]
  | .s135_p13 => [.s135_p10]
  | .s135_p14 => [.s135_p11]
  | .s135_p15 => [.s135_p10, .s135_p12]
  | .s135_p16 => [.s135_p07]
  | .s135_p17 => [.s135_p08]
  | .s135_p18 => [.s135_p09]
  | .s135_p19 => [.s135_p13, .s135_p14]
  | .s135_p20 => [.s135_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 物理法則に基づく気候制約。覆らない自然法則 (ord=7) -/
  | PhysicalLaw
  /-- 観測データに基づく経験的事実。計測精度に依存 (ord=6) -/
  | ObservationalRecord
  /-- IPCCレベルの科学的合意。新知見で修正されうる (ord=5) -/
  | ScientificConsensus
  /-- 地域スケールの気候予測。ダウンスケーリング手法に依存 (ord=4) -/
  | RegionalProjection
  /-- 社会経済的影響評価。シナリオ選択に依存 (ord=3) -/
  | ImpactAssessment
  /-- 適応策の設計。政策判断で変更可能 (ord=2) -/
  | AdaptationStrategy
  /-- 不確実性の定量化。モデルアンサンブルで推定 (ord=1) -/
  | UncertaintyBound
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicalLaw => 7
  | .ObservationalRecord => 6
  | .ScientificConsensus => 5
  | .RegionalProjection => 4
  | .ImpactAssessment => 3
  | .AdaptationStrategy => 2
  | .UncertaintyBound => 1

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
  bottom := .UncertaintyBound
  nontrivial := ⟨.PhysicalLaw, .UncertaintyBound, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨7, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicalLaw
  | .s135_p01 => .PhysicalLaw
  -- ObservationalRecord
  | .s135_p02 | .s135_p03 => .ObservationalRecord
  -- ScientificConsensus
  | .s135_p04 | .s135_p05 | .s135_p06 => .ScientificConsensus
  -- RegionalProjection
  | .s135_p07 | .s135_p08 | .s135_p09 => .RegionalProjection
  -- ImpactAssessment
  | .s135_p10 | .s135_p11 | .s135_p12 => .ImpactAssessment
  -- AdaptationStrategy
  | .s135_p13 | .s135_p14 | .s135_p15 => .AdaptationStrategy
  -- UncertaintyBound
  | .s135_p16 | .s135_p17 | .s135_p18 | .s135_p19 | .s135_p20 => .UncertaintyBound

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

end TestCoverage.S135

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **TeacherWellbeingInvariant** (ord=5): 教師の過重労働防止・健康保護に関する絶対不変条件 [C1]
- **LaborRegulationCompliance** (ord=4): 労働基準法・教育職員の勤務時間規制への適合 [C2, C3]
- **CurriculumCoveragePolicy** (ord=3): 学習指導要領・教科担当適格性・専科配置の方針 [C4, H1]
- **ScheduleBalancingModel** (ord=2): 時限配置・移動コスト・連続授業制約の最適化モデル [H2, H3]
- **TeacherPreferenceHypothesis** (ord=1): 個人の疲労蓄積・授業準備コストに関する推論仮説 [C5, H4, H5, H6]
-/

namespace TestCoverage.S376

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s376_p01
  | s376_p02
  | s376_p03
  | s376_p04
  | s376_p05
  | s376_p06
  | s376_p07
  | s376_p08
  | s376_p09
  | s376_p10
  | s376_p11
  | s376_p12
  | s376_p13
  | s376_p14
  | s376_p15
  | s376_p16
  | s376_p17
  | s376_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s376_p01 => []
  | .s376_p02 => [.s376_p01]
  | .s376_p03 => [.s376_p01]
  | .s376_p04 => [.s376_p02, .s376_p03]
  | .s376_p05 => [.s376_p02]
  | .s376_p06 => [.s376_p03]
  | .s376_p07 => [.s376_p04, .s376_p05, .s376_p06]
  | .s376_p08 => [.s376_p05]
  | .s376_p09 => [.s376_p06]
  | .s376_p10 => [.s376_p07, .s376_p08, .s376_p09]
  | .s376_p11 => [.s376_p08]
  | .s376_p12 => [.s376_p09]
  | .s376_p13 => [.s376_p10]
  | .s376_p14 => [.s376_p11]
  | .s376_p15 => [.s376_p12, .s376_p13]
  | .s376_p16 => [.s376_p13, .s376_p14]
  | .s376_p17 => [.s376_p11, .s376_p12]
  | .s376_p18 => [.s376_p15, .s376_p16, .s376_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 教師の過重労働防止・健康保護に関する絶対不変条件 (ord=5) -/
  | TeacherWellbeingInvariant
  /-- 労働基準法・教育職員の勤務時間規制への適合 (ord=4) -/
  | LaborRegulationCompliance
  /-- 学習指導要領・教科担当適格性・専科配置の方針 (ord=3) -/
  | CurriculumCoveragePolicy
  /-- 時限配置・移動コスト・連続授業制約の最適化モデル (ord=2) -/
  | ScheduleBalancingModel
  /-- 個人の疲労蓄積・授業準備コストに関する推論仮説 (ord=1) -/
  | TeacherPreferenceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .TeacherWellbeingInvariant => 5
  | .LaborRegulationCompliance => 4
  | .CurriculumCoveragePolicy => 3
  | .ScheduleBalancingModel => 2
  | .TeacherPreferenceHypothesis => 1

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
  bottom := .TeacherPreferenceHypothesis
  nontrivial := ⟨.TeacherWellbeingInvariant, .TeacherPreferenceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- TeacherWellbeingInvariant
  | .s376_p01 => .TeacherWellbeingInvariant
  -- LaborRegulationCompliance
  | .s376_p02 | .s376_p03 | .s376_p04 => .LaborRegulationCompliance
  -- CurriculumCoveragePolicy
  | .s376_p05 | .s376_p06 | .s376_p07 => .CurriculumCoveragePolicy
  -- ScheduleBalancingModel
  | .s376_p08 | .s376_p09 | .s376_p10 => .ScheduleBalancingModel
  -- TeacherPreferenceHypothesis
  | .s376_p11 | .s376_p12 | .s376_p13 | .s376_p14 | .s376_p15 | .s376_p16 | .s376_p17 | .s376_p18 => .TeacherPreferenceHypothesis

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

end TestCoverage.S376

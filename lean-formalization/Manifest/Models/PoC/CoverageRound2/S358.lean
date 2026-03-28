/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AntiDiscriminationInvariant** (ord=5): 雇用差別禁止・公平採用の絶対制約。性別・人種・年齢等属性による不当選別の禁止 [C1, C2]
- **LaborLawCompliance** (ord=4): 労働基準法・雇用機会均等法・個人情報保護法への準拠 [C3, C4]
- **HiringPolicy** (ord=3): 採用基準・選考フロー・合否通知に関する人事方針 [C5, C6, H1]
- **CandidateEvaluation** (ord=2): スキルマッチング・文化適合・ポテンシャル評価の方法論 [H2, H3, H4]
- **PredictiveHypothesis** (ord=1): 入社後パフォーマンス・定着率・成長予測に関する統計仮説 [H5, H6]
-/

namespace TestCoverage.S358

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s358_p01
  | s358_p02
  | s358_p03
  | s358_p04
  | s358_p05
  | s358_p06
  | s358_p07
  | s358_p08
  | s358_p09
  | s358_p10
  | s358_p11
  | s358_p12
  | s358_p13
  | s358_p14
  | s358_p15
  | s358_p16
  | s358_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s358_p01 => []
  | .s358_p02 => []
  | .s358_p03 => [.s358_p01]
  | .s358_p04 => [.s358_p01]
  | .s358_p05 => [.s358_p02]
  | .s358_p06 => [.s358_p03]
  | .s358_p07 => [.s358_p04]
  | .s358_p08 => [.s358_p05]
  | .s358_p09 => [.s358_p06, .s358_p07]
  | .s358_p10 => [.s358_p07]
  | .s358_p11 => [.s358_p08]
  | .s358_p12 => [.s358_p09]
  | .s358_p13 => [.s358_p10, .s358_p12]
  | .s358_p14 => [.s358_p10]
  | .s358_p15 => [.s358_p11]
  | .s358_p16 => [.s358_p12, .s358_p13]
  | .s358_p17 => [.s358_p14, .s358_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 雇用差別禁止・公平採用の絶対制約。性別・人種・年齢等属性による不当選別の禁止 (ord=5) -/
  | AntiDiscriminationInvariant
  /-- 労働基準法・雇用機会均等法・個人情報保護法への準拠 (ord=4) -/
  | LaborLawCompliance
  /-- 採用基準・選考フロー・合否通知に関する人事方針 (ord=3) -/
  | HiringPolicy
  /-- スキルマッチング・文化適合・ポテンシャル評価の方法論 (ord=2) -/
  | CandidateEvaluation
  /-- 入社後パフォーマンス・定着率・成長予測に関する統計仮説 (ord=1) -/
  | PredictiveHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AntiDiscriminationInvariant => 5
  | .LaborLawCompliance => 4
  | .HiringPolicy => 3
  | .CandidateEvaluation => 2
  | .PredictiveHypothesis => 1

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
  bottom := .PredictiveHypothesis
  nontrivial := ⟨.AntiDiscriminationInvariant, .PredictiveHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AntiDiscriminationInvariant
  | .s358_p01 | .s358_p02 | .s358_p03 => .AntiDiscriminationInvariant
  -- LaborLawCompliance
  | .s358_p04 | .s358_p05 | .s358_p06 => .LaborLawCompliance
  -- HiringPolicy
  | .s358_p07 | .s358_p08 | .s358_p09 => .HiringPolicy
  -- CandidateEvaluation
  | .s358_p10 | .s358_p11 | .s358_p12 | .s358_p13 => .CandidateEvaluation
  -- PredictiveHypothesis
  | .s358_p14 | .s358_p15 | .s358_p16 | .s358_p17 => .PredictiveHypothesis

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

end TestCoverage.S358

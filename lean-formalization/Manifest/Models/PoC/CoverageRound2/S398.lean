/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalComplianceInvariant** (ord=4): 労働基準法・男女雇用機会均等法・障害者差別解消法への完全適合 [C1, C2]
- **FairnessInvariant** (ord=3): 性別・年齢・人種・障害に基づく評価差別の検出・是正の絶対義務 [C3]
- **EvaluationTransparencyPolicy** (ord=2): 評価基準の透明性確保・根拠説明可能性の維持方針 [C4, C5, C6]
- **BiasDetectionHypothesis** (ord=1): 統計的検定・反実仮想分析によるバイアス検出アルゴリズムの仮説 [H1, H2, H3, H4, H5, H6]
-/

namespace TestCoverage.S398

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s398_p01
  | s398_p02
  | s398_p03
  | s398_p04
  | s398_p05
  | s398_p06
  | s398_p07
  | s398_p08
  | s398_p09
  | s398_p10
  | s398_p11
  | s398_p12
  | s398_p13
  | s398_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s398_p01 => []
  | .s398_p02 => []
  | .s398_p03 => [.s398_p01, .s398_p02]
  | .s398_p04 => [.s398_p02]
  | .s398_p05 => [.s398_p03]
  | .s398_p06 => [.s398_p04]
  | .s398_p07 => [.s398_p05, .s398_p06]
  | .s398_p08 => [.s398_p03]
  | .s398_p09 => [.s398_p05]
  | .s398_p10 => [.s398_p07]
  | .s398_p11 => [.s398_p08]
  | .s398_p12 => [.s398_p09]
  | .s398_p13 => [.s398_p10, .s398_p11]
  | .s398_p14 => [.s398_p12, .s398_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 労働基準法・男女雇用機会均等法・障害者差別解消法への完全適合 (ord=4) -/
  | LegalComplianceInvariant
  /-- 性別・年齢・人種・障害に基づく評価差別の検出・是正の絶対義務 (ord=3) -/
  | FairnessInvariant
  /-- 評価基準の透明性確保・根拠説明可能性の維持方針 (ord=2) -/
  | EvaluationTransparencyPolicy
  /-- 統計的検定・反実仮想分析によるバイアス検出アルゴリズムの仮説 (ord=1) -/
  | BiasDetectionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalComplianceInvariant => 4
  | .FairnessInvariant => 3
  | .EvaluationTransparencyPolicy => 2
  | .BiasDetectionHypothesis => 1

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
  bottom := .BiasDetectionHypothesis
  nontrivial := ⟨.LegalComplianceInvariant, .BiasDetectionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalComplianceInvariant
  | .s398_p01 | .s398_p02 => .LegalComplianceInvariant
  -- FairnessInvariant
  | .s398_p03 => .FairnessInvariant
  -- EvaluationTransparencyPolicy
  | .s398_p04 | .s398_p05 | .s398_p06 | .s398_p07 => .EvaluationTransparencyPolicy
  -- BiasDetectionHypothesis
  | .s398_p08 | .s398_p09 | .s398_p10 | .s398_p11 | .s398_p12 | .s398_p13 | .s398_p14 => .BiasDetectionHypothesis

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

end TestCoverage.S398

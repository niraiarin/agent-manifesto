/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **NoiseLegalStandardInvariant** (ord=2): 騒音規制法・環境基本法に基づく地域別環境基準値の絶対遵守制約 [C1, C2]
- **AcousticMeasurementHypothesis** (ord=1): センサー配置・補間アルゴリズム・時系列変動モデルに関する測定仮説 [C3, C4, H1, H2, H3, H4, H5]
-/

namespace TestCoverage.S456

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s456_p01
  | s456_p02
  | s456_p03
  | s456_p04
  | s456_p05
  | s456_p06
  | s456_p07
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s456_p01 => []
  | .s456_p02 => []
  | .s456_p03 => [.s456_p01]
  | .s456_p04 => [.s456_p02]
  | .s456_p05 => [.s456_p03, .s456_p04]
  | .s456_p06 => [.s456_p03]
  | .s456_p07 => [.s456_p05, .s456_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 騒音規制法・環境基本法に基づく地域別環境基準値の絶対遵守制約 (ord=2) -/
  | NoiseLegalStandardInvariant
  /-- センサー配置・補間アルゴリズム・時系列変動モデルに関する測定仮説 (ord=1) -/
  | AcousticMeasurementHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .NoiseLegalStandardInvariant => 2
  | .AcousticMeasurementHypothesis => 1

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
  bottom := .AcousticMeasurementHypothesis
  nontrivial := ⟨.NoiseLegalStandardInvariant, .AcousticMeasurementHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- NoiseLegalStandardInvariant
  | .s456_p01 | .s456_p02 => .NoiseLegalStandardInvariant
  -- AcousticMeasurementHypothesis
  | .s456_p03 | .s456_p04 | .s456_p05 | .s456_p06 | .s456_p07 => .AcousticMeasurementHypothesis

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

end TestCoverage.S456

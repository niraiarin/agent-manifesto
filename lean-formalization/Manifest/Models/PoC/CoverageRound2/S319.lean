/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **structural_safety_invariant** (ord=4): 構造崩壊防止・人間最終確認の絶対要件 [C1, C3, C6]
- **measurement_standard** (ord=3): センサー構成・計測手順の標準 [C2, C4]
- **detection_model** (ord=2): 損傷検知・診断・優先度付けのモデル [C5, H1, H2, H4]
- **architecture_hypothesis** (ord=1): エッジ-クラウド構成・高度モデルの仮説 [H3, H5]
-/

namespace TestCoverage.S319

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s319_p01
  | s319_p02
  | s319_p03
  | s319_p04
  | s319_p05
  | s319_p06
  | s319_p07
  | s319_p08
  | s319_p09
  | s319_p10
  | s319_p11
  | s319_p12
  | s319_p13
  | s319_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s319_p01 => []
  | .s319_p02 => [.s319_p01]
  | .s319_p03 => [.s319_p01]
  | .s319_p04 => [.s319_p01]
  | .s319_p05 => [.s319_p04]
  | .s319_p06 => [.s319_p04, .s319_p05]
  | .s319_p07 => [.s319_p04, .s319_p06]
  | .s319_p08 => [.s319_p01, .s319_p06]
  | .s319_p09 => [.s319_p04, .s319_p06]
  | .s319_p10 => [.s319_p08, .s319_p09]
  | .s319_p11 => [.s319_p07]
  | .s319_p12 => [.s319_p09, .s319_p11]
  | .s319_p13 => [.s319_p06, .s319_p09]
  | .s319_p14 => [.s319_p11, .s319_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 構造崩壊防止・人間最終確認の絶対要件 (ord=4) -/
  | structural_safety_invariant
  /-- センサー構成・計測手順の標準 (ord=3) -/
  | measurement_standard
  /-- 損傷検知・診断・優先度付けのモデル (ord=2) -/
  | detection_model
  /-- エッジ-クラウド構成・高度モデルの仮説 (ord=1) -/
  | architecture_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .structural_safety_invariant => 4
  | .measurement_standard => 3
  | .detection_model => 2
  | .architecture_hypothesis => 1

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
  bottom := .architecture_hypothesis
  nontrivial := ⟨.structural_safety_invariant, .architecture_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- structural_safety_invariant
  | .s319_p01 | .s319_p02 | .s319_p03 => .structural_safety_invariant
  -- measurement_standard
  | .s319_p04 | .s319_p05 => .measurement_standard
  -- detection_model
  | .s319_p06 | .s319_p07 | .s319_p08 | .s319_p09 | .s319_p10 | .s319_p13 => .detection_model
  -- architecture_hypothesis
  | .s319_p11 | .s319_p12 | .s319_p14 => .architecture_hypothesis

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

end TestCoverage.S319

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **VisitorPrivacy** (ord=4): 来園者のプライバシー保護。個人識別データの取扱い制約 [C1, C2]
- **AnimalWelfare** (ord=3): 動物福祉に関する運営方針。動物へのストレス最小化 [C3, H1]
- **OperationalPolicy** (ord=2): 動物園の運営ポリシー。人員配置・混雑管理 [C4, H2]
- **AnalyticsMethod** (ord=1): 行動分析の技術的手法。センサー・アルゴリズム選択 [C5, H3]
- **InsightHypothesis** (ord=0): 来園者行動に関する洞察仮説。データで検証が必要 [H4, H5]
-/

namespace TestCoverage.S148

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s148_p01
  | s148_p02
  | s148_p03
  | s148_p04
  | s148_p05
  | s148_p06
  | s148_p07
  | s148_p08
  | s148_p09
  | s148_p10
  | s148_p11
  | s148_p12
  | s148_p13
  | s148_p14
  | s148_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s148_p01 => []
  | .s148_p02 => []
  | .s148_p03 => []
  | .s148_p04 => [.s148_p01]
  | .s148_p05 => [.s148_p02]
  | .s148_p06 => [.s148_p01, .s148_p03]
  | .s148_p07 => [.s148_p04]
  | .s148_p08 => [.s148_p05]
  | .s148_p09 => [.s148_p04, .s148_p06]
  | .s148_p10 => [.s148_p07]
  | .s148_p11 => [.s148_p08]
  | .s148_p12 => [.s148_p07, .s148_p09]
  | .s148_p13 => [.s148_p10]
  | .s148_p14 => [.s148_p11]
  | .s148_p15 => [.s148_p12, .s148_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 来園者のプライバシー保護。個人識別データの取扱い制約 (ord=4) -/
  | VisitorPrivacy
  /-- 動物福祉に関する運営方針。動物へのストレス最小化 (ord=3) -/
  | AnimalWelfare
  /-- 動物園の運営ポリシー。人員配置・混雑管理 (ord=2) -/
  | OperationalPolicy
  /-- 行動分析の技術的手法。センサー・アルゴリズム選択 (ord=1) -/
  | AnalyticsMethod
  /-- 来園者行動に関する洞察仮説。データで検証が必要 (ord=0) -/
  | InsightHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .VisitorPrivacy => 4
  | .AnimalWelfare => 3
  | .OperationalPolicy => 2
  | .AnalyticsMethod => 1
  | .InsightHypothesis => 0

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
  bottom := .InsightHypothesis
  nontrivial := ⟨.VisitorPrivacy, .InsightHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- VisitorPrivacy
  | .s148_p01 | .s148_p02 | .s148_p03 => .VisitorPrivacy
  -- AnimalWelfare
  | .s148_p04 | .s148_p05 | .s148_p06 => .AnimalWelfare
  -- OperationalPolicy
  | .s148_p07 | .s148_p08 | .s148_p09 => .OperationalPolicy
  -- AnalyticsMethod
  | .s148_p10 | .s148_p11 | .s148_p12 => .AnalyticsMethod
  -- InsightHypothesis
  | .s148_p13 | .s148_p14 | .s148_p15 => .InsightHypothesis

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

end TestCoverage.S148

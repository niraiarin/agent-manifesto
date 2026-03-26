/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **CrisisInterventionInvariant** (ord=4): 自傷・自殺リスク検知時の即時専門家介入の絶対的義務（危機対応プロトコル） [C1]
- **ConfidentialityPolicy** (ord=3): 相談内容の秘密保持・第三者への無断開示禁止方針（法的例外を除く） [C2, C3]
- **SupportQualityPolicy** (ord=2): エビデンスに基づくメンタルヘルス支援手法の適用方針 [C4, C5, H1, H2]
- **EarlyDetectionHypothesis** (ord=1): 行動パターン・SNS利用・出席率からのメンタルヘルス早期検知仮説 [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S396

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s396_p01
  | s396_p02
  | s396_p03
  | s396_p04
  | s396_p05
  | s396_p06
  | s396_p07
  | s396_p08
  | s396_p09
  | s396_p10
  | s396_p11
  | s396_p12
  | s396_p13
  | s396_p14
  | s396_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s396_p01 => []
  | .s396_p02 => [.s396_p01]
  | .s396_p03 => [.s396_p01]
  | .s396_p04 => [.s396_p02, .s396_p03]
  | .s396_p05 => [.s396_p02]
  | .s396_p06 => [.s396_p03]
  | .s396_p07 => [.s396_p04]
  | .s396_p08 => [.s396_p05]
  | .s396_p09 => [.s396_p06, .s396_p07, .s396_p08]
  | .s396_p10 => [.s396_p05]
  | .s396_p11 => [.s396_p07]
  | .s396_p12 => [.s396_p09]
  | .s396_p13 => [.s396_p10]
  | .s396_p14 => [.s396_p11, .s396_p12]
  | .s396_p15 => [.s396_p13, .s396_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 自傷・自殺リスク検知時の即時専門家介入の絶対的義務（危機対応プロトコル） (ord=4) -/
  | CrisisInterventionInvariant
  /-- 相談内容の秘密保持・第三者への無断開示禁止方針（法的例外を除く） (ord=3) -/
  | ConfidentialityPolicy
  /-- エビデンスに基づくメンタルヘルス支援手法の適用方針 (ord=2) -/
  | SupportQualityPolicy
  /-- 行動パターン・SNS利用・出席率からのメンタルヘルス早期検知仮説 (ord=1) -/
  | EarlyDetectionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .CrisisInterventionInvariant => 4
  | .ConfidentialityPolicy => 3
  | .SupportQualityPolicy => 2
  | .EarlyDetectionHypothesis => 1

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
  bottom := .EarlyDetectionHypothesis
  nontrivial := ⟨.CrisisInterventionInvariant, .EarlyDetectionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- CrisisInterventionInvariant
  | .s396_p01 => .CrisisInterventionInvariant
  -- ConfidentialityPolicy
  | .s396_p02 | .s396_p03 | .s396_p04 => .ConfidentialityPolicy
  -- SupportQualityPolicy
  | .s396_p05 | .s396_p06 | .s396_p07 | .s396_p08 | .s396_p09 => .SupportQualityPolicy
  -- EarlyDetectionHypothesis
  | .s396_p10 | .s396_p11 | .s396_p12 | .s396_p13 | .s396_p14 | .s396_p15 => .EarlyDetectionHypothesis

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

end TestCoverage.S396

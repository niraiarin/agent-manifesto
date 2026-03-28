/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SecurityInvariant** (ord=5): セキュリティ侵害拡大防止・証拠保全・人命安全に関する絶対不変条件 [C1, C2]
- **LegalObligation** (ord=4): 個人情報漏洩報告義務・GDPR・サイバーセキュリティ基本法への準拠 [C3, C4]
- **ResponsePolicy** (ord=3): インシデント分類・エスカレーション基準・対応時間目標に関するポリシー [C5, C6, H1]
- **AutomationStrategy** (ord=2): 自動隔離・パッチ適用・復旧手順の自動化戦略 [H2, H3]
- **LearningHeuristic** (ord=1): インシデントパターン学習・脅威インテリジェンス統合・予防的対応のヒューリスティック [H4, H5]
-/

namespace TestCoverage.S495

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s495_p01
  | s495_p02
  | s495_p03
  | s495_p04
  | s495_p05
  | s495_p06
  | s495_p07
  | s495_p08
  | s495_p09
  | s495_p10
  | s495_p11
  | s495_p12
  | s495_p13
  | s495_p14
  | s495_p15
  | s495_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s495_p01 => []
  | .s495_p02 => []
  | .s495_p03 => [.s495_p01, .s495_p02]
  | .s495_p04 => [.s495_p01]
  | .s495_p05 => [.s495_p02]
  | .s495_p06 => [.s495_p03, .s495_p04]
  | .s495_p07 => [.s495_p04]
  | .s495_p08 => [.s495_p05]
  | .s495_p09 => [.s495_p06, .s495_p07]
  | .s495_p10 => [.s495_p07, .s495_p08]
  | .s495_p11 => [.s495_p07]
  | .s495_p12 => [.s495_p09]
  | .s495_p13 => [.s495_p10, .s495_p11]
  | .s495_p14 => [.s495_p11]
  | .s495_p15 => [.s495_p12]
  | .s495_p16 => [.s495_p13, .s495_p14, .s495_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- セキュリティ侵害拡大防止・証拠保全・人命安全に関する絶対不変条件 (ord=5) -/
  | SecurityInvariant
  /-- 個人情報漏洩報告義務・GDPR・サイバーセキュリティ基本法への準拠 (ord=4) -/
  | LegalObligation
  /-- インシデント分類・エスカレーション基準・対応時間目標に関するポリシー (ord=3) -/
  | ResponsePolicy
  /-- 自動隔離・パッチ適用・復旧手順の自動化戦略 (ord=2) -/
  | AutomationStrategy
  /-- インシデントパターン学習・脅威インテリジェンス統合・予防的対応のヒューリスティック (ord=1) -/
  | LearningHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SecurityInvariant => 5
  | .LegalObligation => 4
  | .ResponsePolicy => 3
  | .AutomationStrategy => 2
  | .LearningHeuristic => 1

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
  bottom := .LearningHeuristic
  nontrivial := ⟨.SecurityInvariant, .LearningHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SecurityInvariant
  | .s495_p01 | .s495_p02 | .s495_p03 => .SecurityInvariant
  -- LegalObligation
  | .s495_p04 | .s495_p05 | .s495_p06 => .LegalObligation
  -- ResponsePolicy
  | .s495_p07 | .s495_p08 | .s495_p09 | .s495_p10 => .ResponsePolicy
  -- AutomationStrategy
  | .s495_p11 | .s495_p12 | .s495_p13 => .AutomationStrategy
  -- LearningHeuristic
  | .s495_p14 | .s495_p15 | .s495_p16 => .LearningHeuristic

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

end TestCoverage.S495

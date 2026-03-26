/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **VictimProtection** (ord=4): 被害者の安全・匿名性・二次被害防止の絶対不変条件 [C1, C2]
- **LegalDutyOfCare** (ord=3): 労働安全衛生法・ハラスメント防止指針への法的義務 [C3, C4]
- **InvestigationPolicy** (ord=2): 報告受付・事実確認・処分プロセスの調査方針 [C5, C6, H1, H2]
- **PatternAnalysisHypothesis** (ord=1): 組織的ハラスメントパターン・再発予測の推論仮説 [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S368

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s368_p01
  | s368_p02
  | s368_p03
  | s368_p04
  | s368_p05
  | s368_p06
  | s368_p07
  | s368_p08
  | s368_p09
  | s368_p10
  | s368_p11
  | s368_p12
  | s368_p13
  | s368_p14
  | s368_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s368_p01 => []
  | .s368_p02 => []
  | .s368_p03 => [.s368_p01, .s368_p02]
  | .s368_p04 => [.s368_p01]
  | .s368_p05 => [.s368_p02]
  | .s368_p06 => [.s368_p04, .s368_p05]
  | .s368_p07 => [.s368_p04]
  | .s368_p08 => [.s368_p05]
  | .s368_p09 => [.s368_p03, .s368_p07]
  | .s368_p10 => [.s368_p07]
  | .s368_p11 => [.s368_p08]
  | .s368_p12 => [.s368_p09, .s368_p10]
  | .s368_p13 => [.s368_p11]
  | .s368_p14 => [.s368_p12, .s368_p13]
  | .s368_p15 => [.s368_p06, .s368_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 被害者の安全・匿名性・二次被害防止の絶対不変条件 (ord=4) -/
  | VictimProtection
  /-- 労働安全衛生法・ハラスメント防止指針への法的義務 (ord=3) -/
  | LegalDutyOfCare
  /-- 報告受付・事実確認・処分プロセスの調査方針 (ord=2) -/
  | InvestigationPolicy
  /-- 組織的ハラスメントパターン・再発予測の推論仮説 (ord=1) -/
  | PatternAnalysisHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .VictimProtection => 4
  | .LegalDutyOfCare => 3
  | .InvestigationPolicy => 2
  | .PatternAnalysisHypothesis => 1

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
  bottom := .PatternAnalysisHypothesis
  nontrivial := ⟨.VictimProtection, .PatternAnalysisHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- VictimProtection
  | .s368_p01 | .s368_p02 | .s368_p03 => .VictimProtection
  -- LegalDutyOfCare
  | .s368_p04 | .s368_p05 | .s368_p06 => .LegalDutyOfCare
  -- InvestigationPolicy
  | .s368_p07 | .s368_p08 | .s368_p09 => .InvestigationPolicy
  -- PatternAnalysisHypothesis
  | .s368_p10 | .s368_p11 | .s368_p12 | .s368_p13 | .s368_p14 | .s368_p15 => .PatternAnalysisHypothesis

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

end TestCoverage.S368

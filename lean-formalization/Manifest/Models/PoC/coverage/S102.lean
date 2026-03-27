/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **RegulatoryStandard** (ord=6): 土壌汚染対策法の基準値。法定で変更不可 [C1]
- **PublicHealthSafety** (ord=5): 住民の健康被害防止。人命に関わる不可侵制約 [C2]
- **GeochemicalEvidence** (ord=4): 地球化学的知見に基づく汚染挙動の経験則 [C3, H1]
- **SamplingProtocol** (ord=3): 調査・サンプリング手法に関する技術的手続き [C4, H2]
- **AssessmentModel** (ord=2): 汚染拡散モデル・リスク評価手法の選択 [H3, H4]
- **RemediationHypothesis** (ord=1): 浄化手法の効果に関する未検証仮説 [C5, H5, H6]
-/

namespace TestCoverage.S102

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s102_p01
  | s102_p02
  | s102_p03
  | s102_p04
  | s102_p05
  | s102_p06
  | s102_p07
  | s102_p08
  | s102_p09
  | s102_p10
  | s102_p11
  | s102_p12
  | s102_p13
  | s102_p14
  | s102_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s102_p01 => []
  | .s102_p02 => [.s102_p01]
  | .s102_p03 => [.s102_p01]
  | .s102_p04 => [.s102_p02]
  | .s102_p05 => [.s102_p01, .s102_p03]
  | .s102_p06 => [.s102_p04]
  | .s102_p07 => [.s102_p04, .s102_p05]
  | .s102_p08 => [.s102_p05]
  | .s102_p09 => [.s102_p06]
  | .s102_p10 => [.s102_p07]
  | .s102_p11 => [.s102_p06, .s102_p08]
  | .s102_p12 => [.s102_p09]
  | .s102_p13 => [.s102_p10]
  | .s102_p14 => [.s102_p11]
  | .s102_p15 => [.s102_p12, .s102_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 土壌汚染対策法の基準値。法定で変更不可 (ord=6) -/
  | RegulatoryStandard
  /-- 住民の健康被害防止。人命に関わる不可侵制約 (ord=5) -/
  | PublicHealthSafety
  /-- 地球化学的知見に基づく汚染挙動の経験則 (ord=4) -/
  | GeochemicalEvidence
  /-- 調査・サンプリング手法に関する技術的手続き (ord=3) -/
  | SamplingProtocol
  /-- 汚染拡散モデル・リスク評価手法の選択 (ord=2) -/
  | AssessmentModel
  /-- 浄化手法の効果に関する未検証仮説 (ord=1) -/
  | RemediationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .RegulatoryStandard => 6
  | .PublicHealthSafety => 5
  | .GeochemicalEvidence => 4
  | .SamplingProtocol => 3
  | .AssessmentModel => 2
  | .RemediationHypothesis => 1

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
  bottom := .RemediationHypothesis
  nontrivial := ⟨.RegulatoryStandard, .RemediationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- RegulatoryStandard
  | .s102_p01 => .RegulatoryStandard
  -- PublicHealthSafety
  | .s102_p02 | .s102_p03 => .PublicHealthSafety
  -- GeochemicalEvidence
  | .s102_p04 | .s102_p05 => .GeochemicalEvidence
  -- SamplingProtocol
  | .s102_p06 | .s102_p07 | .s102_p08 => .SamplingProtocol
  -- AssessmentModel
  | .s102_p09 | .s102_p10 | .s102_p11 => .AssessmentModel
  -- RemediationHypothesis
  | .s102_p12 | .s102_p13 | .s102_p14 | .s102_p15 => .RemediationHypothesis

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

end TestCoverage.S102

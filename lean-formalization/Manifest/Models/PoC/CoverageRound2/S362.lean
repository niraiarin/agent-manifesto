/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalObligation** (ord=5): 犯罪収益移転防止法・FATF勧告への法的義務遵守 [C1, C2]
- **RegulatoryReporting** (ord=4): 疑わしい取引報告・当局連携の規制要件 [C3]
- **DetectionPolicy** (ord=3): 異常取引パターン検出・閾値設定・アラート発報方針 [C4, C5, H1]
- **RiskScoringModel** (ord=2): 顧客リスク評価・取引リスクスコアリング方法論 [H2, H3, H4]
- **PatternHypothesis** (ord=1): 資金洗浄手法・迂回経路パターンの推論仮説 [H5, H6]
-/

namespace TestCoverage.S362

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s362_p01
  | s362_p02
  | s362_p03
  | s362_p04
  | s362_p05
  | s362_p06
  | s362_p07
  | s362_p08
  | s362_p09
  | s362_p10
  | s362_p11
  | s362_p12
  | s362_p13
  | s362_p14
  | s362_p15
  | s362_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s362_p01 => []
  | .s362_p02 => []
  | .s362_p03 => [.s362_p01, .s362_p02]
  | .s362_p04 => [.s362_p01]
  | .s362_p05 => [.s362_p03]
  | .s362_p06 => [.s362_p04]
  | .s362_p07 => [.s362_p05]
  | .s362_p08 => [.s362_p06, .s362_p07]
  | .s362_p09 => [.s362_p06]
  | .s362_p10 => [.s362_p07]
  | .s362_p11 => [.s362_p08]
  | .s362_p12 => [.s362_p09, .s362_p10]
  | .s362_p13 => [.s362_p09]
  | .s362_p14 => [.s362_p11]
  | .s362_p15 => [.s362_p12, .s362_p13]
  | .s362_p16 => [.s362_p14, .s362_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 犯罪収益移転防止法・FATF勧告への法的義務遵守 (ord=5) -/
  | LegalObligation
  /-- 疑わしい取引報告・当局連携の規制要件 (ord=4) -/
  | RegulatoryReporting
  /-- 異常取引パターン検出・閾値設定・アラート発報方針 (ord=3) -/
  | DetectionPolicy
  /-- 顧客リスク評価・取引リスクスコアリング方法論 (ord=2) -/
  | RiskScoringModel
  /-- 資金洗浄手法・迂回経路パターンの推論仮説 (ord=1) -/
  | PatternHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalObligation => 5
  | .RegulatoryReporting => 4
  | .DetectionPolicy => 3
  | .RiskScoringModel => 2
  | .PatternHypothesis => 1

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
  bottom := .PatternHypothesis
  nontrivial := ⟨.LegalObligation, .PatternHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalObligation
  | .s362_p01 | .s362_p02 | .s362_p03 => .LegalObligation
  -- RegulatoryReporting
  | .s362_p04 | .s362_p05 => .RegulatoryReporting
  -- DetectionPolicy
  | .s362_p06 | .s362_p07 | .s362_p08 => .DetectionPolicy
  -- RiskScoringModel
  | .s362_p09 | .s362_p10 | .s362_p11 | .s362_p12 => .RiskScoringModel
  -- PatternHypothesis
  | .s362_p13 | .s362_p14 | .s362_p15 | .s362_p16 => .PatternHypothesis

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

end TestCoverage.S362

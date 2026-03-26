/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EmployeePrivacyInvariant** (ord=6): 個人情報・プライバシー保護の絶対不変条件（GDPR準拠） [C1]
- **LaborLawCompliance** (ord=5): 労働基準法・時間外上限規制・割増賃金計算の適合要件 [C2, C3]
- **FraudDetectionPolicy** (ord=4): 打刻不正・代理打刻・タイムカード改竄検知の方針 [C4]
- **AttendancePatternPolicy** (ord=3): 欠勤パターン・遅刻頻度・残業偏在の管理方針 [H1, H2]
- **BehaviorAnalysisModel** (ord=2): 位置情報・入退室ログ・PC操作ログの行動分析モデル [C5, H3, H4]
- **AnomalyScoreHypothesis** (ord=1): 個人ベースライン・季節性・勤務形態を加味した異常スコア仮説 [H5, H6]
-/

namespace TestCoverage.S378

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s378_p01
  | s378_p02
  | s378_p03
  | s378_p04
  | s378_p05
  | s378_p06
  | s378_p07
  | s378_p08
  | s378_p09
  | s378_p10
  | s378_p11
  | s378_p12
  | s378_p13
  | s378_p14
  | s378_p15
  | s378_p16
  | s378_p17
  | s378_p18
  | s378_p19
  | s378_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s378_p01 => []
  | .s378_p02 => [.s378_p01]
  | .s378_p03 => [.s378_p01]
  | .s378_p04 => [.s378_p02, .s378_p03]
  | .s378_p05 => [.s378_p02]
  | .s378_p06 => [.s378_p04]
  | .s378_p07 => [.s378_p05]
  | .s378_p08 => [.s378_p06]
  | .s378_p09 => [.s378_p07, .s378_p08]
  | .s378_p10 => [.s378_p07]
  | .s378_p11 => [.s378_p08]
  | .s378_p12 => [.s378_p09, .s378_p10]
  | .s378_p13 => [.s378_p10, .s378_p11]
  | .s378_p14 => [.s378_p11, .s378_p12]
  | .s378_p15 => [.s378_p10]
  | .s378_p16 => [.s378_p11]
  | .s378_p17 => [.s378_p12, .s378_p15]
  | .s378_p18 => [.s378_p13, .s378_p16]
  | .s378_p19 => [.s378_p14, .s378_p17]
  | .s378_p20 => [.s378_p18, .s378_p19]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 個人情報・プライバシー保護の絶対不変条件（GDPR準拠） (ord=6) -/
  | EmployeePrivacyInvariant
  /-- 労働基準法・時間外上限規制・割増賃金計算の適合要件 (ord=5) -/
  | LaborLawCompliance
  /-- 打刻不正・代理打刻・タイムカード改竄検知の方針 (ord=4) -/
  | FraudDetectionPolicy
  /-- 欠勤パターン・遅刻頻度・残業偏在の管理方針 (ord=3) -/
  | AttendancePatternPolicy
  /-- 位置情報・入退室ログ・PC操作ログの行動分析モデル (ord=2) -/
  | BehaviorAnalysisModel
  /-- 個人ベースライン・季節性・勤務形態を加味した異常スコア仮説 (ord=1) -/
  | AnomalyScoreHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EmployeePrivacyInvariant => 6
  | .LaborLawCompliance => 5
  | .FraudDetectionPolicy => 4
  | .AttendancePatternPolicy => 3
  | .BehaviorAnalysisModel => 2
  | .AnomalyScoreHypothesis => 1

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
  bottom := .AnomalyScoreHypothesis
  nontrivial := ⟨.EmployeePrivacyInvariant, .AnomalyScoreHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EmployeePrivacyInvariant
  | .s378_p01 => .EmployeePrivacyInvariant
  -- LaborLawCompliance
  | .s378_p02 | .s378_p03 | .s378_p04 => .LaborLawCompliance
  -- FraudDetectionPolicy
  | .s378_p05 | .s378_p06 => .FraudDetectionPolicy
  -- AttendancePatternPolicy
  | .s378_p07 | .s378_p08 | .s378_p09 => .AttendancePatternPolicy
  -- BehaviorAnalysisModel
  | .s378_p10 | .s378_p11 | .s378_p12 | .s378_p13 | .s378_p14 => .BehaviorAnalysisModel
  -- AnomalyScoreHypothesis
  | .s378_p15 | .s378_p16 | .s378_p17 | .s378_p18 | .s378_p19 | .s378_p20 => .AnomalyScoreHypothesis

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

end TestCoverage.S378

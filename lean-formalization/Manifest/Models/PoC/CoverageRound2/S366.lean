/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ConstitutionalEquality** (ord=6): 憲法・教育基本法に基づく平等権・差別禁止の絶対的不変条件 [C1]
- **AdmissionLegality** (ord=5): 入試選抜の法的根拠・個人情報保護・透明性要件 [C2, C3]
- **FairnessStandard** (ord=4): 評価基準の統一性・採点者間信頼性・測定不変性の基準 [C4, C5]
- **BiasDetectionPolicy** (ord=3): 統計的バイアス検出・属性別格差分析の監査方針 [C6, H1, H2]
- **RemediationModel** (ord=2): バイアス是正・選抜プロセス改善の修正モデル [H3, H4]
- **PredictiveHypothesis** (ord=1): 将来的公平性確保・属性相関消去に関する推論仮説 [H5, H6]
-/

namespace TestCoverage.S366

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s366_p01
  | s366_p02
  | s366_p03
  | s366_p04
  | s366_p05
  | s366_p06
  | s366_p07
  | s366_p08
  | s366_p09
  | s366_p10
  | s366_p11
  | s366_p12
  | s366_p13
  | s366_p14
  | s366_p15
  | s366_p16
  | s366_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s366_p01 => []
  | .s366_p02 => [.s366_p01]
  | .s366_p03 => [.s366_p01]
  | .s366_p04 => [.s366_p02]
  | .s366_p05 => [.s366_p03]
  | .s366_p06 => [.s366_p04, .s366_p05]
  | .s366_p07 => [.s366_p04]
  | .s366_p08 => [.s366_p05]
  | .s366_p09 => [.s366_p06, .s366_p07]
  | .s366_p10 => [.s366_p07]
  | .s366_p11 => [.s366_p08]
  | .s366_p12 => [.s366_p09, .s366_p10]
  | .s366_p13 => [.s366_p10]
  | .s366_p14 => [.s366_p11]
  | .s366_p15 => [.s366_p12, .s366_p13]
  | .s366_p16 => [.s366_p14, .s366_p15]
  | .s366_p17 => [.s366_p01, .s366_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 憲法・教育基本法に基づく平等権・差別禁止の絶対的不変条件 (ord=6) -/
  | ConstitutionalEquality
  /-- 入試選抜の法的根拠・個人情報保護・透明性要件 (ord=5) -/
  | AdmissionLegality
  /-- 評価基準の統一性・採点者間信頼性・測定不変性の基準 (ord=4) -/
  | FairnessStandard
  /-- 統計的バイアス検出・属性別格差分析の監査方針 (ord=3) -/
  | BiasDetectionPolicy
  /-- バイアス是正・選抜プロセス改善の修正モデル (ord=2) -/
  | RemediationModel
  /-- 将来的公平性確保・属性相関消去に関する推論仮説 (ord=1) -/
  | PredictiveHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ConstitutionalEquality => 6
  | .AdmissionLegality => 5
  | .FairnessStandard => 4
  | .BiasDetectionPolicy => 3
  | .RemediationModel => 2
  | .PredictiveHypothesis => 1

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
  bottom := .PredictiveHypothesis
  nontrivial := ⟨.ConstitutionalEquality, .PredictiveHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ConstitutionalEquality
  | .s366_p01 => .ConstitutionalEquality
  -- AdmissionLegality
  | .s366_p02 | .s366_p03 => .AdmissionLegality
  -- FairnessStandard
  | .s366_p04 | .s366_p05 | .s366_p06 => .FairnessStandard
  -- BiasDetectionPolicy
  | .s366_p07 | .s366_p08 | .s366_p09 => .BiasDetectionPolicy
  -- RemediationModel
  | .s366_p10 | .s366_p11 | .s366_p12 => .RemediationModel
  -- PredictiveHypothesis
  | .s366_p13 | .s366_p14 | .s366_p15 | .s366_p16 | .s366_p17 => .PredictiveHypothesis

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

end TestCoverage.S366

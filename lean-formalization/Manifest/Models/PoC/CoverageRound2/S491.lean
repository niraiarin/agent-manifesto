/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafetyInvariant** (ord=4): 患者への誤診・見逃しを防ぐ絶対不変条件。臨床的安全性を最優先とする [C1, C2]
- **RegulatoryCompliance** (ord=3): 体外診断薬法・ISO 15189・厚生労働省ガイドラインへの準拠要件 [C3, C4]
- **AnalysisPolicy** (ord=2): 検査項目の自動解釈・アラート閾値・レポート生成に関する運用ポリシー [C5, H1, H2]
- **ModelHypothesis** (ord=1): 機械学習モデルの精度・汎化性能・ドリフト検出に関する推論仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S491

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s491_p01
  | s491_p02
  | s491_p03
  | s491_p04
  | s491_p05
  | s491_p06
  | s491_p07
  | s491_p08
  | s491_p09
  | s491_p10
  | s491_p11
  | s491_p12
  | s491_p13
  | s491_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s491_p01 => []
  | .s491_p02 => []
  | .s491_p03 => [.s491_p01, .s491_p02]
  | .s491_p04 => [.s491_p01]
  | .s491_p05 => [.s491_p02]
  | .s491_p06 => [.s491_p04, .s491_p05]
  | .s491_p07 => [.s491_p04]
  | .s491_p08 => [.s491_p05]
  | .s491_p09 => [.s491_p06, .s491_p07]
  | .s491_p10 => [.s491_p07]
  | .s491_p11 => [.s491_p08]
  | .s491_p12 => [.s491_p09, .s491_p10]
  | .s491_p13 => [.s491_p10, .s491_p11]
  | .s491_p14 => [.s491_p12, .s491_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者への誤診・見逃しを防ぐ絶対不変条件。臨床的安全性を最優先とする (ord=4) -/
  | PatientSafetyInvariant
  /-- 体外診断薬法・ISO 15189・厚生労働省ガイドラインへの準拠要件 (ord=3) -/
  | RegulatoryCompliance
  /-- 検査項目の自動解釈・アラート閾値・レポート生成に関する運用ポリシー (ord=2) -/
  | AnalysisPolicy
  /-- 機械学習モデルの精度・汎化性能・ドリフト検出に関する推論仮説 (ord=1) -/
  | ModelHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafetyInvariant => 4
  | .RegulatoryCompliance => 3
  | .AnalysisPolicy => 2
  | .ModelHypothesis => 1

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
  bottom := .ModelHypothesis
  nontrivial := ⟨.PatientSafetyInvariant, .ModelHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PatientSafetyInvariant
  | .s491_p01 | .s491_p02 | .s491_p03 => .PatientSafetyInvariant
  -- RegulatoryCompliance
  | .s491_p04 | .s491_p05 | .s491_p06 => .RegulatoryCompliance
  -- AnalysisPolicy
  | .s491_p07 | .s491_p08 | .s491_p09 => .AnalysisPolicy
  -- ModelHypothesis
  | .s491_p10 | .s491_p11 | .s491_p12 | .s491_p13 | .s491_p14 => .ModelHypothesis

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

end TestCoverage.S491

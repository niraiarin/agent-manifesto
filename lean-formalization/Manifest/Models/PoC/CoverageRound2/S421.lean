/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **MaternalSafety** (ord=4): 母体・胎児の生命安全に関わる絶対不変条件。バイタル閾値超過時の即時介入義務 [C1, C2]
- **ClinicalProtocol** (ord=3): 産科医療ガイドライン・個人情報保護法・医療機器規制への準拠要件 [C3, C4]
- **MonitoringPolicy** (ord=2): 計測頻度・アラート基準・遠隔相談トリガーに関する運用方針 [C5, H1, H2]
- **RiskPrediction** (ord=1): 早産リスク・妊娠高血圧症候群発症確率に関する予測仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S421

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s421_p01
  | s421_p02
  | s421_p03
  | s421_p04
  | s421_p05
  | s421_p06
  | s421_p07
  | s421_p08
  | s421_p09
  | s421_p10
  | s421_p11
  | s421_p12
  | s421_p13
  | s421_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s421_p01 => []
  | .s421_p02 => []
  | .s421_p03 => [.s421_p01, .s421_p02]
  | .s421_p04 => [.s421_p01]
  | .s421_p05 => [.s421_p02]
  | .s421_p06 => [.s421_p04, .s421_p05]
  | .s421_p07 => [.s421_p04]
  | .s421_p08 => [.s421_p05]
  | .s421_p09 => [.s421_p07, .s421_p08]
  | .s421_p10 => [.s421_p07]
  | .s421_p11 => [.s421_p08]
  | .s421_p12 => [.s421_p10]
  | .s421_p13 => [.s421_p11]
  | .s421_p14 => [.s421_p12, .s421_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 母体・胎児の生命安全に関わる絶対不変条件。バイタル閾値超過時の即時介入義務 (ord=4) -/
  | MaternalSafety
  /-- 産科医療ガイドライン・個人情報保護法・医療機器規制への準拠要件 (ord=3) -/
  | ClinicalProtocol
  /-- 計測頻度・アラート基準・遠隔相談トリガーに関する運用方針 (ord=2) -/
  | MonitoringPolicy
  /-- 早産リスク・妊娠高血圧症候群発症確率に関する予測仮説 (ord=1) -/
  | RiskPrediction
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .MaternalSafety => 4
  | .ClinicalProtocol => 3
  | .MonitoringPolicy => 2
  | .RiskPrediction => 1

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
  bottom := .RiskPrediction
  nontrivial := ⟨.MaternalSafety, .RiskPrediction, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- MaternalSafety
  | .s421_p01 | .s421_p02 | .s421_p03 => .MaternalSafety
  -- ClinicalProtocol
  | .s421_p04 | .s421_p05 | .s421_p06 => .ClinicalProtocol
  -- MonitoringPolicy
  | .s421_p07 | .s421_p08 | .s421_p09 => .MonitoringPolicy
  -- RiskPrediction
  | .s421_p10 | .s421_p11 | .s421_p12 | .s421_p13 | .s421_p14 => .RiskPrediction

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

end TestCoverage.S421

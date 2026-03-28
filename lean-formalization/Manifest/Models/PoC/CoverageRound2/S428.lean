/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ServiceAvailability** (ord=4): SLA99.99%維持・重要インフラ通信断絶防止に関する絶対可用性要件 [C1, C2]
- **IncidentResponse** (ord=3): 障害検知後のエスカレーション・自動回復・影響範囲通知に関する対応要件 [C3, C4]
- **MonitoringPolicy** (ord=2): メトリクス収集間隔・異常検知感度・相関分析ウィンドウに関する監視方針 [C5, H1, H2, H3]
- **FailurePredHypothesis** (ord=1): 障害伝播モデル・機器寿命分布・トラフィックパターン異常に関する予測仮説 [H4, H5, H6, H7]
-/

namespace TestCoverage.S428

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s428_p01
  | s428_p02
  | s428_p03
  | s428_p04
  | s428_p05
  | s428_p06
  | s428_p07
  | s428_p08
  | s428_p09
  | s428_p10
  | s428_p11
  | s428_p12
  | s428_p13
  | s428_p14
  | s428_p15
  | s428_p16
  | s428_p17
  | s428_p18
  | s428_p19
  | s428_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s428_p01 => []
  | .s428_p02 => []
  | .s428_p03 => [.s428_p01, .s428_p02]
  | .s428_p04 => [.s428_p01]
  | .s428_p05 => [.s428_p02]
  | .s428_p06 => [.s428_p04, .s428_p05]
  | .s428_p07 => [.s428_p04]
  | .s428_p08 => [.s428_p05]
  | .s428_p09 => [.s428_p07]
  | .s428_p10 => [.s428_p08, .s428_p09]
  | .s428_p11 => [.s428_p07]
  | .s428_p12 => [.s428_p08]
  | .s428_p13 => [.s428_p11]
  | .s428_p14 => [.s428_p12]
  | .s428_p15 => [.s428_p13]
  | .s428_p16 => [.s428_p14]
  | .s428_p17 => [.s428_p15]
  | .s428_p18 => [.s428_p16]
  | .s428_p19 => [.s428_p17]
  | .s428_p20 => [.s428_p18, .s428_p19]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- SLA99.99%維持・重要インフラ通信断絶防止に関する絶対可用性要件 (ord=4) -/
  | ServiceAvailability
  /-- 障害検知後のエスカレーション・自動回復・影響範囲通知に関する対応要件 (ord=3) -/
  | IncidentResponse
  /-- メトリクス収集間隔・異常検知感度・相関分析ウィンドウに関する監視方針 (ord=2) -/
  | MonitoringPolicy
  /-- 障害伝播モデル・機器寿命分布・トラフィックパターン異常に関する予測仮説 (ord=1) -/
  | FailurePredHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ServiceAvailability => 4
  | .IncidentResponse => 3
  | .MonitoringPolicy => 2
  | .FailurePredHypothesis => 1

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
  bottom := .FailurePredHypothesis
  nontrivial := ⟨.ServiceAvailability, .FailurePredHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ServiceAvailability
  | .s428_p01 | .s428_p02 | .s428_p03 => .ServiceAvailability
  -- IncidentResponse
  | .s428_p04 | .s428_p05 | .s428_p06 => .IncidentResponse
  -- MonitoringPolicy
  | .s428_p07 | .s428_p08 | .s428_p09 | .s428_p10 => .MonitoringPolicy
  -- FailurePredHypothesis
  | .s428_p11 | .s428_p12 | .s428_p13 | .s428_p14 | .s428_p15 | .s428_p16 | .s428_p17 | .s428_p18 | .s428_p19 | .s428_p20 => .FailurePredHypothesis

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

end TestCoverage.S428

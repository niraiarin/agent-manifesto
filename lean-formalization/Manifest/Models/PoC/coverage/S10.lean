/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **WorkerSafety** (ord=7): 作業員の生命・身体の安全。労安法の最上位義務 [C1]
- **LegalCompliance** (ord=6): 労働安全衛生法・建設業法の遵守 [C2, H1]
- **SiteProtocol** (ord=5): 現場固有の安全手順・作業標準 [C3, H2]
- **HazardDetection** (ord=4): 危険検知アルゴリズムのパラメータ [H3, H4]
- **EquipmentMonitoring** (ord=3): 重機・設備の稼働状態監視ルール [C4, H5]
- **WorkflowScheduling** (ord=2): 作業スケジュール・動線管理の最適化 [H6, H7]
- **ReportingFormat** (ord=1): 報告書・ダッシュボードの表示形式 [C5, H8]
-/

namespace TestCoverage.S10

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s10_p01
  | s10_p02
  | s10_p03
  | s10_p04
  | s10_p05
  | s10_p06
  | s10_p07
  | s10_p08
  | s10_p09
  | s10_p10
  | s10_p11
  | s10_p12
  | s10_p13
  | s10_p14
  | s10_p15
  | s10_p16
  | s10_p17
  | s10_p18
  | s10_p19
  | s10_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s10_p01 => []
  | .s10_p02 => []
  | .s10_p03 => [.s10_p01]
  | .s10_p04 => [.s10_p02]
  | .s10_p05 => [.s10_p03]
  | .s10_p06 => [.s10_p04]
  | .s10_p07 => [.s10_p03, .s10_p04]
  | .s10_p08 => [.s10_p05]
  | .s10_p09 => [.s10_p06]
  | .s10_p10 => [.s10_p05, .s10_p07]
  | .s10_p11 => [.s10_p08]
  | .s10_p12 => [.s10_p09]
  | .s10_p13 => [.s10_p08, .s10_p10]
  | .s10_p14 => [.s10_p11]
  | .s10_p15 => [.s10_p12]
  | .s10_p16 => [.s10_p11, .s10_p13]
  | .s10_p17 => [.s10_p14]
  | .s10_p18 => [.s10_p15]
  | .s10_p19 => [.s10_p16]
  | .s10_p20 => [.s10_p17, .s10_p18]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 作業員の生命・身体の安全。労安法の最上位義務 (ord=7) -/
  | WorkerSafety
  /-- 労働安全衛生法・建設業法の遵守 (ord=6) -/
  | LegalCompliance
  /-- 現場固有の安全手順・作業標準 (ord=5) -/
  | SiteProtocol
  /-- 危険検知アルゴリズムのパラメータ (ord=4) -/
  | HazardDetection
  /-- 重機・設備の稼働状態監視ルール (ord=3) -/
  | EquipmentMonitoring
  /-- 作業スケジュール・動線管理の最適化 (ord=2) -/
  | WorkflowScheduling
  /-- 報告書・ダッシュボードの表示形式 (ord=1) -/
  | ReportingFormat
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .WorkerSafety => 7
  | .LegalCompliance => 6
  | .SiteProtocol => 5
  | .HazardDetection => 4
  | .EquipmentMonitoring => 3
  | .WorkflowScheduling => 2
  | .ReportingFormat => 1

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
  bottom := .ReportingFormat
  nontrivial := ⟨.WorkerSafety, .ReportingFormat, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨7, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- WorkerSafety
  | .s10_p01 | .s10_p02 => .WorkerSafety
  -- LegalCompliance
  | .s10_p03 | .s10_p04 => .LegalCompliance
  -- SiteProtocol
  | .s10_p05 | .s10_p06 | .s10_p07 => .SiteProtocol
  -- HazardDetection
  | .s10_p08 | .s10_p09 | .s10_p10 => .HazardDetection
  -- EquipmentMonitoring
  | .s10_p11 | .s10_p12 | .s10_p13 => .EquipmentMonitoring
  -- WorkflowScheduling
  | .s10_p14 | .s10_p15 | .s10_p16 => .WorkflowScheduling
  -- ReportingFormat
  | .s10_p17 | .s10_p18 | .s10_p19 | .s10_p20 => .ReportingFormat

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

end TestCoverage.S10

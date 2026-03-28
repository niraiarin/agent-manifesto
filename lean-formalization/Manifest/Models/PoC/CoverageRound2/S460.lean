/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafetySupplyInvariant** (ord=4): 医薬品・医療機器の欠品・誤配送による患者危害防止の絶対制約 [C1, C2]
- **RegulatoryStorageCompliance** (ord=3): 薬機法・GMP・冷鎖管理に基づく医薬品保管・搬送の法的遵守要件 [C3, H1]
- **InventoryAllocationPolicy** (ord=2): 病棟別在庫配分・緊急補充・期限管理・無駄削減の運用方針 [C4, H2, H3, H4]
- **DemandPredictionHypothesis** (ord=1): 手術スケジュール・季節疾患・入院患者数変動による需要予測仮説 [C5, H5, H6]
-/

namespace TestCoverage.S460

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s460_p01
  | s460_p02
  | s460_p03
  | s460_p04
  | s460_p05
  | s460_p06
  | s460_p07
  | s460_p08
  | s460_p09
  | s460_p10
  | s460_p11
  | s460_p12
  | s460_p13
  | s460_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s460_p01 => []
  | .s460_p02 => []
  | .s460_p03 => [.s460_p01]
  | .s460_p04 => [.s460_p01, .s460_p02]
  | .s460_p05 => [.s460_p03, .s460_p04]
  | .s460_p06 => [.s460_p03]
  | .s460_p07 => [.s460_p04]
  | .s460_p08 => [.s460_p05, .s460_p06]
  | .s460_p09 => [.s460_p07, .s460_p08]
  | .s460_p10 => [.s460_p06]
  | .s460_p11 => [.s460_p07, .s460_p09]
  | .s460_p12 => [.s460_p10, .s460_p11]
  | .s460_p13 => [.s460_p11, .s460_p12]
  | .s460_p14 => [.s460_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医薬品・医療機器の欠品・誤配送による患者危害防止の絶対制約 (ord=4) -/
  | PatientSafetySupplyInvariant
  /-- 薬機法・GMP・冷鎖管理に基づく医薬品保管・搬送の法的遵守要件 (ord=3) -/
  | RegulatoryStorageCompliance
  /-- 病棟別在庫配分・緊急補充・期限管理・無駄削減の運用方針 (ord=2) -/
  | InventoryAllocationPolicy
  /-- 手術スケジュール・季節疾患・入院患者数変動による需要予測仮説 (ord=1) -/
  | DemandPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafetySupplyInvariant => 4
  | .RegulatoryStorageCompliance => 3
  | .InventoryAllocationPolicy => 2
  | .DemandPredictionHypothesis => 1

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
  bottom := .DemandPredictionHypothesis
  nontrivial := ⟨.PatientSafetySupplyInvariant, .DemandPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PatientSafetySupplyInvariant
  | .s460_p01 | .s460_p02 => .PatientSafetySupplyInvariant
  -- RegulatoryStorageCompliance
  | .s460_p03 | .s460_p04 | .s460_p05 => .RegulatoryStorageCompliance
  -- InventoryAllocationPolicy
  | .s460_p06 | .s460_p07 | .s460_p08 | .s460_p09 => .InventoryAllocationPolicy
  -- DemandPredictionHypothesis
  | .s460_p10 | .s460_p11 | .s460_p12 | .s460_p13 | .s460_p14 => .DemandPredictionHypothesis

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

end TestCoverage.S460

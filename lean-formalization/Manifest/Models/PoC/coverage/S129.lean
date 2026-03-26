/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **StructuralSafety** (ord=4): 構造力学的安全基準。橋梁の健全性に直結する不可侵制約 [C1, C2]
- **InspectionStandard** (ord=3): 点検基準・規格。国土交通省の定期点検要領に基づく [C3, C4]
- **MonitoringDesign** (ord=2): モニタリングシステムの設計選択 [C5, H1, H2]
- **AnalysisMethod** (ord=1): 振動解析手法の技術選択。精度と実装の難易度 [C6, H3, H4]
- **DeteriorationModel** (ord=0): 劣化予測モデルの仮説。長期データで検証が必要 [H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s129_p01
  | s129_p02
  | s129_p03
  | s129_p04
  | s129_p05
  | s129_p06
  | s129_p07
  | s129_p08
  | s129_p09
  | s129_p10
  | s129_p11
  | s129_p12
  | s129_p13
  | s129_p14
  | s129_p15
  | s129_p16
  | s129_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s129_p01 => []
  | .s129_p02 => []
  | .s129_p03 => []
  | .s129_p04 => [.s129_p01]
  | .s129_p05 => [.s129_p01, .s129_p02]
  | .s129_p06 => [.s129_p03]
  | .s129_p07 => [.s129_p04]
  | .s129_p08 => [.s129_p05]
  | .s129_p09 => [.s129_p04, .s129_p06]
  | .s129_p10 => [.s129_p07]
  | .s129_p11 => [.s129_p08]
  | .s129_p12 => [.s129_p07, .s129_p09]
  | .s129_p13 => [.s129_p10]
  | .s129_p14 => [.s129_p11]
  | .s129_p15 => [.s129_p12, .s129_p13]
  | .s129_p16 => [.s129_p09]
  | .s129_p17 => [.s129_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 構造力学的安全基準。橋梁の健全性に直結する不可侵制約 (ord=4) -/
  | StructuralSafety
  /-- 点検基準・規格。国土交通省の定期点検要領に基づく (ord=3) -/
  | InspectionStandard
  /-- モニタリングシステムの設計選択 (ord=2) -/
  | MonitoringDesign
  /-- 振動解析手法の技術選択。精度と実装の難易度 (ord=1) -/
  | AnalysisMethod
  /-- 劣化予測モデルの仮説。長期データで検証が必要 (ord=0) -/
  | DeteriorationModel
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .StructuralSafety => 4
  | .InspectionStandard => 3
  | .MonitoringDesign => 2
  | .AnalysisMethod => 1
  | .DeteriorationModel => 0

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
  bottom := .DeteriorationModel
  nontrivial := ⟨.StructuralSafety, .DeteriorationModel, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- StructuralSafety
  | .s129_p01 | .s129_p02 | .s129_p03 => .StructuralSafety
  -- InspectionStandard
  | .s129_p04 | .s129_p05 | .s129_p06 => .InspectionStandard
  -- MonitoringDesign
  | .s129_p07 | .s129_p08 | .s129_p09 => .MonitoringDesign
  -- AnalysisMethod
  | .s129_p10 | .s129_p11 | .s129_p12 | .s129_p16 => .AnalysisMethod
  -- DeteriorationModel
  | .s129_p13 | .s129_p14 | .s129_p15 | .s129_p17 => .DeteriorationModel

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

end Manifest.Models

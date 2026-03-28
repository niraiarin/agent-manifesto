/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalComplianceAbsolute** (ord=4): 特許法・PCT条約・各国知的財産権法への絶対準拠制約 [C1, C2]
- **PriorArtStandard** (ord=3): 先行技術調査・新規性・進歩性判断の客観的基準への適合 [C3, C4]
- **DraftingStrategy** (ord=2): クレーム作成・明細書構成・図面連携に関する出願戦略方針 [C5, H1, H2, H3]
- **StrategicOptimization** (ord=1): 権利範囲最大化・審査官対応・分割出願タイミングに関する戦略仮説 [H4, H5, H6]
-/

namespace TestCoverage.S418

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s418_p01
  | s418_p02
  | s418_p03
  | s418_p04
  | s418_p05
  | s418_p06
  | s418_p07
  | s418_p08
  | s418_p09
  | s418_p10
  | s418_p11
  | s418_p12
  | s418_p13
  | s418_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s418_p01 => []
  | .s418_p02 => []
  | .s418_p03 => [.s418_p01, .s418_p02]
  | .s418_p04 => [.s418_p01]
  | .s418_p05 => [.s418_p02]
  | .s418_p06 => [.s418_p03, .s418_p04, .s418_p05]
  | .s418_p07 => [.s418_p04]
  | .s418_p08 => [.s418_p05, .s418_p06]
  | .s418_p09 => [.s418_p07, .s418_p08]
  | .s418_p10 => [.s418_p07]
  | .s418_p11 => [.s418_p08]
  | .s418_p12 => [.s418_p09]
  | .s418_p13 => [.s418_p10, .s418_p11]
  | .s418_p14 => [.s418_p12, .s418_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 特許法・PCT条約・各国知的財産権法への絶対準拠制約 (ord=4) -/
  | LegalComplianceAbsolute
  /-- 先行技術調査・新規性・進歩性判断の客観的基準への適合 (ord=3) -/
  | PriorArtStandard
  /-- クレーム作成・明細書構成・図面連携に関する出願戦略方針 (ord=2) -/
  | DraftingStrategy
  /-- 権利範囲最大化・審査官対応・分割出願タイミングに関する戦略仮説 (ord=1) -/
  | StrategicOptimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalComplianceAbsolute => 4
  | .PriorArtStandard => 3
  | .DraftingStrategy => 2
  | .StrategicOptimization => 1

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
  bottom := .StrategicOptimization
  nontrivial := ⟨.LegalComplianceAbsolute, .StrategicOptimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalComplianceAbsolute
  | .s418_p01 | .s418_p02 | .s418_p03 => .LegalComplianceAbsolute
  -- PriorArtStandard
  | .s418_p04 | .s418_p05 | .s418_p06 => .PriorArtStandard
  -- DraftingStrategy
  | .s418_p07 | .s418_p08 | .s418_p09 => .DraftingStrategy
  -- StrategicOptimization
  | .s418_p10 | .s418_p11 | .s418_p12 | .s418_p13 | .s418_p14 => .StrategicOptimization

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

end TestCoverage.S418

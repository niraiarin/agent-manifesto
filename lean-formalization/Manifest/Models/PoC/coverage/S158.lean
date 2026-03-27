/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **StandardCompliance** (ord=5): JIS・ISO試験規格への準拠。認証に必須 [C1]
- **MaterialScience** (ord=4): 材料力学の理論的制約。破壊力学・疲労理論 [C2, H1]
- **TestProtocol** (ord=3): 試験手順・条件設定の設計方針 [C3, C4, H2]
- **DataAnalysis** (ord=2): 試験データの統計解析・異常検出手法 [H3, H4]
- **ReportGeneration** (ord=1): 試験レポートの出力形式と可視化 [C5, H5, H6]
-/

namespace TestCoverage.S158

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s158_p01
  | s158_p02
  | s158_p03
  | s158_p04
  | s158_p05
  | s158_p06
  | s158_p07
  | s158_p08
  | s158_p09
  | s158_p10
  | s158_p11
  | s158_p12
  | s158_p13
  | s158_p14
  | s158_p15
  | s158_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s158_p01 => []
  | .s158_p02 => []
  | .s158_p03 => [.s158_p01]
  | .s158_p04 => [.s158_p01]
  | .s158_p05 => [.s158_p01, .s158_p02]
  | .s158_p06 => [.s158_p03]
  | .s158_p07 => [.s158_p04]
  | .s158_p08 => [.s158_p03, .s158_p05]
  | .s158_p09 => [.s158_p06]
  | .s158_p10 => [.s158_p07, .s158_p08]
  | .s158_p11 => [.s158_p06]
  | .s158_p12 => [.s158_p09]
  | .s158_p13 => [.s158_p10]
  | .s158_p14 => [.s158_p11]
  | .s158_p15 => [.s158_p12, .s158_p13]
  | .s158_p16 => [.s158_p14, .s158_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- JIS・ISO試験規格への準拠。認証に必須 (ord=5) -/
  | StandardCompliance
  /-- 材料力学の理論的制約。破壊力学・疲労理論 (ord=4) -/
  | MaterialScience
  /-- 試験手順・条件設定の設計方針 (ord=3) -/
  | TestProtocol
  /-- 試験データの統計解析・異常検出手法 (ord=2) -/
  | DataAnalysis
  /-- 試験レポートの出力形式と可視化 (ord=1) -/
  | ReportGeneration
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .StandardCompliance => 5
  | .MaterialScience => 4
  | .TestProtocol => 3
  | .DataAnalysis => 2
  | .ReportGeneration => 1

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
  bottom := .ReportGeneration
  nontrivial := ⟨.StandardCompliance, .ReportGeneration, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- StandardCompliance
  | .s158_p01 | .s158_p02 => .StandardCompliance
  -- MaterialScience
  | .s158_p03 | .s158_p04 | .s158_p05 => .MaterialScience
  -- TestProtocol
  | .s158_p06 | .s158_p07 | .s158_p08 => .TestProtocol
  -- DataAnalysis
  | .s158_p09 | .s158_p10 | .s158_p11 => .DataAnalysis
  -- ReportGeneration
  | .s158_p12 | .s158_p13 | .s158_p14 | .s158_p15 | .s158_p16 => .ReportGeneration

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

end TestCoverage.S158

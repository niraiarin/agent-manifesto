/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **NumismaticAuthority** (ord=3): 貨幣学・考古学に基づく鑑定基準。専門家の合意に基づく [C1, C2]
- **ImageAnalysisDesign** (ord=2): 画像認識・分類モデルの設計選択 [C3, H1, H2]
- **MarketHypothesis** (ord=1): 市場価値・希少性に関する未検証の仮説 [C4, H3, H4]
-/

namespace TestCoverage.S176

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s176_p01
  | s176_p02
  | s176_p03
  | s176_p04
  | s176_p05
  | s176_p06
  | s176_p07
  | s176_p08
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s176_p01 => []
  | .s176_p02 => []
  | .s176_p03 => [.s176_p01]
  | .s176_p04 => [.s176_p01, .s176_p02]
  | .s176_p05 => [.s176_p02]
  | .s176_p06 => [.s176_p03]
  | .s176_p07 => [.s176_p04]
  | .s176_p08 => [.s176_p03, .s176_p05]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 貨幣学・考古学に基づく鑑定基準。専門家の合意に基づく (ord=3) -/
  | NumismaticAuthority
  /-- 画像認識・分類モデルの設計選択 (ord=2) -/
  | ImageAnalysisDesign
  /-- 市場価値・希少性に関する未検証の仮説 (ord=1) -/
  | MarketHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .NumismaticAuthority => 3
  | .ImageAnalysisDesign => 2
  | .MarketHypothesis => 1

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
  bottom := .MarketHypothesis
  nontrivial := ⟨.NumismaticAuthority, .MarketHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- NumismaticAuthority
  | .s176_p01 | .s176_p02 => .NumismaticAuthority
  -- ImageAnalysisDesign
  | .s176_p03 | .s176_p04 | .s176_p05 => .ImageAnalysisDesign
  -- MarketHypothesis
  | .s176_p06 | .s176_p07 | .s176_p08 => .MarketHypothesis

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

end TestCoverage.S176

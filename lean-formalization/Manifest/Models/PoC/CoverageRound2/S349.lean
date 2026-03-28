/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FairnessInvariant** (ord=4): 地域属性・人種的背景に基づく差別的評価禁止の絶対不変条件 [C1]
- **RegulatoryCompliance** (ord=3): 宅地建物取引業法・個人情報保護法・公正住宅法への適合 [C2, C3]
- **ValuationPolicy** (ord=2): 価格帯定義・不確実性開示・更新頻度の評価方針 [C4, C5, H1, H2]
- **MarketHypothesis** (ord=1): 地価変動・需給バランス・周辺施設影響に関する推論仮説 [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S349

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s349_p01
  | s349_p02
  | s349_p03
  | s349_p04
  | s349_p05
  | s349_p06
  | s349_p07
  | s349_p08
  | s349_p09
  | s349_p10
  | s349_p11
  | s349_p12
  | s349_p13
  | s349_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s349_p01 => []
  | .s349_p02 => [.s349_p01]
  | .s349_p03 => [.s349_p01]
  | .s349_p04 => [.s349_p02]
  | .s349_p05 => [.s349_p03]
  | .s349_p06 => [.s349_p04, .s349_p05]
  | .s349_p07 => [.s349_p04]
  | .s349_p08 => [.s349_p05]
  | .s349_p09 => [.s349_p06, .s349_p07]
  | .s349_p10 => [.s349_p08]
  | .s349_p11 => [.s349_p09]
  | .s349_p12 => [.s349_p10]
  | .s349_p13 => [.s349_p11, .s349_p12]
  | .s349_p14 => [.s349_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地域属性・人種的背景に基づく差別的評価禁止の絶対不変条件 (ord=4) -/
  | FairnessInvariant
  /-- 宅地建物取引業法・個人情報保護法・公正住宅法への適合 (ord=3) -/
  | RegulatoryCompliance
  /-- 価格帯定義・不確実性開示・更新頻度の評価方針 (ord=2) -/
  | ValuationPolicy
  /-- 地価変動・需給バランス・周辺施設影響に関する推論仮説 (ord=1) -/
  | MarketHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FairnessInvariant => 4
  | .RegulatoryCompliance => 3
  | .ValuationPolicy => 2
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
  nontrivial := ⟨.FairnessInvariant, .MarketHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FairnessInvariant
  | .s349_p01 => .FairnessInvariant
  -- RegulatoryCompliance
  | .s349_p02 | .s349_p03 => .RegulatoryCompliance
  -- ValuationPolicy
  | .s349_p04 | .s349_p05 | .s349_p06 => .ValuationPolicy
  -- MarketHypothesis
  | .s349_p07 | .s349_p08 | .s349_p09 | .s349_p10 | .s349_p11 | .s349_p12 | .s349_p13 | .s349_p14 => .MarketHypothesis

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

end TestCoverage.S349

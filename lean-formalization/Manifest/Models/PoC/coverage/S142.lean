/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalCompliance** (ord=4): 個人情報保護法・プライバシー権に関する法的義務 [C1, C2]
- **FairnessStandard** (ord=3): 公平性・透明性に関する試験運営基準 [C3, H1]
- **DetectionPolicy** (ord=2): 不正検知の方針・閾値設定。運用実績に基づき調整 [C4, H2]
- **TechnicalChoice** (ord=1): 実装技術の選択。代替手段に応じて変更可能 [C5, H3]
- **ExperimentalRule** (ord=0): 試行段階のルール。パイロット運用で検証 [H4, H5]
-/

namespace TestCoverage.S142

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s142_p01
  | s142_p02
  | s142_p03
  | s142_p04
  | s142_p05
  | s142_p06
  | s142_p07
  | s142_p08
  | s142_p09
  | s142_p10
  | s142_p11
  | s142_p12
  | s142_p13
  | s142_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s142_p01 => []
  | .s142_p02 => []
  | .s142_p03 => [.s142_p01]
  | .s142_p04 => [.s142_p01, .s142_p02]
  | .s142_p05 => [.s142_p02]
  | .s142_p06 => [.s142_p03]
  | .s142_p07 => [.s142_p04]
  | .s142_p08 => [.s142_p03, .s142_p05]
  | .s142_p09 => [.s142_p06]
  | .s142_p10 => [.s142_p07]
  | .s142_p11 => [.s142_p06, .s142_p08]
  | .s142_p12 => [.s142_p09]
  | .s142_p13 => [.s142_p10, .s142_p11]
  | .s142_p14 => [.s142_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 個人情報保護法・プライバシー権に関する法的義務 (ord=4) -/
  | LegalCompliance
  /-- 公平性・透明性に関する試験運営基準 (ord=3) -/
  | FairnessStandard
  /-- 不正検知の方針・閾値設定。運用実績に基づき調整 (ord=2) -/
  | DetectionPolicy
  /-- 実装技術の選択。代替手段に応じて変更可能 (ord=1) -/
  | TechnicalChoice
  /-- 試行段階のルール。パイロット運用で検証 (ord=0) -/
  | ExperimentalRule
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalCompliance => 4
  | .FairnessStandard => 3
  | .DetectionPolicy => 2
  | .TechnicalChoice => 1
  | .ExperimentalRule => 0

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
  bottom := .ExperimentalRule
  nontrivial := ⟨.LegalCompliance, .ExperimentalRule, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalCompliance
  | .s142_p01 | .s142_p02 => .LegalCompliance
  -- FairnessStandard
  | .s142_p03 | .s142_p04 | .s142_p05 => .FairnessStandard
  -- DetectionPolicy
  | .s142_p06 | .s142_p07 | .s142_p08 => .DetectionPolicy
  -- TechnicalChoice
  | .s142_p09 | .s142_p10 | .s142_p11 => .TechnicalChoice
  -- ExperimentalRule
  | .s142_p12 | .s142_p13 | .s142_p14 => .ExperimentalRule

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

end TestCoverage.S142

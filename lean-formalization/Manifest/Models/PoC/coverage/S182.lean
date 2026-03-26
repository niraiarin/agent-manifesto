/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PublicSafety** (ord=3): 来場者の安全確保に関する不変制約。群衆事故防止が最優先 [C1, C2]
- **EventRegulation** (ord=2): 消防法・条例に基づく規制。主催者判断で細部は調整可能 [C3, H1]
- **OperationalDesign** (ord=1): 運営上の設計選択。会場レイアウトや動線に依存 [C4, C5, H2, H3]
- **PredictiveHypothesis** (ord=0): 予測精度に関する未検証の仮説。実地データで検証が必要 [H4, H5]
-/

namespace TestCoverage.S182

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s182_p01
  | s182_p02
  | s182_p03
  | s182_p04
  | s182_p05
  | s182_p06
  | s182_p07
  | s182_p08
  | s182_p09
  | s182_p10
  | s182_p11
  | s182_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s182_p01 => []
  | .s182_p02 => []
  | .s182_p03 => [.s182_p01]
  | .s182_p04 => [.s182_p01, .s182_p02]
  | .s182_p05 => [.s182_p02]
  | .s182_p06 => [.s182_p03]
  | .s182_p07 => [.s182_p04]
  | .s182_p08 => [.s182_p03, .s182_p05]
  | .s182_p09 => [.s182_p06]
  | .s182_p10 => [.s182_p07, .s182_p08]
  | .s182_p11 => [.s182_p06]
  | .s182_p12 => [.s182_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 来場者の安全確保に関する不変制約。群衆事故防止が最優先 (ord=3) -/
  | PublicSafety
  /-- 消防法・条例に基づく規制。主催者判断で細部は調整可能 (ord=2) -/
  | EventRegulation
  /-- 運営上の設計選択。会場レイアウトや動線に依存 (ord=1) -/
  | OperationalDesign
  /-- 予測精度に関する未検証の仮説。実地データで検証が必要 (ord=0) -/
  | PredictiveHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PublicSafety => 3
  | .EventRegulation => 2
  | .OperationalDesign => 1
  | .PredictiveHypothesis => 0

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
  bottom := .PredictiveHypothesis
  nontrivial := ⟨.PublicSafety, .PredictiveHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PublicSafety
  | .s182_p01 | .s182_p02 => .PublicSafety
  -- EventRegulation
  | .s182_p03 | .s182_p04 | .s182_p05 => .EventRegulation
  -- OperationalDesign
  | .s182_p06 | .s182_p07 | .s182_p08 => .OperationalDesign
  -- PredictiveHypothesis
  | .s182_p09 | .s182_p10 | .s182_p11 | .s182_p12 => .PredictiveHypothesis

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

end TestCoverage.S182

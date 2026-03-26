/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **geophysics** (ord=4): 地球物理学的な制約。津波の物理法則と地形データ。 [C4]
- **policy** (ord=3): 防災政策と法令に基づく制約。保守的予測の要請。 [C1, C3]
- **operational** (ord=2): 運用上の要件。時間制約とデータ管理。 [C2, C5]
- **method** (ord=1): 予測手法の設計判断。計算技術の進歩に応じて改善可能。 [H1, H2]
- **hypothesis** (ord=0): 未検証の仮説。実運用データで検証が必要。 [H3, H4]
-/

namespace Scenario253

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | geo1
  | geo2
  | pol1
  | pol2
  | pol3
  | opr1
  | opr2
  | opr3
  | met1
  | met2
  | met3
  | met4
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .geo1 => []
  | .geo2 => []
  | .pol1 => []
  | .pol2 => []
  | .pol3 => [.pol1]
  | .opr1 => [.pol2]
  | .opr2 => [.geo1]
  | .opr3 => [.opr1, .opr2]
  | .met1 => [.opr1, .geo1]
  | .met2 => [.geo1, .geo2, .pol2]
  | .met3 => [.met1, .met2]
  | .met4 => [.opr2, .opr3]
  | .hyp1 => [.opr2, .met3]
  | .hyp2 => [.pol3, .met2]
  | .hyp3 => [.met4, .hyp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地球物理学的な制約。津波の物理法則と地形データ。 (ord=4) -/
  | geophysics
  /-- 防災政策と法令に基づく制約。保守的予測の要請。 (ord=3) -/
  | policy
  /-- 運用上の要件。時間制約とデータ管理。 (ord=2) -/
  | operational
  /-- 予測手法の設計判断。計算技術の進歩に応じて改善可能。 (ord=1) -/
  | method
  /-- 未検証の仮説。実運用データで検証が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .geophysics => 4
  | .policy => 3
  | .operational => 2
  | .method => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.geophysics, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- geophysics
  | .geo1 | .geo2 => .geophysics
  -- policy
  | .pol1 | .pol2 | .pol3 => .policy
  -- operational
  | .opr1 | .opr2 | .opr3 => .operational
  -- method
  | .met1 | .met2 | .met3 | .met4 => .method
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 => .hypothesis

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

end Scenario253

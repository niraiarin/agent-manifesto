/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=5): 公共安全・災害防止の絶対制約 [C1, C2]
- **regulation** (ord=4): 法規制・検査基準 [C3, H1]
- **geotechnical** (ord=3): 地質・土壌条件の外部依存 [H2, H3]
- **diagnosis** (ord=2): 劣化診断モデル・検査手法 [C4, H4, H5]
- **maintenance** (ord=1): 保全計画・優先順位付け [C5, H6]
- **hypothesis** (ord=0): 未検証の仮説 [H7]
-/

namespace UndergroundPipeDegradation

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | safe2
  | regu1
  | regu2
  | geo1
  | geo2
  | diag1
  | diag2
  | diag3
  | mnt1
  | mnt2
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .safe2 => []
  | .regu1 => [.safe1]
  | .regu2 => [.safe2]
  | .geo1 => []
  | .geo2 => [.geo1]
  | .diag1 => [.regu1, .geo1]
  | .diag2 => [.geo2]
  | .diag3 => [.regu2, .diag1]
  | .mnt1 => [.safe1, .diag1]
  | .mnt2 => [.diag2, .diag3]
  | .hyp1 => [.mnt1]
  | .hyp2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 公共安全・災害防止の絶対制約 (ord=5) -/
  | safety
  /-- 法規制・検査基準 (ord=4) -/
  | regulation
  /-- 地質・土壌条件の外部依存 (ord=3) -/
  | geotechnical
  /-- 劣化診断モデル・検査手法 (ord=2) -/
  | diagnosis
  /-- 保全計画・優先順位付け (ord=1) -/
  | maintenance
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 5
  | .regulation => 4
  | .geotechnical => 3
  | .diagnosis => 2
  | .maintenance => 1
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
  nontrivial := ⟨.safety, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety
  | .safe1 | .safe2 => .safety
  -- regulation
  | .regu1 | .regu2 => .regulation
  -- geotechnical
  | .geo1 | .geo2 => .geotechnical
  -- diagnosis
  | .diag1 | .diag2 | .diag3 => .diagnosis
  -- maintenance
  | .mnt1 | .mnt2 => .maintenance
  -- hypothesis
  | .hyp1 | .hyp2 => .hypothesis

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

end UndergroundPipeDegradation

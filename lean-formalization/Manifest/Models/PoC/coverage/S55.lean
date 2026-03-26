/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=3): ドライバー安全・法規制の不変条件 [C1, C6, C7]
- **constraint** (ord=2): 品質・時間に関する外部依存制約 [C2, C3, C4]
- **policy** (ord=1): コスト・効率に関する運用方針 [C5, H3, H4]
- **optimization** (ord=0): AIが自律的に最適化するルート戦略 [H1, H2, H5]
-/

namespace DeliveryRoute

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | safe2
  | safe3
  | con1
  | con2
  | con3
  | con4
  | pol1
  | pol2
  | pol3
  | opt1
  | opt2
  | opt3
  | opt4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .safe2 => []
  | .safe3 => [.safe2]
  | .con1 => [.safe1]
  | .con2 => []
  | .con3 => [.safe2]
  | .con4 => [.safe1]
  | .pol1 => [.con2]
  | .pol2 => [.con2, .con1]
  | .pol3 => [.con4]
  | .opt1 => [.con3, .pol1]
  | .opt2 => [.pol1]
  | .opt3 => [.con3]
  | .opt4 => [.pol2, .opt1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- ドライバー安全・法規制の不変条件 (ord=3) -/
  | safety
  /-- 品質・時間に関する外部依存制約 (ord=2) -/
  | constraint
  /-- コスト・効率に関する運用方針 (ord=1) -/
  | policy
  /-- AIが自律的に最適化するルート戦略 (ord=0) -/
  | optimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 3
  | .constraint => 2
  | .policy => 1
  | .optimization => 0

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
  bottom := .optimization
  nontrivial := ⟨.safety, .optimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety
  | .safe1 | .safe2 | .safe3 => .safety
  -- constraint
  | .con1 | .con2 | .con3 | .con4 => .constraint
  -- policy
  | .pol1 | .pol2 | .pol3 => .policy
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 => .optimization

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

end DeliveryRoute

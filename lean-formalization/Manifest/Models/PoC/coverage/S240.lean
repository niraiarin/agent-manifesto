/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **flightSafety** (ord=4): 飛行安全の絶対条件。重心エンベロープと構造限界。 [C1]
- **hazmat** (ord=3): IATA危険物規則と温度管理制約。国際規制。 [C2, C4]
- **cargoReq** (ord=2): 貨物の運用要件。承認プロセスと時間制約。 [C3, C5]
- **optimization** (ord=1): AIによる積載配置の最適化戦略。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の最適化・工学的仮説。運用データで検証が必要。 [H2, H3]
-/

namespace Scenario240

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | fs1
  | fs2
  | hz1
  | hz2
  | hz3
  | cr1
  | cr2
  | cr3
  | opt1
  | opt2
  | opt3
  | opt4
  | opt5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .fs1 => []
  | .fs2 => []
  | .hz1 => [.fs1]
  | .hz2 => [.fs1, .fs2]
  | .hz3 => [.fs2]
  | .cr1 => [.fs1, .hz1]
  | .cr2 => [.hz2]
  | .cr3 => [.hz1, .hz3]
  | .opt1 => [.fs1, .fs2, .cr1]
  | .opt2 => [.hz1, .hz2, .hz3, .cr3]
  | .opt3 => [.cr2, .cr3]
  | .opt4 => [.opt1, .opt2]
  | .opt5 => [.opt2, .opt3]
  | .hyp1 => [.opt2, .opt4]
  | .hyp2 => [.opt3, .opt5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 飛行安全の絶対条件。重心エンベロープと構造限界。 (ord=4) -/
  | flightSafety
  /-- IATA危険物規則と温度管理制約。国際規制。 (ord=3) -/
  | hazmat
  /-- 貨物の運用要件。承認プロセスと時間制約。 (ord=2) -/
  | cargoReq
  /-- AIによる積載配置の最適化戦略。 (ord=1) -/
  | optimization
  /-- 未検証の最適化・工学的仮説。運用データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .flightSafety => 4
  | .hazmat => 3
  | .cargoReq => 2
  | .optimization => 1
  | .hyp => 0

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
  bottom := .hyp
  nontrivial := ⟨.flightSafety, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- flightSafety
  | .fs1 | .fs2 => .flightSafety
  -- hazmat
  | .hz1 | .hz2 | .hz3 => .hazmat
  -- cargoReq
  | .cr1 | .cr2 | .cr3 => .cargoReq
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 => .optimization
  -- hyp
  | .hyp1 | .hyp2 => .hyp

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

end Scenario240

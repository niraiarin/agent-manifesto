/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulatory** (ord=4): 原子力規制委員会の基準に基づく制約。法的強制力を持つ。 [C1, C3]
- **safety** (ord=3): プラント安全設計に由来する不変条件。ハードウェアインターロックで強制。 [C1, C4]
- **operational** (ord=2): 運転員と管理者が設定する運転方針。シフトやプラント状態に応じて変動。 [C2, C5, C6]
- **analysis** (ord=1): AIが自律的に最適化する解析手法。データに応じて調整可能。 [H1, H2, H4]
- **hyp** (ord=0): 運用データで検証が必要な未検証仮説。 [H3]
-/

namespace Scenario251

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | reg1
  | reg2
  | reg3
  | saf1
  | saf2
  | saf3
  | ops1
  | ops2
  | ops3
  | ops4
  | ana1
  | ana2
  | ana3
  | ana4
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .reg1 => []
  | .reg2 => []
  | .reg3 => []
  | .saf1 => [.reg1]
  | .saf2 => [.reg2]
  | .saf3 => [.reg1, .reg3]
  | .ops1 => [.saf1]
  | .ops2 => [.reg2, .saf2]
  | .ops3 => [.saf1, .saf3]
  | .ops4 => [.ops1, .ops2]
  | .ana1 => [.saf2, .saf3]
  | .ana2 => [.reg2, .ops2]
  | .ana3 => [.ops1, .ops3]
  | .ana4 => [.ana1, .ana2]
  | .hyp1 => [.ops2]
  | .hyp2 => [.ana3, .ana4]
  | .hyp3 => [.ana1, .hyp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 原子力規制委員会の基準に基づく制約。法的強制力を持つ。 (ord=4) -/
  | regulatory
  /-- プラント安全設計に由来する不変条件。ハードウェアインターロックで強制。 (ord=3) -/
  | safety
  /-- 運転員と管理者が設定する運転方針。シフトやプラント状態に応じて変動。 (ord=2) -/
  | operational
  /-- AIが自律的に最適化する解析手法。データに応じて調整可能。 (ord=1) -/
  | analysis
  /-- 運用データで検証が必要な未検証仮説。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulatory => 4
  | .safety => 3
  | .operational => 2
  | .analysis => 1
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
  nontrivial := ⟨.regulatory, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- regulatory
  | .reg1 | .reg2 | .reg3 => .regulatory
  -- safety
  | .saf1 | .saf2 | .saf3 => .safety
  -- operational
  | .ops1 | .ops2 | .ops3 | .ops4 => .operational
  -- analysis
  | .ana1 | .ana2 | .ana3 | .ana4 => .analysis
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 => .hyp

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

end Scenario251

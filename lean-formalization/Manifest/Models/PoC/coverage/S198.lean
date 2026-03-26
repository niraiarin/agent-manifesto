/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=3): 人命と健康に関わる安全基準。違反は作業停止。 [C1, C2]
- **regulation** (ord=2): 自治体基準と所有権に関する法的・倫理的制約。 [C3, C4]
- **design** (ord=1): 分別・識別の技術的設計判断。改善可能。 [C5, H1, H2]
- **hypothesis** (ord=0): 実証が必要な技術的仮説。 [H3]
-/

namespace Scenario198

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | saf1
  | saf2
  | saf3
  | reg1
  | reg2
  | reg3
  | des1
  | des2
  | des3
  | des4
  | des5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .saf1 => []
  | .saf2 => []
  | .saf3 => [.saf1]
  | .reg1 => []
  | .reg2 => []
  | .reg3 => [.saf1, .reg1]
  | .des1 => [.saf1, .saf3]
  | .des2 => [.reg1, .reg3]
  | .des3 => [.saf2, .reg1]
  | .des4 => [.des1, .des3]
  | .des5 => [.reg3, .des2]
  | .hyp1 => [.reg2, .des3]
  | .hyp2 => [.des4, .des5]
  | .hyp3 => [.hyp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人命と健康に関わる安全基準。違反は作業停止。 (ord=3) -/
  | safety
  /-- 自治体基準と所有権に関する法的・倫理的制約。 (ord=2) -/
  | regulation
  /-- 分別・識別の技術的設計判断。改善可能。 (ord=1) -/
  | design
  /-- 実証が必要な技術的仮説。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 3
  | .regulation => 2
  | .design => 1
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
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety
  | .saf1 | .saf2 | .saf3 => .safety
  -- regulation
  | .reg1 | .reg2 | .reg3 => .regulation
  -- design
  | .des1 | .des2 | .des3 | .des4 | .des5 => .design
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

end Scenario198

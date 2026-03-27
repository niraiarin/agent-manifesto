/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=3): 旅客安全・プライバシーに関わる不変条件 [C1, C2]
- **regulation** (ord=2): 業界規格・法規制への準拠 [C4, C6, H1]
- **operation** (ord=1): 空港職員が設定・調整する運用方針 [C3, C5, H3]
- **optimization** (ord=0): AIが自律的に最適化する追跡戦略 [H4, H5]
-/

namespace AirportBaggage

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | safe2
  | reg1
  | reg2
  | reg3
  | op1
  | op2
  | op3
  | op4
  | opt1
  | opt2
  | opt3
  | opt4
  | opt5
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .safe2 => []
  | .reg1 => [.safe1]
  | .reg2 => [.safe2]
  | .reg3 => []
  | .op1 => [.safe1, .reg1]
  | .op2 => [.reg1]
  | .op3 => [.safe1]
  | .op4 => [.reg2]
  | .opt1 => [.op2, .reg1]
  | .opt2 => [.op2]
  | .opt3 => [.reg2, .op3]
  | .opt4 => [.op1]
  | .opt5 => [.reg3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 旅客安全・プライバシーに関わる不変条件 (ord=3) -/
  | safety
  /-- 業界規格・法規制への準拠 (ord=2) -/
  | regulation
  /-- 空港職員が設定・調整する運用方針 (ord=1) -/
  | operation
  /-- AIが自律的に最適化する追跡戦略 (ord=0) -/
  | optimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 3
  | .regulation => 2
  | .operation => 1
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
  | .safe1 | .safe2 => .safety
  -- regulation
  | .reg1 | .reg2 | .reg3 => .regulation
  -- operation
  | .op1 | .op2 | .op3 | .op4 => .operation
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 => .optimization

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

end AirportBaggage

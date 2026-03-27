/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=4): 人命・設備安全に関わる不変条件 [C1, C2]
- **environment** (ord=3): 外部環境（気象・電力網）への依存 [H1, H2]
- **policy** (ord=2): ユーザが設定する運用方針 [C3, C4]
- **optimization** (ord=1): AIが自律的に最適化する省エネ戦略 [C5, H3]
-/

namespace TestCoverage.S11

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | saf1
  | saf2
  | saf3
  | env1
  | env2
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
  | .saf1 => []
  | .saf2 => []
  | .saf3 => []
  | .env1 => []
  | .env2 => []
  | .pol1 => [.saf1]
  | .pol2 => [.saf2, .env1]
  | .pol3 => [.saf3]
  | .opt1 => [.pol1, .env1]
  | .opt2 => [.pol2]
  | .opt3 => [.pol3, .env2]
  | .opt4 => [.opt1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人命・設備安全に関わる不変条件 (ord=4) -/
  | safety
  /-- 外部環境（気象・電力網）への依存 (ord=3) -/
  | environment
  /-- ユーザが設定する運用方針 (ord=2) -/
  | policy
  /-- AIが自律的に最適化する省エネ戦略 (ord=1) -/
  | optimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 4
  | .environment => 3
  | .policy => 2
  | .optimization => 1

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
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety
  | .saf1 | .saf2 | .saf3 => .safety
  -- environment
  | .env1 | .env2 => .environment
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

end TestCoverage.S11

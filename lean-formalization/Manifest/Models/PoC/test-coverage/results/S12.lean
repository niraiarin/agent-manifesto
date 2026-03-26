/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **fairness** (ord=4): 公平性・不正防止の不変条件 [C1, C2]
- **platform** (ord=3): プラットフォーム基盤への依存 [H1, H2]
- **rule** (ord=2): 運営が設定するマッチングルール [C3, C4]
- **tuning** (ord=1): AIが自動調整するマッチングパラメータ [H3, H4]
-/

namespace TestCoverage.S12

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | fair1
  | fair2
  | plat1
  | plat2
  | rul1
  | rul2
  | rul3
  | tun1
  | tun2
  | tun3
  | tun4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .fair1 => []
  | .fair2 => []
  | .plat1 => []
  | .plat2 => []
  | .rul1 => [.fair1]
  | .rul2 => [.fair2, .plat1]
  | .rul3 => [.fair1]
  | .tun1 => [.rul1, .plat1]
  | .tun2 => [.rul2]
  | .tun3 => [.rul3, .plat2]
  | .tun4 => [.tun1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 公平性・不正防止の不変条件 (ord=4) -/
  | fairness
  /-- プラットフォーム基盤への依存 (ord=3) -/
  | platform
  /-- 運営が設定するマッチングルール (ord=2) -/
  | rule
  /-- AIが自動調整するマッチングパラメータ (ord=1) -/
  | tuning
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .fairness => 4
  | .platform => 3
  | .rule => 2
  | .tuning => 1

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
  bottom := .tuning
  nontrivial := ⟨.fairness, .tuning, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- fairness
  | .fair1 | .fair2 => .fairness
  -- platform
  | .plat1 | .plat2 => .platform
  -- rule
  | .rul1 | .rul2 | .rul3 => .rule
  -- tuning
  | .tun1 | .tun2 | .tun3 | .tun4 => .tuning

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

end TestCoverage.S12

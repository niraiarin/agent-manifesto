/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **orbital** (ord=4): 軌道力学・物理法則に基づく不変条件。変更不可。 [C2, C4]
- **mission** (ord=3): ミッション要件。衛星設計時に確定し、運用中は原則変更しない。 [C1, C4]
- **ground** (ord=2): 地上局が管理する運用パラメータ。パスごとに更新可能。 [C3, C5]
- **onboard** (ord=1): 衛星が自律的に最適化するオンボード制御戦略。 [H1, H2, H3]
- **hyp** (ord=0): 運用データで検証が必要な仮説。 [H4]
-/

namespace Scenario271

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | orb1
  | orb2
  | orb3
  | mis1
  | mis2
  | mis3
  | mis4
  | gnd1
  | gnd2
  | gnd3
  | onb1
  | onb2
  | onb3
  | onb4
  | onb5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .orb1 => []
  | .orb2 => []
  | .orb3 => []
  | .mis1 => [.orb1]
  | .mis2 => [.orb2]
  | .mis3 => [.orb1, .orb3]
  | .mis4 => [.mis1]
  | .gnd1 => [.mis1]
  | .gnd2 => [.mis2, .mis3]
  | .gnd3 => [.gnd1]
  | .onb1 => [.orb1, .mis1]
  | .onb2 => [.gnd1, .gnd2]
  | .onb3 => [.orb2, .mis4]
  | .onb4 => [.onb1, .onb2]
  | .onb5 => [.orb3, .gnd3]
  | .hyp1 => [.onb1]
  | .hyp2 => [.onb3, .onb4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 軌道力学・物理法則に基づく不変条件。変更不可。 (ord=4) -/
  | orbital
  /-- ミッション要件。衛星設計時に確定し、運用中は原則変更しない。 (ord=3) -/
  | mission
  /-- 地上局が管理する運用パラメータ。パスごとに更新可能。 (ord=2) -/
  | ground
  /-- 衛星が自律的に最適化するオンボード制御戦略。 (ord=1) -/
  | onboard
  /-- 運用データで検証が必要な仮説。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .orbital => 4
  | .mission => 3
  | .ground => 2
  | .onboard => 1
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
  nontrivial := ⟨.orbital, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- orbital
  | .orb1 | .orb2 | .orb3 => .orbital
  -- mission
  | .mis1 | .mis2 | .mis3 | .mis4 => .mission
  -- ground
  | .gnd1 | .gnd2 | .gnd3 => .ground
  -- onboard
  | .onb1 | .onb2 | .onb3 | .onb4 | .onb5 => .onboard
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

end Scenario271

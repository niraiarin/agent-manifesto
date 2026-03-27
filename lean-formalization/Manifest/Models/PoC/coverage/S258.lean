/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ethics** (ord=6): 利用者の自律性と尊厳に関わる倫理的制約。不可侵。 [C1]
- **safety** (ord=5): 転倒・衝突防止に関わる安全設計制約。 [C2]
- **accessibility** (ord=4): 障害特性に応じたアクセシビリティ要件。白杖との共存前提。 [C3, C6]
- **hardware** (ord=3): デバイスのハードウェア制約。バッテリー・センサー仕様。 [C4, C5]
- **interaction** (ord=2): 利用者とのインタラクション設計。利用者テストに基づく改善可能。 [H1, H3]
- **optimization** (ord=1): AIモデルの最適化戦略。技術進歩に応じて改善可能。 [H2, H4]
- **hyp** (ord=0): 未検証の仮説。フィールドテストで検証が必要。 [H5]
-/

namespace Scenario258

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | eth1
  | eth2
  | saf1
  | saf2
  | saf3
  | acc1
  | acc2
  | acc3
  | hw1
  | hw2
  | hw3
  | int1
  | int2
  | int3
  | int4
  | int5
  | opt1
  | opt2
  | opt3
  | opt4
  | opt5
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .eth1 => []
  | .eth2 => []
  | .saf1 => [.eth1]
  | .saf2 => [.eth1, .eth2]
  | .saf3 => [.saf1]
  | .acc1 => [.saf1]
  | .acc2 => [.eth1, .saf2]
  | .acc3 => [.acc1, .acc2]
  | .hw1 => [.eth1]
  | .hw2 => [.saf3]
  | .hw3 => [.hw1, .hw2]
  | .int1 => [.saf1, .acc1]
  | .int2 => [.saf2, .acc3]
  | .int3 => [.acc2, .hw3]
  | .int4 => [.int1, .int2]
  | .int5 => [.int3, .int4]
  | .opt1 => [.hw1, .hw2, .hw3]
  | .opt2 => [.hw3, .int2]
  | .opt3 => [.acc1, .saf1]
  | .opt4 => [.opt1, .opt3]
  | .opt5 => [.opt3, .opt4]
  | .hyp1 => [.int4]
  | .hyp2 => [.int5, .opt2]
  | .hyp3 => [.opt4, .opt5]
  | .hyp4 => [.hyp1, .hyp2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 利用者の自律性と尊厳に関わる倫理的制約。不可侵。 (ord=6) -/
  | ethics
  /-- 転倒・衝突防止に関わる安全設計制約。 (ord=5) -/
  | safety
  /-- 障害特性に応じたアクセシビリティ要件。白杖との共存前提。 (ord=4) -/
  | accessibility
  /-- デバイスのハードウェア制約。バッテリー・センサー仕様。 (ord=3) -/
  | hardware
  /-- 利用者とのインタラクション設計。利用者テストに基づく改善可能。 (ord=2) -/
  | interaction
  /-- AIモデルの最適化戦略。技術進歩に応じて改善可能。 (ord=1) -/
  | optimization
  /-- 未検証の仮説。フィールドテストで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ethics => 6
  | .safety => 5
  | .accessibility => 4
  | .hardware => 3
  | .interaction => 2
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
  nontrivial := ⟨.ethics, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ethics
  | .eth1 | .eth2 => .ethics
  -- safety
  | .saf1 | .saf2 | .saf3 => .safety
  -- accessibility
  | .acc1 | .acc2 | .acc3 => .accessibility
  -- hardware
  | .hw1 | .hw2 | .hw3 => .hardware
  -- interaction
  | .int1 | .int2 | .int3 | .int4 | .int5 => .interaction
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 => .optimization
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 | .hyp4 => .hyp

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

end Scenario258

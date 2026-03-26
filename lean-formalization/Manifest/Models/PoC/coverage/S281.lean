/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physics** (ord=4): 加速器物理学に基づく不変条件。粒子ビームの基本力学。 [C2, C4]
- **safety** (ord=3): 放射線安全・機器保護のインターロック。法的・物理的に強制。 [C1, C2, C5]
- **experiment** (ord=2): 物理学者グループが設定する実験パラメータ。ランごとに変更。 [C3, C5]
- **control** (ord=1): AIが自律的に調整するビーム制御戦略。 [H1, H2, H3, H4]
- **hyp** (ord=0): 未検証の仮説。運転データで検証が必要。 [H2]
-/

namespace Scenario281

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | phys1
  | phys2
  | phys3
  | safe1
  | safe2
  | safe3
  | exp1
  | exp2
  | exp3
  | ctrl1
  | ctrl2
  | ctrl3
  | ctrl4
  | ctrl5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .phys1 => []
  | .phys2 => []
  | .phys3 => []
  | .safe1 => [.phys1]
  | .safe2 => [.phys2]
  | .safe3 => [.phys1, .phys3]
  | .exp1 => [.safe1]
  | .exp2 => [.safe2, .safe3]
  | .exp3 => [.safe1, .safe2]
  | .ctrl1 => [.phys2, .exp1]
  | .ctrl2 => [.safe3, .ctrl1]
  | .ctrl3 => [.exp1, .exp2]
  | .ctrl4 => [.safe2, .exp3]
  | .ctrl5 => [.phys3, .ctrl2]
  | .hyp1 => [.ctrl1, .ctrl5]
  | .hyp2 => [.ctrl3, .ctrl4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 加速器物理学に基づく不変条件。粒子ビームの基本力学。 (ord=4) -/
  | physics
  /-- 放射線安全・機器保護のインターロック。法的・物理的に強制。 (ord=3) -/
  | safety
  /-- 物理学者グループが設定する実験パラメータ。ランごとに変更。 (ord=2) -/
  | experiment
  /-- AIが自律的に調整するビーム制御戦略。 (ord=1) -/
  | control
  /-- 未検証の仮説。運転データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physics => 4
  | .safety => 3
  | .experiment => 2
  | .control => 1
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
  nontrivial := ⟨.physics, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physics
  | .phys1 | .phys2 | .phys3 => .physics
  -- safety
  | .safe1 | .safe2 | .safe3 => .safety
  -- experiment
  | .exp1 | .exp2 | .exp3 => .experiment
  -- control
  | .ctrl1 | .ctrl2 | .ctrl3 | .ctrl4 | .ctrl5 => .control
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

end Scenario281

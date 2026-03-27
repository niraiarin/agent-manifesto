/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=3): 作業者安全・衝突防止の絶対制約 [C1, C2]
- **physics** (ord=2): 物理モデル・運動学制約 [H1, H2]
- **calibration** (ord=1): 校正手順・精度ポリシー [C3, H3, H4]
- **hypothesis** (ord=0): 未検証の仮説 [H5]
-/

namespace RobotArmCalibration

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | safe2
  | safe3
  | phys1
  | phys2
  | phys3
  | cal1
  | cal2
  | cal3
  | cal4
  | hyp1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .safe2 => []
  | .safe3 => []
  | .phys1 => []
  | .phys2 => [.phys1]
  | .phys3 => [.safe1]
  | .cal1 => [.safe2, .phys1]
  | .cal2 => [.phys2, .phys3]
  | .cal3 => [.safe3]
  | .cal4 => [.cal1]
  | .hyp1 => [.cal2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 作業者安全・衝突防止の絶対制約 (ord=3) -/
  | safety
  /-- 物理モデル・運動学制約 (ord=2) -/
  | physics
  /-- 校正手順・精度ポリシー (ord=1) -/
  | calibration
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 3
  | .physics => 2
  | .calibration => 1
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
  | .safe1 | .safe2 | .safe3 => .safety
  -- physics
  | .phys1 | .phys2 | .phys3 => .physics
  -- calibration
  | .cal1 | .cal2 | .cal3 | .cal4 => .calibration
  -- hypothesis
  | .hyp1 => .hypothesis

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

end RobotArmCalibration

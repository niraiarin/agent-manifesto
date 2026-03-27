/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **geomech** (ord=6): 地盤力学の物理法則。土圧・水圧の基本原理。不変。 [C1]
- **structural** (ord=5): トンネル構造の安全性。切羽崩壊防止の絶対条件。 [C1, C4]
- **surfaceProtect** (ord=4): 地上構造物の保護。沈下量管理基準。 [C2]
- **designLimit** (ord=3): 設計段階で決定されたパラメータ上限値。 [C4]
- **operation** (ord=2): 技術者の判断による運用方針。地質急変時の停止ルール。 [C3, C5]
- **control** (ord=1): AIによる掘進パラメータの動的制御戦略。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の地質工学的仮説。施工データで検証が必要。 [H4]
-/

namespace Scenario237

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | geo1
  | geo2
  | str1
  | str2
  | str3
  | surf1
  | surf2
  | surf3
  | dlim1
  | dlim2
  | dlim3
  | ops1
  | ops2
  | ops3
  | ctrl1
  | ctrl2
  | ctrl3
  | ctrl4
  | ctrl5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .geo1 => []
  | .geo2 => []
  | .str1 => [.geo1]
  | .str2 => [.geo1, .geo2]
  | .str3 => [.geo2]
  | .surf1 => [.str1]
  | .surf2 => [.str1, .str2]
  | .surf3 => [.str3]
  | .dlim1 => [.str2, .surf1]
  | .dlim2 => [.surf2]
  | .dlim3 => [.surf3]
  | .ops1 => [.str1, .dlim1]
  | .ops2 => [.dlim2]
  | .ops3 => [.dlim1, .dlim3]
  | .ctrl1 => [.geo1, .str1, .dlim1, .ops1]
  | .ctrl2 => [.surf1, .surf2, .ops1]
  | .ctrl3 => [.str3, .ops3]
  | .ctrl4 => [.ctrl1, .ctrl3]
  | .ctrl5 => [.surf3, .dlim3, .ops2]
  | .hyp1 => [.ops2, .ctrl1]
  | .hyp2 => [.ctrl4, .ctrl5]
  | .hyp3 => [.ctrl3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地盤力学の物理法則。土圧・水圧の基本原理。不変。 (ord=6) -/
  | geomech
  /-- トンネル構造の安全性。切羽崩壊防止の絶対条件。 (ord=5) -/
  | structural
  /-- 地上構造物の保護。沈下量管理基準。 (ord=4) -/
  | surfaceProtect
  /-- 設計段階で決定されたパラメータ上限値。 (ord=3) -/
  | designLimit
  /-- 技術者の判断による運用方針。地質急変時の停止ルール。 (ord=2) -/
  | operation
  /-- AIによる掘進パラメータの動的制御戦略。 (ord=1) -/
  | control
  /-- 未検証の地質工学的仮説。施工データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .geomech => 6
  | .structural => 5
  | .surfaceProtect => 4
  | .designLimit => 3
  | .operation => 2
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
  nontrivial := ⟨.geomech, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- geomech
  | .geo1 | .geo2 => .geomech
  -- structural
  | .str1 | .str2 | .str3 => .structural
  -- surfaceProtect
  | .surf1 | .surf2 | .surf3 => .surfaceProtect
  -- designLimit
  | .dlim1 | .dlim2 | .dlim3 => .designLimit
  -- operation
  | .ops1 | .ops2 | .ops3 => .operation
  -- control
  | .ctrl1 | .ctrl2 | .ctrl3 | .ctrl4 | .ctrl5 => .control
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

end Scenario237

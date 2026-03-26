/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **BiologicalSafety** (ord=5): 人体への直接的安全制約。神経損傷・誤動作による傷害を防止 [C1, C2]
- **NeuralInterface** (ord=4): 筋電信号・神経インターフェースの生理学的制約 [C3, H1]
- **MotorControl** (ord=3): 運動制御アルゴリズムの設計方針 [C4, H2]
- **Adaptation** (ord=2): ユーザ適応・学習に基づく調整ルール [H3, H4]
- **ComfortPreference** (ord=1): 装着感・操作感の個人的好み [C5, C6, H5]
-/

namespace TestCoverage.S151

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s151_p01
  | s151_p02
  | s151_p03
  | s151_p04
  | s151_p05
  | s151_p06
  | s151_p07
  | s151_p08
  | s151_p09
  | s151_p10
  | s151_p11
  | s151_p12
  | s151_p13
  | s151_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s151_p01 => []
  | .s151_p02 => []
  | .s151_p03 => []
  | .s151_p04 => [.s151_p01]
  | .s151_p05 => [.s151_p02]
  | .s151_p06 => [.s151_p01, .s151_p03]
  | .s151_p07 => [.s151_p04]
  | .s151_p08 => [.s151_p05]
  | .s151_p09 => [.s151_p04, .s151_p06]
  | .s151_p10 => [.s151_p07]
  | .s151_p11 => [.s151_p08, .s151_p09]
  | .s151_p12 => [.s151_p10]
  | .s151_p13 => [.s151_p11]
  | .s151_p14 => [.s151_p12, .s151_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人体への直接的安全制約。神経損傷・誤動作による傷害を防止 (ord=5) -/
  | BiologicalSafety
  /-- 筋電信号・神経インターフェースの生理学的制約 (ord=4) -/
  | NeuralInterface
  /-- 運動制御アルゴリズムの設計方針 (ord=3) -/
  | MotorControl
  /-- ユーザ適応・学習に基づく調整ルール (ord=2) -/
  | Adaptation
  /-- 装着感・操作感の個人的好み (ord=1) -/
  | ComfortPreference
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .BiologicalSafety => 5
  | .NeuralInterface => 4
  | .MotorControl => 3
  | .Adaptation => 2
  | .ComfortPreference => 1

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
  bottom := .ComfortPreference
  nontrivial := ⟨.BiologicalSafety, .ComfortPreference, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- BiologicalSafety
  | .s151_p01 | .s151_p02 | .s151_p03 => .BiologicalSafety
  -- NeuralInterface
  | .s151_p04 | .s151_p05 | .s151_p06 => .NeuralInterface
  -- MotorControl
  | .s151_p07 | .s151_p08 | .s151_p09 => .MotorControl
  -- Adaptation
  | .s151_p10 | .s151_p11 => .Adaptation
  -- ComfortPreference
  | .s151_p12 | .s151_p13 | .s151_p14 => .ComfortPreference

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

end TestCoverage.S151

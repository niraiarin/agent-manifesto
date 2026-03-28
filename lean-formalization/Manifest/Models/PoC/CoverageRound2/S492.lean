/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PrivacyInvariant** (ord=5): 顧客個人情報保護の絶対制約。GDPR・個人情報保護法に基づく不変条件 [C1]
- **EthicalConstraint** (ord=4): 差別的予測・公平性侵害を防ぐ倫理的制約。透明性確保義務 [C2, C3]
- **BusinessPolicy** (ord=3): 顧客維持施策・介入タイミング・予算配分に関するビジネスポリシー [C4, H1]
- **PredictionStrategy** (ord=2): 特徴量選択・モデル選択・閾値設定に関する予測戦略 [H2, H3]
- **OperationalHeuristic** (ord=1): A/Bテスト設計・コホート分析・リアルタイム更新に関するヒューリスティック [H4, H5]
-/

namespace TestCoverage.S492

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s492_p01
  | s492_p02
  | s492_p03
  | s492_p04
  | s492_p05
  | s492_p06
  | s492_p07
  | s492_p08
  | s492_p09
  | s492_p10
  | s492_p11
  | s492_p12
  | s492_p13
  | s492_p14
  | s492_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s492_p01 => []
  | .s492_p02 => [.s492_p01]
  | .s492_p03 => [.s492_p01]
  | .s492_p04 => [.s492_p01]
  | .s492_p05 => [.s492_p03, .s492_p04]
  | .s492_p06 => [.s492_p03]
  | .s492_p07 => [.s492_p04]
  | .s492_p08 => [.s492_p05, .s492_p06]
  | .s492_p09 => [.s492_p06]
  | .s492_p10 => [.s492_p07]
  | .s492_p11 => [.s492_p08, .s492_p09]
  | .s492_p12 => [.s492_p09]
  | .s492_p13 => [.s492_p10]
  | .s492_p14 => [.s492_p11, .s492_p12]
  | .s492_p15 => [.s492_p13, .s492_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 顧客個人情報保護の絶対制約。GDPR・個人情報保護法に基づく不変条件 (ord=5) -/
  | PrivacyInvariant
  /-- 差別的予測・公平性侵害を防ぐ倫理的制約。透明性確保義務 (ord=4) -/
  | EthicalConstraint
  /-- 顧客維持施策・介入タイミング・予算配分に関するビジネスポリシー (ord=3) -/
  | BusinessPolicy
  /-- 特徴量選択・モデル選択・閾値設定に関する予測戦略 (ord=2) -/
  | PredictionStrategy
  /-- A/Bテスト設計・コホート分析・リアルタイム更新に関するヒューリスティック (ord=1) -/
  | OperationalHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PrivacyInvariant => 5
  | .EthicalConstraint => 4
  | .BusinessPolicy => 3
  | .PredictionStrategy => 2
  | .OperationalHeuristic => 1

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
  bottom := .OperationalHeuristic
  nontrivial := ⟨.PrivacyInvariant, .OperationalHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PrivacyInvariant
  | .s492_p01 | .s492_p02 => .PrivacyInvariant
  -- EthicalConstraint
  | .s492_p03 | .s492_p04 | .s492_p05 => .EthicalConstraint
  -- BusinessPolicy
  | .s492_p06 | .s492_p07 | .s492_p08 => .BusinessPolicy
  -- PredictionStrategy
  | .s492_p09 | .s492_p10 | .s492_p11 => .PredictionStrategy
  -- OperationalHeuristic
  | .s492_p12 | .s492_p13 | .s492_p14 | .s492_p15 => .OperationalHeuristic

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

end TestCoverage.S492

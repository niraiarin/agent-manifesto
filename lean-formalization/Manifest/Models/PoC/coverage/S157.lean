/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **WildlifeProtection** (ord=3): 鳥獣保護法・動物福祉の法的制約。保護種の捕獲禁止 [C1, C2]
- **DetectionSystem** (ord=2): センサー・画像認識システムの設計方針 [C3, H1, H2, H3]
- **ResponseProtocol** (ord=1): 検知後の対応手順と通知方式 [C4, H4, H5]
-/

namespace TestCoverage.S157

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s157_p01
  | s157_p02
  | s157_p03
  | s157_p04
  | s157_p05
  | s157_p06
  | s157_p07
  | s157_p08
  | s157_p09
  | s157_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s157_p01 => []
  | .s157_p02 => []
  | .s157_p03 => []
  | .s157_p04 => [.s157_p01]
  | .s157_p05 => [.s157_p02]
  | .s157_p06 => [.s157_p01, .s157_p03]
  | .s157_p07 => [.s157_p02]
  | .s157_p08 => [.s157_p04]
  | .s157_p09 => [.s157_p05, .s157_p06]
  | .s157_p10 => [.s157_p07, .s157_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 鳥獣保護法・動物福祉の法的制約。保護種の捕獲禁止 (ord=3) -/
  | WildlifeProtection
  /-- センサー・画像認識システムの設計方針 (ord=2) -/
  | DetectionSystem
  /-- 検知後の対応手順と通知方式 (ord=1) -/
  | ResponseProtocol
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .WildlifeProtection => 3
  | .DetectionSystem => 2
  | .ResponseProtocol => 1

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
  bottom := .ResponseProtocol
  nontrivial := ⟨.WildlifeProtection, .ResponseProtocol, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- WildlifeProtection
  | .s157_p01 | .s157_p02 | .s157_p03 => .WildlifeProtection
  -- DetectionSystem
  | .s157_p04 | .s157_p05 | .s157_p06 | .s157_p07 => .DetectionSystem
  -- ResponseProtocol
  | .s157_p08 | .s157_p09 | .s157_p10 => .ResponseProtocol

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

end TestCoverage.S157

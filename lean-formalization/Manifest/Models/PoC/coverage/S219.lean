/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **structural** (ord=4): トンネル構造の安全基準。土木工学的に不変。 [C1]
- **standard** (ord=3): 検査基準・検出閾値。規格で固定。 [C2, C4]
- **operational** (ord=2): 運用上の制約。ダイヤ・設備で決定。 [C3, C5]
- **detection** (ord=1): 検知アルゴリズムの設計方針。技術進歩で変更可能。 [H1, H2, H3, H4]
- **hyp** (ord=0): 未検証の仮説。実地テストで検証が必要。 [H4]
-/

namespace Scenario219

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | str1
  | str2
  | std1
  | std2
  | std3
  | opr1
  | opr2
  | opr3
  | dtc1
  | dtc2
  | dtc3
  | dtc4
  | dtc5
  | dtc6
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .str1 => []
  | .str2 => []
  | .std1 => [.str1]
  | .std2 => [.str1]
  | .std3 => [.str2]
  | .opr1 => [.str1, .std1]
  | .opr2 => [.std1]
  | .opr3 => [.std2, .std3]
  | .dtc1 => [.opr2, .std1]
  | .dtc2 => [.opr1, .opr3]
  | .dtc3 => [.std2, .std3, .opr3]
  | .dtc4 => [.std1, .opr2]
  | .dtc5 => [.opr1, .opr2]
  | .dtc6 => [.std3, .dtc1]
  | .hyp1 => [.dtc4, .dtc5]
  | .hyp2 => [.dtc1, .dtc6]
  | .hyp3 => [.dtc2]
  | .hyp4 => [.dtc3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- トンネル構造の安全基準。土木工学的に不変。 (ord=4) -/
  | structural
  /-- 検査基準・検出閾値。規格で固定。 (ord=3) -/
  | standard
  /-- 運用上の制約。ダイヤ・設備で決定。 (ord=2) -/
  | operational
  /-- 検知アルゴリズムの設計方針。技術進歩で変更可能。 (ord=1) -/
  | detection
  /-- 未検証の仮説。実地テストで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .structural => 4
  | .standard => 3
  | .operational => 2
  | .detection => 1
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
  nontrivial := ⟨.structural, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- structural
  | .str1 | .str2 => .structural
  -- standard
  | .std1 | .std2 | .std3 => .standard
  -- operational
  | .opr1 | .opr2 | .opr3 => .operational
  -- detection
  | .dtc1 | .dtc2 | .dtc3 | .dtc4 | .dtc5 | .dtc6 => .detection
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

end Scenario219

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **security** (ord=3): 物理的セキュリティの不変条件。ハードウェアで強制。 [C1, C3]
- **privacy** (ord=2): プライバシー保護要件。法規制と利用者合意で固定。 [C4, C2]
- **detection** (ord=1): 異常検知アルゴリズムの設計方針。技術進歩で変更可能。 [H1, H2]
- **hyp** (ord=0): 未検証の仮説。実運用データで検証が必要。 [H3]
-/

namespace Scenario215

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | sec1
  | sec2
  | sec3
  | prv1
  | prv2
  | prv3
  | dtc1
  | dtc2
  | dtc3
  | dtc4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .sec1 => []
  | .sec2 => []
  | .sec3 => []
  | .prv1 => [.sec1]
  | .prv2 => [.sec2]
  | .prv3 => [.sec1, .sec3]
  | .dtc1 => [.sec2, .prv1]
  | .dtc2 => [.prv2]
  | .dtc3 => [.sec3, .prv3]
  | .dtc4 => [.prv1, .prv2]
  | .hyp1 => [.dtc1, .dtc3]
  | .hyp2 => [.dtc4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 物理的セキュリティの不変条件。ハードウェアで強制。 (ord=3) -/
  | security
  /-- プライバシー保護要件。法規制と利用者合意で固定。 (ord=2) -/
  | privacy
  /-- 異常検知アルゴリズムの設計方針。技術進歩で変更可能。 (ord=1) -/
  | detection
  /-- 未検証の仮説。実運用データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .security => 3
  | .privacy => 2
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
  nontrivial := ⟨.security, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- security
  | .sec1 | .sec2 | .sec3 => .security
  -- privacy
  | .prv1 | .prv2 | .prv3 => .privacy
  -- detection
  | .dtc1 | .dtc2 | .dtc3 | .dtc4 => .detection
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

end Scenario215

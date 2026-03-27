/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **medical** (ord=4): 医療機器規制・データ保護法。法的に強制。 [C1, C3]
- **ethics** (ord=3): 公平性・非差別の倫理要件。社会的規範。 [C4]
- **clinical** (ord=2): 臨床的精度・表示基準。エビデンスで設定。 [C2, C5]
- **algorithm** (ord=1): 検出アルゴリズムの設計方針。技術進歩で変更可能。 [H1, H2, H3, H4]
- **hyp** (ord=0): 未検証の仮説。臨床試験で検証が必要。 [H4]
-/

namespace Scenario218

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | med1
  | med2
  | med3
  | eth1
  | eth2
  | eth3
  | clin1
  | clin2
  | clin3
  | clin4
  | alg1
  | alg2
  | alg3
  | alg4
  | alg5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .med1 => []
  | .med2 => []
  | .med3 => []
  | .eth1 => [.med1]
  | .eth2 => [.med1, .med2]
  | .eth3 => [.med3]
  | .clin1 => [.med1, .eth1]
  | .clin2 => [.eth2]
  | .clin3 => [.med3, .eth3]
  | .clin4 => [.eth1, .eth2]
  | .alg1 => [.eth1, .clin1]
  | .alg2 => [.clin1, .clin2]
  | .alg3 => [.med2, .clin3]
  | .alg4 => [.clin4]
  | .alg5 => [.eth2, .clin2]
  | .hyp1 => [.alg1, .alg4]
  | .hyp2 => [.alg3, .alg5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医療機器規制・データ保護法。法的に強制。 (ord=4) -/
  | medical
  /-- 公平性・非差別の倫理要件。社会的規範。 (ord=3) -/
  | ethics
  /-- 臨床的精度・表示基準。エビデンスで設定。 (ord=2) -/
  | clinical
  /-- 検出アルゴリズムの設計方針。技術進歩で変更可能。 (ord=1) -/
  | algorithm
  /-- 未検証の仮説。臨床試験で検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .medical => 4
  | .ethics => 3
  | .clinical => 2
  | .algorithm => 1
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
  nontrivial := ⟨.medical, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- medical
  | .med1 | .med2 | .med3 => .medical
  -- ethics
  | .eth1 | .eth2 | .eth3 => .ethics
  -- clinical
  | .clin1 | .clin2 | .clin3 | .clin4 => .clinical
  -- algorithm
  | .alg1 | .alg2 | .alg3 | .alg4 | .alg5 => .algorithm
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

end Scenario218

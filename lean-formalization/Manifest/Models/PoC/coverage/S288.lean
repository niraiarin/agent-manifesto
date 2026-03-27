/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ethics** (ord=5): 患者の権利と倫理に関する不可侵の原則。 [C5]
- **medical** (ord=4): 医療行為としての法的基準と診断権限の所在。 [C1]
- **clinical** (ord=3): 臨床プロトコルと安全基準。医療チームが設定。 [C2, C4]
- **device** (ord=2): センサーデバイスの物理的制約と装着条件。 [C3]
- **algorithm** (ord=1): AI分析アルゴリズムの設計判断。データで改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。臨床データで検証が必要。 [H4]
-/

namespace Scenario288

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | eth1
  | eth2
  | med1
  | med2
  | cln1
  | cln2
  | cln3
  | dev1
  | dev2
  | dev3
  | alg1
  | alg2
  | alg3
  | alg4
  | alg5
  | alg6
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .eth1 => []
  | .eth2 => []
  | .med1 => [.eth1]
  | .med2 => [.eth2]
  | .cln1 => [.med1]
  | .cln2 => [.med1, .med2]
  | .cln3 => [.cln1, .cln2]
  | .dev1 => [.cln2]
  | .dev2 => [.cln1, .cln3]
  | .dev3 => [.dev1, .dev2]
  | .alg1 => [.dev1, .dev2]
  | .alg2 => [.cln2, .dev1]
  | .alg3 => [.med1, .cln1, .dev3]
  | .alg4 => [.alg1, .alg2]
  | .alg5 => [.alg2, .alg3]
  | .alg6 => [.alg1, .alg3]
  | .hyp1 => [.eth1, .alg4]
  | .hyp2 => [.alg5, .alg6]
  | .hyp3 => [.hyp1]
  | .hyp4 => [.hyp2, .hyp3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者の権利と倫理に関する不可侵の原則。 (ord=5) -/
  | ethics
  /-- 医療行為としての法的基準と診断権限の所在。 (ord=4) -/
  | medical
  /-- 臨床プロトコルと安全基準。医療チームが設定。 (ord=3) -/
  | clinical
  /-- センサーデバイスの物理的制約と装着条件。 (ord=2) -/
  | device
  /-- AI分析アルゴリズムの設計判断。データで改善可能。 (ord=1) -/
  | algorithm
  /-- 未検証の仮説。臨床データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ethics => 5
  | .medical => 4
  | .clinical => 3
  | .device => 2
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
  nontrivial := ⟨.ethics, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ethics
  | .eth1 | .eth2 => .ethics
  -- medical
  | .med1 | .med2 => .medical
  -- clinical
  | .cln1 | .cln2 | .cln3 => .clinical
  -- device
  | .dev1 | .dev2 | .dev3 => .device
  -- algorithm
  | .alg1 | .alg2 | .alg3 | .alg4 | .alg5 | .alg6 => .algorithm
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

end Scenario288

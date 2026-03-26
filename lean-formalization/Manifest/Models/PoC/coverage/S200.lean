/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **medical** (ord=4): 医療安全と患者権利の不可侵原則。 [C1]
- **regulatory** (ord=3): 医療機器規制とデータ保護法。外部依存。 [C2, C4, C6]
- **clinical** (ord=2): 臨床運用の方針。施設ごとに設定可能。 [C3, C5]
- **algorithmic** (ord=1): AI推奨アルゴリズムの設計判断。改善可能。 [H1, H2, H3]
- **hypothesis** (ord=0): 臨床データで検証が必要な仮説。 [H4]
-/

namespace Scenario200

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | med1
  | med2
  | rgl1
  | rgl2
  | rgl3
  | cln1
  | cln2
  | cln3
  | alg1
  | alg2
  | alg3
  | alg4
  | alg5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .med1 => []
  | .med2 => []
  | .rgl1 => [.med1]
  | .rgl2 => []
  | .rgl3 => [.rgl2]
  | .cln1 => [.med1, .med2]
  | .cln2 => [.med2]
  | .cln3 => [.rgl1, .cln1]
  | .alg1 => [.cln1, .cln3]
  | .alg2 => [.rgl1]
  | .alg3 => [.cln2, .cln3]
  | .alg4 => [.alg1, .alg3]
  | .alg5 => [.rgl1, .rgl3, .alg2]
  | .hyp1 => [.rgl3, .alg5]
  | .hyp2 => [.alg4]
  | .hyp3 => [.alg1, .alg5, .hyp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医療安全と患者権利の不可侵原則。 (ord=4) -/
  | medical
  /-- 医療機器規制とデータ保護法。外部依存。 (ord=3) -/
  | regulatory
  /-- 臨床運用の方針。施設ごとに設定可能。 (ord=2) -/
  | clinical
  /-- AI推奨アルゴリズムの設計判断。改善可能。 (ord=1) -/
  | algorithmic
  /-- 臨床データで検証が必要な仮説。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .medical => 4
  | .regulatory => 3
  | .clinical => 2
  | .algorithmic => 1
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
  nontrivial := ⟨.medical, .hypothesis, by simp [ConcreteLayer.ord]⟩
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
  | .med1 | .med2 => .medical
  -- regulatory
  | .rgl1 | .rgl2 | .rgl3 => .regulatory
  -- clinical
  | .cln1 | .cln2 | .cln3 => .clinical
  -- algorithmic
  | .alg1 | .alg2 | .alg3 | .alg4 | .alg5 => .algorithmic
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 => .hypothesis

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

end Scenario200

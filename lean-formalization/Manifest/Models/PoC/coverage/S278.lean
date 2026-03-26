/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **clinical** (ord=3): 臨床基準と医師の判断権限。医学的根拠に基づく不変条件。 [C1, C2]
- **neonatal** (ord=2): 新生児の保護に関わる制約。倫理・プライバシーを含む。 [C3, C4, C5]
- **algorithm** (ord=1): AIの判定アルゴリズム。技術進歩で改善可能。 [H1, H2]
- **hyp** (ord=0): 臨床データで検証が必要な仮説。 [H3]
-/

namespace Scenario278

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | cln1
  | cln2
  | cln3
  | neo1
  | neo2
  | neo3
  | neo4
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
  | .cln1 => []
  | .cln2 => []
  | .cln3 => [.cln1]
  | .neo1 => [.cln1]
  | .neo2 => [.cln2]
  | .neo3 => [.cln3]
  | .neo4 => [.neo1, .neo3]
  | .alg1 => [.cln1, .cln3]
  | .alg2 => [.neo1, .neo2]
  | .alg3 => [.alg1, .alg2]
  | .alg4 => [.cln3, .neo4]
  | .alg5 => [.alg2, .alg4]
  | .hyp1 => [.neo2, .alg1]
  | .hyp2 => [.alg3, .alg5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 臨床基準と医師の判断権限。医学的根拠に基づく不変条件。 (ord=3) -/
  | clinical
  /-- 新生児の保護に関わる制約。倫理・プライバシーを含む。 (ord=2) -/
  | neonatal
  /-- AIの判定アルゴリズム。技術進歩で改善可能。 (ord=1) -/
  | algorithm
  /-- 臨床データで検証が必要な仮説。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .clinical => 3
  | .neonatal => 2
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
  nontrivial := ⟨.clinical, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- clinical
  | .cln1 | .cln2 | .cln3 => .clinical
  -- neonatal
  | .neo1 | .neo2 | .neo3 | .neo4 => .neonatal
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

end Scenario278

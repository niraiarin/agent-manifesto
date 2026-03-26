/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **standard** (ord=3): JIS等の規格で定められた安全基準。法的拘束力あり。 [C1]
- **inspection** (ord=2): 検査員による判定体制とデータ保持義務。 [C2, C3]
- **prediction** (ord=1): AIによる劣化予測モデルと交換推奨ロジック。 [H1, H2, H3]
- **hyp** (ord=0): 検証が必要な材料科学的仮説。 [H1]
-/

namespace Scenario233

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | std1
  | std2
  | insp1
  | insp2
  | insp3
  | pred1
  | pred2
  | pred3
  | pred4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .std1 => []
  | .std2 => []
  | .insp1 => [.std1]
  | .insp2 => [.std1, .std2]
  | .insp3 => [.std2]
  | .pred1 => [.std1, .insp1]
  | .pred2 => [.insp2]
  | .pred3 => [.insp1, .insp3]
  | .pred4 => [.pred1, .pred2]
  | .hyp1 => [.pred1]
  | .hyp2 => [.pred3, .pred4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- JIS等の規格で定められた安全基準。法的拘束力あり。 (ord=3) -/
  | standard
  /-- 検査員による判定体制とデータ保持義務。 (ord=2) -/
  | inspection
  /-- AIによる劣化予測モデルと交換推奨ロジック。 (ord=1) -/
  | prediction
  /-- 検証が必要な材料科学的仮説。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .standard => 3
  | .inspection => 2
  | .prediction => 1
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
  nontrivial := ⟨.standard, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- standard
  | .std1 | .std2 => .standard
  -- inspection
  | .insp1 | .insp2 | .insp3 => .inspection
  -- prediction
  | .pred1 | .pred2 | .pred3 | .pred4 => .prediction
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

end Scenario233

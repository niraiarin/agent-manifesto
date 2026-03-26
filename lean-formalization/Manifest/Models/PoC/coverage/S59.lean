/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **lifeSafety** (ord=3): 人命・集落保護の不変条件 [C1, C2, C3]
- **sensor** (ord=2): センサー・通信に関する外部依存 [C4, C5, C6]
- **detection** (ord=1): 検知アルゴリズムの運用方針 [H1, H2, H4]
- **prediction** (ord=0): AIが自律的に最適化する延焼予測 [H3, H5]
-/

namespace WildfireDetection

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | life1
  | life2
  | life3
  | sen1
  | sen2
  | sen3
  | sen4
  | det1
  | det2
  | det3
  | det4
  | pred1
  | pred2
  | pred3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .life1 => []
  | .life2 => [.life1]
  | .life3 => [.life1]
  | .sen1 => [.life2]
  | .sen2 => [.life1]
  | .sen3 => [.life3]
  | .sen4 => []
  | .det1 => [.sen1]
  | .det2 => [.sen1, .life2]
  | .det3 => [.sen4]
  | .det4 => [.sen2]
  | .pred1 => [.det1, .sen3]
  | .pred2 => [.sen2, .det4]
  | .pred3 => [.det2, .det3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人命・集落保護の不変条件 (ord=3) -/
  | lifeSafety
  /-- センサー・通信に関する外部依存 (ord=2) -/
  | sensor
  /-- 検知アルゴリズムの運用方針 (ord=1) -/
  | detection
  /-- AIが自律的に最適化する延焼予測 (ord=0) -/
  | prediction
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .lifeSafety => 3
  | .sensor => 2
  | .detection => 1
  | .prediction => 0

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
  bottom := .prediction
  nontrivial := ⟨.lifeSafety, .prediction, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- lifeSafety
  | .life1 | .life2 | .life3 => .lifeSafety
  -- sensor
  | .sen1 | .sen2 | .sen3 | .sen4 => .sensor
  -- detection
  | .det1 | .det2 | .det3 | .det4 => .detection
  -- prediction
  | .pred1 | .pred2 | .pred3 => .prediction

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

end WildfireDetection

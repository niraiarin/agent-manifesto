/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **medical** (ord=3): 医療安全と薬事規制。歯科医師の判断権限を含む。 [C1, C2]
- **patient** (ord=2): 患者固有の口腔条件と要望。ケースごとに異なる。 [C3, C4]
- **design** (ord=1): AIの設計最適化手法。技術進歩で改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 臨床データで検証が必要な仮説。 [H2, H3]
-/

namespace Scenario274

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | med1
  | med2
  | med3
  | pat1
  | pat2
  | pat3
  | des1
  | des2
  | des3
  | des4
  | des5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .med1 => []
  | .med2 => []
  | .med3 => []
  | .pat1 => [.med1]
  | .pat2 => [.med1]
  | .pat3 => [.pat1, .pat2]
  | .des1 => [.med2, .pat1]
  | .des2 => [.pat2, .pat3]
  | .des3 => [.med2, .pat1]
  | .des4 => [.des1, .des3]
  | .des5 => [.des1, .des2]
  | .hyp1 => [.des2]
  | .hyp2 => [.des4, .des5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医療安全と薬事規制。歯科医師の判断権限を含む。 (ord=3) -/
  | medical
  /-- 患者固有の口腔条件と要望。ケースごとに異なる。 (ord=2) -/
  | patient
  /-- AIの設計最適化手法。技術進歩で改善可能。 (ord=1) -/
  | design
  /-- 臨床データで検証が必要な仮説。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .medical => 3
  | .patient => 2
  | .design => 1
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
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- medical
  | .med1 | .med2 | .med3 => .medical
  -- patient
  | .pat1 | .pat2 | .pat3 => .patient
  -- design
  | .des1 | .des2 | .des3 | .des4 | .des5 => .design
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

end Scenario274

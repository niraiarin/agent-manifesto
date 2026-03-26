/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **content_integrity** (ord=4): コンテンツの意図と品質に関する不変制約 [C1, C2]
- **creative_standard** (ord=3): クリエイティブ品質に関する基準 [C3, H1]
- **workflow_rule** (ord=2): 編集ワークフロー上のルール [C4, C5]
- **technique_choice** (ord=1): 編集技法・ツールの選択 [H2, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_1a3300
  | prop_b87ec2
  | prop_937c56
  | prop_0e37de
  | prop_a4ebce
  | prop_5a346e
  | prop_086436
  | TransNetV_dbf9aa
  | BGM_74b9ef
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_1a3300 => []
  | .prop_b87ec2 => []
  | .prop_937c56 => []
  | .prop_0e37de => []
  | .prop_a4ebce => []
  | .prop_5a346e => []
  | .prop_086436 => []
  | .TransNetV_dbf9aa => []
  | .BGM_74b9ef => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- コンテンツの意図と品質に関する不変制約 (ord=4) -/
  | content_integrity
  /-- クリエイティブ品質に関する基準 (ord=3) -/
  | creative_standard
  /-- 編集ワークフロー上のルール (ord=2) -/
  | workflow_rule
  /-- 編集技法・ツールの選択 (ord=1) -/
  | technique_choice
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .content_integrity => 4
  | .creative_standard => 3
  | .workflow_rule => 2
  | .technique_choice => 1

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
  bottom := .technique_choice
  nontrivial := ⟨.content_integrity, .technique_choice, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- content_integrity
  | .prop_1a3300 | .prop_b87ec2 => .content_integrity
  -- creative_standard
  | .prop_937c56 | .prop_0e37de => .creative_standard
  -- workflow_rule
  | .prop_a4ebce | .prop_5a346e => .workflow_rule
  -- technique_choice
  | .prop_086436 | .TransNetV_dbf9aa | .BGM_74b9ef => .technique_choice

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

end Manifest.Models

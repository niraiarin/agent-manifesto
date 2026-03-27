/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **privacy** (ord=4): 個人情報保護・プライバシーの絶対制約 [C1, C2]
- **pedagogy** (ord=3): 教育学的前提・学習理論 [C3, H1]
- **data** (ord=2): 学習データ・プラットフォーム依存 [H2, H3]
- **prediction** (ord=1): 離脱予測モデル・介入戦略 [C4, H4, H5]
- **hypothesis** (ord=0): 未検証の仮説 [H6]
-/

namespace ELearningDropoutPrediction

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prv1
  | prv2
  | ped1
  | ped2
  | dat1
  | dat2
  | dat3
  | prd1
  | prd2
  | prd3
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prv1 => []
  | .prv2 => []
  | .ped1 => [.prv1]
  | .ped2 => []
  | .dat1 => [.prv2]
  | .dat2 => [.ped1]
  | .dat3 => []
  | .prd1 => [.ped1, .dat1]
  | .prd2 => [.dat2, .dat3]
  | .prd3 => [.ped2, .dat1]
  | .hyp1 => [.prd1]
  | .hyp2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 個人情報保護・プライバシーの絶対制約 (ord=4) -/
  | privacy
  /-- 教育学的前提・学習理論 (ord=3) -/
  | pedagogy
  /-- 学習データ・プラットフォーム依存 (ord=2) -/
  | data
  /-- 離脱予測モデル・介入戦略 (ord=1) -/
  | prediction
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .privacy => 4
  | .pedagogy => 3
  | .data => 2
  | .prediction => 1
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
  nontrivial := ⟨.privacy, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- privacy
  | .prv1 | .prv2 => .privacy
  -- pedagogy
  | .ped1 | .ped2 => .pedagogy
  -- data
  | .dat1 | .dat2 | .dat3 => .data
  -- prediction
  | .prd1 | .prd2 | .prd3 => .prediction
  -- hypothesis
  | .hyp1 | .hyp2 => .hypothesis

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

end ELearningDropoutPrediction

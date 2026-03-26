/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **volcanology** (ord=3): 火山学と海洋物理の法則に基づく不変制約。 [C2, C4]
- **authority** (ord=2): 海上保安庁・予知連の権限と法的制約。 [C1, C3, C5]
- **analysis** (ord=1): 監視・分析手法の設計判断。技術進歩に応じて改善可能。 [H1, H2, H3]
- **hypothesis** (ord=0): 未検証の仮説。監視データとの照合で検証が必要。 [H2]
-/

namespace Scenario257

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | vol1
  | vol2
  | vol3
  | aut1
  | aut2
  | aut3
  | anl1
  | anl2
  | anl3
  | anl4
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .vol1 => []
  | .vol2 => []
  | .vol3 => []
  | .aut1 => []
  | .aut2 => [.vol1]
  | .aut3 => [.aut1]
  | .anl1 => [.vol1, .vol3]
  | .anl2 => [.vol2, .aut2]
  | .anl3 => [.aut1, .aut3]
  | .anl4 => [.anl1, .anl2]
  | .hyp1 => [.anl2]
  | .hyp2 => [.anl4, .hyp1]
  | .hyp3 => [.anl3, .vol2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 火山学と海洋物理の法則に基づく不変制約。 (ord=3) -/
  | volcanology
  /-- 海上保安庁・予知連の権限と法的制約。 (ord=2) -/
  | authority
  /-- 監視・分析手法の設計判断。技術進歩に応じて改善可能。 (ord=1) -/
  | analysis
  /-- 未検証の仮説。監視データとの照合で検証が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .volcanology => 3
  | .authority => 2
  | .analysis => 1
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
  nontrivial := ⟨.volcanology, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- volcanology
  | .vol1 | .vol2 | .vol3 => .volcanology
  -- authority
  | .aut1 | .aut2 | .aut3 => .authority
  -- analysis
  | .anl1 | .anl2 | .anl3 | .anl4 => .analysis
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

end Scenario257

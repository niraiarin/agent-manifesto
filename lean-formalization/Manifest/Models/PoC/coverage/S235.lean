/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **observation** (ord=5): 衛星観測システムの物理的制約と仕様。外部データ提供元に依存。 [C1]
- **climate** (ord=4): 気候科学の理論的枠組み。IPCCシナリオとの整合性。 [C3]
- **policy** (ord=3): 政策立案・航路利用者への情報提供に関する制度的要件。 [C4]
- **operational** (ord=2): 不確実性定量化と出力品質の運用基準。 [C2]
- **forecast** (ord=1): AIによる海氷面積予測の手法と戦略。 [H1, H2, H3, H4]
- **hyp** (ord=0): 未検証の気候科学的・統計的仮説。 [H2, H3]
-/

namespace Scenario235

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | obs1
  | obs2
  | clim1
  | clim2
  | pol1
  | pol2
  | opr1
  | opr2
  | opr3
  | fcst1
  | fcst2
  | fcst3
  | fcst4
  | fcst5
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .obs1 => []
  | .obs2 => []
  | .clim1 => [.obs1]
  | .clim2 => [.obs1, .obs2]
  | .pol1 => [.clim1]
  | .pol2 => [.clim2]
  | .opr1 => [.pol1]
  | .opr2 => [.pol1, .pol2]
  | .opr3 => [.clim1, .pol2]
  | .fcst1 => [.obs1, .obs2, .opr1]
  | .fcst2 => [.clim1, .clim2, .opr2]
  | .fcst3 => [.opr1, .opr2]
  | .fcst4 => [.pol1, .opr3]
  | .fcst5 => [.fcst1, .fcst4]
  | .hyp1 => [.fcst2]
  | .hyp2 => [.fcst3]
  | .hyp3 => [.fcst2, .fcst3]
  | .hyp4 => [.fcst5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 衛星観測システムの物理的制約と仕様。外部データ提供元に依存。 (ord=5) -/
  | observation
  /-- 気候科学の理論的枠組み。IPCCシナリオとの整合性。 (ord=4) -/
  | climate
  /-- 政策立案・航路利用者への情報提供に関する制度的要件。 (ord=3) -/
  | policy
  /-- 不確実性定量化と出力品質の運用基準。 (ord=2) -/
  | operational
  /-- AIによる海氷面積予測の手法と戦略。 (ord=1) -/
  | forecast
  /-- 未検証の気候科学的・統計的仮説。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .observation => 5
  | .climate => 4
  | .policy => 3
  | .operational => 2
  | .forecast => 1
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
  nontrivial := ⟨.observation, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- observation
  | .obs1 | .obs2 => .observation
  -- climate
  | .clim1 | .clim2 => .climate
  -- policy
  | .pol1 | .pol2 => .policy
  -- operational
  | .opr1 | .opr2 | .opr3 => .operational
  -- forecast
  | .fcst1 | .fcst2 | .fcst3 | .fcst4 | .fcst5 => .forecast
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

end Scenario235

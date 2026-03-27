/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalSafety** (ord=4): 有害物質の取扱いに関する安全制約。法的義務 [C1, C2]
- **RecyclingStandard** (ord=3): リサイクル基準・分別ルール。業界標準に基づく [C3, H1]
- **SortingDesign** (ord=2): 分別システムの設計選択。技術更新可能 [C4, C5, H2]
- **EfficiencyHeuristic** (ord=1): 処理効率の仮説。運用実績で検証 [H3, H4]
-/

namespace TestCoverage.S134

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s134_p01
  | s134_p02
  | s134_p03
  | s134_p04
  | s134_p05
  | s134_p06
  | s134_p07
  | s134_p08
  | s134_p09
  | s134_p10
  | s134_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s134_p01 => []
  | .s134_p02 => []
  | .s134_p03 => [.s134_p01]
  | .s134_p04 => [.s134_p01, .s134_p02]
  | .s134_p05 => [.s134_p03]
  | .s134_p06 => [.s134_p03]
  | .s134_p07 => [.s134_p04]
  | .s134_p08 => [.s134_p03, .s134_p04]
  | .s134_p09 => [.s134_p05]
  | .s134_p10 => [.s134_p06, .s134_p07]
  | .s134_p11 => [.s134_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 有害物質の取扱いに関する安全制約。法的義務 (ord=4) -/
  | EnvironmentalSafety
  /-- リサイクル基準・分別ルール。業界標準に基づく (ord=3) -/
  | RecyclingStandard
  /-- 分別システムの設計選択。技術更新可能 (ord=2) -/
  | SortingDesign
  /-- 処理効率の仮説。運用実績で検証 (ord=1) -/
  | EfficiencyHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalSafety => 4
  | .RecyclingStandard => 3
  | .SortingDesign => 2
  | .EfficiencyHeuristic => 1

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
  bottom := .EfficiencyHeuristic
  nontrivial := ⟨.EnvironmentalSafety, .EfficiencyHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalSafety
  | .s134_p01 | .s134_p02 => .EnvironmentalSafety
  -- RecyclingStandard
  | .s134_p03 | .s134_p04 => .RecyclingStandard
  -- SortingDesign
  | .s134_p05 | .s134_p06 | .s134_p07 | .s134_p08 => .SortingDesign
  -- EfficiencyHeuristic
  | .s134_p09 | .s134_p10 | .s134_p11 => .EfficiencyHeuristic

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

end TestCoverage.S134

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **taxonomic_law** (ord=4): 国際動物命名規約・分類学の原則。学名の有効性基準 [C1, C2]
- **geological_context** (ord=3): 地質年代・地層情報。化石の時空間的制約 [C3, H1]
- **morphological_rule** (ord=2): 形態学的同定基準。鍵となる形質の判定ルール [H2, H3]
- **inference** (ord=1): 画像認識・統計的推論による同定候補 [H4, H5]
- **hypothesis** (ord=0): 未確認の分類仮説 [H6]
-/

namespace TestScenario.S262

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | tx1
  | tx2
  | gl1
  | gl2
  | mr1
  | mr2
  | mr3
  | in1
  | in2
  | in3
  | hp1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .tx1 => []
  | .tx2 => []
  | .gl1 => [.tx1]
  | .gl2 => []
  | .mr1 => [.tx1, .gl1]
  | .mr2 => [.tx2]
  | .mr3 => [.gl2]
  | .in1 => [.mr1, .mr2]
  | .in2 => [.mr3, .gl2]
  | .in3 => [.in1]
  | .hp1 => [.in2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 国際動物命名規約・分類学の原則。学名の有効性基準 (ord=4) -/
  | taxonomic_law
  /-- 地質年代・地層情報。化石の時空間的制約 (ord=3) -/
  | geological_context
  /-- 形態学的同定基準。鍵となる形質の判定ルール (ord=2) -/
  | morphological_rule
  /-- 画像認識・統計的推論による同定候補 (ord=1) -/
  | inference
  /-- 未確認の分類仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .taxonomic_law => 4
  | .geological_context => 3
  | .morphological_rule => 2
  | .inference => 1
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
  nontrivial := ⟨.taxonomic_law, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- taxonomic_law
  | .tx1 | .tx2 => .taxonomic_law
  -- geological_context
  | .gl1 | .gl2 => .geological_context
  -- morphological_rule
  | .mr1 | .mr2 | .mr3 => .morphological_rule
  -- inference
  | .in1 | .in2 | .in3 => .inference
  -- hypothesis
  | .hp1 => .hypothesis

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

end TestScenario.S262

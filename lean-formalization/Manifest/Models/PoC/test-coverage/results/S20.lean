/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **legal_regulation** (ord=5): 不動産取引法・宅建業法の法的義務 [C1, C2]
- **macro_economy** (ord=4): 金利・人口動態等のマクロ経済環境依存 [H1, H2]
- **area_attribute** (ord=3): 地域属性・インフラ等の構造的要因 [H3, C3]
- **valuation_policy** (ord=2): 鑑定士が設定する評価方針 [C4, C5]
- **price_estimate** (ord=1): AIが算出する価格予測・推奨値 [H4, H5]
-/

namespace TestCoverage.S20

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | lr1
  | lr2
  | me1
  | me2
  | aa1
  | aa2
  | vp1
  | vp2
  | vp3
  | pe1
  | pe2
  | pe3
  | pe4
  | pe5
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .lr1 => []
  | .lr2 => []
  | .me1 => []
  | .me2 => [.lr1]
  | .aa1 => [.me1]
  | .aa2 => [.lr2]
  | .vp1 => [.lr1, .aa1]
  | .vp2 => [.lr2, .me2]
  | .vp3 => [.aa2]
  | .pe1 => [.vp1, .me1]
  | .pe2 => [.vp2, .aa1]
  | .pe3 => [.vp3, .aa2]
  | .pe4 => [.pe1]
  | .pe5 => [.vp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 不動産取引法・宅建業法の法的義務 (ord=5) -/
  | legal_regulation
  /-- 金利・人口動態等のマクロ経済環境依存 (ord=4) -/
  | macro_economy
  /-- 地域属性・インフラ等の構造的要因 (ord=3) -/
  | area_attribute
  /-- 鑑定士が設定する評価方針 (ord=2) -/
  | valuation_policy
  /-- AIが算出する価格予測・推奨値 (ord=1) -/
  | price_estimate
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .legal_regulation => 5
  | .macro_economy => 4
  | .area_attribute => 3
  | .valuation_policy => 2
  | .price_estimate => 1

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
  bottom := .price_estimate
  nontrivial := ⟨.legal_regulation, .price_estimate, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- legal_regulation
  | .lr1 | .lr2 => .legal_regulation
  -- macro_economy
  | .me1 | .me2 => .macro_economy
  -- area_attribute
  | .aa1 | .aa2 => .area_attribute
  -- valuation_policy
  | .vp1 | .vp2 | .vp3 => .valuation_policy
  -- price_estimate
  | .pe1 | .pe2 | .pe3 | .pe4 | .pe5 => .price_estimate

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

end TestCoverage.S20

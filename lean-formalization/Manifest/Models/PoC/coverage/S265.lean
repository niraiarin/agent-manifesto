/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **atmospheric_physics** (ord=6): 大気化学・光化学反応の基本法則。Chapman機構 [C1]
- **regulatory_framework** (ord=5): モントリオール議定書・規制物質リスト [C2, C3]
- **observation_system** (ord=4): 観測機器の仕様・校正基準。ドブソン分光計・衛星センサ [C4, H1]
- **retrieval_algorithm** (ord=3): オゾン全量・鉛直分布の導出アルゴリズム [H2, H3]
- **trend_analysis** (ord=2): オゾン層回復トレンド解析。統計的有意性検定 [H4, H5]
- **early_warning** (ord=1): オゾンホール拡大警報の判定ロジック [H6, C5]
- **projection** (ord=0): 将来予測・気候モデル連携の仮説 [H7]
-/

namespace TestScenario.S265

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | ap1
  | ap2
  | rf1
  | rf2
  | os1
  | os2
  | ra1
  | ra2
  | ta1
  | ta2
  | ew1
  | ew2
  | pj1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .ap1 => []
  | .ap2 => []
  | .rf1 => [.ap1]
  | .rf2 => []
  | .os1 => [.ap1]
  | .os2 => [.rf1]
  | .ra1 => [.os1, .ap2]
  | .ra2 => [.os2]
  | .ta1 => [.ra1, .ra2]
  | .ta2 => [.rf2]
  | .ew1 => [.ta1]
  | .ew2 => [.ta2, .rf1]
  | .pj1 => [.ew1, .ta1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 大気化学・光化学反応の基本法則。Chapman機構 (ord=6) -/
  | atmospheric_physics
  /-- モントリオール議定書・規制物質リスト (ord=5) -/
  | regulatory_framework
  /-- 観測機器の仕様・校正基準。ドブソン分光計・衛星センサ (ord=4) -/
  | observation_system
  /-- オゾン全量・鉛直分布の導出アルゴリズム (ord=3) -/
  | retrieval_algorithm
  /-- オゾン層回復トレンド解析。統計的有意性検定 (ord=2) -/
  | trend_analysis
  /-- オゾンホール拡大警報の判定ロジック (ord=1) -/
  | early_warning
  /-- 将来予測・気候モデル連携の仮説 (ord=0) -/
  | projection
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .atmospheric_physics => 6
  | .regulatory_framework => 5
  | .observation_system => 4
  | .retrieval_algorithm => 3
  | .trend_analysis => 2
  | .early_warning => 1
  | .projection => 0

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
  bottom := .projection
  nontrivial := ⟨.atmospheric_physics, .projection, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- atmospheric_physics
  | .ap1 | .ap2 => .atmospheric_physics
  -- regulatory_framework
  | .rf1 | .rf2 => .regulatory_framework
  -- observation_system
  | .os1 | .os2 => .observation_system
  -- retrieval_algorithm
  | .ra1 | .ra2 => .retrieval_algorithm
  -- trend_analysis
  | .ta1 | .ta2 => .trend_analysis
  -- early_warning
  | .ew1 | .ew2 => .early_warning
  -- projection
  | .pj1 => .projection

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

end TestScenario.S265

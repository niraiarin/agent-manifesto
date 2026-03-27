/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **grid_safety** (ord=5): 電力系統の安全・安定に関する不変制約 [C1]
- **regulatory_standard** (ord=4): 電力市場・規制に関する要件 [C2]
- **forecast_quality** (ord=3): 予測精度に関する基準 [C3, H1]
- **operational_policy** (ord=2): 運用方針に関するルール [C4, C5]
- **model_selection** (ord=1): 予測モデル・手法の選択 [H3, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_03178e
  | prop_0f3f24
  | prop_f72a2b
  | prop_b6682a
  | prop_fbe3c0
  | prop_4d86a3
  | prop_f4cf63
  | ML_34695d
  | GBDT_779429
  | PI_15057f
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_03178e => []
  | .prop_0f3f24 => []
  | .prop_f72a2b => []
  | .prop_b6682a => []
  | .prop_fbe3c0 => []
  | .prop_4d86a3 => []
  | .prop_f4cf63 => []
  | .ML_34695d => []
  | .GBDT_779429 => []
  | .PI_15057f => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 電力系統の安全・安定に関する不変制約 (ord=5) -/
  | grid_safety
  /-- 電力市場・規制に関する要件 (ord=4) -/
  | regulatory_standard
  /-- 予測精度に関する基準 (ord=3) -/
  | forecast_quality
  /-- 運用方針に関するルール (ord=2) -/
  | operational_policy
  /-- 予測モデル・手法の選択 (ord=1) -/
  | model_selection
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .grid_safety => 5
  | .regulatory_standard => 4
  | .forecast_quality => 3
  | .operational_policy => 2
  | .model_selection => 1

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
  bottom := .model_selection
  nontrivial := ⟨.grid_safety, .model_selection, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- grid_safety
  | .prop_03178e | .prop_0f3f24 => .grid_safety
  -- regulatory_standard
  | .prop_f72a2b => .regulatory_standard
  -- forecast_quality
  | .prop_b6682a | .prop_fbe3c0 | .PI_15057f => .forecast_quality
  -- operational_policy
  | .prop_4d86a3 | .prop_f4cf63 => .operational_policy
  -- model_selection
  | .ML_34695d | .GBDT_779429 => .model_selection

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

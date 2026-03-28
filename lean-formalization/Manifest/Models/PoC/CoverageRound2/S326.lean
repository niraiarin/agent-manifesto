/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_invariant** (ord=5): 安全直結故障の即時停止に関する絶対不変条件 [C1]
- **asset_management_standard** (ord=4): ISO 55000・資産ライフサイクル管理への適合 [C6]
- **operational_policy** (ord=3): 予測提示・ウォームアップ期間・生産連動スケジューリング [C2, C3, C4, H3]
- **model_governance** (ord=2): モデル専門化・転移学習・ウォームアップ管理の方針 [C4, C5, H4]
- **prediction_model** (ord=1): センサー融合・LSTMオートエンコーダ・ベイズ更新の推論仮説 [H1, H2, H5]
-/

namespace TestCoverage.S326

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s326_p01
  | s326_p02
  | s326_p03
  | s326_p04
  | s326_p05
  | s326_p06
  | s326_p07
  | s326_p08
  | s326_p09
  | s326_p10
  | s326_p11
  | s326_p12
  | s326_p13
  | s326_p14
  | s326_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s326_p01 => []
  | .s326_p02 => [.s326_p01]
  | .s326_p03 => []
  | .s326_p04 => [.s326_p03]
  | .s326_p05 => [.s326_p01]
  | .s326_p06 => [.s326_p05]
  | .s326_p07 => [.s326_p05, .s326_p06]
  | .s326_p08 => [.s326_p04, .s326_p06]
  | .s326_p09 => [.s326_p07]
  | .s326_p10 => [.s326_p07, .s326_p09]
  | .s326_p11 => [.s326_p10]
  | .s326_p12 => [.s326_p09]
  | .s326_p13 => [.s326_p05, .s326_p12]
  | .s326_p14 => [.s326_p03, .s326_p04]
  | .s326_p15 => [.s326_p12, .s326_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 安全直結故障の即時停止に関する絶対不変条件 (ord=5) -/
  | safety_invariant
  /-- ISO 55000・資産ライフサイクル管理への適合 (ord=4) -/
  | asset_management_standard
  /-- 予測提示・ウォームアップ期間・生産連動スケジューリング (ord=3) -/
  | operational_policy
  /-- モデル専門化・転移学習・ウォームアップ管理の方針 (ord=2) -/
  | model_governance
  /-- センサー融合・LSTMオートエンコーダ・ベイズ更新の推論仮説 (ord=1) -/
  | prediction_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_invariant => 5
  | .asset_management_standard => 4
  | .operational_policy => 3
  | .model_governance => 2
  | .prediction_model => 1

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
  bottom := .prediction_model
  nontrivial := ⟨.safety_invariant, .prediction_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_invariant
  | .s326_p01 | .s326_p02 => .safety_invariant
  -- asset_management_standard
  | .s326_p03 | .s326_p04 => .asset_management_standard
  -- operational_policy
  | .s326_p05 | .s326_p06 | .s326_p07 | .s326_p08 => .operational_policy
  -- model_governance
  | .s326_p09 | .s326_p10 | .s326_p11 => .model_governance
  -- prediction_model
  | .s326_p12 | .s326_p13 | .s326_p14 | .s326_p15 => .prediction_model

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

end TestCoverage.S326

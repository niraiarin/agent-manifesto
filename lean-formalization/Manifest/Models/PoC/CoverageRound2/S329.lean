/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **grid_safety_invariant** (ord=4): 電力系統安定性・デマンドレスポンス遵守に関する絶対不変条件 [C1]
- **regulatory_compliance** (ord=3): 価格規制・個人情報保護・報告義務への適合 [C3, C4, C6]
- **operational_policy** (ord=2): 故障通知・再エネ優先・KPI管理の運用方針 [C2, C5, H2, H3]
- **optimization_model** (ord=1): V2G統合・動的価格・予知保全の最適化モデル仮説 [H1, H4, H5]
-/

namespace TestCoverage.S329

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s329_p01
  | s329_p02
  | s329_p03
  | s329_p04
  | s329_p05
  | s329_p06
  | s329_p07
  | s329_p08
  | s329_p09
  | s329_p10
  | s329_p11
  | s329_p12
  | s329_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s329_p01 => []
  | .s329_p02 => [.s329_p01]
  | .s329_p03 => [.s329_p01]
  | .s329_p04 => []
  | .s329_p05 => [.s329_p03]
  | .s329_p06 => [.s329_p05]
  | .s329_p07 => [.s329_p01]
  | .s329_p08 => [.s329_p06]
  | .s329_p09 => [.s329_p07]
  | .s329_p10 => [.s329_p01, .s329_p07]
  | .s329_p11 => [.s329_p03, .s329_p09]
  | .s329_p12 => [.s329_p04]
  | .s329_p13 => [.s329_p10, .s329_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 電力系統安定性・デマンドレスポンス遵守に関する絶対不変条件 (ord=4) -/
  | grid_safety_invariant
  /-- 価格規制・個人情報保護・報告義務への適合 (ord=3) -/
  | regulatory_compliance
  /-- 故障通知・再エネ優先・KPI管理の運用方針 (ord=2) -/
  | operational_policy
  /-- V2G統合・動的価格・予知保全の最適化モデル仮説 (ord=1) -/
  | optimization_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .grid_safety_invariant => 4
  | .regulatory_compliance => 3
  | .operational_policy => 2
  | .optimization_model => 1

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
  bottom := .optimization_model
  nontrivial := ⟨.grid_safety_invariant, .optimization_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- grid_safety_invariant
  | .s329_p01 | .s329_p02 => .grid_safety_invariant
  -- regulatory_compliance
  | .s329_p03 | .s329_p04 | .s329_p05 => .regulatory_compliance
  -- operational_policy
  | .s329_p06 | .s329_p07 | .s329_p08 | .s329_p09 => .operational_policy
  -- optimization_model
  | .s329_p10 | .s329_p11 | .s329_p12 | .s329_p13 => .optimization_model

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

end TestCoverage.S329

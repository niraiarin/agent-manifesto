/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_invariant** (ord=4): 航空安全・衝突回避に関する絶対不変条件 [C1, C2, C3]
- **regulatory_compliance** (ord=3): 航空法・国交省規則への適合要件 [C1, C5]
- **operational_policy** (ord=2): 運用方針・飛行停止基準・監視体制 [C4, C5, C6, H1, H2, H3]
- **optimization_model** (ord=1): ルート最適化・バッテリー管理の推論モデル [H4, H5]
-/

namespace TestCoverage.S321

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s321_p01
  | s321_p02
  | s321_p03
  | s321_p04
  | s321_p05
  | s321_p06
  | s321_p07
  | s321_p08
  | s321_p09
  | s321_p10
  | s321_p11
  | s321_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s321_p01 => []
  | .s321_p02 => [.s321_p01]
  | .s321_p03 => []
  | .s321_p04 => [.s321_p01]
  | .s321_p05 => [.s321_p04]
  | .s321_p06 => [.s321_p04]
  | .s321_p07 => [.s321_p02, .s321_p06]
  | .s321_p08 => [.s321_p03]
  | .s321_p09 => [.s321_p08]
  | .s321_p10 => [.s321_p06, .s321_p07]
  | .s321_p11 => [.s321_p10]
  | .s321_p12 => [.s321_p09, .s321_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 航空安全・衝突回避に関する絶対不変条件 (ord=4) -/
  | safety_invariant
  /-- 航空法・国交省規則への適合要件 (ord=3) -/
  | regulatory_compliance
  /-- 運用方針・飛行停止基準・監視体制 (ord=2) -/
  | operational_policy
  /-- ルート最適化・バッテリー管理の推論モデル (ord=1) -/
  | optimization_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_invariant => 4
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
  nontrivial := ⟨.safety_invariant, .optimization_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_invariant
  | .s321_p01 | .s321_p02 | .s321_p03 => .safety_invariant
  -- regulatory_compliance
  | .s321_p04 | .s321_p05 => .regulatory_compliance
  -- operational_policy
  | .s321_p06 | .s321_p07 | .s321_p08 | .s321_p09 => .operational_policy
  -- optimization_model
  | .s321_p10 | .s321_p11 | .s321_p12 => .optimization_model

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

end TestCoverage.S321

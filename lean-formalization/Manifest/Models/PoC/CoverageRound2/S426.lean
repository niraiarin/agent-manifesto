/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PublicSafety** (ord=3): 住民避難勧告発令基準・誤報抑制・見落とし防止に関する絶対要件 [C1, C2]
- **AlertPolicy** (ord=2): 水位閾値・降雨量累積・ダム放流通知に基づくアラート発令方針 [C3, C4, H1, H2, H3]
- **HydroHypothesis** (ord=1): 流域モデル・土壌飽和度・地下水位・降雨継続時間に関する水文学仮説 [H4, H5, H6, H7, H8]
-/

namespace TestCoverage.S426

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s426_p01
  | s426_p02
  | s426_p03
  | s426_p04
  | s426_p05
  | s426_p06
  | s426_p07
  | s426_p08
  | s426_p09
  | s426_p10
  | s426_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s426_p01 => []
  | .s426_p02 => []
  | .s426_p03 => [.s426_p01]
  | .s426_p04 => [.s426_p02]
  | .s426_p05 => [.s426_p03, .s426_p04]
  | .s426_p06 => [.s426_p03]
  | .s426_p07 => [.s426_p04]
  | .s426_p08 => [.s426_p06]
  | .s426_p09 => [.s426_p07]
  | .s426_p10 => [.s426_p08]
  | .s426_p11 => [.s426_p09, .s426_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 住民避難勧告発令基準・誤報抑制・見落とし防止に関する絶対要件 (ord=3) -/
  | PublicSafety
  /-- 水位閾値・降雨量累積・ダム放流通知に基づくアラート発令方針 (ord=2) -/
  | AlertPolicy
  /-- 流域モデル・土壌飽和度・地下水位・降雨継続時間に関する水文学仮説 (ord=1) -/
  | HydroHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PublicSafety => 3
  | .AlertPolicy => 2
  | .HydroHypothesis => 1

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
  bottom := .HydroHypothesis
  nontrivial := ⟨.PublicSafety, .HydroHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PublicSafety
  | .s426_p01 | .s426_p02 => .PublicSafety
  -- AlertPolicy
  | .s426_p03 | .s426_p04 | .s426_p05 => .AlertPolicy
  -- HydroHypothesis
  | .s426_p06 | .s426_p07 | .s426_p08 | .s426_p09 | .s426_p10 | .s426_p11 => .HydroHypothesis

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

end TestCoverage.S426

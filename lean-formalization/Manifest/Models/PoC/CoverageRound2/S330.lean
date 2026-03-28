/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_invariant** (ord=5): 毒性見逃しゼロ・臨床移行ゲートに関する絶対不変条件 [C1, C2]
- **ip_protection** (ord=4): 化合物データ・予測結果の知的財産保護 [C4]
- **quality_standard** (ord=3): モデル検証・ベンチマーク合格・ADMET評価基準 [C5, C3]
- **prioritization_policy** (ord=2): アンメット・ニーズ優先・ヒット率管理・候補選定方針 [C6, H2, H3]
- **ml_model** (ord=1): GNN・アンサンブル毒性予測・類似化合物検索の仮説 [H1, H4, H5]
-/

namespace TestCoverage.S330

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s330_p01
  | s330_p02
  | s330_p03
  | s330_p04
  | s330_p05
  | s330_p06
  | s330_p07
  | s330_p08
  | s330_p09
  | s330_p10
  | s330_p11
  | s330_p12
  | s330_p13
  | s330_p14
  | s330_p15
  | s330_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s330_p01 => []
  | .s330_p02 => [.s330_p01]
  | .s330_p03 => [.s330_p01, .s330_p02]
  | .s330_p04 => []
  | .s330_p05 => [.s330_p04]
  | .s330_p06 => [.s330_p01]
  | .s330_p07 => [.s330_p06]
  | .s330_p08 => [.s330_p06, .s330_p07]
  | .s330_p09 => [.s330_p06]
  | .s330_p10 => [.s330_p02, .s330_p09]
  | .s330_p11 => [.s330_p07, .s330_p10]
  | .s330_p12 => [.s330_p09, .s330_p11]
  | .s330_p13 => [.s330_p06, .s330_p08]
  | .s330_p14 => [.s330_p01, .s330_p13]
  | .s330_p15 => [.s330_p08]
  | .s330_p16 => [.s330_p13, .s330_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 毒性見逃しゼロ・臨床移行ゲートに関する絶対不変条件 (ord=5) -/
  | safety_invariant
  /-- 化合物データ・予測結果の知的財産保護 (ord=4) -/
  | ip_protection
  /-- モデル検証・ベンチマーク合格・ADMET評価基準 (ord=3) -/
  | quality_standard
  /-- アンメット・ニーズ優先・ヒット率管理・候補選定方針 (ord=2) -/
  | prioritization_policy
  /-- GNN・アンサンブル毒性予測・類似化合物検索の仮説 (ord=1) -/
  | ml_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_invariant => 5
  | .ip_protection => 4
  | .quality_standard => 3
  | .prioritization_policy => 2
  | .ml_model => 1

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
  bottom := .ml_model
  nontrivial := ⟨.safety_invariant, .ml_model, by simp [ConcreteLayer.ord]⟩
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
  | .s330_p01 | .s330_p02 | .s330_p03 => .safety_invariant
  -- ip_protection
  | .s330_p04 | .s330_p05 => .ip_protection
  -- quality_standard
  | .s330_p06 | .s330_p07 | .s330_p08 => .quality_standard
  -- prioritization_policy
  | .s330_p09 | .s330_p10 | .s330_p11 | .s330_p12 => .prioritization_policy
  -- ml_model
  | .s330_p13 | .s330_p14 | .s330_p15 | .s330_p16 => .ml_model

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

end TestCoverage.S330

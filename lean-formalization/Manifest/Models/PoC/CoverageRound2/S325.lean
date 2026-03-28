/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **environmental_safety** (ord=4): 水質汚染検出・住民安全に関する絶対不変条件 [C1, C4]
- **sensor_integrity** (ord=3): センサーネットワークの信頼性・冗長性保証 [C2, C6]
- **operational_policy** (ord=2): 汚染源特定・アラート通知・長期保存の運用方針 [C3, C5, H3, H5]
- **analysis_model** (ord=1): 多変量異常検知・粒子追跡・時系列分析モデルの仮説 [H1, H2, H4]
-/

namespace TestCoverage.S325

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s325_p01
  | s325_p02
  | s325_p03
  | s325_p04
  | s325_p05
  | s325_p06
  | s325_p07
  | s325_p08
  | s325_p09
  | s325_p10
  | s325_p11
  | s325_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s325_p01 => []
  | .s325_p02 => [.s325_p01]
  | .s325_p03 => []
  | .s325_p04 => [.s325_p03]
  | .s325_p05 => [.s325_p03, .s325_p04]
  | .s325_p06 => [.s325_p05]
  | .s325_p07 => [.s325_p04]
  | .s325_p08 => [.s325_p01, .s325_p07]
  | .s325_p09 => [.s325_p03, .s325_p05]
  | .s325_p10 => [.s325_p05, .s325_p09]
  | .s325_p11 => [.s325_p06]
  | .s325_p12 => [.s325_p09, .s325_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 水質汚染検出・住民安全に関する絶対不変条件 (ord=4) -/
  | environmental_safety
  /-- センサーネットワークの信頼性・冗長性保証 (ord=3) -/
  | sensor_integrity
  /-- 汚染源特定・アラート通知・長期保存の運用方針 (ord=2) -/
  | operational_policy
  /-- 多変量異常検知・粒子追跡・時系列分析モデルの仮説 (ord=1) -/
  | analysis_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .environmental_safety => 4
  | .sensor_integrity => 3
  | .operational_policy => 2
  | .analysis_model => 1

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
  bottom := .analysis_model
  nontrivial := ⟨.environmental_safety, .analysis_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- environmental_safety
  | .s325_p01 | .s325_p02 => .environmental_safety
  -- sensor_integrity
  | .s325_p03 | .s325_p04 => .sensor_integrity
  -- operational_policy
  | .s325_p05 | .s325_p06 | .s325_p07 | .s325_p08 => .operational_policy
  -- analysis_model
  | .s325_p09 | .s325_p10 | .s325_p11 | .s325_p12 => .analysis_model

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

end TestCoverage.S325

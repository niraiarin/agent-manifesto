/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **environmental_law** (ord=5): 海洋環境保護の国際法規。MARPOL条約・生態系保全義務 [C1, C2]
- **oceanographic_model** (ord=4): 海流・波浪の物理モデル。Ekman輸送・Stokes漂流 [H1, C3]
- **debris_dynamics** (ord=3): プラスチック漂流・分解モデル。マイクロプラスチック拡散 [H2, H3]
- **collection_strategy** (ord=2): 回収船配置・回収装置の運用戦略 [H4, C4]
- **route_planning** (ord=1): 回収ルート最適化。燃料効率・回収量最大化 [H5, H6]
- **impact_hypothesis** (ord=0): 回収効果・生態系影響の未検証仮説 [H7]
-/

namespace TestScenario.S267

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | el1
  | el2
  | om1
  | om2
  | dd1
  | dd2
  | cs1
  | cs2
  | rp1
  | rp2
  | ih1
  | ih2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .el1 => []
  | .el2 => []
  | .om1 => [.el1]
  | .om2 => []
  | .dd1 => [.om1, .om2]
  | .dd2 => [.om2]
  | .cs1 => [.dd1, .el1]
  | .cs2 => [.dd2, .el2]
  | .rp1 => [.cs1, .om1]
  | .rp2 => [.cs2, .dd1]
  | .ih1 => [.rp1, .rp2]
  | .ih2 => [.dd2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋環境保護の国際法規。MARPOL条約・生態系保全義務 (ord=5) -/
  | environmental_law
  /-- 海流・波浪の物理モデル。Ekman輸送・Stokes漂流 (ord=4) -/
  | oceanographic_model
  /-- プラスチック漂流・分解モデル。マイクロプラスチック拡散 (ord=3) -/
  | debris_dynamics
  /-- 回収船配置・回収装置の運用戦略 (ord=2) -/
  | collection_strategy
  /-- 回収ルート最適化。燃料効率・回収量最大化 (ord=1) -/
  | route_planning
  /-- 回収効果・生態系影響の未検証仮説 (ord=0) -/
  | impact_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .environmental_law => 5
  | .oceanographic_model => 4
  | .debris_dynamics => 3
  | .collection_strategy => 2
  | .route_planning => 1
  | .impact_hypothesis => 0

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
  bottom := .impact_hypothesis
  nontrivial := ⟨.environmental_law, .impact_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- environmental_law
  | .el1 | .el2 => .environmental_law
  -- oceanographic_model
  | .om1 | .om2 => .oceanographic_model
  -- debris_dynamics
  | .dd1 | .dd2 => .debris_dynamics
  -- collection_strategy
  | .cs1 | .cs2 => .collection_strategy
  -- route_planning
  | .rp1 | .rp2 => .route_planning
  -- impact_hypothesis
  | .ih1 | .ih2 => .impact_hypothesis

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

end TestScenario.S267

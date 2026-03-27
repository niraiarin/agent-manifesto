/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalLaw** (ord=5): 海洋汚染防止法・国際条約に基づく法的義務 [C1]
- **OceanPhysics** (ord=4): 海洋物理学の確立された知見 [C2, H1]
- **ResponseProtocol** (ord=3): 油防除の対応手順。海上保安庁の指針に基づく [C3, H2]
- **ModelDesign** (ord=2): 拡散予測モデルの設計選択 [C4, H3]
- **OperationalHypothesis** (ord=1): 運用効率に関する未検証の仮説 [C5, H4, H5]
-/

namespace TestCoverage.S177

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s177_p01
  | s177_p02
  | s177_p03
  | s177_p04
  | s177_p05
  | s177_p06
  | s177_p07
  | s177_p08
  | s177_p09
  | s177_p10
  | s177_p11
  | s177_p12
  | s177_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s177_p01 => []
  | .s177_p02 => [.s177_p01]
  | .s177_p03 => [.s177_p01]
  | .s177_p04 => [.s177_p02]
  | .s177_p05 => [.s177_p02, .s177_p03]
  | .s177_p06 => [.s177_p03]
  | .s177_p07 => [.s177_p04]
  | .s177_p08 => [.s177_p05]
  | .s177_p09 => [.s177_p04, .s177_p06]
  | .s177_p10 => [.s177_p07]
  | .s177_p11 => [.s177_p08]
  | .s177_p12 => [.s177_p09]
  | .s177_p13 => [.s177_p07, .s177_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋汚染防止法・国際条約に基づく法的義務 (ord=5) -/
  | EnvironmentalLaw
  /-- 海洋物理学の確立された知見 (ord=4) -/
  | OceanPhysics
  /-- 油防除の対応手順。海上保安庁の指針に基づく (ord=3) -/
  | ResponseProtocol
  /-- 拡散予測モデルの設計選択 (ord=2) -/
  | ModelDesign
  /-- 運用効率に関する未検証の仮説 (ord=1) -/
  | OperationalHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalLaw => 5
  | .OceanPhysics => 4
  | .ResponseProtocol => 3
  | .ModelDesign => 2
  | .OperationalHypothesis => 1

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
  bottom := .OperationalHypothesis
  nontrivial := ⟨.EnvironmentalLaw, .OperationalHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalLaw
  | .s177_p01 => .EnvironmentalLaw
  -- OceanPhysics
  | .s177_p02 | .s177_p03 => .OceanPhysics
  -- ResponseProtocol
  | .s177_p04 | .s177_p05 | .s177_p06 => .ResponseProtocol
  -- ModelDesign
  | .s177_p07 | .s177_p08 | .s177_p09 => .ModelDesign
  -- OperationalHypothesis
  | .s177_p10 | .s177_p11 | .s177_p12 | .s177_p13 => .OperationalHypothesis

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

end TestCoverage.S177

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PublicHealthProtection** (ord=4): 住民の健康被害防止・緊急警報発令の絶対的公衆衛生制約 [C1, C2]
- **EnvironmentalLaw** (ord=3): 大気汚染防止法・環境基準値・自治体条例への法的準拠 [C3, C4]
- **MonitoringPolicy** (ord=2): 観測点配置・データ収集頻度・欠損補完の監視方針 [C5, H1, H2]
- **DispersionHypothesis** (ord=1): 大気拡散モデル・気象影響・汚染源推定に関する予測仮説 [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S357

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s357_p01
  | s357_p02
  | s357_p03
  | s357_p04
  | s357_p05
  | s357_p06
  | s357_p07
  | s357_p08
  | s357_p09
  | s357_p10
  | s357_p11
  | s357_p12
  | s357_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s357_p01 => []
  | .s357_p02 => [.s357_p01]
  | .s357_p03 => [.s357_p01]
  | .s357_p04 => [.s357_p02]
  | .s357_p05 => [.s357_p03]
  | .s357_p06 => [.s357_p04]
  | .s357_p07 => [.s357_p03, .s357_p04]
  | .s357_p08 => [.s357_p05]
  | .s357_p09 => [.s357_p06]
  | .s357_p10 => [.s357_p07]
  | .s357_p11 => [.s357_p08]
  | .s357_p12 => [.s357_p09, .s357_p10]
  | .s357_p13 => [.s357_p11, .s357_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 住民の健康被害防止・緊急警報発令の絶対的公衆衛生制約 (ord=4) -/
  | PublicHealthProtection
  /-- 大気汚染防止法・環境基準値・自治体条例への法的準拠 (ord=3) -/
  | EnvironmentalLaw
  /-- 観測点配置・データ収集頻度・欠損補完の監視方針 (ord=2) -/
  | MonitoringPolicy
  /-- 大気拡散モデル・気象影響・汚染源推定に関する予測仮説 (ord=1) -/
  | DispersionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PublicHealthProtection => 4
  | .EnvironmentalLaw => 3
  | .MonitoringPolicy => 2
  | .DispersionHypothesis => 1

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
  bottom := .DispersionHypothesis
  nontrivial := ⟨.PublicHealthProtection, .DispersionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PublicHealthProtection
  | .s357_p01 | .s357_p02 => .PublicHealthProtection
  -- EnvironmentalLaw
  | .s357_p03 | .s357_p04 => .EnvironmentalLaw
  -- MonitoringPolicy
  | .s357_p05 | .s357_p06 | .s357_p07 => .MonitoringPolicy
  -- DispersionHypothesis
  | .s357_p08 | .s357_p09 | .s357_p10 | .s357_p11 | .s357_p12 | .s357_p13 => .DispersionHypothesis

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

end TestCoverage.S357

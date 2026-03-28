/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PublicSafetyObligation** (ord=4): 気象業務法・防災情報提供義務・生命安全への不変条件 [C1, C2]
- **DataQualityStandard** (ord=3): 観測データ精度・欠損値処理・品質管理基準 [C3, C4]
- **ForecastPolicy** (ord=2): 予報発表基準・警報閾値・更新頻度の予報方針 [C5, H1, H2, H3]
- **PredictionHypothesis** (ord=1): 数値予報モデル・アンサンブル予測・ダウンスケーリングの推論仮説 [H4, H5, H6, H7, H8]
-/

namespace TestCoverage.S370

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s370_p01
  | s370_p02
  | s370_p03
  | s370_p04
  | s370_p05
  | s370_p06
  | s370_p07
  | s370_p08
  | s370_p09
  | s370_p10
  | s370_p11
  | s370_p12
  | s370_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s370_p01 => []
  | .s370_p02 => [.s370_p01]
  | .s370_p03 => [.s370_p01]
  | .s370_p04 => [.s370_p02]
  | .s370_p05 => [.s370_p03, .s370_p04]
  | .s370_p06 => [.s370_p03]
  | .s370_p07 => [.s370_p04]
  | .s370_p08 => [.s370_p05, .s370_p06]
  | .s370_p09 => [.s370_p06]
  | .s370_p10 => [.s370_p07]
  | .s370_p11 => [.s370_p08, .s370_p09]
  | .s370_p12 => [.s370_p10, .s370_p11]
  | .s370_p13 => [.s370_p01, .s370_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 気象業務法・防災情報提供義務・生命安全への不変条件 (ord=4) -/
  | PublicSafetyObligation
  /-- 観測データ精度・欠損値処理・品質管理基準 (ord=3) -/
  | DataQualityStandard
  /-- 予報発表基準・警報閾値・更新頻度の予報方針 (ord=2) -/
  | ForecastPolicy
  /-- 数値予報モデル・アンサンブル予測・ダウンスケーリングの推論仮説 (ord=1) -/
  | PredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PublicSafetyObligation => 4
  | .DataQualityStandard => 3
  | .ForecastPolicy => 2
  | .PredictionHypothesis => 1

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
  bottom := .PredictionHypothesis
  nontrivial := ⟨.PublicSafetyObligation, .PredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PublicSafetyObligation
  | .s370_p01 | .s370_p02 => .PublicSafetyObligation
  -- DataQualityStandard
  | .s370_p03 | .s370_p04 | .s370_p05 => .DataQualityStandard
  -- ForecastPolicy
  | .s370_p06 | .s370_p07 | .s370_p08 => .ForecastPolicy
  -- PredictionHypothesis
  | .s370_p09 | .s370_p10 | .s370_p11 | .s370_p12 | .s370_p13 => .PredictionHypothesis

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

end TestCoverage.S370

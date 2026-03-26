/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalInvariant** (ord=6): 排水基準・化学物質規制・環境保護法に基づく絶対不変条件 [C1, C2]
- **QualityStandard** (ord=5): 色差許容範囲・堅牢度・繊維損傷防止に関する品質基準 [C3]
- **ProcessCompliance** (ord=4): ISO 9001・OEKO-TEX・顧客仕様への準拠要件 [C4, C5]
- **DyeingPolicy** (ord=3): 染料選択・温度プロファイル・助剤配合に関する工程ポリシー [H1, H2]
- **OptimizationModel** (ord=2): 色予測モデル・条件最適化・再現性向上に関する最適化モデル仮説 [H3, H4, H5]
- **AdaptiveHeuristic** (ord=1): リアルタイム調整・学習ループ・異常検知に関する適応的ヒューリスティック [H6, H7]
-/

namespace TestCoverage.S494

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s494_p01
  | s494_p02
  | s494_p03
  | s494_p04
  | s494_p05
  | s494_p06
  | s494_p07
  | s494_p08
  | s494_p09
  | s494_p10
  | s494_p11
  | s494_p12
  | s494_p13
  | s494_p14
  | s494_p15
  | s494_p16
  | s494_p17
  | s494_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s494_p01 => []
  | .s494_p02 => []
  | .s494_p03 => [.s494_p01]
  | .s494_p04 => [.s494_p02, .s494_p03]
  | .s494_p05 => [.s494_p03]
  | .s494_p06 => [.s494_p04]
  | .s494_p07 => [.s494_p05, .s494_p06]
  | .s494_p08 => [.s494_p05]
  | .s494_p09 => [.s494_p06]
  | .s494_p10 => [.s494_p07, .s494_p08]
  | .s494_p11 => [.s494_p08]
  | .s494_p12 => [.s494_p09]
  | .s494_p13 => [.s494_p10, .s494_p11]
  | .s494_p14 => [.s494_p11, .s494_p12]
  | .s494_p15 => [.s494_p11]
  | .s494_p16 => [.s494_p12]
  | .s494_p17 => [.s494_p13, .s494_p15]
  | .s494_p18 => [.s494_p14, .s494_p16, .s494_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 排水基準・化学物質規制・環境保護法に基づく絶対不変条件 (ord=6) -/
  | EnvironmentalInvariant
  /-- 色差許容範囲・堅牢度・繊維損傷防止に関する品質基準 (ord=5) -/
  | QualityStandard
  /-- ISO 9001・OEKO-TEX・顧客仕様への準拠要件 (ord=4) -/
  | ProcessCompliance
  /-- 染料選択・温度プロファイル・助剤配合に関する工程ポリシー (ord=3) -/
  | DyeingPolicy
  /-- 色予測モデル・条件最適化・再現性向上に関する最適化モデル仮説 (ord=2) -/
  | OptimizationModel
  /-- リアルタイム調整・学習ループ・異常検知に関する適応的ヒューリスティック (ord=1) -/
  | AdaptiveHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalInvariant => 6
  | .QualityStandard => 5
  | .ProcessCompliance => 4
  | .DyeingPolicy => 3
  | .OptimizationModel => 2
  | .AdaptiveHeuristic => 1

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
  bottom := .AdaptiveHeuristic
  nontrivial := ⟨.EnvironmentalInvariant, .AdaptiveHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalInvariant
  | .s494_p01 | .s494_p02 => .EnvironmentalInvariant
  -- QualityStandard
  | .s494_p03 | .s494_p04 => .QualityStandard
  -- ProcessCompliance
  | .s494_p05 | .s494_p06 | .s494_p07 => .ProcessCompliance
  -- DyeingPolicy
  | .s494_p08 | .s494_p09 | .s494_p10 => .DyeingPolicy
  -- OptimizationModel
  | .s494_p11 | .s494_p12 | .s494_p13 | .s494_p14 => .OptimizationModel
  -- AdaptiveHeuristic
  | .s494_p15 | .s494_p16 | .s494_p17 | .s494_p18 => .AdaptiveHeuristic

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

end TestCoverage.S494

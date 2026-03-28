/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **TaxLegalInvariant** (ord=6): 所得税法・法人税法・消費税法の強行規定。誤申告・脱税示唆は絶対禁止 [C1]
- **PrivacyProtectionCompliance** (ord=5): 個人情報保護法・マイナンバー法に基づく納税者情報取扱いの法的義務 [C2, C3]
- **AdvisoryBoundaryPolicy** (ord=4): 税理士法による非資格者の税務相談範囲制限。AIの助言限界の明示方針 [C4, H1]
- **DeductionClassificationRule** (ord=3): 経費・控除・特例適用の分類ルール。通達・事例データベースに基づく [C5, H2, H3]
- **OptimizationStrategyHypothesis** (ord=2): 合法的節税手法・申告タイミング・繰越控除活用の最適化仮説 [H4, H5]
- **UserInputValidationHypothesis** (ord=1): 領収書OCR精度・入力値整合性・異常値検出に関する検証仮説 [C6, H6]
-/

namespace TestCoverage.S455

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s455_p01
  | s455_p02
  | s455_p03
  | s455_p04
  | s455_p05
  | s455_p06
  | s455_p07
  | s455_p08
  | s455_p09
  | s455_p10
  | s455_p11
  | s455_p12
  | s455_p13
  | s455_p14
  | s455_p15
  | s455_p16
  | s455_p17
  | s455_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s455_p01 => []
  | .s455_p02 => [.s455_p01]
  | .s455_p03 => [.s455_p01]
  | .s455_p04 => [.s455_p02]
  | .s455_p05 => [.s455_p02, .s455_p03]
  | .s455_p06 => [.s455_p04, .s455_p05]
  | .s455_p07 => [.s455_p04]
  | .s455_p08 => [.s455_p05]
  | .s455_p09 => [.s455_p06, .s455_p07]
  | .s455_p10 => [.s455_p08, .s455_p09]
  | .s455_p11 => [.s455_p07, .s455_p09]
  | .s455_p12 => [.s455_p10]
  | .s455_p13 => [.s455_p11, .s455_p12]
  | .s455_p14 => [.s455_p08]
  | .s455_p15 => [.s455_p11]
  | .s455_p16 => [.s455_p14, .s455_p15]
  | .s455_p17 => [.s455_p12, .s455_p16]
  | .s455_p18 => [.s455_p13, .s455_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 所得税法・法人税法・消費税法の強行規定。誤申告・脱税示唆は絶対禁止 (ord=6) -/
  | TaxLegalInvariant
  /-- 個人情報保護法・マイナンバー法に基づく納税者情報取扱いの法的義務 (ord=5) -/
  | PrivacyProtectionCompliance
  /-- 税理士法による非資格者の税務相談範囲制限。AIの助言限界の明示方針 (ord=4) -/
  | AdvisoryBoundaryPolicy
  /-- 経費・控除・特例適用の分類ルール。通達・事例データベースに基づく (ord=3) -/
  | DeductionClassificationRule
  /-- 合法的節税手法・申告タイミング・繰越控除活用の最適化仮説 (ord=2) -/
  | OptimizationStrategyHypothesis
  /-- 領収書OCR精度・入力値整合性・異常値検出に関する検証仮説 (ord=1) -/
  | UserInputValidationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .TaxLegalInvariant => 6
  | .PrivacyProtectionCompliance => 5
  | .AdvisoryBoundaryPolicy => 4
  | .DeductionClassificationRule => 3
  | .OptimizationStrategyHypothesis => 2
  | .UserInputValidationHypothesis => 1

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
  bottom := .UserInputValidationHypothesis
  nontrivial := ⟨.TaxLegalInvariant, .UserInputValidationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- TaxLegalInvariant
  | .s455_p01 => .TaxLegalInvariant
  -- PrivacyProtectionCompliance
  | .s455_p02 | .s455_p03 => .PrivacyProtectionCompliance
  -- AdvisoryBoundaryPolicy
  | .s455_p04 | .s455_p05 | .s455_p06 => .AdvisoryBoundaryPolicy
  -- DeductionClassificationRule
  | .s455_p07 | .s455_p08 | .s455_p09 | .s455_p10 => .DeductionClassificationRule
  -- OptimizationStrategyHypothesis
  | .s455_p11 | .s455_p12 | .s455_p13 => .OptimizationStrategyHypothesis
  -- UserInputValidationHypothesis
  | .s455_p14 | .s455_p15 | .s455_p16 | .s455_p17 | .s455_p18 => .UserInputValidationHypothesis

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

end TestCoverage.S455

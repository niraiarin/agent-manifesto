/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ProductSafetySpec** (ord=4): 製品強度・寸法公差・材料認証の絶対仕様 [C1, C2]
- **ProcessCertification** (ord=3): ISO/ASTM AM認証・医療機器製造プロセス適合 [C3]
- **InspectionControlPolicy** (ord=2): インライン検査・リワーク判定・廃棄ルールの方針 [C4, H1, H2]
- **PrintDefectModelHypothesis** (ord=1): 層欠陥・気孔・反り変形の予測モデル仮説 [C5, H3, H4, H5, H6]
-/

namespace TestCoverage.S374

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s374_p01
  | s374_p02
  | s374_p03
  | s374_p04
  | s374_p05
  | s374_p06
  | s374_p07
  | s374_p08
  | s374_p09
  | s374_p10
  | s374_p11
  | s374_p12
  | s374_p13
  | s374_p14
  | s374_p15
  | s374_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s374_p01 => []
  | .s374_p02 => []
  | .s374_p03 => [.s374_p01, .s374_p02]
  | .s374_p04 => [.s374_p01]
  | .s374_p05 => [.s374_p03]
  | .s374_p06 => [.s374_p04]
  | .s374_p07 => [.s374_p05]
  | .s374_p08 => [.s374_p06, .s374_p07]
  | .s374_p09 => [.s374_p07, .s374_p08]
  | .s374_p10 => [.s374_p06]
  | .s374_p11 => [.s374_p07]
  | .s374_p12 => [.s374_p08]
  | .s374_p13 => [.s374_p09, .s374_p10]
  | .s374_p14 => [.s374_p11]
  | .s374_p15 => [.s374_p12, .s374_p13]
  | .s374_p16 => [.s374_p14, .s374_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 製品強度・寸法公差・材料認証の絶対仕様 (ord=4) -/
  | ProductSafetySpec
  /-- ISO/ASTM AM認証・医療機器製造プロセス適合 (ord=3) -/
  | ProcessCertification
  /-- インライン検査・リワーク判定・廃棄ルールの方針 (ord=2) -/
  | InspectionControlPolicy
  /-- 層欠陥・気孔・反り変形の予測モデル仮説 (ord=1) -/
  | PrintDefectModelHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ProductSafetySpec => 4
  | .ProcessCertification => 3
  | .InspectionControlPolicy => 2
  | .PrintDefectModelHypothesis => 1

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
  bottom := .PrintDefectModelHypothesis
  nontrivial := ⟨.ProductSafetySpec, .PrintDefectModelHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ProductSafetySpec
  | .s374_p01 | .s374_p02 | .s374_p03 => .ProductSafetySpec
  -- ProcessCertification
  | .s374_p04 | .s374_p05 => .ProcessCertification
  -- InspectionControlPolicy
  | .s374_p06 | .s374_p07 | .s374_p08 | .s374_p09 => .InspectionControlPolicy
  -- PrintDefectModelHypothesis
  | .s374_p10 | .s374_p11 | .s374_p12 | .s374_p13 | .s374_p14 | .s374_p15 | .s374_p16 => .PrintDefectModelHypothesis

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

end TestCoverage.S374

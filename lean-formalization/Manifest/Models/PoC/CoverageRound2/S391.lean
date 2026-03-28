/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyInvariant** (ord=3): 被介護者の身体的安全に関わる絶対不変条件（転倒検知・緊急通報の必須性） [C1, C2]
- **PrivacyProtection** (ord=2): 在宅環境の映像・音声データに対するプライバシー保護方針 [C3, C4]
- **CareQualityHypothesis** (ord=1): 見守り精度・介護者への通知タイミングに関する経験的仮説 [C5, H1, H2, H3, H4, H5, H6]
-/

namespace TestCoverage.S391

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s391_p01
  | s391_p02
  | s391_p03
  | s391_p04
  | s391_p05
  | s391_p06
  | s391_p07
  | s391_p08
  | s391_p09
  | s391_p10
  | s391_p11
  | s391_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s391_p01 => []
  | .s391_p02 => []
  | .s391_p03 => [.s391_p01, .s391_p02]
  | .s391_p04 => [.s391_p01]
  | .s391_p05 => [.s391_p02]
  | .s391_p06 => [.s391_p04, .s391_p05]
  | .s391_p07 => [.s391_p03]
  | .s391_p08 => [.s391_p04]
  | .s391_p09 => [.s391_p07]
  | .s391_p10 => [.s391_p08]
  | .s391_p11 => [.s391_p06]
  | .s391_p12 => [.s391_p09, .s391_p10, .s391_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 被介護者の身体的安全に関わる絶対不変条件（転倒検知・緊急通報の必須性） (ord=3) -/
  | SafetyInvariant
  /-- 在宅環境の映像・音声データに対するプライバシー保護方針 (ord=2) -/
  | PrivacyProtection
  /-- 見守り精度・介護者への通知タイミングに関する経験的仮説 (ord=1) -/
  | CareQualityHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyInvariant => 3
  | .PrivacyProtection => 2
  | .CareQualityHypothesis => 1

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
  bottom := .CareQualityHypothesis
  nontrivial := ⟨.SafetyInvariant, .CareQualityHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyInvariant
  | .s391_p01 | .s391_p02 | .s391_p03 => .SafetyInvariant
  -- PrivacyProtection
  | .s391_p04 | .s391_p05 | .s391_p06 => .PrivacyProtection
  -- CareQualityHypothesis
  | .s391_p07 | .s391_p08 | .s391_p09 | .s391_p10 | .s391_p11 | .s391_p12 => .CareQualityHypothesis

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

end TestCoverage.S391

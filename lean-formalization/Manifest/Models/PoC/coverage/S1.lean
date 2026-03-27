/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyInvariant** (ord=5): 人命に関わる安全制約。いかなる状況でも違反不可 [C1, C2]
- **RegulatoryCompliance** (ord=4): 法令・規制への準拠。外部権威に基づく [C3, H1]
- **ServicePolicy** (ord=3): サービス品質に関するポリシー。事業判断で変更可能 [C4, H2]
- **OptimizationRule** (ord=2): 配車効率の最適化ルール。データに基づき調整可能 [H3, H4]
- **UserPreference** (ord=1): 乗客の好みに基づく調整。個別に変動する [C5, H5]
-/

namespace TestCoverage.S1

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s1_p01
  | s1_p02
  | s1_p03
  | s1_p04
  | s1_p05
  | s1_p06
  | s1_p07
  | s1_p08
  | s1_p09
  | s1_p10
  | s1_p11
  | s1_p12
  | s1_p13
  | s1_p14
  | s1_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s1_p01 => []
  | .s1_p02 => []
  | .s1_p03 => []
  | .s1_p04 => [.s1_p01]
  | .s1_p05 => [.s1_p02]
  | .s1_p06 => [.s1_p01, .s1_p03]
  | .s1_p07 => [.s1_p04]
  | .s1_p08 => [.s1_p05]
  | .s1_p09 => [.s1_p04, .s1_p06]
  | .s1_p10 => [.s1_p07]
  | .s1_p11 => [.s1_p08, .s1_p09]
  | .s1_p12 => [.s1_p07]
  | .s1_p13 => [.s1_p10]
  | .s1_p14 => [.s1_p11]
  | .s1_p15 => [.s1_p12, .s1_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人命に関わる安全制約。いかなる状況でも違反不可 (ord=5) -/
  | SafetyInvariant
  /-- 法令・規制への準拠。外部権威に基づく (ord=4) -/
  | RegulatoryCompliance
  /-- サービス品質に関するポリシー。事業判断で変更可能 (ord=3) -/
  | ServicePolicy
  /-- 配車効率の最適化ルール。データに基づき調整可能 (ord=2) -/
  | OptimizationRule
  /-- 乗客の好みに基づく調整。個別に変動する (ord=1) -/
  | UserPreference
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyInvariant => 5
  | .RegulatoryCompliance => 4
  | .ServicePolicy => 3
  | .OptimizationRule => 2
  | .UserPreference => 1

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
  bottom := .UserPreference
  nontrivial := ⟨.SafetyInvariant, .UserPreference, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyInvariant
  | .s1_p01 | .s1_p02 | .s1_p03 => .SafetyInvariant
  -- RegulatoryCompliance
  | .s1_p04 | .s1_p05 | .s1_p06 => .RegulatoryCompliance
  -- ServicePolicy
  | .s1_p07 | .s1_p08 | .s1_p09 => .ServicePolicy
  -- OptimizationRule
  | .s1_p10 | .s1_p11 | .s1_p12 => .OptimizationRule
  -- UserPreference
  | .s1_p13 | .s1_p14 | .s1_p15 => .UserPreference

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

end TestCoverage.S1

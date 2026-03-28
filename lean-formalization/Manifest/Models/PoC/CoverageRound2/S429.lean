/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafetyConstraint** (ord=2): アナフィラキシーリスク過小評価禁止・医師最終確認義務・患者同意必須に関する安全制約 [C1, C2, C3, C4, C5]
- **AllergyHypothesis** (ord=1): 遺伝的素因・食物抗原交差反応・環境曝露累積・腸内菌叢変化に関するアレルギー発症仮説 [H1, H2, H3, H4, H5, H6]
-/

namespace TestCoverage.S429

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s429_p01
  | s429_p02
  | s429_p03
  | s429_p04
  | s429_p05
  | s429_p06
  | s429_p07
  | s429_p08
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s429_p01 => []
  | .s429_p02 => [.s429_p01]
  | .s429_p03 => [.s429_p01]
  | .s429_p04 => [.s429_p02]
  | .s429_p05 => [.s429_p03]
  | .s429_p06 => [.s429_p04]
  | .s429_p07 => [.s429_p05]
  | .s429_p08 => [.s429_p06, .s429_p07]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- アナフィラキシーリスク過小評価禁止・医師最終確認義務・患者同意必須に関する安全制約 (ord=2) -/
  | PatientSafetyConstraint
  /-- 遺伝的素因・食物抗原交差反応・環境曝露累積・腸内菌叢変化に関するアレルギー発症仮説 (ord=1) -/
  | AllergyHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafetyConstraint => 2
  | .AllergyHypothesis => 1

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
  bottom := .AllergyHypothesis
  nontrivial := ⟨.PatientSafetyConstraint, .AllergyHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PatientSafetyConstraint
  | .s429_p01 | .s429_p02 | .s429_p03 => .PatientSafetyConstraint
  -- AllergyHypothesis
  | .s429_p04 | .s429_p05 | .s429_p06 | .s429_p07 | .s429_p08 => .AllergyHypothesis

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

end TestCoverage.S429

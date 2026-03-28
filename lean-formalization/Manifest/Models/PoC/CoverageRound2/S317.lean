/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **patient_safety_invariant** (ord=4): 患者安全・人間最終判断・データローカリティの絶対要件 [C1, C2, C5]
- **clinical_standard** (ord=3): 臨床ガイドライン・標準スコアリングへの準拠 [C3, C4]
- **alert_model** (ord=2): アラート生成・優先度付け・説明生成のモデル [C6, C7, H1, H2, H3]
- **learning_infrastructure** (ord=1): モデル学習・更新・施設間共有の仮説 [H4, H5]
-/

namespace TestCoverage.S317

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s317_p01
  | s317_p02
  | s317_p03
  | s317_p04
  | s317_p05
  | s317_p06
  | s317_p07
  | s317_p08
  | s317_p09
  | s317_p10
  | s317_p11
  | s317_p12
  | s317_p13
  | s317_p14
  | s317_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s317_p01 => []
  | .s317_p02 => [.s317_p01]
  | .s317_p03 => []
  | .s317_p04 => [.s317_p03]
  | .s317_p05 => []
  | .s317_p06 => [.s317_p01, .s317_p03]
  | .s317_p07 => [.s317_p02, .s317_p06]
  | .s317_p08 => [.s317_p03, .s317_p06]
  | .s317_p09 => [.s317_p06, .s317_p08]
  | .s317_p10 => [.s317_p07, .s317_p09]
  | .s317_p11 => [.s317_p08, .s317_p09]
  | .s317_p12 => [.s317_p03, .s317_p05, .s317_p11]
  | .s317_p13 => [.s317_p11]
  | .s317_p14 => [.s317_p07, .s317_p10]
  | .s317_p15 => [.s317_p12, .s317_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者安全・人間最終判断・データローカリティの絶対要件 (ord=4) -/
  | patient_safety_invariant
  /-- 臨床ガイドライン・標準スコアリングへの準拠 (ord=3) -/
  | clinical_standard
  /-- アラート生成・優先度付け・説明生成のモデル (ord=2) -/
  | alert_model
  /-- モデル学習・更新・施設間共有の仮説 (ord=1) -/
  | learning_infrastructure
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .patient_safety_invariant => 4
  | .clinical_standard => 3
  | .alert_model => 2
  | .learning_infrastructure => 1

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
  bottom := .learning_infrastructure
  nontrivial := ⟨.patient_safety_invariant, .learning_infrastructure, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- patient_safety_invariant
  | .s317_p01 | .s317_p02 | .s317_p05 => .patient_safety_invariant
  -- clinical_standard
  | .s317_p03 | .s317_p04 => .clinical_standard
  -- alert_model
  | .s317_p06 | .s317_p07 | .s317_p08 | .s317_p09 | .s317_p10 | .s317_p14 => .alert_model
  -- learning_infrastructure
  | .s317_p11 | .s317_p12 | .s317_p13 | .s317_p15 => .learning_infrastructure

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

end TestCoverage.S317

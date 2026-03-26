/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **patientSafety** (ord=4): 患者生命・安全に直結する不変条件 [C1, C3, C7]
- **regulatory** (ord=3): 法規制・承認に関する制約 [C2, C5, C6]
- **clinical** (ord=2): 臨床運用に関する方針 [C4, C8, H2, H5]
- **modelStrategy** (ord=1): AIモデルの学習・推論戦略 [H1, H3, H6]
- **hypothesis** (ord=0): 未検証の仮説 [H4]
-/

namespace MedicalImaging

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | ps1
  | ps2
  | ps3
  | reg1
  | reg2
  | reg3
  | clin1
  | clin2
  | clin3
  | clin4
  | mod1
  | mod2
  | mod3
  | mod4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .ps1 => []
  | .ps2 => []
  | .ps3 => [.ps1]
  | .reg1 => [.ps2]
  | .reg2 => [.ps1]
  | .reg3 => [.ps2]
  | .clin1 => [.ps1, .reg2]
  | .clin2 => [.reg1]
  | .clin3 => [.ps2, .reg3]
  | .clin4 => [.ps3]
  | .mod1 => [.clin1, .reg2]
  | .mod2 => [.reg3, .clin3]
  | .mod3 => [.mod1]
  | .mod4 => [.clin1, .clin2]
  | .hyp1 => [.reg2]
  | .hyp2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者生命・安全に直結する不変条件 (ord=4) -/
  | patientSafety
  /-- 法規制・承認に関する制約 (ord=3) -/
  | regulatory
  /-- 臨床運用に関する方針 (ord=2) -/
  | clinical
  /-- AIモデルの学習・推論戦略 (ord=1) -/
  | modelStrategy
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .patientSafety => 4
  | .regulatory => 3
  | .clinical => 2
  | .modelStrategy => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.patientSafety, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- patientSafety
  | .ps1 | .ps2 | .ps3 => .patientSafety
  -- regulatory
  | .reg1 | .reg2 | .reg3 => .regulatory
  -- clinical
  | .clin1 | .clin2 | .clin3 | .clin4 => .clinical
  -- modelStrategy
  | .mod1 | .mod2 | .mod3 | .mod4 => .modelStrategy
  -- hypothesis
  | .hyp1 | .hyp2 => .hypothesis

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

end MedicalImaging

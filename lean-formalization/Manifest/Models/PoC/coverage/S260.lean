/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **regulatory** (ord=4): GMP・薬事規制に基づく法的制約。違反は製品回収と行政処分。 [C1, C5]
- **quality** (ord=3): 品質管理部門の承認とバリデーション要件。 [C2, C4]
- **traceability** (ord=2): データ完全性と監査対応の記録要件。 [C3, C6]
- **optimization** (ord=1): AIによる工程最適化の手法。技術進歩に応じて改善可能。 [H1, H2, H4]
- **hypothesis** (ord=0): 未検証の仮説。パイロットプラントで検証が必要。 [H3]
-/

namespace Scenario260

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | reg1
  | reg2
  | reg3
  | qua1
  | qua2
  | qua3
  | trc1
  | trc2
  | trc3
  | trc4
  | opt1
  | opt2
  | opt3
  | opt4
  | opt5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .reg1 => []
  | .reg2 => []
  | .reg3 => []
  | .qua1 => [.reg1]
  | .qua2 => [.reg1, .reg2]
  | .qua3 => [.qua1, .qua2]
  | .trc1 => [.reg1, .qua1]
  | .trc2 => [.qua2]
  | .trc3 => [.trc1, .trc2]
  | .trc4 => [.qua3, .trc1]
  | .opt1 => [.reg2, .qua1]
  | .opt2 => [.qua3, .trc2]
  | .opt3 => [.qua2, .trc1]
  | .opt4 => [.opt1, .opt2]
  | .opt5 => [.opt3, .opt4]
  | .hyp1 => [.trc1, .trc3]
  | .hyp2 => [.opt4, .hyp1]
  | .hyp3 => [.opt5, .trc4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- GMP・薬事規制に基づく法的制約。違反は製品回収と行政処分。 (ord=4) -/
  | regulatory
  /-- 品質管理部門の承認とバリデーション要件。 (ord=3) -/
  | quality
  /-- データ完全性と監査対応の記録要件。 (ord=2) -/
  | traceability
  /-- AIによる工程最適化の手法。技術進歩に応じて改善可能。 (ord=1) -/
  | optimization
  /-- 未検証の仮説。パイロットプラントで検証が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .regulatory => 4
  | .quality => 3
  | .traceability => 2
  | .optimization => 1
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
  nontrivial := ⟨.regulatory, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- regulatory
  | .reg1 | .reg2 | .reg3 => .regulatory
  -- quality
  | .qua1 | .qua2 | .qua3 => .quality
  -- traceability
  | .trc1 | .trc2 | .trc3 | .trc4 => .traceability
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 => .optimization
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 => .hypothesis

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

end Scenario260

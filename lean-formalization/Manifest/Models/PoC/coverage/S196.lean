/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **welfare** (ord=6): 動物福祉の絶対原則。全ての活動はこの制約下にある。 [C1]
- **genetics** (ord=5): 遺伝的多様性の維持に関する生物学的制約。 [C2]
- **veterinary** (ord=4): 獣医学的判断の権限と安全基準。 [C3]
- **regulation** (ord=3): 国際的な種保存規制。外部依存。 [C4]
- **monitoring** (ord=2): データ収集の方法論的制約。非侵襲性が前提。 [C5, H1]
- **algorithm** (ord=1): AIが最適化する分析・推奨アルゴリズム。 [H2, H3]
- **hypothesis** (ord=0): 運用データで検証が必要な仮説。 [H4]
-/

namespace Scenario196

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | wel1
  | wel2
  | gen1
  | gen2
  | vet1
  | vet2
  | vet3
  | reg1
  | reg2
  | mon1
  | mon2
  | mon3
  | algo1
  | algo2
  | algo3
  | algo4
  | algo5
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .wel1 => []
  | .wel2 => []
  | .gen1 => [.wel1]
  | .gen2 => [.wel1, .wel2]
  | .vet1 => [.wel1]
  | .vet2 => [.gen1, .wel2]
  | .vet3 => [.vet1]
  | .reg1 => [.gen1, .gen2]
  | .reg2 => [.vet2]
  | .mon1 => [.wel1, .wel2]
  | .mon2 => [.mon1]
  | .mon3 => [.vet3, .mon1]
  | .algo1 => [.gen1, .gen2, .reg1]
  | .algo2 => [.mon2, .mon3]
  | .algo3 => [.vet1, .mon2]
  | .algo4 => [.algo1, .algo2]
  | .algo5 => [.reg1, .reg2, .algo1]
  | .hyp1 => [.reg1]
  | .hyp2 => [.algo4, .algo5]
  | .hyp3 => [.algo3]
  | .hyp4 => [.hyp1, .hyp2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 動物福祉の絶対原則。全ての活動はこの制約下にある。 (ord=6) -/
  | welfare
  /-- 遺伝的多様性の維持に関する生物学的制約。 (ord=5) -/
  | genetics
  /-- 獣医学的判断の権限と安全基準。 (ord=4) -/
  | veterinary
  /-- 国際的な種保存規制。外部依存。 (ord=3) -/
  | regulation
  /-- データ収集の方法論的制約。非侵襲性が前提。 (ord=2) -/
  | monitoring
  /-- AIが最適化する分析・推奨アルゴリズム。 (ord=1) -/
  | algorithm
  /-- 運用データで検証が必要な仮説。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .welfare => 6
  | .genetics => 5
  | .veterinary => 4
  | .regulation => 3
  | .monitoring => 2
  | .algorithm => 1
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
  nontrivial := ⟨.welfare, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- welfare
  | .wel1 | .wel2 => .welfare
  -- genetics
  | .gen1 | .gen2 => .genetics
  -- veterinary
  | .vet1 | .vet2 | .vet3 => .veterinary
  -- regulation
  | .reg1 | .reg2 => .regulation
  -- monitoring
  | .mon1 | .mon2 | .mon3 => .monitoring
  -- algorithm
  | .algo1 | .algo2 | .algo3 | .algo4 | .algo5 => .algorithm
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 | .hyp4 => .hypothesis

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

end Scenario196

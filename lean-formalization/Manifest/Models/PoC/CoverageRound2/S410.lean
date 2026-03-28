/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ScientificIntegrityInvariant** (ord=4): 予測結果の科学的整合性・物理法則との整合性を保証する不変制約 [C1, C2]
- **ResearchEthicsCompliance** (ord=3): 研究倫理・データ帰属・再現可能性要件への準拠。学術標準 [C3, H1]
- **ModelValidationPolicy** (ord=2): 予測モデルの検証・ベンチマーク・不確実性定量化ポリシー。品質保証規則 [C4, H2, H3]
- **ExplorationHypothesis** (ord=1): 新材料設計空間探索・マルチフィデリティ学習の仮説。実験と計算の統合 [H4, H5, H6]
-/

namespace TestCoverage.S410

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s410_p01
  | s410_p02
  | s410_p03
  | s410_p04
  | s410_p05
  | s410_p06
  | s410_p07
  | s410_p08
  | s410_p09
  | s410_p10
  | s410_p11
  | s410_p12
  | s410_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s410_p01 => []
  | .s410_p02 => []
  | .s410_p03 => [.s410_p01, .s410_p02]
  | .s410_p04 => [.s410_p01]
  | .s410_p05 => [.s410_p02]
  | .s410_p06 => [.s410_p03]
  | .s410_p07 => [.s410_p04]
  | .s410_p08 => [.s410_p05]
  | .s410_p09 => [.s410_p06]
  | .s410_p10 => [.s410_p07, .s410_p08]
  | .s410_p11 => [.s410_p07]
  | .s410_p12 => [.s410_p08]
  | .s410_p13 => [.s410_p09, .s410_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 予測結果の科学的整合性・物理法則との整合性を保証する不変制約 (ord=4) -/
  | ScientificIntegrityInvariant
  /-- 研究倫理・データ帰属・再現可能性要件への準拠。学術標準 (ord=3) -/
  | ResearchEthicsCompliance
  /-- 予測モデルの検証・ベンチマーク・不確実性定量化ポリシー。品質保証規則 (ord=2) -/
  | ModelValidationPolicy
  /-- 新材料設計空間探索・マルチフィデリティ学習の仮説。実験と計算の統合 (ord=1) -/
  | ExplorationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ScientificIntegrityInvariant => 4
  | .ResearchEthicsCompliance => 3
  | .ModelValidationPolicy => 2
  | .ExplorationHypothesis => 1

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
  bottom := .ExplorationHypothesis
  nontrivial := ⟨.ScientificIntegrityInvariant, .ExplorationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ScientificIntegrityInvariant
  | .s410_p01 | .s410_p02 | .s410_p03 => .ScientificIntegrityInvariant
  -- ResearchEthicsCompliance
  | .s410_p04 | .s410_p05 | .s410_p06 => .ResearchEthicsCompliance
  -- ModelValidationPolicy
  | .s410_p07 | .s410_p08 | .s410_p09 | .s410_p10 => .ModelValidationPolicy
  -- ExplorationHypothesis
  | .s410_p11 | .s410_p12 | .s410_p13 => .ExplorationHypothesis

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

end TestCoverage.S410

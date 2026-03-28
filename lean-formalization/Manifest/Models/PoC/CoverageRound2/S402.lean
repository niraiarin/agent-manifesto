/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **TransactionIntegrityInvariant** (ord=5): 決済トランザクションの原子性・一貫性・永続性。資金消失を防ぐ不変制約 [C1, C2]
- **FinancialRegulatoryCompliance** (ord=4): 金融規制・PCI-DSS・AML法令への準拠。外部権威に基づく義務 [C3, H1]
- **FraudPreventionPolicy** (ord=3): 不正検知・防止ポリシー。リスク管理判断に基づく運用規則 [C4, H2]
- **PerformanceOptimization** (ord=2): レイテンシ・スループット最適化。SLA達成のための調整可能ルール [C5, H3, H4]
- **PersonalizationHypothesis** (ord=1): ユーザー行動パターンに基づく個別化仮説。機械学習で継続的に更新 [H5, H6, H7]
-/

namespace TestCoverage.S402

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s402_p01
  | s402_p02
  | s402_p03
  | s402_p04
  | s402_p05
  | s402_p06
  | s402_p07
  | s402_p08
  | s402_p09
  | s402_p10
  | s402_p11
  | s402_p12
  | s402_p13
  | s402_p14
  | s402_p15
  | s402_p16
  | s402_p17
  | s402_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s402_p01 => []
  | .s402_p02 => []
  | .s402_p03 => [.s402_p01, .s402_p02]
  | .s402_p04 => [.s402_p01]
  | .s402_p05 => [.s402_p02]
  | .s402_p06 => [.s402_p03]
  | .s402_p07 => [.s402_p04]
  | .s402_p08 => [.s402_p05]
  | .s402_p09 => [.s402_p06]
  | .s402_p10 => [.s402_p07]
  | .s402_p11 => [.s402_p08]
  | .s402_p12 => [.s402_p09]
  | .s402_p13 => [.s402_p10, .s402_p11]
  | .s402_p14 => [.s402_p10]
  | .s402_p15 => [.s402_p11]
  | .s402_p16 => [.s402_p12]
  | .s402_p17 => [.s402_p13, .s402_p14]
  | .s402_p18 => [.s402_p15, .s402_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 決済トランザクションの原子性・一貫性・永続性。資金消失を防ぐ不変制約 (ord=5) -/
  | TransactionIntegrityInvariant
  /-- 金融規制・PCI-DSS・AML法令への準拠。外部権威に基づく義務 (ord=4) -/
  | FinancialRegulatoryCompliance
  /-- 不正検知・防止ポリシー。リスク管理判断に基づく運用規則 (ord=3) -/
  | FraudPreventionPolicy
  /-- レイテンシ・スループット最適化。SLA達成のための調整可能ルール (ord=2) -/
  | PerformanceOptimization
  /-- ユーザー行動パターンに基づく個別化仮説。機械学習で継続的に更新 (ord=1) -/
  | PersonalizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .TransactionIntegrityInvariant => 5
  | .FinancialRegulatoryCompliance => 4
  | .FraudPreventionPolicy => 3
  | .PerformanceOptimization => 2
  | .PersonalizationHypothesis => 1

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
  bottom := .PersonalizationHypothesis
  nontrivial := ⟨.TransactionIntegrityInvariant, .PersonalizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- TransactionIntegrityInvariant
  | .s402_p01 | .s402_p02 | .s402_p03 => .TransactionIntegrityInvariant
  -- FinancialRegulatoryCompliance
  | .s402_p04 | .s402_p05 | .s402_p06 => .FinancialRegulatoryCompliance
  -- FraudPreventionPolicy
  | .s402_p07 | .s402_p08 | .s402_p09 => .FraudPreventionPolicy
  -- PerformanceOptimization
  | .s402_p10 | .s402_p11 | .s402_p12 | .s402_p13 => .PerformanceOptimization
  -- PersonalizationHypothesis
  | .s402_p14 | .s402_p15 | .s402_p16 | .s402_p17 | .s402_p18 => .PersonalizationHypothesis

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

end TestCoverage.S402

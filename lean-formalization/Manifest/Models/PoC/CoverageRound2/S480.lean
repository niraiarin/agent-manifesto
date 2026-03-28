/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **KeySecurityAndRegulatoryInvariant** (ord=4): 秘密鍵保護・KYC/AML規制・資金決済法準拠の絶対条件 [C1, C2, C3]
- **TransactionValidationPolicy** (ord=3): 署名検証・二重送金防止・トランザクション承認ポリシー [C4, C5]
- **RiskMonitoringPolicy** (ord=2): 異常取引検知・ブラックリスト照合・アラート管理の方針 [C6, H1, H2]
- **MarketRiskHypothesis** (ord=1): 価格変動・流動性リスク・ポートフォリオ最適化の推論仮説 [H3, H4, H5]
-/

namespace TestCoverage.S480

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s480_p01
  | s480_p02
  | s480_p03
  | s480_p04
  | s480_p05
  | s480_p06
  | s480_p07
  | s480_p08
  | s480_p09
  | s480_p10
  | s480_p11
  | s480_p12
  | s480_p13
  | s480_p14
  | s480_p15
  | s480_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s480_p01 => []
  | .s480_p02 => []
  | .s480_p03 => [.s480_p01, .s480_p02]
  | .s480_p04 => [.s480_p01]
  | .s480_p05 => [.s480_p02]
  | .s480_p06 => [.s480_p04, .s480_p05]
  | .s480_p07 => [.s480_p03]
  | .s480_p08 => [.s480_p05]
  | .s480_p09 => [.s480_p06, .s480_p07]
  | .s480_p10 => [.s480_p07]
  | .s480_p11 => [.s480_p08]
  | .s480_p12 => [.s480_p09, .s480_p10]
  | .s480_p13 => [.s480_p10, .s480_p11]
  | .s480_p14 => [.s480_p08, .s480_p09]
  | .s480_p15 => [.s480_p04, .s480_p06]
  | .s480_p16 => [.s480_p03]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 秘密鍵保護・KYC/AML規制・資金決済法準拠の絶対条件 (ord=4) -/
  | KeySecurityAndRegulatoryInvariant
  /-- 署名検証・二重送金防止・トランザクション承認ポリシー (ord=3) -/
  | TransactionValidationPolicy
  /-- 異常取引検知・ブラックリスト照合・アラート管理の方針 (ord=2) -/
  | RiskMonitoringPolicy
  /-- 価格変動・流動性リスク・ポートフォリオ最適化の推論仮説 (ord=1) -/
  | MarketRiskHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .KeySecurityAndRegulatoryInvariant => 4
  | .TransactionValidationPolicy => 3
  | .RiskMonitoringPolicy => 2
  | .MarketRiskHypothesis => 1

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
  bottom := .MarketRiskHypothesis
  nontrivial := ⟨.KeySecurityAndRegulatoryInvariant, .MarketRiskHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- KeySecurityAndRegulatoryInvariant
  | .s480_p01 | .s480_p02 | .s480_p03 | .s480_p16 => .KeySecurityAndRegulatoryInvariant
  -- TransactionValidationPolicy
  | .s480_p04 | .s480_p05 | .s480_p06 | .s480_p15 => .TransactionValidationPolicy
  -- RiskMonitoringPolicy
  | .s480_p07 | .s480_p08 | .s480_p09 | .s480_p14 => .RiskMonitoringPolicy
  -- MarketRiskHypothesis
  | .s480_p10 | .s480_p11 | .s480_p12 | .s480_p13 => .MarketRiskHypothesis

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

end TestCoverage.S480

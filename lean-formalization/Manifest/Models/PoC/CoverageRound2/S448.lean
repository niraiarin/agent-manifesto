/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **DemocraticIntegrityInvariant** (ord=5): 一人一票・無記名秘密投票・改竄不可能性の民主主義的絶対不変条件 [C1, C2]
- **LegalFrameworkInvariant** (ord=4): 公職選挙法・個人情報保護法・選挙管理委員会規則への適合 [C3, C4]
- **SecurityAuditPolicy** (ord=3): ペネトレーションテスト・監査ログ・改竄検知の不正防止方針 [C5, H1]
- **AccessibilityOperationPolicy** (ord=2): 障害者対応・多言語サポート・操作性確保の運用方針 [C6, H2]
- **SystemReliabilityHypothesis** (ord=1): 投票集計精度・システム可用性・障害復旧時間に関する仮説 [C7, H3, H4]
-/

namespace TestCoverage.S448

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s448_p01
  | s448_p02
  | s448_p03
  | s448_p04
  | s448_p05
  | s448_p06
  | s448_p07
  | s448_p08
  | s448_p09
  | s448_p10
  | s448_p11
  | s448_p12
  | s448_p13
  | s448_p14
  | s448_p15
  | s448_p16
  | s448_p17
  | s448_p18
  | s448_p19
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s448_p01 => []
  | .s448_p02 => [.s448_p01]
  | .s448_p03 => [.s448_p01, .s448_p02]
  | .s448_p04 => [.s448_p01]
  | .s448_p05 => [.s448_p02]
  | .s448_p06 => [.s448_p04, .s448_p05]
  | .s448_p07 => [.s448_p03]
  | .s448_p08 => [.s448_p06, .s448_p07]
  | .s448_p09 => [.s448_p07, .s448_p08]
  | .s448_p10 => [.s448_p04]
  | .s448_p11 => [.s448_p08, .s448_p10]
  | .s448_p12 => [.s448_p10, .s448_p11]
  | .s448_p13 => [.s448_p07]
  | .s448_p14 => [.s448_p09, .s448_p13]
  | .s448_p15 => [.s448_p11]
  | .s448_p16 => [.s448_p14, .s448_p15]
  | .s448_p17 => [.s448_p12]
  | .s448_p18 => [.s448_p16, .s448_p17]
  | .s448_p19 => [.s448_p18]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 一人一票・無記名秘密投票・改竄不可能性の民主主義的絶対不変条件 (ord=5) -/
  | DemocraticIntegrityInvariant
  /-- 公職選挙法・個人情報保護法・選挙管理委員会規則への適合 (ord=4) -/
  | LegalFrameworkInvariant
  /-- ペネトレーションテスト・監査ログ・改竄検知の不正防止方針 (ord=3) -/
  | SecurityAuditPolicy
  /-- 障害者対応・多言語サポート・操作性確保の運用方針 (ord=2) -/
  | AccessibilityOperationPolicy
  /-- 投票集計精度・システム可用性・障害復旧時間に関する仮説 (ord=1) -/
  | SystemReliabilityHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .DemocraticIntegrityInvariant => 5
  | .LegalFrameworkInvariant => 4
  | .SecurityAuditPolicy => 3
  | .AccessibilityOperationPolicy => 2
  | .SystemReliabilityHypothesis => 1

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
  bottom := .SystemReliabilityHypothesis
  nontrivial := ⟨.DemocraticIntegrityInvariant, .SystemReliabilityHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- DemocraticIntegrityInvariant
  | .s448_p01 | .s448_p02 | .s448_p03 => .DemocraticIntegrityInvariant
  -- LegalFrameworkInvariant
  | .s448_p04 | .s448_p05 | .s448_p06 => .LegalFrameworkInvariant
  -- SecurityAuditPolicy
  | .s448_p07 | .s448_p08 | .s448_p09 => .SecurityAuditPolicy
  -- AccessibilityOperationPolicy
  | .s448_p10 | .s448_p11 | .s448_p12 => .AccessibilityOperationPolicy
  -- SystemReliabilityHypothesis
  | .s448_p13 | .s448_p14 | .s448_p15 | .s448_p16 | .s448_p17 | .s448_p18 | .s448_p19 => .SystemReliabilityHypothesis

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

end TestCoverage.S448

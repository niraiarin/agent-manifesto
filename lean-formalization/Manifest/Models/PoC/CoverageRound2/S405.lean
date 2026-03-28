/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **CryptographicSecurityInvariant** (ord=6): 暗号強度・鍵の機密性を保証する絶対不変制約。数学的安全保証 [C1, C2]
- **RegulatoryKeyManagement** (ord=5): FIPS 140-2・Common Criteria等規格準拠。政府・規制当局の要求 [C3, H1]
- **AccessControlPolicy** (ord=4): 鍵へのアクセス制御・最小権限原則。セキュリティポリシーに基づく [C4, H2]
- **LifecycleManagementPolicy** (ord=3): 鍵の生成・更新・廃棄ライフサイクル管理。運用規則 [C5, H3]
- **AuditAndMonitoringPolicy** (ord=2): 鍵使用の監査ログ・異常検知ポリシー。コンプライアンス記録 [C6, H4]
- **OptimizationHypothesis** (ord=1): 鍵管理パフォーマンス・可用性改善の仮説。運用データで検証 [H5]
-/

namespace TestCoverage.S405

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s405_p01
  | s405_p02
  | s405_p03
  | s405_p04
  | s405_p05
  | s405_p06
  | s405_p07
  | s405_p08
  | s405_p09
  | s405_p10
  | s405_p11
  | s405_p12
  | s405_p13
  | s405_p14
  | s405_p15
  | s405_p16
  | s405_p17
  | s405_p18
  | s405_p19
  | s405_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s405_p01 => []
  | .s405_p02 => []
  | .s405_p03 => [.s405_p01, .s405_p02]
  | .s405_p04 => [.s405_p01]
  | .s405_p05 => [.s405_p02]
  | .s405_p06 => [.s405_p03]
  | .s405_p07 => [.s405_p04]
  | .s405_p08 => [.s405_p05]
  | .s405_p09 => [.s405_p06]
  | .s405_p10 => [.s405_p07]
  | .s405_p11 => [.s405_p08]
  | .s405_p12 => [.s405_p09]
  | .s405_p13 => [.s405_p10, .s405_p11]
  | .s405_p14 => [.s405_p10]
  | .s405_p15 => [.s405_p11]
  | .s405_p16 => [.s405_p12, .s405_p13]
  | .s405_p17 => [.s405_p14]
  | .s405_p18 => [.s405_p15]
  | .s405_p19 => [.s405_p16]
  | .s405_p20 => [.s405_p17, .s405_p18, .s405_p19]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 暗号強度・鍵の機密性を保証する絶対不変制約。数学的安全保証 (ord=6) -/
  | CryptographicSecurityInvariant
  /-- FIPS 140-2・Common Criteria等規格準拠。政府・規制当局の要求 (ord=5) -/
  | RegulatoryKeyManagement
  /-- 鍵へのアクセス制御・最小権限原則。セキュリティポリシーに基づく (ord=4) -/
  | AccessControlPolicy
  /-- 鍵の生成・更新・廃棄ライフサイクル管理。運用規則 (ord=3) -/
  | LifecycleManagementPolicy
  /-- 鍵使用の監査ログ・異常検知ポリシー。コンプライアンス記録 (ord=2) -/
  | AuditAndMonitoringPolicy
  /-- 鍵管理パフォーマンス・可用性改善の仮説。運用データで検証 (ord=1) -/
  | OptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .CryptographicSecurityInvariant => 6
  | .RegulatoryKeyManagement => 5
  | .AccessControlPolicy => 4
  | .LifecycleManagementPolicy => 3
  | .AuditAndMonitoringPolicy => 2
  | .OptimizationHypothesis => 1

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
  bottom := .OptimizationHypothesis
  nontrivial := ⟨.CryptographicSecurityInvariant, .OptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- CryptographicSecurityInvariant
  | .s405_p01 | .s405_p02 | .s405_p03 => .CryptographicSecurityInvariant
  -- RegulatoryKeyManagement
  | .s405_p04 | .s405_p05 | .s405_p06 => .RegulatoryKeyManagement
  -- AccessControlPolicy
  | .s405_p07 | .s405_p08 | .s405_p09 => .AccessControlPolicy
  -- LifecycleManagementPolicy
  | .s405_p10 | .s405_p11 | .s405_p12 | .s405_p13 => .LifecycleManagementPolicy
  -- AuditAndMonitoringPolicy
  | .s405_p14 | .s405_p15 | .s405_p16 => .AuditAndMonitoringPolicy
  -- OptimizationHypothesis
  | .s405_p17 | .s405_p18 | .s405_p19 | .s405_p20 => .OptimizationHypothesis

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

end TestCoverage.S405

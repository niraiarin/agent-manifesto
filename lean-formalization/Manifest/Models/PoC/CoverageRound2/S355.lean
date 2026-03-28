/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SecurityInvariant** (ord=5): 機密情報保護・不正アクセス禁止の絶対セキュリティ制約 [C1, C2]
- **ComplianceRequirement** (ord=4): SOC2・ISO 27001・個人情報保護法・GDPR への準拠要件 [C3, C4]
- **OrganizationalPolicy** (ord=3): 最小権限原則・職務分離・定期レビュー要件の組織方針 [C5, C6, H1]
- **AccessControlRule** (ord=2): ロールベースアクセス制御・コンテキスト認証・時間制限の実装ルール [H2, H3]
- **BehaviorHypothesis** (ord=1): ユーザー行動パターン・異常アクセス検知・リスクスコア推定の仮説 [H4, H5]
-/

namespace TestCoverage.S355

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s355_p01
  | s355_p02
  | s355_p03
  | s355_p04
  | s355_p05
  | s355_p06
  | s355_p07
  | s355_p08
  | s355_p09
  | s355_p10
  | s355_p11
  | s355_p12
  | s355_p13
  | s355_p14
  | s355_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s355_p01 => []
  | .s355_p02 => []
  | .s355_p03 => [.s355_p01]
  | .s355_p04 => [.s355_p02]
  | .s355_p05 => [.s355_p03]
  | .s355_p06 => [.s355_p04]
  | .s355_p07 => [.s355_p03, .s355_p04]
  | .s355_p08 => [.s355_p05]
  | .s355_p09 => [.s355_p06]
  | .s355_p10 => [.s355_p07, .s355_p08]
  | .s355_p11 => [.s355_p08]
  | .s355_p12 => [.s355_p09]
  | .s355_p13 => [.s355_p10]
  | .s355_p14 => [.s355_p11, .s355_p12]
  | .s355_p15 => [.s355_p13, .s355_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 機密情報保護・不正アクセス禁止の絶対セキュリティ制約 (ord=5) -/
  | SecurityInvariant
  /-- SOC2・ISO 27001・個人情報保護法・GDPR への準拠要件 (ord=4) -/
  | ComplianceRequirement
  /-- 最小権限原則・職務分離・定期レビュー要件の組織方針 (ord=3) -/
  | OrganizationalPolicy
  /-- ロールベースアクセス制御・コンテキスト認証・時間制限の実装ルール (ord=2) -/
  | AccessControlRule
  /-- ユーザー行動パターン・異常アクセス検知・リスクスコア推定の仮説 (ord=1) -/
  | BehaviorHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SecurityInvariant => 5
  | .ComplianceRequirement => 4
  | .OrganizationalPolicy => 3
  | .AccessControlRule => 2
  | .BehaviorHypothesis => 1

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
  bottom := .BehaviorHypothesis
  nontrivial := ⟨.SecurityInvariant, .BehaviorHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SecurityInvariant
  | .s355_p01 | .s355_p02 => .SecurityInvariant
  -- ComplianceRequirement
  | .s355_p03 | .s355_p04 => .ComplianceRequirement
  -- OrganizationalPolicy
  | .s355_p05 | .s355_p06 | .s355_p07 => .OrganizationalPolicy
  -- AccessControlRule
  | .s355_p08 | .s355_p09 | .s355_p10 => .AccessControlRule
  -- BehaviorHypothesis
  | .s355_p11 | .s355_p12 | .s355_p13 | .s355_p14 | .s355_p15 => .BehaviorHypothesis

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

end TestCoverage.S355

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SupplyChainSecurity** (ord=4): 既知脆弱性コンポーネントの使用禁止・Critical CVE即時対応に関する絶対要件 [C1, C2]
- **LicenseCompliance** (ord=3): OSS ライセンス遵守・GPL汚染防止・特許侵害回避に関する法的要件 [C3, C4]
- **DependencyPolicy** (ord=2): 推移的依存解決・バージョンピン戦略・更新ポリシーに関する管理方針 [C5, C6, H1, H2]
- **RiskAssessHypothesis** (ord=1): サプライチェーン攻撃経路・依存グラフ脆弱性伝播に関するリスク仮説 [H3, H4, H5]
-/

namespace TestCoverage.S425

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s425_p01
  | s425_p02
  | s425_p03
  | s425_p04
  | s425_p05
  | s425_p06
  | s425_p07
  | s425_p08
  | s425_p09
  | s425_p10
  | s425_p11
  | s425_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s425_p01 => []
  | .s425_p02 => []
  | .s425_p03 => [.s425_p01]
  | .s425_p04 => [.s425_p02]
  | .s425_p05 => [.s425_p03, .s425_p04]
  | .s425_p06 => [.s425_p03]
  | .s425_p07 => [.s425_p04]
  | .s425_p08 => [.s425_p06, .s425_p07]
  | .s425_p09 => [.s425_p06]
  | .s425_p10 => [.s425_p07]
  | .s425_p11 => [.s425_p09]
  | .s425_p12 => [.s425_p10, .s425_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 既知脆弱性コンポーネントの使用禁止・Critical CVE即時対応に関する絶対要件 (ord=4) -/
  | SupplyChainSecurity
  /-- OSS ライセンス遵守・GPL汚染防止・特許侵害回避に関する法的要件 (ord=3) -/
  | LicenseCompliance
  /-- 推移的依存解決・バージョンピン戦略・更新ポリシーに関する管理方針 (ord=2) -/
  | DependencyPolicy
  /-- サプライチェーン攻撃経路・依存グラフ脆弱性伝播に関するリスク仮説 (ord=1) -/
  | RiskAssessHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SupplyChainSecurity => 4
  | .LicenseCompliance => 3
  | .DependencyPolicy => 2
  | .RiskAssessHypothesis => 1

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
  bottom := .RiskAssessHypothesis
  nontrivial := ⟨.SupplyChainSecurity, .RiskAssessHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SupplyChainSecurity
  | .s425_p01 | .s425_p02 => .SupplyChainSecurity
  -- LicenseCompliance
  | .s425_p03 | .s425_p04 | .s425_p05 => .LicenseCompliance
  -- DependencyPolicy
  | .s425_p06 | .s425_p07 | .s425_p08 => .DependencyPolicy
  -- RiskAssessHypothesis
  | .s425_p09 | .s425_p10 | .s425_p11 | .s425_p12 => .RiskAssessHypothesis

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

end TestCoverage.S425

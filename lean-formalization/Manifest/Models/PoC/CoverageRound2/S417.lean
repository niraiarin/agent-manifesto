/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **CertificationIntegrity** (ord=5): 再エネ証書の発行・移転・無効化に関するダブルカウント防止の絶対制約 [C1, C2]
- **RegulatoryFramework** (ord=4): 再生可能エネルギー特別措置法・ISO 15919・国際標準への適合制約 [C3, C4]
- **MarketTransparency** (ord=3): 証書取引の透明性・公正価格形成・市場操作防止に関する方針 [C5, H1, H2]
- **VerificationProtocol** (ord=2): 発電実績検証・第三者監査・ブロックチェーン台帳整合性確認手順 [C6, H3, H4]
- **MarketOptimization** (ord=1): 需給マッチング・価格予測・証書流動性向上に関する最適化仮説 [H5, H6]
-/

namespace TestCoverage.S417

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s417_p01
  | s417_p02
  | s417_p03
  | s417_p04
  | s417_p05
  | s417_p06
  | s417_p07
  | s417_p08
  | s417_p09
  | s417_p10
  | s417_p11
  | s417_p12
  | s417_p13
  | s417_p14
  | s417_p15
  | s417_p16
  | s417_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s417_p01 => []
  | .s417_p02 => []
  | .s417_p03 => [.s417_p01, .s417_p02]
  | .s417_p04 => [.s417_p01]
  | .s417_p05 => [.s417_p02]
  | .s417_p06 => [.s417_p03, .s417_p04, .s417_p05]
  | .s417_p07 => [.s417_p04]
  | .s417_p08 => [.s417_p05, .s417_p06]
  | .s417_p09 => [.s417_p07, .s417_p08]
  | .s417_p10 => [.s417_p07]
  | .s417_p11 => [.s417_p08]
  | .s417_p12 => [.s417_p09, .s417_p10, .s417_p11]
  | .s417_p13 => [.s417_p10]
  | .s417_p14 => [.s417_p11]
  | .s417_p15 => [.s417_p13, .s417_p14]
  | .s417_p16 => [.s417_p06]
  | .s417_p17 => [.s417_p12, .s417_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 再エネ証書の発行・移転・無効化に関するダブルカウント防止の絶対制約 (ord=5) -/
  | CertificationIntegrity
  /-- 再生可能エネルギー特別措置法・ISO 15919・国際標準への適合制約 (ord=4) -/
  | RegulatoryFramework
  /-- 証書取引の透明性・公正価格形成・市場操作防止に関する方針 (ord=3) -/
  | MarketTransparency
  /-- 発電実績検証・第三者監査・ブロックチェーン台帳整合性確認手順 (ord=2) -/
  | VerificationProtocol
  /-- 需給マッチング・価格予測・証書流動性向上に関する最適化仮説 (ord=1) -/
  | MarketOptimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .CertificationIntegrity => 5
  | .RegulatoryFramework => 4
  | .MarketTransparency => 3
  | .VerificationProtocol => 2
  | .MarketOptimization => 1

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
  bottom := .MarketOptimization
  nontrivial := ⟨.CertificationIntegrity, .MarketOptimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- CertificationIntegrity
  | .s417_p01 | .s417_p02 | .s417_p03 => .CertificationIntegrity
  -- RegulatoryFramework
  | .s417_p04 | .s417_p05 | .s417_p06 => .RegulatoryFramework
  -- MarketTransparency
  | .s417_p07 | .s417_p08 | .s417_p09 => .MarketTransparency
  -- VerificationProtocol
  | .s417_p10 | .s417_p11 | .s417_p12 | .s417_p16 => .VerificationProtocol
  -- MarketOptimization
  | .s417_p13 | .s417_p14 | .s417_p15 | .s417_p17 => .MarketOptimization

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

end TestCoverage.S417

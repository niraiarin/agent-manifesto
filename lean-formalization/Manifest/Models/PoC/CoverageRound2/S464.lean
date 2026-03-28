/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PrivacyRightsInvariant** (ord=5): 個人情報の収集・利用の絶対制約。GDPR・個人情報保護法への違反禁止 [C1, C2]
- **AdRegulationCompliance** (ord=4): 景品表示法・不当広告規制・プラットフォーム広告ポリシーへの準拠 [C3, C4]
- **TargetingEthicsPolicy** (ord=3): 脆弱層（未成年・依存症リスク）への有害広告排除。差別的ターゲティングの禁止 [C5, C6, H1]
- **AudienceSegmentationPolicy** (ord=2): 行動データ・デモグラフィクスによるオーディエンスセグメント設計方針 [H2, H3, H4]
- **ConversionPredictionHypothesis** (ord=1): クリック率・購買確率の予測仮説。実績データによる継続的更新 [H5, H6, H7, H8]
-/

namespace TestCoverage.S464

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s464_p01
  | s464_p02
  | s464_p03
  | s464_p04
  | s464_p05
  | s464_p06
  | s464_p07
  | s464_p08
  | s464_p09
  | s464_p10
  | s464_p11
  | s464_p12
  | s464_p13
  | s464_p14
  | s464_p15
  | s464_p16
  | s464_p17
  | s464_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s464_p01 => []
  | .s464_p02 => [.s464_p01]
  | .s464_p03 => [.s464_p01]
  | .s464_p04 => [.s464_p02]
  | .s464_p05 => [.s464_p03]
  | .s464_p06 => [.s464_p04]
  | .s464_p07 => [.s464_p05, .s464_p06]
  | .s464_p08 => [.s464_p05]
  | .s464_p09 => [.s464_p06]
  | .s464_p10 => [.s464_p07]
  | .s464_p11 => [.s464_p08, .s464_p09]
  | .s464_p12 => [.s464_p08]
  | .s464_p13 => [.s464_p09]
  | .s464_p14 => [.s464_p10]
  | .s464_p15 => [.s464_p11]
  | .s464_p16 => [.s464_p12, .s464_p13]
  | .s464_p17 => [.s464_p14, .s464_p15]
  | .s464_p18 => [.s464_p16, .s464_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 個人情報の収集・利用の絶対制約。GDPR・個人情報保護法への違反禁止 (ord=5) -/
  | PrivacyRightsInvariant
  /-- 景品表示法・不当広告規制・プラットフォーム広告ポリシーへの準拠 (ord=4) -/
  | AdRegulationCompliance
  /-- 脆弱層（未成年・依存症リスク）への有害広告排除。差別的ターゲティングの禁止 (ord=3) -/
  | TargetingEthicsPolicy
  /-- 行動データ・デモグラフィクスによるオーディエンスセグメント設計方針 (ord=2) -/
  | AudienceSegmentationPolicy
  /-- クリック率・購買確率の予測仮説。実績データによる継続的更新 (ord=1) -/
  | ConversionPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PrivacyRightsInvariant => 5
  | .AdRegulationCompliance => 4
  | .TargetingEthicsPolicy => 3
  | .AudienceSegmentationPolicy => 2
  | .ConversionPredictionHypothesis => 1

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
  bottom := .ConversionPredictionHypothesis
  nontrivial := ⟨.PrivacyRightsInvariant, .ConversionPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PrivacyRightsInvariant
  | .s464_p01 | .s464_p02 => .PrivacyRightsInvariant
  -- AdRegulationCompliance
  | .s464_p03 | .s464_p04 => .AdRegulationCompliance
  -- TargetingEthicsPolicy
  | .s464_p05 | .s464_p06 | .s464_p07 => .TargetingEthicsPolicy
  -- AudienceSegmentationPolicy
  | .s464_p08 | .s464_p09 | .s464_p10 | .s464_p11 => .AudienceSegmentationPolicy
  -- ConversionPredictionHypothesis
  | .s464_p12 | .s464_p13 | .s464_p14 | .s464_p15 | .s464_p16 | .s464_p17 | .s464_p18 => .ConversionPredictionHypothesis

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

end TestCoverage.S464

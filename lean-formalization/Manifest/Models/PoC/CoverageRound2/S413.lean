/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **UserPrivacyProtection** (ord=4): ユーザープライバシー・個人データ保護・GDPR準拠の絶対制約 [C1, C2]
- **ContentModerationPolicy** (ord=3): 有害コンテンツ排除・著作権遵守・プラットフォーム利用規約の適用 [C3, C4]
- **RecommendationAlgorithm** (ord=2): 協調フィルタリング・コンテンツベースフィルタリングによる推薦ロジック [C5, H1, H2, H3]
- **PersonalizationHypothesis** (ord=1): 行動履歴・嗜好推定・多様性バランスに関する推薦精度向上仮説 [H4, H5, H6, H7, H8]
-/

namespace TestCoverage.S413

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s413_p01
  | s413_p02
  | s413_p03
  | s413_p04
  | s413_p05
  | s413_p06
  | s413_p07
  | s413_p08
  | s413_p09
  | s413_p10
  | s413_p11
  | s413_p12
  | s413_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s413_p01 => []
  | .s413_p02 => []
  | .s413_p03 => [.s413_p01]
  | .s413_p04 => [.s413_p02]
  | .s413_p05 => [.s413_p03, .s413_p04]
  | .s413_p06 => [.s413_p03]
  | .s413_p07 => [.s413_p04, .s413_p05]
  | .s413_p08 => [.s413_p06, .s413_p07]
  | .s413_p09 => [.s413_p06]
  | .s413_p10 => [.s413_p07]
  | .s413_p11 => [.s413_p08]
  | .s413_p12 => [.s413_p09, .s413_p10]
  | .s413_p13 => [.s413_p11, .s413_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- ユーザープライバシー・個人データ保護・GDPR準拠の絶対制約 (ord=4) -/
  | UserPrivacyProtection
  /-- 有害コンテンツ排除・著作権遵守・プラットフォーム利用規約の適用 (ord=3) -/
  | ContentModerationPolicy
  /-- 協調フィルタリング・コンテンツベースフィルタリングによる推薦ロジック (ord=2) -/
  | RecommendationAlgorithm
  /-- 行動履歴・嗜好推定・多様性バランスに関する推薦精度向上仮説 (ord=1) -/
  | PersonalizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .UserPrivacyProtection => 4
  | .ContentModerationPolicy => 3
  | .RecommendationAlgorithm => 2
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
  nontrivial := ⟨.UserPrivacyProtection, .PersonalizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- UserPrivacyProtection
  | .s413_p01 | .s413_p02 => .UserPrivacyProtection
  -- ContentModerationPolicy
  | .s413_p03 | .s413_p04 | .s413_p05 => .ContentModerationPolicy
  -- RecommendationAlgorithm
  | .s413_p06 | .s413_p07 | .s413_p08 => .RecommendationAlgorithm
  -- PersonalizationHypothesis
  | .s413_p09 | .s413_p10 | .s413_p11 | .s413_p12 | .s413_p13 => .PersonalizationHypothesis

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

end TestCoverage.S413

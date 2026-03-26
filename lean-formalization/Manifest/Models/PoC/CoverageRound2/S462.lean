/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ContentSafetyInvariant** (ord=4): 未成年保護・有害コンテンツ排除の絶対制約。レーティング誤判定の防止 [C1, C2]
- **RegulatoryRatingStandard** (ord=3): 映倫・放送倫理基準・年齢制限法規への準拠要件 [C3, C4]
- **GenreClassificationPolicy** (ord=2): ジャンル・暴力度・性描写スコアリング方針。多次元特徴量による分類基準 [C5, C6, H1, H2]
- **AudienceReactionHypothesis** (ord=1): 視聴者属性・過去評価から反応を推定する仮説。A/B テスト結果で更新可能 [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S462

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s462_p01
  | s462_p02
  | s462_p03
  | s462_p04
  | s462_p05
  | s462_p06
  | s462_p07
  | s462_p08
  | s462_p09
  | s462_p10
  | s462_p11
  | s462_p12
  | s462_p13
  | s462_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s462_p01 => []
  | .s462_p02 => [.s462_p01]
  | .s462_p03 => [.s462_p01]
  | .s462_p04 => [.s462_p02]
  | .s462_p05 => [.s462_p03]
  | .s462_p06 => [.s462_p04]
  | .s462_p07 => [.s462_p05, .s462_p06]
  | .s462_p08 => [.s462_p05]
  | .s462_p09 => [.s462_p06]
  | .s462_p10 => [.s462_p07]
  | .s462_p11 => [.s462_p08]
  | .s462_p12 => [.s462_p09]
  | .s462_p13 => [.s462_p10, .s462_p11]
  | .s462_p14 => [.s462_p12, .s462_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 未成年保護・有害コンテンツ排除の絶対制約。レーティング誤判定の防止 (ord=4) -/
  | ContentSafetyInvariant
  /-- 映倫・放送倫理基準・年齢制限法規への準拠要件 (ord=3) -/
  | RegulatoryRatingStandard
  /-- ジャンル・暴力度・性描写スコアリング方針。多次元特徴量による分類基準 (ord=2) -/
  | GenreClassificationPolicy
  /-- 視聴者属性・過去評価から反応を推定する仮説。A/B テスト結果で更新可能 (ord=1) -/
  | AudienceReactionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ContentSafetyInvariant => 4
  | .RegulatoryRatingStandard => 3
  | .GenreClassificationPolicy => 2
  | .AudienceReactionHypothesis => 1

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
  bottom := .AudienceReactionHypothesis
  nontrivial := ⟨.ContentSafetyInvariant, .AudienceReactionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ContentSafetyInvariant
  | .s462_p01 | .s462_p02 => .ContentSafetyInvariant
  -- RegulatoryRatingStandard
  | .s462_p03 | .s462_p04 => .RegulatoryRatingStandard
  -- GenreClassificationPolicy
  | .s462_p05 | .s462_p06 | .s462_p07 => .GenreClassificationPolicy
  -- AudienceReactionHypothesis
  | .s462_p08 | .s462_p09 | .s462_p10 | .s462_p11 | .s462_p12 | .s462_p13 | .s462_p14 => .AudienceReactionHypothesis

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

end TestCoverage.S462

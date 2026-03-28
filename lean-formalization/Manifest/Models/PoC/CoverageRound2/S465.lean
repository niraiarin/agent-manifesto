/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **IPRightsInvariant** (ord=4): 著作権・知的財産権の侵害防止絶対制約。誤検知による正当コンテンツ削除の最小化 [C1, C2]
- **CopyrightLawCompliance** (ord=3): 著作権法・DMCA・フェアユース原則への準拠。法的根拠に基づく削除判断 [C3, C4]
- **DetectionPolicy** (ord=2): フィンガープリント照合・メタデータ分析・類似度閾値設定方針 [C5, H1, H2]
- **SimilarityInferenceHypothesis** (ord=1): 音声・映像・テキストの特徴量類似度から侵害確率を推定する仮説層 [H3, H4, H5, H6]
-/

namespace TestCoverage.S465

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s465_p01
  | s465_p02
  | s465_p03
  | s465_p04
  | s465_p05
  | s465_p06
  | s465_p07
  | s465_p08
  | s465_p09
  | s465_p10
  | s465_p11
  | s465_p12
  | s465_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s465_p01 => []
  | .s465_p02 => [.s465_p01]
  | .s465_p03 => [.s465_p01]
  | .s465_p04 => [.s465_p02]
  | .s465_p05 => [.s465_p03]
  | .s465_p06 => [.s465_p04]
  | .s465_p07 => [.s465_p05, .s465_p06]
  | .s465_p08 => [.s465_p05]
  | .s465_p09 => [.s465_p06]
  | .s465_p10 => [.s465_p07]
  | .s465_p11 => [.s465_p08]
  | .s465_p12 => [.s465_p09, .s465_p10]
  | .s465_p13 => [.s465_p11, .s465_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 著作権・知的財産権の侵害防止絶対制約。誤検知による正当コンテンツ削除の最小化 (ord=4) -/
  | IPRightsInvariant
  /-- 著作権法・DMCA・フェアユース原則への準拠。法的根拠に基づく削除判断 (ord=3) -/
  | CopyrightLawCompliance
  /-- フィンガープリント照合・メタデータ分析・類似度閾値設定方針 (ord=2) -/
  | DetectionPolicy
  /-- 音声・映像・テキストの特徴量類似度から侵害確率を推定する仮説層 (ord=1) -/
  | SimilarityInferenceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .IPRightsInvariant => 4
  | .CopyrightLawCompliance => 3
  | .DetectionPolicy => 2
  | .SimilarityInferenceHypothesis => 1

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
  bottom := .SimilarityInferenceHypothesis
  nontrivial := ⟨.IPRightsInvariant, .SimilarityInferenceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- IPRightsInvariant
  | .s465_p01 | .s465_p02 => .IPRightsInvariant
  -- CopyrightLawCompliance
  | .s465_p03 | .s465_p04 => .CopyrightLawCompliance
  -- DetectionPolicy
  | .s465_p05 | .s465_p06 | .s465_p07 => .DetectionPolicy
  -- SimilarityInferenceHypothesis
  | .s465_p08 | .s465_p09 | .s465_p10 | .s465_p11 | .s465_p12 | .s465_p13 => .SimilarityInferenceHypothesis

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

end TestCoverage.S465

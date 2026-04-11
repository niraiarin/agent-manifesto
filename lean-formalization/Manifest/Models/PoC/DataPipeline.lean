/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **DataPrivacy** (ord=5): 個人情報保護の不変条件。GDPR/CCPA準拠 [C1, C2]
- **SchemaContract** (ord=4): 上下流のスキーマ契約。互換性維持が必須 [C3, H1]
- **QualityGate** (ord=3): データ品質ゲート。null率・異常値の閾値 [C4, H2]
- **PartitionStrategy** (ord=2): パーティション戦略。コスト最適化のため調整可能 [H3, H4]
- **RetryPolicy** (ord=1): リトライポリシー。失敗パターンに基づき自動調整 [H5, H6]
-/

namespace DataPipeline

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | dp_p01
  | dp_p02
  | dp_p03
  | dp_p04
  | dp_p05
  | dp_p06
  | dp_p07
  | dp_p08
  | dp_p09
  | dp_p10
  | dp_p11
  | dp_p12
  | dp_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .dp_p01 => []
  | .dp_p02 => []
  | .dp_p03 => [.dp_p01]
  | .dp_p04 => [.dp_p02]
  | .dp_p05 => [.dp_p01, .dp_p02]
  | .dp_p06 => [.dp_p03]
  | .dp_p07 => [.dp_p04]
  | .dp_p08 => [.dp_p03, .dp_p05]
  | .dp_p09 => [.dp_p06]
  | .dp_p10 => [.dp_p07]
  | .dp_p11 => [.dp_p09]
  | .dp_p12 => [.dp_p10]
  | .dp_p13 => [.dp_p09, .dp_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 個人情報保護の不変条件。GDPR/CCPA準拠 (ord=5) -/
  | DataPrivacy
  /-- 上下流のスキーマ契約。互換性維持が必須 (ord=4) -/
  | SchemaContract
  /-- データ品質ゲート。null率・異常値の閾値 (ord=3) -/
  | QualityGate
  /-- パーティション戦略。コスト最適化のため調整可能 (ord=2) -/
  | PartitionStrategy
  /-- リトライポリシー。失敗パターンに基づき自動調整 (ord=1) -/
  | RetryPolicy
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .DataPrivacy => 5
  | .SchemaContract => 4
  | .QualityGate => 3
  | .PartitionStrategy => 2
  | .RetryPolicy => 1

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
  bottom := .RetryPolicy
  nontrivial := ⟨.DataPrivacy, .RetryPolicy, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- DataPrivacy
  | .dp_p01 | .dp_p02 => .DataPrivacy
  -- SchemaContract
  | .dp_p03 | .dp_p04 | .dp_p05 => .SchemaContract
  -- QualityGate
  | .dp_p06 | .dp_p07 | .dp_p08 => .QualityGate
  -- PartitionStrategy
  | .dp_p09 | .dp_p10 => .PartitionStrategy
  -- RetryPolicy
  | .dp_p11 | .dp_p12 | .dp_p13 => .RetryPolicy

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

end DataPipeline

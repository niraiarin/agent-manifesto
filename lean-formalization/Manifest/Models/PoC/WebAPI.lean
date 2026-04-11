/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SecurityInvariant** (ord=4): 認証・認可の不変条件。全リクエストに適用 [C1, C2]
- **DataIntegrity** (ord=3): データの整合性制約。スキーマ・外部キー・一意性 [C3, H1]
- **RateLimiting** (ord=2): レート制限ポリシー。運用負荷に応じて調整可能 [C4, H2]
- **CachingStrategy** (ord=1): キャッシュ戦略。パフォーマンス最適化のため自動調整 [H3, H4]
-/

namespace WebAPI

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | wa_p01
  | wa_p02
  | wa_p03
  | wa_p04
  | wa_p05
  | wa_p06
  | wa_p07
  | wa_p08
  | wa_p09
  | wa_p10
  | wa_p11
  | wa_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .wa_p01 => []
  | .wa_p02 => []
  | .wa_p03 => []
  | .wa_p04 => [.wa_p01]
  | .wa_p05 => [.wa_p02]
  | .wa_p06 => [.wa_p01, .wa_p03]
  | .wa_p07 => [.wa_p04]
  | .wa_p08 => [.wa_p05]
  | .wa_p09 => [.wa_p04, .wa_p06]
  | .wa_p10 => [.wa_p07]
  | .wa_p11 => [.wa_p08]
  | .wa_p12 => [.wa_p09, .wa_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 認証・認可の不変条件。全リクエストに適用 (ord=4) -/
  | SecurityInvariant
  /-- データの整合性制約。スキーマ・外部キー・一意性 (ord=3) -/
  | DataIntegrity
  /-- レート制限ポリシー。運用負荷に応じて調整可能 (ord=2) -/
  | RateLimiting
  /-- キャッシュ戦略。パフォーマンス最適化のため自動調整 (ord=1) -/
  | CachingStrategy
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SecurityInvariant => 4
  | .DataIntegrity => 3
  | .RateLimiting => 2
  | .CachingStrategy => 1

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
  bottom := .CachingStrategy
  nontrivial := ⟨.SecurityInvariant, .CachingStrategy, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SecurityInvariant
  | .wa_p01 | .wa_p02 | .wa_p03 => .SecurityInvariant
  -- DataIntegrity
  | .wa_p04 | .wa_p05 | .wa_p06 => .DataIntegrity
  -- RateLimiting
  | .wa_p07 | .wa_p08 | .wa_p09 => .RateLimiting
  -- CachingStrategy
  | .wa_p10 | .wa_p11 | .wa_p12 => .CachingStrategy

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

end WebAPI

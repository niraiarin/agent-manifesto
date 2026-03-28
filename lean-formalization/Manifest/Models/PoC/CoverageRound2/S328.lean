/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **rights_invariant** (ord=4): 市民権・プライバシー・無差別原則に関する絶対不変条件 [C1, C2, C3]
- **accountability_standard** (ord=3): 透明性・第三者監査・バイアス評価の説明責任要件 [C4, C5]
- **operational_policy** (ord=2): 予測提示方法・過依存防止・データ制限の運用方針 [C6, H3, H4, H5]
- **prediction_model** (ord=1): ホットスポット分析・公平性評価・データ期間制限の推論仮説 [H1, H2]
-/

namespace TestCoverage.S328

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s328_p01
  | s328_p02
  | s328_p03
  | s328_p04
  | s328_p05
  | s328_p06
  | s328_p07
  | s328_p08
  | s328_p09
  | s328_p10
  | s328_p11
  | s328_p12
  | s328_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s328_p01 => []
  | .s328_p02 => [.s328_p01]
  | .s328_p03 => [.s328_p01, .s328_p02]
  | .s328_p04 => [.s328_p01]
  | .s328_p05 => [.s328_p04]
  | .s328_p06 => [.s328_p02, .s328_p04]
  | .s328_p07 => [.s328_p03, .s328_p05]
  | .s328_p08 => [.s328_p02, .s328_p06]
  | .s328_p09 => [.s328_p05, .s328_p07]
  | .s328_p10 => [.s328_p01, .s328_p07]
  | .s328_p11 => [.s328_p04, .s328_p10]
  | .s328_p12 => [.s328_p10, .s328_p11]
  | .s328_p13 => [.s328_p07, .s328_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 市民権・プライバシー・無差別原則に関する絶対不変条件 (ord=4) -/
  | rights_invariant
  /-- 透明性・第三者監査・バイアス評価の説明責任要件 (ord=3) -/
  | accountability_standard
  /-- 予測提示方法・過依存防止・データ制限の運用方針 (ord=2) -/
  | operational_policy
  /-- ホットスポット分析・公平性評価・データ期間制限の推論仮説 (ord=1) -/
  | prediction_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .rights_invariant => 4
  | .accountability_standard => 3
  | .operational_policy => 2
  | .prediction_model => 1

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
  bottom := .prediction_model
  nontrivial := ⟨.rights_invariant, .prediction_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- rights_invariant
  | .s328_p01 | .s328_p02 | .s328_p03 => .rights_invariant
  -- accountability_standard
  | .s328_p04 | .s328_p05 => .accountability_standard
  -- operational_policy
  | .s328_p06 | .s328_p07 | .s328_p08 | .s328_p09 => .operational_policy
  -- prediction_model
  | .s328_p10 | .s328_p11 | .s328_p12 | .s328_p13 => .prediction_model

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

end TestCoverage.S328

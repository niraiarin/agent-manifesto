/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PrivacyProtection** (ord=4): 個人識別情報の最小化・目的外利用禁止・保存期間制限に関する絶対要件 [C1, C2]
- **LegalFramework** (ord=3): 個人情報保護法・防犯目的限定・令状なし顔認識禁止に関する法的準拠 [C3, C4]
- **DetectionPolicy** (ord=2): 異常行動検出閾値・アラート基準・オペレータ確認フローに関する検出方針 [C5, H1, H2]
- **BehaviorHypothesis** (ord=1): 群衆密度・動線異常・放置物検知・侵入パターンに関する行動仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S427

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s427_p01
  | s427_p02
  | s427_p03
  | s427_p04
  | s427_p05
  | s427_p06
  | s427_p07
  | s427_p08
  | s427_p09
  | s427_p10
  | s427_p11
  | s427_p12
  | s427_p13
  | s427_p14
  | s427_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s427_p01 => []
  | .s427_p02 => []
  | .s427_p03 => [.s427_p01]
  | .s427_p04 => [.s427_p02]
  | .s427_p05 => [.s427_p03, .s427_p04]
  | .s427_p06 => [.s427_p03]
  | .s427_p07 => [.s427_p04]
  | .s427_p08 => [.s427_p06, .s427_p07]
  | .s427_p09 => [.s427_p06]
  | .s427_p10 => [.s427_p07]
  | .s427_p11 => [.s427_p09]
  | .s427_p12 => [.s427_p10]
  | .s427_p13 => [.s427_p11]
  | .s427_p14 => [.s427_p12]
  | .s427_p15 => [.s427_p13, .s427_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 個人識別情報の最小化・目的外利用禁止・保存期間制限に関する絶対要件 (ord=4) -/
  | PrivacyProtection
  /-- 個人情報保護法・防犯目的限定・令状なし顔認識禁止に関する法的準拠 (ord=3) -/
  | LegalFramework
  /-- 異常行動検出閾値・アラート基準・オペレータ確認フローに関する検出方針 (ord=2) -/
  | DetectionPolicy
  /-- 群衆密度・動線異常・放置物検知・侵入パターンに関する行動仮説 (ord=1) -/
  | BehaviorHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PrivacyProtection => 4
  | .LegalFramework => 3
  | .DetectionPolicy => 2
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
  nontrivial := ⟨.PrivacyProtection, .BehaviorHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PrivacyProtection
  | .s427_p01 | .s427_p02 => .PrivacyProtection
  -- LegalFramework
  | .s427_p03 | .s427_p04 | .s427_p05 => .LegalFramework
  -- DetectionPolicy
  | .s427_p06 | .s427_p07 | .s427_p08 => .DetectionPolicy
  -- BehaviorHypothesis
  | .s427_p09 | .s427_p10 | .s427_p11 | .s427_p12 | .s427_p13 | .s427_p14 | .s427_p15 => .BehaviorHypothesis

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

end TestCoverage.S427

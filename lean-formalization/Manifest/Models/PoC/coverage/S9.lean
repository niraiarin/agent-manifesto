/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AnimalWelfare** (ord=4): 動物福祉。緊急時の即時通報義務 [C1]
- **VeterinaryGuideline** (ord=3): 獣医学的ガイドライン。正常値範囲の定義 [C2, H1]
- **MonitoringPolicy** (ord=2): モニタリング頻度・閾値の設定ポリシー [C3, H2]
- **OwnerCustomization** (ord=1): 飼い主の好みに応じた通知・表示設定 [C4, H3]
-/

namespace TestCoverage.S9

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s9_p01
  | s9_p02
  | s9_p03
  | s9_p04
  | s9_p05
  | s9_p06
  | s9_p07
  | s9_p08
  | s9_p09
  | s9_p10
  | s9_p11
  | s9_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s9_p01 => []
  | .s9_p02 => []
  | .s9_p03 => [.s9_p01]
  | .s9_p04 => [.s9_p02]
  | .s9_p05 => [.s9_p01, .s9_p02]
  | .s9_p06 => [.s9_p03]
  | .s9_p07 => [.s9_p04]
  | .s9_p08 => [.s9_p03, .s9_p05]
  | .s9_p09 => [.s9_p06]
  | .s9_p10 => [.s9_p07]
  | .s9_p11 => [.s9_p08]
  | .s9_p12 => [.s9_p09, .s9_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 動物福祉。緊急時の即時通報義務 (ord=4) -/
  | AnimalWelfare
  /-- 獣医学的ガイドライン。正常値範囲の定義 (ord=3) -/
  | VeterinaryGuideline
  /-- モニタリング頻度・閾値の設定ポリシー (ord=2) -/
  | MonitoringPolicy
  /-- 飼い主の好みに応じた通知・表示設定 (ord=1) -/
  | OwnerCustomization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AnimalWelfare => 4
  | .VeterinaryGuideline => 3
  | .MonitoringPolicy => 2
  | .OwnerCustomization => 1

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
  bottom := .OwnerCustomization
  nontrivial := ⟨.AnimalWelfare, .OwnerCustomization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AnimalWelfare
  | .s9_p01 | .s9_p02 => .AnimalWelfare
  -- VeterinaryGuideline
  | .s9_p03 | .s9_p04 | .s9_p05 => .VeterinaryGuideline
  -- MonitoringPolicy
  | .s9_p06 | .s9_p07 | .s9_p08 => .MonitoringPolicy
  -- OwnerCustomization
  | .s9_p09 | .s9_p10 | .s9_p11 | .s9_p12 => .OwnerCustomization

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

end TestCoverage.S9

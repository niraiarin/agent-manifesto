/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **lunarPhysics** (ord=4): 月面環境の物理法則。変更不可能。 [C1, C6, C7]
- **structural** (ord=3): 構造安全性の工学的要件。物理法則から導出。 [C1, C6, C7, H3]
- **logistics** (ord=2): 資材・通信のリソース制約。技術進歩で変動しうる。 [C3, C4]
- **construction** (ord=1): 建設手法と自律ロボットの運用方針。 [C2, C5, H1, H2]
- **hypothesis** (ord=0): 実証が必要な技術的仮説。 [H1, H3]
-/

namespace Scenario199

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | lph1
  | lph2
  | lph3
  | str1
  | str2
  | str3
  | lgs1
  | lgs2
  | lgs3
  | con1
  | con2
  | con3
  | con4
  | con5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .lph1 => []
  | .lph2 => []
  | .lph3 => []
  | .str1 => [.lph3]
  | .str2 => [.lph1, .lph2]
  | .str3 => [.lph2, .lph3, .str1]
  | .lgs1 => []
  | .lgs2 => []
  | .lgs3 => [.str2, .lgs1]
  | .con1 => [.lgs2]
  | .con2 => [.str1, .str2, .lgs1]
  | .con3 => [.lgs2, .con1]
  | .con4 => [.lgs2, .con2]
  | .con5 => [.str3, .con2, .con3]
  | .hyp1 => [.lgs1, .con2]
  | .hyp2 => [.str1, .str3]
  | .hyp3 => [.con5, .hyp1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 月面環境の物理法則。変更不可能。 (ord=4) -/
  | lunarPhysics
  /-- 構造安全性の工学的要件。物理法則から導出。 (ord=3) -/
  | structural
  /-- 資材・通信のリソース制約。技術進歩で変動しうる。 (ord=2) -/
  | logistics
  /-- 建設手法と自律ロボットの運用方針。 (ord=1) -/
  | construction
  /-- 実証が必要な技術的仮説。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .lunarPhysics => 4
  | .structural => 3
  | .logistics => 2
  | .construction => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.lunarPhysics, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- lunarPhysics
  | .lph1 | .lph2 | .lph3 => .lunarPhysics
  -- structural
  | .str1 | .str2 | .str3 => .structural
  -- logistics
  | .lgs1 | .lgs2 | .lgs3 => .logistics
  -- construction
  | .con1 | .con2 | .con3 | .con4 | .con5 => .construction
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 => .hypothesis

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

end Scenario199

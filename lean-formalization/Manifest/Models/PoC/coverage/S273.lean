/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **geophysics** (ord=4): 地球物理学的制約。断層の物理的挙動に基づく不変条件。 [C3, C4]
- **societal** (ord=3): 社会的責任に関わる制約。誤報防止と情報公開。 [C1, C2, C5]
- **expert** (ord=2): 専門家が設定するモデルパラメータ。地質調査の更新で変化。 [C4, H3]
- **analysis** (ord=1): AIが自律的に行うデータ分析手法。改善可能。 [H1, H2]
- **hyp** (ord=0): 検証待ちの仮説。観測データの蓄積で確認。 [H4]
-/

namespace Scenario273

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | geo1
  | geo2
  | geo3
  | soc1
  | soc2
  | soc3
  | exp1
  | exp2
  | exp3
  | ana1
  | ana2
  | ana3
  | ana4
  | ana5
  | ana6
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .geo1 => []
  | .geo2 => []
  | .geo3 => []
  | .soc1 => []
  | .soc2 => [.soc1]
  | .soc3 => [.soc2]
  | .exp1 => [.geo2, .geo3]
  | .exp2 => [.geo1, .soc2]
  | .exp3 => [.exp1]
  | .ana1 => [.geo1, .exp1]
  | .ana2 => [.soc2, .exp2]
  | .ana3 => [.ana1, .ana2]
  | .ana4 => [.geo3, .exp3]
  | .ana5 => [.soc3, .ana3]
  | .ana6 => [.exp2, .ana4]
  | .hyp1 => [.soc3, .ana1]
  | .hyp2 => [.ana5, .ana6]
  | .hyp3 => [.ana3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地球物理学的制約。断層の物理的挙動に基づく不変条件。 (ord=4) -/
  | geophysics
  /-- 社会的責任に関わる制約。誤報防止と情報公開。 (ord=3) -/
  | societal
  /-- 専門家が設定するモデルパラメータ。地質調査の更新で変化。 (ord=2) -/
  | expert
  /-- AIが自律的に行うデータ分析手法。改善可能。 (ord=1) -/
  | analysis
  /-- 検証待ちの仮説。観測データの蓄積で確認。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .geophysics => 4
  | .societal => 3
  | .expert => 2
  | .analysis => 1
  | .hyp => 0

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
  bottom := .hyp
  nontrivial := ⟨.geophysics, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- geophysics
  | .geo1 | .geo2 | .geo3 => .geophysics
  -- societal
  | .soc1 | .soc2 | .soc3 => .societal
  -- expert
  | .exp1 | .exp2 | .exp3 => .expert
  -- analysis
  | .ana1 | .ana2 | .ana3 | .ana4 | .ana5 | .ana6 => .analysis
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 => .hyp

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

end Scenario273

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **cryosphere** (ord=5): 凍土の物理学的制約。熱力学法則に基づく不変条件。 [C3]
- **ethics** (ord=4): 先住民の権利と国際データ公開義務。倫理的不可侵。 [C1, C5]
- **policy** (ord=3): 政策判断に影響する不確実性管理。社会的責任。 [C2, C4]
- **science** (ord=2): 気候科学者が管理するモデルパラメータ。研究進展で更新。 [C6, H2]
- **technique** (ord=1): AIのデータ処理・予測手法。改善可能。 [H1, H3]
- **hyp** (ord=0): 検証待ちの仮説。フィールドデータで確認。 [H4]
-/

namespace Scenario279

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | cry1
  | cry2
  | eth1
  | eth2
  | eth3
  | pol1
  | pol2
  | pol3
  | sci1
  | sci2
  | sci3
  | tec1
  | tec2
  | tec3
  | tec4
  | tec5
  | tec6
  | tec7
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .cry1 => []
  | .cry2 => []
  | .eth1 => []
  | .eth2 => []
  | .eth3 => [.eth1, .eth2]
  | .pol1 => [.eth1]
  | .pol2 => [.eth3]
  | .pol3 => [.pol1, .pol2]
  | .sci1 => [.cry1, .pol2]
  | .sci2 => [.pol2, .pol3]
  | .sci3 => [.sci1, .sci2]
  | .tec1 => [.cry1, .cry2]
  | .tec2 => [.pol1, .sci1]
  | .tec3 => [.tec1, .tec2]
  | .tec4 => [.cry2, .sci3]
  | .tec5 => [.sci2, .tec3]
  | .tec6 => [.tec1, .tec4]
  | .tec7 => [.pol3, .tec5]
  | .hyp1 => [.eth2, .tec1]
  | .hyp2 => [.tec6, .tec7]
  | .hyp3 => [.sci3, .tec3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 凍土の物理学的制約。熱力学法則に基づく不変条件。 (ord=5) -/
  | cryosphere
  /-- 先住民の権利と国際データ公開義務。倫理的不可侵。 (ord=4) -/
  | ethics
  /-- 政策判断に影響する不確実性管理。社会的責任。 (ord=3) -/
  | policy
  /-- 気候科学者が管理するモデルパラメータ。研究進展で更新。 (ord=2) -/
  | science
  /-- AIのデータ処理・予測手法。改善可能。 (ord=1) -/
  | technique
  /-- 検証待ちの仮説。フィールドデータで確認。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .cryosphere => 5
  | .ethics => 4
  | .policy => 3
  | .science => 2
  | .technique => 1
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
  nontrivial := ⟨.cryosphere, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- cryosphere
  | .cry1 | .cry2 => .cryosphere
  -- ethics
  | .eth1 | .eth2 | .eth3 => .ethics
  -- policy
  | .pol1 | .pol2 | .pol3 => .policy
  -- science
  | .sci1 | .sci2 | .sci3 => .science
  -- technique
  | .tec1 | .tec2 | .tec3 | .tec4 | .tec5 | .tec6 | .tec7 => .technique
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

end Scenario279

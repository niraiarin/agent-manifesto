/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **climate_science** (ord=5): 気候学・土壌学の基本法則。水収支・蒸発散 [C1]
- **unccd_framework** (ord=4): 国連砂漠化対処条約（UNCCD）の指標体系 [C2, C3]
- **remote_sensing** (ord=3): 衛星リモートセンシングの物理モデル。NDVI・土壌水分指標 [H1, C4]
- **degradation_model** (ord=2): 土地劣化評価モデル。LDN指標・生産性動態 [H2, H3]
- **intervention** (ord=1): 緑化・土壌保全介入の効果推定 [H4, H5]
- **projection** (ord=0): 砂漠化進行の将来予測仮説 [H6]
-/

namespace TestScenario.S269

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | cs1
  | cs2
  | uf1
  | uf2
  | rs1
  | rs2
  | dm1
  | dm2
  | dm3
  | iv1
  | iv2
  | pj1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .cs1 => []
  | .cs2 => []
  | .uf1 => [.cs1]
  | .uf2 => []
  | .rs1 => [.cs1, .uf1]
  | .rs2 => [.cs2]
  | .dm1 => [.rs1, .uf2]
  | .dm2 => [.rs2]
  | .dm3 => [.rs1, .rs2]
  | .iv1 => [.dm1, .dm2]
  | .iv2 => [.dm3, .uf1]
  | .pj1 => [.iv1, .iv2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 気候学・土壌学の基本法則。水収支・蒸発散 (ord=5) -/
  | climate_science
  /-- 国連砂漠化対処条約（UNCCD）の指標体系 (ord=4) -/
  | unccd_framework
  /-- 衛星リモートセンシングの物理モデル。NDVI・土壌水分指標 (ord=3) -/
  | remote_sensing
  /-- 土地劣化評価モデル。LDN指標・生産性動態 (ord=2) -/
  | degradation_model
  /-- 緑化・土壌保全介入の効果推定 (ord=1) -/
  | intervention
  /-- 砂漠化進行の将来予測仮説 (ord=0) -/
  | projection
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .climate_science => 5
  | .unccd_framework => 4
  | .remote_sensing => 3
  | .degradation_model => 2
  | .intervention => 1
  | .projection => 0

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
  bottom := .projection
  nontrivial := ⟨.climate_science, .projection, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- climate_science
  | .cs1 | .cs2 => .climate_science
  -- unccd_framework
  | .uf1 | .uf2 => .unccd_framework
  -- remote_sensing
  | .rs1 | .rs2 => .remote_sensing
  -- degradation_model
  | .dm1 | .dm2 | .dm3 => .degradation_model
  -- intervention
  | .iv1 | .iv2 => .intervention
  -- projection
  | .pj1 => .projection

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

end TestScenario.S269

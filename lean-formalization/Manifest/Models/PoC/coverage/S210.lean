/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=6): 設備・人員安全の絶対制約 [C1]
- **regulation** (ord=5): 環境規制・漁業権等の法的制約 [C2, H1]
- **oceanography** (ord=4): 海洋物理・潮汐モデル [H2, H3]
- **engineering** (ord=3): タービン設計・構造工学制約 [C3, H4]
- **grid** (ord=2): 送電網・系統連系の外部依存 [H5, H6]
- **optimization** (ord=1): 発電最適化アルゴリズム [C4, H7]
- **hypothesis** (ord=0): 未検証の仮説 [H8]
-/

namespace TidalPowerOptimization

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | regu1
  | regu2
  | ocn1
  | ocn2
  | eng1
  | eng2
  | grd1
  | grd2
  | opt1
  | opt2
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .regu1 => [.safe1]
  | .regu2 => []
  | .ocn1 => []
  | .ocn2 => [.ocn1]
  | .eng1 => [.safe1, .ocn1]
  | .eng2 => [.regu1, .ocn2]
  | .grd1 => []
  | .grd2 => [.eng1, .grd1]
  | .opt1 => [.eng2, .grd2]
  | .opt2 => [.ocn2, .grd1]
  | .hyp1 => [.opt1]
  | .hyp2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 設備・人員安全の絶対制約 (ord=6) -/
  | safety
  /-- 環境規制・漁業権等の法的制約 (ord=5) -/
  | regulation
  /-- 海洋物理・潮汐モデル (ord=4) -/
  | oceanography
  /-- タービン設計・構造工学制約 (ord=3) -/
  | engineering
  /-- 送電網・系統連系の外部依存 (ord=2) -/
  | grid
  /-- 発電最適化アルゴリズム (ord=1) -/
  | optimization
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 6
  | .regulation => 5
  | .oceanography => 4
  | .engineering => 3
  | .grid => 2
  | .optimization => 1
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
  nontrivial := ⟨.safety, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety
  | .safe1 => .safety
  -- regulation
  | .regu1 | .regu2 => .regulation
  -- oceanography
  | .ocn1 | .ocn2 => .oceanography
  -- engineering
  | .eng1 | .eng2 => .engineering
  -- grid
  | .grd1 | .grd2 => .grid
  -- optimization
  | .opt1 | .opt2 => .optimization
  -- hypothesis
  | .hyp1 | .hyp2 => .hypothesis

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

end TidalPowerOptimization

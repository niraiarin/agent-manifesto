/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **pharma** (ord=4): 薬事規制・温度管理基準。法的に不変。 [C1, C4]
- **publicHealth** (ord=3): 公衆衛生当局の方針。政策で決定。 [C2, C5]
- **logistics** (ord=2): 物流・在庫制約。インフラで決定。 [C3]
- **optimization** (ord=1): 配送最適化アルゴリズムの設計方針。技術で変更可能。 [H1, H2, H3, H4]
- **hyp** (ord=0): 未検証の仮説。実運用データで検証が必要。 [H4]
-/

namespace Scenario220

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | pha1
  | pha2
  | pha3
  | pub1
  | pub2
  | pub3
  | log1
  | log2
  | log3
  | opt1
  | opt2
  | opt3
  | opt4
  | opt5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .pha1 => []
  | .pha2 => []
  | .pha3 => []
  | .pub1 => [.pha1]
  | .pub2 => [.pha1, .pha2]
  | .pub3 => [.pha3]
  | .log1 => [.pha2, .pub1]
  | .log2 => [.pub2]
  | .log3 => [.pha3, .pub3]
  | .opt1 => [.pha1, .pha2, .log1]
  | .opt2 => [.pub1, .log1, .log2]
  | .opt3 => [.pub2, .pub3]
  | .opt4 => [.pha2, .log1, .log3]
  | .opt5 => [.log2, .log3]
  | .hyp1 => [.opt1, .opt4]
  | .hyp2 => [.opt2, .opt5]
  | .hyp3 => [.opt3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 薬事規制・温度管理基準。法的に不変。 (ord=4) -/
  | pharma
  /-- 公衆衛生当局の方針。政策で決定。 (ord=3) -/
  | publicHealth
  /-- 物流・在庫制約。インフラで決定。 (ord=2) -/
  | logistics
  /-- 配送最適化アルゴリズムの設計方針。技術で変更可能。 (ord=1) -/
  | optimization
  /-- 未検証の仮説。実運用データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .pharma => 4
  | .publicHealth => 3
  | .logistics => 2
  | .optimization => 1
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
  nontrivial := ⟨.pharma, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- pharma
  | .pha1 | .pha2 | .pha3 => .pharma
  -- publicHealth
  | .pub1 | .pub2 | .pub3 => .publicHealth
  -- logistics
  | .log1 | .log2 | .log3 => .logistics
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 => .optimization
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

end Scenario220

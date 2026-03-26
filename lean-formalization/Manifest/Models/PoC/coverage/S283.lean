/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **governance** (ord=4): 防災行政の法的枠組みと権限構造。法令で規定。 [C1]
- **infrastructure** (ord=3): 河川・堤防・センサーの物理的特性。変更に年単位を要する。 [C2, C4, C5]
- **operational** (ord=2): 運用者が設定する予測パラメータと出力形式。 [C3, C6]
- **model** (ord=1): 予測モデルの設計判断。データと知見で改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。実運用で検証が必要。 [H4]
-/

namespace Scenario283

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | gov1
  | gov2
  | inf1
  | inf2
  | inf3
  | inf4
  | ops1
  | ops2
  | ops3
  | mdl1
  | mdl2
  | mdl3
  | mdl4
  | mdl5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .gov1 => []
  | .gov2 => []
  | .inf1 => []
  | .inf2 => []
  | .inf3 => []
  | .inf4 => [.inf1, .inf2]
  | .ops1 => [.gov1]
  | .ops2 => [.gov1, .gov2]
  | .ops3 => [.inf4, .ops1]
  | .mdl1 => [.inf1, .inf2]
  | .mdl2 => [.inf4, .ops1]
  | .mdl3 => [.inf3, .mdl1]
  | .mdl4 => [.mdl1, .mdl2]
  | .mdl5 => [.ops3, .mdl3]
  | .hyp1 => [.ops2, .mdl4]
  | .hyp2 => [.mdl5]
  | .hyp3 => [.hyp1, .hyp2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 防災行政の法的枠組みと権限構造。法令で規定。 (ord=4) -/
  | governance
  /-- 河川・堤防・センサーの物理的特性。変更に年単位を要する。 (ord=3) -/
  | infrastructure
  /-- 運用者が設定する予測パラメータと出力形式。 (ord=2) -/
  | operational
  /-- 予測モデルの設計判断。データと知見で改善可能。 (ord=1) -/
  | model
  /-- 未検証の仮説。実運用で検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .governance => 4
  | .infrastructure => 3
  | .operational => 2
  | .model => 1
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
  nontrivial := ⟨.governance, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- governance
  | .gov1 | .gov2 => .governance
  -- infrastructure
  | .inf1 | .inf2 | .inf3 | .inf4 => .infrastructure
  -- operational
  | .ops1 | .ops2 | .ops3 => .operational
  -- model
  | .mdl1 | .mdl2 | .mdl3 | .mdl4 | .mdl5 => .model
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

end Scenario283

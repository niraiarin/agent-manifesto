/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **immutable_protocol** (ord=4): ブロックチェーンプロトコル仕様・暗号学的保証など不変の前提 [C1, C2]
- **network_assumption** (ord=3): ネットワーク状態・コンセンサスの健全性に関する経験的仮定 [C3, H1]
- **detection_policy** (ord=2): 異常検知の閾値・分類方針・アラート基準 [C4, H2, H3]
- **tuning_parameter** (ord=1): 感度パラメータ・学習率・ウィンドウサイズなどの運用調整値 [C5, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | t1
  | t4
  | t6
  | e1
  | e2
  | p1
  | p2
  | p5
  | l1
  | l2
  | d1
  | d8
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .t1 => []
  | .t4 => []
  | .t6 => []
  | .e1 => []
  | .e2 => []
  | .p1 => []
  | .p2 => []
  | .p5 => []
  | .l1 => []
  | .l2 => []
  | .d1 => []
  | .d8 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- ブロックチェーンプロトコル仕様・暗号学的保証など不変の前提 (ord=4) -/
  | immutable_protocol
  /-- ネットワーク状態・コンセンサスの健全性に関する経験的仮定 (ord=3) -/
  | network_assumption
  /-- 異常検知の閾値・分類方針・アラート基準 (ord=2) -/
  | detection_policy
  /-- 感度パラメータ・学習率・ウィンドウサイズなどの運用調整値 (ord=1) -/
  | tuning_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .immutable_protocol => 4
  | .network_assumption => 3
  | .detection_policy => 2
  | .tuning_parameter => 1

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
  bottom := .tuning_parameter
  nontrivial := ⟨.immutable_protocol, .tuning_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- immutable_protocol
  | .t1 | .t4 | .t6 => .immutable_protocol
  -- network_assumption
  | .e1 | .e2 | .p1 => .network_assumption
  -- detection_policy
  | .p2 | .p5 | .l1 | .l2 => .detection_policy
  -- tuning_parameter
  | .d1 | .d8 => .tuning_parameter

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

end Manifest.Models

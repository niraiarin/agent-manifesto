/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **legal_constraint** (ord=4): 個人情報保護法・生体情報規制など法的に不変の制約 [C1, C2]
- **biometric_assumption** (ord=3): 顔認証精度・生体情報の特性に関する経験的前提 [C3, H1]
- **access_policy** (ord=2): 入退室ポリシー・認証フロー・フォールバック手順 [C4, C5, H2, H3]
- **operational_param** (ord=1): 認証閾値・カメラ設定・照合速度などの運用パラメータ [C6, H4, H5]
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
  | t7
  | e1
  | e2
  | p1
  | p2
  | p5
  | l1
  | l2
  | l3
  | d1
  | d8
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .t1 => []
  | .t4 => []
  | .t6 => []
  | .t7 => []
  | .e1 => []
  | .e2 => []
  | .p1 => []
  | .p2 => []
  | .p5 => []
  | .l1 => []
  | .l2 => []
  | .l3 => []
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
  /-- 個人情報保護法・生体情報規制など法的に不変の制約 (ord=4) -/
  | legal_constraint
  /-- 顔認証精度・生体情報の特性に関する経験的前提 (ord=3) -/
  | biometric_assumption
  /-- 入退室ポリシー・認証フロー・フォールバック手順 (ord=2) -/
  | access_policy
  /-- 認証閾値・カメラ設定・照合速度などの運用パラメータ (ord=1) -/
  | operational_param
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .legal_constraint => 4
  | .biometric_assumption => 3
  | .access_policy => 2
  | .operational_param => 1

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
  bottom := .operational_param
  nontrivial := ⟨.legal_constraint, .operational_param, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- legal_constraint
  | .t1 | .t4 | .t6 | .t7 => .legal_constraint
  -- biometric_assumption
  | .e1 | .e2 | .p1 => .biometric_assumption
  -- access_policy
  | .p2 | .p5 | .l1 | .l2 | .d8 => .access_policy
  -- operational_param
  | .l3 | .d1 => .operational_param

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

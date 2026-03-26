/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety_law** (ord=5): 公共安全に関する法的・物理的不変制約 [C1]
- **inspection_standard** (ord=4): 点検基準・診断精度に関する要件 [C2, C3]
- **engineering_rule** (ord=3): 工学的な判断ルール [C4, H1]
- **data_policy** (ord=2): データ取得・管理に関する制約 [C5, H2]
- **model_choice** (ord=1): モデル・手法の選択 [H3, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | prop_53fa17
  | prop_dd4cb3
  | prop_210633
  | prop_19aa9c
  | ASR_048a45
  | prop_f80f23
  | mmpixel_f48a9b
  | prop_2b7216
  | prop_d9bbad
  | prop_c9b59b
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .prop_53fa17 => []
  | .prop_dd4cb3 => []
  | .prop_210633 => []
  | .prop_19aa9c => []
  | .ASR_048a45 => []
  | .prop_f80f23 => []
  | .mmpixel_f48a9b => []
  | .prop_2b7216 => []
  | .prop_d9bbad => []
  | .prop_c9b59b => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 公共安全に関する法的・物理的不変制約 (ord=5) -/
  | safety_law
  /-- 点検基準・診断精度に関する要件 (ord=4) -/
  | inspection_standard
  /-- 工学的な判断ルール (ord=3) -/
  | engineering_rule
  /-- データ取得・管理に関する制約 (ord=2) -/
  | data_policy
  /-- モデル・手法の選択 (ord=1) -/
  | model_choice
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety_law => 5
  | .inspection_standard => 4
  | .engineering_rule => 3
  | .data_policy => 2
  | .model_choice => 1

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
  bottom := .model_choice
  nontrivial := ⟨.safety_law, .model_choice, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety_law
  | .prop_53fa17 | .prop_dd4cb3 => .safety_law
  -- inspection_standard
  | .prop_210633 | .prop_19aa9c | .prop_c9b59b => .inspection_standard
  -- engineering_rule
  | .ASR_048a45 | .prop_f80f23 => .engineering_rule
  -- data_policy
  | .mmpixel_f48a9b | .prop_2b7216 => .data_policy
  -- model_choice
  | .prop_d9bbad => .model_choice

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

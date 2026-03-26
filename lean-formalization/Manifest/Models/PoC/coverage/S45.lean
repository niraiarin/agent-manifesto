/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **privacy_law** (ord=4): プライバシー保護法・肖像権・監視カメラ設置基準など法的制約 [C1, C2]
- **detection_capability** (ord=3): 物体検出・行動認識モデルの精度と限界に関する経験的前提 [C3, H1]
- **alert_policy** (ord=2): 異常行動の定義・通報基準・人間確認フロー [C4, C5, H2, H3]
- **camera_parameter** (ord=1): カメラ配置・解像度・録画保持期間などの運用パラメータ [C6, H4]
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
  /-- プライバシー保護法・肖像権・監視カメラ設置基準など法的制約 (ord=4) -/
  | privacy_law
  /-- 物体検出・行動認識モデルの精度と限界に関する経験的前提 (ord=3) -/
  | detection_capability
  /-- 異常行動の定義・通報基準・人間確認フロー (ord=2) -/
  | alert_policy
  /-- カメラ配置・解像度・録画保持期間などの運用パラメータ (ord=1) -/
  | camera_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .privacy_law => 4
  | .detection_capability => 3
  | .alert_policy => 2
  | .camera_parameter => 1

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
  bottom := .camera_parameter
  nontrivial := ⟨.privacy_law, .camera_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- privacy_law
  | .t1 | .t4 | .t6 => .privacy_law
  -- detection_capability
  | .e1 | .e2 | .p1 => .detection_capability
  -- alert_policy
  | .p2 | .p5 | .l1 | .l2 => .alert_policy
  -- camera_parameter
  | .d1 | .d8 => .camera_parameter

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

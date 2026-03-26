/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **seismological_law** (ord=5): 地震学の基本法則・P波S波の伝播特性・気象庁基準 [C1, C2]
- **safety_mandate** (ord=4): 人命保護の絶対優先・誤報許容の判断基準 [C3, H1]
- **sensor_model** (ord=3): 地震計ネットワークの精度・遅延・カバレッジに関する経験的仮定 [C4, H2]
- **alert_policy** (ord=2): 警報発出基準・段階的通知・フォールバック手順 [C5, H3, H4]
- **system_parameter** (ord=1): 処理遅延・通信帯域・表示フォーマットなどの運用パラメータ [C6, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | t1
  | t3
  | t6
  | t7
  | t8
  | e1
  | e2
  | p1
  | p4
  | p5
  | p6
  | l1
  | d1
  | d5
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .t1 => []
  | .t3 => []
  | .t6 => []
  | .t7 => []
  | .t8 => []
  | .e1 => []
  | .e2 => []
  | .p1 => []
  | .p4 => []
  | .p5 => []
  | .p6 => []
  | .l1 => []
  | .d1 => []
  | .d5 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地震学の基本法則・P波S波の伝播特性・気象庁基準 (ord=5) -/
  | seismological_law
  /-- 人命保護の絶対優先・誤報許容の判断基準 (ord=4) -/
  | safety_mandate
  /-- 地震計ネットワークの精度・遅延・カバレッジに関する経験的仮定 (ord=3) -/
  | sensor_model
  /-- 警報発出基準・段階的通知・フォールバック手順 (ord=2) -/
  | alert_policy
  /-- 処理遅延・通信帯域・表示フォーマットなどの運用パラメータ (ord=1) -/
  | system_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .seismological_law => 5
  | .safety_mandate => 4
  | .sensor_model => 3
  | .alert_policy => 2
  | .system_parameter => 1

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
  bottom := .system_parameter
  nontrivial := ⟨.seismological_law, .system_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- seismological_law
  | .t1 | .t3 | .t6 => .seismological_law
  -- safety_mandate
  | .t7 | .t8 => .safety_mandate
  -- sensor_model
  | .e1 | .e2 | .p1 => .sensor_model
  -- alert_policy
  | .p4 | .p5 | .p6 | .l1 => .alert_policy
  -- system_parameter
  | .d1 | .d5 => .system_parameter

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

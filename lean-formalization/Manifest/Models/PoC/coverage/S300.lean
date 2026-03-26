/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **collision_safety** (ord=7): 衝突・接触防止の絶対不変制約 [C1, C2]
- **system_liveness** (ord=6): デッドロック回避・緊急停止の生存性保証 [C3, C4]
- **comm_resilience** (ord=5): 通信途絶時のフェイルセーフ [C5]
- **production_rule** (ord=4): 製造ラインの搬送優先度ルール [C6]
- **path_planning** (ord=3): 経路計画・予約アルゴリズムの設計 [H1]
- **perception_method** (ord=2): 人間検知・障害物認識の手法 [H2]
- **optimization_model** (ord=1): 搬送順序最適化の仮説 [H3, H4]
-/

namespace AGVFleetControl

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | no_agv_collision
  | human_safe_zone
  | no_deadlock
  | instant_estop
  | comm_loss_stop
  | dual_radio
  | line_priority
  | spatiotemporal_rsv
  | dynamic_replan
  | lidar_camera_fusion
  | occlusion_handling
  | mip_scheduling
  | realtime_heuristic
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .no_agv_collision => []
  | .human_safe_zone => []
  | .no_deadlock => [.no_agv_collision]
  | .instant_estop => [.no_agv_collision, .human_safe_zone]
  | .comm_loss_stop => [.instant_estop]
  | .dual_radio => [.comm_loss_stop]
  | .line_priority => [.no_deadlock]
  | .spatiotemporal_rsv => [.no_deadlock, .no_agv_collision]
  | .dynamic_replan => [.spatiotemporal_rsv, .human_safe_zone]
  | .lidar_camera_fusion => [.human_safe_zone]
  | .occlusion_handling => [.lidar_camera_fusion]
  | .mip_scheduling => [.line_priority, .spatiotemporal_rsv]
  | .realtime_heuristic => [.mip_scheduling]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 衝突・接触防止の絶対不変制約 (ord=7) -/
  | collision_safety
  /-- デッドロック回避・緊急停止の生存性保証 (ord=6) -/
  | system_liveness
  /-- 通信途絶時のフェイルセーフ (ord=5) -/
  | comm_resilience
  /-- 製造ラインの搬送優先度ルール (ord=4) -/
  | production_rule
  /-- 経路計画・予約アルゴリズムの設計 (ord=3) -/
  | path_planning
  /-- 人間検知・障害物認識の手法 (ord=2) -/
  | perception_method
  /-- 搬送順序最適化の仮説 (ord=1) -/
  | optimization_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .collision_safety => 7
  | .system_liveness => 6
  | .comm_resilience => 5
  | .production_rule => 4
  | .path_planning => 3
  | .perception_method => 2
  | .optimization_model => 1

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
  bottom := .optimization_model
  nontrivial := ⟨.collision_safety, .optimization_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨7, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- collision_safety
  | .no_agv_collision | .human_safe_zone => .collision_safety
  -- system_liveness
  | .no_deadlock | .instant_estop => .system_liveness
  -- comm_resilience
  | .comm_loss_stop | .dual_radio => .comm_resilience
  -- production_rule
  | .line_priority => .production_rule
  -- path_planning
  | .spatiotemporal_rsv | .dynamic_replan => .path_planning
  -- perception_method
  | .lidar_camera_fusion | .occlusion_handling => .perception_method
  -- optimization_model
  | .mip_scheduling | .realtime_heuristic => .optimization_model

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

end AGVFleetControl

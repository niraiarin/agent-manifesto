/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **health_safety** (ord=4): 公衆衛生・安全基準の絶対条件 [C1, C2]
- **sensor_infra** (ord=3): センサー・通信インフラの物理制約 [H1, H2, H3]
- **monitoring_policy** (ord=2): 管理者が設定する監視・通報方針 [C3, C4]
- **anomaly_detection** (ord=1): AIが自動判定する異常検知・予測 [H4, H5]
-/

namespace TestCoverage.S16

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | hs1
  | hs2
  | si1
  | si2
  | si3
  | mp1
  | mp2
  | mp3
  | ad1
  | ad2
  | ad3
  | ad4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .hs1 => []
  | .hs2 => []
  | .si1 => []
  | .si2 => [.hs1]
  | .si3 => []
  | .mp1 => [.hs1, .si1]
  | .mp2 => [.hs2, .si2]
  | .mp3 => [.si3]
  | .ad1 => [.mp1, .si1]
  | .ad2 => [.mp2]
  | .ad3 => [.mp3, .si3]
  | .ad4 => [.ad1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 公衆衛生・安全基準の絶対条件 (ord=4) -/
  | health_safety
  /-- センサー・通信インフラの物理制約 (ord=3) -/
  | sensor_infra
  /-- 管理者が設定する監視・通報方針 (ord=2) -/
  | monitoring_policy
  /-- AIが自動判定する異常検知・予測 (ord=1) -/
  | anomaly_detection
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .health_safety => 4
  | .sensor_infra => 3
  | .monitoring_policy => 2
  | .anomaly_detection => 1

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
  bottom := .anomaly_detection
  nontrivial := ⟨.health_safety, .anomaly_detection, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- health_safety
  | .hs1 | .hs2 => .health_safety
  -- sensor_infra
  | .si1 | .si2 | .si3 => .sensor_infra
  -- monitoring_policy
  | .mp1 | .mp2 | .mp3 => .monitoring_policy
  -- anomaly_detection
  | .ad1 | .ad2 | .ad3 | .ad4 => .anomaly_detection

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

end TestCoverage.S16

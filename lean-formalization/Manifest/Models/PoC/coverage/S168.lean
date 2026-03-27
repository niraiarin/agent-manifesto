/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **vestibularPhysiology** (ord=4): 前庭系と視覚系の感覚統合に関する生理学的原理 [C1]
- **motionSicknessModel** (ord=3): VR酔いの定量モデルと予測因子 [H1, H2]
- **renderingConstraint** (ord=2): フレームレート・遅延の許容閾値 [C2, H3]
- **adaptiveIntervention** (ord=1): 酔い兆候検出時の動的介入手法 [H4, H5]
- **userProfile** (ord=0): 個人の酔い感受性プロファイル [H6]
-/

namespace TestScenario.S168

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | sensoryConflictTheory
  | otolithResponse
  | optokineticReflex
  | ssqScoring
  | vectionIntensity
  | postureInstability
  | motionToPhotonLatency
  | fovRendering
  | fpsFloorGuard
  | fovReduction
  | restFrameInsert
  | galvanicStimHint
  | susceptibilityScore
  | sessionDurationLimit
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .sensoryConflictTheory => []
  | .otolithResponse => []
  | .optokineticReflex => []
  | .ssqScoring => [.sensoryConflictTheory]
  | .vectionIntensity => [.optokineticReflex]
  | .postureInstability => [.otolithResponse, .ssqScoring]
  | .motionToPhotonLatency => [.sensoryConflictTheory]
  | .fovRendering => [.motionToPhotonLatency, .vectionIntensity]
  | .fpsFloorGuard => [.motionToPhotonLatency]
  | .fovReduction => [.vectionIntensity, .fovRendering]
  | .restFrameInsert => [.sensoryConflictTheory, .fovReduction]
  | .galvanicStimHint => [.otolithResponse, .postureInstability]
  | .susceptibilityScore => [.ssqScoring, .postureInstability]
  | .sessionDurationLimit => [.susceptibilityScore, .restFrameInsert]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 前庭系と視覚系の感覚統合に関する生理学的原理 (ord=4) -/
  | vestibularPhysiology
  /-- VR酔いの定量モデルと予測因子 (ord=3) -/
  | motionSicknessModel
  /-- フレームレート・遅延の許容閾値 (ord=2) -/
  | renderingConstraint
  /-- 酔い兆候検出時の動的介入手法 (ord=1) -/
  | adaptiveIntervention
  /-- 個人の酔い感受性プロファイル (ord=0) -/
  | userProfile
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .vestibularPhysiology => 4
  | .motionSicknessModel => 3
  | .renderingConstraint => 2
  | .adaptiveIntervention => 1
  | .userProfile => 0

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
  bottom := .userProfile
  nontrivial := ⟨.vestibularPhysiology, .userProfile, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- vestibularPhysiology
  | .sensoryConflictTheory | .otolithResponse | .optokineticReflex => .vestibularPhysiology
  -- motionSicknessModel
  | .ssqScoring | .vectionIntensity | .postureInstability => .motionSicknessModel
  -- renderingConstraint
  | .motionToPhotonLatency | .fovRendering | .fpsFloorGuard => .renderingConstraint
  -- adaptiveIntervention
  | .fovReduction | .restFrameInsert | .galvanicStimHint => .adaptiveIntervention
  -- userProfile
  | .susceptibilityScore | .sessionDurationLimit => .userProfile

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

end TestScenario.S168

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PassengerSafety** (ord=7): 乗客の安全確保。過密状態での事故防止は最優先 [C1]
- **TransportRegulation** (ord=6): 鉄道営業法・国交省基準。法定遵守事項 [C2]
- **OperationalConstraint** (ord=5): ダイヤ・車両運用の物理的制約 [C3, H1]
- **DemandPattern** (ord=4): 乗客需要パターンの経験則。過去データに基づく [C4, H2]
- **InformationPolicy** (ord=3): 混雑情報の公開方針。利用者コミュニケーション [C5, H3]
- **PredictionModel** (ord=2): 混雑予測モデルの選択・パラメータ調整 [H4, H5]
- **BehaviorHypothesis** (ord=1): 混雑情報提供による旅客行動変容の仮説 [C6, H6]
-/

namespace TestCoverage.S108

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s108_p01
  | s108_p02
  | s108_p03
  | s108_p04
  | s108_p05
  | s108_p06
  | s108_p07
  | s108_p08
  | s108_p09
  | s108_p10
  | s108_p11
  | s108_p12
  | s108_p13
  | s108_p14
  | s108_p15
  | s108_p16
  | s108_p17
  | s108_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s108_p01 => []
  | .s108_p02 => [.s108_p01]
  | .s108_p03 => [.s108_p01]
  | .s108_p04 => [.s108_p02]
  | .s108_p05 => [.s108_p02, .s108_p03]
  | .s108_p06 => [.s108_p04]
  | .s108_p07 => [.s108_p04, .s108_p05]
  | .s108_p08 => [.s108_p05]
  | .s108_p09 => [.s108_p06]
  | .s108_p10 => [.s108_p07]
  | .s108_p11 => [.s108_p06, .s108_p08]
  | .s108_p12 => [.s108_p09]
  | .s108_p13 => [.s108_p10]
  | .s108_p14 => [.s108_p09, .s108_p11]
  | .s108_p15 => [.s108_p12]
  | .s108_p16 => [.s108_p13]
  | .s108_p17 => [.s108_p14]
  | .s108_p18 => [.s108_p15, .s108_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 乗客の安全確保。過密状態での事故防止は最優先 (ord=7) -/
  | PassengerSafety
  /-- 鉄道営業法・国交省基準。法定遵守事項 (ord=6) -/
  | TransportRegulation
  /-- ダイヤ・車両運用の物理的制約 (ord=5) -/
  | OperationalConstraint
  /-- 乗客需要パターンの経験則。過去データに基づく (ord=4) -/
  | DemandPattern
  /-- 混雑情報の公開方針。利用者コミュニケーション (ord=3) -/
  | InformationPolicy
  /-- 混雑予測モデルの選択・パラメータ調整 (ord=2) -/
  | PredictionModel
  /-- 混雑情報提供による旅客行動変容の仮説 (ord=1) -/
  | BehaviorHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PassengerSafety => 7
  | .TransportRegulation => 6
  | .OperationalConstraint => 5
  | .DemandPattern => 4
  | .InformationPolicy => 3
  | .PredictionModel => 2
  | .BehaviorHypothesis => 1

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
  bottom := .BehaviorHypothesis
  nontrivial := ⟨.PassengerSafety, .BehaviorHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨7, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PassengerSafety
  | .s108_p01 => .PassengerSafety
  -- TransportRegulation
  | .s108_p02 | .s108_p03 => .TransportRegulation
  -- OperationalConstraint
  | .s108_p04 | .s108_p05 => .OperationalConstraint
  -- DemandPattern
  | .s108_p06 | .s108_p07 | .s108_p08 => .DemandPattern
  -- InformationPolicy
  | .s108_p09 | .s108_p10 | .s108_p11 => .InformationPolicy
  -- PredictionModel
  | .s108_p12 | .s108_p13 | .s108_p14 => .PredictionModel
  -- BehaviorHypothesis
  | .s108_p15 | .s108_p16 | .s108_p17 | .s108_p18 => .BehaviorHypothesis

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

end TestCoverage.S108

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **RadiationSafetyInvariant** (ord=6): 放射線被曝防止・施設外漏洩禁止の絶対安全制約。いかなる状況でも違反不可 [C1, C2]
- **NuclearRegulation** (ord=5): 原子力規制法・IAEA安全基準・施設使用許可条件への厳格な準拠 [C3, C4]
- **FacilityProtectionPolicy** (ord=4): 超電導磁石保護・ビームダンプ動作・緊急停止手順の施設保護方針 [C5, C6]
- **ExperimentalProtocol** (ord=3): 衝突エネルギー設定・ルミノシティ管理・検出器運用の実験手順 [C7, H1, H2]
- **AcceleratorControl** (ord=2): ビーム調整・磁場制御・位相同期に関する運転制御ルール [H3, H4]
- **PhysicsHypothesis** (ord=1): 粒子軌道・衝突断面積・二次粒子生成に関する物理予測仮説 [H5, H6]
-/

namespace TestCoverage.S360

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s360_p01
  | s360_p02
  | s360_p03
  | s360_p04
  | s360_p05
  | s360_p06
  | s360_p07
  | s360_p08
  | s360_p09
  | s360_p10
  | s360_p11
  | s360_p12
  | s360_p13
  | s360_p14
  | s360_p15
  | s360_p16
  | s360_p17
  | s360_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s360_p01 => []
  | .s360_p02 => []
  | .s360_p03 => [.s360_p01]
  | .s360_p04 => [.s360_p01]
  | .s360_p05 => [.s360_p02]
  | .s360_p06 => [.s360_p04]
  | .s360_p07 => [.s360_p05]
  | .s360_p08 => [.s360_p03, .s360_p04]
  | .s360_p09 => [.s360_p06]
  | .s360_p10 => [.s360_p07]
  | .s360_p11 => [.s360_p08, .s360_p09]
  | .s360_p12 => [.s360_p09]
  | .s360_p13 => [.s360_p10]
  | .s360_p14 => [.s360_p11, .s360_p12]
  | .s360_p15 => [.s360_p12]
  | .s360_p16 => [.s360_p13]
  | .s360_p17 => [.s360_p14, .s360_p15]
  | .s360_p18 => [.s360_p16, .s360_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 放射線被曝防止・施設外漏洩禁止の絶対安全制約。いかなる状況でも違反不可 (ord=6) -/
  | RadiationSafetyInvariant
  /-- 原子力規制法・IAEA安全基準・施設使用許可条件への厳格な準拠 (ord=5) -/
  | NuclearRegulation
  /-- 超電導磁石保護・ビームダンプ動作・緊急停止手順の施設保護方針 (ord=4) -/
  | FacilityProtectionPolicy
  /-- 衝突エネルギー設定・ルミノシティ管理・検出器運用の実験手順 (ord=3) -/
  | ExperimentalProtocol
  /-- ビーム調整・磁場制御・位相同期に関する運転制御ルール (ord=2) -/
  | AcceleratorControl
  /-- 粒子軌道・衝突断面積・二次粒子生成に関する物理予測仮説 (ord=1) -/
  | PhysicsHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .RadiationSafetyInvariant => 6
  | .NuclearRegulation => 5
  | .FacilityProtectionPolicy => 4
  | .ExperimentalProtocol => 3
  | .AcceleratorControl => 2
  | .PhysicsHypothesis => 1

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
  bottom := .PhysicsHypothesis
  nontrivial := ⟨.RadiationSafetyInvariant, .PhysicsHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- RadiationSafetyInvariant
  | .s360_p01 | .s360_p02 | .s360_p03 => .RadiationSafetyInvariant
  -- NuclearRegulation
  | .s360_p04 | .s360_p05 => .NuclearRegulation
  -- FacilityProtectionPolicy
  | .s360_p06 | .s360_p07 | .s360_p08 => .FacilityProtectionPolicy
  -- ExperimentalProtocol
  | .s360_p09 | .s360_p10 | .s360_p11 => .ExperimentalProtocol
  -- AcceleratorControl
  | .s360_p12 | .s360_p13 | .s360_p14 => .AcceleratorControl
  -- PhysicsHypothesis
  | .s360_p15 | .s360_p16 | .s360_p17 | .s360_p18 => .PhysicsHypothesis

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

end TestCoverage.S360

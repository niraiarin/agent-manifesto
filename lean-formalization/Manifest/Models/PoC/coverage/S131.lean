/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **InfrastructureSafety** (ord=5): 水道インフラの安全制約。断水・汚染リスクに直結 [C1, C2]
- **RegulatoryStandard** (ord=4): 水道法・水質基準への準拠。法的義務 [C3, H1]
- **OperationalPolicy** (ord=3): 水道事業体の運用方針。組織判断で変更可能 [C4, H2]
- **DetectionMethod** (ord=2): 漏水検知手法の選択。技術進歩に応じて更新 [C5, H3]
- **MaintenanceHeuristic** (ord=1): 保守優先度の経験則。運用データで調整 [H4, H5]
-/

namespace TestCoverage.S131

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s131_p01
  | s131_p02
  | s131_p03
  | s131_p04
  | s131_p05
  | s131_p06
  | s131_p07
  | s131_p08
  | s131_p09
  | s131_p10
  | s131_p11
  | s131_p12
  | s131_p13
  | s131_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s131_p01 => []
  | .s131_p02 => []
  | .s131_p03 => []
  | .s131_p04 => [.s131_p01]
  | .s131_p05 => [.s131_p02]
  | .s131_p06 => [.s131_p04]
  | .s131_p07 => [.s131_p04, .s131_p05]
  | .s131_p08 => [.s131_p03]
  | .s131_p09 => [.s131_p06]
  | .s131_p10 => [.s131_p07]
  | .s131_p11 => [.s131_p06, .s131_p08]
  | .s131_p12 => [.s131_p09]
  | .s131_p13 => [.s131_p10]
  | .s131_p14 => [.s131_p11, .s131_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 水道インフラの安全制約。断水・汚染リスクに直結 (ord=5) -/
  | InfrastructureSafety
  /-- 水道法・水質基準への準拠。法的義務 (ord=4) -/
  | RegulatoryStandard
  /-- 水道事業体の運用方針。組織判断で変更可能 (ord=3) -/
  | OperationalPolicy
  /-- 漏水検知手法の選択。技術進歩に応じて更新 (ord=2) -/
  | DetectionMethod
  /-- 保守優先度の経験則。運用データで調整 (ord=1) -/
  | MaintenanceHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .InfrastructureSafety => 5
  | .RegulatoryStandard => 4
  | .OperationalPolicy => 3
  | .DetectionMethod => 2
  | .MaintenanceHeuristic => 1

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
  bottom := .MaintenanceHeuristic
  nontrivial := ⟨.InfrastructureSafety, .MaintenanceHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- InfrastructureSafety
  | .s131_p01 | .s131_p02 | .s131_p03 => .InfrastructureSafety
  -- RegulatoryStandard
  | .s131_p04 | .s131_p05 => .RegulatoryStandard
  -- OperationalPolicy
  | .s131_p06 | .s131_p07 | .s131_p08 => .OperationalPolicy
  -- DetectionMethod
  | .s131_p09 | .s131_p10 | .s131_p11 => .DetectionMethod
  -- MaintenanceHeuristic
  | .s131_p12 | .s131_p13 | .s131_p14 => .MaintenanceHeuristic

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

end TestCoverage.S131

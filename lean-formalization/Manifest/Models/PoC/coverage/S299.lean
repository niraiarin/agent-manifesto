/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **scientific_rigor** (ord=5): 不確実性定量化・補正適用の科学的厳密性 [C1, C4]
- **institutional_consistency** (ord=4): GRACE-FO連続性・IPCC整合の制度的要件 [C2, C3]
- **error_budget** (ord=3): 誤差配分・GIA不確実性の評価方針 [H1]
- **inversion_method** (ord=2): 重力場逆解析手法の選択 [H2]
- **sensor_model** (ord=1): 衛星センサー特性の仮説 [H3]
-/

namespace AntarcticIceSheetMonitoring

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | uncertainty_required
  | gia_correction
  | grace_fo_continuity
  | ipcc_reconcile
  | gia_dominance
  | error_partition
  | mascon_analysis
  | regularization_tune
  | kbr_precision
  | accelerometer_noise
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .uncertainty_required => []
  | .gia_correction => []
  | .grace_fo_continuity => [.uncertainty_required]
  | .ipcc_reconcile => [.uncertainty_required]
  | .gia_dominance => [.gia_correction, .uncertainty_required]
  | .error_partition => [.gia_dominance]
  | .mascon_analysis => [.gia_correction, .error_partition]
  | .regularization_tune => [.mascon_analysis]
  | .kbr_precision => [.grace_fo_continuity]
  | .accelerometer_noise => [.kbr_precision]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 不確実性定量化・補正適用の科学的厳密性 (ord=5) -/
  | scientific_rigor
  /-- GRACE-FO連続性・IPCC整合の制度的要件 (ord=4) -/
  | institutional_consistency
  /-- 誤差配分・GIA不確実性の評価方針 (ord=3) -/
  | error_budget
  /-- 重力場逆解析手法の選択 (ord=2) -/
  | inversion_method
  /-- 衛星センサー特性の仮説 (ord=1) -/
  | sensor_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .scientific_rigor => 5
  | .institutional_consistency => 4
  | .error_budget => 3
  | .inversion_method => 2
  | .sensor_model => 1

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
  bottom := .sensor_model
  nontrivial := ⟨.scientific_rigor, .sensor_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- scientific_rigor
  | .uncertainty_required | .gia_correction => .scientific_rigor
  -- institutional_consistency
  | .grace_fo_continuity | .ipcc_reconcile => .institutional_consistency
  -- error_budget
  | .gia_dominance | .error_partition => .error_budget
  -- inversion_method
  | .mascon_analysis | .regularization_tune => .inversion_method
  -- sensor_model
  | .kbr_precision | .accelerometer_noise => .sensor_model

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

end AntarcticIceSheetMonitoring

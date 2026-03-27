/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **medical_standard** (ord=3): 聴覚検査の医学的基準。ISO 8253・JIS規格準拠 [C1, C2]
- **audiometric_model** (ord=2): 聴力測定のモデル。純音・語音・ABR検査パラメータ [H1, C3]
- **adaptive_algorithm** (ord=1): 適応型検査アルゴリズム。閾値追跡・被検者応答解析 [H2, H3]
- **calibration_hypothesis** (ord=0): 環境騒音補正・機器校正の仮説 [H4]
-/

namespace TestScenario.S268

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | ms1
  | ms2
  | ms3
  | am1
  | am2
  | am3
  | aa1
  | aa2
  | ch1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .ms1 => []
  | .ms2 => []
  | .ms3 => []
  | .am1 => [.ms1]
  | .am2 => [.ms2, .ms3]
  | .am3 => [.ms1]
  | .aa1 => [.am1, .am2]
  | .aa2 => [.am3]
  | .ch1 => [.aa1, .aa2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 聴覚検査の医学的基準。ISO 8253・JIS規格準拠 (ord=3) -/
  | medical_standard
  /-- 聴力測定のモデル。純音・語音・ABR検査パラメータ (ord=2) -/
  | audiometric_model
  /-- 適応型検査アルゴリズム。閾値追跡・被検者応答解析 (ord=1) -/
  | adaptive_algorithm
  /-- 環境騒音補正・機器校正の仮説 (ord=0) -/
  | calibration_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .medical_standard => 3
  | .audiometric_model => 2
  | .adaptive_algorithm => 1
  | .calibration_hypothesis => 0

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
  bottom := .calibration_hypothesis
  nontrivial := ⟨.medical_standard, .calibration_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- medical_standard
  | .ms1 | .ms2 | .ms3 => .medical_standard
  -- audiometric_model
  | .am1 | .am2 | .am3 => .audiometric_model
  -- adaptive_algorithm
  | .aa1 | .aa2 => .adaptive_algorithm
  -- calibration_hypothesis
  | .ch1 => .calibration_hypothesis

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

end TestScenario.S268

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **HazardInvariant** (ord=5): 爆発・毒性漏洩・火災による人命・環境への損害禁止の絶対不変条件 [C1, C2]
- **RegulatoryCompliance** (ord=4): 高圧ガス保安法・労働安全衛生法・REACH規制への適合 [C3, C4]
- **SafetyPolicy** (ord=3): 緊急停止・立入制限・防護装備着用の安全方針 [C5, H1, H2]
- **ProcessControl** (ord=2): 温度・圧力・流量の制御限界と自動調整方針 [C6, C7, H3, H4]
- **AnomalyHypothesis** (ord=1): 異常予兆・設備劣化・反応暴走に関する推論仮説 [H5, H6]
-/

namespace TestCoverage.S344

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s344_p01
  | s344_p02
  | s344_p03
  | s344_p04
  | s344_p05
  | s344_p06
  | s344_p07
  | s344_p08
  | s344_p09
  | s344_p10
  | s344_p11
  | s344_p12
  | s344_p13
  | s344_p14
  | s344_p15
  | s344_p16
  | s344_p17
  | s344_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s344_p01 => []
  | .s344_p02 => []
  | .s344_p03 => [.s344_p01, .s344_p02]
  | .s344_p04 => [.s344_p01]
  | .s344_p05 => [.s344_p02]
  | .s344_p06 => [.s344_p04, .s344_p05]
  | .s344_p07 => [.s344_p03]
  | .s344_p08 => [.s344_p04]
  | .s344_p09 => [.s344_p07, .s344_p08]
  | .s344_p10 => [.s344_p06]
  | .s344_p11 => [.s344_p05]
  | .s344_p12 => [.s344_p09, .s344_p10]
  | .s344_p13 => [.s344_p11]
  | .s344_p14 => [.s344_p10]
  | .s344_p15 => [.s344_p11]
  | .s344_p16 => [.s344_p12, .s344_p14]
  | .s344_p17 => [.s344_p13, .s344_p15]
  | .s344_p18 => [.s344_p16, .s344_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 爆発・毒性漏洩・火災による人命・環境への損害禁止の絶対不変条件 (ord=5) -/
  | HazardInvariant
  /-- 高圧ガス保安法・労働安全衛生法・REACH規制への適合 (ord=4) -/
  | RegulatoryCompliance
  /-- 緊急停止・立入制限・防護装備着用の安全方針 (ord=3) -/
  | SafetyPolicy
  /-- 温度・圧力・流量の制御限界と自動調整方針 (ord=2) -/
  | ProcessControl
  /-- 異常予兆・設備劣化・反応暴走に関する推論仮説 (ord=1) -/
  | AnomalyHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .HazardInvariant => 5
  | .RegulatoryCompliance => 4
  | .SafetyPolicy => 3
  | .ProcessControl => 2
  | .AnomalyHypothesis => 1

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
  bottom := .AnomalyHypothesis
  nontrivial := ⟨.HazardInvariant, .AnomalyHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- HazardInvariant
  | .s344_p01 | .s344_p02 | .s344_p03 => .HazardInvariant
  -- RegulatoryCompliance
  | .s344_p04 | .s344_p05 | .s344_p06 => .RegulatoryCompliance
  -- SafetyPolicy
  | .s344_p07 | .s344_p08 | .s344_p09 => .SafetyPolicy
  -- ProcessControl
  | .s344_p10 | .s344_p11 | .s344_p12 | .s344_p13 => .ProcessControl
  -- AnomalyHypothesis
  | .s344_p14 | .s344_p15 | .s344_p16 | .s344_p17 | .s344_p18 => .AnomalyHypothesis

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

end TestCoverage.S344

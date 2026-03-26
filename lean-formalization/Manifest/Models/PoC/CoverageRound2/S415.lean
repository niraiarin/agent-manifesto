/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **RegulatoryMandate** (ord=3): 金融庁・証券取引等監視委員会・国際会計基準に基づく法定監査義務 [C1, C2, C3]
- **AuditMethodology** (ord=2): リスクベースアプローチ・サンプリング・証跡収集に関する監査手法方針 [C4, C5, H1, H2]
- **IntelligenceEnhancement** (ord=1): パターン認識・異常検知・予測分析による監査効率向上仮説 [C6, H3, H4, H5]
-/

namespace TestCoverage.S415

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s415_p01
  | s415_p02
  | s415_p03
  | s415_p04
  | s415_p05
  | s415_p06
  | s415_p07
  | s415_p08
  | s415_p09
  | s415_p10
  | s415_p11
  | s415_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s415_p01 => []
  | .s415_p02 => []
  | .s415_p03 => []
  | .s415_p04 => [.s415_p01, .s415_p02, .s415_p03]
  | .s415_p05 => [.s415_p01]
  | .s415_p06 => [.s415_p02, .s415_p03]
  | .s415_p07 => [.s415_p04, .s415_p05, .s415_p06]
  | .s415_p08 => [.s415_p05]
  | .s415_p09 => [.s415_p06]
  | .s415_p10 => [.s415_p07]
  | .s415_p11 => [.s415_p08, .s415_p09]
  | .s415_p12 => [.s415_p10, .s415_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 金融庁・証券取引等監視委員会・国際会計基準に基づく法定監査義務 (ord=3) -/
  | RegulatoryMandate
  /-- リスクベースアプローチ・サンプリング・証跡収集に関する監査手法方針 (ord=2) -/
  | AuditMethodology
  /-- パターン認識・異常検知・予測分析による監査効率向上仮説 (ord=1) -/
  | IntelligenceEnhancement
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .RegulatoryMandate => 3
  | .AuditMethodology => 2
  | .IntelligenceEnhancement => 1

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
  bottom := .IntelligenceEnhancement
  nontrivial := ⟨.RegulatoryMandate, .IntelligenceEnhancement, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- RegulatoryMandate
  | .s415_p01 | .s415_p02 | .s415_p03 | .s415_p04 => .RegulatoryMandate
  -- AuditMethodology
  | .s415_p05 | .s415_p06 | .s415_p07 => .AuditMethodology
  -- IntelligenceEnhancement
  | .s415_p08 | .s415_p09 | .s415_p10 | .s415_p11 | .s415_p12 => .IntelligenceEnhancement

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

end TestCoverage.S415

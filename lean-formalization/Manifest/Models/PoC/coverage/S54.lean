/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **compliance** (ord=3): 法規制・倫理に関わる不変条件 [C2, C5]
- **standard** (ord=2): 業界標準・フォーマット準拠 [C1, C4, C6]
- **quality** (ord=1): 翻訳品質に関する運用方針 [C3, H3, H4]
- **optimization** (ord=0): AIが自律的に最適化する処理戦略 [H1, H2, H5]
-/

namespace TranslationSubtitle

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | comp1
  | comp2
  | std1
  | std2
  | std3
  | qual1
  | qual2
  | qual3
  | qual4
  | opt1
  | opt2
  | opt3
  | opt4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .comp1 => []
  | .comp2 => []
  | .std1 => []
  | .std2 => []
  | .std3 => []
  | .qual1 => [.comp1]
  | .qual2 => [.comp1, .std2]
  | .qual3 => [.std2]
  | .qual4 => [.comp2]
  | .opt1 => [.std1]
  | .opt2 => [.std2, .qual3]
  | .opt3 => [.std1, .opt1]
  | .opt4 => [.std3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法規制・倫理に関わる不変条件 (ord=3) -/
  | compliance
  /-- 業界標準・フォーマット準拠 (ord=2) -/
  | standard
  /-- 翻訳品質に関する運用方針 (ord=1) -/
  | quality
  /-- AIが自律的に最適化する処理戦略 (ord=0) -/
  | optimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .compliance => 3
  | .standard => 2
  | .quality => 1
  | .optimization => 0

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
  bottom := .optimization
  nontrivial := ⟨.compliance, .optimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- compliance
  | .comp1 | .comp2 => .compliance
  -- standard
  | .std1 | .std2 | .std3 => .standard
  -- quality
  | .qual1 | .qual2 | .qual3 | .qual4 => .quality
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 => .optimization

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

end TranslationSubtitle

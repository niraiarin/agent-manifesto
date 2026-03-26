/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **braille_standard** (ord=3): 点字表記規則（日本点字表記法・UEB等）。文字体系の不変規則 [C1, C2]
- **mechanical_spec** (ord=2): プリンタ機構の物理仕様。ピン配置・用紙サイズ・打刻力 [C3, H1]
- **translation** (ord=1): 墨字→点字変換ロジック。略字・分かち書き・数式処理 [H2, H3]
- **optimization** (ord=0): 印刷速度・品質の最適化仮説 [H4]
-/

namespace TestScenario.S264

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | bs1
  | bs2
  | bs3
  | ms1
  | ms2
  | tr1
  | tr2
  | tr3
  | ot1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .bs1 => []
  | .bs2 => []
  | .bs3 => []
  | .ms1 => []
  | .ms2 => [.bs1]
  | .tr1 => [.bs1, .bs2]
  | .tr2 => [.bs3, .ms1]
  | .tr3 => [.ms2]
  | .ot1 => [.tr1, .ms1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 点字表記規則（日本点字表記法・UEB等）。文字体系の不変規則 (ord=3) -/
  | braille_standard
  /-- プリンタ機構の物理仕様。ピン配置・用紙サイズ・打刻力 (ord=2) -/
  | mechanical_spec
  /-- 墨字→点字変換ロジック。略字・分かち書き・数式処理 (ord=1) -/
  | translation
  /-- 印刷速度・品質の最適化仮説 (ord=0) -/
  | optimization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .braille_standard => 3
  | .mechanical_spec => 2
  | .translation => 1
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
  nontrivial := ⟨.braille_standard, .optimization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- braille_standard
  | .bs1 | .bs2 | .bs3 => .braille_standard
  -- mechanical_spec
  | .ms1 | .ms2 => .mechanical_spec
  -- translation
  | .tr1 | .tr2 | .tr3 => .translation
  -- optimization
  | .ot1 => .optimization

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

end TestScenario.S264

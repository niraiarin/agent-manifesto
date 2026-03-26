/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **judicial** (ord=4): 司法制度・裁判所規則による絶対的制約。AIが変更不可。 [C1, C4]
- **privacy** (ord=3): 個人情報保護とプライバシー権の保障。法的義務。 [C2]
- **editorial** (ord=2): 要約の編集方針と品質基準。免責事項の明示。 [C3]
- **processing** (ord=1): 音声認識・NLP・要約生成の技術的処理戦略。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の技術的仮説。実データで検証が必要。 [H1]
-/

namespace Scenario234

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | jud1
  | jud2
  | jud3
  | priv1
  | priv2
  | edit1
  | edit2
  | edit3
  | proc1
  | proc2
  | proc3
  | proc4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .jud1 => []
  | .jud2 => []
  | .jud3 => []
  | .priv1 => [.jud1]
  | .priv2 => [.jud1, .jud2]
  | .edit1 => [.jud1, .priv1]
  | .edit2 => [.priv2]
  | .edit3 => [.jud3, .priv1]
  | .proc1 => [.jud2, .edit1]
  | .proc2 => [.priv1, .priv2]
  | .proc3 => [.edit1, .edit3]
  | .proc4 => [.proc1, .proc3]
  | .hyp1 => [.proc1]
  | .hyp2 => [.proc2, .proc4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 司法制度・裁判所規則による絶対的制約。AIが変更不可。 (ord=4) -/
  | judicial
  /-- 個人情報保護とプライバシー権の保障。法的義務。 (ord=3) -/
  | privacy
  /-- 要約の編集方針と品質基準。免責事項の明示。 (ord=2) -/
  | editorial
  /-- 音声認識・NLP・要約生成の技術的処理戦略。 (ord=1) -/
  | processing
  /-- 未検証の技術的仮説。実データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .judicial => 4
  | .privacy => 3
  | .editorial => 2
  | .processing => 1
  | .hyp => 0

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
  bottom := .hyp
  nontrivial := ⟨.judicial, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- judicial
  | .jud1 | .jud2 | .jud3 => .judicial
  -- privacy
  | .priv1 | .priv2 => .privacy
  -- editorial
  | .edit1 | .edit2 | .edit3 => .editorial
  -- processing
  | .proc1 | .proc2 | .proc3 | .proc4 => .processing
  -- hyp
  | .hyp1 | .hyp2 => .hyp

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

end Scenario234

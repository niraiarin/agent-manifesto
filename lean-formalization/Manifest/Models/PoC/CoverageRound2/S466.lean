/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **UserSafetyInvariant** (ord=2): ユーザーの安全・プライバシー保護の絶対制約。有害情報提供・個人情報漏洩の禁止 [C1, C2, C3]
- **DialogueCapabilityHypothesis** (ord=1): 意図理解・文脈把握・応答生成に関する推論能力仮説。ユーザー行動から更新可能 [C4, H1, H2, H3, H4, H5]
-/

namespace TestCoverage.S466

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s466_p01
  | s466_p02
  | s466_p03
  | s466_p04
  | s466_p05
  | s466_p06
  | s466_p07
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s466_p01 => []
  | .s466_p02 => [.s466_p01]
  | .s466_p03 => [.s466_p01]
  | .s466_p04 => [.s466_p01]
  | .s466_p05 => [.s466_p02, .s466_p04]
  | .s466_p06 => [.s466_p03]
  | .s466_p07 => [.s466_p05, .s466_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- ユーザーの安全・プライバシー保護の絶対制約。有害情報提供・個人情報漏洩の禁止 (ord=2) -/
  | UserSafetyInvariant
  /-- 意図理解・文脈把握・応答生成に関する推論能力仮説。ユーザー行動から更新可能 (ord=1) -/
  | DialogueCapabilityHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .UserSafetyInvariant => 2
  | .DialogueCapabilityHypothesis => 1

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
  bottom := .DialogueCapabilityHypothesis
  nontrivial := ⟨.UserSafetyInvariant, .DialogueCapabilityHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- UserSafetyInvariant
  | .s466_p01 | .s466_p02 | .s466_p03 => .UserSafetyInvariant
  -- DialogueCapabilityHypothesis
  | .s466_p04 | .s466_p05 | .s466_p06 | .s466_p07 => .DialogueCapabilityHypothesis

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

end TestCoverage.S466

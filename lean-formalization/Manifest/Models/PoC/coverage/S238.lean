/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **medical** (ord=4): 医療制度上の制約。医師の判断権限とアナフィラキシー対応。 [C1, C2]
- **privacyHealth** (ord=3): 健康データのプライバシー保護。本人同意原則。 [C3]
- **clinical** (ord=2): 臨床エビデンスに基づく知見。症状と環境因子の相関。 [C4, H2]
- **prediction** (ord=1): AIによる症状予測と服薬推奨の戦略。 [H1, H4]
- **hyp** (ord=0): 未検証のアレルギー学的・統計的仮説。 [H3]
-/

namespace Scenario238

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | med1
  | med2
  | med3
  | phlt1
  | phlt2
  | clin1
  | clin2
  | clin3
  | pred1
  | pred2
  | pred3
  | pred4
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .med1 => []
  | .med2 => []
  | .med3 => []
  | .phlt1 => [.med1]
  | .phlt2 => [.med1, .med2]
  | .clin1 => [.med1]
  | .clin2 => [.med2, .med3]
  | .clin3 => [.clin1]
  | .pred1 => [.med1, .clin1, .clin2]
  | .pred2 => [.clin2, .clin3]
  | .pred3 => [.clin3, .pred1]
  | .pred4 => [.phlt1, .clin2]
  | .hyp1 => [.phlt2, .pred1]
  | .hyp2 => [.pred3, .pred4]
  | .hyp3 => [.pred2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医療制度上の制約。医師の判断権限とアナフィラキシー対応。 (ord=4) -/
  | medical
  /-- 健康データのプライバシー保護。本人同意原則。 (ord=3) -/
  | privacyHealth
  /-- 臨床エビデンスに基づく知見。症状と環境因子の相関。 (ord=2) -/
  | clinical
  /-- AIによる症状予測と服薬推奨の戦略。 (ord=1) -/
  | prediction
  /-- 未検証のアレルギー学的・統計的仮説。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .medical => 4
  | .privacyHealth => 3
  | .clinical => 2
  | .prediction => 1
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
  nontrivial := ⟨.medical, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- medical
  | .med1 | .med2 | .med3 => .medical
  -- privacyHealth
  | .phlt1 | .phlt2 => .privacyHealth
  -- clinical
  | .clin1 | .clin2 | .clin3 => .clinical
  -- prediction
  | .pred1 | .pred2 | .pred3 | .pred4 => .prediction
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 => .hyp

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

end Scenario238

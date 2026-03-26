/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physical** (ord=2): 弦の物理的限界と基準音高。破断張力は絶対制約。 [C1, C3]
- **tuning** (ord=1): 調律のアルゴリズムと品質評価基準。人間承認を前提。 [C2, H1, H2, H3]
- **hyp** (ord=0): 未検証の音響学的仮説。実機データで検証が必要。 [H2, H3]
-/

namespace Scenario236

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | phy1
  | phy2
  | phy3
  | tun1
  | tun2
  | tun3
  | tun4
  | tun5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .phy1 => []
  | .phy2 => []
  | .phy3 => []
  | .tun1 => [.phy1, .phy2]
  | .tun2 => [.phy1, .phy3]
  | .tun3 => [.phy2]
  | .tun4 => [.tun1, .tun2]
  | .tun5 => [.phy3, .tun3]
  | .hyp1 => [.tun3]
  | .hyp2 => [.tun4, .tun5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 弦の物理的限界と基準音高。破断張力は絶対制約。 (ord=2) -/
  | physical
  /-- 調律のアルゴリズムと品質評価基準。人間承認を前提。 (ord=1) -/
  | tuning
  /-- 未検証の音響学的仮説。実機データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physical => 2
  | .tuning => 1
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
  nontrivial := ⟨.physical, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physical
  | .phy1 | .phy2 | .phy3 => .physical
  -- tuning
  | .tun1 | .tun2 | .tun3 | .tun4 | .tun5 => .tuning
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

end Scenario236

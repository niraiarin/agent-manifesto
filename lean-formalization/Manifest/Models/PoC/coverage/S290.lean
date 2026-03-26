/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=4): 乗客安全に関する不可侵の基準。法的・社会的要件。 [C2]
- **operations** (ord=3): 運行判断の権限構造と意思決定プロセス。 [C1]
- **maintenance** (ord=2): 車両基地の保守手順と点検基準。メーカー推奨に準拠。 [C3, C5, C6]
- **prediction** (ord=1): AI予測モデルの設計判断。運用データで改善可能。 [C4, H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。フィールドデータで検証が必要。 [H4]
-/

namespace Scenario290

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | saf1
  | saf2
  | opr1
  | opr2
  | mnt1
  | mnt2
  | mnt3
  | mnt4
  | prd1
  | prd2
  | prd3
  | prd4
  | prd5
  | prd6
  | prd7
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .saf1 => []
  | .saf2 => []
  | .opr1 => [.saf1]
  | .opr2 => [.saf1, .saf2]
  | .mnt1 => [.saf1, .opr1]
  | .mnt2 => [.opr2]
  | .mnt3 => [.opr1, .mnt1]
  | .mnt4 => [.mnt1, .mnt2]
  | .prd1 => [.mnt2, .mnt4]
  | .prd2 => [.mnt1, .mnt4]
  | .prd3 => [.saf1, .mnt2]
  | .prd4 => [.mnt3]
  | .prd5 => [.prd1, .prd2]
  | .prd6 => [.prd2, .prd3]
  | .prd7 => [.prd1, .prd3, .prd4]
  | .hyp1 => [.prd5, .prd6]
  | .hyp2 => [.prd7]
  | .hyp3 => [.mnt3, .prd4]
  | .hyp4 => [.hyp1, .hyp2, .hyp3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 乗客安全に関する不可侵の基準。法的・社会的要件。 (ord=4) -/
  | safety
  /-- 運行判断の権限構造と意思決定プロセス。 (ord=3) -/
  | operations
  /-- 車両基地の保守手順と点検基準。メーカー推奨に準拠。 (ord=2) -/
  | maintenance
  /-- AI予測モデルの設計判断。運用データで改善可能。 (ord=1) -/
  | prediction
  /-- 未検証の仮説。フィールドデータで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 4
  | .operations => 3
  | .maintenance => 2
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
  nontrivial := ⟨.safety, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety
  | .saf1 | .saf2 => .safety
  -- operations
  | .opr1 | .opr2 => .operations
  -- maintenance
  | .mnt1 | .mnt2 | .mnt3 | .mnt4 => .maintenance
  -- prediction
  | .prd1 | .prd2 | .prd3 | .prd4 | .prd5 | .prd6 | .prd7 => .prediction
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 | .hyp4 => .hyp

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

end Scenario290

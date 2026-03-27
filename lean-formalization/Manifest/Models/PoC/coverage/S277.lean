/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=4): ハードウェア安全保護と環境規制。絶対不可侵。 [C1, C2]
- **grid** (ord=3): 電力系統からの要求。中央給電指令に基づく。 [C4]
- **operations** (ord=2): オペレーターの運転管理。燃料切替・メンテナンス。 [C3, C5]
- **optimization** (ord=1): AIの燃焼最適化手法。改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 検証待ちの仮説。運転データで確認。 [H4]
-/

namespace Scenario277

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | saf1
  | saf2
  | saf3
  | grd1
  | grd2
  | ops1
  | ops2
  | ops3
  | opt1
  | opt2
  | opt3
  | opt4
  | opt5
  | opt6
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .saf1 => []
  | .saf2 => []
  | .saf3 => []
  | .grd1 => [.saf1]
  | .grd2 => [.saf2, .saf3]
  | .ops1 => [.saf1, .grd1]
  | .ops2 => [.saf2]
  | .ops3 => [.ops1, .ops2]
  | .opt1 => [.saf1, .ops1]
  | .opt2 => [.saf2, .saf3]
  | .opt3 => [.grd1, .grd2]
  | .opt4 => [.opt1, .opt2]
  | .opt5 => [.ops3, .opt3]
  | .opt6 => [.opt2, .opt3]
  | .hyp1 => [.ops2, .opt4]
  | .hyp2 => [.opt5, .opt6]
  | .hyp3 => [.ops3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- ハードウェア安全保護と環境規制。絶対不可侵。 (ord=4) -/
  | safety
  /-- 電力系統からの要求。中央給電指令に基づく。 (ord=3) -/
  | grid
  /-- オペレーターの運転管理。燃料切替・メンテナンス。 (ord=2) -/
  | operations
  /-- AIの燃焼最適化手法。改善可能。 (ord=1) -/
  | optimization
  /-- 検証待ちの仮説。運転データで確認。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 4
  | .grid => 3
  | .operations => 2
  | .optimization => 1
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
  | .saf1 | .saf2 | .saf3 => .safety
  -- grid
  | .grd1 | .grd2 => .grid
  -- operations
  | .ops1 | .ops2 | .ops3 => .operations
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 | .opt6 => .optimization
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

end Scenario277

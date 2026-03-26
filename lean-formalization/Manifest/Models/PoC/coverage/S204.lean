/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ethics** (ord=6): 倫理的絶対制約（誤判定の影響） [C1, C2]
- **clinical** (ord=5): 臨床エビデンスに基づく医学的前提 [C3, H1]
- **regulation** (ord=4): 医療機器規制・個人情報保護 [C4, H2]
- **data** (ord=3): データ収集・品質の外部依存 [H3, H4]
- **early_detection** (ord=2): 早期検出アルゴリズム・閾値 [C5, H5]
- **ux** (ord=1): 保護者・専門家向けUI設計 [H6, H7]
- **hypothesis** (ord=0): 未検証の仮説 [H8]
-/

namespace ASDEarlyDetection

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | eth1
  | eth2
  | clin1
  | clin2
  | regu1
  | regu2
  | dat1
  | dat2
  | dat3
  | scr1
  | scr2
  | ux1
  | ux2
  | hyp1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .eth1 => []
  | .eth2 => []
  | .clin1 => [.eth1]
  | .clin2 => [.eth2]
  | .regu1 => [.eth1, .eth2]
  | .regu2 => [.clin1]
  | .dat1 => [.regu1]
  | .dat2 => []
  | .dat3 => []
  | .scr1 => [.clin1, .dat1]
  | .scr2 => [.dat3]
  | .ux1 => [.scr1, .eth1]
  | .ux2 => [.regu2]
  | .hyp1 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 倫理的絶対制約（誤判定の影響） (ord=6) -/
  | ethics
  /-- 臨床エビデンスに基づく医学的前提 (ord=5) -/
  | clinical
  /-- 医療機器規制・個人情報保護 (ord=4) -/
  | regulation
  /-- データ収集・品質の外部依存 (ord=3) -/
  | data
  /-- 早期検出アルゴリズム・閾値 (ord=2) -/
  | early_detection
  /-- 保護者・専門家向けUI設計 (ord=1) -/
  | ux
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ethics => 6
  | .clinical => 5
  | .regulation => 4
  | .data => 3
  | .early_detection => 2
  | .ux => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.ethics, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ethics
  | .eth1 | .eth2 => .ethics
  -- clinical
  | .clin1 | .clin2 => .clinical
  -- regulation
  | .regu1 | .regu2 => .regulation
  -- data
  | .dat1 | .dat2 | .dat3 => .data
  -- early_detection
  | .scr1 | .scr2 => .early_detection
  -- ux
  | .ux1 | .ux2 => .ux
  -- hypothesis
  | .hyp1 => .hypothesis

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

end ASDEarlyDetection

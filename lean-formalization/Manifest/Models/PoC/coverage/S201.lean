/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=4): 患者安全に直結する絶対制約 [C1, C2]
- **regulation** (ord=3): 法規制・ガイドライン要件 [C3, H1]
- **environment** (ord=2): 外部環境依存（HVAC・外気等） [H2, H3]
- **policy** (ord=1): 運用方針（閾値設定・アラート頻度） [C4, H4]
- **hypothesis** (ord=0): 未検証の仮説 [H5]
-/

namespace OperatingRoomAirQuality

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | safe2
  | safe3
  | reg1
  | reg2
  | env1
  | env2
  | pol1
  | pol2
  | pol3
  | hyp1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .safe2 => []
  | .safe3 => []
  | .reg1 => [.safe1]
  | .reg2 => [.safe2]
  | .env1 => []
  | .env2 => [.env1]
  | .pol1 => [.reg1, .env1]
  | .pol2 => [.safe3, .env2]
  | .pol3 => [.reg2]
  | .hyp1 => [.pol1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者安全に直結する絶対制約 (ord=4) -/
  | safety
  /-- 法規制・ガイドライン要件 (ord=3) -/
  | regulation
  /-- 外部環境依存（HVAC・外気等） (ord=2) -/
  | environment
  /-- 運用方針（閾値設定・アラート頻度） (ord=1) -/
  | policy
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 4
  | .regulation => 3
  | .environment => 2
  | .policy => 1
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
  nontrivial := ⟨.safety, .hypothesis, by simp [ConcreteLayer.ord]⟩
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
  | .safe1 | .safe2 | .safe3 => .safety
  -- regulation
  | .reg1 | .reg2 => .regulation
  -- environment
  | .env1 | .env2 => .environment
  -- policy
  | .pol1 | .pol2 | .pol3 => .policy
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

end OperatingRoomAirQuality

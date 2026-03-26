/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalAccuracy** (ord=5): 法的正確性。誤った法解釈は許容不可 [C1]
- **Confidentiality** (ord=4): 守秘義務。弁護士・依頼者間の秘密保持 [C2, H1]
- **JurisdictionalRule** (ord=3): 管轄固有の法的ルール。地域により異なる [C3, H2]
- **DocumentConvention** (ord=2): 文書作成の慣行・書式ルール [C4, H3]
- **StylePreference** (ord=1): 事務所・弁護士個人の文体の好み [C5, H4]
-/

namespace TestCoverage.S8

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s8_p01
  | s8_p02
  | s8_p03
  | s8_p04
  | s8_p05
  | s8_p06
  | s8_p07
  | s8_p08
  | s8_p09
  | s8_p10
  | s8_p11
  | s8_p12
  | s8_p13
  | s8_p14
  | s8_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s8_p01 => []
  | .s8_p02 => []
  | .s8_p03 => [.s8_p01]
  | .s8_p04 => [.s8_p02]
  | .s8_p05 => [.s8_p01, .s8_p02]
  | .s8_p06 => [.s8_p03]
  | .s8_p07 => [.s8_p04]
  | .s8_p08 => [.s8_p03, .s8_p05]
  | .s8_p09 => [.s8_p06]
  | .s8_p10 => [.s8_p07]
  | .s8_p11 => [.s8_p06, .s8_p08]
  | .s8_p12 => [.s8_p09]
  | .s8_p13 => [.s8_p10]
  | .s8_p14 => [.s8_p11]
  | .s8_p15 => [.s8_p12, .s8_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法的正確性。誤った法解釈は許容不可 (ord=5) -/
  | LegalAccuracy
  /-- 守秘義務。弁護士・依頼者間の秘密保持 (ord=4) -/
  | Confidentiality
  /-- 管轄固有の法的ルール。地域により異なる (ord=3) -/
  | JurisdictionalRule
  /-- 文書作成の慣行・書式ルール (ord=2) -/
  | DocumentConvention
  /-- 事務所・弁護士個人の文体の好み (ord=1) -/
  | StylePreference
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalAccuracy => 5
  | .Confidentiality => 4
  | .JurisdictionalRule => 3
  | .DocumentConvention => 2
  | .StylePreference => 1

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
  bottom := .StylePreference
  nontrivial := ⟨.LegalAccuracy, .StylePreference, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalAccuracy
  | .s8_p01 | .s8_p02 => .LegalAccuracy
  -- Confidentiality
  | .s8_p03 | .s8_p04 | .s8_p05 => .Confidentiality
  -- JurisdictionalRule
  | .s8_p06 | .s8_p07 | .s8_p08 => .JurisdictionalRule
  -- DocumentConvention
  | .s8_p09 | .s8_p10 | .s8_p11 => .DocumentConvention
  -- StylePreference
  | .s8_p12 | .s8_p13 | .s8_p14 | .s8_p15 => .StylePreference

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

end TestCoverage.S8

/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **GeneticDataSovereignty** (ord=5): 遺伝情報の本人主権・同意原則・目的外利用禁止の絶対制約 [C1, C2]
- **LegalEthicalCompliance** (ord=4): 遺伝子検査ビジネス規制法・個人情報保護法・ユネスコ宣言への適合 [C3, C4]
- **DataQualityStandard** (ord=3): シーケンシング精度・品質スコア・変異アノテーション信頼性に関する基準 [C5, C6, H1]
- **AccessControlProtocol** (ord=2): 研究者認証・データ利用申請・匿名化処理・監査ログの管理手順 [C7, H2, H3, H4]
- **ResearchEnablement** (ord=1): ゲノムワイド関連解析・希少疾患研究・創薬データ活用促進の最適化仮説 [H5, H6]
-/

namespace TestCoverage.S420

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s420_p01
  | s420_p02
  | s420_p03
  | s420_p04
  | s420_p05
  | s420_p06
  | s420_p07
  | s420_p08
  | s420_p09
  | s420_p10
  | s420_p11
  | s420_p12
  | s420_p13
  | s420_p14
  | s420_p15
  | s420_p16
  | s420_p17
  | s420_p18
  | s420_p19
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s420_p01 => []
  | .s420_p02 => []
  | .s420_p03 => [.s420_p01, .s420_p02]
  | .s420_p04 => [.s420_p01]
  | .s420_p05 => [.s420_p02]
  | .s420_p06 => [.s420_p03, .s420_p04, .s420_p05]
  | .s420_p07 => [.s420_p04]
  | .s420_p08 => [.s420_p05]
  | .s420_p09 => [.s420_p06, .s420_p07, .s420_p08]
  | .s420_p10 => [.s420_p07]
  | .s420_p11 => [.s420_p08]
  | .s420_p12 => [.s420_p09, .s420_p10, .s420_p11]
  | .s420_p13 => [.s420_p10]
  | .s420_p14 => [.s420_p11]
  | .s420_p15 => [.s420_p12, .s420_p13, .s420_p14]
  | .s420_p16 => []
  | .s420_p17 => [.s420_p06]
  | .s420_p18 => [.s420_p12]
  | .s420_p19 => [.s420_p15, .s420_p17, .s420_p18]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 遺伝情報の本人主権・同意原則・目的外利用禁止の絶対制約 (ord=5) -/
  | GeneticDataSovereignty
  /-- 遺伝子検査ビジネス規制法・個人情報保護法・ユネスコ宣言への適合 (ord=4) -/
  | LegalEthicalCompliance
  /-- シーケンシング精度・品質スコア・変異アノテーション信頼性に関する基準 (ord=3) -/
  | DataQualityStandard
  /-- 研究者認証・データ利用申請・匿名化処理・監査ログの管理手順 (ord=2) -/
  | AccessControlProtocol
  /-- ゲノムワイド関連解析・希少疾患研究・創薬データ活用促進の最適化仮説 (ord=1) -/
  | ResearchEnablement
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .GeneticDataSovereignty => 5
  | .LegalEthicalCompliance => 4
  | .DataQualityStandard => 3
  | .AccessControlProtocol => 2
  | .ResearchEnablement => 1

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
  bottom := .ResearchEnablement
  nontrivial := ⟨.GeneticDataSovereignty, .ResearchEnablement, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- GeneticDataSovereignty
  | .s420_p01 | .s420_p02 | .s420_p03 | .s420_p16 => .GeneticDataSovereignty
  -- LegalEthicalCompliance
  | .s420_p04 | .s420_p05 | .s420_p06 => .LegalEthicalCompliance
  -- DataQualityStandard
  | .s420_p07 | .s420_p08 | .s420_p09 => .DataQualityStandard
  -- AccessControlProtocol
  | .s420_p10 | .s420_p11 | .s420_p12 | .s420_p17 => .AccessControlProtocol
  -- ResearchEnablement
  | .s420_p13 | .s420_p14 | .s420_p15 | .s420_p18 | .s420_p19 => .ResearchEnablement

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

end TestCoverage.S420

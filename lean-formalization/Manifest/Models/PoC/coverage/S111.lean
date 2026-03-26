/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=4): 鑑定結果の法的・倫理的に不可侵な前提。誤鑑定による損害責任の根拠 [C1, C2, C5]
- **domain_knowledge** (ord=3): 美術史・材料科学・様式分析の確立された知見。反例は極めて稀 [C4, H1, H3]
- **methodology** (ord=2): 鑑定プロセスの手順・基準。人間の専門家が設定・更新する [C3, C6, H4]
- **inference** (ord=1): AI が画像・データから推論する真贋判定。確信度付き [C7, H6, H7]
- **hypothesis** (ord=0): 未検証の仮説。新発見の作家・技法に関する推定 [H8, H9]
-/

namespace ArtAuthentication

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | auth_legal1
  | auth_legal2
  | auth_provenance
  | dk_material
  | dk_style
  | dk_period
  | dk_pigment
  | meth_workflow
  | meth_xray
  | meth_multistage
  | meth_human_final
  | inf_image_cls
  | inf_age_est
  | inf_ensemble
  | inf_confidence
  | inf_report
  | hyp_new_artist
  | hyp_forgery_net
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .auth_legal1 => []
  | .auth_legal2 => []
  | .auth_provenance => []
  | .dk_material => []
  | .dk_style => []
  | .dk_period => []
  | .dk_pigment => [.dk_material]
  | .meth_workflow => [.auth_legal1]
  | .meth_xray => [.dk_material]
  | .meth_multistage => [.auth_legal2, .dk_style]
  | .meth_human_final => [.auth_legal1]
  | .inf_image_cls => [.dk_style, .meth_xray]
  | .inf_age_est => [.dk_pigment, .dk_period]
  | .inf_ensemble => [.inf_image_cls, .inf_age_est, .meth_multistage]
  | .inf_confidence => [.inf_ensemble]
  | .inf_report => [.inf_confidence, .meth_human_final, .auth_provenance]
  | .hyp_new_artist => [.inf_image_cls]
  | .hyp_forgery_net => [.inf_ensemble, .dk_period]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 鑑定結果の法的・倫理的に不可侵な前提。誤鑑定による損害責任の根拠 (ord=4) -/
  | constraint
  /-- 美術史・材料科学・様式分析の確立された知見。反例は極めて稀 (ord=3) -/
  | domain_knowledge
  /-- 鑑定プロセスの手順・基準。人間の専門家が設定・更新する (ord=2) -/
  | methodology
  /-- AI が画像・データから推論する真贋判定。確信度付き (ord=1) -/
  | inference
  /-- 未検証の仮説。新発見の作家・技法に関する推定 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 4
  | .domain_knowledge => 3
  | .methodology => 2
  | .inference => 1
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
  nontrivial := ⟨.constraint, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- constraint
  | .auth_legal1 | .auth_legal2 | .auth_provenance => .constraint
  -- domain_knowledge
  | .dk_material | .dk_style | .dk_period | .dk_pigment => .domain_knowledge
  -- methodology
  | .meth_workflow | .meth_xray | .meth_multistage | .meth_human_final => .methodology
  -- inference
  | .inf_image_cls | .inf_age_est | .inf_ensemble | .inf_confidence | .inf_report => .inference
  -- hypothesis
  | .hyp_new_artist | .hyp_forgery_net => .hypothesis

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

end ArtAuthentication

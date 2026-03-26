/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **DeviceSecurityInvariant** (ord=4): デバイス偽装・不正アクセスの絶対防止制約。クリティカルインフラ保護の最上位要件 [C1, C2]
- **SecurityStandardCompliance** (ord=3): FIDO2・X.509・ISO/IEC 27001 などセキュリティ標準への準拠要件 [C3, C4]
- **AuthenticationPolicy** (ord=2): 多要素認証・証明書ライフサイクル管理・失効チェック頻度の方針 [C5, H1, H2]
- **TrustScoreHypothesis** (ord=1): デバイス行動履歴・ファームウェア整合性・ネットワーク文脈から信頼スコアを推定する仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S470

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s470_p01
  | s470_p02
  | s470_p03
  | s470_p04
  | s470_p05
  | s470_p06
  | s470_p07
  | s470_p08
  | s470_p09
  | s470_p10
  | s470_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s470_p01 => []
  | .s470_p02 => [.s470_p01]
  | .s470_p03 => [.s470_p01]
  | .s470_p04 => [.s470_p02]
  | .s470_p05 => [.s470_p03]
  | .s470_p06 => [.s470_p04]
  | .s470_p07 => [.s470_p05]
  | .s470_p08 => [.s470_p06]
  | .s470_p09 => [.s470_p07]
  | .s470_p10 => [.s470_p08, .s470_p09]
  | .s470_p11 => [.s470_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- デバイス偽装・不正アクセスの絶対防止制約。クリティカルインフラ保護の最上位要件 (ord=4) -/
  | DeviceSecurityInvariant
  /-- FIDO2・X.509・ISO/IEC 27001 などセキュリティ標準への準拠要件 (ord=3) -/
  | SecurityStandardCompliance
  /-- 多要素認証・証明書ライフサイクル管理・失効チェック頻度の方針 (ord=2) -/
  | AuthenticationPolicy
  /-- デバイス行動履歴・ファームウェア整合性・ネットワーク文脈から信頼スコアを推定する仮説 (ord=1) -/
  | TrustScoreHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .DeviceSecurityInvariant => 4
  | .SecurityStandardCompliance => 3
  | .AuthenticationPolicy => 2
  | .TrustScoreHypothesis => 1

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
  bottom := .TrustScoreHypothesis
  nontrivial := ⟨.DeviceSecurityInvariant, .TrustScoreHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- DeviceSecurityInvariant
  | .s470_p01 | .s470_p02 => .DeviceSecurityInvariant
  -- SecurityStandardCompliance
  | .s470_p03 | .s470_p04 => .SecurityStandardCompliance
  -- AuthenticationPolicy
  | .s470_p05 | .s470_p06 => .AuthenticationPolicy
  -- TrustScoreHypothesis
  | .s470_p07 | .s470_p08 | .s470_p09 | .s470_p10 | .s470_p11 => .TrustScoreHypothesis

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

end TestCoverage.S470

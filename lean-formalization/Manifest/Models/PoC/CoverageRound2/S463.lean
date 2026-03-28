/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ServiceReliabilityInvariant** (ord=4): 配信断絶ゼロ・視聴者体験の最低品質保証。SLA 違反の絶対禁止 [C1, C2]
- **NetworkProtocolCompliance** (ord=3): RTMP/HLS/WebRTC プロトコル規格・帯域割当規制への準拠 [C3, C4]
- **AdaptiveBitratePolicy** (ord=2): ネットワーク状態に応じたビットレート自動調整方針。遅延 vs 品質トレードオフ基準 [H1, H2]
- **ViewerExperienceHypothesis** (ord=1): 視聴者の接続環境・デバイス特性から体感品質を推定する仮説層 [H3, H4, H5]
-/

namespace TestCoverage.S463

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s463_p01
  | s463_p02
  | s463_p03
  | s463_p04
  | s463_p05
  | s463_p06
  | s463_p07
  | s463_p08
  | s463_p09
  | s463_p10
  | s463_p11
  | s463_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s463_p01 => []
  | .s463_p02 => [.s463_p01]
  | .s463_p03 => [.s463_p01]
  | .s463_p04 => [.s463_p02]
  | .s463_p05 => [.s463_p03]
  | .s463_p06 => [.s463_p04]
  | .s463_p07 => [.s463_p05, .s463_p06]
  | .s463_p08 => [.s463_p05]
  | .s463_p09 => [.s463_p06]
  | .s463_p10 => [.s463_p07]
  | .s463_p11 => [.s463_p08, .s463_p09]
  | .s463_p12 => [.s463_p10, .s463_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 配信断絶ゼロ・視聴者体験の最低品質保証。SLA 違反の絶対禁止 (ord=4) -/
  | ServiceReliabilityInvariant
  /-- RTMP/HLS/WebRTC プロトコル規格・帯域割当規制への準拠 (ord=3) -/
  | NetworkProtocolCompliance
  /-- ネットワーク状態に応じたビットレート自動調整方針。遅延 vs 品質トレードオフ基準 (ord=2) -/
  | AdaptiveBitratePolicy
  /-- 視聴者の接続環境・デバイス特性から体感品質を推定する仮説層 (ord=1) -/
  | ViewerExperienceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ServiceReliabilityInvariant => 4
  | .NetworkProtocolCompliance => 3
  | .AdaptiveBitratePolicy => 2
  | .ViewerExperienceHypothesis => 1

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
  bottom := .ViewerExperienceHypothesis
  nontrivial := ⟨.ServiceReliabilityInvariant, .ViewerExperienceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ServiceReliabilityInvariant
  | .s463_p01 | .s463_p02 => .ServiceReliabilityInvariant
  -- NetworkProtocolCompliance
  | .s463_p03 | .s463_p04 => .NetworkProtocolCompliance
  -- AdaptiveBitratePolicy
  | .s463_p05 | .s463_p06 | .s463_p07 => .AdaptiveBitratePolicy
  -- ViewerExperienceHypothesis
  | .s463_p08 | .s463_p09 | .s463_p10 | .s463_p11 | .s463_p12 => .ViewerExperienceHypothesis

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

end TestCoverage.S463

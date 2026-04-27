import AgentSpec.Manifest.Observable

/-!
# Promotion Protocol

## 目的

ProxyMaturityLevel の昇格に型制約を導入し、前提なしの昇格を構造的に防ぐ。

## Research Issue

#528 (Parent: #526)
-/

namespace AgentSpec.Manifest.Framework.PromotionProtocol

open Manifest

-- ============================================================
-- Gap 2: 昇格プロトコルの型制約
-- ============================================================

/-- 昇格の方向。ProxyMaturityLevel の有効な昇格パスを列挙する。 -/
inductive PromotionPath where
  /-- provisional → established -/
  | toEstablished
  /-- established → formal -/
  | toFormal
  /-- provisional → formal（established をスキップ） -/
  | directToFormal
  deriving BEq, Repr, DecidableEq

/-- 昇格根拠の種別。 -/
inductive EvidenceKind where
  /-- T6 権威に基づく人間の判断。 -/
  | humanJudgment (date : String) (justification : String)
  /-- 定量的基準の達成。 -/
  | quantitativeCriteria (metric : String) (threshold : Float) (actual : Float)
  /-- P2 独立検証の完了。 -/
  | independentVerification (verifierId : String) (date : String)
  deriving Repr

/-- 昇格根拠。どの経路で、どのような根拠で昇格するかを記録する。 -/
structure PromotionEvidence where
  /-- 昇格経路。 -/
  path : PromotionPath
  /-- 根拠のリスト（複数根拠の組み合わせ可能）。 -/
  evidence : List EvidenceKind
  /-- 根拠が空でないことの保証。 -/
  nonempty : evidence.length > 0
  deriving Repr

/-- 昇格元の ProxyMaturityLevel が経路と整合しているかを判定する。 -/
def PromotionPath.isValidFrom (path : PromotionPath) (from_ : ProxyMaturityLevel) : Prop :=
  match path, from_ with
  | .toEstablished, .provisional => True
  | .toFormal, .established => True
  | .directToFormal, .provisional => True
  | _, _ => False

/-- 昇格先の ProxyMaturityLevel を返す。 -/
def PromotionPath.target : PromotionPath → ProxyMaturityLevel
  | .toEstablished => .established
  | .toFormal => .formal
  | .directToFormal => .formal

/-- 型制約付き昇格関数。
    昇格元と経路の整合性を Prop として要求する。
    不正な昇格（例: formal → established への降格）は型レベルで構成不可能。 -/
def promoteProxy
    (current : ProxyMaturityLevel)
    {path : PromotionPath}
    (_evidence : PromotionEvidence)
    (_valid : path.isValidFrom current)
    (_pathMatch : _evidence.path = path) :
    ProxyMaturityLevel :=
  path.target

-- ============================================================
-- 昇格プロトコルの定理
-- ============================================================

/-- provisional から established への昇格は有効。 -/
theorem provisional_to_established_valid :
    PromotionPath.isValidFrom .toEstablished .provisional = True := by
  simp [PromotionPath.isValidFrom]

/-- established から formal への昇格は有効。 -/
theorem established_to_formal_valid :
    PromotionPath.isValidFrom .toFormal .established = True := by
  simp [PromotionPath.isValidFrom]

/-- provisional から formal への直接昇格は有効。 -/
theorem provisional_to_formal_valid :
    PromotionPath.isValidFrom .directToFormal .provisional = True := by
  simp [PromotionPath.isValidFrom]

/-- formal からの昇格は不可能（toEstablished 経路）。 -/
theorem formal_cannot_promote_to_established :
    PromotionPath.isValidFrom .toEstablished .formal = False := by
  simp [PromotionPath.isValidFrom]

/-- formal からの昇格は不可能（toFormal 経路）。 -/
theorem formal_cannot_promote_to_formal :
    PromotionPath.isValidFrom .toFormal .formal = False := by
  simp [PromotionPath.isValidFrom]

/-- established からの toEstablished 昇格は不可能（すでに established）。 -/
theorem established_cannot_promote_to_established :
    PromotionPath.isValidFrom .toEstablished .established = False := by
  simp [PromotionPath.isValidFrom]

/-- 昇格先は常に昇格元以上の成熟度を持つ（数値化して比較）。 -/
private def maturityOrd : ProxyMaturityLevel → Nat
  | .provisional => 0
  | .established => 1
  | .formal => 2

/-- 各有効経路で、昇格先の ord は昇格元以上。 -/
theorem promotion_monotone (current : ProxyMaturityLevel) (path : PromotionPath)
    (h : path.isValidFrom current) :
    maturityOrd current ≤ maturityOrd path.target := by
  cases path <;> cases current <;> simp [PromotionPath.isValidFrom] at h <;>
    simp [maturityOrd, PromotionPath.target]

-- E3a (confidence_is_self_description) is now in EmpiricalPostulates.lean.
-- E3b (cot_not_always_faithful) is in Framework/CoTFaithfulness.lean.

end AgentSpec.Manifest.Framework.PromotionProtocol

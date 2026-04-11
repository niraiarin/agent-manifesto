/-
  DomainClassification.lean — ドメイン非依存性の運用分類基準

  #429 (R4): 子公理系の命題をドメイン依存/非依存に分類する運用基準を定義する。

  DeviationPolicy.lean の DomainSpecificity 型に対して、
  分類を行うための観測可能なシグナル（ヒューリスティクス）を形式化する。

  @traces P3, D3
-/
import Manifest.Models.DeviationPolicy
import Manifest.TaskClassification

namespace Manifest.Models.DomainClassification

open Manifest.Models (DomainSpecificity questionAutomationClass)

-- ============================================================
-- 1. 分類シグナル（観測可能な指標）
-- ============================================================

/-- 命題がドメイン固有かどうかを示唆する観測可能なシグナル。 -/
inductive DomainSignal where
  | referencesPlatformPrimitive
  | hardcodesConfigValue
  | isPlatformMapping
  | comparesPlatforms
  | dependsOnHumanDecision
  deriving BEq, Repr, DecidableEq

/-- 命題がドメイン非依存であることを示唆する観測可能なシグナル。 -/
inductive IndependenceSignal where
  | referencesManifestoProposition
  | provesGenericTypeProperty
  | universallyQuantified
  | dependsOnlyOnInference
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. 分類判定ルール
-- ============================================================

/-- 分類の確信度。 -/
inductive Certainty where
  | high
  | moderate
  | ambiguous
  deriving BEq, Repr, DecidableEq

/-- 分類結果。 -/
structure Result where
  domainClass : DomainSpecificity
  cert : Certainty
  domainSignals : List DomainSignal
  independenceSignals : List IndependenceSignal
  deriving Repr

/-- シグナルに基づく分類。 -/
def classify (ds : List DomainSignal) (is_ : List IndependenceSignal) : Result :=
  if ds.length ≥ 2 && is_.length == 0 then
    ⟨.domainSpecific, .high, ds, is_⟩
  else if ds.length == 0 && is_.length ≥ 2 then
    ⟨.notDomainSpecific, .high, ds, is_⟩
  else if ds.length > is_.length then
    ⟨.domainSpecific, if ds.length ≥ 2 then .moderate else .ambiguous, ds, is_⟩
  else if is_.length > ds.length then
    ⟨.notDomainSpecific, if is_.length ≥ 2 then .moderate else .ambiguous, ds, is_⟩
  else
    ⟨.domainSpecific, .ambiguous, ds, is_⟩

-- ============================================================
-- 3. 分類の性質
-- ============================================================

/-- ambiguous な分類は high にも moderate にもならない。
    classify がシグナル均衡で ambiguous を返す場合、人間判断が必要。 -/
theorem ambiguous_is_exclusive :
    ∀ (ds : List DomainSignal) (is_ : List IndependenceSignal),
      (classify ds is_).cert = Certainty.ambiguous →
      (classify ds is_).cert ≠ Certainty.high ∧
      (classify ds is_).cert ≠ Certainty.moderate := by
  intro ds is_ h
  constructor <;> (rw [h]; decide)

/-- シグナルが空の場合は ambiguous。 -/
theorem no_signals_ambiguous :
    (classify [] []).cert = Certainty.ambiguous := by
  simp [classify]

/-- ドメインシグナル 2+ かつ独立シグナル 0 → high certainty。 -/
theorem strong_domain (d1 d2 : DomainSignal) (ds : List DomainSignal) :
    (classify (d1 :: d2 :: ds) []).cert = Certainty.high := by
  simp [classify]

/-- 独立シグナル 2+ かつドメインシグナル 0 → high certainty。 -/
theorem strong_independence (i1 i2 : IndependenceSignal) (is_ : List IndependenceSignal) :
    (classify [] (i1 :: i2 :: is_)).cert = Certainty.high := by
  simp [classify]

-- ============================================================
-- 4. 検証データ
-- ============================================================

/-- ccEnforcementLayer: domain-specific (2 signals) -/
example : (classify [.isPlatformMapping, .referencesPlatformPrimitive] []).domainClass
    = .domainSpecific := rfl

/-- cc5_subagent_hook_satisfies_high: domain-independent (2 signals) -/
example : (classify [] [.referencesManifestoProposition, .provesGenericTypeProperty]).domainClass
    = .notDomainSpecific := rfl

/-- pluginShellRequirement: domain-independent (1 signal → ambiguous) -/
example : (classify [] [.universallyQuantified]).cert
    = Certainty.ambiguous := by simp [classify]

/-- 混合: 1 domain + 1 independent → ambiguous -/
example : (classify [.referencesPlatformPrimitive] [.referencesManifestoProposition]).cert
    = Certainty.ambiguous := by simp [classify]

end Manifest.Models.DomainClassification

import AgentSpec.Manifest.FormalDerivationSkill
import AgentSpec.Manifest.Terminology

/-!
# 形式的導出手順書の形式化

`docs/formal-derivation-procedure.md` の規則と関係を Lean の型と定理として書き下す。

## FormalDerivationSkill.lean との関係

FormalDerivationSkill.lean は手順書の構成要素を**列挙型**として定義済み。
本ファイルはこれらの型の上に手順書の**規則**を定式化する。

## Terminology.lean との接続

手順書の概念を用語リファレンスの形式的定義に接続する:
- T₀ / Γ \ T₀ → ExtensionKind (§5.5), BeliefRevisionOp (§9.2)
- 公理衛生 → AxiomKind, IndependenceStatus (§4)

## 形式化の構造

- **T₀**: 手順書の規則自体。型定義と定理で表現（axiom 0 個）
- **φ**: procedure_rules_consistent — 手順書の規則体系の内部整合性
-/

namespace AgentSpec.Manifest.Procedure

open AgentSpec.Manifest.FormalDerivationSkill
open AgentSpec.Manifest.Terminology

-- ============================================================
-- §2.4: T₀ / Γ \ T₀ の分類規則
-- ============================================================

/-- 前提集合の区分と許容される AGM 操作の対応。 -/
def permittedOp : PremisePartition → BeliefRevisionOp → Bool
  | .baseTheory, .expansion   => true
  | .baseTheory, .contraction => false
  | .baseTheory, .revision    => false
  | .extension,  .expansion   => true
  | .extension,  .contraction => true
  | .extension,  .revision    => true

/-- [Derivation Card]
    Derives from: (none — derived from definition permittedOp)
    Proposition: P3
    Content: Base theory (T₀) contraction is forbidden. permittedOp classifies contraction on baseTheory as false.
    Proof strategy: rfl (definitional equality) -/
theorem t0_contraction_forbidden :
  permittedOp .baseTheory .contraction = false := by rfl

/-- §2.4: Γ \ T₀ にはすべての AGM 操作が許容される。 -/
theorem extension_all_ops_permitted :
  permittedOp .extension .expansion = true ∧
  permittedOp .extension .contraction = true ∧
  permittedOp .extension .revision = true := by
  refine ⟨?_, ?_, ?_⟩ <;> rfl

-- ============================================================
-- §2.4: T₀ エンコード方法の規則
-- ============================================================

/-- T₀ エンコード方法と拡大の種類の対応。 -/
def encodingToExtension : T0EncodingMethod → ExtensionKind
  | .definitionalTheorem => .definitional
  | .axiomWithCard       => .consistent

/-- §2.4: 型定義によるエンコードは axiom より厳密に安全。 -/
theorem definitional_encoding_safer :
  (encodingToExtension .definitionalTheorem).strength >
  (encodingToExtension .axiomWithCard).strength := by
  simp [encodingToExtension, ExtensionKind.strength]

-- ============================================================
-- §2.5: 公理カードの必須フィールド規則
-- ============================================================

/-- 公理カードのフィールドが必須かどうか。 -/
def fieldRequired : PremisePartition → AxiomCardField → Bool
  | _,           .membership     => true
  | _,           .content        => true
  | _,           .rationale      => true
  | _,           .source         => true
  | .baseTheory, .refutationCond => false
  | .extension,  .refutationCond => true

/-- §2.5: T₀ には反証条件不要、Γ \ T₀ には必須。 -/
theorem refutation_cond_rule :
  fieldRequired .baseTheory .refutationCond = false ∧
  fieldRequired .extension .refutationCond = true := by
  constructor <;> rfl

/-- §2.5: 所属・内容・根拠・ソースは両区分で必須。 -/
theorem common_fields_always_required :
  ∀ (p : PremisePartition),
    fieldRequired p .membership = true ∧
    fieldRequired p .content = true ∧
    fieldRequired p .rationale = true ∧
    fieldRequired p .source = true := by
  intro p; cases p <;> refine ⟨?_, ?_, ?_, ?_⟩ <;> rfl

-- ============================================================
-- §2.6: 公理衛生の独立性
-- ============================================================

/-- 各検査が検出する問題の種類。 -/
def hygieneDetects : HygieneCheck → String
  | .nonVacuity            => "vacuously true axiom"
  | .nonLogicalValidity    => "logically valid axiom"
  | .independence          => "redundant axiom"
  | .minimality            => "unused axiom"
  | .baseTheoryPreservation => "inconsistent extension"

/-- §2.6: 5 検査はすべて異なる問題を検出する。 -/
theorem hygiene_checks_independent :
  hygieneDetects .nonVacuity ≠ hygieneDetects .nonLogicalValidity ∧
  hygieneDetects .nonLogicalValidity ≠ hygieneDetects .independence ∧
  hygieneDetects .independence ≠ hygieneDetects .minimality ∧
  hygieneDetects .minimality ≠ hygieneDetects .baseTheoryPreservation := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> simp [hygieneDetects]

-- ============================================================
-- §3: Phase 順序
-- ============================================================

/-- Phase の実行順序。 -/
def phaseOrder : Phase → Nat
  | .leanConstruction => 0
  | .derivation       => 1
  | .correctionLoop   => 2
  | .audit            => 3

/-- §3: Phase 1 は最初。 -/
theorem phase1_is_first :
  ∀ (p : Phase), phaseOrder .leanConstruction ≤ phaseOrder p := by
  intro p; cases p <;> simp [phaseOrder]

/-- §3: Phase 4 は最後。 -/
theorem phase4_is_last :
  ∀ (p : Phase), phaseOrder p ≤ phaseOrder .audit := by
  intro p; cases p <;> simp [phaseOrder]

/-- §3: Phase は厳密に順序づけられている。 -/
theorem phase_sequential :
  phaseOrder .leanConstruction < phaseOrder .derivation ∧
  phaseOrder .derivation < phaseOrder .correctionLoop ∧
  phaseOrder .correctionLoop < phaseOrder .audit := by
  simp [phaseOrder]

-- ============================================================
-- §3 Phase 3b: 修正の安全性
-- ============================================================

/-- 修正の安全性レベル。値が大きいほど安全。 -/
def modSafetyLevel : ModificationKind → Nat
  | .definitionalExtension => 3
  | .extensionChange       => 2
  | .goalWeakening         => 1
  | .baseTheoryContraction => 0

/-- §3 Phase 3b: 定義的拡大は最も安全。 -/
theorem definitional_extension_safest :
  ∀ (m : ModificationKind),
    modSafetyLevel m ≤ modSafetyLevel .definitionalExtension := by
  intro m; cases m <;> simp [modSafetyLevel]

/-- §3 Phase 3b: T₀ の縮小は最も危険。 -/
theorem t0_contraction_least_safe :
  ∀ (m : ModificationKind),
    modSafetyLevel .baseTheoryContraction ≤ modSafetyLevel m := by
  intro m; cases m <;> simp [modSafetyLevel]

/-- §3 Phase 3b: 安全性の厳密な全順序。 -/
theorem modification_safety_chain :
  modSafetyLevel .definitionalExtension > modSafetyLevel .extensionChange ∧
  modSafetyLevel .extensionChange > modSafetyLevel .goalWeakening ∧
  modSafetyLevel .goalWeakening > modSafetyLevel .baseTheoryContraction := by
  simp [modSafetyLevel]

-- ============================================================
-- §3 Phase 3c: 戦略変更の優先順位
-- ============================================================

/-- 戦略変更の優先順位。値が小さいほど優先。 -/
def strategyPriority : StrategyChangeOption → Nat
  | .reviseExtension     => 0
  | .redefDomain         => 1
  | .changeDecomposition => 2
  | .weakenGoal          => 3

/-- §3 Phase 3c: Γ \ T₀ の見直しが最優先。 -/
theorem revise_extension_first :
  ∀ (o : StrategyChangeOption),
    strategyPriority .reviseExtension ≤ strategyPriority o := by
  intro o; cases o <;> simp [strategyPriority]

/-- §3 Phase 3c: φ の弱化は最終手段。 -/
theorem weaken_goal_last :
  ∀ (o : StrategyChangeOption),
    strategyPriority o ≤ strategyPriority .weakenGoal := by
  intro o; cases o <;> simp [strategyPriority]

-- ============================================================
-- §3 Phase 3c: バックトラック保持規則
-- ============================================================

/-- バックトラック時の保持強度。値が大きいほど保持される。 -/
def retentionStrength : BacktrackComponent → Nat
  | .baseTheory      => 3
  | .derivedLemmas   => 2
  | .domainTypes     => 1
  | .extensionAxioms => 0

/-- §3 Phase 3c: T₀ は常に保持される。 -/
theorem t0_always_retained :
  ∀ (b : BacktrackComponent),
    retentionStrength b ≤ retentionStrength .baseTheory := by
  intro b; cases b <;> simp [retentionStrength]

/-- §3 Phase 3c: Γ \ T₀ は最も破棄されやすい。 -/
theorem extension_most_disposable :
  ∀ (b : BacktrackComponent),
    retentionStrength .extensionAxioms ≤ retentionStrength b := by
  intro b; cases b <;> simp [retentionStrength]

-- ============================================================
-- §4: 終了条件
-- ============================================================

/-- 終了条件の決定性。 -/
def isDecisive : TerminationKind → Bool
  | .success   => true
  | .failure   => true
  | .undecided => false

/-- §4: 成功と失敗は決定的、未決は非決定的。 -/
theorem termination_decisiveness :
  isDecisive .success = true ∧
  isDecisive .failure = true ∧
  isDecisive .undecided = false := by
  refine ⟨?_, ?_, ?_⟩ <;> rfl

-- ============================================================
-- 目標命題 φ
-- ============================================================

/-- [目標命題]
    タスク: 「形式的導出手順書の規則体系は内部的に整合している」

    形式化の意図:
    手順書が定義する規則（T₀ 縮小禁止、修正の安全性順序、
    Phase 順序、戦略優先順位、バックトラック保持規則、
    公理衛生の独立性）が正しく成立することを導出する。 -/
theorem procedure_rules_consistent :
  -- §2.4: T₀ 縮小禁止
  (permittedOp .baseTheory .contraction = false) ∧
  -- §2.4: Γ \ T₀ は全操作許容
  (permittedOp .extension .expansion = true ∧
   permittedOp .extension .contraction = true ∧
   permittedOp .extension .revision = true) ∧
  -- §2.4: 型定義エンコードは axiom より安全
  ((encodingToExtension .definitionalTheorem).strength >
   (encodingToExtension .axiomWithCard).strength) ∧
  -- §2.5: 反証条件は Γ \ T₀ のみ必須
  (fieldRequired .baseTheory .refutationCond = false ∧
   fieldRequired .extension .refutationCond = true) ∧
  -- §3: Phase 順序
  (phaseOrder .leanConstruction < phaseOrder .derivation ∧
   phaseOrder .derivation < phaseOrder .correctionLoop ∧
   phaseOrder .correctionLoop < phaseOrder .audit) ∧
  -- §3 Phase 3b: 修正の安全性順序
  (modSafetyLevel .definitionalExtension > modSafetyLevel .extensionChange ∧
   modSafetyLevel .extensionChange > modSafetyLevel .goalWeakening ∧
   modSafetyLevel .goalWeakening > modSafetyLevel .baseTheoryContraction) ∧
  -- §3 Phase 3c: T₀ は常に保持
  (∀ (b : BacktrackComponent),
    retentionStrength b ≤ retentionStrength .baseTheory) ∧
  -- §4: 終了条件の決定性
  (isDecisive .success = true ∧
   isDecisive .failure = true ∧
   isDecisive .undecided = false) :=
  ⟨t0_contraction_forbidden,
   extension_all_ops_permitted,
   definitional_encoding_safer,
   refutation_cond_rule,
   phase_sequential,
   modification_safety_chain,
   t0_always_retained,
   termination_decisiveness⟩

-- ============================================================
-- SelfGoverning 自己適用
-- ============================================================

/-- 手順書の規則カテゴリ。 -/
inductive ProcedureRuleCategory where
  | premiseClassification
  | encodingRule
  | axiomCardRule
  | hygieneRule
  | phaseOrdering
  | modificationSafety
  | strategyPriority
  | backtrackRetention
  | terminationSemantics
  deriving BEq, Repr, DecidableEq

instance : SelfGoverning ProcedureRuleCategory where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

theorem all_rule_categories_enumerated :
  ∀ (r : ProcedureRuleCategory),
    r = .premiseClassification ∨ r = .encodingRule ∨
    r = .axiomCardRule ∨ r = .hygieneRule ∨
    r = .phaseOrdering ∨ r = .modificationSafety ∨
    r = .strategyPriority ∨ r = .backtrackRetention ∨
    r = .terminationSemantics := by
  intro r; cases r <;> simp

-- ============================================================
-- Structure-AGM Bridge — 依存追跡と AGM 操作の接続
-- ============================================================

/-!
## Structure レベルの AGM 安全条件

Ontology.lean の reachableVia（Structure レベル影響波及）と
本ファイルの permittedOp（AGM 操作許可）を接続する。
-/

/-- StructureKind から PremisePartition へのマッピング。
    manifest（T1-T8, E1-E2, P1-P6 を包含）は baseTheory（T₀）。
    他は extension（Γ \ T₀）。 -/
def structurePartition : StructureKind → PremisePartition
  | .manifest         => .baseTheory
  | .designConvention => .extension
  | .skill            => .extension
  | .test             => .extension
  | .document         => .extension

/-- manifest への contraction は許可されない（T₀ 縮小禁止の Structure 版）。 -/
theorem manifest_contraction_forbidden' :
  permittedOp (structurePartition .manifest) .contraction = false := by rfl

/-- manifest への revision も許可されない。 -/
theorem manifest_revision_forbidden :
  permittedOp (structurePartition .manifest) .revision = false := by rfl

/-- 非 manifest 構造は全 AGM 操作が許可される。 -/
theorem non_manifest_all_ops_permitted (k : StructureKind) (hk : k ≠ .manifest) :
  ∀ (op : BeliefRevisionOp), permittedOp (structurePartition k) op = true := by
  intro op
  cases k with
  | manifest => exact absurd rfl hk
  | designConvention => cases op <;> rfl
  | skill => cases op <;> rfl
  | test => cases op <;> rfl
  | document => cases op <;> rfl

/-- AGM contraction の影響集合: Structure s の contraction が許可される場合、
    reachableVia で到達可能な全 Structure が見直し対象。 -/
def contractionAffected (w : World) (s : Structure) (t : Structure) : Prop :=
  permittedOp (structurePartition s.kind) .contraction = true ∧
  reachableVia w s t

/-- 空の World では contraction の影響集合は空。 -/
theorem empty_world_no_contraction_affected :
  ∀ (s t : Structure),
    ¬contractionAffected
      { sessions := [], time := 0, auditLog := [], structures := [],
        epoch := 0, feedbacks := [], allocations := [] } s t := by
  intro s t ⟨_, hreach⟩
  exact empty_world_no_reach s t hreach

/-- manifest の contraction は許可されないため影響集合は発生しない。 -/
theorem manifest_no_contraction_affected (w : World) (s : Structure)
    (hk : s.kind = .manifest) :
    ∀ t, ¬contractionAffected w s t := by
  intro t ⟨hperm, _⟩
  simp [structurePartition, hk, permittedOp] at hperm

/-- contraction 影響は推移的。 -/
theorem contraction_affected_trans (w : World) (s mid t : Structure)
    (hsm : contractionAffected w s mid)
    (hmt : reachableVia w mid t) :
    contractionAffected w s t :=
  ⟨hsm.1, reachableVia_trans w s mid t hsm.2 hmt⟩

end AgentSpec.Manifest.Procedure

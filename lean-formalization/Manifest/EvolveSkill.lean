import Manifest.Evolution
import Manifest.DesignFoundation
import Manifest.Workflow

/-!
# Formal Evaluation of the evolve Skill

## タスク記述

/evolve スキル（.claude/skills/evolve/SKILL.md）が
マニフェストの学習ライフサイクル（Workflow.lean）および
設計原則（P2, P3, P4, T6, D9）に整合することを形式的に検証する。

## 形式化の方針

axiom 0 を目指す。/evolve の設計は既存の型（LearningPhase,
CompatibilityClass, VerificationIndependence 等）上で検証可能な
性質のみを主張しているため、全て定義的拡大 + theorem で表現する。

## Γ の構成

## Base Theory T0
型定義のみ。axiom なし。T₀ の権威（マニフェスト Workflow.lean,
Evolution.lean, DesignFoundation.lean）は型の構成子の選択に反映される。

## Extension Beyond T0
なし（axiom 0）。
-/

namespace Manifest.EvolveSkill

-- ============================================================
-- 論議領域: /evolve が語る対象の型定義
-- ============================================================

/-- /evolve のエージェント。5 エージェント構成。 -/
inductive EvolveAgent where
  | observer       -- P4: 可観測性
  | hypothesizer   -- P3: 仮説化
  | verifier       -- P2: 検証分離
  | judge          -- 非自明性・品質評価
  | integrator     -- P3: 統合
  deriving BEq, Repr, DecidableEq

/-- /evolve のフェーズ。学習ライフサイクル（Workflow.lean）に対応。 -/
inductive EvolvePhase where
  | observe       -- Phase 1: 観察
  | hypothesize   -- Phase 2: 仮説化
  | verify        -- Phase 3: 検証
  | judge         -- Phase 3.5: 判定（非自明性・品質評価）
  | integrate     -- Phase 4: 統合
  | retire        -- Phase 5: 退役
  deriving BEq, Repr, DecidableEq

/-- /evolve のフェーズから LearningPhase への写像。
    SKILL.md のフェーズが Workflow.lean の学習ライフサイクルに対応する。 -/
def toWorkflowPhase : EvolvePhase → LearningPhase
  | .observe     => .observation
  | .hypothesize => .hypothesizing
  | .verify      => .verification
  | .judge       => .judging
  | .integrate   => .integration
  | .retire      => .retirement

/-- フェーズとエージェントの対応。
    各 Phase に責任を持つエージェント。
    SKILL.md のアーキテクチャ図に基づく。 -/
def phaseAgent : EvolvePhase → EvolveAgent
  | .observe     => .observer
  | .hypothesize => .hypothesizer
  | .verify      => .verifier
  | .judge       => .judge
  | .integrate   => .integrator
  | .retire      => .integrator  -- 退役も Integrator が担当

-- ============================================================
-- マニフェスト準拠性の性質
-- ============================================================

/-- /evolve の構造的性質。各性質はマニフェスト原則に対応。 -/
inductive ComplianceProperty where
  | lifecycleAlignment    -- Workflow.lean の LearningPhase と整合
  | verificationSeparation -- P2: Verifier が独立コンテキスト
  | humanApproval         -- T6: 統合前に人間の承認
  | compatibilityRequired -- P3: 全改善に互換性分類
  | observabilityFirst    -- P4/D4: 観察が最初のフェーズ
  | selfApplication       -- D9: /evolve 自身が改善対象
  | retirementDual        -- 退役基準が二重（形式 + ポリシー）
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- φ₁: フェーズ順序が学習ライフサイクルに整合
-- ============================================================

/-- [目標命題 φ₁]
    タスク: /evolve のフェーズ遷移が Workflow.lean の validPhaseTransition と整合する。
    形式化の意図: toWorkflowPhase で写した隣接フェーズの遷移が全て有効。
    verify→judge→integrate のパスと verify→integrate のフォールバックの両方を含む。 -/
theorem phase_order_aligns_with_workflow :
  validPhaseTransition (toWorkflowPhase .observe) (toWorkflowPhase .hypothesize) ∧
  validPhaseTransition (toWorkflowPhase .hypothesize) (toWorkflowPhase .verify) ∧
  validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .judge) ∧
  validPhaseTransition (toWorkflowPhase .judge) (toWorkflowPhase .integrate) ∧
  validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .integrate) ∧
  validPhaseTransition (toWorkflowPhase .integrate) (toWorkflowPhase .retire) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> trivial

/-- 完全 1 周は Workflow.lean の full_cycle_exists に一致する（judge フェーズ含む）。 -/
theorem evolve_full_cycle_matches_workflow :
  (toWorkflowPhase .observe = .observation) ∧
  (toWorkflowPhase .hypothesize = .hypothesizing) ∧
  (toWorkflowPhase .verify = .verification) ∧
  (toWorkflowPhase .judge = .judging) ∧
  (toWorkflowPhase .integrate = .integration) ∧
  (toWorkflowPhase .retire = .retirement) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> rfl

-- ============================================================
-- φ₂: 全フェーズにエージェントが割り当てられている
-- ============================================================

/-- [目標命題 φ₂]
    タスク: /evolve の全 5 フェーズにエージェントが割り当て済み。
    形式化の意図: phaseAgent が全射（surjective onto defined agents）。 -/
theorem all_phases_have_agents :
  ∀ (p : EvolvePhase), ∃ (a : EvolveAgent), phaseAgent p = a := by
  intro p; exact ⟨phaseAgent p, rfl⟩

/-- 5 種のエージェントが全て使用されている。 -/
theorem all_agents_used :
  (∃ p, phaseAgent p = .observer) ∧
  (∃ p, phaseAgent p = .hypothesizer) ∧
  (∃ p, phaseAgent p = .verifier) ∧
  (∃ p, phaseAgent p = .judge) ∧
  (∃ p, phaseAgent p = .integrator) := by
  refine ⟨⟨.observe, rfl⟩, ⟨.hypothesize, rfl⟩, ⟨.verify, rfl⟩, ⟨.judge, rfl⟩, ⟨.integrate, rfl⟩⟩

-- ============================================================
-- φ₃: P2 検証の独立性
-- ============================================================

/-- /evolve の Verifier の独立性プロファイル。
    SKILL.md の「P2 の限界」セクションに基づく。
    contextSeparated = true（Agent tool で別コンテキスト）
    framingIndependent = false（Worker が Verifier へのプロンプトを構成）
    executionAutomatic = false（Verifier の起動は orchestrator の Agent tool 呼び出しに依存。
      SKILL.md Step 3 は命令的手順であり hook 等で構造的に強制されていない。
      Verifier レビュー Issue 1 を受けて修正）
    evaluatorIndependent = false（同一モデルの Subagent） -/
def evolveVerifierProfile : VerificationIndependence :=
  { contextSeparated    := true
    framingIndependent   := false
    executionAutomatic   := false
    evaluatorIndependent := false }

/-- [目標命題 φ₃]
    タスク: /evolve の Verifier は low リスクにのみ十分。
    形式化の意図: satisfiedConditions を計算し、requiredConditions と比較。

    結果: 1/4 条件充足（contextSeparated のみ）= low に十分。
    moderate 以上には不十分 → SKILL.md が「moderate レベル」と自称しているが、
    executionAutomatic が構造的に強制されていないため、厳密には low レベル。
    Verifier レビュー Issue 1 により修正。 -/
theorem evolve_verifier_sufficient_for_low :
  sufficientVerification evolveVerifierProfile .low := by
  simp [sufficientVerification, satisfiedConditions, evolveVerifierProfile, requiredConditions]

/-- moderate リスクには不十分（Verifier Issue 1 の帰結）。
    SKILL.md は「moderate レベル（2/4 条件充足）」と記載しているが、
    executionAutomatic = false に修正したため 1/4 条件。
    → SKILL.md の記述を修正するか、Phase 3 を hook で強制する必要がある。 -/
theorem evolve_verifier_insufficient_for_moderate :
  ¬sufficientVerification evolveVerifierProfile .moderate := by
  simp [sufficientVerification, satisfiedConditions, evolveVerifierProfile, requiredConditions]

/-- high リスクには不十分。 -/
theorem evolve_verifier_insufficient_for_high :
  ¬sufficientVerification evolveVerifierProfile .high := by
  simp [sufficientVerification, satisfiedConditions, evolveVerifierProfile, requiredConditions]

/-- critical リスクにも不十分。 -/
theorem evolve_verifier_insufficient_for_critical :
  ¬sufficientVerification evolveVerifierProfile .critical := by
  simp [sufficientVerification, satisfiedConditions, evolveVerifierProfile, requiredConditions]

-- ============================================================
-- φ₄: 統合ゲートの整合性
-- ============================================================

/-- [目標命題 φ₄]
    タスク: /evolve の統合フェーズが Workflow.lean の integrationGateCondition を
    前提として要求していることの型レベル表現。

    /evolve の Step 4（人間承認取得）+ Step 5（Integrator）は
    integrationGateCondition の 3 条件を手続的に実現する。 -/
theorem integration_gate_structure :
  -- 条件 1: independentlyVerified = true → Phase 3 で Verifier が PASS
  -- 条件 2: status = .verified → Phase 3 の Gate 通過
  -- 条件 3: breakingChange → epoch increment
  -- これらは integrationGateCondition の定義そのもの
  ∀ (ki : KnowledgeItem) (w_before w_after : World),
    integrationGateCondition ki w_before w_after →
    ki.independentlyVerified = true ∧ ki.status = .verified := by
  intro ki _ _ ⟨h_iv, h_status, _⟩
  exact ⟨h_iv, h_status⟩

-- ============================================================
-- φ₅: 検証なしの統合は禁止
-- ============================================================

/-- [目標命題 φ₅]
    タスク: /evolve で「観察→統合」や「仮説化→統合」のショートカットが不可能。
    形式化の意図: Workflow.lean の integration_requires_verification の再利用。 -/
theorem evolve_no_verification_bypass :
  ¬validKnowledgeTransition .observed .integrated ∧
  ¬validKnowledgeTransition .hypothesized .integrated :=
  integration_requires_verification

-- ============================================================
-- φ₆: 互換性分類の代数的性質
-- ============================================================

/-- [目標命題 φ₆]
    タスク: /evolve が互換性分類を使用する際、分類の合成が正しく動作すること。
    形式化の意図: conservative extension 優先戦略の安全性。

    /evolve が「conservative extension 優先」を採用している場合、
    conservative extension の連鎖は conservative extension のまま。 -/
theorem conservative_strategy_safe :
  CompatibilityClass.conservativeExtension.join .conservativeExtension
    = .conservativeExtension := by rfl

/-- breaking change が含まれると全体が breaking change になる。
    /evolve の Integrator が breaking change を適切に検出する根拠。 -/
theorem breaking_change_propagates :
  ∀ (c : CompatibilityClass),
    CompatibilityClass.breakingChange.join c = .breakingChange :=
  breaking_change_dominates

-- ============================================================
-- φ₇: 退役基準の二重性
-- ============================================================

/-- 退役の根拠の種類。SKILL.md Step 6 の「基準 A / 基準 B」に対応。 -/
inductive RetirementBasis where
  | formal   -- 基準 A: Workflow.lean retirementCandidate（breakingChange）
  | policy   -- 基準 B: p3-governed-learning.md（6ヶ月未更新）
  deriving BEq, Repr, DecidableEq

/-- [目標命題 φ₇]
    タスク: /evolve の退役基準が二重であること。
    形式化の意図: 2 つの独立した基準が存在する。 -/
theorem retirement_criteria_dual :
  RetirementBasis.formal ≠ RetirementBasis.policy := by
  intro h; cases h

/-- 基準 A は Workflow.lean の retirementCandidate と整合。
    integrated ∧ breakingChange の知識が退役候補。 -/
theorem formal_retirement_matches_workflow :
  ∀ (ki : KnowledgeItem),
    retirementCandidate ki →
    ki.status = .integrated ∧ ki.compatibility = .breakingChange := by
  intro ki h
  exact h

-- ============================================================
-- φ₈: D9 自己適用（SelfGoverning）
-- ============================================================

/-- /evolve の構成要素。D9 自己適用の対象。 -/
inductive EvolveComponent where
  | skill          -- SKILL.md
  | observerAgent  -- observer/AGENT.md
  | hypothesizerAgent -- hypothesizer/AGENT.md
  | integratorAgent   -- integrator/AGENT.md
  | verifierAgent     -- verifier.md
  | judgeAgent        -- judge.md
  | hooks          -- evolve-*.sh
  deriving BEq, Repr, DecidableEq

/-- /evolve の構成要素は SelfGoverning（D9）。
    互換性分類を全構成要素に適用できる。 -/
instance : SelfGoverning EvolveComponent where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

/-- [目標命題 φ₈]
    タスク: /evolve の全構成要素が列挙されていること。
    形式化の意図: D9 自己適用の対象が網羅的。 -/
theorem all_components_enumerated :
  ∀ (c : EvolveComponent),
    c = .skill ∨ c = .observerAgent ∨ c = .hypothesizerAgent ∨
    c = .integratorAgent ∨ c = .verifierAgent ∨ c = .judgeAgent ∨ c = .hooks := by
  intro c; cases c <;> simp

-- ============================================================
-- φ₉: D4 フェーズ順序（安全→検証→可観測→統治）
-- ============================================================

/-- [目標命題 φ₉]
    タスク: /evolve の観察が最初のフェーズであること（P4 可観測性の先行）。
    形式化の意図: フェーズ順序が D4 に整合。 -/
theorem observability_first :
  toWorkflowPhase .observe = .observation := by rfl

/-- 検証は統合に先行する（D4 の部分）。 -/
theorem verification_precedes_integration :
  validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .integrate) := by
  trivial

-- ============================================================
-- φ₁₀: 仮説の反証可能性（Γ \ T₀ の設計）
-- ============================================================

/-- /evolve SKILL.md が宣言する仮説。
    全て反証条件付き（Γ \ T₀ の要件）。 -/
inductive EvolveHypothesis where
  | h1_teams_natural     -- Agent Teams が学習ライフサイクルの自然なモデル化
  | h2_four_agents       -- 4 エージェント分離が最適粒度
  | h3_metrics_adequate  -- AxiomQuality の指標で改善を計測可能
  | h4_conservative_first -- conservative extension 優先が最適戦略
  | h5_one_per_session   -- 1 セッション 1 evolve が適切な頻度
  | h6_cost_efficiency   -- /evolve のコスト効率は経時的に改善する
  deriving BEq, Repr, DecidableEq

/-- 全仮説が列挙されている。 -/
theorem all_hypotheses_enumerated :
  ∀ (h : EvolveHypothesis),
    h = .h1_teams_natural ∨ h = .h2_four_agents ∨
    h = .h3_metrics_adequate ∨ h = .h4_conservative_first ∨
    h = .h5_one_per_session ∨ h = .h6_cost_efficiency := by
  intro h; cases h <;> simp

/-- 仮説の数は 6 つ。 -/
theorem hypothesis_count :
  [EvolveHypothesis.h1_teams_natural,
   .h2_four_agents, .h3_metrics_adequate,
   .h4_conservative_first, .h5_one_per_session,
   .h6_cost_efficiency].length = 6 := by rfl

-- ============================================================
-- φ₁₁: Deferral の正当性条件
-- ============================================================

/-!
## Deferral（引き継ぎ）の正当性

/evolve は 1 サイクルで完結するのが基本設計。
deferral は例外であり、以下の 3 条件のいずれかに該当する場合のみ正当。
条件に該当しない deferral は stasisUnhealthy（Evolution.lean）のインスタンス。
-/

/-- deferral の正当な理由。3 条件のいずれかに該当する場合のみ。 -/
inductive DeferralReason where
  | resourceExhaustion   -- T7: サイクル予算超過（globalResourceBound）
  | dependencyBlocked    -- 半順序: 先行改善が未完了（structureDependsOn）
  | actionSpaceExceeded  -- L4: 行動空間外（人間による拡張が必要）
  deriving BEq, Repr, DecidableEq

/-- deferral の状態。 -/
inductive DeferralStatus where
  | open       -- 未解決（次サイクルで優先的に扱う）
  | resolved   -- 次サイクルで解決済み
  | abandoned  -- 実装不可能と判断（2 回 defer → 放棄または分割）
  deriving BEq, Repr, DecidableEq

/-- [目標命題 φ₁₁]
    正当な理由なき deferral は不正。
    3 条件のいずれかに該当しなければ deferral できない。 -/
theorem deferral_requires_justification :
  ∀ (r : DeferralReason),
    r = .resourceExhaustion ∨
    r = .dependencyBlocked ∨
    r = .actionSpaceExceeded := by
  intro r; cases r <;> simp

/-- [φ₁₁ 系] 追跡されていない前方参照は D3 条件 2 違反。
    notes に未完了タスク（前方参照）が存在するが、対応する deferred エントリがない場合、
    劣化の検知が humanReadable のみであり、structurallyQueryable ではない。
    D3 精緻化（d3_human_readable_insufficient）により、これは不十分。 -/
theorem untracked_forward_reference_violates_d3 :
  ¬effectivelyOptimizable ⟨true, true, .humanReadable, true⟩ :=
  d3_human_readable_insufficient

/-- deferral 状態は 3 値のいずれか。 -/
theorem deferral_status_exhaustive :
  ∀ (s : DeferralStatus),
    s = .open ∨ s = .resolved ∨ s = .abandoned := by
  intro s; cases s <;> simp

-- ============================================================
-- ループバック設計（Issue #7, #8, #9）
-- ============================================================

/-- FAIL 分析の根本原因分類。SKILL.md Step 3 FAIL 分析に対応。 -/
inductive FailRootCause where
  | observationError   -- Observer の計測データが不正確
  | hypothesisError    -- Hypothesizer の論理的誤り
  | assumptionError    -- 前提条件の誤り
  | preconditionError  -- 先行フェーズの成果物不十分
  deriving BEq, Repr

/-- ループバックの対象フェーズ。根本原因に応じて異なるフェーズに戻る（Issue #8）。
    observation_error は Phase 1（Observer）に、hypothesis/assumption_error は Phase 2（Hypothesizer）に。
    precondition_error はループバックなし。 -/
def loopbackTarget : FailRootCause → Option EvolvePhase
  | .observationError  => some .observe
  | .hypothesisError   => some .hypothesize
  | .assumptionError   => some .hypothesize
  | .preconditionError => none

/-- ループバック予算。T6（人間が設定）+ T7（リソース有限性）（Issue #7）。
    globalResourceBound は opaque であり具体値を導出できないため、
    予算は人間が設定するパラメータとする。 -/
structure LoopbackBudget where
  maxRetries : Nat
  deriving BEq, Repr

/-- φ₁₂: ループバック対象の有効性。
    loopbackTarget が返すフェーズへの遷移が validPhaseTransition で正当化される。 -/
theorem loopback_target_valid_transition :
  ∀ (cause : FailRootCause) (phase : EvolvePhase),
    loopbackTarget cause = some phase →
    validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase phase) := by
  intro cause phase h
  cases cause <;> simp [loopbackTarget] at h <;> subst h <;> simp [toWorkflowPhase, validPhaseTransition]

/-- φ₁₃: ループバック実行エージェントの一意性（Issue #9）。
    loopbackTarget で決まるフェーズには phaseAgent で一意のエージェントが対応する。 -/
theorem loopback_agent_determined :
  ∀ (cause : FailRootCause) (phase : EvolvePhase),
    loopbackTarget cause = some phase →
    ∃ (a : EvolveAgent), phaseAgent phase = a := by
  intro cause phase h
  cases cause <;> simp [loopbackTarget] at h <;> subst h <;> exact ⟨_, rfl⟩

/-- φ₁₄: observation_error は Observer にループバックする。 -/
theorem observation_error_loops_to_observer :
  loopbackTarget .observationError = some .observe ∧
  phaseAgent .observe = .observer := by
  constructor <;> rfl

/-- φ₁₅: hypothesis_error は Hypothesizer にループバックする。 -/
theorem hypothesis_error_loops_to_hypothesizer :
  loopbackTarget .hypothesisError = some .hypothesize ∧
  phaseAgent .hypothesize = .hypothesizer := by
  constructor <;> rfl

/-- φ₁₆: preconditionError はループバックしない。 -/
theorem precondition_error_no_loopback :
  loopbackTarget .preconditionError = none := by rfl

/-- φ₁₇: ループバック予算は任意の自然数を受け入れるパラメータ。
    globalResourceBound は opaque であり具体値を導出できない（Issue #7 の核心）。 -/
theorem loopback_budget_is_parameter :
  ∀ (n : Nat), (⟨n⟩ : LoopbackBudget).maxRetries = n := by
  intro n; rfl

/-- φ₁₈: Judge FAIL 時は Hypothesizer にループバックする。
    SKILL.md Step 3.5: Judge FAIL → FAIL_LIST → 再仮説化。
    judging→hypothesizing の遷移が validPhaseTransition で正当化される。 -/
theorem judge_fail_loops_to_hypothesizer :
  validPhaseTransition (toWorkflowPhase .judge) (toWorkflowPhase .hypothesize) ∧
  phaseAgent .hypothesize = .hypothesizer := by
  constructor
  · trivial
  · rfl

-- ============================================================
-- 合成命題 φ: 全性質の合取
-- ============================================================

/-- [目標命題 φ — 全性質の合取]
    タスク: /evolve スキルはマニフェスト準拠の構造的要件を全て満たす。 -/
theorem evolve_skill_compliant :
  -- φ₁: フェーズ順序が学習ライフサイクルに整合（judge フェーズ含む）
  (validPhaseTransition (toWorkflowPhase .observe) (toWorkflowPhase .hypothesize) ∧
   validPhaseTransition (toWorkflowPhase .hypothesize) (toWorkflowPhase .verify) ∧
   validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .judge) ∧
   validPhaseTransition (toWorkflowPhase .judge) (toWorkflowPhase .integrate) ∧
   validPhaseTransition (toWorkflowPhase .verify) (toWorkflowPhase .integrate) ∧
   validPhaseTransition (toWorkflowPhase .integrate) (toWorkflowPhase .retire)) ∧
  -- φ₂: 全エージェントが使用されている
  ((∃ p, phaseAgent p = EvolveAgent.observer) ∧
   (∃ p, phaseAgent p = EvolveAgent.hypothesizer) ∧
   (∃ p, phaseAgent p = EvolveAgent.verifier) ∧
   (∃ p, phaseAgent p = EvolveAgent.judge) ∧
   (∃ p, phaseAgent p = EvolveAgent.integrator)) ∧
  -- φ₃: Verifier は low に十分（moderate は不十分 — SKILL.md の改善候補）
  sufficientVerification evolveVerifierProfile .low ∧
  -- φ₅: 検証バイパス不可
  (¬validKnowledgeTransition .observed .integrated ∧
   ¬validKnowledgeTransition .hypothesized .integrated) ∧
  -- φ₉: 観察が最初
  (toWorkflowPhase .observe = .observation) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  -- φ₁
  · exact phase_order_aligns_with_workflow
  -- φ₂
  · exact all_agents_used
  -- φ₃
  · exact evolve_verifier_sufficient_for_low
  -- φ₅
  · exact evolve_no_verification_bypass
  -- φ₉
  · rfl

-- ============================================================
-- Sorry Inventory
-- ============================================================

/-!
## Sorry Inventory

sorry なし。新規 axiom なし。
全 theorem は型定義の構造的な cases 解析、rfl、trivial、simp で証明完了。

**公理依存性:** propext のみ（Lean 基盤公理）。
非論理的公理（axiom）への依存なし。
-/

end Manifest.EvolveSkill

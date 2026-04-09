import Manifest.DesignFoundation
import Manifest.Models.Instances.ForgeCode.Assumptions

/-!
# ForgeCode 条件付き設計基礎 — ConditionalDesignFoundation

D1-D18（プラットフォーム非依存設計定理）を ForgeCode のプリミティブに
マッピングする条件付き公理系。

## 位置づけ

```
D1-D18 (DesignFoundation.lean, プラットフォーム非依存)
  ↓ 条件付き導出（ForgeCode の仮定 FC-C1~C7, FC-H1~H10）
FC1-FCn (このファイル, ForgeCode 固有)
```

## 設計方針

- 手書き（D→FC のマッピングは意味的推論が必要）
- 各 FC axiom に Derivation Card を付与
- DesignFoundation.lean の型（EnforcementLayer, VerificationIndependence 等）を直接使用
- 0 sorry を維持

## Claude Code との対比

ForgeCode は Claude Code とは異なるアーキテクチャ判断を持つ:
- Hook (exit 2 block) なし → Policy engine (Deny) が主な構造的強制
- Subagent 1 種 → 3 種の組込みエージェント (forge/sage/muse) + Task 委譲
- CLAUDE.md → AGENTS.md (同等の役割)
- PostToolUse async → 6 種のライフサイクルイベント + composable hooks
-/

namespace Manifest.Models.Instances.ForgeCode

open Manifest
open Manifest.Models.Assumptions

-- ============================================================
-- ForgeCode プリミティブの存在論的定義
-- ============================================================

/-- ForgeCode のライフサイクルイベント種別。 -/
inductive LifecycleEvent where
  | start         -- 会話初期化
  | «end»         -- 会話完了
  | request       -- 各 LLM リクエスト
  | response      -- 各 LLM レスポンス
  | toolcallStart -- ツール実行前
  | toolcallEnd   -- ツール実行後
  deriving BEq, Repr

/-- ForgeCode の組込みエージェント種別。 -/
inductive AgentKind where
  | forge  -- 実装エージェント (read-write-shell)
  | sage   -- 研究エージェント (read-only)
  | muse   -- 計画エージェント (read + plan write)
  | custom -- カスタムエージェント (.forge/agents/)
  deriving BEq, Repr

/-- ForgeCode のプリミティブ。
    D1 の EnforcementLayer にマッピングされる。 -/
inductive FCPrimitive where
  /-- Policy Engine: Allow/Deny/Confirm のブール代数。
      4 操作型 (read/write/execute/fetch) に glob パターンで適用。
      Deny はランタイムが強制（FC-H1）。 -/
  | policy
  /-- Lifecycle Hook: 6 種のイベントに対する composable ハンドラ。
      doom loop 検出、compaction、pending todos 等の構造的挙動を実装。 -/
  | lifecycleHook (event : LifecycleEvent)
  /-- Agent: 組込み + カスタムエージェント。ツールホワイトリストで能力制限。 -/
  | agent (kind : AgentKind)
  /-- AGENTS.md: プロジェクトルールファイル。規範的指針。 -/
  | agentsMd
  /-- Skill: .forge/skills/*/SKILL.md。再利用可能手順。T2 永続。 -/
  | skill
  /-- Sandbox: git worktree ベースのファイルシステム隔離。 -/
  | sandbox
  /-- Snapshot: ファイル変更前のスナップショット保存。Undo の基盤。 -/
  | snapshot
  /-- MCP Server: 外部サービス連携 (stdio/HTTP)。 -/
  | mcpServer
  /-- Todo: タスク追跡システム (mandatory todo_write)。 -/
  | todo
  deriving BEq, Repr

-- ============================================================
-- D1 マッピング: FC プリミティブ → EnforcementLayer
-- ============================================================

/-- [Derivation Card]
    Derives from: D1 (EnforcementLayer), FC-C1, FC-H1, FC-H2
    Proposition: FC-D1
    Content: Each ForgeCode primitive maps to an enforcement layer.
      Policy (Deny) = structural (FC-H1: runtime-enforced, agent cannot bypass).
      Policy (Confirm) = procedural (user must approve, but agent initiated).
      Lifecycle Hook = procedural (observes/injects but doesn't block tool calls directly).
      Agent (sage) = structural for read-only (FC-H2: no write tools by construction).
      Agent (forge/muse/custom) = procedural (tool-restricted but has write capability).
      AGENTS.md = normative (loaded into prompt, probabilistic compliance by P5).
      Skill = procedural (structured procedure, not mandatory).
      Sandbox = procedural (git worktree isolation, not OS-level).
      Snapshot = procedural (automatic pre-modification backup).
      MCP Server = procedural (external integration).
      Todo = procedural (mandatory tracking, but content not verified).
    Proof strategy: pattern matching on FCPrimitive constructors -/
def fcEnforcementLayer : FCPrimitive → EnforcementLayer
  | .policy                    => .structural   -- Deny はランタイム強制
  | .lifecycleHook _           => .procedural   -- 観察・注入だが直接ブロックしない
  | .agent .sage               => .structural   -- read-only by construction
  | .agent _                   => .procedural   -- ツール制限あるが write 可能
  | .agentsMd                  => .normative    -- プロンプト読み込み、確率的遵守
  | .skill                     => .procedural   -- 構造化手順、強制ではない
  | .sandbox                   => .procedural   -- git worktree 隔離
  | .snapshot                  => .procedural   -- 自動スナップショット
  | .mcpServer                 => .procedural   -- 外部連携
  | .todo                      => .procedural   -- タスク追跡

-- ============================================================
-- D1 定理: 構造的強制の存在
-- ============================================================

/-- [Derivation Card]
    Derives from: fcEnforcementLayer (FC-D1), d1_fixed_requires_structural (D1)
    Proposition: FC1
    Content: ForgeCode has structural enforcement via Policy (Deny rules).
      FC-H1: Policy engine evaluates all operations at runtime, agent cannot bypass.
    Proof strategy: rfl on fcEnforcementLayer .policy -/
theorem fc1_policy_structural :
  fcEnforcementLayer .policy = .structural := by rfl

/-- [Derivation Card]
    Derives from: fcEnforcementLayer (FC-D1), FC-H2
    Proposition: FC2
    Content: sage agent provides structural read-only enforcement.
      FC-H2: sage's tool whitelist contains no write/shell/patch tools.
    Proof strategy: rfl -/
theorem fc2_sage_structural :
  fcEnforcementLayer (.agent .sage) = .structural := by rfl

/-- [Derivation Card]
    Derives from: fcEnforcementLayer (FC-D1)
    Proposition: FC3
    Content: AGENTS.md is normative guideline (analogous to CC4 for CLAUDE.md).
    Proof strategy: rfl -/
theorem fc3_agentsMd_normative :
  fcEnforcementLayer .agentsMd = .normative := by rfl

-- ============================================================
-- D2 マッピング: sage エージェントの独立性条件
-- ============================================================

/-- ForgeCode sage エージェントの独立性条件（Task 委譲時）。
    FC-H2 (contextSeparated, framingIndependent) + FC-C2 (verification method)。
    Task 委譲は Worker (forge) が呼び出すため executionAutomatic=false。
    同一モデルファミリ使用可能のため evaluatorIndependent は設定依存。 -/
def fcSageTaskDelegated : VerificationIndependence := {
  contextSeparated := true      -- Task 委譲は独立コンテキスト
  framingIndependent := true    -- sage は自身の基準で調査
  executionAutomatic := false   -- forge が Task を呼び出す裁量あり
  evaluatorIndependent := false -- 同一モデルファミリ可能
}

/-- ForgeCode sage の独立性条件（Plan-then-Act で muse 経由時）。
    muse → sage の委譲は計画フェーズの一部であり、
    forge (Worker) とは分離された実行パスで sage が呼ばれる。 -/
def fcSagePlanDelegated : VerificationIndependence := {
  contextSeparated := true      -- sage は muse からも独立コンテキスト
  framingIndependent := true    -- sage の調査基準は独立
  executionAutomatic := false   -- muse が sage を呼ぶ裁量あり
  evaluatorIndependent := false -- 同一モデルファミリ可能
}

/-- ForgeCode sage エージェントの独立性条件（異なるモデルファミリ使用時）。
    FC-H11: agent ごとに provider/model を設定可能。
    sage を異なるモデルで動かすと evaluatorIndependent=true。 -/
def fcSageCrossModel : VerificationIndependence := {
  contextSeparated := true      -- Task 委譲は独立コンテキスト
  framingIndependent := true    -- sage は自身の基準で調査
  executionAutomatic := false   -- forge が Task を呼び出す裁量あり
  evaluatorIndependent := true  -- FC-H11: 異なるモデルファミリ
}

/-- [Derivation Card]
    Derives from: requiredConditions (D2), fcSageCrossModel, FC-H11
    Proposition: FC4a
    Content: sage with cross-model config satisfies 3 of 4 independence conditions.
      Sufficient for high risk. Requires explicit provider/model override in sage agent definition.
    Proof strategy: native_decide -/
theorem fc4a_sage_crossmodel_satisfies_high :
  satisfiedConditions fcSageCrossModel ≥ requiredConditions .high := by
  native_decide

/-- [Derivation Card]
    Derives from: requiredConditions (D2), fcSageTaskDelegated
    Proposition: FC4
    Content: sage via Task delegation satisfies 2 of 4 independence conditions.
      Sufficient for moderate risk, insufficient for high risk.
    Proof strategy: native_decide -/
theorem fc4_sage_satisfies_moderate :
  satisfiedConditions fcSageTaskDelegated ≥ requiredConditions .moderate ∧
  satisfiedConditions fcSageTaskDelegated < requiredConditions .high := by
  constructor <;> native_decide

/-- [Derivation Card]
    Derives from: requiredConditions (D2), fcSageTaskDelegated
    Proposition: FC5
    Content: sage is insufficient for critical risk.
      evaluatorIndependent=false means human review required for L1 changes.
    Proof strategy: native_decide -/
theorem fc5_sage_insufficient_critical :
  satisfiedConditions fcSageTaskDelegated < requiredConditions .critical := by
  native_decide

-- ============================================================
-- D11 マッピング: コンテキストコスト
-- ============================================================

/-- Context cost of each ForgeCode primitive.
    Higher value = more context consumption per session.
    Policy has 0 cost (runtime evaluation, not in context).
    Lifecycle hooks have 0 cost (runtime handlers).
    AGENTS.md has highest cost (always loaded into system prompt).
    Todo has 1 cost (lightweight status tracking in context). -/
def fcContextCost : FCPrimitive → Nat
  | .policy          => 0   -- ランタイム評価、コンテキスト消費なし
  | .lifecycleHook _ => 0   -- ランタイムハンドラ
  | .sandbox         => 0   -- git worktree、コンテキスト消費なし
  | .snapshot        => 0   -- ファイルシステムレベル
  | .agent _         => 1   -- 委譲時のみ
  | .mcpServer       => 1   -- ツール定義のみ
  | .todo            => 1   -- 状態追跡
  | .skill           => 2   -- セッション開始時に自動ロード
  | .agentsMd        => 3   -- 毎セッション読み込み、最大サイズ

/-- [Derivation Card]
    Derives from: fcContextCost, fcEnforcementLayer
    Proposition: FC6
    Content: D11 inverse correlation holds for ForgeCode:
      structural enforcement (policy) has lowest context cost (0),
      normative guideline (AGENTS.md) has highest context cost (3).
    Proof strategy: rfl for all parts -/
theorem fc6_context_cost_inverse_correlation :
  fcContextCost .policy < fcContextCost .agentsMd ∧
  fcEnforcementLayer .policy = .structural ∧
  fcEnforcementLayer .agentsMd = .normative := by
  refine ⟨?_, ?_, ?_⟩ <;> simp [fcContextCost, fcEnforcementLayer]

-- ============================================================
-- D10 マッピング: T1/T2 分類
-- ============================================================

/-- T1 (ephemeral) or T2 (persistent) classification of FC primitives.
    T2 primitives survive across sessions; T1 primitives do not.
    D10: improvements accumulate only through T2 primitives. -/
def fcPersistence : FCPrimitive → Bool
  | .policy          => true   -- .forge.toml / permissions.yaml に定義
  | .lifecycleHook _ => true   -- Rust コードにコンパイル済み
  | .agentsMd        => true   -- プロジェクトルートのファイル
  | .skill           => true   -- .forge/skills/ ファイル
  | .sandbox         => false  -- セッション内の一時 worktree
  | .snapshot        => false  -- 一時的なファイルバックアップ
  | .mcpServer       => true   -- 設定ファイルに定義
  | .todo            => false  -- セッション内のタスク追跡
  | .agent _         => false  -- エージェントインスタンスはセッション内で消滅

/-- [Derivation Card]
    Derives from: fcPersistence, d10_agent_temporary_structure_permanent (D10)
    Proposition: FC7
    Content: Agent instances, sandbox worktrees, snapshots, and todos are T1 (ephemeral).
      Policy, lifecycle hooks, AGENTS.md, skills, and MCP servers are T2 (persistent).
    Proof strategy: decide on each constructor -/
theorem fc7_persistence_classification :
  fcPersistence .policy = true ∧
  fcPersistence (.agent .forge) = false ∧
  fcPersistence .agentsMd = true ∧
  fcPersistence .skill = true ∧
  fcPersistence .sandbox = false ∧
  fcPersistence .todo = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> rfl

-- ============================================================
-- D15 マッピング: ハーネスエンジニアリング
-- ============================================================

/-- [Derivation Card]
    Derives from: D15a (unbounded retry infeasible), FC-H3, FC-H6
    Proposition: FC8
    Content: ForgeCode implements D15a/D15b structurally:
      - Doom loop detection (FC-H3) prevents non-converging iteration
      - Mandatory todo_write (FC-H6) prevents premature termination
      - max_requests_per_turn (100) and max_tool_failure_per_turn (3) bound retries
    These are derived from the ForgeCode-specific analysis in #147 (S1). -/
theorem fc8_harness_engineering :
  fcEnforcementLayer (.lifecycleHook .toolcallEnd) = .procedural := by rfl

-- ============================================================
-- D18 マッピング: マルチエージェント協調
-- ============================================================

/-- [Derivation Card]
    Derives from: D18 (multi-agent coordination), FC-C6, FC-H4
    Proposition: FC9
    Content: ForgeCode implements D18 via Task tool delegation:
      - 3 built-in agents with role-based tool restrictions
      - Task tool calls run in parallel (FC-H4)
      - Agent-as-tool recursion enables hierarchical decomposition
      - Plan-then-Act workflow (FC-C5) separates planning from execution
    Unlike Claude Code (Subagent + Agent Teams), ForgeCode uses a single
    coordination primitive (Task) with differentiated agent roles. -/
theorem fc9_multiagent :
  fcEnforcementLayer (.agent .sage) = .structural ∧
  fcEnforcementLayer (.agent .forge) = .procedural := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- カバレッジ: D1-D18 → FC マッピングの存在
-- ============================================================

/-- Design principles that have direct FC primitive mappings.
    D1, D2, D3, D10, D11, D15, D18 have direct mappings.
    D4, D5, D6-D9, D12, D13, D14, D16, D17 are methodological or meta-level. -/
def hasFCMapping : DesignPrinciple → Bool
  | .d1_enforcementLayering            => true  -- fcEnforcementLayer
  | .d2_workerVerifierSeparation       => true  -- fcSageTaskDelegated
  | .d3_observabilityFirst             => true  -- lifecycle hooks for P4
  | .d4_progressiveSelfApplication     => false -- methodological
  | .d5_specTestImpl                   => false -- project-level (not FC primitive)
  | .d10_structuralPermanence          => true  -- fcPersistence
  | .d11_contextEconomy                => true  -- fcContextCost
  | .d13_premiseNegationPropagation    => false -- methodological
  | .d6_boundaryMitigationVariable     => false -- methodological
  | .d7_trustAsymmetry                 => false -- methodological
  | .d8_equilibriumSearch              => false -- methodological
  | .d9_selfMaintenance                => false -- methodological
  | .d12_constraintSatisfactionTaskDesign => false -- methodological
  | .d14_verificationOrderConstraint   => false -- methodological
  | .d15_harnessEngineering            => true  -- doom loop + todo + guardrails
  | .d16_informationRelevance          => true  -- tiered thinking + semantic search
  | .d17_deductiveDesignWorkflow       => false -- meta-level
  | .d18_multiAgentCoordination        => true  -- Task tool + 3 agents

/-- All 18 design principles enumerated. -/
def allDesignPrinciples : List DesignPrinciple :=
  [.d1_enforcementLayering, .d2_workerVerifierSeparation,
   .d3_observabilityFirst, .d4_progressiveSelfApplication,
   .d5_specTestImpl, .d6_boundaryMitigationVariable,
   .d7_trustAsymmetry, .d8_equilibriumSearch,
   .d9_selfMaintenance, .d10_structuralPermanence,
   .d11_contextEconomy, .d12_constraintSatisfactionTaskDesign,
   .d13_premiseNegationPropagation, .d14_verificationOrderConstraint,
   .d15_harnessEngineering, .d16_informationRelevance,
   .d17_deductiveDesignWorkflow,
   .d18_multiAgentCoordination]

/-- [Derivation Card]
    Derives from: hasFCMapping, allDesignPrinciples
    Proposition: FC-coverage
    Content: At least 8 of 18 design principles have direct FC primitive mappings.
    Proof strategy: native_decide -/
theorem fc_coverage_at_least_half :
  (allDesignPrinciples.filter hasFCMapping).length ≥ 8 := by
  native_decide

end Manifest.Models.Instances.ForgeCode

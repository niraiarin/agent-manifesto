import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions

/-!
# Claude Code ConditionalDesignFoundation

D1-D14（プラットフォーム非依存設計定理）を Claude Code のプリミティブに
マッピングする条件付き公理系。

## Architecture

```
D1-D14 (DesignFoundation.lean, プラットフォーム非依存)
  ↓ 条件付き導出（Claude Code の仮定 CC-C1~C5, CC-H1~H5）
CC1-CCn (このファイル, Claude Code 固有)
```

## Design Policy

- 手書き（D→CC のマッピングは意味的推論が必要）
- 各 CC axiom に Derivation Card を付与
- DesignFoundation.lean の型（EnforcementLayer, VerificationIndependence 等）を直接使用
- 0 sorry を維持
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest
open Manifest.Models.Assumptions

-- ============================================================
-- Claude Code プリミティブの存在論的定義
-- ============================================================

/-- Claude Code の Hook 種別。 -/
inductive HookKind where
  | preToolUse   -- ツール実行前。exit 2 でブロック可能
  | postToolUse  -- ツール実行後。ブロック不可、async 可能
  | sessionStart -- セッション開始時
  | userPromptSubmit -- ユーザープロンプト送信時
  | taskCompleted    -- タスク完了時
  deriving BEq, Repr

/-- Claude Code のプリミティブ。
    D1 の EnforcementLayer にマッピングされる。 -/
inductive CCPrimitive where
  /-- Hook: ハーネスレベルで実行されるシェルスクリプト。
      PreToolUse は構造的強制、PostToolUse は可観測性。 -/
  | hook (kind : HookKind)
  /-- Permission: settings.json の allow/deny rules。
      間接実行でバイパス可能（CC-H3）のため procedural。 -/
  | permission
  /-- Sandbox: OS レベルのファイルシステム制限。
      有効化時は構造的強制。現在は未有効化。 -/
  | sandbox
  /-- Rule: .claude/rules/*.md。規範的指針。毎セッション読み込み。 -/
  | rule
  /-- Skill: .claude/skills/*/SKILL.md。再利用可能手順。T2 永続。 -/
  | skill
  /-- Agent: subagent（Agent tool 経由）。P2 検証手段。 -/
  | agent
  /-- CLAUDE.md: プロジェクト指示。規範的指針。最大のコンテキストコスト。 -/
  | claudeMd
  /-- MCP Server: 外部サービス連携。 -/
  | mcpServer
  deriving BEq, Repr

-- ============================================================
-- D1 マッピング: CC プリミティブ → EnforcementLayer
-- ============================================================

/-- [Derivation Card]
    Derives from: D1 (EnforcementLayer), CC-C1, CC-H1, CC-H3
    Proposition: CC-D1
    Content: Each Claude Code primitive maps to an enforcement layer.
      PreToolUse hook = structural (CC-H1: agent cannot bypass).
      PostToolUse hook = procedural (cannot block, only observe).
      Permission = procedural (CC-H3: bypassable via indirect execution).
      Sandbox = structural (OS-level, when enabled).
      Rule/CLAUDE.md = normative (CC-H4: loaded into context, probabilistic compliance).
      Skill = procedural (structured procedure, not mandatory).
      Agent = procedural (verification tool, Worker can invoke).
      MCP Server = procedural (external integration).
    Proof strategy: pattern matching on CCPrimitive constructors -/
def ccEnforcementLayer : CCPrimitive → EnforcementLayer
  | .hook .preToolUse     => .structural
  | .hook .postToolUse    => .procedural
  | .hook .sessionStart   => .procedural
  | .hook .userPromptSubmit => .procedural
  | .hook .taskCompleted  => .procedural
  | .permission           => .procedural
  | .sandbox              => .structural
  | .rule                 => .normative
  | .skill                => .procedural
  | .agent                => .procedural
  | .claudeMd             => .normative
  | .mcpServer            => .procedural

-- ============================================================
-- D1 定理: 構造的強制の存在
-- ============================================================

/-- [Derivation Card]
    Derives from: ccEnforcementLayer (CC-D1), d1_fixed_requires_structural (D1)
    Proposition: CC1
    Content: Claude Code has at least one structural enforcement primitive (PreToolUse hook).
      This satisfies D1's requirement that L1 constraints be placed in structural enforcement.
    Note: CC-H1 の反証条件として cwd 移動による hook パス解決失敗が発見された（#414）。
      hook 内 cwd 正規化により対処済み。新規 hook 追加時は同パターンに注意。
    Proof strategy: rfl on ccEnforcementLayer (.hook .preToolUse) -/
theorem cc1_structural_exists :
  ccEnforcementLayer (.hook .preToolUse) = .structural := by rfl

/-- [Derivation Card]
    Derives from: ccEnforcementLayer (CC-D1)
    Proposition: CC2
    Content: Sandbox provides structural enforcement when enabled.
    Proof strategy: rfl -/
theorem cc2_sandbox_structural :
  ccEnforcementLayer .sandbox = .structural := by rfl

/-- [Derivation Card]
    Derives from: ccEnforcementLayer (CC-D1), CC-H3
    Proposition: CC3
    Content: Permission (deny rules) is procedural, not structural.
      CC-H3 establishes that deny rules are bypassable via indirect execution.
    Proof strategy: rfl -/
theorem cc3_permission_procedural :
  ccEnforcementLayer .permission = .procedural := by rfl

/-- [Derivation Card]
    Derives from: ccEnforcementLayer (CC-D1), CC-H4
    Proposition: CC4
    Content: Rules and CLAUDE.md are normative guidelines.
      CC-H4 establishes they are loaded into context (probabilistic compliance by P5).
    Proof strategy: constructor with rfl -/
theorem cc4_normative_exists :
  ccEnforcementLayer .rule = .normative ∧
  ccEnforcementLayer .claudeMd = .normative := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- D2 マッピング: Subagent の独立性条件
-- ============================================================

/-- Claude Code subagent の独立性条件（hook 経由で自動起動時）。
    CC-H1 (executionAutomatic) + CC-H2 (contextSeparated) を反映。
    framingIndependent は verifier.md の設計による。
    evaluatorIndependent は false（同一モデルファミリ）。 -/
def ccSubagentHookInvoked : VerificationIndependence := {
  contextSeparated := true      -- CC-H2: 独立コンテキストウィンドウ
  framingIndependent := true    -- verifier.md: Verifier が自身の基準で判断
  executionAutomatic := true    -- CC-H1: hook 経由で Worker が回避不可
  evaluatorIndependent := false -- 同一モデルファミリ（Anthropic Claude）
}

/-- Claude Code subagent の独立性条件（Worker が手動で /verify を呼出時）。
    手動呼出しでは executionAutomatic=false（Worker の裁量で呼ばないことが可能）。 -/
def ccSubagentManualInvoked : VerificationIndependence := {
  contextSeparated := true      -- CC-H2: 独立コンテキストウィンドウ
  framingIndependent := true    -- verifier.md: Verifier が自身の基準で判断
  executionAutomatic := false   -- 手動呼出し: Worker が検証を回避可能
  evaluatorIndependent := false -- 同一モデルファミリ（Anthropic Claude）
}

/-- [Derivation Card]
    Derives from: requiredConditions (D2), ccSubagentHookInvoked
    Proposition: CC5
    Content: Hook-invoked subagent satisfies 3 of 4 independence conditions.
      Sufficient for high risk (3 required), insufficient for critical (4 required).
    Proof strategy: simp on satisfiedConditions -/
theorem cc5_subagent_hook_satisfies_high :
  satisfiedConditions ccSubagentHookInvoked ≥ requiredConditions .high := by
  simp [satisfiedConditions, ccSubagentHookInvoked, requiredConditions]

/-- [Derivation Card]
    Derives from: requiredConditions (D2), ccSubagentManualInvoked
    Proposition: CC5b
    Content: Manually-invoked subagent satisfies only 2 of 4 conditions.
      Sufficient for moderate risk (2 required), insufficient for high (3 required).
    Proof strategy: native_decide -/
theorem cc5b_subagent_manual_satisfies_moderate :
  satisfiedConditions ccSubagentManualInvoked ≥ requiredConditions .moderate ∧
  satisfiedConditions ccSubagentManualInvoked < requiredConditions .high := by
  constructor <;> native_decide

/-- [Derivation Card]
    Derives from: requiredConditions (D2), ccSubagentHookInvoked
    Proposition: CC6
    Content: Even hook-invoked subagent is insufficient for critical risk.
      evaluatorIndependent=false means human review is required for L1 changes.
    Proof strategy: native_decide -/
theorem cc6_subagent_insufficient_critical :
  satisfiedConditions ccSubagentHookInvoked < requiredConditions .critical := by
  native_decide

-- ============================================================
-- D11 マッピング: コンテキストコスト
-- ============================================================

/-- Context cost of each Claude Code primitive.
    Higher value = more context consumption per session.
    Hooks have 0 cost (not loaded into context window).
    Rules have medium cost (loaded but smaller than CLAUDE.md).
    CLAUDE.md has highest cost (always loaded, largest file).
    D11: enforcement layer strength and context cost are inversely correlated. -/
def ccContextCost : CCPrimitive → Nat
  | .hook _     => 0   -- ハーネスレベル実行、コンテキスト消費なし
  | .permission => 0   -- settings.json はコンテキストに読み込まれない
  | .sandbox    => 0   -- OS レベル、コンテキスト消費なし
  | .skill      => 1   -- 起動時のみ読み込み
  | .agent      => 1   -- 起動時のみ読み込み
  | .mcpServer  => 1   -- ツール定義のみ
  | .rule       => 2   -- 毎セッション読み込み
  | .claudeMd   => 3   -- 毎セッション読み込み、最大サイズ

/-- [Derivation Card]
    Derives from: ccContextCost, ccEnforcementLayer
    Proposition: CC7
    Content: D11 inverse correlation holds for Claude Code:
      structural enforcement (hook) has lowest context cost (0),
      normative guideline (CLAUDE.md) has highest context cost (3).
    Proof strategy: rfl for both sides of the conjunction -/
theorem cc7_context_cost_inverse_correlation :
  ccContextCost (.hook .preToolUse) < ccContextCost .claudeMd ∧
  ccEnforcementLayer (.hook .preToolUse) = .structural ∧
  ccEnforcementLayer .claudeMd = .normative := by
  refine ⟨?_, ?_, ?_⟩ <;> simp [ccContextCost, ccEnforcementLayer]

-- ============================================================
-- D10 マッピング: T1/T2 分類
-- ============================================================

/-- T1 (ephemeral) or T2 (persistent) classification of CC primitives.
    T2 primitives survive across sessions; T1 primitives do not.
    D10: improvements accumulate only through T2 primitives. -/
def ccPersistence : CCPrimitive → Bool
  | .hook _     => true   -- settings.json に定義、セッション跨ぎ
  | .permission => true   -- settings.json に定義
  | .sandbox    => true   -- settings.json に定義
  | .rule       => true   -- .claude/rules/ ファイル
  | .skill      => true   -- .claude/skills/ ファイル
  | .claudeMd   => true   -- CLAUDE.md ファイル
  | .mcpServer  => true   -- 設定ファイルに定義
  | .agent      => false  -- Agent インスタンスはセッション内で消滅

/-- [Derivation Card]
    Derives from: ccPersistence, d10_agent_temporary_structure_permanent (D10)
    Proposition: CC8
    Content: Agent is the only T1 (ephemeral) CC primitive.
      All other primitives persist across sessions (T2).
      This is consistent with D10: agent instances are temporary,
      but the structures they produce (skills, rules, hooks) are permanent.
    Proof strategy: decide on each constructor -/
theorem cc8_only_agent_ephemeral :
  ccPersistence .agent = false ∧
  ccPersistence (.hook .preToolUse) = true ∧
  ccPersistence .rule = true ∧
  ccPersistence .skill = true ∧
  ccPersistence .claudeMd = true := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> rfl

-- ============================================================
-- カバレッジ: D1-D14 → CC マッピングの存在
-- ============================================================

/-- Design principles that have direct CC primitive mappings.
    D1, D2, D3, D4, D5, D10, D11, D13 have direct mappings.
    D6-D9, D12, D14 are methodological — CC primitives do not obstruct them
    but do not directly implement them either. -/
def hasCCMapping : DesignPrinciple → Bool
  | .d1_enforcementLayering            => true  -- ccEnforcementLayer
  | .d2_workerVerifierSeparation       => true  -- ccSubagentIndependence
  | .d3_observabilityFirst             => true  -- PostToolUse hooks for P4
  | .d4_progressiveSelfApplication     => true  -- hook layering = phase ordering
  | .d5_specTestImpl                   => true  -- Lean spec → test → skill/hook
  | .d10_structuralPermanence          => true  -- ccPersistence
  | .d11_contextEconomy                => true  -- ccContextCost
  | .d13_premiseNegationPropagation    => true  -- dependency tracking via git + /trace
  | .d6_boundaryMitigationVariable     => false -- methodological
  | .d7_trustAsymmetry                 => false -- methodological
  | .d8_equilibriumSearch              => false -- methodological
  | .d9_selfMaintenance                => false -- methodological
  | .d12_constraintSatisfactionTaskDesign => false -- methodological
  | .d14_verificationOrderConstraint   => false -- methodological
  | .d15_harnessEngineering            => false -- methodological (platform-specific patterns)
  | .d16_informationRelevance          => false -- methodological (context composition strategy)
  | .d17_deductiveDesignWorkflow       => false -- meta-level (design process itself)
  | .d18_multiAgentCoordination        => true  -- Agent tool + Agent Teams

/-- All 16 design principles enumerated. -/
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
    Derives from: hasCCMapping, allDesignPrinciples
    Proposition: CC-coverage
    Content: At least 8 of 16 design principles have direct CC primitive mappings.
      The remaining 8 are methodological principles that CC primitives do not obstruct.
    Proof strategy: native_decide on the filtered list of all 16 principles -/
theorem cc_coverage_at_least_half :
  (allDesignPrinciples.filter hasCCMapping).length ≥ 8 := by
  native_decide

end Manifest.Models.Instances.ClaudeCode

import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.ConditionalDesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions

/-!
# Managed Agents ギャップ分析 — 条件付き公理系拡張

Claude Managed Agents (2026-04) の技術調査に基づく条件付き公理系の拡張。
ConditionalDesignFoundation.lean の conservative extension。

## 位置づけ

```
DesignFoundation.lean (EnforcementLayer, D1-D18)
  ↓
ConditionalDesignFoundation.lean (CCPrimitive → EnforcementLayer)
  ↓ conservative extension
ManagedAgentsGapAnalysis.lean (SessionDurability, IsolationDimension, InterceptionCapability)
```

## 追加される概念

- SessionDurability: セッション永続性レベル（ephemeral/journaled/durable）
- IsolationDimension: sandbox の次元分解（filesystem/network/process/credential）
  - credential は OS 隔離ではなく認証管理の概念。他の3次元（OS レベル隔離）とは
    カテゴリが異なるが、L1 の脅威モデル上は同一プロファイルで管理する実用的理由がある
- IsolationProfile: 各次元の EnforcementLayer 割当て
- HarnessArchitecture: Harness/実行の結合度
- AutonomyLevel: 自律実行レベル
- InterceptionCapability: ランタイムインターセプション能力（CC > MA の次元）

## conservative extension の保証

既存の CCPrimitive, ccEnforcementLayer, cc1-cc8 定理に一切変更なし。
新規 inductive + def + theorem の追加のみ。

## 設計判断と論理的必然の区別

このファイルの定義関数（harnessMinSession, autonomyMinSession）は
**最小要件**（十分条件の下界）を定式化する。実際の運用ではこれ以下の
SessionDurability でも特定条件下で動作しうる。これらは設計判断であり、
数学的必然ではない。

## 一次ソースの制約

Managed Agents の具体的な隔離技術（gVisor, Firecracker 等）は公式に非公開。
Engineering blog は "isolated containers" とのみ記述。本形式化では
公式ドキュメントで確認可能な範囲のみを structural と分類し、
非公開の実装詳細に依存する分類は避ける。

## 参照 Issue

#311: Claude Managed Agents ギャップ分析
#312: G1 Session Durability
#313: G2 Isolation Dimensions
#314: G3 Harness Architecture + Autonomy
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest

-- ============================================================
-- Session Durability: セッション永続性レベル (#312)
-- ============================================================

/-- [Derivation Card]
    Derives from: T1 (temporary instance), T2 (persistent structure)
    Proposition: SD-type
    Content: Session durability level classifies cross-session recovery guarantees.
      ephemeral: no recovery. journaled: manual recovery via event log.
      durable: automatic crash recovery + positional event access.
      Note: in-session state is always maintained while the process runs;
      this type classifies *cross-session recovery*, not in-session behavior.
    Proof strategy: N/A (type definition) -/
inductive SessionDurability where
  | ephemeral
  | journaled
  | durable
  deriving BEq, Repr

/-- SessionDurability の強度順序。durable > journaled > ephemeral。 -/
def SessionDurability.strength : SessionDurability → Nat
  | .ephemeral => 0
  | .journaled => 1
  | .durable   => 2

/-- [Derivation Card]
    Derives from: D1 (EnforcementLayer), SD-type
    Proposition: SD-enforcement
    Content: Maps cross-session recovery guarantees to enforcement layers.
      ephemeral → normative (no cross-session recovery is enforced).
      journaled → procedural (log exists, recovery is manual — violation detectable).
      durable → structural (automatic recovery — session loss physically impossible).
      Caveat: ephemeral=normative refers to cross-session recovery only.
      In-session state is deterministic while the process runs.
    Proof strategy: pattern matching -/
def sessionEnforcement : SessionDurability → EnforcementLayer
  | .ephemeral => .normative
  | .journaled => .procedural
  | .durable   => .structural

/-- [Derivation Card]
    Derives from: sessionEnforcement, SessionDurability.strength, EnforcementLayer.strength
    Proposition: SD-monotone
    Content: sessionEnforcement preserves the strength ordering.
    Proof strategy: case analysis on all SessionDurability values -/
theorem session_enforcement_strength_monotone :
  ∀ (s t : SessionDurability),
    s.strength ≤ t.strength →
    (sessionEnforcement s).strength ≤ (sessionEnforcement t).strength := by
  intro s t h
  cases s <;> cases t <;> simp [SessionDurability.strength, sessionEnforcement, EnforcementLayer.strength] at *

/-- [Derivation Card]
    Derives from: sessionEnforcement, SessionDurability.strength, EnforcementLayer.strength
    Proposition: SD-journaled-procedural
    Content: journaled or higher sessions have at least procedural enforcement.
    Proof strategy: case analysis, eliminating ephemeral by strength constraint -/
theorem session_journaled_at_least_procedural :
  ∀ (s : SessionDurability),
    s.strength ≥ SessionDurability.journaled.strength →
    (sessionEnforcement s).strength ≥ EnforcementLayer.procedural.strength := by
  intro s h
  cases s with
  | ephemeral => simp [SessionDurability.strength] at h
  | journaled => simp [sessionEnforcement, EnforcementLayer.strength]
  | durable => simp [sessionEnforcement, EnforcementLayer.strength]

/-- Claude Code のセッション永続性（現状）。
    Agent SDK は JSONL 保存 + resume by ID をサポート → journaled。
    自動クラッシュ回復はなし → durable ではない。
    Source: https://code.claude.com/docs/en/agent-sdk/sessions -/
def ccSessionDurability : SessionDurability := .journaled

/-- Managed Agents のセッション永続性。
    Append-only イベントログ + 自動クラッシュ回復 + 位置指定アクセス → durable。
    Source: https://www.anthropic.com/engineering/managed-agents
    Quote: "Because the session log sits outside the harness, nothing in the
    harness needs to survive a crash." -/
def managedAgentsSessionDurability : SessionDurability := .durable

/-- [Derivation Card]
    Derives from: ccSessionDurability, managedAgentsSessionDurability, SessionDurability.strength
    Proposition: SD-gap
    Content: CC session durability is strictly lower than Managed Agents.
    Proof strategy: simp on definitions -/
theorem session_durability_gap :
  ccSessionDurability.strength < managedAgentsSessionDurability.strength := by
  simp [ccSessionDurability, managedAgentsSessionDurability, SessionDurability.strength]

-- ============================================================
-- Isolation Dimensions: 隔離の次元分解 (#313)
-- ============================================================

/-- [Derivation Card]
    Derives from: L1 threat model (l1-safety.md), CCPrimitive.sandbox
    Proposition: ID-type
    Content: Independent dimensions of what a sandbox isolates.
      filesystem/network/process are OS-level resource isolation (kernel namespaces, seccomp).
      credential is access control policy (secret lifecycle management).
      credential differs in category from the OS-level dimensions but is included
      in the same type for practical L1 threat model coverage.
      Note: process is itself a composite (seccomp, capabilities, namespaces, user remapping).
      Memory/IPC isolation are omitted (relevant to L3 resource boundary, not L1 safety).
    Proof strategy: N/A (type definition) -/
inductive IsolationDimension where
  | filesystem   -- FS read/write アクセス制御
  | network      -- outbound ネットワークアクセス制御
  | process      -- syscall/capability 制御（seccomp + cap drop + namespace の複合）
  | credential   -- 認証情報の注入・隔離（OS 隔離ではなくアクセス制御ポリシー）
  deriving BEq, Repr, DecidableEq

/-- 各隔離次元に EnforcementLayer を割り当てるプロファイル。
    プラットフォーム固有のマッピングで具体化される。 -/
def IsolationProfile := IsolationDimension → EnforcementLayer

/-- [Derivation Card]
    Derives from: L1 threat model (l1-safety.md: test tampering, secret non-commitment,
      secret non-exfiltration via unintended paths)
    Proposition: ID-l1-required
    Content: Minimum isolation dimensions required for L1 structural guarantee.
      filesystem: test tampering prevention, secret file protection.
      network: prevents secret exfiltration via outbound connections.
      credential: prevents credential leakage through agent context.
    Proof strategy: N/A (definition derived from L1 threat analysis) -/
def l1RequiredDimensions : List IsolationDimension :=
  [.filesystem, .network, .credential]

/-- 全隔離次元。 -/
def allIsolationDimensions : List IsolationDimension :=
  [.filesystem, .network, .process, .credential]

-- ============================================================
-- プラットフォーム別 IsolationProfile
-- ============================================================

/-- [Derivation Card]
    Derives from: Claude Code sandbox documentation (https://code.claude.com/docs/en/sandboxing)
    Proposition: IP-cc-sandbox
    Content: Claude Code sandbox enabled profile.
      filesystem: structural (Seatbelt on macOS / bubblewrap on Linux — kernel-level).
      network: procedural (proxy + allowlist, but dangerouslyDisableSandbox escape hatch
        exists by default, and domain fronting bypasses are documented).
      process: normative (no syscall filtering in sandbox alone).
      credential: procedural (deny rules partially protect, bypassable per CC-H3).
    Proof strategy: N/A (definition from platform documentation) -/
def ccSandboxProfile : IsolationProfile
  | .filesystem  => .structural   -- Seatbelt/bwrap: kernel-level, no escape hatch for FS
  | .network     => .procedural   -- proxy + allowlist, but dangerouslyDisableSandbox escape
                                    -- hatch exists (triggers normal permissions flow — user
                                    -- approval required, not a free bypass; disableable via
                                    -- allowUnsandboxedCommands=false)
  | .process     => .normative    -- no syscall filtering in sandbox alone
  | .credential  => .procedural   -- deny rules, bypassable per CC-H3

/-- Claude Code sandbox 無効時の隔離プロファイル。
    全次元 normative（hook の grep パターンのみ）。 -/
def ccNoSandboxProfile : IsolationProfile
  | _ => .normative

/-- [Derivation Card]
    Derives from: Docker security documentation (seccomp, capabilities, namespaces)
    Proposition: IP-docker-hardened
    Content: Agent SDK in Docker hardened configuration.
      docker run --cap-drop ALL --security-opt no-new-privileges
      --security-opt seccomp=profile --read-only --network none
      Note: Docker seccomp is kernel-level syscall filtering. --network none
      removes all network interfaces (no escape hatch unlike CC sandbox proxy).
    Proof strategy: N/A (definition from Docker documentation) -/
def ccDockerHardenedProfile : IsolationProfile
  | .filesystem  => .structural  -- --read-only + 明示的 tmpfs
  | .network     => .structural  -- --network none (kernel-level, no escape hatch)
  | .process     => .structural  -- --cap-drop ALL + seccomp profile
  | .credential  => .procedural  -- env var injection（プロセス内アクセス可能）

/-- [Derivation Card]
    Derives from: CC-C9 (MCP Vault credential isolation), IP-docker-hardened
    Proposition: IP-docker-vault
    Content: Docker + MCP Vault configuration. All dimensions structural.
      Caveat: structural classification means "violation requires circumventing
      an infrastructure mechanism", but the quality/assurance level differs
      between self-managed Docker+Vault and Anthropic-managed infrastructure.
      This profile achieves dimension-count parity, not assurance-level parity.
    Proof strategy: N/A (definition from CC-C9 + Docker docs) -/
def ccDockerVaultProfile : IsolationProfile
  | .filesystem  => .structural
  | .network     => .structural
  | .process     => .structural
  | .credential  => .structural  -- MCP proxy + HashiCorp Vault

/-- [Derivation Card]
    Derives from: Managed Agents API documentation
      (https://platform.claude.com/docs/en/managed-agents/environments)
    Proposition: IP-ma-limited
    Content: Managed Agents with `limited` networking configuration.
      filesystem: structural (per-session isolated container).
      network: structural (limited mode with explicit allowed_hosts).
      process: procedural (containers are isolated but specific isolation technology
        — gVisor, Firecracker, etc. — is not publicly documented. Classified as
        procedural rather than structural due to lack of verifiable documentation).
      credential: structural (Vault with MCP proxy, credentials never reach sandbox.
        Source: engineering blog "OAuth tokens stored in external vault").
    Proof strategy: N/A (definition from Managed Agents documentation) -/
def managedAgentsLimitedProfile : IsolationProfile
  | .filesystem  => .structural   -- per-session isolated container
  | .network     => .structural   -- limited + allowed_hosts
  | .process     => .procedural   -- isolation exists but technology undocumented
  | .credential  => .structural   -- Vault + MCP proxy

/-- [Derivation Card]
    Derives from: Managed Agents API documentation
      (https://platform.claude.com/docs/en/managed-agents/environments)
    Proposition: IP-ma-default
    Content: Managed Agents with default (`unrestricted`) networking.
      filesystem: structural (per-session isolated container).
      network: normative (unrestricted mode allows all outbound traffic except safety blocklist).
      process: procedural (same as limited — technology undocumented).
      credential: structural (Vault with MCP proxy).
      IMPORTANT: This is the default configuration. Users must explicitly set
      `networking.type: "limited"` to achieve structural network isolation.
    Proof strategy: N/A (definition from Managed Agents documentation) -/
def managedAgentsDefaultProfile : IsolationProfile
  | .filesystem  => .structural   -- per-session isolated container
  | .network     => .normative    -- unrestricted: all outbound allowed
  | .process     => .procedural   -- isolation exists but technology undocumented
  | .credential  => .structural   -- Vault + MCP proxy

-- ============================================================
-- 隔離に関する定理
-- ============================================================

/-- [Derivation Card]
    Derives from: ccSandboxProfile (IP-cc-sandbox), l1RequiredDimensions (ID-l1-required)
    Proposition: ID-sandbox-partial
    Content: CC sandbox: filesystem=structural, network=procedural, credential=procedural.
      network is procedural (not structural) because:
      (1) dangerouslyDisableSandbox escape hatch exists (agent-triggered, but requires
          user approval via normal permissions flow; disableable via allowUnsandboxedCommands=false)
      (2) domain fronting bypasses are documented
      credential is procedural because deny rules are bypassable (CC-H3).
    Proof strategy: constructor with rfl and simp -/
theorem cc_sandbox_partial_l1 :
  ccSandboxProfile .filesystem = .structural ∧
  ccSandboxProfile .network = .procedural ∧
  ccSandboxProfile .credential ≠ .structural := by
  refine ⟨rfl, rfl, ?_⟩
  simp [ccSandboxProfile]

/-- [Derivation Card]
    Derives from: ccDockerVaultProfile (IP-docker-vault), l1RequiredDimensions (ID-l1-required)
    Proposition: ID-docker-vault-l1
    Content: Docker + Vault satisfies all L1 required dimensions.
      Note: proves dimension-level structural, not assurance-level equivalence.
    Proof strategy: intro + simp on l1RequiredDimensions membership, then case split -/
theorem cc_docker_vault_satisfies_l1 :
  ∀ d ∈ l1RequiredDimensions,
    ccDockerVaultProfile d = .structural := by
  intro d hd
  simp [l1RequiredDimensions] at hd
  rcases hd with rfl | rfl | rfl <;> simp [ccDockerVaultProfile]

/-- [Derivation Card]
    Derives from: managedAgentsLimitedProfile (IP-ma-limited)
    Proposition: ID-ma-limited-l1
    Content: Managed Agents (limited networking) satisfies all L1 required dimensions.
    Proof strategy: intro + simp + case split -/
theorem managed_agents_limited_satisfies_l1 :
  ∀ d ∈ l1RequiredDimensions,
    managedAgentsLimitedProfile d = .structural := by
  intro d hd
  simp [l1RequiredDimensions] at hd
  rcases hd with rfl | rfl | rfl <;> simp [managedAgentsLimitedProfile]

/-- [Derivation Card]
    Derives from: managedAgentsDefaultProfile (IP-ma-default), l1RequiredDimensions
    Proposition: ID-ma-default-below-l1
    Content: Managed Agents with DEFAULT networking does not meet this project's
      L1 structural requirement on the network dimension.
      This is a classification gap relative to agent-manifesto's L1 standard,
      not a security vulnerability in Managed Agents. MA's default (unrestricted)
      is designed for development convenience; production use recommends `limited`.
    Proof strategy: intro + instantiate network + contradiction -/
theorem managed_agents_default_below_l1_structural :
  ¬(∀ d ∈ l1RequiredDimensions,
    managedAgentsDefaultProfile d = .structural) := by
  intro h
  have := h .network (by simp [l1RequiredDimensions])
  simp [managedAgentsDefaultProfile] at this

/-- [Derivation Card]
    Derives from: ccNoSandboxProfile, l1RequiredDimensions (ID-l1-required)
    Proposition: ID-no-sandbox-fails
    Content: Without sandbox, L1 structural requirements cannot be met.
    Proof strategy: intro + instantiate filesystem + contradiction -/
theorem cc_no_sandbox_violates_l1 :
  ¬(∀ d ∈ l1RequiredDimensions,
    ccNoSandboxProfile d = .structural) := by
  intro h
  have := h .filesystem (by simp [l1RequiredDimensions])
  simp [ccNoSandboxProfile] at this

/-- [Derivation Card]
    Derives from: ccDockerHardenedProfile (IP-docker-hardened), allIsolationDimensions
    Proposition: ID-docker-3of4
    Content: Docker hardened achieves structural on 3 of 4 dimensions.
    Proof strategy: native_decide -/
theorem cc_docker_hardened_structural_count :
  (allIsolationDimensions.filter (fun d => ccDockerHardenedProfile d == .structural)).length = 3 := by
  native_decide

/-- [Derivation Card]
    Derives from: ccSandboxProfile, managedAgentsLimitedProfile
    Proposition: ID-gap
    Content: CC sandbox has fewer structural dimensions than MA limited.
      CC sandbox: 1 structural (filesystem only — network downgraded to procedural).
      MA limited: 3 structural (filesystem, network, credential).
    Proof strategy: native_decide -/
theorem isolation_gap_cc_vs_managed :
  (allIsolationDimensions.filter (fun d => ccSandboxProfile d == .structural)).length <
  (allIsolationDimensions.filter (fun d => managedAgentsLimitedProfile d == .structural)).length := by
  native_decide

-- ============================================================
-- Harness Architecture: Harness/実行の結合度 (#314)
-- ============================================================

/-- [Derivation Card]
    Derives from: Managed Agents engineering blog
      (https://www.anthropic.com/engineering/managed-agents)
    Proposition: HA-type
    Content: Coupling level between orchestration loop and execution environment.
      coupled: same process (Claude Code default).
      decoupled: stateless harness delegates via session log (Managed Agents).
    Proof strategy: N/A (type definition) -/
inductive HarnessArchitecture where
  | coupled
  | decoupled
  deriving BEq, Repr

/-- [Derivation Card]
    Derives from: HA-type, SD-type
    Proposition: HA-min-session
    Content: Minimum session durability for each harness architecture.
      coupled: ephemeral suffices.
      decoupled: journaled suffices (manual resume-by-ID).
    Proof strategy: N/A (definition — design judgment) -/
def harnessMinSession : HarnessArchitecture → SessionDurability
  | .coupled   => .ephemeral
  | .decoupled => .journaled

/-- [Derivation Card]
    Derives from: harnessMinSession (HA-min-session)
    Proposition: HA-decoupled-journaled
    Content: Decoupled harness minimally requires journaled session durability.
    Proof strategy: rfl -/
theorem decoupled_min_journaled :
  harnessMinSession .decoupled = .journaled := by rfl

def ccHarnessArchitecture : HarnessArchitecture := .coupled
def managedAgentsHarnessArchitecture : HarnessArchitecture := .decoupled

/-- [Derivation Card]
    Derives from: ccHarnessArchitecture, managedAgentsHarnessArchitecture, harnessMinSession
    Proposition: HA-gap
    Content: Architectural gap in minimum session requirements.
    Proof strategy: simp on definitions -/
theorem harness_architecture_gap :
  (harnessMinSession ccHarnessArchitecture).strength <
  (harnessMinSession managedAgentsHarnessArchitecture).strength := by
  simp [ccHarnessArchitecture, managedAgentsHarnessArchitecture,
        harnessMinSession, SessionDurability.strength]

-- ============================================================
-- Autonomy Level: 自律実行レベル (#314)
-- ============================================================

/-- [Derivation Card]
    Derives from: T6 (human final decision authority)
    Proposition: AL-type
    Content: Agent autonomy level with T6 compatibility conditions.
    Proof strategy: N/A (type definition) -/
inductive AutonomyLevel where
  | supervised
  | preApproved
  | autonomous
  deriving BEq, Repr

/-- [Derivation Card]
    Derives from: AL-type, SD-type, T6
    Proposition: AL-min-session
    Content: Minimum session durability for T6-compatible operation.
      autonomous: journaled suffices (durable is reliability enhancement, not T6 minimum).
    Proof strategy: N/A (definition — design judgment) -/
def autonomyMinSession : AutonomyLevel → SessionDurability
  | .supervised  => .ephemeral
  | .preApproved => .journaled
  | .autonomous  => .journaled

/-- [Derivation Card]
    Derives from: autonomyMinSession (AL-min-session)
    Proposition: AL-all-need-journaled
    Content: Both preApproved and autonomous require at least journaled sessions.
    Proof strategy: case analysis -/
theorem non_supervised_requires_journaled :
  ∀ (a : AutonomyLevel),
    a ≠ .supervised →
    (autonomyMinSession a).strength ≥ SessionDurability.journaled.strength := by
  intro a h
  cases a with
  | supervised => contradiction
  | preApproved => simp [autonomyMinSession, SessionDurability.strength]
  | autonomous => simp [autonomyMinSession, SessionDurability.strength]

/-- Claude Code の自律レベル（現状）。
    auto mode (CC-H7, Assumptions.lean) で preApproved に到達可能。
    デフォルトは supervised（全ツール確認）。preApproved は設定後の状態。 -/
def ccAutonomyLevel : AutonomyLevel := .preApproved

def managedAgentsAutonomyLevel : AutonomyLevel := .autonomous

-- ============================================================
-- Interception Capability: ランタイムインターセプション能力 (R3-H2)
-- ============================================================

/-- [Derivation Card]
    Derives from: Agent SDK hooks documentation (https://code.claude.com/docs/en/agent-sdk/hooks),
      Managed Agents permission policies (https://platform.claude.com/docs/en/managed-agents/permission-policies)
    Proposition: IC-type
    Content: Runtime interception capability — ability to block/modify tool calls at runtime.
      Four levels reflecting increasing control:
      - none: read-only access (getEvents API). No runtime influence on tool execution.
      - staticPolicy: always_allow policy decided at agent creation time. No runtime check.
      - dynamicConfirmation: always_ask policy. Session pauses mid-execution
        (stop_reason: requires_action), external application sends user.tool_confirmation
        with allow/deny + deny_message. The application can make context-dependent runtime
        decisions, but cannot modify tool inputs or inject context.
      - dynamicHook: PreToolUse hooks. Arbitrary code execution before tool call.
        Can block (deny), modify inputs (updatedInput), inject context (systemMessage).
    Proof strategy: N/A (type definition) -/
inductive InterceptionCapability where
  | none                  -- 読み取り専用（getEvents API）
  | staticPolicy          -- 静的ポリシー（always_allow、作成時に固定）
  | dynamicConfirmation   -- 動的確認（always_ask、ランタイム pause + 外部 allow/deny）
  | dynamicHook           -- 動的 hook（PreToolUse でブロック・修正・コンテキスト注入）
  deriving BEq, Repr

/-- InterceptionCapability の強度。dynamicHook が最強。
    dynamicConfirmation は dynamicHook より弱い（入力修正・コンテキスト注入が不可能）。 -/
def InterceptionCapability.strength : InterceptionCapability → Nat
  | .none                => 0
  | .staticPolicy        => 1
  | .dynamicConfirmation => 2
  | .dynamicHook         => 3

/-- [Derivation Card]
    Derives from: Agent SDK hooks docs (https://code.claude.com/docs/en/agent-sdk/hooks)
    Proposition: IC-cc
    Content: CC has dynamic hooks (PreToolUse can block/modify/inject).
    Proof strategy: N/A (definition) -/
def ccInterceptionCapability : InterceptionCapability := .dynamicHook

/-- [Derivation Card]
    Derives from: Managed Agents permission policies docs
      (https://platform.claude.com/docs/en/managed-agents/permission-policies)
    Proposition: IC-ma
    Content: MA has dynamicConfirmation via always_ask policy.
      The session pauses (stop_reason: requires_action) and waits for
      user.tool_confirmation from the controlling application.
      The application can make dynamic, context-dependent allow/deny decisions.
      However, it cannot modify tool inputs or inject context into the conversation
      (unlike CC's PreToolUse hooks which support updatedInput and systemMessage).
    Proof strategy: N/A (definition) -/
def managedAgentsInterceptionCapability : InterceptionCapability := .dynamicConfirmation

/-- [Derivation Card]
    Derives from: IC-cc, IC-ma, InterceptionCapability.strength
    Proposition: IC-cc-exceeds-ma
    Content: CC's interception capability exceeds Managed Agents by one level.
      CC: dynamicHook (block + modify inputs + inject context).
      MA: dynamicConfirmation (block only, no input modification or context injection).
      Both can block tool calls at runtime, but CC can additionally modify tool inputs
      and inject system messages — capabilities essential for L1 enforcement hooks,
      P4 observability (PostToolUse logging), and P2 verification (hook-invoked subagents).
    Proof strategy: simp on definitions -/
theorem cc_interception_exceeds_ma :
  ccInterceptionCapability.strength > managedAgentsInterceptionCapability.strength := by
  simp [ccInterceptionCapability, managedAgentsInterceptionCapability,
        InterceptionCapability.strength]

-- CC-C9 は Assumptions.lean に定義済み（MCP Vault による credential 隔離）。allAssumptions に登録。
-- CC-H7 は Assumptions.lean に定義済み（auto mode による自律レベル昇格）。

-- ============================================================
-- ギャップサマリ定理
-- ============================================================

/-- [Derivation Card]
    Derives from: SD-gap, ID-gap, HA-gap, IC-cc-exceeds-ma
    Proposition: GAP-summary
    Content: Bidirectional gaps between CC and Managed Agents.
      MA exceeds CC: session durability, isolation dimensions, harness architecture.
      CC exceeds MA: interception capability (dynamic hooks vs static policies).
      This bidirectional analysis avoids the confirmation bias of only formalizing
      MA advantages.
    Proof strategy: conjunction of four sub-proofs -/
theorem gaps_are_bidirectional :
  -- MA exceeds CC
  (ccSessionDurability.strength < managedAgentsSessionDurability.strength) ∧
  ((allIsolationDimensions.filter (fun d => ccSandboxProfile d == .structural)).length <
    (allIsolationDimensions.filter (fun d => managedAgentsLimitedProfile d == .structural)).length) ∧
  ((harnessMinSession ccHarnessArchitecture).strength <
    (harnessMinSession managedAgentsHarnessArchitecture).strength) ∧
  -- CC exceeds MA
  (ccInterceptionCapability.strength > managedAgentsInterceptionCapability.strength) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp [ccSessionDurability, managedAgentsSessionDurability, SessionDurability.strength]
  · native_decide
  · simp [ccHarnessArchitecture, managedAgentsHarnessArchitecture,
          harnessMinSession, SessionDurability.strength]
  · simp [ccInterceptionCapability, managedAgentsInterceptionCapability,
          InterceptionCapability.strength]

/-- [Derivation Card]
    Derives from: ccDockerVaultProfile (IP-docker-vault), managedAgentsLimitedProfile (IP-ma-limited)
    Proposition: GAP-dimension-count-parity
    Content: Docker + Vault achieves the same NUMBER of structural L1 dimensions
      as Managed Agents (limited). Both satisfy all 3 L1-required dimensions.
      CAVEAT: Dimension-count parity only. Self-managed infra differs in assurance
      from Anthropic-managed infra. Process isolation is structural (Docker) vs
      procedural (MA — undocumented technology).
    Proof strategy: native_decide -/
theorem docker_vault_l1_dimension_parity :
  (l1RequiredDimensions.filter (fun d => ccDockerVaultProfile d == .structural)).length =
  (l1RequiredDimensions.filter (fun d => managedAgentsLimitedProfile d == .structural)).length := by
  native_decide

end Manifest.Models.Instances.ClaudeCode

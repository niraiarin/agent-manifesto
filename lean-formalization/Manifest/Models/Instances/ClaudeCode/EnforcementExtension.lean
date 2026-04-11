import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.ConditionalDesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions

/-!
# Enforcement Model Extension - EnforcementExtension

ConditionalDesignFoundation.lean の conservative extension。
D1 EnforcementLayer を新しい次元（session, isolation, harness, autonomy, interception）に拡張する。

## 位置づけ

```
DesignFoundation.lean (EnforcementLayer, D1-D18)
  ↓
ConditionalDesignFoundation.lean (CCPrimitive → EnforcementLayer)
  ↓ conservative extension
EnforcementExtension.lean (新次元 → EnforcementLayer)
```

## 仮定への依存

このファイルの定義は Assumptions.lean の CC-C/H 仮定に依存する。
各定義の Derivation Card に依存する仮定 ID を明記する。
外部ドキュメントへの直接参照は行わず、仮定を経由する（TemporalValidity で追跡可能）。

## 設計判断と論理的必然の区別

harnessMinSession, autonomyMinSession は**最小要件**（十分条件の下界）を定式化する。
実際の運用ではこれ以下の SessionDurability でも動作しうる。
これらは設計判断であり数学的必然ではない。

## 参照 Issue

#311: Claude Managed Agents ギャップ分析
#336: /research skill 構造的欠陥（仮定接続の改善）
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest

-- ============================================================
-- Session Durability: セッション永続性レベル
-- ============================================================

/-- [Derivation Card]
    Derives from: T1 (temporary instance), T2 (persistent structure)
    Proposition: SD-type
    Content: Cross-session recovery guarantee level.
      ephemeral: no recovery. journaled: manual recovery. durable: automatic recovery.
      Classifies *cross-session recovery*, not in-session behavior.
    Proof strategy: N/A (type definition) -/
inductive SessionDurability where
  | ephemeral
  | journaled
  | durable
  deriving BEq, Repr

def SessionDurability.strength : SessionDurability → Nat
  | .ephemeral => 0
  | .journaled => 1
  | .durable   => 2

/-- [Derivation Card]
    Derives from: D1 (EnforcementLayer), SD-type
    Proposition: SD-enforcement
    Content: Maps cross-session recovery to enforcement layers.
      Caveat: ephemeral=normative refers to cross-session recovery only.
    Proof strategy: pattern matching -/
def sessionEnforcement : SessionDurability → EnforcementLayer
  | .ephemeral => .normative
  | .journaled => .procedural
  | .durable   => .structural

/-- [Derivation Card]
    Derives from: sessionEnforcement, SessionDurability.strength, EnforcementLayer.strength
    Proposition: SD-monotone
    Content: sessionEnforcement preserves strength ordering.
    Proof strategy: case analysis on all values -/
theorem session_enforcement_strength_monotone :
  ∀ (s t : SessionDurability),
    s.strength ≤ t.strength →
    (sessionEnforcement s).strength ≤ (sessionEnforcement t).strength := by
  intro s t h
  cases s <;> cases t <;> simp [SessionDurability.strength, sessionEnforcement, EnforcementLayer.strength] at *

/-- [Derivation Card]
    Derives from: sessionEnforcement, SessionDurability.strength, EnforcementLayer.strength
    Proposition: SD-journaled-procedural
    Content: journaled or higher → at least procedural enforcement.
    Proof strategy: case analysis -/
theorem session_journaled_at_least_procedural :
  ∀ (s : SessionDurability),
    s.strength ≥ SessionDurability.journaled.strength →
    (sessionEnforcement s).strength ≥ EnforcementLayer.procedural.strength := by
  intro s h
  cases s with
  | ephemeral => simp [SessionDurability.strength] at h
  | journaled => simp [sessionEnforcement, EnforcementLayer.strength]
  | durable => simp [sessionEnforcement, EnforcementLayer.strength]

/-- [Derivation Card]
    Derives from: CC-H8 (Agent SDK session = JSONL + resume by ID, no auto recovery)
    Proposition: SD-cc
    Content: CC session durability = journaled. -/
def ccSessionDurability : SessionDurability := .journaled

/-- [Derivation Card]
    Derives from: CC-H9 (MA session = append-only log + auto crash recovery + getEvents)
    Proposition: SD-ma
    Content: MA session durability = durable. -/
def managedAgentsSessionDurability : SessionDurability := .durable

/-- [Derivation Card]
    Derives from: SD-cc (CC-H8), SD-ma (CC-H9), SessionDurability.strength
    Proposition: SD-gap
    Content: CC < MA in session durability.
    Proof strategy: simp -/
theorem session_durability_gap :
  ccSessionDurability.strength < managedAgentsSessionDurability.strength := by
  simp [ccSessionDurability, managedAgentsSessionDurability, SessionDurability.strength]

-- ============================================================
-- Isolation Dimensions: 隔離の次元分解
-- ============================================================

/-- [Derivation Card]
    Derives from: L1 threat model (l1-safety.md), CCPrimitive.sandbox
    Proposition: ID-type
    Content: Independent dimensions of sandbox isolation.
      filesystem/network/process: OS-level (namespaces, seccomp).
      credential: access control policy (differs in category but included for L1 coverage).
      process is composite (seccomp + capabilities + namespaces).
      Memory/IPC omitted (L3 resource boundary, not L1).
    Proof strategy: N/A (type definition) -/
inductive IsolationDimension where
  | filesystem
  | network
  | process
  | credential
  deriving BEq, Repr, DecidableEq

def IsolationProfile := IsolationDimension → EnforcementLayer

/-- [Derivation Card]
    Derives from: L1 (Ontology.lean: ethics_safety_boundary), CC-C1 (L1 enforcement method)
    Proposition: ID-l1-required
    Content: L1 structural guarantee requires filesystem + network + credential.
      filesystem: L1 test tampering prohibition + secret file protection.
      network: L1 secret non-exfiltration via unintended paths.
      credential: L1 secret non-commitment + credential leakage prevention. -/
def l1RequiredDimensions : List IsolationDimension :=
  [.filesystem, .network, .credential]

def allIsolationDimensions : List IsolationDimension :=
  [.filesystem, .network, .process, .credential]

-- ============================================================
-- プラットフォーム別 IsolationProfile
-- ============================================================

/-- [Derivation Card]
    Derives from: CC-H10 (CC sandbox: FS=structural, network=procedural, process=normative, credential=procedural)
    Proposition: IP-cc-sandbox
    Content: CC sandbox enabled profile. See CC-H10 for detailed rationale. -/
def ccSandboxProfile : IsolationProfile
  | .filesystem  => .structural
  | .network     => .procedural
  | .process     => .normative
  | .credential  => .procedural

/-- [Derivation Card]
    Derives from: CC-H10 (sandbox disabled = no OS-level isolation)
    Proposition: IP-cc-no-sandbox
    Content: CC sandbox disabled. All dimensions normative (hook grep patterns only). -/
def ccNoSandboxProfile : IsolationProfile
  | _ => .normative

/-- [Derivation Card]
    Derives from: CC-H11 (Docker hardened: FS/network/process=structural, credential=procedural)
    Proposition: IP-docker-hardened
    Content: Agent SDK in Docker hardened. See CC-H11 for detailed rationale. -/
def ccDockerHardenedProfile : IsolationProfile
  | .filesystem  => .structural
  | .network     => .structural
  | .process     => .structural
  | .credential  => .procedural

/-- [Derivation Card]
    Derives from: CC-C9 (MCP Vault), CC-H11 (Docker hardened)
    Proposition: IP-docker-vault
    Content: Docker + MCP Vault. All dimensions structural.
      CAVEAT: dimension-count parity, not assurance-level parity.
      Self-managed Docker+Vault differs in assurance from Anthropic-managed infra. -/
def ccDockerVaultProfile : IsolationProfile
  | .filesystem  => .structural
  | .network     => .structural
  | .process     => .structural
  | .credential  => .structural

/-- [Derivation Card]
    Derives from: CC-H12 (MA limited: FS/network/credential=structural, process=procedural)
    Proposition: IP-ma-limited
    Content: MA with limited networking. See CC-H12 for detailed rationale.
      process=procedural because isolation technology is undocumented. -/
def managedAgentsLimitedProfile : IsolationProfile
  | .filesystem  => .structural
  | .network     => .structural
  | .process     => .procedural
  | .credential  => .structural

/-- [Derivation Card]
    Derives from: CC-H13 (MA default: unrestricted networking), CC-H12
    Proposition: IP-ma-default
    Content: MA with default (unrestricted) networking. network=normative.
      This is a classification gap vs L1, not a security vulnerability. -/
def managedAgentsDefaultProfile : IsolationProfile
  | .filesystem  => .structural
  | .network     => .normative
  | .process     => .procedural
  | .credential  => .structural

-- ============================================================
-- 隔離に関する定理
-- ============================================================

/-- [Derivation Card]
    Derives from: IP-cc-sandbox (CC-H10), ID-l1-required, CC-H3
    Proposition: ID-sandbox-partial
    Content: CC sandbox: FS=structural, network=procedural (CC-H10: escape hatch),
      credential≠structural (CC-H3: deny rules bypassable).
    Proof strategy: constructor + simp -/
theorem cc_sandbox_partial_l1 :
  ccSandboxProfile .filesystem = .structural ∧
  ccSandboxProfile .network = .procedural ∧
  ccSandboxProfile .credential ≠ .structural := by
  refine ⟨rfl, rfl, ?_⟩
  simp [ccSandboxProfile]

/-- [Derivation Card]
    Derives from: IP-docker-vault (CC-C9, CC-H11), ID-l1-required
    Proposition: ID-docker-vault-l1
    Content: Docker + Vault satisfies all L1 required dimensions.
    Proof strategy: intro + case split -/
theorem cc_docker_vault_satisfies_l1 :
  ∀ d ∈ l1RequiredDimensions,
    ccDockerVaultProfile d = .structural := by
  intro d hd
  simp [l1RequiredDimensions] at hd
  rcases hd with rfl | rfl | rfl <;> simp [ccDockerVaultProfile]

/-- [Derivation Card]
    Derives from: IP-ma-limited (CC-H12), ID-l1-required
    Proposition: ID-ma-limited-l1
    Content: MA limited satisfies all L1 required dimensions.
    Proof strategy: intro + case split -/
theorem managed_agents_limited_satisfies_l1 :
  ∀ d ∈ l1RequiredDimensions,
    managedAgentsLimitedProfile d = .structural := by
  intro d hd
  simp [l1RequiredDimensions] at hd
  rcases hd with rfl | rfl | rfl <;> simp [managedAgentsLimitedProfile]

/-- [Derivation Card]
    Derives from: IP-ma-default (CC-H13), ID-l1-required
    Proposition: ID-ma-default-below-l1
    Content: MA default does not meet this project's L1 structural requirement.
      Classification gap, not security vulnerability. Production recommends limited.
    Proof strategy: intro + instantiate network + contradiction -/
theorem managed_agents_default_below_l1_structural :
  ¬(∀ d ∈ l1RequiredDimensions,
    managedAgentsDefaultProfile d = .structural) := by
  intro h
  have := h .network (by simp [l1RequiredDimensions])
  simp [managedAgentsDefaultProfile] at this

/-- [Derivation Card]
    Derives from: ccNoSandboxProfile, ID-l1-required
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
    Derives from: IP-docker-hardened (CC-H11), allIsolationDimensions
    Proposition: ID-docker-3of4
    Content: Docker hardened = 3/4 structural.
    Proof strategy: native_decide -/
theorem cc_docker_hardened_structural_count :
  (allIsolationDimensions.filter (fun d => ccDockerHardenedProfile d == .structural)).length = 3 := by
  native_decide

/-- [Derivation Card]
    Derives from: IP-cc-sandbox (CC-H10), IP-ma-limited (CC-H12)
    Proposition: ID-gap
    Content: CC sandbox structural count < MA limited structural count.
    Proof strategy: native_decide -/
theorem isolation_gap_cc_vs_managed :
  (allIsolationDimensions.filter (fun d => ccSandboxProfile d == .structural)).length <
  (allIsolationDimensions.filter (fun d => managedAgentsLimitedProfile d == .structural)).length := by
  native_decide

-- ============================================================
-- Harness Architecture
-- ============================================================

/-- [Derivation Card]
    Derives from: CC-H14 (CC=coupled, MA=decoupled)
    Proposition: HA-type
    Content: Harness/execution coupling level. -/
inductive HarnessArchitecture where
  | coupled
  | decoupled
  deriving BEq, Repr

/-- [Derivation Card]
    Derives from: HA-type, SD-type
    Proposition: HA-min-session
    Content: Minimum session durability per harness architecture. Design judgment. -/
def harnessMinSession : HarnessArchitecture → SessionDurability
  | .coupled   => .ephemeral
  | .decoupled => .journaled

/-- [Derivation Card]
    Derives from: HA-min-session
    Proposition: HA-decoupled-journaled
    Proof strategy: rfl -/
theorem decoupled_min_journaled :
  harnessMinSession .decoupled = .journaled := by rfl

/-- [Derivation Card]
    Derives from: CC-H14 (CC=coupled)
    Proposition: HA-cc -/
def ccHarnessArchitecture : HarnessArchitecture := .coupled

/-- [Derivation Card]
    Derives from: CC-H14 (MA=decoupled)
    Proposition: HA-ma -/
def managedAgentsHarnessArchitecture : HarnessArchitecture := .decoupled

/-- [Derivation Card]
    Derives from: HA-cc (CC-H14), HA-ma (CC-H14), HA-min-session
    Proposition: HA-gap
    Content: Architectural gap in minimum session requirements.
    Proof strategy: simp -/
theorem harness_architecture_gap :
  (harnessMinSession ccHarnessArchitecture).strength <
  (harnessMinSession managedAgentsHarnessArchitecture).strength := by
  simp [ccHarnessArchitecture, managedAgentsHarnessArchitecture,
        harnessMinSession, SessionDurability.strength]

-- ============================================================
-- Autonomy Level
-- ============================================================

/-- [Derivation Card]
    Derives from: T6 (human final decision authority)
    Proposition: AL-type
    Content: Agent autonomy level with T6 compatibility. -/
inductive AutonomyLevel where
  | supervised
  | preApproved
  | autonomous
  deriving BEq, Repr

/-- [Derivation Card]
    Derives from: AL-type, SD-type, T6
    Proposition: AL-min-session
    Content: Minimum session durability for T6-compatible operation. Design judgment.
      autonomous = journaled (durable is reliability enhancement, not T6 minimum). -/
def autonomyMinSession : AutonomyLevel → SessionDurability
  | .supervised  => .ephemeral
  | .preApproved => .journaled
  | .autonomous  => .journaled

/-- [Derivation Card]
    Derives from: AL-min-session
    Proposition: AL-all-need-journaled
    Content: Non-supervised levels require at least journaled.
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

/-- [Derivation Card]
    Derives from: CC-C10 (human decision: use auto mode for preApproved), CC-H7
    Proposition: AL-cc -/
def ccAutonomyLevel : AutonomyLevel := .preApproved

/-- [Derivation Card]
    Derives from: CC-H9 (MA = durable session + post-audit)
    Proposition: AL-ma -/
def managedAgentsAutonomyLevel : AutonomyLevel := .autonomous

-- ============================================================
-- Interception Capability
-- ============================================================

/-- [Derivation Card]
    Derives from: CC-H15 (CC=dynamicHook, MA=dynamicConfirmation), CC-H1 (hooks are harness-enforced)
    Proposition: IC-type
    Content: Runtime interception capability. CC > MA on this dimension.
      none: read-only (getEvents). staticPolicy: always_allow (creation-time).
      dynamicConfirmation: always_ask (runtime pause + allow/deny, no input modification).
      dynamicHook: PreToolUse (block + modify inputs + inject context). -/
inductive InterceptionCapability where
  | none
  | staticPolicy
  | dynamicConfirmation
  | dynamicHook
  deriving BEq, Repr

def InterceptionCapability.strength : InterceptionCapability → Nat
  | .none                => 0
  | .staticPolicy        => 1
  | .dynamicConfirmation => 2
  | .dynamicHook         => 3

/-- [Derivation Card]
    Derives from: CC-H15 (CC PreToolUse = block/modify/inject)
    Proposition: IC-cc -/
def ccInterceptionCapability : InterceptionCapability := .dynamicHook

/-- [Derivation Card]
    Derives from: CC-H15 (MA always_ask = runtime pause + allow/deny only)
    Proposition: IC-ma -/
def managedAgentsInterceptionCapability : InterceptionCapability := .dynamicConfirmation

/-- [Derivation Card]
    Derives from: IC-cc (CC-H15), IC-ma (CC-H15), InterceptionCapability.strength
    Proposition: IC-cc-exceeds-ma
    Content: CC interception > MA. dynamicHook > dynamicConfirmation.
      CC can modify inputs + inject context; MA can only allow/deny.
    Proof strategy: simp -/
theorem cc_interception_exceeds_ma :
  ccInterceptionCapability.strength > managedAgentsInterceptionCapability.strength := by
  simp [ccInterceptionCapability, managedAgentsInterceptionCapability,
        InterceptionCapability.strength]

-- Assumptions: CC-C9, CC-C10, CC-H8〜H15 は Assumptions.lean に定義済み。
-- allAssumptions に全て登録済み。

-- ============================================================
-- ギャップサマリ
-- ============================================================

/-- [Derivation Card]
    Derives from: SD-gap (CC-H8, CC-H9), ID-gap (CC-H10, CC-H12),
      HA-gap (CC-H14), IC-cc-exceeds-ma (CC-H15)
    Proposition: GAP-bidirectional
    Content: Bidirectional gaps: MA > CC (session, isolation, harness) + CC > MA (interception).
    Proof strategy: conjunction of four sub-proofs -/
theorem gaps_are_bidirectional :
  (ccSessionDurability.strength < managedAgentsSessionDurability.strength) ∧
  ((allIsolationDimensions.filter (fun d => ccSandboxProfile d == .structural)).length <
    (allIsolationDimensions.filter (fun d => managedAgentsLimitedProfile d == .structural)).length) ∧
  ((harnessMinSession ccHarnessArchitecture).strength <
    (harnessMinSession managedAgentsHarnessArchitecture).strength) ∧
  (ccInterceptionCapability.strength > managedAgentsInterceptionCapability.strength) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp [ccSessionDurability, managedAgentsSessionDurability, SessionDurability.strength]
  · native_decide
  · simp [ccHarnessArchitecture, managedAgentsHarnessArchitecture,
          harnessMinSession, SessionDurability.strength]
  · simp [ccInterceptionCapability, managedAgentsInterceptionCapability,
          InterceptionCapability.strength]

/-- [Derivation Card]
    Derives from: IP-docker-vault (CC-C9, CC-H11), IP-ma-limited (CC-H12)
    Proposition: GAP-l1-dimension-parity
    Content: Docker+Vault = MA limited on L1 dimension count.
      CAVEAT: count parity only, not assurance parity.
    Proof strategy: native_decide -/
theorem docker_vault_l1_dimension_parity :
  (l1RequiredDimensions.filter (fun d => ccDockerVaultProfile d == .structural)).length =
  (l1RequiredDimensions.filter (fun d => managedAgentsLimitedProfile d == .structural)).length := by
  native_decide

end Manifest.Models.Instances.ClaudeCode

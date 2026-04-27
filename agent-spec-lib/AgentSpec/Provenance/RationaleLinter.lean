-- Provenance 層: RationaleLinter (Day 60、A-Standard A-Minimal 版、Day 14-18 RetirementLinter pattern 踏襲)
-- F1 Option C sprint 1/4: #check_unattributed_rationale command
-- Day 50/57 empirical で検出された attribution 欠損 (欠損率 100%、prod 23 sites) の構造的可視化機構
import Lean
import AgentSpec.Spine.Rationale

/-!
# AgentSpec.Provenance.RationaleLinter: `#check_unattributed_rationale` command (Day 60、F1 Option C sprint 1/4)

Phase 0 Week 4-5 Provenance 層の Day 60 構成要素。F1 Option C sprint 1 日目、
Day 14-22 RetirementLinter lineage を Rationale attribution に複製。

段階的成熟パス:
- Day 52 A-Minimal: `@[deprecated]` fixture (trivialDeprecated / ofTextUnauthoredDeprecated)
- **Day 60 A-Standard A-Minimal**: `#check_unattributed_rationale <ident>` command (本 module)
- Day 61: register_rationale_watched_namespace + SimplePersistentEnvExtension
- Day 62: `#check_unattributed_rationale_in_namespace` + `_auto` 変種
- Day 63: integration + 運用 register
- Week 5-6 A-Maximal: elaborator 型レベル強制

## 設計 (Day 18 RetirementLinterCommand pattern 踏襲)

    elab "#check_unattributed_rationale " id:ident : command => do
      let env ← getEnv
      let name ← ... realizeGlobalConstNoOverloadWithInfo
      -- 指定 decl の value body を取得、Rationale.trivial / ofText を refs から検出
      let unattributed : List Lean.Name :=
        [`AgentSpec.Spine.Rationale.trivial, `AgentSpec.Spine.Rationale.ofText]
      -- match on defnInfo.value の used constants
      ...

これにより:
- `#check_unattributed_rationale AgentSpec.Process.Hypothesis.trivial` → ⚠ uses Rationale.trivial
- `#check_unattributed_rationale AgentSpec.Provenance.RetiredEntity.trivial` → ⚠ uses Rationale.trivial
- `#check_unattributed_rationale <strict 化済 decl>` → ✓ no unattributed

## Day 14-18 RetirementLinter との関係

- Day 18 RetirementLinter: `@[deprecated]` **attribute** を `Lean.Linter.isDeprecated` で検査
- Day 60 RationaleLinter: **value body** を `getUsedConstants` で検査、blacklist 定数を検出

後者は value-level 検査のため、@[deprecated] pre-marking 不要 (既存全 decl を scan 可能)。
Day 52 fixture deprecated 路線の限界 (Day 57 empirical F1 で 0 warning) を根本解決。

## TyDD 原則 (Day 1-59 確立パターン適用)

- **Pattern #5**: elab command 定義、先行宣言
- **Pattern #6** (sorry 0): Elab API + Expr traversal のみで完結
- **Pattern #7**: artifact-manifest 同 commit
- **Pattern #8**: `#check_unattributed_rationale` は user-facing command、予約語ではない

## Day 60 意思決定ログ

### D1. value-level scanner (vs attribute-level、Day 52 fixture deprecated 路線の限界)
- **Day 52 路線**: `@[deprecated]` trivialDeprecated / ofTextUnauthoredDeprecated fixture
- **Day 57 empirical F1 finding**: prod 23 sites は既存 API (`Rationale.trivial` / `ofText`) を
  そのまま使用、warning 0 (fixture を呼ばないため)
- **Day 60 採用**: value-level scanner で decl body の Expr を traverse、blacklist
  定数 (Rationale.trivial / Rationale.ofText) 参照を検出
- **理由**: F1 structural 解決 (existing 23 sites を flag 可能)、Day 14 RetirementLinter の
  attribute-level より power 1 段上、Day 61-62 で namespace scan に拡張予定。

### D2. blacklist 2 定数のみで Day 60 minimal
- **採用**: `Rationale.trivial` / `Rationale.ofText` の 2 constant のみ blacklist
- **理由**: Day 50 empirical I2 で "attributed" 判定は `isProperlyAttributed = true` (text
  non-empty + references non-empty + confidence > 0 + author some + timestamp some)。
  逆の unattributed 候補 = (a) trivial (全 0) + (b) ofText (author/timestamp 未指定)。
  `mk'` / `withAuthor` / `withTimestamp` は caller が attribute を付与するので OK。
  `strict` は必須化 API なので OK。残 2 constant (trivial / ofText) のみ危険、blacklist。

### D3. Day 67 G1: deprecated decl の早期除外
- **採用**: 3 つの elab command で `Lean.Linter.isDeprecated env name` true の decl を
  blacklist 検査前に除外
- **理由**: Day 64 empirical G1 で Day 52 fixture (`trivialDeprecated` /
  `ofTextUnauthoredDeprecated`) が scanner に flag され semi-FP noise 化。
  fixture は migration 警告用途で production に呼ばれない設計、deprecated 全般を
  scanner blacklist 検査から除外する方が意図整合的 (migration 中の decl は
  warning が別チャネルで発火するため二重検出不要)。Day 14 RetirementLinter とは
  逆方向 (RetirementLinter は deprecated を検出する側、RationaleLinter は
  deprecated を除外する側) で意味的に補完。
-/

namespace AgentSpec.Provenance

open Lean Elab Command

/-- Day 60 A-Standard A-Minimal: `#check_unattributed_rationale <ident>` command。

    指定 declaration の value body を traverse し、`Rationale.trivial` / `Rationale.ofText`
    (attribution 欠損定数) への参照を検出、warning/info output を発生。

    利用例:
    - `#check_unattributed_rationale AgentSpec.Process.Hypothesis.trivial`
      → ⚠ uses Rationale.trivial (unattributed)
    - `#check_unattributed_rationale AgentSpec.Spine.Rationale.strict`
      → ✓ no unattributed Rationale refs
-/
elab "#check_unattributed_rationale " id:ident : command => do
  let env ← getEnv
  let name ← liftCoreM <| realizeGlobalConstNoOverloadWithInfo id
  if Lean.Linter.isDeprecated env name then
    -- Day 67 G1: deprecated decl は migration 移行中扱い、scanner blacklist 検査から除外
    logInfo m!"○ '{name}' is @[deprecated] (filtered, Day 67 G1)"
  else
    match env.find? name with
      | some (.defnInfo info) =>
        let used := info.value.getUsedConstants
        let blacklist : Array Lean.Name :=
          #[`AgentSpec.Spine.Rationale.trivial, `AgentSpec.Spine.Rationale.ofText]
        let hits := blacklist.filter (fun n => used.contains n)
        if hits.isEmpty then
          logInfo m!"✓ '{name}' has no unattributed Rationale refs"
        else
          logInfo m!"⚠ '{name}' uses unattributed: {hits}"
      | some _ =>
        logInfo m!"○ '{name}' is not a definition with body (axiom/opaque/inductive)"
      | none =>
        logInfo m!"? '{name}' declaration not found"

/-! ### Day 61 (F1 sprint 2/4): watched-namespace register + EnvExtension

Day 22 RetirementLinter の SimplePersistentEnvExtension pattern を Rationale に複製。
Day 61 では infrastructure 追加のみ、Day 62 で `#check_unattributed_rationale_in_namespace`
+ `_auto` 変種がこれを消費。
-/

/-- Day 61 F1 sprint 2/4: watched-namespace hardcode default。
    register で追加される前の initial list、agent-spec-lib の主要 namespace を網羅。 -/
def defaultWatchedRationaleNamespaces : List Name := [
  `AgentSpec.Process,
  `AgentSpec.Spine,
  `AgentSpec.Provenance
]

/-- Day 61 F1 sprint 2/4: env-driven watched-namespace extension
    (Day 22 watchedRetirementNamespacesExt pattern)。 -/
initialize watchedRationaleNamespacesExt :
    SimplePersistentEnvExtension Name (Array Name) ←
  registerSimplePersistentEnvExtension {
    addEntryFn := fun arr name => arr.push name
    addImportedFn := fun arrs => arrs.foldl (init := #[]) (· ++ ·)
  }

/-- Day 61 F1 sprint 2/4: env state から watched namespaces を取得。
    default hardcode ++ register 経由分の additive 連結。backward compatible。 -/
def getWatchedRationaleNamespaces (env : Environment) : List Name :=
  defaultWatchedRationaleNamespaces ++
    (watchedRationaleNamespacesExt.getState env).toList

/-- Day 61 F1 sprint 2/4: `register_rationale_watched_namespace <namespace>` command。
    指定 namespace を watched list に追加、Day 62 以降の `_in_namespace` / `_auto` で
    auto-target となる。

    利用例:
    - `register_rationale_watched_namespace AgentSpec.Test.MyModule`
      → 以降の `#check_unattributed_rationale_auto` で本 namespace も検査対象に追加

    Day 22 `register_retirement_namespace` と同 pattern (no `#`-prefix、declarative
    side-effect、query commands と semantic 区別)。 -/
elab "register_rationale_watched_namespace " id:ident : command => do
  let ns := id.getId
  modifyEnv fun env => watchedRationaleNamespacesExt.addEntry env ns
  logInfo m!"Registered rationale watched namespace: '{ns}'"

/-! ### Day 62 (F1 sprint 3/4): namespace scan + auto 変種 -/

/-- Day 62 F1 sprint 3/4: `#check_unattributed_rationale_in_namespace <namespace>` command。

    指定 namespace 配下の全 definitions を enumerate、各 decl の value body を scan し、
    blacklist (Rationale.trivial / ofText) 参照を持つものを列挙。

    Day 19 `#check_retired_in_namespace` pattern 踏襲、但し Day 60 RationaleLinter は
    value-level 検査 (Day 18 attribute-level とは異なる)。

    利用例:
    - `#check_unattributed_rationale_in_namespace AgentSpec.Process`
      → Process 層配下で Rationale.trivial / ofText を使う decl を全列挙
-/
elab "#check_unattributed_rationale_in_namespace " id:ident : command => do
  let env ← getEnv
  let ns := id.getId
  let blacklist : Array Lean.Name :=
    #[`AgentSpec.Spine.Rationale.trivial, `AgentSpec.Spine.Rationale.ofText]
  let mut unattributedNames : List (Name × Array Name) := []
  for (name, info) in env.constants.toList do
    if ns.isPrefixOf name && name != ns then
      -- Day 67 G1: deprecated decl は migration 移行中扱い、blacklist 検査から除外
      if Lean.Linter.isDeprecated env name then
        pure ()
      else
        match info with
          | .defnInfo defn =>
            let used := defn.value.getUsedConstants
            let hits := blacklist.filter (fun n => used.contains n)
            if !hits.isEmpty then
              unattributedNames := (name, hits) :: unattributedNames
          | _ => pure ()
  if unattributedNames.isEmpty then
    logInfo m!"Namespace '{ns}': no unattributed Rationale refs found"
  else
    let sorted := unattributedNames.reverse
    let mut msg := m!"Namespace '{ns}': {sorted.length} unattributed Rationale ref(s)"
    for (name, hits) in sorted do
      msg := msg ++ m!"\n  ⚠ '{name}' uses {hits}"
    logInfo msg

/-- Day 62 F1 sprint 3/4: `#check_unattributed_rationale_auto` command。

    Day 61 `getWatchedRationaleNamespaces` (default + registered) を auto-target として
    一括 scan、各 namespace の unattributed refs を info output。

    Day 21 `#check_retired_auto` pattern 踏襲、但し Rationale は value-level 検査。 -/
elab "#check_unattributed_rationale_auto" : command => do
  let env ← getEnv
  let watched := getWatchedRationaleNamespaces env
  let blacklist : Array Lean.Name :=
    #[`AgentSpec.Spine.Rationale.trivial, `AgentSpec.Spine.Rationale.ofText]
  -- Day 28 D16 pattern: presentation-layer dedup
  let watchedDedup := watched.eraseDups
  let mut totalCount : Nat := 0
  let mut msg := m!"#check_unattributed_rationale_auto: agent-spec-lib watched namespaces auto-check"
  for ns in watchedDedup do
    let mut unattributedInNs : List (Name × Array Name) := []
    for (name, info) in env.constants.toList do
      if ns.isPrefixOf name && name != ns then
        -- Day 67 G1: deprecated decl は migration 移行中扱い、blacklist 検査から除外
        if Lean.Linter.isDeprecated env name then
          pure ()
        else
          match info with
            | .defnInfo defn =>
              let used := defn.value.getUsedConstants
              let hits := blacklist.filter (fun n => used.contains n)
              if !hits.isEmpty then
                unattributedInNs := (name, hits) :: unattributedInNs
            | _ => pure ()
    msg := msg ++ m!"\n  '{ns}': {unattributedInNs.length} unattributed"
    totalCount := totalCount + unattributedInNs.length
  msg := msg ++ m!"\n  Total: {totalCount} unattributed Rationale ref(s) in {watchedDedup.length} watched namespaces"
  logInfo msg

end AgentSpec.Provenance

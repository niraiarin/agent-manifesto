-- Provenance 層: RetirementLinterCommand (Day 18、A-Standard custom linter A-Minimal)
-- Q1 A 案 + Q2 A-Minimal: Lean.Elab.Command 拡張で #check_retired command
-- Q3 案 A: 新 module 隔離 (Day 15 RetirementLinter.lean と並列、macro 系 vs command 系 semantic 分離)
import Lean
import AgentSpec.Provenance.RetiredEntity

/-!
# AgentSpec.Provenance.RetirementLinterCommand: `#check_retired` command (Day 18、A-Standard A-Minimal)

Phase 0 Week 4-5 Provenance 層の Day 18 構成要素。段階的 Lean 機能習得パス **3/4 段階目**
(Day 14 A-Minimal 標準 @[deprecated] → Day 15 A-Compact Hybrid macro → **Day 18 A-Standard
custom linter A-Minimal** → Week 5-6 A-Maximal elaborator 型レベル強制)。

Lean 4 `Lean.Elab.Command` + `Lean.Linter.isDeprecated` API 利用で `#check_retired <identifier>`
command を実装、指定 identifier が `@[deprecated]` 付き (Day 14 A-Minimal fixture 等、Day 15
`@[retired]` macro 展開後も含む) かを実行時検査、info output を発生。

## 設計 (Section 2.34 Q1-Q4 確定)

    elab "#check_retired " id:ident : command => do
      let env ← getEnv
      let name ← resolveGlobalConstNoOverloadWithInfo id
      if Lean.Linter.isDeprecated env name then
        logInfo m!"✓ '{name}' is retired (has @[deprecated] attribute)"
      else
        logInfo m!"✗ '{name}' is NOT retired (no @[deprecated] attribute)"

これにより利用側で以下が可能:

    -- Day 14 A-Minimal deprecated fixture を検査 (retired 判定):
    #check_retired RetiredEntity.obsoleteTrivialDeprecated
    -- Info: ✓ 'AgentSpec.Provenance.RetiredEntity.obsoleteTrivialDeprecated' is retired

    -- Day 12 通常 fixture を検査 (not retired 判定):
    #check_retired RetiredEntity.trivial
    -- Info: ✗ 'AgentSpec.Provenance.RetiredEntity.trivial' is NOT retired

## Day 14 / Day 15 との関係

- Day 14 A-Minimal: Lean 4 標準 `@[deprecated]` attribute (test fixture 4 variant)
- Day 15 A-Compact Hybrid macro: `@[retired msg since]` → `@[deprecated msg (since := since)]` 展開
- **Day 18 A-Standard A-Minimal**: `Lean.Elab.Command` で `#check_retired` command、検査 logic

Day 14 `@[deprecated]` / Day 15 `@[retired]` で付与された declaration を Day 18 `#check_retired`
で実行時検査可能 (Day 14-15 backward compatible、Day 18 で 3/4 段階目の linter 検査機能完備)。

## TyDD 原則 (Day 1-17 確立パターン適用)

- **Pattern #5** (def Prop signature): `elab` command 定義は command 先行宣言
- **Pattern #6** (sorry 0): command + Elab API のみで完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化 + Day 10 v2 拡張 + Day 17 十段階発展到達
- **Pattern #8** (Lean 4 予約語回避): `#check_retired` は user-facing command で予約語ではない

## Day 24 意思決定ログ (Role.toCtorIdx long-deferred root cause investigation 解消)

### D14. Role.toCtorIdx が retired 判定される root cause (Day 20-22 長期繰り延べ、Day 22 audit で long-deferred 化識別、Day 24 で解消)
- **背景**: Day 20 で `#check_retired_in_namespace_with_depth AgentSpec.Provenance 2` 実行時に `Role.toCtorIdx` が retired として検出、agent-spec-lib 側で `Role` (ResearchAgent.lean inductive) も auto-gen helpers も `@[deprecated]` を付けていないため謎現象として Day 20-22 繰り延げ (3 Day 連続)
- **investigation 方法**: temporary probe module (`RoleProbe.lean`、Day 24 で削除済) で `Lean.Linter.deprecatedAttr.getParam?` を各 auto-gen helper に適用、deprecation entry を direct 検査
- **investigation 結果**:
  1. `Role` 自身: isDeprecated = false ✓ (期待通り)
  2. `Role.rec` / `Role.casesOn` / `Role.noConfusion`: isDeprecated = false ✓
  3. `Role.toCtorIdx`: isDeprecated = **true** ❗ (deprecation entry: `since = "2025-08-25"`, `newName = Role.ctorIdx`)
  4. `Role.ctorIdx`: inEnv = true + isDeprecated = false ✓ (新名、deprecated ではない)
- **root cause 確定**: **Lean 4 4.29.0 upstream で `toCtorIdx` → `ctorIdx` rename** (2025-08-25)、backward compat のため旧名 `toCtorIdx` が `@[deprecated newName := ctorIdx]` として保持されている。agent-spec-lib 側の問題ではなく Lean 4 core の auto-gen helper naming change が原因。
- **対処**:
  1. 本 D14 docstring 追加で investigation 結果を production 化 (TyDD-S4 P5 explicit assumptions、Day 22 audit long-deferred 解消の記録)
  2. `ResearchAgent.lean` docstring に D3 (toCtorIdx rename 注記) 追加
  3. Test で `Role.ctorIdx` (新名) の type-level example 追加 (Role.toCtorIdx → Role.ctorIdx 移行パス実例)
  4. agent-spec-lib 本体 code は `Role.toCtorIdx` / `Role.ctorIdx` を直接参照していない (deriving DecidableEq の副産物のみ) ため、本質的 code 変更は不要
- **Day 22 audit long-deferred 累積警告の解消**: Day 20-22 = 3 Day 連続繰り延べだった「Role.toCtorIdx investigation」が Day 24 で解消 (Day 21 改訂 100 で解消した I3 = 4 セッション繰り延げ到達前に対処、long-deferred 化防止成功)
- **教訓**: Lean 4 core library の rename は backward-compat 付き deprecated alias として残るため、`Lean.Linter.isDeprecated` を使った scan は **Lean 4 upstream の rename も全て拾う** ことを明示化。将来 (Lean 4 upgrade 時) に他 auto-gen helper (`sizeOf` 等) が同パターンで rename されても同現象が発生し得ることを想定しておく。

## Day 23 意思決定ログ (multi-module import propagate test、Day 22 D10 PersistentEnvExtension addImportedFn 動作実証)

### D13. helper module 経由 multi-module import propagate test (Day 23 Q1 Day 22 Subagent informational I1 直接対処)
- **背景**: Day 22 で `SimplePersistentEnvExtension` + `register_retirement_namespace` 導入、Day 22 Subagent informational I1 で「multi-module duplicate handling は benign だが Day 23+ multi-module import test 推奨」と identified
- **代案 A**: production code に複数 `register_retirement_namespace` を散布 (実用的だが test 専用と production 用が混在)
- **代案 B**: test file 内で複数 helper module を inline (test cohesion 低下)
- **採用**: 新 helper module `AgentSpec/Test/Provenance/RetirementWatchedFixture.lean` (test scope 専用) で `register_retirement_namespace` + `@[retired]` decorated `importPropagateFixture` を定義、`AgentSpec.Test.Provenance.RetirementLinterCommandTest` が import で経由 propagate 確認
- **理由**: Day 22 D10 `addImportedFn := arrs.foldl (init := #[]) (· ++ ·)` の import 越境動作を実コードで実証、test cohesion 維持 (helper 専用 module + test 専用 fixture)、Day 22 backward compatible 完全維持 (本 helper module は test scope のみ、production code 変更なし)。本実証で Day 22 PersistentEnvExtension の implementation correctness を multi-module 構造で確認、Day 24+ で duplicate handling / multi-source register 等の進展に活用可能。

## Day 22 意思決定ログ (A-Standard-Full-Standard A-Minimal、PersistentEnvExtension callback)

### D10. PersistentEnvExtension で watched namespaces env-driven 化 (Day 22 Q1 A-Standard-Full-Standard)
- **代案**: Day 21 hardcode list を直接置換 (旧 list 削除 → breaking change)
- **代案 EnvExtension**: 非 persistent (module 越境せず、import 後消失)
- **採用**: `SimplePersistentEnvExtension Name (Array Name)` で env-driven 化、Day 21 hardcode list は `defaultWatchedRetirementNamespaces` として保持し additive 連結 (`hardcode ++ registered` で順序確定)
- **理由**: backward compatible 完全維持 (`#check_retired_auto` は register 不要で Day 21 同様に動作)、Lean 4 標準 API (Persistent...) で TyDD-S4 P4 power-to-weight、import 越境で extension 状態 propagate (Day 22+ で multi-module env-driven 連携基盤)。Day 22 minimal scope では `addEntryFn` / `addImportedFn` のみ実装、`statsFn` 等は省略 (Simple variant)。

### D11. `register_retirement_namespace <namespace>` command 提供 (Day 22 Q2 A-Minimal)
- **代案**: `#register_retirement_namespace` (`#`-prefix 慣習)
- **採用**: `register_retirement_namespace NS` (no `#` prefix、attribute 風 declarative DSL、`#`-prefix の query 用 commands と semantic 区別)
- **理由**: Day 18-21 `#check_retired*` は query (info output 専用)、Day 22 `register_retirement_namespace` は env mutation (declarative side-effect)、`#`-prefix なしで semantic 区別を明示。`elab "register_retirement_namespace " id:ident : command` で modifyEnv 経由 extension entry 追加。

### D12. env iteration を `env.constants.toList` (map₁ + map₂) に修正 (Day 22 同時改善、correctness fix)
- **背景**: Day 18-21 では `env.constants.map₁.toList` でイテレーションしていたが、これは imported declarations (`map₁`) のみで current-module declarations (`map₂`) を漏らしていた
- **影響**: Day 18-21 では imported namespaces (`AgentSpec.Provenance.RetiredEntity` 等) が対象だったため正常動作 (test fixture が imported 側にあった)
- **顕在化**: Day 22 register API テストで local namespace `AgentSpec.Test.Provenance.RetirementLinterCommand` を register し `day21LinkageFixture` (local @[retired]) を検出しようとした際、map₁ のみ iteration では検出できず判明
- **採用**: `env.constants.toList` (`SMap.toList = map₂.toList ++ map₁.toList` で両方 iterate)、Day 18-21 の 3 commands も同時修正 (correctness fix、output は Day 21 までと変化なし＝対象が imported のみだったため)
- **理由**: env-driven 拡張で local namespace を扱うために必須、TyDD-S4 P4 標準 API (`SMap.toList`)、performance は test scale で問題なし

## Day 21 意思決定ログ (A-Standard-Full A-Minimal、pre-defined namespace auto-target)

### D8. `#check_retired_auto` command 追加 (Day 21 Q1 A-Standard-Full A-Minimal、auto-target)
- **代案 A-Maximal**: `@[deprecated]` attribute 自体に callback 登録 (declaration 追加時 auto info)、Lean core 改造相当
- **代案 A-Standard-Full-Standard**: PersistentEnvExtension で declaration tracking + post-elaboration callback
- **採用 (Day 21 minimal)**: pre-defined namespace list (`agentSpecRetirementWatchedNamespaces`) を hardcode で auto-target する `#check_retired_auto` command 提供
- **理由**: Day 14-15-18-19-20 で確立した A-Minimal 段階的拡張パターン継続、Lean core 改造回避、Day 22+ で A-Standard-Full-Standard (PersistentEnvExtension) / Week 5-6 A-Maximal (elaborator 型レベル強制) へ段階的拡張パスを開ける。
  Day 18-20 の `#check_retired` / `#check_retired_in_namespace` / `#check_retired_in_namespace_with_depth` は手動 namespace 指定だったが、Day 21 `#check_retired_auto` は agent-spec-lib 内 watched namespaces (RetiredEntity / Failure / EvolutionStep) を auto-target する higher-order command。

### D9. watched namespaces を hardcode list で定義 (Day 21、A-Minimal scope)
- **代案**: Lean Environment 全体で `@[deprecated]` 付き declaration を全 enumerate
- **採用**: pre-defined hardcode list (`AgentSpec.Provenance.RetiredEntity` / `AgentSpec.Process.Failure` / `AgentSpec.Spine.EvolutionStep` の 3 namespaces)
- **理由**: A-Minimal scope (Day 21 1 day 完結)、agent-spec-lib 用途では本 3 namespaces で十分、Day 22+ で env-driven 拡張検討。

## Day 20 意思決定ログ (A-Compact nested namespace 再帰対応)

### D6. `#check_retired_in_namespace_with_depth NS N` command 追加 (Day 20 Q1 A-Compact、Day 19 Subagent I2 設計対応)
- **代案**: Day 19 syntax を変更して optional `(maxDepth := N)` 追加
- **採用**: 別 command 名 `#check_retired_in_namespace_with_depth NS N` で新規追加 (Day 19 syntax は backward compatible 維持)
- **理由**: Day 19 syntax の backward compatibility 完全維持、Day 20 で explicit depth-controlled 版を別 syntax で提供。
  Day 19 Subagent I2 で指摘された "NS 配下 any depth" の曖昧性を A-Compact で **explicit depth parameter** により狭義化、
  `(maxDepth := 1)` で NS 直下のみ、`(maxDepth := 2)` で NS.subNS まで等。
  depth 計算は `name.components.length - ns.components.length` で algebraic に定義。

### D7. depth 計算は components.length 差分 (Day 20)
- **代案**: 文字列 `.` の出現回数で計算
- **採用**: `Name.components.length` 差分 (algebraic、Lean 4 標準 API)
- **理由**: Lean 4 `Name` の component 構造 (anonymous / num / str) を直接活用、文字列パース不要、TyDD-S4 P4 power-to-weight (標準 API)。

## Day 19 意思決定ログ (A-Standard-Lite namespace 検出拡張)

### D4. `#check_retired_in_namespace` command 追加 (Day 19 Q1 A 案 + Q2 A-Minimal、Day 18 A-Minimal の自然な拡張)
- **代案 A-Compact**: nested namespace 再帰対応 (`NS.*` 全階層列挙)
- **代案 A-Maximal**: A-Compact + 退役 count + summary info (`N/M retired` 形式)
- **採用 (Day 19)**: 案 A-Minimal (NS 直下 constants のみ enumerate + 各 Lean.Linter.isDeprecated 検査)
- **理由**: Day 14-15-16-18 で確立した A-Minimal 段階的拡張パターン踏襲、1 日完結、
  Day 20+ で A-Compact (nested) / A-Maximal (summary) へ段階的拡張パスを開ける。
  `Environment.constants` 経由の enumeration + `Name.isPrefixOf` で NS 配下判定、
  標準 Lean 4 API 活用 (TyDD-S4 P4 power-to-weight 継続適用)。

### D5. Day 18 同 module に追加 (Q3 案 A、Day 18 + Day 19 同 command 系統)
- **代案 B**: 新 module `RetirementLinterNamespace.lean` 分離
- **採用**: 案 A Day 18 `RetirementLinterCommand.lean` MODIFY
- **理由**: `#check_retired` (Day 18) + `#check_retired_in_namespace` (Day 19) は同 command 系統、
  semantic 一貫性で統合が自然 (Day 15 macro 系 vs Day 18 command 系の semantic 分離とは異なる)、
  file 数維持で cohesion 高い。

## Day 18 意思決定ログ

### D1. Lean.Elab.Command 拡張で #check_retired command (Q1 A + Q2 A-Minimal)
- **代案 A-Standard-Lite**: namespace 検出 (`#check_retired_in_namespace NS`)、A-Minimal の拡張
- **代案 A-Standard-Full**: elaborator hook (command 実行時自動 linting、Day 19+ 領域)
- **採用**: A-Minimal (`#check_retired <ident>` simple command)
- **理由**: Day 1-17 リズム維持、Day 14-15-16 で確立した A-Minimal → A-Compact → A-Standard
  段階的拡張パターンを Day 18 でも踏襲、1 日完結、Day 19+ で A-Standard-Lite → A-Standard-Full
  → Week 5-6 A-Maximal elaborator への段階的拡張パスを開ける。新分野 (Elab.Command) 初回は
  minimal で学習 + 設計判断。

### D2. 新 module `RetirementLinterCommand.lean` (Q3 案 A)
- **代案 B**: Day 15 RetirementLinter.lean に追加 (macro + command 同 module)
- **代案 C**: test 内定義 (production code 変更なし、外部利用不可)
- **採用**: 案 A 新 module
- **理由**: Day 15 RetirementLinter.lean と並列配置、linter 専門化、Day 15 D2 案 B (新 module 隔離)
  同パターン踏襲、macro 系 vs command 系の semantic 分離維持。Day 19+ で A-Standard-Lite /
  A-Standard-Full 拡張時に同 module 継続利用可能。

### D3. `Lean.Linter.isDeprecated` API 利用
- **代案**: 自前で `deprecatedAttr.getParam?` 経由 implementation
- **採用**: 標準 `Lean.Linter.isDeprecated (env : Environment) (declName : Name) : Bool` を利用
- **理由**: Lean 4 core library 標準 API で semantic 保証、自前 implementation は Day 19+
  A-Standard-Full で検討 (elaborator hook 実装時に custom logic 必要になるため、Day 18 minimal
  では標準 API 利用が power-to-weight 最適)。
-/

namespace AgentSpec.Provenance

open Lean Elab Command

/-- Day 18 A-Standard custom linter A-Minimal: `#check_retired <identifier>` command。

    指定 identifier が `@[deprecated]` 付き (Day 14 A-Minimal fixture 等、Day 15 `@[retired]`
    macro 展開後も含む) かを `Lean.Linter.isDeprecated` で実行時検査、info output を発生。

    利用例:
    - `#check_retired RetiredEntity.obsoleteTrivialDeprecated` → ✓ is retired
    - `#check_retired RetiredEntity.trivial` → ✗ is NOT retired
 -/
elab "#check_retired " id:ident : command => do
  let env ← getEnv
  let name ← liftCoreM <| realizeGlobalConstNoOverloadWithInfo id
  if Lean.Linter.isDeprecated env name then
    logInfo m!"✓ '{name}' is retired (has @[deprecated] attribute)"
  else
    logInfo m!"✗ '{name}' is NOT retired (no @[deprecated] attribute)"

/-- Day 19 A-Standard-Lite: `#check_retired_in_namespace <namespace>` command。

    指定 namespace 配下 (any depth descendants) の全 constants を Environment 経由で
    enumerate、各 constant が `@[deprecated]` 付きかを `Lean.Linter.isDeprecated` で
    実行時検査、retired な constant を info output に列挙。

    **実装注意** (Day 19 Subagent I2 対処、改訂 92): `Name.isPrefixOf` は nested namespace
    も match するため、NS 配下 any depth descendants を列挙 (namespace 直下限定ではない)。
    A-Minimal scope では nested / 直下区別なし (test 対象 namespaces に nested retired なし)、
    Day 20+ A-Compact で nested namespace 再帰制御を明示的に追加予定。

    利用例:
    - `#check_retired_in_namespace AgentSpec.Provenance.RetiredEntity`
      → Day 14 deprecated fixture 4 variant が列挙される

    Day 18 A-Minimal (`#check_retired <identifier>` 単一検査) の自然な拡張 (Q1 A + Q2 A-Minimal)。
 -/
elab "#check_retired_in_namespace " id:ident : command => do
  let env ← getEnv
  let ns := id.getId
  let mut retiredNames : List Name := []
  for (name, _info) in env.constants.toList do
    if ns.isPrefixOf name && name != ns then
      if Lean.Linter.isDeprecated env name then
        retiredNames := name :: retiredNames
  if retiredNames.isEmpty then
    logInfo m!"Namespace '{ns}': no retired declarations found"
  else
    let sorted := retiredNames.reverse
    let mut msg := m!"Namespace '{ns}': {sorted.length} retired declaration(s)"
    for name in sorted do
      msg := msg ++ m!"\n  ✓ '{name}'"
    logInfo msg

/-- Day 20 A-Compact: `#check_retired_in_namespace_with_depth <namespace> <maxDepth>` command。

    Day 19 A-Standard-Lite (`#check_retired_in_namespace`) の自然な拡張。
    指定 namespace 配下の constants を **maxDepth レベルまで** enumerate (depth 制御)、
    各 constant が `@[deprecated]` 付きかを検査、retired を info output。

    depth 計算: `name.components.length - ns.components.length` (Lean 4 `Name.components` API、
    Day 20 D7 判断、algebraic で文字列パース不要)。

    利用例:
    - `#check_retired_in_namespace_with_depth AgentSpec.Provenance.RetiredEntity 1`
      → NS 直下のみ (depth=1) 検出
    - `#check_retired_in_namespace_with_depth AgentSpec.Provenance 2`
      → NS 配下 2 段階まで (NS.subNS まで) 検出

    Day 19 Subagent I2 設計対応 (Q1 A-Compact、Day 19 "NS 配下 any depth" を explicit
    depth parameter で狭義化)。Day 19 syntax (`#check_retired_in_namespace`) は backward
    compatible 維持 (Day 20 D6 判断、別 command 名で新規追加)。
 -/
elab "#check_retired_in_namespace_with_depth " id:ident maxDepth:num : command => do
  let env ← getEnv
  let ns := id.getId
  let max := maxDepth.getNat
  let nsComponents := ns.components.length
  let mut retiredNames : List Name := []
  for (name, _info) in env.constants.toList do
    if ns.isPrefixOf name && name != ns then
      let nameComponents := name.components.length
      let depthFromNs := nameComponents - nsComponents
      if depthFromNs ≤ max then
        if Lean.Linter.isDeprecated env name then
          retiredNames := name :: retiredNames
  if retiredNames.isEmpty then
    logInfo m!"Namespace '{ns}' (depth ≤ {max}): no retired declarations found"
  else
    let sorted := retiredNames.reverse
    let mut msg := m!"Namespace '{ns}' (depth ≤ {max}): {sorted.length} retired declaration(s)"
    for name in sorted do
      msg := msg ++ m!"\n  ✓ '{name}'"
    logInfo msg

/-- Day 21 A-Standard-Full A-Minimal (auto-target、Day 22 で env-driven 化): pre-defined
    watched namespaces hardcode list (Day 22 PersistentEnvExtension の initial / fallback seed)。

    `#check_retired_auto` (Day 21) と `getWatchedRetirementNamespaces` (Day 22) で利用。
    Day 22 register API 経由で追加された namespaces は本 list に additive 連結される。
 -/
def defaultWatchedRetirementNamespaces : List Name := [
  `AgentSpec.Provenance.RetiredEntity,
  `AgentSpec.Process.Failure,
  `AgentSpec.Spine.EvolutionStep
]

/-- Day 22 A-Standard-Full-Standard A-Minimal: watched retirement namespaces env-driven
    extension。`SimplePersistentEnvExtension Name (Array Name)` で declaration 追加時に
    `register_retirement_namespace` 経由で env 状態に追加、import 越境で propagate。

    Day 21 hardcode list (`defaultWatchedRetirementNamespaces`) は `getWatchedRetirementNamespaces`
    で additive 連結されるため backward compatible 完全維持 (Day 22 D10 判断)。
 -/
initialize watchedRetirementNamespacesExt :
    SimplePersistentEnvExtension Name (Array Name) ←
  registerSimplePersistentEnvExtension {
    addEntryFn := fun arr name => arr.push name
    addImportedFn := fun arrs => arrs.foldl (init := #[]) (· ++ ·)
  }

/-- Day 22 A-Standard-Full-Standard A-Minimal: env state から watched namespaces を取得。
    Day 21 hardcode (`defaultWatchedRetirementNamespaces`) ++ Day 22 register 経由分。
    backward compatible: register なしの場合 Day 21 動作と同一。
 -/
def getWatchedRetirementNamespaces (env : Environment) : List Name :=
  defaultWatchedRetirementNamespaces ++ (watchedRetirementNamespacesExt.getState env).toList

/-- Day 22 A-Standard-Full-Standard A-Minimal: `register_retirement_namespace <namespace>`
    command。指定 namespace を `watchedRetirementNamespacesExt` に追加 (env mutation)、
    以降の `#check_retired_auto` で本 namespace も auto-target される。

    利用例:
    - `register_retirement_namespace AgentSpec.Provenance.RetirementLinter`
      → 以降 `#check_retired_auto` で本 namespace 配下も検査対象に追加

    Day 22 D11 判断: `#`-prefix なし (declarative side-effect、`#check_retired*` query と semantic 区別)。
    Day 21 hardcode list との additive 関係 (D10、backward compatible 完全維持)。
 -/
elab "register_retirement_namespace " id:ident : command => do
  let ns := id.getId
  modifyEnv fun env => watchedRetirementNamespacesExt.addEntry env ns
  logInfo m!"Registered retirement watched namespace: '{ns}'"

/-- Day 21 A-Standard-Full A-Minimal (auto-target、Day 22 で env-driven 化): `#check_retired_auto` command。

    Day 22 で `getWatchedRetirementNamespaces env` 経由で env-driven 化、Day 21 hardcode list
    (`defaultWatchedRetirementNamespaces`) + Day 22 `register_retirement_namespace` 登録分の
    additive 連結 watched namespaces を auto-target で一括 check し、各 namespace の retired
    declaration count + total を summary 出力。

    Day 22 backward compatible: register 0 件の場合は Day 21 動作と同一 output。

    watched namespaces default (Day 21 D9 hardcode、Day 22 で defaultWatchedRetirementNamespaces 経由):
    - `AgentSpec.Provenance.RetiredEntity` (Day 14 4 deprecated fixture)
    - `AgentSpec.Process.Failure` (Day 6 通常 fixture、retired なし期待)
    - `AgentSpec.Spine.EvolutionStep` (Day 17 transitionLegacy 完全削除後、retired なし期待)

    利用例:
    - `#check_retired_auto` → 全 watched namespaces の retired summary
      Day 21 default 期待 output: RetiredEntity 4 + Failure 0 + EvolutionStep 0 = total 4
      (watched NS は AgentSpec.Provenance.RetiredEntity 直下のため、Role.toCtorIdx
      Lean 4 auto-gen helper は対象外、Day 14 fixture 4 のみ counted)

    Day 18-19-20-21 の `#check_retired*` (手動 namespace 指定 + Day 21 hardcode auto) を
    Day 22 で env-driven 拡張、Week 5-6 A-Maximal elaborator で declaration 追加時 callback 検討。
 -/
elab "#check_retired_auto" : command => do
  let env ← getEnv
  let watchedNamespaces := getWatchedRetirementNamespaces env
  let mut totalRetired := 0
  let mut summary := m!"#check_retired_auto: agent-spec-lib watched namespaces auto-check"
  for ns in watchedNamespaces do
    let mut count := 0
    for (name, _info) in env.constants.toList do
      if ns.isPrefixOf name && name != ns then
        if Lean.Linter.isDeprecated env name then
          count := count + 1
    totalRetired := totalRetired + count
    summary := summary ++ m!"\n  '{ns}': {count} retired"
  summary := summary ++ m!"\n  Total: {totalRetired} retired declaration(s) in {watchedNamespaces.length} watched namespaces"
  logInfo summary

end AgentSpec.Provenance

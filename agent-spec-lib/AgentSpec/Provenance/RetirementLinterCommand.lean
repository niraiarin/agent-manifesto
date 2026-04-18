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

end AgentSpec.Provenance

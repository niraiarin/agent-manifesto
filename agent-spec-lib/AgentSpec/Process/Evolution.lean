-- Process 層: Evolution (研究プロセスの「進化ステップ」)
-- Day 7 hole-driven (Q3 案 B): inductive + Hypothesis 依存
-- B4 4-arg post の完全統合は Day 8+ Verdict 型確定後 (Section 2.9 部分解消)
-- PROV mapping (02-data-provenance §4.1): ResearchActivity (Day 8+ で実装)
import Init.Core
import AgentSpec.Process.Hypothesis

/-!
# AgentSpec.Process.Evolution: 研究プロセスの「進化ステップ」 (Process 層)

Phase 0 Week 4-5 Process 層 (Day 7) の構成要素。Day 6 で実装した `Hypothesis` を
基盤として、研究プロセスの state transition (進化) を inductive で表現。

## 設計 (Section 2.11 確定 Q1-Q4 + 02-data-provenance §4.1)

`Evolution` は研究プロセスにおける進化ステップを表現する inductive。
- `initial` で Hypothesis から開始
- `refineWith` で既存 evolution に新 Hypothesis を加えて継続
- `origin` / `latest` / `stepCount` accessor で各種属性を抽出

**Q3 案 B (Day 7 確定方針)**: EvolutionStep B4 Hoare 4-arg post
`(pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop`
の完全統合は Day 8+ Verdict 型確定後 (Section 2.9 部分解消)。Day 7 では
inductive structure のみ宣言、B4 統合の signature は Day 8+ で追加。

## PROV mapping (Day 8+ で実装、Day 6 と同パターン: docstring 注記レベル)

02-data-provenance §4.1 の `ResearchActivity` constructor として位置付け:

    inductive ResearchActivity : Type where
      | Investigate (e : Evolution)
      | Decompose
      | Refine (e : Evolution)
      | Verify
      | Retire

Day 8+ で `AgentSpec.Provenance` namespace に `ResearchActivity` + mapping
`Evolution.toActivity : Evolution → ResearchActivity` を実装予定。

## TyDD 原則 (Day 1-6 確立パターン適用)

- **Pattern #5** (def Prop signature): inductive 先行、accessor は def
- **Pattern #6** (sorry 0): inductive + recursive def + deriving のみで完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 で hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `initial` / `refineWith` / `origin` / `latest` / `stepCount` は予約語ではない

## Day 7 意思決定ログ (Q1 Minimal、Q3 案 B 反映)

### D1. inductive 採用 (vs structure)
- **代案 A**: `structure Evolution { initialHypothesis : Hypothesis, currentStep : Nat }`
- **採用**: inductive 2 constructor (`initial`, `refineWith`)
- **理由**: 進化の step 構造を type-level で表現、refineWith で recursive に展開可能。
  Day 8+ で Verdict 型を追加して B4 4-arg post に refactor する際、structure より
  inductive の方が constructor 拡張が natural (`refineWithVerdict` 等)。

### D2. `refineWith` の payload は Hypothesis (Q3 案 B、Verdict は Day 8+)
- **代案 A**: `refineWith (prev : Evolution) (input : Hypothesis) (output : Verdict)` (B4 4-arg post 完全)
- **採用**: `refineWith (prev : Evolution) (refined : Hypothesis)` (Day 7 hole-driven)
- **理由**: Verdict 型は未定義、Day 8+ Provenance 層実装時に追加 (Q3 案 B、Section 2.9 部分解消)。
  Day 7 scope を 2 type に制御 (Q1 Minimal)。

### D3. accessor の recursive def 採用
- **代案 A**: `Evolution.origin` を `Hypothesis` field として保持 (structure に近い設計)
- **採用**: `def origin : Evolution → Hypothesis` で recursive def
- **理由**: inductive の自然な evaluation、Pattern #5 (def Prop signature) 踏襲。
  `stepCount` も同様 (Nat への recursive map)。

### D4. `deriving Inhabited` の解決パス (Subagent A1 注記)
- 自動 deriving は `initial Hypothesis.default` を選択 (最初の constructor)。
  `Hypothesis` が `Inhabited` (claim = "" 等のデフォルト) を deriving しているため
  `Evolution` も `initial { claim := "" }` で解決される。
- Day 38 (2026-04-21): `DecidableEq` も recursive inductive に対して Lean 4 が
  自動 derive 可能と実証 (HandoffChain Day 35 と同パターン)。Day 36 empirical
  I2 (Evolution DecidableEq 要判定) を解消。
-/

namespace AgentSpec.Process

/-- 研究プロセスの「進化ステップ」を表現する inductive
    (PROV mapping: `ResearchActivity`、Day 8+ 実装)。

    Day 7 hole-driven (Q3 案 B): Hypothesis 依存 inductive 2 constructor。
    Day 8+ で Verdict 型を追加して B4 Hoare 4-arg post に refactor 予定。 -/
inductive Evolution where
  /-- Hypothesis を出発点とする evolution の開始 (initial step)。 -/
  | initial (hypothesis : Hypothesis)
  /-- 既存 evolution に新しい Hypothesis を加えて継続 (Day 7 hole-driven、
      Day 8+ で Verdict 型を加えて B4 Hoare 4-arg post に refactor 予定)。 -/
  | refineWith (prev : Evolution) (refined : Hypothesis)
  deriving DecidableEq, Inhabited, Repr

namespace Evolution

/-- evolution の origin (最初の Hypothesis) を抽出。 -/
def origin : Evolution → Hypothesis
  | .initial h => h
  | .refineWith prev _ => origin prev

/-- evolution の latest (最新 Hypothesis) を抽出。 -/
def latest : Evolution → Hypothesis
  | .initial h => h
  | .refineWith _ refined => refined

/-- evolution の step 数 (initial = 0、refineWith ごと +1)。 -/
def stepCount : Evolution → Nat
  | .initial _ => 0
  | .refineWith prev _ => prev.stepCount + 1

/-- 自明な evolution (test fixture)、trivial Hypothesis から initial 開始。 -/
def trivial : Evolution := .initial Hypothesis.trivial

end Evolution

end AgentSpec.Process

-- Provenance 層: ResearchActivity (PROV-O 三項の Activity)
-- Day 9 で先行配置 (5 variant: investigate / decompose / refine / verify / retire)
-- verify variant は Day 8 EvolutionStep B4 4-arg post と整合 (input : Hypothesis、output : Verdict)
import Init.Core
import AgentSpec.Process.Hypothesis
import AgentSpec.Provenance.Verdict

/-!
# AgentSpec.Provenance.ResearchActivity: PROV-O 三項の Activity 統合

Phase 0 Week 4-5 Provenance 層の Day 9 構成要素。02-data-provenance §4.1 PROV-O の
`ResearchActivity` を Lean 化、5 variant inductive で実装:

    inductive ResearchActivity where
      | investigate                                        -- 調査
      | decompose                                          -- 分解
      | refine                                             -- 洗練
      | verify (input : Hypothesis) (output : Verdict)     -- 検証 (B4 4-arg post 対応)
      | retire                                             -- 退役

`verify` variant は Day 8 EvolutionStep B4 4-arg post と直接整合 (Hypothesis 入力 +
Verdict 出力)。これにより EvolutionStep の transition を `ResearchActivity.verify`
として PROV-O activity 化する path が natural に確立。

## TyDD 原則 (Day 1-8 確立パターン適用)

- **Pattern #5** (def Prop signature): inductive 先行
- **Pattern #6** (sorry 0): inductive + deriving + accessor で完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `investigate` / `decompose` / `refine` / `verify` /
  `retire` は予約語ではない

## Day 9 意思決定ログ

### D1. 5 variant inductive 採用 (02-data-provenance §4.1 通り)
- **代案**: B4 4-arg post と同型の単一 `verify` variant のみ
- **採用**: 5 variant (investigate / decompose / refine / verify / retire)
- **理由**: 02-data-provenance §4.1 PROV-O 設計を 100% 忠実実装。investigate / decompose /
  refine / retire は Day 10+ で payload 拡充候補 (現状 payload なし、minimal scope)。

### D2. verify variant の payload を Hypothesis + Verdict に固定
- **代案**: payload なし (opaque)、または payload を String 等で hole-driven
- **採用**: `verify (input : Hypothesis) (output : Verdict)`
- **理由**: Day 8 EvolutionStep B4 4-arg post (transition の input / output) と直接整合。
  EvolutionStep transition を ResearchActivity.verify として PROV mapping する path が natural。

### D3. payload なし variant (investigate / decompose / refine / retire) は Day 10+ で拡充検討
- **採用**: Day 9 minimal scope で payload なし
- **理由**: Q2 A-Minimal 確定方針 (2 type per Day rhythm)、payload 拡充は Day 10+ Provenance 層完成時。

## Day 26 意思決定ログ (ResearchActivity payload 拡充、Day 13-22 = 12 Day 連続繰り延げ解消、Day 24 audit 次 long-deferred candidate 対処)

### D4. payload 付き variants `investigateOf` / `retireOf` を backward compatible 追加 (Day 26 Q1 Day 24 audit 次 long-deferred candidate 解消)
- **背景**: Day 9 D3 で「Day 10+ で payload 拡充検討」と記載したが Day 10-25 = 16 Day (Day 13-22 識別時点から 12 Day) 連続繰り延げ、Day 24 audit で次の long-deferred candidate 警告識別
- **代案 A (breaking change)**: 既存 `.investigate` / `.retire` に payload 追加、既存 test と `.trivial = .investigate` 等を書き換え
- **代案 B (backward compat)**: 新 variant `investigateOf (target : Hypothesis)` / `retireOf (entity : Hypothesis)` を追加、既存 payloadless variants を維持
- **採用**: 案 B (backward compatible)
- **理由**: Day 14-25 で確立された backward compatible 原則継続 (Day 17 transitionLegacy のような breaking change は Week 3-4 Manifest 移植まで避ける)、既存 Test (ResearchActivityTest / ProvRelationTest) 変更なし、Day 27+ で残 variants (decompose / refine) 拡充可能
- **semantic 整合**: 02-data-provenance §4.1 PROV-O Activity は optional payload を許容、payloadless + payload 付き variant の共存は PROV-O 仕様に即する (Day 9 `verify` が payload 付きのみだったのを一般化)

### D5. 2 variant 選択 (investigate + retire)
- **選択**: `investigateOf` + `retireOf` (Day 26 A-Minimal scope、2 variant 追加)
- **理由**: `investigateOf` は PROV-O 最も frequently-used activity (初期探索段階)、`retireOf` は §4.4 退役との連携 path (Day 12 RetiredEntity と semantic 整合)、decompose / refine は Day 27+ (Day 27 で残 2 variant 拡充予定、A-Minimal 1 Day 完結)
- **payload type 選択**: 両者とも `Hypothesis` (Day 9 `verify` と同型)、Day 27+ で `retireOf` を `RetiredEntity` 拡張検討 (Day 12 structural 対応)

### D6. payload 型 = Hypothesis (Day 9 verify pattern 継続)
- **採用**: `investigateOf (target : Hypothesis)` / `retireOf (entity : Hypothesis)`
- **理由**: Day 9 `verify (input : Hypothesis) (output : Verdict)` と同型 `Hypothesis` argument、TyDD-S1 types-first (既存 type 再利用)、Day 27+ で `retireOf` を `RetiredEntity` 拡張時も backward compatible (Day 12 RetiredEntity.entity : ResearchEntity、Hypothesis は ResearchEntity の constructor なので lift 可能)
-/

namespace AgentSpec.Provenance

open AgentSpec.Process (Hypothesis)

/-- 02-data-provenance §4.1 PROV-O `ResearchActivity` (Day 9、5 variant)。

    `verify` variant は Day 8 EvolutionStep B4 4-arg post と整合 (input : Hypothesis、
    output : Verdict)。他 4 variant は Day 10+ で payload 拡充候補。 -/
inductive ResearchActivity where
  /-- 調査 activity (Day 9 payload なし、Day 26 で investigateOf も追加)。 -/
  | investigate
  /-- 分解 activity (Day 27+ で payload 拡充候補)。 -/
  | decompose
  /-- 洗練 activity (Day 27+ で payload 拡充候補)。 -/
  | refine
  /-- 検証 activity (Day 8 EvolutionStep B4 4-arg post と整合: input + output)。 -/
  | verify (input : Hypothesis) (output : Verdict)
  /-- 退役 activity (Day 9 payload なし、Day 26 で retireOf も追加、Day 27+ で RetiredEntity 拡張検討)。 -/
  | retire
  /-- Day 26 追加: 調査 activity with target hypothesis (02-data-provenance §4.1 PROV-O Activity
      optional payload、Day 9 D3 の Day 10+ 拡充検討を Day 26 で解消、Day 22 audit 次 long-deferred
      candidate 対処、backward compatible で payloadless `investigate` と共存)。 -/
  | investigateOf (target : Hypothesis)
  /-- Day 26 追加: 退役 activity with target entity (02-data-provenance §4.4 RetiredEntity 連携 path、
      Day 27+ で RetiredEntity 拡張検討、Day 9 payload なし `retire` と共存、Day 22 audit 次
      long-deferred candidate 対処)。 -/
  | retireOf (entity : Hypothesis)
  deriving DecidableEq, Inhabited, Repr

namespace ResearchActivity

/-- 自明な activity (test fixture)、investigate を選択。 -/
def trivial : ResearchActivity := .investigate

/-- ResearchActivity が verify variant かを判定。 -/
def isVerify : ResearchActivity → Bool
  | .verify _ _ => true
  | _ => false

/-- ResearchActivity が retire variant かを判定。 -/
def isRetire : ResearchActivity → Bool
  | .retire => true
  | _ => false

/-- Day 26: ResearchActivity が investigateOf variant かを判定。 -/
def isInvestigateOf : ResearchActivity → Bool
  | .investigateOf _ => true
  | _ => false

/-- Day 26: ResearchActivity が retireOf variant かを判定。 -/
def isRetireOf : ResearchActivity → Bool
  | .retireOf _ => true
  | _ => false

end ResearchActivity

end AgentSpec.Provenance

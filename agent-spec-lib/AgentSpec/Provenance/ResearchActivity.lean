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
-/

namespace AgentSpec.Provenance

open AgentSpec.Process (Hypothesis)

/-- 02-data-provenance §4.1 PROV-O `ResearchActivity` (Day 9、5 variant)。

    `verify` variant は Day 8 EvolutionStep B4 4-arg post と整合 (input : Hypothesis、
    output : Verdict)。他 4 variant は Day 10+ で payload 拡充候補。 -/
inductive ResearchActivity where
  /-- 調査 activity (Day 10+ で payload 拡充候補)。 -/
  | investigate
  /-- 分解 activity。 -/
  | decompose
  /-- 洗練 activity。 -/
  | refine
  /-- 検証 activity (Day 8 EvolutionStep B4 4-arg post と整合: input + output)。 -/
  | verify (input : Hypothesis) (output : Verdict)
  /-- 退役 activity (Day 10+ で 02-data-provenance §4.4 RetiredEntity 連携検討)。 -/
  | retire
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

end ResearchActivity

end AgentSpec.Provenance

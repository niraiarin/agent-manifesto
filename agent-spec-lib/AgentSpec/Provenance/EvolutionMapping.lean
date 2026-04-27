-- Provenance 層: EvolutionStep transition → ResearchActivity.verify mapping (Day 10、Q4 案 A)
-- Day 8 EvolutionStep B4 4-arg post と Day 9 ResearchActivity.verify (Hypothesis+Verdict) の連携 path 確立
import Init.Core
import AgentSpec.Process.Hypothesis
import AgentSpec.Provenance.Verdict
import AgentSpec.Provenance.ResearchActivity

/-!
# AgentSpec.Provenance.EvolutionMapping: Spine EvolutionStep B4 → Provenance ResearchActivity 連携

Phase 0 Week 4-5 Provenance 層の Day 10 連携要素。Day 8 で EvolutionStep を B4 Hoare
4-arg post に refactor、Day 9 で ResearchActivity.verify (input : Hypothesis,
output : Verdict) を実装。Day 10 で **両者の連携 path を free function で確立**
(Q4 案 A 確定方針)。

## 設計 (Section 2.18 Q4 案 A 確定)

    def transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity :=
      .verify h v

これは **EvolutionStep.transition の (input, output) を ResearchActivity.verify として
PROV-O Activity 化する mapping**。free function 形式で input/output のみ受取り、
state の変化 (pre/post) は対象外 (Q4 案 A 案 B overspec を回避、Q1 Minimal scope 維持)。

## 利用例

    -- Day 8 EvolutionStep transition の (input, output) を取り出して Activity 化:
    -- (pre, h, v, post) → ResearchActivity.verify h v
    example : ResearchActivity := transitionToActivity Hypothesis.trivial Verdict.proven

## 案 B (overspec、Day 11+ 検討) との比較

案 B は transition proof 引数を取る厳密形:

    def transitionToActivityStrict {S} [EvolutionStep S] (pre post : S) (h : Hypothesis)
        (v : Verdict) (ev : transition pre h v post) : ResearchActivity := .verify h v

これは「実際に transition が成立する場合のみ Activity 化」を型レベルで強制するが、
Day 10 minimal scope では overspec。Day 11+ で必要時に追加検討。

## TyDD 原則 (Day 1-9 確立パターン適用)

- **Pattern #5** (def Prop signature): free function、Prop ではないが types-first
- **Pattern #6** (sorry 0): 1 行の `.verify h v` で完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `transitionToActivity` は予約語ではない

## 層依存性 (Day 10)

EvolutionMapping は Spine 層 EvolutionStep を **import しない** (Day 10 mapping は input/output
のみで signature 整合を保証、transition 自体は呼び出し側が実体として扱う)。
代わりに Hypothesis (Process) + Verdict + ResearchActivity (Provenance) を import。

これは Day 8 で確立した「Spine = core abstraction、Process/Provenance = 具体型」
layer architecture と整合的。

## Day 10 意思決定ログ

### D1. free function 採用 (Q4 案 A、案 B overspec を回避)
- **代案 B**: `transitionToActivityStrict {S} [EvolutionStep S] (pre post : S) (h : Hypothesis) (v : Verdict) (ev : transition pre h v post) : ResearchActivity`
- **採用**: free function `transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity := .verify h v`
- **理由**: Q1 Minimal scope 制御、Day 9 ResearchActivity.verify との直接整合、案 B は transition proof
  の生成・受渡しが冗長。Day 11+ で必要時に Strict 版追加可能。

### D2. EvolutionStep を import しない (層依存性最小化)
- **採用**: Spine 層 EvolutionStep を import せず、Hypothesis + Verdict + ResearchActivity のみ依存
- **理由**: Day 8 layer architecture (Spine = core abstraction) と整合、transition proof を取らない
  free function 設計のため EvolutionStep への依存が不要。Day 11+ で Strict 版追加時に EvolutionStep import 追加。
-/

namespace AgentSpec.Provenance

open AgentSpec.Process (Hypothesis)

/-- Day 8 EvolutionStep B4 4-arg post の (input, output) を Day 9 ResearchActivity.verify
    として PROV-O Activity 化する mapping (Q4 案 A 確定: free function、input/output のみ)。

    Day 10 メイン成果の一つ、Day 8/9 連携 path 確立。 -/
def transitionToActivity (h : Hypothesis) (v : Verdict) : ResearchActivity :=
  .verify h v

end AgentSpec.Provenance

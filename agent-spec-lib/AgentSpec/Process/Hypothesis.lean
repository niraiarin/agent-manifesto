-- Process 層: Hypothesis (研究プロセスの「主張」)
-- Day 6 hole-driven: claim を String で保持、Day 8+ で型安全な表現に refactor 候補
-- PROV mapping (02-data-provenance §4.1): ResearchEntity.Hypothesis に対応 (Day 8+ で実装)
import Init.Core

/-!
# AgentSpec.Process.Hypothesis: 研究プロセスの「主張」 (Process 層)

Phase 0 Week 4-5 Process 層 (Day 6 前倒し開始) の最小要素。

## 設計 (Section 2.11 + 02-data-provenance §4.1)

`Hypothesis` は研究プロセスにおける主張 (claim) を表現する first-class entity。
- claim は Day 6 hole-driven で `String` 表現
- 主張間の関係 (refines / refutes / blocks) は `Spine/Edge.lean` の `EdgeKind` で表現
  (Hypothesis 単体には保持しない、graph 構造として疎結合)

## PROV mapping (Day 8+ で実装、Day 6 では docstring 注記レベル)

02-data-provenance §4.1 の `ResearchEntity` constructor として位置付け:

    inductive ResearchEntity : Type where
      | Hypothesis (h : AgentSpec.Process.Hypothesis)
      | Failure (f : AgentSpec.Process.Failure)
      | ...

Day 8+ で `AgentSpec.Provenance` namespace に `ResearchEntity` + mapping
`Hypothesis.toEntity : Hypothesis → ResearchEntity` を実装予定。

## TyDD 原則 (Day 1-5 確立パターン適用)

- **Pattern #5** (def Prop signature): Hypothesis structure 先行、操作は後付け
- **Pattern #6** (sorry 0): structure + deriving のみで完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 で hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `claim` / `rationale` は予約語ではない、安全

## Day 6 意思決定ログ

### D1. claim を String で実装 (Day 8+ で型化検討)
- **代案 A**: `inductive Claim` で型安全な claim 表現
- **採用**: `String`
- **理由**: Day 6 hole-driven の minimal 実装、claim の構造化は Day 8+ Provenance 層
  + Process 層成熟後に検討。先に Hypothesis/Failure/Evolution の関係を確立する優先。

### D2. structure 採用 (vs inductive)
- **代案 A**: `inductive Hypothesis` で variant ごとに claim/rationale 構造を変える
- **採用**: `structure Hypothesis { claim : String, rationale : Option String }`
- **理由**: Hypothesis 自体は単一形 (claim + 任意 rationale)。variant が必要な場合は
  Day 7+ で Evolution / Failure と組合わせて表現する方が cleaner。

### D3. refines/refutes/blocks を内部 field にしない
- **代案 A**: `Hypothesis` に `refinesOf : Option Hypothesis` field 追加
- **採用**: 関係は `Spine/Edge.lean` の `EdgeKind` で表現、Hypothesis 単体には保持しない
- **理由**: Edge は既に 6 variant (wasDerivedFrom/refines/refutes/blocks/relates/wasReplacedBy)
  完備、Hypothesis の関係も Edge graph として表現する方が consistent + sparse representation。
-/

namespace AgentSpec.Process

/-- 研究プロセスの「主張」(claim) を表現する first-class entity。

    Day 6 hole-driven: `claim` を `String` で保持。Day 8+ で型安全な表現に refactor 候補。
    主張間の関係 (refines / refutes / blocks) は `AgentSpec.Spine.Edge` の `EdgeKind`
    で表現 (本 structure には保持しない)。

    PROV mapping: `ResearchEntity.Hypothesis` (Day 8+ 実装)。 -/
structure Hypothesis where
  /-- 主張本体 (Day 6 hole-driven: String 表現)。 -/
  claim : String
  /-- 主張の根拠 (任意)。Day 8+ で Evidence 型に refactor 候補。 -/
  rationale : Option String := none
  deriving DecidableEq, Inhabited, Repr

namespace Hypothesis

/-- 自明な hypothesis (test fixture / placeholder)。 -/
def trivial : Hypothesis := { claim := "trivial" }

/-- claim と rationale から構築 (smart constructor)。 -/
def mk' (claim : String) (rationale : String) : Hypothesis :=
  { claim := claim, rationale := some rationale }

end Hypothesis

end AgentSpec.Process

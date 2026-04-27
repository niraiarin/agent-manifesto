-- Process 層: Hypothesis (研究プロセスの「主張」)
-- Day 6 hole-driven: claim を String で保持
-- Day 45 (2026-04-21): GA-S8 必須化 Week スプリント B-2 第 1 弾、rationale : Rationale 必須化 (breaking change)
-- PROV mapping (02-data-provenance §4.1): ResearchEntity.Hypothesis に対応
import Init.Core
import AgentSpec.Spine.Rationale

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
- **採用**: `structure Hypothesis { claim : String, rationale : Rationale }` (Day 45 で必須化)
- **理由**: Hypothesis 自体は単一形 (claim + rationale)。variant が必要な場合は
  Day 7+ で Evolution / Failure と組合わせて表現する方が cleaner。

### D4. Day 45 GA-S8 必須化 (breaking change、B-2 スプリント第 1 弾)
- **Day 6 D2 原案**: `rationale : Option String := none` (optional)
- **Day 45 採用**: `rationale : AgentSpec.Spine.Rationale` (必須、default なし)
- **理由**: GA-S8 原文「全 constructor で必須化」忠実遵守。Option + default none は型で
  「判断根拠が必須」という規範を表現できず、Week 6+ 以降で再 breaking となる技術的負債化する。
  Phase 0 Week 2 (Day 45) を breaking の最後のタイミングとして採用。Rationale.trivial は
  test fixture placeholder として提供、production 使用には意味ある Rationale を要求。

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
  /-- 主張の根拠 (Day 45 で必須化、GA-S8 準拠)。test fixture では Rationale.trivial 許容、
      production 利用では意味ある Rationale (text + references + confidence) を要求。 -/
  rationale : AgentSpec.Spine.Rationale
  deriving DecidableEq, Inhabited, Repr

namespace Hypothesis

/-- 自明な hypothesis (test fixture / placeholder)、空 Rationale 付き。 -/
def trivial : Hypothesis :=
  { claim := "trivial", rationale := AgentSpec.Spine.Rationale.trivial }

/-- claim と rationale から構築 (smart constructor、Day 45 で signature 更新)。 -/
def mk' (claim : String) (rationale : AgentSpec.Spine.Rationale) : Hypothesis :=
  { claim := claim, rationale := rationale }

/-- Day 45: String ベースの旧 API 互換ヘルパー (text のみの rationale を内部で Rationale.ofText に包む)。
    ただし confidence は 0 で固定、references 空、author/timestamp 未指定のため production 利用は非推奨。
    Day 58 (2026-04-21): @[deprecated] 付与、Day 57 empirical F1 Option B 先行 strict 化 prod site 1 件目。
    実利用では `Hypothesis.mk' claim (Rationale.strict ...)` を推奨。 -/
@[deprecated "ofClaimWithText は attribution 欠損 — Hypothesis.mk' + Rationale.strict を使用推奨 (Day 58 A-Minimal linter)" (since := "2026-04-21")]
def ofClaimWithText (claim : String) (rationaleText : String) : Hypothesis :=
  { claim := claim,
    rationale := AgentSpec.Spine.Rationale.ofText rationaleText 0 }

end Hypothesis

end AgentSpec.Process

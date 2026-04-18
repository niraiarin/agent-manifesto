-- Process 層: Failure (研究プロセスの「失敗」) - first-class entity
-- Day 6 hole-driven: 関連 hypothesis/evidence/blocker は String 参照、Day 7+ で型化
-- PROV mapping (02-data-provenance §4.1, §4.3): ResearchEntity.Failure に対応 (Day 8+ 実装)
import Init.Core

/-!
# AgentSpec.Process.Failure: 研究プロセスの「失敗」 (Process 層)

Phase 0 Week 4-5 Process 層 (Day 6 前倒し開始) の最小要素。
**MLflow/DVC の弱点 (失敗の post-hoc 化) を回避し、Failure を first-class entity として
最初から型に組み込む** (02-data-provenance §4.3 設計指針)。

## 設計 (02-data-provenance §4.3 + Section 2.11)

`Failure` は研究プロセスにおける失敗を first-class entity として表現。
- `failedHypothesis` は Day 6 hole-driven で `String` (Hypothesis name)
- `reason : FailureReason` で失敗の根本原因を 4 variant で構造化
- `whyFailed : Failure → FailureReason` accessor で reason 抽出

`FailureReason` 4 variant は 02-data-provenance §4.3 設計を踏襲:

    inductive FailureReason where
      | HypothesisRefuted (evidence : ...)         -- 主張が反証された
      | ImplementationBlocked (blocker : ...)      -- 実装が阻害された
      | SpecInconsistent (inconsistency : ...)     -- 仕様が不整合
      | Retired (replacedBy : ...)                 -- 退役、後継あり

Day 6 では各 variant の payload を `String` で hole-driven、Day 7+ で型化:
- `evidence : Evidence` 型 (Day 8+ Provenance 層)
- `blocker : Spec` 型 (Manifest 移植 Week 3-4)
- `inconsistency : InconsistencyProof` 型 (Process 層成熟後)
- `replacedBy : ResearchEntity` (Day 8+ Provenance 層、本来は Hypothesis 直接参照)

## PROV mapping (Day 8+ で実装、Day 6 では docstring 注記レベル)

02-data-provenance §4.1 の `ResearchEntity` constructor として位置付け:

    inductive ResearchEntity : Type where
      | Hypothesis (h : AgentSpec.Process.Hypothesis)
      | Failure (f : AgentSpec.Process.Failure)
      | ...

PROV では `wasInvalidatedAt` 概念 (02-data-provenance §4.4) と関連、
退役 entity への参照を Lean compiler で warning/error 検出する設計が将来候補。

## TyDD 原則 (Day 1-5 確立パターン適用)

- **Pattern #5** (def Prop signature): structure + inductive 先行、操作 (whyFailed) は accessor
- **Pattern #6** (sorry 0): structure + inductive + deriving のみで完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 で hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `failedHypothesis` / `reason` / `whyFailed` 全て予約語ではない

## Day 6 意思決定ログ

### D1. FailureReason を inductive enum で定義 (4 variant)
- **代案 A**: `String` で reason を表現 (free-form)
- **採用**: 4 variant inductive (HypothesisRefuted / ImplementationBlocked / SpecInconsistent / Retired)
- **理由**: 02-data-provenance §4.3 設計指針忠実遵守、root cause を構造化記録。
  variant 追加は backward compatible (Day 7+ で必要時)。

### D2. payload を String で hole-driven (Day 7+ で型化)
- **代案 A**: 各 payload に専用型 (Evidence / Spec / InconsistencyProof / ResearchEntity) を即時定義
- **採用**: 全 payload を `String` (Day 6 hole-driven)
- **理由**: 各専用型は別 module 依存 (Evidence は Provenance 層 Day 8+、Spec は Manifest 移植 Week 3-4)、
  Day 6 minimal scope では Process 層 inductive のみに集中。

### D3. failedHypothesis を String name 参照 (Day 7+ で Hypothesis 直接参照)
- **代案 A**: `failedHypothesis : Hypothesis` で直接参照
- **採用**: `failedHypothesis : String` (Hypothesis name 参照)
- **理由**: Day 6 で Hypothesis と Failure の循環依存を避ける hole-driven 戦略。
  Day 7+ で `Evolution` 結合時に直接参照に refactor (Hypothesis を import)。
-/

namespace AgentSpec.Process

/-- 失敗の根本原因 4 variant (02-data-provenance §4.3 first-class Failure 設計)。

    Day 6 hole-driven: 各 variant の payload を `String` で表現、Day 7+ で専用型に refactor。 -/
inductive FailureReason where
  /-- 主張が反証された (evidence: 反証の根拠、Day 8+ で Evidence 型に refactor)。 -/
  | HypothesisRefuted (evidence : String)
  /-- 実装が阻害された (blocker: 阻害要因、Day 8+ で Spec 型に refactor)。 -/
  | ImplementationBlocked (blocker : String)
  /-- 仕様が不整合 (inconsistency: 不整合の証明、Day 8+ で InconsistencyProof 型に refactor)。 -/
  | SpecInconsistent (inconsistency : String)
  /-- 退役、後継あり (replacedBy: 後継 entity、Day 8+ で ResearchEntity 型に refactor)。 -/
  | Retired (replacedBy : String)
  deriving DecidableEq, Inhabited, Repr

/-- 研究プロセスの「失敗」を first-class entity として表現
    (PROV mapping: `ResearchEntity.Failure`、Day 8+ 実装)。

    Day 6 hole-driven: `failedHypothesis` は Hypothesis name (String 参照)、
    Day 7+ で Hypothesis 直接参照に refactor 予定。 -/
structure Failure where
  /-- 失敗した hypothesis の name (Day 6: String、Day 7+ で Hypothesis 直接参照)。 -/
  failedHypothesis : String
  /-- 失敗の根本原因 (4 variant のうち 1 つ)。 -/
  reason : FailureReason
  deriving DecidableEq, Inhabited, Repr

namespace Failure

/-- 失敗の原因を抽出 (`reason` field の alias、明示的 accessor)。 -/
def whyFailed (f : Failure) : FailureReason := f.reason

/-- 自明な failure (test fixture / placeholder)。 -/
def trivial : Failure :=
  { failedHypothesis := "trivial-hypothesis", reason := .HypothesisRefuted "no evidence" }

/-- HypothesisRefuted variant の smart constructor。 -/
def refuted (hypothesisName : String) (evidence : String) : Failure :=
  { failedHypothesis := hypothesisName, reason := .HypothesisRefuted evidence }

/-- Retired variant の smart constructor。 -/
def retired (hypothesisName : String) (successor : String) : Failure :=
  { failedHypothesis := hypothesisName, reason := .Retired successor }

end Failure

end AgentSpec.Process

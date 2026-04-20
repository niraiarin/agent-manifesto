-- Spine 層: ResearchNode umbrella (GA-S1、研究 tree 全体の Lean 型表現)
-- Day 54: 7 constructor inductive (Survey/Gap/Hypothesis/Decomposition/Implementation/Failure/Retired)
-- 各 constructor に rationale 必須化 (Day 45-48 pattern)、String payload で hole-driven (Spine 層隔離)
import Init.Core
import Init.Data.List.Basic
import AgentSpec.Spine.Rationale

/-!
# AgentSpec.Spine.ResearchNode: 研究 tree 全体の umbrella inductive (GA-S1、Spine 層)

GA-S1 umbrella Gap「研究 tree 全体の Lean 型表現なし」を解消。7 node kind を inductive
constructor として型化、Tana supertag と Lean inductive type の同型性 (10-gap-analysis.md)
を利用。各 constructor に rationale : Rationale を必須化 (Day 45-48 Process 型 pattern
踏襲)。

## 設計 (10-gap-analysis.md §GA-S1 + synthesis §4.1 #1, §2a)

7 constructor (研究 lifecycle 全網羅):
- `Survey`: 先行研究調査 (topic, rationale)
- `Gap`: 未解決 Gap 特定 (description, rationale)
- `Hypothesis`: 主張提案 (claim, rationale)
- `Decomposition`: タスク分解 (parent, children, rationale)
- `Implementation`: 実装作成 (target, artifact, rationale)
- `Failure`: 反証 (reason, rationale)
- `Retired`: 退役 (cause, rationale)

各 payload は Day 6 Hypothesis 方針と同じ String hole-driven、Day N+ で構造化検討。
Process 層型 (AgentSpec.Process.Hypothesis 等) との mapping は既存 Provenance.ResearchEntity
と対照的に Spine 層内部で閉じる (layer 整合性)。Rationale は Day 44-52 で確立済みの Spine 型、
inductive payload として参加可能。

## 層境界設計

- **Spine.ResearchNode** (本 module): 研究 lifecycle の ontological kind (何の種類か)
- **Provenance.ResearchEntity**: PROV-O entity 境界 (誰の判断か、どう関連するか、Day 9-)
- **Spine.LifeCyclePhase** (Day 51): 現在の進行状態 (Proposed → ... → Retired)

3 者は直交:
- Hypothesis (kind) × Implementing (phase) × rationale = 「実装中の主張」
- Failure (kind) × Cancelled (phase) × rationale = 「中止された反証」等

Day 55+ で ResearchNode ↔ LifeCyclePhase の "current phase" 関係を ResearchNodeWithPhase
structure で追加検討 (Day 54 scope 外、conservative)。

## TyDD 原則 (Day 1-53 確立パターン適用)

- **Pattern #5** (def Prop signature): inductive 先行、accessor (kind/rationale) は def
- **Pattern #6** (sorry 0): inductive + deriving + accessor def のみで完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 済
- **Pattern #8** (Lean 4 予約語回避): 全 constructor 名 (Survey/Gap/Hypothesis/Decomposition/
  Implementation/Failure/Retired) は予約語ではない。Hypothesis は Process 層 type と同名だが
  `ResearchNode.Hypothesis` で fully-qualified 可能、name collision は namespace 分離で回避。

## Day 54 意思決定ログ (GA-S1 conservative 着手)

### D1. 7 constructor 網羅 (GA-S1 原文通り)
- **代案 A**: 既存 Provenance.ResearchEntity 6 constructor を流用
- **採用**: 新 inductive 7 constructor (Survey/Gap/Hypothesis/Decomposition/Implementation/
  Failure/Retired)
- **理由**: ResearchEntity は PROV-O entity (誰がどう関連するか) で layer が異なる。
  GA-S1 umbrella は ontological kind (何の種類か) で役割分離。両者は共存 (ResearchNode ↔
  ResearchEntity mapping は Day 55+ で検討)。

### D2. String payload + Rationale 必須 (hole-driven、Day 45-48 pattern)
- **代案**: Process.Hypothesis 等 concrete type を payload に使用
- **採用**: String payload (Day 6 Hypothesis と同方針) + rationale 必須化
- **理由**: Spine → Process 逆依存回避 (Day 44 Rationale / Day 51 State / Day 53 ResearchSpec
  と同方針)。Rationale は Spine 内部型なので循環なし。Day N+ で Process 層 mapping 追加時に
  payload を Process 型に refactor 検討。

### D3. `deriving DecidableEq, Inhabited, Repr`
- Day 45-48 の recursive inductive DecidableEq derive 可能性を継承。ResearchNode は
  recursive ではないが、field 全てが DecidableEq (String / List String / Rationale) のため
  自動 derive 成立。Inhabited は Survey "trivial" + Rationale.trivial で解決。
-/

namespace AgentSpec.Spine

/-- GA-S1 umbrella: 研究 tree の 7 node kind を統合する inductive。

    Day 45-48 pattern で各 constructor に rationale 必須化、payload は String hole-driven。
    Provenance.ResearchEntity (PROV-O entity) / Spine.LifeCyclePhase (State) と直交。 -/
inductive ResearchNode where
  /-- 先行研究調査 node (topic は調査対象)。 -/
  | Survey (topic : String) (rationale : Rationale)
  /-- 未解決 Gap 特定 node (description は Gap の説明)。 -/
  | Gap (description : String) (rationale : Rationale)
  /-- 主張提案 node (claim は主張本体、Process.Hypothesis と同型 String)。 -/
  | Hypothesis (claim : String) (rationale : Rationale)
  /-- タスク分解 node (parent は親 node ID、children は分解結果 ID list)。 -/
  | Decomposition (parent : String) (children : List String) (rationale : Rationale)
  /-- 実装作成 node (target は実装対象、artifact は成果物 ref)。 -/
  | Implementation (target : String) (artifact : String) (rationale : Rationale)
  /-- 反証 node (reason は反証理由、Process.Failure と同型 String)。 -/
  | Failure (reason : String) (rationale : Rationale)
  /-- 退役 node (cause は退役原因)。 -/
  | Retired (cause : String) (rationale : Rationale)
  deriving DecidableEq, Inhabited, Repr

/-- ResearchNode の ontological kind を enum tag として抽出 (7 variant)。 -/
inductive ResearchNodeKind where
  | Survey | Gap | Hypothesis | Decomposition | Implementation | Failure | Retired
  deriving DecidableEq, Inhabited, Repr

namespace ResearchNode

/-- 自明な node (test fixture)、trivial Survey + Rationale.trivial。 -/
def trivial : ResearchNode :=
  .Survey "" Rationale.trivial

/-- node の kind を抽出 (enum tag)。 -/
def kind : ResearchNode → ResearchNodeKind
  | .Survey _ _ => .Survey
  | .Gap _ _ => .Gap
  | .Hypothesis _ _ => .Hypothesis
  | .Decomposition _ _ _ => .Decomposition
  | .Implementation _ _ _ => .Implementation
  | .Failure _ _ => .Failure
  | .Retired _ _ => .Retired

/-- node の rationale を抽出 (全 constructor に必須 field なので total)。 -/
def rationale : ResearchNode → Rationale
  | .Survey _ r => r
  | .Gap _ r => r
  | .Hypothesis _ r => r
  | .Decomposition _ _ r => r
  | .Implementation _ _ r => r
  | .Failure _ r => r
  | .Retired _ r => r

/-- node が terminal kind (Failure / Retired) か判定。 -/
def isTerminal : ResearchNode → Bool
  | .Failure _ _ => true
  | .Retired _ _ => true
  | _ => false

/-- node が generative kind (Survey / Gap / Hypothesis / Decomposition / Implementation) か判定。 -/
def isGenerative : ResearchNode → Bool
  | .Survey _ _ => true
  | .Gap _ _ => true
  | .Hypothesis _ _ => true
  | .Decomposition _ _ _ => true
  | .Implementation _ _ _ => true
  | _ => false

end ResearchNode

end AgentSpec.Spine

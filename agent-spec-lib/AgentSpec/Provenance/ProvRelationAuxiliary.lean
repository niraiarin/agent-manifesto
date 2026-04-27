-- Provenance 層: ProvRelationAuxiliary (Day 13、PROV-O §4.1 auxiliary + §4.4 retirement relation)
-- Q1 A 案 + Q2 A-Minimal: WasInformedBy + ActedOnBehalfOf + WasRetiredBy 3 structure 1 ファイル統合
-- Q3 案 B: 新 ProvRelationAuxiliary.lean 別 file 配置 (ProvRelation.lean = main、本 file = auxiliary)
-- Q4 案 A: WasRetiredBy { entity : ResearchEntity, retired : RetiredEntity } (Entity → RetiredEntity 2-arg)
import Init.Core
import AgentSpec.Provenance.ResearchEntity
import AgentSpec.Provenance.ResearchActivity
import AgentSpec.Provenance.ResearchAgent
import AgentSpec.Provenance.RetiredEntity

/-!
# AgentSpec.Provenance.ProvRelationAuxiliary: PROV-O auxiliary relations + WasRetiredBy (Day 13、A-Minimal)

Phase 0 Week 4-5 Provenance 層の Day 13 構成要素。Day 11 で **PROV-O §4.1 main 3 relation**
(WasAttributedTo / WasGeneratedBy / WasDerivedFrom) を確立、Day 12 で **§4.4 RetiredEntity**
を完備、Day 13 で **§4.1 auxiliary 2 relation + §4.4 retirement relation** を Lean 化:

- `WasInformedBy` (Activity → Activity): "activity was informed by another activity" (PROV-O §4.1 auxiliary)
- `ActedOnBehalfOf` (Agent → Agent): "agent acted on behalf of another agent" (PROV-O §4.1 auxiliary)
- `WasRetiredBy` (Entity → RetiredEntity): "entity was retired by retirement event" (PROV-O §4.4 retirement relation、Day 12 で開いたパス)

これらは PROV-O §4.1 auxiliary relations (RDF triple) + §4.4 retirement event に対応し、
Lean では Day 11 ProvRelation パターン踏襲で separate structure 3 種を 1 ファイル統合配置。

## 設計 (Section 2.24 Q1-Q4 確定)

    structure WasInformedBy where
      activity : ResearchActivity
      informer : ResearchActivity

    structure ActedOnBehalfOf where
      agent : ResearchAgent
      on_behalf_of : ResearchAgent

    structure WasRetiredBy where
      entity : ResearchEntity
      retired : RetiredEntity

3 separate structure (Q3 案 B = 別 file 配置で main / auxiliary 構造化、Day 11 D3 を auxiliary
側で踏襲) で各 relation の semantic 区別を型レベルで強制 (Q4 案 A、TyDD-S1 + S4 P5)。

WasRetiredBy は Day 12 RetiredEntity を再利用 (entity → RetiredEntity 経由で retirement event を
relation として表現)、Day 11 ProvRelation 同パターン (Entity 経由 2-arg relation)。

## DecidableEq 省略 (Day 9-12 同パターン継続)

WasRetiredBy が RetiredEntity 経由で ResearchEntity recursive 制約継承、ActedOnBehalfOf /
WasInformedBy も将来 ResearchActivity / ResearchAgent への拡張時に同様の制約を回避するため
DecidableEq 省略 (一貫性確保)。Inhabited / Repr のみ deriving、DecidableEq 手動実装は Day 14+
検討 (Section 2.23 / 2.24 に記録)。

## 層依存性

- `AgentSpec.Provenance.ResearchEntity` (WasRetiredBy.entity field)
- `AgentSpec.Provenance.ResearchActivity` (WasInformedBy.{activity, informer} field)
- `AgentSpec.Provenance.ResearchAgent` (ActedOnBehalfOf.{agent, on_behalf_of} field)
- `AgentSpec.Provenance.RetiredEntity` (WasRetiredBy.retired field、Day 12 で確立)

Day 8-12 で確立した layer architecture 内 (Provenance 層内部)、新たな循環依存問題なし。
Day 12 D2 (separate structure 配置) の妥当性が WasRetiredBy 経由参照で確認される。

## TyDD 原則 (Day 1-12 確立パターン適用)

- **Pattern #5** (def Prop signature): structure 先行
- **Pattern #6** (sorry 0): structure + deriving + helper で完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化 + Day 10 v2 拡張済 (Provenance 検出可能)
- **Pattern #8** (Lean 4 予約語回避): `WasInformedBy` / `ActedOnBehalfOf` / `WasRetiredBy` / `informer` /
  `on_behalf_of` / `retired` は予約語ではない (PROV-O §4.1 / §4.4 命名規約準拠、snake_case 使用は
  Lean 4 で許容)

## Day 13 意思決定ログ

### D1. 3 separate structure 採用 + 別 file 配置 (Q3 案 B)
- **代案 A**: 既存 ProvRelation.lean に 3 structure 追加 (6 relation 1 ファイル)
- **代案 C**: 3 separate file (ProvRelationAuxiliary.lean + WasRetiredBy.lean 別ファイル)
- **採用**: 案 B 新 ProvRelationAuxiliary.lean 別 file (3 structure 統合配置)
- **理由**: main / auxiliary の semantic 区別が file 単位で明確、Day 11 D3 (1 ファイル統合配置)
  パターンを auxiliary 側で踏襲しつつ separate file で main/auxiliary 構造化。
  案 A は 1 ファイル大型化 (推定 250+ 行) / cohesion 低下、案 C は file 数増加 / D3 パターン非踏襲。

### D2. WasRetiredBy 引数 type = Entity → RetiredEntity (Q4 案 A)
- **代案 B**: `WasRetiredBy { entity : ResearchEntity, reason : RetirementReason }` (RetiredEntity flatten)
- **代案 C**: `WasRetiredBy { activity : ResearchActivity, retired : RetiredEntity }` (Activity 経由)
- **採用**: 案 A `WasRetiredBy { entity : ResearchEntity, retired : RetiredEntity }`
- **理由**: TyDD-S1 + Day 11 ProvRelation 同パターン (Entity 経由 2-arg relation)、Day 12 RetiredEntity
  再利用、entity 重複 (`wasRetired.entity` と `wasRetired.retired.entity`) は accessor で回避可能。
  案 B は Day 12 D2 (separate structure 配置) と矛盾、案 C は ResearchActivity.retire payload 拡充
  (Day 14+ 候補) と組合わせるべきで Day 13 scope 超過。

### D3. snake_case field name 採用 (`on_behalf_of`)
- **代案**: camelCase (`onBehalfOf`)
- **採用**: snake_case (`on_behalf_of`)
- **理由**: PROV-O §4.1 命名規約 (`actedOnBehalfOf` は予約語衝突なし、ただし Lean 4 で snake_case
  も許容、PROV-O semantic 直接対応)。代案 camelCase は Lean 4 慣習に近いが PROV-O 元仕様との
  対応が間接的になる。本 file では PROV-O 仕様忠実性を優先。
-/

namespace AgentSpec.Provenance

/-! ### `WasInformedBy`: Activity が別 Activity から通知された関係 (PROV-O §4.1 auxiliary) -/

/-- 02-data-provenance §4.1 PROV-O `wasInformedBy` (Activity → Activity)。

    "activity was informed by another activity" を表現。例: 検証 activity (verify) が
    調査 activity (investigate) から通知を受けた関係。 -/
structure WasInformedBy where
  /-- 通知された activity (informee)。 -/
  activity : ResearchActivity
  /-- 通知元 activity (informer)。 -/
  informer : ResearchActivity
  deriving DecidableEq, Inhabited, Repr

namespace WasInformedBy

/-- Smart constructor: activity と informer を直接指定。 -/
def mk' (activity : ResearchActivity) (informer : ResearchActivity) : WasInformedBy :=
  { activity := activity, informer := informer }

/-- 自明な fixture: trivial activity が trivial activity から通知された関係。 -/
def trivial : WasInformedBy :=
  { activity := ResearchActivity.trivial, informer := ResearchActivity.trivial }

end WasInformedBy

/-! ### `ActedOnBehalfOf`: Agent が別 Agent の代理として行動した関係 (PROV-O §4.1 auxiliary) -/

/-- 02-data-provenance §4.1 PROV-O `actedOnBehalfOf` (Agent → Agent)。

    "agent acted on behalf of another agent" を表現。例: Reviewer Agent が
    Researcher Agent の代理として行動した関係 (delegation)。 -/
structure ActedOnBehalfOf where
  /-- 代理として行動した agent (delegate)。 -/
  agent : ResearchAgent
  /-- 代理元 agent (delegator)。 -/
  on_behalf_of : ResearchAgent
  deriving DecidableEq, Inhabited, Repr

namespace ActedOnBehalfOf

/-- Smart constructor: agent と on_behalf_of を直接指定。 -/
def mk' (agent : ResearchAgent) (on_behalf_of : ResearchAgent) : ActedOnBehalfOf :=
  { agent := agent, on_behalf_of := on_behalf_of }

/-- 自明な fixture: trivial agent が trivial agent の代理として行動した関係。 -/
def trivial : ActedOnBehalfOf :=
  { agent := ResearchAgent.trivial, on_behalf_of := ResearchAgent.trivial }

end ActedOnBehalfOf

/-! ### `WasRetiredBy`: Entity が retirement event で退役された関係 (PROV-O §4.4 retirement relation) -/

/-- 02-data-provenance §4.4 PROV-O `wasRetiredBy` (Entity → RetiredEntity record)。

    "entity was retired by retirement event" を表現。Day 12 RetiredEntity を再利用、
    退役元 entity と RetiredEntity record (entity + reason) を 2-arg relation で結ぶ。

    例: Hypothesis entity が Failure 経由で退役された場合、
        `{ entity := .Hypothesis hyp, retired := { entity := .Hypothesis hyp, reason := .Refuted f } }` -/
structure WasRetiredBy where
  /-- 退役元 entity (退役される対象)。 -/
  entity : ResearchEntity
  /-- 退役 record (Day 12 RetiredEntity = entity + reason)。 -/
  retired : RetiredEntity
  deriving DecidableEq, Inhabited, Repr

namespace WasRetiredBy

/-- Smart constructor: entity と retired を直接指定。 -/
def mk' (entity : ResearchEntity) (retired : RetiredEntity) : WasRetiredBy :=
  { entity := entity, retired := retired }

/-- 自明な fixture: trivial entity が trivial RetiredEntity (Obsolete) で退役された関係。 -/
def trivial : WasRetiredBy :=
  { entity := ResearchEntity.trivial, retired := RetiredEntity.trivial }

end WasRetiredBy

end AgentSpec.Provenance

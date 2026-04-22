-- Spine 層: Reference (Day 72、DataCite relatedIdentifierType pattern 準拠)
-- Day 70 人間判断: List String → List Reference structured 化決定
-- Day 44 D2 deferred → Day 70 survey (74 先行研究 + DataCite/PROV-O) → Day 72 実装

/-!
# AgentSpec.Spine.Reference: structured citation type (Day 72、Spine 層)

Rationale.references を `List String` から `List Reference` に structured 化する
ための型定義。DataCite Metadata Schema 4.x の `relatedIdentifierType` enum を
参考に、agent-spec-lib に必要な 4 variant minimal で開始。

## 設計 (Day 70 人間判断、DataCite pattern)

    inductive Reference where
      | doi (id : String)       -- DOI identifier (e.g., "10.1145/12345")
      | url (uri : String)      -- URL (Issue/PR/page/resource)
      | arxiv (id : String)     -- arXiv identifier (e.g., "2604.14572")
      | commit (sha : String)   -- Git commit SHA

**Day 70 survey 根拠**:
- DataCite 4.x: 20+ relatedIdentifierType のうち DOI/URL/arXiv/Handle が主要
- Semantic Scholar API: externalIds dict (DOI/ArXivId/PMID/CorpusId)
- PROV-O: Qualified Terms は citation 未特化、generic Entity のみ
- 74 先行研究: 全 8 provenance システムで structured citation typing absent

4 variant は conservative extension で追加可能 (bibkey, isbn, pmid 等)。

## TyDD 原則

- **Pattern #5**: inductive 定義のみ (sorry 0)
- **Pattern #6**: deriving DecidableEq, Inhabited, Repr で完結
- **Pattern #7**: artifact-manifest 同 commit (hook 化済)
-/

namespace AgentSpec.Spine

/-- Structured citation/reference type (Day 72、DataCite pattern 準拠)。

    Rationale.references の要素型。`List String` から `List Reference` への
    breaking change migration で導入。各 variant は参照の種類を型で区別し、
    provenance theorem の前提条件として活用可能。 -/
inductive Reference where
  /-- DOI identifier (e.g., "10.1145/12345")。学術文献の永続識別子。 -/
  | doi (id : String)
  /-- URL (Issue / PR / page / resource)。Web 上のリソース参照。 -/
  | url (uri : String)
  /-- arXiv identifier (e.g., "2604.14572")。プレプリント参照。 -/
  | arxiv (id : String)
  /-- Git commit SHA。コード変更への参照。 -/
  | commit (sha : String)
  deriving DecidableEq, Inhabited, Repr

namespace Reference

/-- Reference から内部の文字列値を取得。 -/
def value : Reference → String
  | .doi id => id
  | .url uri => uri
  | .arxiv id => id
  | .commit sha => sha

end Reference

end AgentSpec.Spine

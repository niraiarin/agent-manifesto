# Knowledge Base Schema — todos.md 6 カテゴリ

Source: [S3 §3] AutoResearchClaw Knowledge Base

## カテゴリ

| Category | 目的 | 例 |
|----------|------|-----|
| **decisions** | 論文で下した判定（採用 / 却下 / 保留） | "K=3 を採用、K=16 以降は CONDITIONAL" |
| **experiments** | 実行した検証とその結果 | "pairwise vs individual: +10.9pp" |
| **findings** | 再利用可能な知見 | "bidirectional averaging が position bias を消す" |
| **literature** | 引用した外部/内部資料 | "[S2] PaperOrchestra arXiv:2604.05018" |
| **questions** | 未解決、後続で追う問い | "margin threshold の最適値は？" |
| **reviews** | 評価・批判・反証 | "AgentReview halt rule は recall を落とすが precision が高い" |

## Time Decay

- 30 日経過した `questions` は `$OUT/evidence/expired-questions.md` に退避
- 他カテゴリは decay しない（findings は永続）

## Schema (todos.md YAML front-matter)

```yaml
---
schema_version: "1"
generated_at: 2026-04-20T10:00:00Z
source_manifest: docs/papers/2026-04-20-verifier/manifest.json
decay_days: 30
---
```

カテゴリ本体は markdown リストで記述:

```markdown
## decisions
- [2026-04-20] K=3 を採用（K=16 plateau 検証、N=128 rounds）
  - source: commit 9159f62 / PR #636
  - compatibility: compatible change

## questions
- [2026-04-20] margin threshold 0.0 は実務で最適？
  - decay_at: 2026-05-20
  - discovered_in: paper §5
```

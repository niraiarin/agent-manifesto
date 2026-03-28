# manifest-trace CLI

全成果物と公理系（Lean `PropositionId`）の半順序トレーサビリティ。

## 前提

- `jq` がインストールされていること
- `artifact-manifest.json` がプロジェクトルートに存在すること
- `lean-formalization/Manifest/Ontology.lean` が存在すること（真実源）

## サブコマンド

### health — 全指標サマリ

```bash
./manifest-trace health
```

命題数、成果物数、種別分布、カバレッジ率、ファイル存在チェック。

### coverage — カバレッジギャップレポート

```bash
./manifest-trace coverage
```

各命題について、参照する成果物を種別ごとにカウント。
未カバー（実装なし）と弱カバレッジ（テストなし）を報告。

### trace — 順方向・逆方向トレース

```bash
./manifest-trace trace T6
./manifest-trace trace d13   # 小文字も可
```

指定した命題の:
- 上流（depends_on — 半順序の trunk 方向）
- 下流（depended_by — branch 方向）
- 実装成果物一覧

### violations — 半順序違反レポート

```bash
./manifest-trace violations
```

検査 1: 成果物が参照する命題の上流が他の成果物でカバーされているか。
検査 2: L1 を参照する成果物が structural enforcement を持つか。

### json — 構造的 JSON 出力

```bash
./manifest-trace json
./manifest-trace json | jq '.summary'
```

半順序 DAG を完全な JSON として出力。各命題ノードに:
- `strength` — 認識論的強度 (5=constraint → 1=designTheorem)
- `depends_on` — 上流命題
- `depended_by` — 下流命題
- `artifacts` — 実装成果物
- `coverage` — カバレッジ情報 (`total`, `by_type`, `has_test`, `has_implementation`)

jq クエリ例:

```bash
# テストのない命題
./manifest-trace json | jq '[.propositions[] | select(.coverage.has_test == false) | .id]'

# strength 3 以上で実装がない命題
./manifest-trace json | jq '[.propositions[] | select(.strength >= 3 and .coverage.has_implementation == false) | .id]'

# 被依存が最も多い命題（影響範囲が大きい）
./manifest-trace json | jq '[.propositions[] | {id, depended_by_count: (.depended_by | length)}] | sort_by(-.depended_by_count) | .[:5]'

# 未カバー命題の上流を確認
./manifest-trace json | jq '.propositions[] | select(.coverage.total == 0) | {id, depends_on}'
```

### graph — DOT 形式グラフ

```bash
./manifest-trace graph > trace.dot
dot -Tpng trace.dot -o trace.png   # Graphviz で可視化
```

### selfcheck — 自己検証

```bash
./manifest-trace selfcheck
```

Lean を真実源として manifest-trace 自身の正確性を検証:
1. 命題リスト同期（manifest ↔ Lean `PropositionId`）
2. refs の接地（全 refs が Lean に存在するか）
3. パーサ忠実性（2つの独立パーサで交差検証）
4. 内部整合性（重複 ID、プレフィックス一貫性、ファイル存在）

## --scope オプション

全サブコマンドで `--scope` を指定して対象を絞り込める。

```bash
./manifest-trace --scope=implementation coverage   # hooks/skills/agents/rules/tests のみ
./manifest-trace --scope=document health            # 文書のみ
./manifest-trace --scope=implementation,config json  # 実装+設定
./manifest-trace coverage                           # 全スコープ（デフォルト）
```

| scope | 対象 |
|-------|------|
| `implementation` | hooks, skills, agents, rules, tests |
| `config` | settings.json, settings.local.json |
| `document` | CLAUDE.md, README.md, docs/, research/ |
| `data` | .claude/metrics/*.jsonl, benchmark.json |

## データソース

| ファイル | 役割 |
|---------|------|
| `artifact-manifest.json` | 全成果物→公理マッピング（手動メンテナンス） |
| `lean-formalization/Manifest/Ontology.lean` | 命題定義・依存関係（真実源） |

成果物を追加・変更した場合は `artifact-manifest.json` を更新し、`selfcheck` で整合性を確認すること。

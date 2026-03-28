---
name: package-plugin
description: >
  現在の .claude/ 構成を Claude Code Plugin としてパッケージ化する。
  .claude/ の hooks, agents, skills, rules を自動収集し、hooks.json のパス相対化、
  plugin.json の生成、検証を一括で行う。
  「プラグイン化」「plugin package」「パッケージ」「配布」「plugin」で起動。
---

# Plugin Packager

.claude/ の構成を dist/agent-manifesto-plugin/ にパッケージ化する。

## このスキルが呼ばれたら

引数でバージョンが指定された場合はそれを使い、なければ自動 increment する。
以下のコマンドを実行する:

```bash
bash .claude/skills/package-plugin/scripts/package.sh {{args}}
```

実行後、結果を確認して以下を行う:

1. パッケージングスクリプトの出力を表示する
2. エラーがあれば修正を提案する
3. 成功したら `/verify` でパッケージを独立検証するか聞く
4. コミットする場合は互換性分類を付与する

## バージョニング

引数なし → 現在の patch を +1（e.g. 0.2.1 → 0.2.2）。
互換性分類に応じて明示的に指定する:
- conservative extension: patch（0.2.1 → 0.2.2）
- compatible change: minor（0.2.1 → 0.3.0）
- breaking change: major（0.2.1 → 1.0.0）

## スクリプトが行うこと

1. `.claude/hooks/*.sh` を全て収集してコピー
2. `.claude/settings.json` から hooks.json を自動生成（パスを `${CLAUDE_PLUGIN_ROOT}` に変換）
3. `.claude/agents/*.md` を全てコピー
4. `.claude/skills/*/SKILL.md` を全てコピー（package-plugin 自身と workspace は除外）
5. `.claude/rules/*.md` を全てコピー
6. plugin.json を生成（指定バージョン）
7. README.md を自動生成（コンポーネント数を自動カウント）
8. 検証: JSON 妥当性、参照整合性、絶対パスの不在

## artifact-manifest.json テンプレート

パッケージに `artifact-manifest.json` テンプレートを同梱する。
外部プロジェクトが `manifest-trace --manifest=<path>` で突合に使用する。

テンプレートは本リポジトリの `artifact-manifest.json` から propositions を継承し、
パッケージに含まれるコンポーネントを artifacts として登録する:

```json
{
  "version": "0.2.0",
  "parent": "agent-manifesto",
  "scopes": ["plugin"],
  "propositions": ["T1", "T2", ...],
  "artifacts": [
    {
      "id": "plugin-hook:<name>",
      "type": "hook",
      "path": ".claude/hooks/<name>.sh",
      "refs": ["L1", "T6"],
      "scope": "plugin"
    }
  ]
}
```

### 生成ルール

1. `propositions` は本リポジトリの全 36 命題をコピー
2. `artifacts` はパッケージに含まれる各コンポーネントから自動生成:
   - hook → `plugin-hook:<name>` (refs は hook 内のコメントから抽出、なければ空)
   - rule → `plugin-rule:<name>` (refs は rule 内の命題 ID から抽出)
   - skill → `plugin-skill:<name>`
   - agent → `plugin-agent:<name>`
3. `scope` は全て `"plugin"`
4. refs の自動抽出: ファイル内の `T[0-9]+|E[0-9]+|P[0-9]+|L[0-9]+|D[0-9]+` パターン

### manifest-trace との突合

```bash
# 外部プロジェクトで実行
manifest-trace --manifest=path/to/plugin/artifact-manifest.json coverage
manifest-trace --manifest=path/to/plugin/artifact-manifest.json --scope=plugin health
```

## D9 自己適用

このスキル自身の更新:
- .claude/ に新しいコンポーネント種別が追加された場合、scripts/package.sh を更新
- plugin.json のスキーマが変わった場合、スクリプトの生成部分を更新
- 新しい検証項目が必要になった場合、スクリプトの検証セクションに追加
- artifact-manifest.json のスキーマが変わった場合、テンプレート生成を更新

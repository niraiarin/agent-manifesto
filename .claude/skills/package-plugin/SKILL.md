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

## D9 自己適用

このスキル自身の更新:
- .claude/ に新しいコンポーネント種別が追加された場合、scripts/package.sh を更新
- plugin.json のスキーマが変わった場合、スクリプトの生成部分を更新
- 新しい検証項目が必要になった場合、スクリプトの検証セクションに追加

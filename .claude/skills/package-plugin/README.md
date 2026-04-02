# package-plugin

現在の `.claude/` 構成を Claude Code Plugin としてパッケージ化するスキル。

hooks, agents, skills, rules を自動収集し、hooks.json のパス相対化、
plugin.json の生成、検証を一括で行う。

## 起動トリガー

`/package-plugin` または「プラグイン化」「plugin package」「パッケージ」「配布」

## 出力

`dist/agent-manifesto-plugin/` にパッケージを生成する。

## ワークフロー

1. `package.sh` スクリプトを実行
2. 結果を確認・エラーがあれば修正提案
3. `/verify` で独立検証（オプション）
4. コミット時は互換性分類を付与

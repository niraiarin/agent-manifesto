# Vision Document: Safety Enforcement Plugin

## Source
G1 Observer: Source 5 (Cross-Project Patterns) — agent-manifesto の L1 safety hooks を汎用化

## What are you building?
Claude Code の全プロジェクトで使える安全性強制プラグイン。
agent-manifesto で実証済みの L1 hooks（破壊的操作の阻止、秘密ファイルの保護、テスト改竄防止）を、
任意の Claude Code プロジェクトにインストール可能なプラグインとして提供する。

## Who is it for?
Claude Code を使う全てのプロジェクト。特に:
- LLM に自律的なコード変更を許可しているチーム
- CI/CD パイプラインで Claude Code を使用しているプロジェクト
- セキュリティ要件が高いプロジェクト

## What matters most?
1. 破壊的操作（rm -rf, git push --force, git reset --hard）の事前阻止
2. 秘密ファイル（.env, credentials）のコミット防止
3. テストファイルの改竄・削除防止
4. 偽陽性の最小化（正当な操作をブロックしない）

## What does success look like?
- `claude-code-safety` プラグインをインストールすると、L1 相当の安全フックが即座に有効化
- 破壊的コマンドが実行前にブロックされ、人間に確認を求める
- プロジェクト固有の保護対象ファイルを設定可能
- 偽陽性率 < 5%

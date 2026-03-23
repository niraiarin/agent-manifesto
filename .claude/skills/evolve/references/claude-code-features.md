# Claude Code 機能リファレンス（/evolve 用）

/evolve が活用する Claude Code 機能の詳細リファレンス。
SKILL.md のコンテキスト経済（D11）のため、詳細はここに分離する。

## Agent Teams（実験的機能）

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` で有効化済み
- Team lead が Teammate を起動・管理
- 共有タスクリスト、エージェント間メッセージング
- `TeammateIdle` / `TaskCompleted` hook で品質ゲートを設置可能
- 表示モード: `in-process`（デフォルト）, `tmux`（分割ペイン）

## Skill フロントマター高度な機能

```yaml
---
context: fork        # フォークしたサブエージェントで実行（P2 コンテキスト分離）
agent: verifier      # context: fork 時のサブエージェント型
hooks:               # スキルスコープの hook（settings.json 変更不要）
  PostToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "bash scripts/record.sh"
allowed-tools:       # アクティブ時に使用可能なツールを制限
  - Read
  - Grep
---
```

## Hook ハンドラ型（4 種類）

| 型 | 用途 | /evolve での使い方 |
|----|------|-------------------|
| `command` | シェルコマンド | メトリクス収集、ファイルチェック |
| `http` | HTTP POST | 外部サービス連携（将来） |
| `prompt` | 単発 LLM yes/no 判定 | 品質ゲートの LLM ベース判定 |
| `agent` | サブエージェント起動 | 検証ゲートのエージェントベース判定 |

## Hook イベント（/evolve 関連）

| イベント | マッチャー | 用途 |
|---------|----------|------|
| `SessionStart` | `startup` | 前回の evolve 結果読み込み |
| `PostToolUse` | `Bash` | evolve commit の検出・記録 |
| `TeammateIdle` | — | Agent Teams の品質ゲート |
| `TaskCompleted` | — | 統合タスクの完了検証 |
| `SubagentStop` | — | Verifier 完了時の結果確認 |

## Dynamic Context Injection

SKILL.md 内で `` !`command` `` を使うと、スキル読み込み時にコマンドを実行し結果を注入:

```markdown
## 現在の構造状態
!`bash .claude/skills/evolve/scripts/observe.sh`
```

## Git Worktree 隔離

`isolation: worktree` を Agent 定義に指定すると、独立した git worktree で実行:

```yaml
---
isolation: worktree
---
```

- Integrator が worktree で変更を適用 → テスト通過 → main にマージ
- 失敗時は worktree を破棄（安全なロールバック）

## Structured Output

`--json-schema` フラグで Observer の出力を JSON スキーマで検証可能:

```bash
claude -p "observe the structure" --json-schema '{"type":"object","properties":{"lean":{"type":"object"},"tests":{"type":"object"}}}'
```

## Plugin パッケージ化

/evolve を Plugin としてパッケージ化し、他のプロジェクトに配布可能:

```
.claude-plugin/
├── plugin.json
├── skills/evolve/SKILL.md
├── agents/observer/AGENT.md
├── agents/hypothesizer/AGENT.md
├── agents/integrator/AGENT.md
├── hooks/hooks.json
└── scripts/observe.sh
```

## Effort Level

エージェントごとに effort を指定可能:

| エージェント | effort | 理由 |
|-------------|--------|------|
| Observer | high | 精密な計測が必要 |
| Hypothesizer | high | 創造的な設計が必要 |
| Verifier | high | 正確な検証が必要 |
| Integrator | high | 確実な統合が必要 |

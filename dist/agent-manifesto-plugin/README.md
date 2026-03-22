# agent-manifesto Plugin

マニフェスト準拠の AI エージェント統治を任意のプロジェクトに適用する Claude Code Plugin。

## インストール

```bash
claude plugin install /path/to/agent-manifesto-plugin --scope user
```

または GitHub から:

```bash
claude plugin install github:niraiarin/agent-manifesto --scope user
```

## 含まれるコンポーネント

### Hooks (Phase 1–4)

| Hook | Event | 機能 |
|------|-------|------|
| l1-safety-check.sh | PreToolUse: Bash | 破壊操作、インジェクション、認証情報漏洩をブロック |
| l1-file-guard.sh | PreToolUse: Edit/Write | テスト改竄、秘密ファイル、Hook 自己保護 |
| p2-verify-on-commit.sh | PreToolUse: Bash | 高リスクコミット時の検証警告 |
| p3-compatibility-check.sh | PreToolUse: Bash | 構造変更の互換性分類要求 |
| p4-metrics-collector.sh | PostToolUse (async) | ツール使用ログ収集 |
| p4-gate-logger.sh | SessionStart | セッションサマリ生成 |

### Skills

| Skill | 機能 |
|-------|------|
| /verify | P2: Subagent による独立コードレビュー |
| /metrics | P4: V1–V7 ダッシュボード |
| /adjust-action-space | D8: 行動空間の拡張/縮小提案 |
| /design-implementation-plan | D1–D9 の Provider マッピング |

### Agents

| Agent | 機能 |
|-------|------|
| verifier | P2: 読み取り専用の独立検証エージェント |

### Rules

| Rule | 機能 |
|------|------|
| l1-safety.md | L1 遵守義務（規範的補完） |
| p3-governed-learning.md | P3 学習ライフサイクルと互換性分類 |

## マニフェストとの対応

このプラグインは [agent-manifesto](https://github.com/niraiarin/agent-manifesto) の
設計開発基礎論（D1–D9）に基づいて構成されている。

- D1（強制のレイヤリング）: L1 = Hook（構造的）、L6 = Rules（規範的）
- D2（Worker/Verifier 分離）: verifier agent + /verify skill
- D3（可観測性先行）: metrics hooks + /metrics skill
- D4（漸進的自己適用）: Phase 1→2→3→4→5 の順序で構築
- D9（メンテナンス）: plugin.json の semver でバージョン管理

## 形式検証

公理系（41 axioms, 65 theorems, 0 sorry）は Lean 4 で機械検証済み。
`lean-formalization/` ディレクトリを参照。

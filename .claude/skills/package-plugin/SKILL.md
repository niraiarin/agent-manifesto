---
name: package-plugin
description: >
  現在の .claude/ 構成（hooks, agents, skills, rules, settings）を
  Claude Code Plugin としてパッケージ化する。plugin.json の生成、
  ディレクトリ構造の整理、Hook パスの相対化、バージョン管理を行う。
  「プラグイン化」「plugin package」「パッケージ」「配布」で起動。
---

# Plugin Packager

.claude/ の構成を、他のプロジェクトにインストール可能な
Claude Code Plugin としてパッケージ化する。

## なぜ Plugin 化するか

現在の .claude/ 構成はこのリポジトリ固有。Plugin にすることで:
- 任意のプロジェクトに `claude plugin install` でインストール可能
- バージョン管理（semver）により互換性分類（P3）が機械的に適用される
- 更新の配布が一箇所からできる

## 実行手順

### Step 1: 現在の .claude/ 構成を調査

以下を読み込み、Plugin に含めるべきコンポーネントを列挙する:

- `.claude/hooks/` — 全 hook スクリプト
- `.claude/agents/` — 全 agent 定義
- `.claude/skills/` — 全 skill（ただし package-plugin 自身は除外可能）
- `.claude/rules/` — 全 rule
- `.claude/settings.json` — hook 登録と permissions

### Step 2: Plugin ディレクトリ構造を生成

以下の構造を `dist/agent-manifesto-plugin/` に生成する:

```
agent-manifesto-plugin/
├── plugin.json              # Plugin マニフェスト
├── hooks/
│   ├── hooks.json           # Hook 登録（settings.json から抽出）
│   ├── l1-safety-check.sh
│   ├── l1-file-guard.sh
│   ├── p2-verify-on-commit.sh
│   ├── p3-compatibility-check.sh
│   ├── p4-metrics-collector.sh
│   └── p4-gate-logger.sh
├── agents/
│   └── verifier.md
├── skills/
│   ├── verify/SKILL.md
│   ├── metrics/SKILL.md
│   ├── adjust-action-space/SKILL.md
│   └── design-implementation-plan/SKILL.md
├── rules/
│   ├── l1-safety.md
│   └── p3-governed-learning.md
└── README.md                # Plugin の説明とインストール手順
```

### Step 3: plugin.json を生成

```json
{
  "name": "agent-manifesto",
  "version": "0.1.0",
  "description": "Manifest-compliant AI agent governance: L1 safety hooks, P2 verification, P3 governance, P4 observability, D8 equilibrium",
  "author": {
    "name": "niraiarin",
    "url": "https://github.com/niraiarin/agent-manifesto"
  },
  "repository": "https://github.com/niraiarin/agent-manifesto",
  "license": "MIT",
  "keywords": ["safety", "governance", "verification", "manifesto", "agent"],
  "agents": "./agents/",
  "skills": "./skills/",
  "hooks": "./hooks/hooks.json"
}
```

### Step 4: Hook パスの相対化

.claude/settings.json の hook コマンドは相対パス（`bash .claude/hooks/...`）だが、
Plugin では `${CLAUDE_PLUGIN_ROOT}` を使う必要がある:

```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/l1-safety-check.sh"
}
```

hooks.json にこの形式で全 hook を登録する。

### Step 5: README.md を生成

Plugin のインストール手順、含まれるコンポーネント、マニフェストとの対応を記述。

### Step 6: 検証

生成された Plugin 構造を検証する:
- [ ] plugin.json が有効な JSON か
- [ ] 全 hook スクリプトが存在し実行可能か
- [ ] hooks.json の参照先が全て存在するか
- [ ] agent/skill ファイルが全て存在するか
- [ ] Hook パスが `${CLAUDE_PLUGIN_ROOT}` を使っているか

### Step 7: /verify で独立検証（P2）

生成された Plugin を Verifier Subagent に検証させる。
Worker（このスキル）の成果物を独立したコンテキストでレビューする。

## 品質基準

- [ ] plugin.json が Claude Code Plugin の仕様に準拠している
- [ ] 全 hook が `${CLAUDE_PLUGIN_ROOT}` 相対パスを使用
- [ ] Phase 1–5 の全コンポーネントが含まれている
- [ ] L1 hook の自己保護が Plugin 構造でも有効か確認
- [ ] README にインストール手順が記載されている

## D9 自己適用

このスキル自身の更新:
- Plugin 仕様の変更時に更新
- .claude/ にコンポーネントが追加された時に Step 2 を更新
- 新しい hook/skill/agent が追加された場合、パッケージ対象リストを更新

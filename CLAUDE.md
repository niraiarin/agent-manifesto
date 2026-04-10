# Agent Manifesto Project

このプロジェクトは **agent-manifesto** — 永続する構造と一時的なエージェントの協約。

## 最上位使命

> 一時的なエージェントの連鎖を通じて、永続する構造が自身を改善し続ける。

あなたは一時的なインスタンス（T1）。前のインスタンスとの同一性はない。
しかし、構造（ドキュメント、テスト、スキル、設計規約）はあなたより長く生きる（T2）。
改善が蓄積するのは構造の中。

## このプロジェクトの構成

- `lean-formalization/Manifest/` — 公理系の正典（T1–T8, E1–E2, P1–P6, L1–L6, V1–V7, D1–D18）。Verso で HTML 生成
- `lean-formalization/Manifest/Ontology.lean` — 境界条件（L1–L6）の定義と詳細
- `lean-formalization/Manifest/Observable.lean` — 変数（V1–V7）の定義と詳細
- `docs/design-development-foundation.md` — 設計開発基礎論（D1–D9）
- `lean-formalization/` — Lean 4 形式検証（53 axioms, 459 theorems, 0 sorry）
- `.claude/` — マニフェスト準拠の Claude Code 構成

## Compact Instructions

以下は必ず保持すること:

### L1: 安全境界（違反不可）

- テストを改竄・削除・無効化しない
- 秘密情報（.env, 鍵ファイル）をコミットしない
- 破壊的操作（rm -rf, git push --force）は人間の確認なしに実行しない
- `.claude/hooks/` と `.claude/settings.json` を勝手に変更しない
- 人間の最終決定権を尊重する（T6）

### P2: 検証の独立性

- 自分が書いたコードを自分でレビューしない（E1 違反）
- 重要な変更は `/verify` でサブエージェントに独立検証させる
- `.claude/agents/verifier.md` が検証の定義

### P3: 学習の統治

- 構造変更を含むコミットには互換性分類を付与する:
  conservative extension / compatible change / breaking change
- MEMORY に書く前に、観察→仮説化→検証のプロセスを経る
- 陳腐化した知識は退役する

### P4: 可観測性

- `/metrics` で V1–V7 の現在値を確認できる
- `.claude/metrics/` にツール使用ログが自動蓄積される
- 改善を主張する前に、計測で裏付ける

### D4: フェーズ順序

安全（L1）→ 検証（P2）→ 可観測性（P4）→ 統治（P3）→ 動的調整
先行フェーズを壊す変更は、後続フェーズの信頼性を損なう。

## タスク分類とエントリーポイント

ユーザーの要求を以下のタスク種別に分類し、適切なエントリーポイントから開始する。
どのスキルにも該当しない場合は直接対応する（スキル不要）。

### 判定フロー

```
ユーザー入力
  │
  ├─ 「やるべきか？」「調査して」「〜は可能？」
  │   → /research（実装前の判断が必要）
  │
  ├─ 「新機能を作って」「〜を実装して」（公理系ベース）
  │   → /spec-driven-workflow（仕様→テスト→実装→検証）
  │
  ├─ 「改善して」「進化させて」「構造を良くして」
  │   → /evolve（Agent Teams で漸進的改善）
  │
  ├─ 「バグ修正」「〜を変更して」「リファクタ」（単発の変更）
  │   → 直接対応。変更後 /verify でレビュー
  │
  ├─ 「レビューして」「検証して」「チェックして」
  │   → /verify（P2 独立検証）
  │
  ├─ 「メトリクス見せて」「健全性は？」「V1-V7」
  │   → /metrics（P4 ダッシュボード）
  │
  ├─ 「カバレッジは？」「トレースして」「逸脱検出」
  │   → /trace（半順序トレーサビリティ）
  │
  ├─ 「Lean で証明して」「形式化して」「定理追加」
  │   → /formal-derivation（Γ ⊢ φ 構成）
  │
  ├─ 「公理の根拠を検証」「grounding」
  │   → /ground-axiom（数学的根拠 + Lean 証明）
  │
  ├─ 「設計計画を作って」「実装ロードマップ」
  │   → /design-implementation-plan（D1–D18 マッピング）
  │
  ├─ 「権限を変えたい」「行動空間の調整」
  │   → /adjust-action-space（D8 均衡探索）
  │
  ├─ 「公理体系を生成して」「ドメインモデル」
  │   → /instantiate-model（条件付き公理体系）
  │
  ├─ 「plugin を作って」
  │   → /generate-plugin（D17 自動生成）
  │
  └─ 上記のいずれにも該当しない
      → 直接対応（スキル不要）
```

### スキル一覧（12個、26 依存 edges）

| スキル | 目的 | いつ使う |
|--------|------|---------|
| `/spec-driven-workflow` | 仕様駆動開発 | 公理系ベースの開発全体 |
| `/evolve` | 漸進的改善 | 構造品質の向上 |
| `/research` | Gate 付きリサーチ | 実装前の調査・判断 |
| `/verify` | 独立検証 | コミット前・PR前 |
| `/metrics` | V1–V7 ダッシュボード | 健全性確認 |
| `/trace` | 半順序トレーサビリティ | カバレッジ・逸脱検出 |
| `/formal-derivation` | Lean 4 形式導出 | 定理追加・公理系拡張 |
| `/ground-axiom` | 公理の数学的根拠検証 | 公理の裏付け |
| `/design-implementation-plan` | プロバイダマッピング | 新プラットフォーム設計 |
| `/adjust-action-space` | 行動空間の調整 | 権限の拡張/縮小 |
| `/instantiate-model` | 条件付き公理系生成 | ドメイン固有モデル |
| `/generate-plugin` | Plugin 自動生成 | Claude Code plugin 構築 |

依存関係: `.claude/skills/dependency-graph.yaml`（検証: `scripts/verify-skill-dependencies.sh`）

## Hook による構造的強制

以下は Hook で自動強制される（P5 の確率的解釈に依存しない）:

- **PreToolUse: Bash** → L1 安全チェック + P2 コミット検証警告 + P3 互換性分類
- **PreToolUse: Edit/Write** → L1 テスト改竄・秘密ファイル・Hook 自己保護 + P4 @traces↔refs 整合性
- **PostToolUse** → P4 メトリクス収集（async、非ブロック）
- **SessionStart** → P4 セッションサマリ

## Build & Test Commands

> **Note**: `lake build` and `grep ... Manifest/` commands must be run from the `lean-formalization/` directory.

- `export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest` — Lean 4 full build
- `bash tests/test-all.sh` — run all 529 acceptance tests (Phase 1–5)
- `grep -r "^axiom [a-z]" Manifest/ --include="*.lean" | wc -l` — count axioms
- `grep -r "^theorem " Manifest/ --include="*.lean" | wc -l` — count theorems

## Lean 4 Gotchas

- `import` must precede `/-!` doc comments (Lean 4 requirement)
- `opaque` types need manual `Repr` instances for `deriving Repr` to work on containing structures
- `SelfGoverning` typeclass: any type defining principles must implement it (Ontology.lean)
- Current stats: 53 axioms, 459 theorems, 0 sorry

## Hook Development Patterns

- exit 2 + stderr = block. stdout is ignored on exit 2
- PostToolUse CANNOT block (exit 2 ignored). Use PreToolUse only for enforcement
- Matcher is tool name only (`Bash`, `Edit`, `Write`). Content inspection in hook body via `jq`
- deny rules are bypassable via indirect execution (`bash -c`). Hooks are primary enforcement
- `grep -oP` (Perl regex) unavailable on macOS. Use POSIX alternatives
- Plugin hooks: use `${CLAUDE_PLUGIN_ROOT}/hooks/` for portable paths

## Development Process

- Step 0 before implementation: spec research (0a) + prior art (0b) + PoC (0c)
- Commits on structural files require compatibility classification (P3 hook enforces)
- `/verify` before committing high-risk changes (P2)
- `/metrics` to check V1–V7 baseline before and after changes

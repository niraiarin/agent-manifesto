# Agent Manifesto

永続する構造と一時的なエージェントの協約。

> **永続する構造が、一時的なエージェントインスタンスの連鎖を通じて、自身を漸進的に改善し続けること。**

エージェントのセッションは一時的である。記憶は失われ、「自己」は連続しない。しかし、構造——ドキュメント、テスト、スキル、設計規約——はセッションを超えて永続する。改善が蓄積する場所は構造の中であり、エージェントはその触媒にすぎない。

## ドキュメント読み順

1. **[manifesto.md](manifesto.md)** — 公理系の原典。拘束条件（T1–T8）、経験的公準（E1–E2）、基盤原理（P1–P6）
2. **[lean-formalization/Manifest/Ontology.lean](lean-formalization/Manifest/Ontology.lean)** — 境界条件（L1–L6）の定義と詳細
3. **[lean-formalization/Manifest/Observable.lean](lean-formalization/Manifest/Observable.lean)** — 変数（V1–V7）の定義と詳細
4. **[docs/design-development-foundation.md](docs/design-development-foundation.md)** — 設計開発基礎論（D1–D9）。プラットフォーム非依存の設計原理
5. **[docs/implementation-boundaries.md](docs/implementation-boundaries.md)** — 実装判断基準。何をどう実装するかの選択指針

## ディレクトリ構造

```
├── manifesto.md                 # 公理系の原典
├── docs/                        # 派生ドキュメント
│   ├── design-development-foundation.md  #   設計開発基礎論
│   └── implementation-boundaries.md      #   実装判断基準
├── lean-formalization/          # Lean 4 形式検証
├── tests/                       # 受入テスト (Phase 1–5)
├── research/                    # 調査・参照資料
├── reports/                     # 生成レポート
├── archive/                     # 検証済み歴史的成果物 (PoC等)
├── .claude/                     # Claude Code 構成
│   ├── hooks/                   #   構造的強制 (L1安全, P2検証, P3統治, P4可観測)
│   ├── skills/                  #   /verify, /metrics, /adjust-action-space 等
│   ├── agents/                  #   verifier (P2独立検証)
│   └── rules/                   #   L1安全, P3学習統治
└── scripts/                     # 自動化スクリプト
```

## 三層公理系

### 拘束条件 (T) — 否定不可能な事実

| ID | 名称 | 内容 |
|----|------|------|
| T1 | セッションの一時性 | エージェントのセッションは終了し、記憶は継続しない |
| T2 | 構造の永続性 | ドキュメント・テスト・設計規約はセッションを超えて存続する |
| T3 | コンテキストの有限性 | 一度に処理できる情報量は有限である |
| T4 | 出力の確率性 | エージェントの出力は確率的であり、決定論的ではない |
| T5 | フィードバックの必要性 | 改善にはフィードバック機構が必要である |
| T6 | 人間の最終権限 | 人間がリソース配分の最終決定権を持つ |
| T7 | リソースの有限性 | タスク遂行に使えるリソースは有限である |
| T8 | 精度水準の要求 | タスクには要求される精度水準がある |

### 経験的公準 (E) — 繰り返し実証された知見

| ID | 名称 | 内容 |
|----|------|------|
| E1 | 検証の独立性 | 検証が有効であるためには、生成プロセスからの独立性が必要 |
| E2 | 能力とリスクの不可分性 | 能力の増加はリスクの増加と不可分である |

### 基盤原理 (P) — T/E から導出

| ID | 名称 | 根拠 |
|----|------|------|
| P1 | 自律と脆弱の共スケーリング | E2 |
| P2 | 認知的関心分離 | T4 + E1 |
| P3 | 統治された学習 | T1 + T2 |
| P4 | 可観測な劣化 | T5 |
| P5 | 構造の確率的解釈 | T4 |
| P6 | タスク設計の制約充足 | T3 + T7 + T8 |

## 形式検証

`lean-formalization/` に Lean 4 による形式検証を含む。

- **41 公理** (T: 13, E: 4, V: 24)
- **65+ 定理** (全て sorry-free)
- 内部整合性を機械的に証明

```bash
export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest
```

## Claude Code 連携

このリポジトリは Claude Code Plugin として利用可能。

**スキル:**
- `/verify` — P2 独立検証（Worker/Verifier 分離）
- `/metrics` — V1–V7 ダッシュボード
- `/adjust-action-space` — L4 行動空間の拡張/縮小提案
- `/design-implementation-plan` — D1–D9 のプロバイダマッピング
- `/package-plugin` — `.claude/` 構成を Plugin としてパッケージ化

**プラグイン化:**
```bash
bash scripts/package.sh
# -> dist/agent-manifesto-plugin/
```

## テスト

```bash
bash tests/test-all.sh    # 全 66+ 受入テスト (Phase 1–5)
```

| Phase | 対象 | 内容 |
|-------|------|------|
| 1 | L1 安全 | Hook 登録、破壊的操作ブロック |
| 2 | P2 検証 | Verifier エージェント、検証スキル |
| 3 | P4 可観測 | メトリクス収集、V1–V7 定義 |
| 4 | P3 統治 | 互換性分類、知識ライフサイクル |
| 5 | 動的調整 | 投資サイクル、L4 拡張/縮小 |

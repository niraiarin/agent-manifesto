# カバレッジテスト — 認識論的層モデルの検証パイプライン

Phase 0-3 の一気通貫テストを通じて、`EpistemicLayerClass` のインスタンシエーションが
多様なドメイン・構造パラメータで正しく動作することを検証する。

## テスト結果サマリ

| ラウンド | シナリオ範囲 | 生成方式 | BUILD PASS | VIOLATIONS | FAIL |
|---------|-------------|---------|------------|------------|------|
| Round 1 | S1-S300 | LLM (batch-1〜30) | 279 | — | 0 (+21 欠落) |
| Round 2 | S301-S500 | LLM Phase 0-3 (batch-31〜50) | 153 | 47 (意図的) | 0 |
| Synthetic | scenario001-100 | generate-test-scenarios.sh | 100 | 0 | 0 |

## ディレクトリ構成

```
test-coverage/
├── README.md                  # このファイル
├── run-coverage-test.sh       # オーケストレーター（セッション跨ぎ対応）
├── domains.txt                # 200+ ドメインリスト
├── prompts/                   # 自動生成されたバッチプロンプト
│   └── batch-{N}.prompt
├── batch-{1..50}.json         # LLM 生成シナリオ (各 10 件)
├── validate-batch-output.sh   # バリデーション（ID 範囲 + スキーマ）
├── model-spec-schema.json     # JSON Schema draft-07
├── extract-batch-json.py      # エージェント出力 → JSON 抽出
├── process-batch.sh           # パイプライン実行
├── run-batch.prompt           # LLM 用プロンプトテンプレート
└── generate-llm-scenarios.py  # プログラム的シナリオ生成（参考用）
```

```
../CoverageRound2/             # Round 2 パイプライン出力
├── s{N}.json                  # 個別シナリオ spec
└── S{N}.lean                  # 生成された Lean 4 コード (lake build 済み)
```

## パイプライン

```
Phase 0 (ビジョン)
  → Phase 1 (質問生成 + 回答シミュレーション)
  → Phase 2 (C/H 抽出 → 層推論 → 命題設計)
  → Phase 3 (ModelSpec JSON 出力)
  → バリデーション (validate-batch-output.sh)
  → 単調性チェック (check-monotonicity.sh)
  → Lean コード生成 (generate-conditional-axiom-system.sh)
  → 形式検証 (lake build)
```

## 再現方法

```bash
# Step 1: バッチプロンプト生成
bash run-coverage-test.sh generate --range 301-500

# Step 2: LLM エージェントにプロンプトを実行させ、batch-{N}.json として保存

# Step 3: バリデーション
bash run-coverage-test.sh validate --range 301-500

# Step 4: パイプライン実行
bash run-coverage-test.sh pipeline --range 301-500

# 進捗確認
bash run-coverage-test.sh status --range 301-500
```

## バリデーションツール

### validate-batch-output.sh

```bash
# 単一バッチのバリデーション
bash validate-batch-output.sh -f batch-31.json --range 301-310

# ディレクトリ全体のギャップ検出
bash validate-batch-output.sh --scan-dir . --total-range 1-500

# スキーマ厳密モード
bash validate-batch-output.sh -f batch-31.json --range 301-310 --strict
```

### extract-batch-json.py

```bash
# 基本使用
python3 extract-batch-json.py <agent-output> <output.json>

# 件数・範囲チェック付き
python3 extract-batch-json.py <agent-output> <output.json> --expected-range 301-310
```

## 設計判断

- **意図的単調性違反**: 各バッチに 1-2 件含める → パイプラインの拒否機能を検証
- **ドメイン多様性**: 200+ の独立ドメイン（医療、金融、交通、エネルギー等 14 カテゴリ）
- **構造パラメータ多様性**: 層数 2-7、命題数 5-20、依存密度可変
- **再現性**: `domains.txt` + `run-coverage-test.sh` でセッション跨ぎの再現が可能

---
name: verify
description: >
  P2 (Cognitive Separation of Concerns) の実装。Worker の成果物を独立した
  コンテキストで検証する。コード変更、設計文書、設定変更のレビューに使う。
  コミット前、PR 前、または品質に不安がある時に呼び出す。
  リスクレベルに応じて検証手段を選択する（Subagent / 人間レビュー / 別モデル）。
  「レビューして」「検証して」「verify」「チェックして」で起動。
---

# Verifier (P2: 評価検証の独立性)

Worker の成果物を独立した検証で評価する。

## 評価検証の独立性 — 4条件 (DesignFoundation.lean)

| 条件 | 意味 |
|------|------|
| **コンテキスト分離** | Worker の思考過程が Verifier に漏洩しない |
| **フレーミング非依存** | 検証基準が Worker のフレーミングに依存しない |
| **実行の自動性** | Worker が検証を回避できない |
| **評価者の独立** | Worker と異なる判断傾向を持つ主体が評価する |

## リスクレベル別の検証ルーティング

### Step 1: リスク判定

変更対象を見て、リスクレベルを判定する:

| リスク | 対象 | 例 |
|--------|------|-----|
| **critical** | L1 関連、セキュリティ、権限設定 | hooks, settings.json, 認証, 外部通信 |
| **high** | 構造変更 | アーキテクチャ, テスト, 設定, マニフェスト |
| **moderate** | 通常のコード変更 | ロジック, 新機能, バグ修正 |
| **low** | ドキュメント、コメント | README, docstring, コメント |

### Step 2: 検証手段の選択

| リスク | 必要条件数 | 検証手段 | 独立性の達成 |
|--------|----------|---------|------------|
| **critical** | 4 | **人間レビュー必須**。LLM の結果は参考のみ。人間が最終判断 | 4/4: 人間のみが保証 |
| **high** | 3 | **Local LLM / 別 API / 別 CLI** で評価者独立を達成。人間不要 | 3/4: 異なるモデルが評価者独立を充足 |
| **moderate** | 2 | **Subagent** で十分 | 2/4: コンテキスト分離 + 自動 |
| **low** | 1 | **Subagent** (手動起動でも可) | 1/4: コンテキスト分離のみ |

### 評価者の選択肢（Claude Code 環境）

| 評価者 | 評価者独立 | コスト | 検出力 | 適用 |
|-------|----------|-------|--------|------|
| 評価者 | 評価者独立 | 金銭コスト | 検出力 | レイテンシ | 前提条件 | 適用 |
|-------|----------|----------|--------|----------|---------|------|
| **Subagent（同一モデル）** | ❌ | API 料金（セッション内） | 高い | 5–30秒 | なし（常に利用可能） | moderate / low |
| **Local LLM（Ollama 等）** | ✅ | 電力のみ | モデル依存 | 10–120秒（モデルサイズ依存） | Ollama 起動済み、十分な VRAM/RAM（32B: ~20GB, 70B: ~40GB） | high |
| **別 API（OpenRouter / 直接）** | ✅ | API 料金（従量課金） | 高い | 5–30秒 | API キー設定済み、ネットワーク接続 | critical 補助 |
| **別 CLI（Codex 等）** | ✅ | Subscription | 高い | 10–60秒 | CLI インストール済み、認証済み | critical 補助 |
| **人間** | ✅ | 時間（分〜時間） | 最高 | 非同期（分〜日） | レビュー可能な人間が存在する | critical（必須） |

### 制約に基づく選択指針

- **即時フィードバックが必要**: Subagent（常に利用可能、最速）
- **コスト 0 で判断独立性が必要**: Local LLM（Ollama が起動していれば）
- **高い検出力 + 判断独立性**: 別 API（ネットワーク + API キーが前提）
- **最終的な安全保証**: 人間（非同期だが非代替）

Local LLM はハードウェア制約が最も厳しい（VRAM/RAM）。
別 API はネットワーク依存（オフライン環境では使えない）。
人間は最も信頼性が高いが最も遅い。
Subagent は制約が最も少ないが判断の独立性がない。

**可能な場合は複数の評価者を組み合わせる。** 単一の評価者に依存しない。

Local LLM は「コスト 0 で判断の独立性を得る」手段。
同一モデルの Subagent では検出できないパターンを異なるモデルが検出する場合がある（逆も）。
ただし、モデルの能力差に注意 — 検出力と判断の独立性はトレードオフになりうる。

### Step 3: 検証実行

**moderate/low の場合**: Verifier Subagent を起動する。

Subagent への指示（フレーミング非依存のため、Worker の意図説明を含めない）:

```
あなたは独立した Verifier です。以下のファイルを検証してください。
検証対象: [ファイルパスのリスト]
あなた自身の判断で、重要な問題を特定してください。
```

Worker が「何が正しいか」を Verifier に伝えない。Verifier が自分の基準で判断する。

**high の場合**: 評価者独立を達成する手段を1つ以上使う（人間不要）。
1. Local LLM が利用可能なら、Hook 経由または直接呼び出しで検証
2. 別 API が利用可能なら、OpenRouter 等で異なるモデルに検証を依頼
3. 別 CLI が利用可能なら、Codex 等で検証
4. いずれも利用不可なら、Subagent で検証し「評価者独立は未達」と明記する（フォールバック）

Local LLM 呼び出し例（Ollama）:
```bash
curl -s http://localhost:11434/api/generate \
  -d '{"model":"qwen3:32b","prompt":"Review these files for bugs and security issues: ...","stream":false}' \
  | jq -r '.response'
```

**critical の場合**: 多層検証を実施する。
1. Subagent（プロセス独立、参考）
2. Local LLM または別 API（評価者独立）
3. 人間レビュー（最終判断、必須）

別 API 呼び出し例（OpenRouter）:
```bash
curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"openai/gpt-4o","messages":[{"role":"user","content":"Review this code for security issues: ..."}]}'
```

別 CLI エージェント例（Codex CLI）:
```bash
codex -p "Review these files for security issues and bugs: $(git diff --cached)" --quiet
```

上記すべての結果を表示した上で:

```
⚠️ CRITICAL RISK: 人間によるレビューが必要です。
LLM の検証結果は参考情報です。最終判断は人間が行ってください。
```

### Step 4: 結果報告

Verifier の出力をそのまま報告する。Worker が結果を要約・解釈しない
（フレーミング非依存の維持）。

FAIL の場合は問題箇所をユーザーに提示し、判断を委ねる。

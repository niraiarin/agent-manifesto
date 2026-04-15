---
name: verify
user-invocable: true
description: >
  P2 (Cognitive Separation of Concerns) の実装。Worker の成果物を独立した
  コンテキストで検証する。コード変更、設計文書、設定変更のレビューに使う。
  コミット前、PR 前、または品質に不安がある時に呼び出す。
  リスクレベルに応じて検証手段を選択する（Subagent / 人間レビュー / 別モデル）。
  「レビューして」「検証して」「verify」「チェックして」で起動。
dependencies:
  invokes: []
  agents:
    - agent: verifier
      role: "Independent code/design review"
---
<!-- @traces P2, E1, D2, D1 -->

# Verifier (P2: 評価検証の独立性)

Worker の成果物を独立した検証で評価する。

## Lean 形式化との対応

| スキルの概念 | Lean ファイル | 定理/定義 |
|------------|-------------|----------|
| 4 条件の定義 | DesignFoundation.lean | `VerificationIndependence` |
| リスクレベル | DesignFoundation.lean | `VerificationRisk`, `requiredConditions` |
| Subagent は low のみ十分 | DesignFoundation.lean | `subagent_only_sufficient_for_low` |
| critical は 4 条件必須 | DesignFoundation.lean | `critical_requires_all_four` |
| E1 が直接の根拠 | DesignFoundation.lean | `d2_from_e1` |
| D10: 検証結果は構造に永続 | DesignFoundation.lean | `d10_agent_temporary_structure_permanent` |

## タスク自動化分類（TaskClassification.lean 準拠, #377/#378）

各ステップの `TaskAutomationClass` をデザインタイムに定義する。
実行時に LLM が毎回判断するコストを排除する（`designtime_classification_amortizes`）。

| ステップ | 分類 | 推奨実装手段 | 備考 |
|---|---|---|---|
| Step 1: リスク判定 | **deterministic + judgmental（未分離）** | LLM が直接実行 | deterministic: リスクマッピングテーブルの照合 / judgmental: 複合変更（hooks + docs 等）のリスク分類 |
| Step 2: 検証手段の選択 | **deterministic** | ルックアップテーブル | リスクレベル→検証手段は一意に決定される |
| Step 3: 検証実行 | **deterministic + judgmental（分離済み）** | スクリプト/コマンド（起動） + Verifier agent（レビュー） | `mixed_task_decomposition` 適用済み ✓: Subagent 起動は deterministic、レビュー自体は judgmental |
| Step 4: 結果報告 | **deterministic** | パススルー出力 | Verifier 出力をそのまま表示。Worker は解釈しない |
| Step 5: P2 トークン書き込み | **deterministic** | JSONL append コマンド | PASS/FAIL に基づく機械的書き込み |

**設計原則**:
- deterministic 成分は構造的強制で実行する（`deterministic_must_be_structural`）
- Step 2 のルックアップテーブルと Step 5 の JSONL 書き込みはスクリプト化候補
- judgmental タスク（Verifier のレビュー）を agent に委ねるのは適切（normative 層の本来の用途）

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

Lean 形式化はカウントモデル: 任意の N 条件を充足すれば十分（`satisfiedConditions >= requiredConditions`）。
どの条件を充足するかは問わない。

| リスク | 必要条件数 | 検証手段 | 独立性の達成例 |
|--------|----------|---------|------------|
| **critical** | 4 | **人間レビュー必須**。LLM の結果は参考のみ。人間が最終判断 | 4/4: 人間のみが保証 |
| **high** | 任意の 3/4 | **Subagent（hook 経由）** で 3 条件達成可能。または **Local LLM / 別 API** で評価者独立を含む 3 条件 | 例: コンテキスト分離 + フレーミング非依存 + 自動実行 |
| **moderate** | 任意の 2/4 | **Subagent（hook 経由）** で十分 | 例: コンテキスト分離 + 自動実行 |
| **low** | 任意の 1/4 | **Subagent** (手動起動でも可) | コンテキスト分離のみで十分 |

> **注意: 手動呼出し時の条件低下**
> Worker が手動で `/verify` を呼び出した場合、`executionAutomatic=false` となり、
> 充足条件数が 1 つ減る。手動 Subagent は `contextSeparated` のみ（1/4）のため、
> moderate 以上には不十分。Hook 経由の自動実行が推奨される。
> 手動呼出し時は充足条件の不足を結果に明記すること。

### 評価者の選択肢（Claude Code 環境）

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

**high の場合**: 任意の 3 条件を達成する手段を使う（人間不要）。
1. **Hook 経由 Subagent**（推奨）: contextSeparated + framingIndependent + executionAutomatic = 3/4 で十分
2. Local LLM が利用可能なら、evaluatorIndependent を加えて 3/4 以上を達成
3. 別 API / 別 CLI が利用可能なら、同様に evaluatorIndependent を含む 3/4 以上
4. **手動 Subagent**（フォールバック）: contextSeparated + framingIndependent = 2/4 で high に不十分。「3 条件未達」と明記する

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
# 安全なパターン: diff を一時ファイルに書き出してからパスを渡す
# $(git diff --cached) を直接引数に展開すると shell injection のリスクがある
git diff --cached > /tmp/verify-diff-$$.txt
codex -p "Review this diff for security issues and bugs. Diff file: /tmp/verify-diff-$$.txt" --quiet
rm -f /tmp/verify-diff-$$.txt
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

### Step 5: P2 検証トークンの書き込み

Verifier が **PASS** を返した場合、検証対象ファイルのリストを P2 トークンとして記録する。
これにより `p2-verify-on-commit.sh` が検証済みファイルのコミットを許可する。

**evaluator_type の判定:**

| 検証手段 | evaluator 値 | evaluator_independent |
|---------|-------------|----------------------|
| Subagent (Claude) | `"subagent/claude"` | `false` |
| Local LLM (Ollama 等) | `"ollama/<model>"` | `true` |
| 別 API | `"api/<provider>"` | `true` |
| 人間 | `"human"` | `true` |

```bash
# PASS の場合のみ実行
# evaluator と evaluator_independent は検証手段に応じて設定する
echo '{"epoch":'$(date +%s)',"files":["file1","file2",...],"verdict":"PASS","evaluator":"subagent/claude","evaluator_independent":false}' \
  >> .claude/metrics/p2-verified.jsonl
```

**Critical files** (`.claude/hooks/`, `.claude/settings.json`, `.claude/settings.local.json`) の
コミットには `evaluator_independent: true` のトークンが必要。
`p2-verify-on-commit.sh` が CRITICAL_PATTERNS で構造的に強制する。

**トークンの仕様:**
- 形式: JSONL（1 行 1 エントリ）
- TTL: 10 分（`p2-verify-on-commit.sh` が epoch ベースで検査）
- 場所: `.claude/metrics/p2-verified.jsonl`
- files: 検証対象の全ファイルパス（git diff --cached --name-only の出力に一致させる）
- evaluator: 検証手段の識別子（上記テーブル参照）
- evaluator_independent: 評価者が Worker と異なるモデルファミリか（VerificationIndependence）
- 後方互換: `evaluator_independent` フィールドがないトークンは `false` として扱われる

**FAIL の場合:** トークンを書き込まない。修正後に再度 /verify を実行する。

### D10 接続: 検証結果の構造化

D10（構造永続性）: 検証結果はエージェント消滅後も構造に残る。
- 検証で発見された問題は、修正コミットとして構造に永続化する
- 検証で PASS した事実は、`#print axioms` 出力として構造に残る
- 検証結果の要約は、コミットメッセージに含める

### V5 連携: 人間の承認/却下率

V5（`.claude/metrics/v5-approvals.jsonl`）は UserPromptSubmit hook が自動記録する人間の承認/却下率であり、verify スキルの Verifier pass rate (P2) とは異なる指標。verify の結果は P2 検証トークン（p2-verified.jsonl）に記録され、V5 は人間のセッション全体の操作を計測する。

## Traceability

| 命題 | このスキルとの関係 |
|------|-------------------|
| D2 | Worker と Verifier のコンテキスト分離により、生成と検証を独立した主体が実行する構造を実現 |
| D1 | リスクレベル→検証手段のルックアップテーブルと P2 トークン書き込みにより、検証ルーティングを LLM 判断に依存しない構造で強制 |

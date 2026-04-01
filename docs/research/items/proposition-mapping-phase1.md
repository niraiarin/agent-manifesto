# Phase 1 テスト→命題マッピング

Research #191, Sub-Issue #194

## マッピング手法

各テストの検証内容を分析し、対応する PropositionId を人間が判定した。
判定基準: テストが失敗した場合、どの命題の違反を示唆するか。

## Phase 1 Structural (S1.1–S1.10)

| ID | テスト内容 | Primary | Secondary | 根拠 |
|---|---|---|---|---|
| S1.1 | settings.json has hooks | D1 | L1 | D1: 構造的強制が存在する |
| S1.2 | PreToolUse Bash hook registered | D1 | L1 | D1: Bash 操作の構造的強制 |
| S1.3 | PreToolUse Edit hook registered | D1 | L1 | D1: Edit 操作の構造的強制 |
| S1.4 | PreToolUse Write hook registered | D1 | L1 | D1: Write 操作の構造的強制 |
| S1.5 | deny list has 10+ entries | L1 | T6 | L1: 安全境界の補助層。T6: 人間が設定した制限 |
| S1.6 | l1-safety-check.sh exists | L1 | D1 | L1: 安全チェックの実装が存在 |
| S1.7 | l1-file-guard.sh exists | L1 | D5 | L1: ファイルガードの実装。D5: テスト保護 |
| S1.8 | L1 rules file exists | L1 | D1 | L1: 規範的層（normative）の存在 |
| S1.9 | PostToolUse hooks are async-only | P4 | D11 | P4: 可観測性。D11: コンテキスト経済 |
| S1.10 | No absolute paths in hook commands | L5 | — | L5: プラットフォーム境界 |

## Phase 1 Behavioral — Bash hooks (B1.1–B1.8)

| ID | テスト内容 | Primary | Secondary | 根拠 |
|---|---|---|---|---|
| B1.1 | rm -rf / blocked | L1 | T6 | L1: 破壊的操作の阻止 |
| B1.2 | git push --force blocked | L1 | T6 | L1: 不可逆操作の阻止 |
| B1.3 | sudo blocked | L1 | — | L1: 権限昇格の阻止 |
| B1.4 | prompt injection blocked | L1 | — | L1: 外部指示の分離 |
| B1.5 | credential exfil blocked | L1 | — | L1: 秘密情報の外部送信禁止 |
| B1.6 | git add .env blocked | L1 | — | L1: 秘密情報のコミット禁止 |
| B1.7 | safe ls allowed | L1 | — | L1: 安全操作の許可（偽陽性なし） |
| B1.8 | safe git commit allowed | L1 | — | L1: 通常操作の許可 |

## Phase 1 Behavioral — File guard (B2.1–B2.5)

| ID | テスト内容 | Primary | Secondary | 根拠 |
|---|---|---|---|---|
| B2.1 | .env write blocked | L1 | — | L1: 秘密ファイルへの書き込み禁止 |
| B2.2 | skip pattern blocked | L1 | D5 | L1: テスト改竄禁止。D5: 仕様/テスト/実装の層 |
| B2.3 | hook self-modification blocked | L1 | D1 | L1: hook の自己保護。D1: 構造的強制の自己防御 |
| B2.4 | normal file edit allowed | L1 | — | L1: 正常操作の許可 |
| B2.5 | normal edit allowed | L1 | D5 | L1: 編集（改竄でない）の許可 |

## 分布分析

### 1テスト → N命題

| 命題数 | テスト数 | 割合 |
|---|---|---|
| 1 命題 | 10 | 43% |
| 2 命題 | 13 | 57% |

### N テスト → 1命題

| 命題 | Primary | Secondary | Total |
|---|---|---|---|
| L1 | 19 | 4 | 23 (100%) |
| D1 | 5 | 4 | 9 (39%) |
| T6 | 1 | 3 | 4 (17%) |
| D5 | 0 | 3 | 3 (13%) |
| L5 | 1 | 0 | 1 (4%) |
| P4 | 1 | 0 | 1 (4%) |
| D11 | 0 | 1 | 1 (4%) |

Phase 1 は L1（安全境界）に集中するのは設計通り。

## 方式比較と推奨

### 方式A: `# @traces` インラインアノテーション

```bash
# @traces L1,T6
check_block "B1.1 rm -rf / blocked" ...
```

- **利点**: 共配置原則（DbC）に従い、テストと命題IDが同一ファイル内に存在。保守性が高い。
- **制約**: L1 file-guard hook が behavioral テストファイルの編集時に、テストデータ内の危険パターン（`rm -rf`, `test.skip` 等）を誤検出し、Edit をブロックする。
- **回避策**: behavioral テストの `# @traces` は trace-map.json（方式B）で管理。または hook の誤検出を修正（テストデータ内の文字列リテラルを除外するロジック追加）。

### 方式B: `trace-map.json` 外部マッピングファイル

```json
{ "B1.1": { "primary": "L1", "secondary": ["T6"] } }
```

- **利点**: テストファイル非接触。L1 hook の誤検出を回避。jq で機械的に解析可能。
- **制約**: テストとマッピングが別ファイル — 乖離リスクがある。

### 方式C: 命名規則変更（不推奨）

- 全テストの改名が必要（breaking change）。利点が方式A/B を上回らない。

### 推奨

**方式A を基本、Phase 1 behavioral テストのみ方式B**。`trace-coverage.sh` が両方式を統合。

## 移行コスト見積もり

### Phase 1 実績（本 PoC）

| 作業 | テスト数 | 所要時間 | 1テストあたり |
|---|---|---|---|
| 命題マッピング判定（人間） | 23 | ~30 min | ~1.3 min |
| 方式A アノテーション追加 | 10 | ~5 min | ~0.5 min |
| 方式B trace-map.json 作成 | 23 | ~10 min | ~0.4 min |

### 全314テストへの展開推定

| 作業 | 推定工数 | 根拠 |
|---|---|---|
| 命題マッピング判定 | ~6.5 時間 | 291 × 1.3 min。Phase 2-5 は Phase 1 より複雑（multiple propositions per test が増える見込み） |
| アノテーション付与 | ~2.5 時間 | 291 × 0.5 min（方式A）。方式B のみなら ~2 時間 |
| trace-coverage.sh の拡張 | ~0.5 時間 | 既存スクリプトは全 Phase 対応済み |
| 検証・修正 | ~1.5 時間 | カバレッジレポートの確認と修正 |
| **合計** | **~11 時間** | 自動化率: アノテーション付与は自動化可能。判定のみ人間が必要 |

### 自動化可能な部分

- テストID抽出: `grep -o '"[A-Z][A-Z0-9]*\.[0-9]*'` で機械的に可能（実装済み）
- Phase→命題の初期推定: Phase 番号と命題カテゴリの対応（Phase 1→L1, Phase 2→P2 等）から初期値を自動生成し、人間が修正する方式
- カバレッジレポート: `scripts/trace-coverage.sh` で完全自動化済み

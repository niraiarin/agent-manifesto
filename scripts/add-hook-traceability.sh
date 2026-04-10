#!/usr/bin/env bash
# add-hook-traceability.sh — hook ファイルにトレーサビリティコメントを追加
# 人間が実行: bash scripts/add-hook-traceability.sh
set -euo pipefail
BASE="$(git rev-parse --show-toplevel)"
H="$BASE/.claude/hooks"

add_trace() {
  local file="$1"; shift
  local comment="$*"
  if grep -qF "Traceability:" "$file" 2>/dev/null; then
    echo "SKIP (already present): $(basename "$file")"
    return
  fi
  # ファイル末尾に追加
  printf '\n# Traceability:\n%s\n' "$comment" >> "$file"
  echo "DONE: $(basename "$file")"
}

add_trace "$H/l1-safety-check.sh" \
  "# T6: 人間の資源権限 — 破壊的操作は人間の確認を要求する（exit 2 で T6 を構造的に強制）" \
  "# T7: 資源有限性 — rm -rf 等の資源破壊コマンドを検出しブロック"

add_trace "$H/l1-file-guard.sh" \
  "# T1: セッション有界性 — テスト改竄・秘密ファイルの書き込みを阻止し、セッション間の構造整合性を保護"

add_trace "$H/p2-verify-on-commit.sh" \
  "# E1: 検証独立性 — P2 検証トークンの有無で、独立検証を経たコミットかを判定" \
  "# D2: 認知的関心の分離 — 生成（Worker）と検証（Verifier）が分離されていることをコミット時に強制"

add_trace "$H/p3-compatibility-check.sh" \
  "# D13: 影響波及 — 互換性分類（conservative/compatible/breaking）により変更の波及範囲を明示させる"

add_trace "$H/p4-metrics-collector.sh" \
  "# D3: 可観測性先行 — ツール使用ログを自動収集し、V2/V4 の計測基盤を提供"

add_trace "$H/p4-drift-detector.sh" \
  "# T5: フィードバック必要性 — 承認率の経時変化を検出し、劣化時にフィードバックループを発動" \
  "# D3: 可観測性先行 — ドリフト検出は改善の前に計測が存在することを前提とする"

add_trace "$H/p4-gate-logger.sh" \
  "# L6: 退役境界 — Gate 通過/失敗を記録し、退役判定の定量的根拠を蓄積"

add_trace "$H/p4-temporal-tracker.sh" \
  "# T1: セッション有界性 — セッション開始/終了時刻を記録し、T1 の実測データを提供"

add_trace "$H/p4-v5-approval-tracker.sh" \
  "# P4: 可観測性 — 人間の承認/却下を自動記録し V5 を計測可能にする" \
  "# T6: 人間の資源権限 — 人間の判断（承認/却下）をログに永続化" \
  "# D3: 可観測性先行 — V5 の計測基盤として機能" \
  "# V5: 人間承認率 — 承認/却下の比率を直接計測"

add_trace "$H/p4-v7-task-tracker.sh" \
  "# P4: 可観測性 — タスク設計の自動化率を記録し V7 を計測可能にする" \
  "# D3: 可観測性先行 — V7 の計測基盤として機能" \
  "# V7: タスク設計効率 — deterministic/mixed/judgmental の分類比率を計測"

add_trace "$H/hallucination-check.sh" \
  "# L2: 情報整合境界 — 参照ファイルの実在性を検証し、幻覚（存在しないファイルへの参照）を検出"

add_trace "$H/evolve-metrics-recorder.sh" \
  "# P4: 可観測性 — /evolve の各フェーズ結果を evolve-history.jsonl に自動記録" \
  "# D3: 可観測性先行 — 改善の成果を計測可能にする基盤" \
  "# D9: 自己適用 — /evolve 自身のメトリクスを記録し、スキル改善の入力にする"

add_trace "$H/evolve-state-loader.sh" \
  "# P3: 学習の統治 — /evolve セッション開始時に前回の状態を復元し、学習の継続性を保証" \
  "# T2: 構造永続性 — evolve-history.jsonl から構造に蓄積された学習履歴を読み出す" \
  "# D10: 構造永続性 — エージェント消滅後も構造（ログ）が残ることを前提に状態復元を実現"

add_trace "$H/h5-doc-lint.sh" \
  "# D5: 仕様層の順序 — ドキュメントの書式整合性を検証し、仕様の品質を構造的に維持" \
  "# D1: 構造的強制 — lint ルールを hook で自動実行し、LLM の判断に依存しない品質保証"

add_trace "$H/p4-sync-counts-check.sh" \
  "# D3: 可観測性先行 — axiom/theorem/sorry カウントの同期状態を検証し、計測値の正確性を保証"

add_trace "$H/p4-manifest-refs-check.sh" \
  "# D1: 構造的強制 — artifact-manifest.json の refs が ontology の命題に存在するか自動検証"

add_trace "$H/p4-traces-integrity-check.sh" \
  "# D13: 影響波及 — @traces と refs の不一致を検出し、traceability の破壊がコミットされることを防止"

echo ""
echo "All hooks annotated. Run: bash scripts/detect-refs-body-violations.sh"

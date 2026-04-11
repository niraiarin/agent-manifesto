import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions

/-!
# Claude Code 条件付き公理系: データスキーマ契約 (#404)

JSON/YAML/JSONL の使い分け、スキーマ間の依存関係、
命名規則を条件付き公理として構造化する。

## 反証トリガー

データ形式方針の変更、新しいデータファイル追加時に再検証対象。

## 設計方針

- 手書き
- 0 sorry を維持
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest

-- ============================================================
-- データ形式の型定義
-- ============================================================

/-- プロジェクトで使用するデータ形式。CC-H38 に基づく。 -/
inductive DataFormat where
  | json   -- 構造化設定、マニフェスト（mutable）
  | yaml   -- 宣言的定義（dependency-graph 等）
  | jsonl  -- 時系列ログ（append-only）
  deriving BEq, Repr

/-- データ形式の更新パターン。 -/
inductive UpdatePattern where
  | mutable     -- 読み書き可能、上書き更新
  | appendOnly  -- 追記のみ、既存エントリは不変
  | readOnly    -- 読み取り専用
  deriving BEq, Repr

-- ============================================================
-- DS1: データ形式と更新パターンの対応
-- ============================================================

/-- 形式→更新パターンのマッピング。 -/
def formatUpdatePattern : DataFormat → UpdatePattern
  | .json  => .mutable     -- settings.json, instance-manifest.json 等
  | .yaml  => .mutable     -- dependency-graph.yaml
  | .jsonl => .appendOnly  -- evolve-history.jsonl, p2-verified.jsonl 等

/-- [Derivation Card]
    Derives from: CC-H38
    Proposition: DS1
    Content: JSONL files are append-only by convention.
      This ensures temporal ordering is preserved and
      concurrent writes don't corrupt existing entries.
    Proof strategy: rfl -/
theorem ds1_jsonl_append_only :
  formatUpdatePattern .jsonl = .appendOnly := by rfl

-- ============================================================
-- DS2: スキーマ間の書き込み元と読み取り先
-- ============================================================

/-- メトリクスデータファイル。 -/
inductive MetricsFile where
  | evolveHistory    -- evolve-history.jsonl
  | p2Verified       -- p2-verified.jsonl
  | deferredStatus   -- deferred-status.json
  | toolUsage        -- tool-usage.jsonl
  | v5Approvals      -- v5-approvals.jsonl
  deriving BEq, Repr

/-- 書き込み元の分類。CC-H36 に基づく。 -/
inductive WriterKind where
  | postToolUseHook  -- PostToolUse hook（自動、非ブロック）
  | preToolUseHook   -- PreToolUse hook（自動、ブロック可能）
  | skill            -- スキル実行中に明示的書き込み
  | script           -- スクリプト実行
  deriving BEq, Repr

/-- メトリクスファイルの書き込み元。 -/
def metricsWriter : MetricsFile → WriterKind
  | .evolveHistory  => .postToolUseHook  -- evolve-metrics-recorder.sh
  | .p2Verified     => .skill            -- /verify スキルが PASS 時に書き込み
  | .deferredStatus => .script           -- observe.sh 等で更新
  | .toolUsage      => .postToolUseHook  -- p4-metrics-collector.sh
  | .v5Approvals    => .preToolUseHook   -- p4-v5-approval-tracker.sh (UserPromptSubmit)

/-- [Derivation Card]
    Derives from: CC-H36, CC-C28
    Proposition: DS2
    Content: evolve-history.jsonl is written by PostToolUse hook, not by observe.sh.
      p2-verified.jsonl is written by /verify skill.
      Understanding writer identity is critical for schema evolution.
    Proof strategy: constructor with rfl -/
theorem ds2_writer_identity :
  metricsWriter .evolveHistory = .postToolUseHook ∧
  metricsWriter .p2Verified = .skill := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- DS3: P2 トークンの TTL
-- ============================================================

/-- P2 検証トークンの TTL（秒）。CC-C28 に基づく。 -/
def p2TokenTTL : Nat := 600

/-- [Derivation Card]
    Derives from: CC-C28
    Proposition: DS3
    Content: P2 verification tokens have a 10-minute TTL (600 seconds).
      Tokens older than TTL are treated as expired.
      This ensures verification is temporally close to the commit.
    Proof strategy: rfl -/
theorem ds3_p2_ttl_10min :
  p2TokenTTL = 600 := by rfl

end Manifest.Models.Instances.ClaudeCode

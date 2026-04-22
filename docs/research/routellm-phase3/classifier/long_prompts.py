#!/usr/bin/env python3
"""
long_prompts.py — Gap 4: 長文 prompt variants.

訓練 prompt の平均長は 60-200 chars (短文中心)、実 prompt は 2000+ chars と
domain shift がある。各 taxonomy task に 1500-2500 chars の長文版を追加。
system-prompt 込み の形式 (CLAUDE.md 先頭 500 chars + task prompt) を模擬。
"""

# 共通の system prompt stub (CLAUDE.md の核心を模擬)
SYSTEM_STUB = """あなたは agent-manifesto プロジェクトの一時的エージェント。
永続する構造（ドキュメント、テスト、スキル、設計規約）を改善することが使命。
L1 安全境界: テスト改竄禁止、秘密情報 commit 禁止、破壊的操作は人間確認必須。
P2 検証独立性: 自分が書いたコードを自分でレビューしない。
P3 学習統治: 構造変更の commit に互換性分類を付与。
D4 フェーズ順序: 安全→検証→可観測性→統治→動的調整。
"""


LONG_FORM_PROMPTS = [
    # === local_probable (metrics/trace/observer/paperize-writing) 各 2 件 ===

    ("metrics-interp-long", "local_probable",
     SYSTEM_STUB + """
## タスク: M-interp

以下は /metrics (observe.sh) の出力です:

```json
{
  "V1_skill_quality": {"graduation": true, "non_triviality": {"score": 0, "label": "trivial"}, "saturation": "ok", "consecutive_zero_delta": 2},
  "V2_context_efficiency": {"tool_calls": 62028, "sessions": 1699, "recent_avg": 46, "cumulative_avg": 40, "trend": "stable", "divergence_percent": 15},
  "V3_output_quality": {"test_pass_rate": 1.0, "gate_capture_rate": 1.0, "hallucination_proxy_active": {"observer_error": 3, "hypothesis_error": 36}},
  "V4_gate_pass_rate": {"pass_rate": 0.99, "blocked": 106},
  "V5_proposal_accuracy": {"approval_rate": 0.96, "approved": 162, "total": 168, "schema_drift": false},
  "V6_knowledge_structure": {"memory_entries": 12, "last_update_days_ago": 0, "orphan": 0},
  "V7_task_design": {"completed": 188, "unique_subjects": 180, "teamwork_percent": 0},
  "valueless_change": {"streak": 4, "halt_recommended": true},
  "failure_patterns": {"unresolved_total": 55, "hypothesis_error": 36, "assumption_error": 7, "precondition_error": 5},
  "scope_balance": {"meta_runs": 8, "substance_runs": 7, "bias_warning": false}
}
```

このメトリクスを分析し、以下を日本語で構造化して出力:
1. 全体評価 (HEALTHY / WARNING / DEGRADED) + 一言根拠
2. V1-V7 各指標の解釈 (現在値が良好か注意か)
3. 改善提案 優先度順 最大 3 件

判断根拠は valueless_change streak、non_triviality score、failure_patterns の未解決数から導出せよ。
D13 影響波及を考慮した優先度付けで。"""),

    # 長文 trace-interp
    ("trace-interp-long", "local_probable",
     SYSTEM_STUB + """
## タスク: T-interp

以下は /trace (manifest-trace json) の出力:

```json
{
  "coverage": {"total_propositions": 53, "covered": 48, "uncovered": ["D15", "D16", "D17", "D18", "E2"], "coverage_rate": 0.906},
  "deviations": [
    {"artifact": ".claude/skills/evolve/SKILL.md", "refs_claimed": ["D13"], "traces_found": ["D13", "D9"], "mismatch": "extra D9"},
    {"artifact": "tests/phase5/test-evolve-structural.sh", "refs_claimed": ["P3"], "traces_found": [], "mismatch": "missing"}
  ],
  "partial_order": {"nodes": 53, "edges": 127, "max_depth": 4, "hub_propositions": ["D13", "P2", "T6"]}
}
```

このレポートを解釈して:
1. カバレッジ状況の summary (数値 + 未カバー命題の意味論的分類)
2. ギャップ分析 — D13 影響波及の観点で、最も重要なカバレッジギャップはどれか、その影響を受ける下流命題は何か
3. 改善提案 優先度順 最大 3 件

未カバーの D15-D18 は条件付き形式化関連、E2 は epistemic 層関連。
hub propositions (D13, P2, T6) の周辺影響を考慮せよ。"""),

    # 長文 observer
    ("observer-long", "local_probable",
     SYSTEM_STUB + """
## タスク: Observer Agent Phase 1

以下は最新の evolve-history.jsonl 抜粋 + deferred-status.json + recent git log です。

```jsonl
{"type": "evolve_entry", "run": 108, "phase": "observe", "findings": ["valueless_change streak 3", "V5 approval_rate 96%"]}
{"type": "evolve_entry", "run": 109, "phase": "hypothesize", "rejected": 2, "reason": "trivially_true"}
{"type": "human_feedback", "notes": "P2 verify の dispatch が遅い、subagent spawn overhead"}
{"type": "evolve_entry", "run": 110, "phase": "integrate", "compatibility": "compatible_change", "files_changed": 7}
```

```json
{"items": {"D17_state_machine_runtime": {"status": "open", "reason": "dependencyBlocked", "depends_on": "#598"}}}
```

git log (最新 10 件):
- 16222ec research: Causal LM router PoC (#649)
- 8b4e1cc research: Local LLM routing — Sub-3 BF16 (#594)
- fcb8741 feat: /paperize skill autonomous research (#642)
...

Observer として以下を出力。**判断・提案はしない、観察のみ**:
- 直近 5 run の phase distribution
- 未解決 deferred items (#件数 + 主要理由)
- git commit の scope balance (meta vs substance)
- 停滞シグナルの有無 (valueless_change streak 等)
- 改善候補 (観察されたパターンのみ列挙、TaskClassification [D]/[B]/[J] タグ付き)

判断・提案・優先度付けは一切行わない。"""),

    # 長文 paperize writing
    ("paperize-writing-long", "local_probable",
     SYSTEM_STUB + """
## タスク: /paperize Writing Agent — Method section

### Outline
```json
{
  "title": "Local LLM Routing for Claude Code Skills",
  "sections": [
    {"heading": "Motivation", "key_claims": ["cost reduction", "context pass-through via ccr"]},
    {"heading": "Method", "key_claims": ["golden dataset 55 items", "judge Claude Opus", "BF16 qwen3.6-35b"]},
    {"heading": "Experiments", "key_claims": ["M-interp 90% pass", "T-interp 84% pass"]},
    {"heading": "Findings", "key_claims": ["3-factor model: active params x quant x distill"]}
  ]
}
```

### Evidence (抜粋)
- commit e1da87b: Sub-2/3 比較実験基盤 construction
- commit df966c7: BF16 統一 55/55 完成 (M-interp avg delta 0.29, T-interp 0.096)
- commit d15182b: Sub-4 RouteLLM preference data 生成 (55 items x 2 thresholds)
- PR #598 (merged): Sub-2/3 scaffold, Sub-1 #592 PASS (ccr + tool calling)
- PR #595: context pass-through 発見 (eval "$(ccr activate)" で CLAUDE.md が system prompt 注入)

### 指示
Method セクションを single-pass で執筆。未検証事実は [UNVERIFIED] タグ付与。
内部 citation は 8-char SHA 付き (commit `xxxxxxxx` / PR #N)。
ページ予算 2 pages (約 1500 words)。
言語: 日本語。"""),

    # === cloud_required long === (important to have Cloud long prompts in training)
    ("verify-long", "cloud_required",
     SYSTEM_STUB + """
## タスク: /verify — 独立検証

以下の PR 差分を独立検証してください。K=3 rounds で pairwise 判定。
L1 safety 違反、manifesto 公理からの逸脱、P2 evaluator_independent 違反を全て列挙。

### PR #NNN 差分

```diff
diff --git a/.claude/hooks/p2-verify-on-commit.sh b/.claude/hooks/p2-verify-on-commit.sh
index abc123..def456 100755
--- a/.claude/hooks/p2-verify-on-commit.sh
+++ b/.claude/hooks/p2-verify-on-commit.sh
@@ -10,6 +10,10 @@ BASE="$(git rev-parse --show-toplevel)"
+HIGH_RISK_BYPASS_PATTERN="bypass-p2"
+if git log -1 --format=%B | grep -q "$HIGH_RISK_BYPASS_PATTERN"; then
+  echo "[p2-verify] bypass requested, skipping"
+  exit 0
+fi
```

### 評価軸
1. Safety (L1): この bypass mechanism が T6 を損なわないか
2. Correctness (P2): evaluator_independent の構造的強制を崩さないか
3. Compliance: マニフェスト P2 との整合性

K=3 rounds + bidirectional averaging で pairwise 評価。
各 round の根拠を記録し、final verdict は PASS / FAIL / CONDITIONAL。"""),

    ("formal-derivation-long", "cloud_required",
     SYSTEM_STUB + """
## タスク: /formal-derivation

以下の要件から Γ ⊢ φ を Lean 4 で構成せよ。

### Γ (前提集合)
- `axiom ccr_forwards_system_prompt (m : Model) : CCR_activated → ∀ p : Prompt, system_prompt_transferred p m`
- `axiom qwen36_acceptable_quality_for_M_interp : avg_delta_M_interp qwen36 ≤ 0.5`
- `def Router := Prompt → Model`

### φ (目標命題)
`∀ p : Prompt, task_is_M_interp p → ∃ r : Router, r p = qwen36 ∧ quality_acceptable (r p) p`

### 制約
- axiom を最小化（上記 2 個のみ使用）
- sorry 禁止
- 証明の各 step に @traces でマニフェスト命題への reference を付与
- Phase 2 で derivation composition、Phase 3 でエラー反復修正

### 出力
```lean
-- Phase 1: domain + goal
def qwen36 : Model := ...
def task_is_M_interp (p : Prompt) : Prop := ...

-- Phase 2: derivation
theorem router_exists_for_M_interp : <goal> := by
  ...

-- Phase 4c: formalization gap verification
-- Public API <-> proof の逆方向 traceability
```"""),

    # === hybrid long ===
    ("qa-long", "hybrid",
     SYSTEM_STUB + """
Python で asyncio を使ったサーバーを書いているのですが、CPU-bound な処理を
混ぜたときにイベントループがブロックされてしまいます。

具体的には以下のような状況:

```python
import asyncio

async def handle_request(req):
    data = await fetch_from_db(req.id)
    # ここで 2 秒かかる CPU 計算
    result = heavy_numeric_analysis(data)
    return await render_response(result)
```

heavy_numeric_analysis は numpy の行列演算を含む 2 秒の純粋 CPU 処理です。
これを loop.run_in_executor(ThreadPoolExecutor, ...) で逃がすべきか、
ProcessPoolExecutor に逃がすべきか、あるいは別の approach か、教えてください。
同時接続 100 リクエスト程度を想定しています。GIL の影響、プロセス間通信の
オーバーヘッド、numpy の GIL 挙動も含めて説明お願いします。"""),
]

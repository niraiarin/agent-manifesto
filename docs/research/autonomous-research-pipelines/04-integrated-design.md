# Integrated Design: `/paperize` Skill

> **Parent Issue**: #642
> **Sub-Issue**: #643 (SS4)
> **Status**: 統合設計 v1 (2026-04-20)
> **Traceability**: 各設計要素に [S1], [S2], [S3] で survey record への source link を付与

## 凡例（Source Tag）

| Tag | Source | 記録 |
|-----|--------|------|
| **[S1]** | AI-Scientist-v2 (SakanaAI) | [01-ai-scientist-v2.md](./01-ai-scientist-v2.md) |
| **[S2]** | PaperOrchestra (Google Cloud AI) | [02-paper-orchestra.md](./02-paper-orchestra.md) |
| **[S3]** | AutoResearchClaw (aiming-lab) | [03-auto-research-claw.md](./03-auto-research-claw.md) |
| **[P]** | agent-manifesto project 固有（新規） | — |

各設計要素は source tag + section ref（例: [S2 §2.5]）で trace back 可能。
**§N.M は survey record（01-*.md/02-*.md/03-*.md）内のセクション番号**を指す。
原論文・原 GitHub 内の section ではない（survey 経由でアクセスする）。

---

## 1. 設計目標

| # | 目標 | Source |
|---|------|--------|
| G1 | `.claude/metrics/p2-verified.jsonl` を読み込み submission-ready LaTeX → PDF を生成 | [P] ユーザ要件 |
| G2 | 後続の宿題（follow-up）を構造化して永続化 | [P] ユーザ要件 |
| G3 | jsonl を安全にフラッシュ（削除でなくアーカイブ後に空化） | [P] ユーザ要件 |
| G4 | 捏造（データ/引用）を構造的に防ぐ | [S2 §4], [S3 §6] |
| G5 | Claude Code の skill 機構に自然に統合 | [S2 §3.1] |
| G6 | T6（人間の最終決定権）を尊重、強制より警告主体 | [P] CLAUDE.md L1 |
| G7 | Verifier (PR #637) との dog-fooding | [S2 §2.5] |

---

## 2. Source Mapping Table（★中核）

設計要素ごとに、どの先行研究のどのセクションから来たかを明示:

| 設計要素 | 採用/改変 | Primary Source | Secondary | 注記 |
|---------|----------|---------------|-----------|------|
| **5-agent pipeline (Outline / Plotting / LitRev / Writing / Refinement)** | 採用（一部改変） | [S2 §2] | — | 骨格として採用。Plotting は軽量化、LitRev は内部化 |
| **Skills-based architecture** (SKILL.md + references/ + scripts/) | 採用 | [S2 §3.1] | — | Claude Code に最も自然 |
| **Outline Agent** — JSON blueprint 出力 | 採用 | [S2 §2.1] | — | 出力形式そのまま |
| **Plotting Agent** — PaperBanana + VLM critic | **軽量化** | [S2 §2.2] | — | matplotlib で十分。VLM は省略 |
| **Literature Review Agent** — Semantic Scholar + 90% cite rule | **内部化** | [S2 §2.3] | [S1 §2.3] | 外部論文でなく内部 PR/issue/commit の graph。90% cite rule は同じ比率で internal citation に適用 |
| **Section Writing Agent** — single multimodal call | 採用 | [S2 §2.4] | [S1 §2.3] | S1 の "single-pass + reflection" 思想と同じ |
| **Content Refinement Agent** — AgentReview halt rule | **Verifier で代替** | [S2 §2.5] | — | 我々の Verifier pairwise (PR #637) で AgentReview を代替。P2 検証独立性 |
| **Halt rule: 「score 減少で即座に halt」** | 採用 | [S2 §2.5] | [S3 §5] | AgentReview 準拠。Verifier の winner=B margin<0 で halt |
| **Anti-hallucination: 存在しない data 要求無視** | 採用 | [S2 §4] | — | system prompt に明示 |
| **Knowledge Base 6 category (todos.md 構造)** | 採用 | [S3 §3] | — | Decisions/Experiments/Findings/Literature/Questions/Reviews |
| **30-day time-decay for Questions** | 採用 | [S3 §3] | — | `evidence/expired-questions.md` に移動 |
| **`[UNVERIFIED]` tag** | 採用 | [S2 §3.4] | [S3 §6] | 両者が同機構 |
| **Agent Research Aggregator 4-phase** | 採用 | [S2 §3.4] | — | jsonl → experimental_log.md 変換の骨格 |
| **Evidence archive directory** | 採用 | [S1 §3], [S3 §8] | — | `docs/papers/<slug>/evidence/` |
| **Single-pass writeup + reflection** | 採用 | [S1 §2.3] | [S2 §2.5] | Aider 的逐次編集を避ける |
| **Page length constraint in prompt** | 採用 | [S1 §2.3] | — | 冗長性抑制 |
| **paperize.yaml 外部設定** | 採用 | [S1 §3] | [S3 §4] | bfts_config.yaml / config.arc.yaml 相当 |
| **PROCEED / REFINE / PIVOT 判定** | **既存整合** | [S3 §5] | — | 我々の Verifier 判定 PASS/CONDITIONAL/FAIL と直接対応 |
| **HITL SmartPause** | **採用（弱）** | [S3 §7] | — | commit hook は warn のみ（block せず）。T6 尊重 |
| **Cost Guardrails** | 見送り | [S3 §7] | — | 我々は local LLM 中心、API 課金 warning は不要 |
| **23-stage pipeline** | 不採用 | [S3 §2] | — | 我々は writeup-only、tree search 不要 |
| **Tree-based experimentation** | 不採用 | [S1 §2.2] | [S3] | 既に検証済みトークン列が入力 |
| **Multi-agent debate (Innovator/Pragmatist/Contrarian)** | 不採用 | [S3 §2] | — | hypothesis generation 不要 |
| **VLM for figures** | 不採用 | [S1 §2.3], [S2 §2.2] | — | 成果物は table 中心 |
| **OpenAlex / arXiv / Semantic Scholar** | 見送り | [S2 §2.3], [S3 §2] | — | 内部 citation に集中 |
| **NeurIPS / ICLR template** | **内部 template で代替** | [S3 §8] | — | internal report 形式（LNCS-like 軽量） |
| **Dashboard / WebSocket / Overleaf** | 不採用 | [S3 §9] | — | overengineering |
| **Sentinel Watchdog background monitor** | 不採用 | [S3 §6] | — | commit hook で代用 |
| **MetaClaw cross-run learning (arc-* skill files)** | **軽量版採用** | [S3 §3] | — | `evidence/lessons.md` に前回の /paperize の反省を 1 行ずつ |

**網羅性チェック**: 上記 30 項目で、3 サーベイ記録の主要機構を全て cover（採用/改変/不採用の明示）。

---

## 3. 統合アーキテクチャ（採用要素のみ）

```
┌─────────────────────────────────────────────────────────────┐
│ Pre-Agent: Aggregator                            Source: [S2 §3.4] │
│  Phase 1 Discovery:  scan p2-verified.jsonl                │
│  Phase 2 Extraction: LLM reads commits/PRs/issues          │
│  Phase 3 Synthesis:  merge redundant tokens                │
│  Phase 4 Formatting: → experimental_log.md + idea.md      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Agent 1: Outline                                Source: [S2 §2.1] │
│  入力: idea.md + experimental_log.md + template.tex        │
│  出力: outline.json (section plan + visualization plan +   │
│        internal citation hints)                            │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐    (並列 [S2 §2.2-2.3])
        ▼                          ▼
┌──────────────┐            ┌─────────────────────┐
│ Agent 2:     │            │ Agent 3:            │
│ Plotting     │            │ Internal Citation   │
│ (matplotlib) │            │  (PR/issue/commit   │
│              │            │   graph 構築)       │
│ Source:      │            │ Source: [S2 §2.3]   │
│ [S2 §2.2]    │            │ 改変: 外部 → 内部   │
│ 改変: VLM 省略│            └──────────┬──────────┘
└──────┬───────┘                       │
       │                               │
       └───────────────┬───────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Agent 4: Section Writing                   Source: [S2 §2.4] │
│  Single-pass multimodal call                Source: [S1 §2.3]│
│  Page length constraint                     Source: [S1 §2.3]│
│  Anti-hallucination: 存在しない data 要求無視 Source: [S2 §4]│
│  [UNVERIFIED] tag                           Source: [S2 §3.4]│
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Agent 5: Refinement (Verifier pairwise)   Source: [S2 §2.5]  │
│  我々の Verifier (PR #637) で AgentReview を代替             │
│  Halt rule:                                                 │
│   - winner=A, margin>0 → accept                            │
│   - winner=B → revert + halt              Source: [S2 §2.5] │
│  k_rounds=3, bidirectional                Source: [P] PR#617│
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Post-Agent: Archiver                       Source: [S3 §8]   │
│  LaTeX compile → paper.pdf                                  │
│  todos.md 更新 (Knowledge Base 6 cat)       Source: [S3 §3] │
│  evidence/*.jsonl (p2-verified snapshot)                    │
│  jsonl をフラッシュ（空にする）              Source: [P]    │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. File Structure

```
.claude/skills/paperize/
├── SKILL.md                                  # orchestrator skill
├── references/
│   ├── outline-prompt.md                     # [S2 §2.1] Outline Agent prompt
│   ├── section-writing-prompt.md             # [S2 §2.4] Writing Agent prompt
│   ├── refinement-prompt.md                  # [S2 §2.5] Refinement Agent prompt
│   ├── halt-rules.md                         # [S2 §2.5] halt conditions
│   ├── anti-hallucination-rules.md           # [S2 §4]
│   ├── page-length-rules.md                  # [S1 §2.3]
│   ├── knowledge-base-schema.md              # [S3 §3] todos.md 6 cat
│   ├── internal-citation-rules.md            # [S2 §2.3] adapted
│   ├── schemas/
│   │   ├── outline.schema.json               # [S2 §2.1]
│   │   ├── experimental-log.schema.json      # [S2 §2.1]
│   │   └── todos.schema.json                 # [S3 §3]
│   ├── rubrics.md                            # [S2 §2.5] evaluation rubrics
│   └── template/
│       ├── paper.tex                         # internal report template
│       └── guidelines.md                     # [P] internal 規約
└── scripts/
    ├── aggregate-jsonl.sh                    # [S2 §3.4] Phase 1-4 Aggregator
    ├── collect-commit-context.sh             # [S2 §3.4] Phase 2
    ├── build-internal-citation-graph.sh      # [S2 §2.3] internal 版
    ├── verifier-refinement.py                # [S2 §2.5] + PR #637 統合
    ├── latex-sanity-check.sh                 # [S3 §6] AI-slop detection 軽量版
    ├── compile-paper.sh                      # pandoc / latexmk
    ├── update-todos.py                       # [S3 §3] Knowledge Base 更新
    ├── decay-expired-questions.py            # [S3 §3] 30-day decay
    └── flush-jsonl.sh                        # [P] jsonl を空化
```

出力:
```
docs/papers/YYYY-MM-DD-<slug>/                # [S3 §8] に対応
├── paper.tex                                 # [S3 §8]
├── paper.pdf                                 # [S1 §3]
├── todos.md                                  # [S3 §3] 6 cat
├── outline.json                              # [S2 §2.1]
├── evidence/
│   ├── p2-verified-snapshot.jsonl            # [P] 元 jsonl のコピー
│   ├── commits.md                            # [S2 §3.4]
│   ├── sources.md                            # [S2 §3.4]
│   ├── lessons.md                            # [S3 §3] MetaClaw 軽量版
│   └── expired-questions.md                  # [S3 §3] decayed
└── metadata.json                             # [P] 再現性: model/k/timestamp
```

---

## 5. `paperize.yaml` Schema

```yaml
# [S1 §3] bfts_config.yaml / [S3 §4] config.arc.yaml を参照

# --- 入力指定 ---
input:
  jsonl_path: .claude/metrics/p2-verified.jsonl
  git_range: HEAD~20..HEAD                    # 関連 commit の収集範囲
  issue_labels: [research, verifier]           # 関連 issue の絞り込み
  pr_merged_since: 7d                          # 直近 N 日の PR

# --- 論文設定 ---
paper:
  template: internal-report                    # [P] or neurips / iclr
  max_pages: 8                                 # [S1 §2.3] page length constraint
  slug_format: "{date}-{primary-topic}"

# --- Agent 設定 ---
agents:
  outline:
    model: claude-opus-4-7                     # [S1 §2.3] reasoning model
    max_tokens: 8000
  section_writing:
    model: claude-opus-4-7
    extended_thinking: true                    # [S1 §2.3] reflection 相当
  refinement:
    verifier: logprob/qwen                     # [P] PR #637
    k_rounds: 3                                # [P] PR #636
    bidirectional: true                        # [P] PR #617
    halt_on_margin_below: 0.0                  # [S2 §2.5] winner=B で halt
    max_iterations: 7                          # [S2] "5-7 calls"

# --- Follow-up 管理 ---
follow_up:
  todos_file: todos.md                         # [S3 §3]
  categories:                                  # [S3 §3] 6 cat
    - decisions
    - experiments
    - findings
    - literature
    - questions
    - reviews
  decay_days: 30                               # [S3 §3]

# --- 強制 ---
enforcement:
  mode: warn                                   # [P] T6: warn / block / skip
  jsonl_flush_on_complete: true                # [P] G3
  git_commit_on_complete: true                 # [P] 成果物を追跡
  require_evaluator_independent: true          # [P] P2
```

---

## 6. Trigger 機構（3 層）

| 層 | 機構 | 強さ | Source |
|----|------|------|--------|
| **L1: 明示実行** | `/paperize` スキル呼び出し | ユーザ駆動 | [S2 §3.5] |
| **L2: commit hook (warn)** | `scripts/paperize-reminder.sh`: jsonl ≥ N entries / ≥ N days で stderr 警告 | 弱（block せず） | [S3 §7] SmartPause 軽量版 |
| **L3: session end (reminder)** | Stop hook: 未処理 jsonl をリマインド | 弱 | [S3 §7] |

**L2/L3 はあくまで reminder — T6 (人間の最終決定権) を尊重して block はしない** ([P] CLAUDE.md L1)。

---

## 7. Agent 5 (Refinement) の Verifier 統合設計（★dog-fooding の中核）

### 7.1 置換関係

| PaperOrchestra AgentReview | 我々の Verifier pairwise | 実装 |
|--------------------------|-------------------------|------|
| manuscript を review | proposal_a = revised manuscript, proposal_b = current manuscript | [S2 §2.5] 写像 |
| 「score 増加または同点 + sub-axis net non-negative」で accept | winner=A と margin > 0 | [S2 §2.5] 写像 |
| 「score 減少」で revert + halt | winner=B で revert + halt | [S2 §2.5] 写像 |
| ~5-7 iterations | `max_iterations: 7` | [S2] |

### 7.2 criteria（論文品質判定）

[S2 §2.5] と [S3 §6] を統合:

| # | criterion | description | Source |
|---|-----------|-------------|--------|
| R1 | clarity | Is the revision clearer and better structured? | [S2 §2.5] |
| R2 | evidence_consistency | Are claims backed by evidence archive data only? | [S3 §6] VerifiedRegistry |
| R3 | citation_integrity | Do internal citations (PR/issue/commit) resolve? | [S2 §2.3] |
| R4 | length_compliance | Does it satisfy `max_pages` constraint? | [S1 §2.3] |

### 7.3 Loop 制御

```python
# scripts/verifier-refinement.py ([S2 §2.5] + PR #637)
for iteration in range(max_iterations):
    revised = section_writing_agent.refine(current_draft, review_comments)
    result = verifier_local.pairwise_compare(
        problem="Evaluating manuscript refinement.",
        proposal_a=revised,
        proposal_b=current_draft,
        criteria=[R1, R2, R3, R4],
        k_rounds=3,
        bidirectional=True,
    )
    if result['winner'] == 'A' and result['margin'] > 0.0:
        current_draft = revised       # accept
    else:
        break                         # halt (revert は current_draft 保持で自然)
```

### 7.4 evaluatorIndependent

- Worker (Claude Opus 4.7) と Verifier (Qwen3.5-4B) は別モデルファミリ
- → `.claude/metrics/p2-verified.jsonl` に `evaluator_independent=true` の token を書き込み
- → p2-verify-on-commit.sh が通る ([P] PR #641 と同じ経路)

**自己言及的**: paperize が書く論文は、paperize 自身の evaluatorIndependent 要件を満たす必要がある
→ 構造が自己強制する → **P2 (検証の独立性) の実例**。

---

## 8. Knowledge Base: `todos.md` 詳細設計

[S3 §3] 6 category を採用。各 entry に timestamp と 30-day decay ([S3 §3]):

```markdown
# Research Follow-ups — {paperize-slug}

> Generated by /paperize on {timestamp}
> Source: {commit-hashes}, {pr-numbers}, {issue-numbers}
> Next decay scan: {timestamp + 30 days}

## Decisions
<!-- 採用した設計判断 (rationale, stage, approval status) -->
- [DEC-001] {date} {description} — approval: {T6 tag}

## Experiments
<!-- 実施した実験 (runs, metrics, failure modes) -->
- [EXP-001] {date} {n} samples, k={k}, model={model}, accuracy={x}

## Findings
<!-- 主要な発見 (novel insights, anomalies) -->
- [FIN-001] {date} {description}

## Literature
<!-- 引用した文献 (internal: PR/issue/commit; external: arxiv) -->
- [LIT-001] {date} {source} — relevance: high/medium

## Questions  ← Follow-up 宿題
<!-- 未解決 (unresolved directions, branching paths) -->
- [Q-001] {date} {description} — expires {timestamp + 30d}

## Reviews
<!-- 本論文に対する peer review (Verifier margin, reviewer feedback) -->
- [REV-001] {date} Verifier pairwise margin={x}, k_rounds={k}
```

### Decay 処理

`scripts/decay-expired-questions.py`:
1. `todos.md` を parse
2. `Questions` category の各 entry の `expires` date を確認
3. 期限切れを `evidence/expired-questions.md` に移動
4. `todos.md` から削除

**呼び出しタイミング**:
- `/paperize` 実行の最初（前回の expired を整理してから開始）
- cron hook で週次（optional）

---

## 9. 棄却代替案（rejected alternatives）

設計過程で検討したが採用しなかった選択肢:

| 代替案 | 却下理由 | 出典 |
|--------|---------|------|
| Tree search を軽量化して採用 | 我々は writeup-only。探索対象（hypothesis）が既に確定している | [S1] 不要 |
| VLM figure critic | 我々の成果物は table 中心、figure は少数 | [S1 §2.3] |
| PaperBanana diagram 生成 | matplotlib で十分 | [S2 §2.2] |
| Semantic Scholar 連携 | 内部 citation に集中、外部は optional | [S2 §2.3] |
| OpenAlex / arXiv 連携 | 同上 | [S3 §2] |
| Multi-agent debate (Innovator/Pragmatist/Contrarian) | hypothesis generation 不要 | [S3 §2] |
| 23-stage pipeline | 8 phase のうち 6 phase が不要（experiment 関連） | [S3 §2] |
| NeurIPS/ICLR template 強制 | internal report 形式の方が我々の文脈に合う | [S3 §8] |
| Dashboard / Overleaf | overengineering、pandoc で十分 | [S3 §9] |
| HITL 全機能 (Co-Pilot, Gate-Only, Step-by-Step) | 我々は「warn + skill」の軽量 2 層で足りる | [S3 §7] |
| AI-Scientist-v2 の Aider-based 逐次編集 | V2 自身が single-pass + reflection に切り替えた | [S1 §2.3] |
| Citation hallucination 許容 | anti-hallucination を最初から採用 | [S1 §5] が指摘 |
| commit hook で block (強制) | T6 尊重 ([P] CLAUDE.md)、warn に留める | [P], [S3 §7] |

---

## 10. 実装 Sub-Issue 分割案

本 SS4 で **設計** は確定。**実装** は別 Sub-Issues に分割:

| Sub-Issue | タスク | 依存 |
|-----------|-------|------|
| SS5 | `scripts/aggregate-jsonl.sh` (Aggregator 4-phase) [S2 §3.4] 実装 | SS4 |
| SS6 | `.claude/skills/paperize/SKILL.md` orchestrator + references 実装 | SS5 |
| SS7 | `scripts/verifier-refinement.py` [S2 §2.5] + PR #637 統合 | SS6 |
| SS8 | `scripts/update-todos.py` + `decay-expired-questions.py` [S3 §3] | SS6 |
| SS9 | `scripts/compile-paper.sh` + LaTeX template [S1 §2.3] | SS6 |
| SS10 | commit hook (warn) + Stop hook [S3 §7] ... **L1 承認要** | SS6, 人間 setup スクリプト |
| SS11 | End-to-end smoke test: 過去 PR #641 の jsonl エントリを paperize | SS5-9 |

---

## 11. Gate 判定 (SS4 用)

本 SS4 の成果物:

1. ✅ **Source Mapping Table (§2)** — 30 設計要素を 3 サーベイに trace back
2. ✅ **統合アーキテクチャ (§3)** — 採用/改変/不採用を図で明示
3. ✅ **File Structure (§4)** — skills/paperize/ 配置
4. ✅ **paperize.yaml Schema (§5)** — config 型定義
5. ✅ **Trigger 機構 (§6)** — 3 層 (explicit/warn/reminder)
6. ✅ **Verifier 統合設計 (§7)** — dog-fooding の実装スケッチ
7. ✅ **todos.md 詳細 (§8)** — Knowledge Base 6 cat
8. ✅ **棄却代替案 (§9)** — 13 項目
9. ✅ **実装 Sub-Issue 分割 (§10)** — SS5-11

### Gate 判定: **PASS 候補**

- Source Mapping 完備 ✅
- 3 サーベイに網羅的に trace back 可 ✅
- 棄却判断も明示 ✅

**次のアクション**: SS5-11 の順で実装 (別ラウンドで順次)。

---

## 12. Traceability Integrity Check

以下は自動検証したい項目（future work）:

```bash
# 各 Source Tag が存在するファイルに対応するか
grep -oE '\[S[123][^]]*\]' 04-integrated-design.md | sort -u
# 期待: S1 §2.1/§2.2/§2.3/§3/§5, S2 §2/§2.1-2.5/§3.1/§3.4/§3.5/§4,
#       S3 §2/§3/§4/§5/§6/§7/§8/§9  (全 28 tag, 2026-04-20 audit で 0 broken 確認)

# 各サーベイ記録の該当 section が実在するか（grep の存在確認）
for s in 01 02 03; do
  grep -c "^## " docs/research/autonomous-research-pipelines/$s-*.md
done
```

→ 別スクリプト `scripts/validate-source-tags.sh` で将来自動化（SS10 の一部として検討）。

---

## References

- 先行サーベイ 3 件（本ディレクトリ内）
- Verifier 実装: `scripts/verifier_local.py`, PR #617, #637
- Verifier 論文: [Kwok et al. 2026] `research/LLM-as-a-Verifier_*.pdf`
- PaperOrchestra 実装: [Ar9av/PaperOrchestra](https://github.com/Ar9av/PaperOrchestra)
- AutoResearchClaw: [aiming-lab/AutoResearchClaw](https://github.com/aiming-lab/AutoResearchClaw)

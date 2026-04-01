# Gate-Driven Research Workflow

A structured workflow for conducting technical research using Git, GitHub Issues, and worktrees. Designed for questions that require empirical validation before implementation — "should we do X?" rather than "how do we do X?".

## Overview

```
Gap Analysis → Parent Issue → Sub-Issues (with gates)
                                  ↓
                          Git Worktree (isolated)
                                  ↓
                          Experiment → Results (issue comment)
                                  ↓
                          Gate Judgment
                         ╱      │       ╲
                      PASS  CONDITIONAL  FAIL
                       │        │         │
                     Close   Sub-issue  Escalate
                              (recurse)
```

The core idea: every research question has an explicit **gate** — a decision point with predefined criteria that determines whether to proceed, dig deeper, or stop. Gates prevent unbounded exploration and make research outcomes actionable.

## Workflow Steps

### 1. Gap Analysis

Before opening any issues, identify the gaps between the current state and the goal. Each gap becomes a candidate research task.

Write the analysis as structured text:

```markdown
### Gap N: [Name]
- Current state: ...
- Required state: ...
- Risk level: high / medium / low
- Unknowns: ...
```

Rank gaps by risk. The highest-risk gap should be researched first, because its outcome may invalidate the entire effort (fail-fast).

### 2. Parent Issue

Create a single parent issue that frames the overall research goal. It contains:

- **Background**: Why this research is needed
- **Current vs target state**: Architecture diagrams, before/after
- **Gap list**: All identified gaps with brief descriptions
- **Sub-issue table**: Links to research tasks
- **Related issues**: Cross-references to implementation work

The parent issue is a living document — update it as research progresses.

### 3. Sub-Issues (Research Tasks)

Each gap becomes a sub-issue. Every sub-issue follows this template:

```markdown
Parent: #N

## 目的
[One sentence: what question does this research answer?]

## 背景
[Why this question matters. Link to parent issue context.]

## 方法
[Concrete steps. What experiments to run, what data to collect.]

## 成果物
[What artifacts this research produces — scripts, reports, config.]

## 依存
[Which other sub-issues must complete first, or "none (parallel)".]

## Gate 判定プロセス

実験実施 → 結果記録（コメント） → Gate 判定
  ├─ PASS: [criteria] → [action]
  ├─ CONDITIONAL: [criteria] → sub-issue 起票
  └─ FAIL: [criteria] → [action]

## 研究結果の記録

研究の進捗・結果は本 issue の **コメント** として追記する。
最終結果はコメントに加えて成果物ファイルにも反映する。

記録フォーマット:
### [日付] 実験名

**条件**: ...
**結果**: ...
**考察**: ...
**次のアクション**: ...
```

### 4. Git Worktree for Isolation

Each research task gets its own git worktree:

```bash
git worktree add ../project-research-45 -b research/45-topic-name main
```

**Why worktrees**:
- Research artifacts (scripts, data, reports) don't pollute the main branch
- Multiple research tasks can run in parallel without conflicts
- Easy to discard if the gate judges FAIL
- Easy to merge if the gate judges PASS and artifacts are worth keeping

**Worktree conventions**:
- Branch name: `research/<issue-number>-<short-name>`
- Scripts go in `scripts/` within the worktree
- Results go in `docs/research/` within the worktree
- Reference data from main repo via absolute paths or symlinks

### 5. Experiment Execution

Run experiments from the worktree. Record results incrementally as issue comments — don't wait until everything is done.

**Comment structure for experiments**:

```markdown
### [YYYY-MM-DD] Experiment: [name]

**条件**:
- Parameter A: value
- Parameter B: value

**結果**:

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Metric 1 | X | ≥ Y | PASS/FAIL |

**考察**: [interpretation]
**次のアクション**: [what to do next]
```

**Rules**:
- Always include raw numbers, not just pass/fail
- Always state conditions precisely enough to reproduce
- Always state what you'll do next — even if it's "wait for #XX"

### 6. Judge Evaluation + Gate Judgment

Before gate judgment, conduct structured evaluation using LLM-as-a-judge (`.claude/agents/judge.md`).

#### 6a. Judge Evaluation

Pass the following to the Judge agent:
- Experiment results (issue comments)
- Gate PASS/FAIL criteria defined in the sub-issue
- Artifact file list

Judge evaluates on G1-G4 criteria:

| # | Criterion | Question |
|---|-----------|----------|
| G1 | Question Response | Does it answer the sub-issue's question? |
| G2 | Reproducibility | Can the results be reproduced? |
| G3 | Judgment Basis | Is the PASS/FAIL rationale quantitative? |
| G4 | Next Action | Is the next step clear? |

Judge recommendation: average ≥ 3.5 → PASS recommended, < 3.5 → reconsider.
Final judgment is made by human (T6). Judge results are reference material.

#### 6b. Gate Judgment

The gate is the most important part. After each experiment, record a judgment as an issue comment:

```markdown
### Judge 評価

| 基準 | スコア | 根拠 |
|------|--------|------|
| G1 Question Response | N/5 | ... |
| G2 Reproducibility | N/5 | ... |
| G3 Judgment Basis | N/5 | ... |
| G4 Next Action | N/5 | ... |

**総合スコア**: X.X/5.0

### Gate: [判定名]

**日付**: YYYY-MM-DD
**判定**: PASS / CONDITIONAL / FAIL
**Judge スコア**: X.X/5.0
**根拠**: [quantitative data or qualitative assessment]
**追加研究**: 必要 → #XX / 不要
**次のアクション**: ...
```

**Gate outcomes**:

| Judgment | Meaning | Action |
|----------|---------|--------|
| **PASS** | Question answered, criteria met | Close issue. Update parent. |
| **CONDITIONAL** | Partially answered, more research needed | Create child sub-issue with narrower scope. Keep current issue open. |
| **FAIL** | Fundamental assumption broken | Escalate to parent issue. May invalidate sibling research. |

**CONDITIONAL is recursive** — the child sub-issue gets its own gate, which may produce further children. This creates a tree:

```
#44 Parent
├── #45 Extraction quality (CONDITIONAL)
│   ├── #51 max_tokens fix (PASS → close)
│   ├── #52 Semantic evaluation (CONDITIONAL)
│   │   └── #XX Embedding model selection (...)
│   └── #53 Few-shot prompt (depends on #51, #52)
├── #46 Context window (PASS → skip, gap resolved)
├── #47 JSON reliability (parallel with #45)
├── #48 Prompt adaptation (depends on #45)
└── #49 Job queue design (parallel, no LLM dependency)
```

### 7. Closing the Loop

When all sub-issues are resolved (PASS or FAIL), return to the parent issue:

1. Summarize findings across all sub-issues
2. State the overall gate judgment (go / no-go / conditional)
3. If go: create implementation issues referencing the research
4. If no-go: document why and what alternatives exist
5. Close the parent issue

## Parallelization

Sub-issues that don't depend on each other should run in parallel. State dependencies explicitly in each sub-issue:

```markdown
## 依存
- #51 の結果が前提（JSON 信頼性確保後に実施）
- #49 と並行可（LLM 性能に依存しない）
```

When planning execution order, draw the dependency graph:

```
#45 + #47 + #49  ← parallel (no dependencies)
       ↓
   #46 + #48     ← depend on #45 results
```

## Quantitative Thresholds

Every gate must have **predefined quantitative criteria**. Set these when creating the sub-issue, not after seeing the results. Examples:

```markdown
| Metric | Threshold | Rationale |
|--------|-----------|-----------|
| JSON parse rate | ≥ 90% | Below this, output is unreliable |
| Schema compliance | ≥ 80% | Remaining 20% fixable by validation |
| Term recall | ≥ 60% | Below this, extraction misses too much |
```

Thresholds can be adjusted if the rationale changes — but document why:

```markdown
**Threshold adjustment**: Term recall threshold lowered from 60% to "semantic recall ≥ 60%"
because exact match penalizes valid alternative terminology (#52).
```

## Anti-Patterns

| Anti-pattern | Why it's bad | Instead |
|-------------|-------------|---------|
| Research without a gate | Exploration never converges | Define PASS/FAIL criteria upfront |
| Gate criteria set after results | Confirmation bias | Set thresholds in the sub-issue body before experimenting |
| All results in one final comment | Intermediate failures are invisible | Comment after each experiment |
| Worktree merged before gate | Unvalidated code enters main | Gate PASS is prerequisite for merge |
| Sub-issue without parent link | Research tree becomes disconnected | Always include `Parent: #N` |
| CONDITIONAL without child issue | "Need more research" with no actionable next step | CONDITIONAL must create a child issue |

## マニフェスト公理系との対応

本ワークフローは P3（学習の統治）のライフサイクルの運用インスタンスである。

### P3 ライフサイクルとの対応

| Research Workflow ステップ | P3 ライフサイクル段階 | 備考 |
|---|---|---|
| Gap Analysis | **観察** | 現状と目標の差分を識別する |
| Parent Issue 作成 | 観察→**仮説化**の境界 | 研究目標のフレーミング |
| Sub-Issue + Gate 定義 | **仮説化** | Gap を検証可能な仮説に変換。Gate 基準 = 棄却条件 |
| Git Worktree 隔離 | (P2: 認知的役割分離) | 実験と本流の分離 |
| 実験実施 + 結果記録 | **検証** | 仮説の実証/反証 |
| Gate PASS → Close | 検証→**統合** | 成果物を構造に取り込む |
| Gate CONDITIONAL → Child Issue | 検証→**仮説化**（再帰） | 追加仮説の生成 |
| Gate FAIL → Escalate | 検証→**退役** | 仮説の棄却 |
| Parent Issue Close | **統合**完了 | 全研究の集約と構造への書き戻し |

### D4（フェーズ順序）との整合

本ワークフローは D4 の各フェーズを前提として機能する:

- **L1**: Worktree 隔離により実験が本流を破壊しない（安全基盤）
- **P2**: Worktree = 実験と本流の構造的分離（検証基盤）
- **P4**: Gate の定量的閾値 = 可観測性の確保（可観測性）
- **P3**: Gate 判定プロセス自体が統治された学習（統治）

### D13（前提否定の影響波及）との関係

Gate FAIL は D13 の影響波及を発動する:
- FAIL した仮説に依存する sibling sub-issue は影響集合に含まれる
- Parent Issue で影響波及の範囲を評価し、必要に応じて他の sub-issue を再検討する

---

## Template: Checklist for New Research

When starting a new research effort:

- [ ] Gap analysis written
- [ ] Parent issue created with all gaps listed
- [ ] Sub-issues created with gates and thresholds
- [ ] Dependencies between sub-issues documented
- [ ] Git worktree created for the first task
- [ ] Highest-risk sub-issue identified and started first

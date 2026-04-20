---
name: paperize
user-invocable: true
description: >
  .claude/metrics/p2-verified.jsonl の検証トークンから論文成果物 (paper.pdf +
  todos.md + evidence/) を生成する。P3 学習ライフサイクルの「統合→退役」段階を
  構造化する。PaperOrchestra 5-agent pipeline (outline → [plotting ∥ litreview] →
  writing → refinement) を採用し、AutoResearchClaw の Knowledge Base 6-cat を
  follow-up tracking に採用、AI-Scientist-v2 の paperize.yaml 外部設定を採用する。
  「論文化」「paperize」「jsonl フラッシュ」「宿題化」で起動。
dependencies:
  invokes:
    - skill: verify
      type: hard
      phase: "Phase 4 Refinement"
      condition: "refinement halt rule 評価"
  invoked_by:
    - skill: evolve
      phase: "退役 (Retirement)"
      expected_output: "p2-verified.jsonl → paper.pdf + todos.md + flush"
---
<!-- @traces P3, D13, T2 -->

# /paperize — Autonomous Research Paperization

`.claude/metrics/p2-verified.jsonl` が蓄積した検証トークン群を、
LaTeX 論文 + 後続宿題 todos.md + 証拠 evidence/ に変換し、jsonl を空化する。

設計文書: `docs/research/autonomous-research-pipelines/04-integrated-design.md`

## 起動条件

- `.claude/metrics/p2-verified.jsonl` が存在し、エントリが 1 件以上
- git repo 内部
- `paperize.yaml` が存在する（無ければ `paperize.yaml.example` を cp して促す）

## 5-Agent Pipeline

| # | Agent | 役割 | Source |
|---|-------|------|--------|
| 1 | **Outline** | manifest.json → outline.json (章立て + 各章の論点) | [S2 §2.1] |
| 2a | **Plotting** | evidence/ → 図表（matplotlib で numeric plot, pandoc で table） | [S2 §2.2] |
| 2b | **LitReview** | internal citation graph 構築（PR/issue/commit hash を第一級化） | [S2 §2.3] adapted |
| 3 | **Writing** | outline + evidence → paper.tex (single-pass + extended thinking) | [S2 §2.4] |
| 4 | **Refinement** | verifier-refinement.py (logprob pairwise, halt on margin<0) | [S2 §2.5] + PR #637 |

Agent 2a/2b は独立、並列化可。

## 実行手順

### Step 0: 前提チェック

```bash
[ -f .claude/metrics/p2-verified.jsonl ] || { echo "no jsonl"; exit 0; }
[ -s .claude/metrics/p2-verified.jsonl ] || { echo "empty jsonl"; exit 0; }
[ -f paperize.yaml ] || { cp .claude/skills/paperize/paperize.yaml.example paperize.yaml; echo "created paperize.yaml — review before re-running"; exit 1; }
```

### Step 1: Aggregate (Phase 1 + 4, deterministic)

```bash
SLUG=$(date +%Y-%m-%d)-$(yq -r '.paper.slug_format // "paperize"' paperize.yaml | sed 's/[^a-z0-9-]/-/g')
OUT="docs/papers/$SLUG"
scripts/aggregate-jsonl.sh "$OUT" \
  "$(yq -r '.input.jsonl_path' paperize.yaml)" \
  "$(yq -r '.input.git_range' paperize.yaml)"
```

成果物: `$OUT/manifest.json` + `$OUT/evidence/{p2-verified-snapshot.jsonl,commits.md,sources.md}`

### Step 2: Extraction + Synthesis (Phase 2 + 3, LLM)

`manifest.json` を読み、`references/agent-prompts/extraction-prompt.md` のルールで:

1. 各 verification を 1〜3 文の narrative に要約（未検証事項は `[UNVERIFIED]` tag）
2. 重複を merge、独立プロジェクトを分離
3. 抽出物を `$OUT/idea.md` + `$OUT/experimental_log.md` に書き出す

### Step 3: Outline Agent

`references/schemas/outline.schema.json` に準拠した `$OUT/outline.json` を生成。
ページ数上限は `paperize.yaml:paper.max_pages` から取得 (default 8)。

### Step 4: Plotting ∥ LitReview（並列）

- **Plotting**: `evidence/` 中の numeric data → `figures/*.pdf`
- **LitReview**: `manifest.json:commits` + `evidence/sources.md` → `references.md`（internal citation graph）

### Step 5: Writing Agent

`outline.json` + `idea.md` + `experimental_log.md` + `figures/` + `references.md` → `paper.tex`。
single-pass (extended_thinking=true)。Section ごとの Aider-style 反復は避ける。

### Step 6: Refinement Agent

`scripts/verifier-refinement.py` で logprob pairwise verifier を回す:
- K=3 rounds, bidirectional, winner=A and margin>0 で accept
- winner=B または margin<0 で halt（AgentReview halt rule）
- max_iterations=7

### Step 7: Compile

```bash
scripts/compile-paper.sh "$OUT/paper.tex" "$OUT/paper.pdf"
```

### Step 8: Follow-up tracking

```bash
scripts/update-todos.py "$OUT/todos.md" "$OUT/manifest.json"
scripts/decay-expired-questions.py "$OUT/todos.md"
```

Knowledge Base 6 カテゴリ (`references/knowledge-base-schema.md`):
- decisions / experiments / findings / literature / questions / reviews
- 30-day time decay で stale を `$OUT/evidence/expired-questions.md` に退避

### Step 9: Metadata + Flush

```bash
jq -n --arg model "$(yq -r '.agents.refinement.verifier' paperize.yaml)" \
      --arg k "$(yq -r '.agents.refinement.k_rounds' paperize.yaml)" \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{model:$model, k_rounds:$k, timestamp:$ts}' > "$OUT/metadata.json"

# Flush (enforcement.jsonl_flush_on_complete で条件付き)
if [ "$(yq -r '.enforcement.jsonl_flush_on_complete' paperize.yaml)" = "true" ]; then
  scripts/flush-jsonl.sh "$(yq -r '.input.jsonl_path' paperize.yaml)"
fi

# Commit (enforcement.git_commit_on_complete で条件付き)
if [ "$(yq -r '.enforcement.git_commit_on_complete' paperize.yaml)" = "true" ]; then
  git add "$OUT" && git commit -m "paperize: $SLUG (compatible change)"
fi
```

## Enforcement モード (paperize.yaml:enforcement.mode)

| mode | 挙動 |
|------|------|
| `warn` | SessionStart/Stop hook で「jsonl N 件未処理」を表示するだけ |
| `block` | 次の commit を block（commit hook で検知。要 L1 承認） |
| `skip` | 強制なし、明示起動のみ |

Default: `warn`。

## 成果物構造

```
docs/papers/YYYY-MM-DD-<slug>/
├── paper.tex              # writing agent output
├── paper.pdf              # compile-paper.sh output
├── outline.json           # outline agent output
├── idea.md                # extraction agent output
├── experimental_log.md    # extraction agent output
├── todos.md               # knowledge-base 6 cat
├── manifest.json          # aggregate-jsonl.sh output
├── metadata.json          # reproducibility (model/k/ts)
├── figures/               # plotting agent output
├── references.md          # litreview agent output
└── evidence/
    ├── p2-verified-snapshot.jsonl
    ├── commits.md
    ├── sources.md
    ├── lessons.md         # MetaClaw 軽量版 (SS8 で追加)
    └── expired-questions.md
```

## 不変条件

- `paper.pdf` 生成前に jsonl flush しない（G3: atomic commit）
- refinement で winner=B なら commit せず `$OUT/evidence/refinement-rejected.md` に記録
- `evaluator_independent=false` の verification は manifest で `quarantined: true` タグ付け

## 未実装箇所（SS7-SS11 で埋める）

- [ ] Phase 2/3 LLM 実行 → SKILL.md 本体のプロンプト化（本ファイルで記述中）
- [ ] `scripts/verifier-refinement.py` → SS7
- [ ] `scripts/update-todos.py` + `scripts/decay-expired-questions.py` → SS8
- [ ] `scripts/compile-paper.sh` + `references/template/paper.tex` → SS9
- [ ] commit hook / Stop hook (enforcement.mode=warn/block) → SS10
- [ ] end-to-end smoke test → SS11

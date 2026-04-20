# Survey 2: PaperOrchestra (Google Cloud AI Research, 2026-04)

> **Parent Issue**: #642
> **Survey Sub-Issue**: SS2
> **Status**: 深堀サーベイ完了 (2026-04-20)
> **Primary Sources**:
> - Paper: [arXiv:2604.05018](https://arxiv.org/abs/2604.05018) (Song, Song, Pfister, Yoon — Google Cloud AI Research)
> - Project page: [paper_orchestra (yiwen-song.github.io)](https://yiwen-song.github.io/paper_orchestra/)
> - Open-source implementation: [GitHub Ar9av/PaperOrchestra](https://github.com/Ar9av/PaperOrchestra)

---

## 1. What is it

**Raw experimental materials → submission-ready LaTeX manuscript** に特化した
multi-agent framework。AI-Scientist-v2 が **end-to-end (ideation + experimentation + writeup)**
を扱うのに対し、**PaperOrchestra は writeup に focus** し、入力はすでに終わった実験の
メモ（ideas + logs）を前提とする。

**我々の要件（jsonl にある検証済みトークン → 論文 PDF）に最も直接的にマッチ**。

### 代表的成果

- **Literature review 品質 win rate**: baseline 比 **+50〜+68 pp**
- **Overall manuscript 品質**: **+14〜+38 pp**
- **引用質**: 1 論文あたり 45.7-48.0 citations（baseline 9.8-14.2）
- **計算コスト**: **60-70 LLM API calls / ~39.6 min / paper**
- **Refined manuscript の効果**: refined vs non-refined で **79-81% win rate**
- **simulated acceptance 改善**: +19 pp (CVPR), +22 pp (ICLR)

## 2. Architecture: 5-Agent Pipeline

```
         ┌──────────────┐
         │ Outline      │ 構造化 JSON blueprint
         │ Agent        │ + 可視化戦略 + 2-phase literature search 戦略
         └──────┬───────┘
                │
      ┌─────────┴─────────┐
      │                   │         (並列実行)
      ▼                   ▼
┌──────────┐        ┌──────────────┐
│ Plotting │        │ Literature   │
│ Agent    │        │ Review Agent │
│ (~20-30) │        │   (~20-30)   │
└────┬─────┘        └──────┬───────┘
     │                     │
     └──────────┬──────────┘
                │
                ▼
         ┌──────────────┐
         │ Section      │ 全 LaTeX section を single multimodal call で draft
         │ Writing      │
         └──────┬───────┘
                │
                ▼
         ┌──────────────┐
         │ Content      │ AgentReview で simulated peer review
         │ Refinement   │ (~5-7 calls, 厳しい halt rule)
         └──────┬───────┘
                │
                ▼
        submission-ready
         LaTeX + PDF
```

### 2.1 Outline Agent

**入力**:
- `idea.md` (Sparse Idea format — 研究 concept の要約)
- `experimental_log.md` (App. D.3 format — 構造化実験結果)
- `template.tex` (conference template)
- `conference_guidelines.md` (submission rules, page limit)

**出力 (JSON blueprint)**:
- **Visualization specifications**: どの figure を生成するか
- **2-phase literature search strategies**:
  - Macro-level: intro 用（分野全体）
  - Micro-level: related work 用（特定アルゴリズム比較）
- **Section-level writing plans**: citation hint 付き

### 2.2 Plotting Agent

- **PaperBanana** (Zhu et al., 2026) を使った academic illustration
- **VLM critic** が生成画像を評価し iterative refinement
- Design objective（label 明瞭性、axis 整合、color consistency 等）を満たすまで繰り返す

### 2.3 Literature Review Agent

**Plotting Agent と並列実行**:

1. **LLM + web search** で candidate papers を発見
2. **Semantic Scholar API** で存在確認:
   - Fuzzy title match (Levenshtein distance)
   - Abstract retrieval
   - **Temporal cutoff enforcement**（投稿 deadline 以降は除外）
3. 検証不能な参照は破棄
4. **Constraint**: 「集めた literature pool の **90% 以上**が実際に cite されていること」

**Anti-hallucination**: Semantic Scholar で存在確認された論文のみ引用に使う。

### 2.4 Section Writing Agent

- **Single multimodal call** で abstract / methodology / experiments / conclusion を一気に draft
- 数値表は **experimental log から直接抽出**（LLM が数値を生成しない）
- 生成 figure を LaTeX source に splice

### 2.5 Content Refinement Agent

**AgentReview による simulated peer review**:

**Accept 条件**（厳密）:
- **全体 score が増加**、または
- **全体 score が同点かつ sub-axis 合計が net non-negative**

**Revert and halt 条件**:
- **全体 score が減少** → 即座に revert し halt

**重要な anti-hallucination rule**:
- 「reviewer が存在しない data を要求した場合、無視する」と explicit instruction
- **data 捏造を構造的に防止**

**約 5-7 calls** で refinement 完了。

## 3. Open-Source Implementation: Skills-Based Architecture

GitHub の Ar9av/PaperOrchestra は **extraordinary relevant**:

### 3.1 設計思想

> "There are no API keys, no SDK dependencies, no embedded LLM calls.
> The skills are instruction documents plus deterministic helpers;
> your coding agent does all LLM reasoning and web search using its own tools."

**これは我々の Claude Code + .claude/skills/ の構造と完全に一致する**。

### 3.2 Skills 一覧（各 skill = SKILL.md + references/ + scripts/）

| Skill | 役割 |
|-------|------|
| `paper-orchestra` | Orchestrator（全体制御） |
| `outline-agent` | Outline Agent |
| `plotting-agent` | Plotting Agent |
| `literature-review-agent` | Literature Review Agent |
| `section-writing-agent` | Section Writing Agent |
| `content-refinement-agent` | Content Refinement Agent |
| `paper-writing-bench` | Benchmark utilities |
| `paper-autoraters` | Automated evaluators |

各 skill:
- **SKILL.md**: dense instruction document
- **references/**: paper の App. F prompts を verbatim、JSON schemas、rubrics、halt rules
- **scripts/**: schema validation / fuzzy matching / BibTeX formatting / LaTeX sanity checks

### 3.3 入出力

```
workspace/
├── inputs/
│   ├── idea.md                   # research concept (Sparse Idea format)
│   ├── experimental_log.md       # 構造化実験結果 (App. D.3)
│   ├── template.tex              # conference LaTeX template
│   ├── conference_guidelines.md  # submission rules
│   └── figures/                  # optional pre-existing visualizations
└── outputs/
    ├── outline.json
    ├── literature.bib
    ├── sections/*.tex
    ├── figures/*.pdf
    └── paper.pdf
```

### 3.4 Agent Research Aggregator（★特筆すべき preprocessor）

「**scattered な research 痕跡 → idea.md + experimental_log.md**」への 4-phase 前処理:

| Phase | 処理 | 実装 |
|-------|------|------|
| **1. Discovery** | `.claude/`, `.cursor/`, `.antigravity/`, `.openclaw/` を deterministic scan | scripts |
| **2. Extraction** | LLM が batch (~50KB/ea) を処理、`extraction-prompt.md`。未検証は `[UNVERIFIED]` tag | LLM |
| **3. Synthesis** | 単一 LLM call で redundant records を merge、複数 project 分離 | LLM |
| **4. Formatting** | 決定論的に `idea.md` / `experimental_log.md` に変換 | scripts |

**我々の `.claude/metrics/p2-verified.jsonl` からの narrative extraction** は
このパターンがそのまま使える。

### 3.5 Install / Invocation

```bash
# Symlink インストール
ln -sf ~/paper-orchestra/skills/$skill ~/.claude/skills/$skill

# 自然言語で呼び出し
"Run the paper-orchestra pipeline on ./workspace"
"Write a paper from my work in ~/my-project"
```

Supported hosts: **Claude Code**, Cursor, Antigravity, Cline, Aider, OpenCode

## 4. Anti-Hallucination の二重防御

1. **Lit Review Agent**: Semantic Scholar 検証で citation 捏造を防ぐ
2. **Content Refinement Agent**: reviewer 要求に対し「data が存在しなければ無視」ルール

→ AI-Scientist-v2 の citation error 問題（workshop paper で頻発）を正面から解決。

## 5. PaperWritingBench

**評価 benchmark**:
- 200 top-tier AI conference papers を **reverse engineer** して (Sparse Idea, Experimental Log) pair に
- CVPR 2025 (100) + ICLR 2025 (100)
- **Paper Autoraters** (App. F.3):
  - Citation F1 (precision/recall grades P0-P1)
  - Literature review quality (6-axis)
  - Section-by-section paper quality
  - Side-by-side literature review comparison

**Human evaluation**: 11 AI researchers による side-by-side 比較。

## 6. 我々の要件への示唆

### 6.1 完全に mappable な要素

| PaperOrchestra | 我々のプロジェクト | Mapping |
|---------------|----------------------|---------|
| `idea.md` | Parent Issue body + 関連 research plan | 容易に作成可能 |
| `experimental_log.md` | `p2-verified.jsonl` + commit messages + `research/verifier-gt/*.json` | **直接適用可能** |
| `template.tex` | 自作 template（internal report 形式で開始） | 軽量で OK |
| `conference_guidelines.md` | 「internal research report 形式、~5 page、Verifier evidence 必須」 | 我々の規約 |
| `outline-agent` skill | `.claude/skills/paperize/` に配置 | 採用 |
| `literature-review-agent` skill | **internal citation** (自 PR/commit/issue) に変換 | 適応が必要 |
| `section-writing-agent` skill | そのまま採用 | 採用 |
| `content-refinement-agent` skill | **我々の Verifier pairwise (PR #637) を自然に統合** | ★ dog-fooding |
| `agent-research-aggregator` | **p2-verified.jsonl 読み取り + git log 抽出** | ★★ 実質同じ |

### 6.2 AgentReview の halt rule = 我々の Verifier と自然に対応

| PaperOrchestra AgentReview | 我々の Verifier pairwise |
|---------------------------|------------------------|
| "score 増加または同点 + sub-axis net non-negative" で accept | winner=A and margin > threshold |
| "score 減少" で即座に halt | winner=B → revert |
| ~5-7 refinement iterations | k_rounds=3 + bidirectional |

### 6.3 我々に特化した変更点

| 差分 | 理由 |
|------|------|
| **Web 検索・Semantic Scholar 省略** | 内部研究なので外部引用は optional。代わりに **internal citation** (PR/issue/commit hash) を第一級化 |
| **PaperBanana 不要** | 図は matplotlib で十分 |
| **benchmark 不要** | PaperWritingBench は公開論文向け |
| **`p2-verified.jsonl` を入力の一等市民に** | 我々独自の「検証トークン列」。PaperOrchestra は experimental_log.md を想定するので、**preprocessing で変換** |

## 7. 直接的な採用案

我々の `/paperize` skill は **PaperOrchestra の skills-based 設計を忠実に写像**できる:

```
.claude/skills/paperize/
├── SKILL.md                     # orchestrator skill
├── references/
│   ├── outline-prompt.md
│   ├── section-writing-prompt.md
│   ├── refinement-prompt.md
│   ├── halt-rules.md
│   ├── json-schemas/*.json
│   └── rubrics.md
└── scripts/
    ├── p2-to-experimental-log.sh  # jsonl → experimental_log.md
    ├── collect-commit-context.sh  # commit msg / PR / issue 収集
    ├── verifier-refinement.py     # Verifier pairwise で AgentReview を代替
    └── latex-sanity-check.sh
```

呼び出し: `/paperize docs/papers/2026-04-20-<slug>`

これは **6 論文を実装した skill を我々に移植する** という形になる。再発明ではない。

## 8. 結論

**PaperOrchestra は我々の要件に最も直接的に写像できる先行研究**。

### 採用すべき要素（全て）

1. **5-agent 構造** (Outline → [Plotting ∥ LitReview] → Writing → Refinement)
2. **Skills-based architecture**（Claude Code に自然）
3. **Content Refinement の halt rule** (score non-decrease 制約)
4. **Anti-hallucination rules** (存在しない data を生成しない)
5. **Agent Research Aggregator** の 4-phase preprocessing（jsonl → experimental_log 変換に応用）

### 適応すべき要素

1. **Lit Review**: 外部 → 内部（自 PR/issue/commit）に入れ替え
2. **PaperBanana**: 省略（matplotlib で充分）
3. **Semantic Scholar**: 省略（内部 citation graph を自作）

### Dog-fooding の好機

- Content Refinement Agent = **我々の Verifier pairwise (PR #637)**
- 「**論文を書く AI が、書いた論文を同じ AI で verify する**」という自己言及的構造
- agent-manifesto の **P2 (検証の独立性)** の実践になる（Claude Opus で書き、Qwen で検証）

## References

- [arXiv:2604.05018 — PaperOrchestra](https://arxiv.org/abs/2604.05018)
- [Project page (yiwen-song.github.io)](https://yiwen-song.github.io/paper_orchestra/)
- [GitHub: Ar9av/PaperOrchestra (open-source impl)](https://github.com/Ar9av/PaperOrchestra)
- [MarkTechPost (2026-04-08)](https://www.marktechpost.com/2026/04/08/google-ai-research-introduces-paperorchestra-a-multi-agent-framework-for-automated-ai-research-paper-writing/)
- [Dev|Journal article](https://earezki.com/ai-news/2026-04-09-google-ai-research-introduces-paperorchestra-a-multi-agent-framework-for-automated-ai-research-paper-writing/)

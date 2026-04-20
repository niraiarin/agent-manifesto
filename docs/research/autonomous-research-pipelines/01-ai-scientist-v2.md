# Survey 1: AI-Scientist-v2 (SakanaAI, 2026-04)

> **Parent Issue**: #642
> **Survey Sub-Issue**: SS1
> **Status**: 深堀サーベイ完了 (2026-04-20)
> **Primary Source**: [arXiv:2504.08066v1](https://arxiv.org/abs/2504.08066) (Yamada et al., 2025-04-10), [GitHub: SakanaAI/AI-Scientist-v2](https://github.com/SakanaAI/AI-Scientist-v2)

---

## 1. What is it

AI-Scientist-v2 は、AI 研究論文を**完全自律生成**するエンドツーエンド system。
前身 v1 が要求したタスク特化 code template への依存を排除し、**domain-general**
に展開可能となった後継実装。

最大の実績: ICLR 2025 workshop (ICBINB) へ 3 本を blind 投稿し、
うち **1 本が人間 reviewer の合格ラインを超えた**（reviewer scores 6, 7, 6, mean 6.33, top 45%）。
AI 単独生成論文の peer review 通過の最初の事例。

## 2. 3-stage Pipeline

```
┌──────────────┐   ┌──────────────────────┐   ┌──────────────┐
│ Idea         │   │ Tree-Based           │   │ Paper        │
│ Generation   │──▶│ Experimentation      │──▶│ Write-Up     │
│              │   │  (4 sub-stages)      │   │              │
└──────────────┘   └──────────────────────┘   └──────────────┘
       │                      │                      │
 Novelty check          Experiment Manager     Plotting + VLM
 (Semantic Scholar)     + Parallel workers     Manuscript template
 Idea scoring           Node types (B/R/H/A/Agg) Single-pass + reflection
 Archiving              Best-first selection   LLM paper reviewing
```

### 2.1 Idea Generation (§3.1)

- **入力**: workshop topic を書いた markdown (`my_research_topic.md`)
- **LLM が open-ended な hypothesis を 20 件ほど生成**、grant-proposal 相当の抽象度
- **Novelty check**: Semantic Scholar API で既存研究と照合
- **Scoring + archiving**: scoring と prompt improvement をループ (`--num-reflections 5`)
- **出力**: 構造化 JSON (`my_research_topic.json`)

### 2.2 Tree-Based Experimentation (§3.2) ★中核

**Experiment Progress Manager** が 4 段階を coordinate:

| Stage | 目的 | 停止条件 |
|-------|------|---------|
| Stage 1 | Preliminary Investigation: 最小動作 prototype 確立 | 基本 prototype が走る |
| Stage 2 | Hyperparameter Tuning: lr/epochs 等を最適化 | training 曲線が収束し ≥2 dataset で成功 |
| Stage 3 | Research Agenda Execution: 核心的な研究 agenda 実行 | 計算予算枯渇 |
| Stage 4 | Ablation Studies: 各 component の重要度評価 | 計算予算枯渇 |

- 各 stage の終わりで **LLM evaluator が best node を選択** → 次 stage の root となる
- 各 stage 完了時に **replication runs** を走らせ mean/std を確保

#### Node Types（Figure 2）

| Type | 生成条件 | 役割 |
|------|---------|------|
| Buggy | 実行エラー or VLM 不合格 | debug 候補 |
| Non-buggy | 実行成功 + VLM 合格 | refinement 候補 |
| **Hyperparameter** | Stage 2 | hp 探索 |
| **Ablation** | Stage 4 | component 削除評価 |
| **Replication** | 各 stage 末 | 異なる seed で mean/std 計算 |
| **Aggregation** | replication 群の末端 | 新実験せず結果集約のみ |

#### Search Mechanics (§3.2.2)

- 各 iteration で複数ノードを**並列 expand**
- **debug_prob** の確率で buggy node を優先選択（error resolution 優先）
- それ以外は **best-first search** で non-buggy node を選ぶ (metrics + training dynamics + plot quality)
- **max_debug_depth** を超えた分岐は放棄
- 各 node = { 実験 script, 実行 trace, metrics, LLM feedback, plot 生成 script, figure path list, VLM feedback, 最終ステータス }

### 2.3 Paper Write-Up (§3.4 + Figure 1)

**v1 から大改革**: v1 の incremental Aider-based iteration を廃し、
**single-pass generation + reflection stage** に変更（推論モデル o1 系を想定）。

構成:

1. **Plotting + VLM Feedback**: numpy で保存された metrics を python で可視化 → VLM が批評
   - 不明瞭 label / missing legend / 誤解を招く可視化 → node を "buggy" に格下げ
2. **Manuscript Template**: LaTeX template (workshop-size, 4-page limit 等)
3. **Manuscript**: single-pass で全セクション draft
4. **LLM Paper Reviewing (reflection)**: VLM が fig-caption alignment / visual clarity / fig 重複を検査
5. **Citation rounds**: `--num_cite_rounds 20` で Semantic Scholar 経由で citations を集め refining

#### Command
```bash
python launch_scientist_bfts.py \
  --load_ideas "ai_scientist/ideas/my_research_topic.json" \
  --load_code \
  --add_dataset_ref \
  --model_writeup     o1-preview-2024-09-12 \
  --model_citation    gpt-4o-2024-11-20 \
  --model_review      gpt-4o-2024-11-20 \
  --model_agg_plots   o3-mini-2025-01-31 \
  --num_cite_rounds 20
```

## 3. 出力物とディレクトリ構造

```
experiments/
 └── timestamp_ideaname/
     ├── logs/
     │   └── 0-run/
     │       └── unified_tree_viz.html        # 探索木の interactive 可視化
     └── timestamp_ideaname.pdf                # 最終 manuscript (20-30 min)
ai_scientist/
 └── ideas/
     ├── my_research_topic.md                  # input
     └── my_research_topic.json                # ideation output
bfts_config.yaml                              # 探索設定
```

**bfts_config.yaml の主要 param**:
- `num_workers`: 並列 worker 数
- `steps`: 最大 node 展開数
- `num_seeds`: 独立 seed 数（< 3 なら num_workers と同じ、≥ 3 なら 3）
- `max_debug_depth`: 1 node あたりの debug 最大試行
- `debug_prob`: buggy 優先確率
- `num_drafts`: Stage 1 の root 数（独立 tree の本数）

## 4. Follow-up Research Tracking

**v2 paper 本文内では明示的な follow-up 追跡機構は記述されていない**。
Single-shot execution を前提とし、「本 manuscript で何が未解決か」は paper 本文の
Discussion / Limitations セクションに LLM が書き込むのみ。

Related Work (§6) で競合として CycleResearcher (Weng et al., 2025) を挙げ、
これが ideation → draft 中心で実験を除外している点を対比。

## 5. Limitations（自己申告、§5）

1. **Workshop 止まり**: ICLR/ICML/NeurIPS main track 水準には未達（workshop accept 率 60-80% vs main 20-30%）
2. **Citation hallucination**: 引用の不正確性が頻発
3. **Methodological rigor の不足**: main conference に求められる深さが欠ける
4. **Novel hypothesis 創出の弱さ**: LLM-generated ideas は novel だが feasibility が低い (Si et al., 2025)
5. **Foundation model 依存**: 成功率は完全に LLM の能力に律速される

## 6. 我々の p2-verified.jsonl 論文化への示唆

| AI-Scientist-v2 の機構 | 我々への applicability |
|----------------------|----------------------|
| **Experiment Progress Manager** による 4-stage coordination | ★ jsonl token → 論文の pipeline を明示的 stage 化できる。我々は「検証 → narrative 収集 → 章立て → draft → refinement」の 5-stage 化が良い |
| **Tree-based experimentation** | ✗ 我々は単一 session の linear な検証の後処理なので tree は不要。stage 内 linear で十分 |
| **VLM feedback for figures** | △ 我々は図が少ない（主に表）。除外可 |
| **Single-pass writeup + reflection** | ★★ これを採用する。**Aider-based 反復は我々の文脈（local LLM）では過重**、reasoning model (Claude Opus + extended thinking) で single-pass + reflection が適切 |
| **Citation rounds with Semantic Scholar** | △ 外部研究引用は少数。代わりに **internal citation** (自 PR/issue/commit) を強化すべき |
| **LaTeX page length constraint を prompt に含める** | ★ 文字数上限を明示すると冗長性が抑制される |
| **logs/0-run/ の構造化保存** | ★★ evidence archive の直接の参照パターンになる |
| **bfts_config.yaml** による設定の外部化 | ★ paperize.yaml を用意、model 指定・k_rounds・section 構成等を外部化 |

### Key takeaway

AI-Scientist-v2 の中核貢献は **Experiment Progress Manager (EPM)** と **tree search**。
我々の要件では tree 探索は不要だが、**EPM 相当の stage coordinator**（orchestrator） が
writeup の複雑さを管理する設計は採用すべき。

具体的には:
- jsonl の token をグルーピングして**複数の "research arc"** として認識
- 各 arc に対し 4 段の stage（observation / narrative / draft / refinement）を EPM 管理
- Best-node selection の代わりに **先行 PR #637 の Verifier で論文 draft を quality gate**

## 7. 再現性確認

**実運用コスト**:
- Ideation: 数ドル
- 実験 run: Claude 3.5 Sonnet で $15-$20 / run
- Writing phase: default model で約 $5 / run

我々の用途（1 session 1 paper）では **write phase のみ必要**。実験 phase (agentic tree search) は
既に Verifier 検証で代替済み。

**依存**:
- OpenAI / Gemini / AWS Bedrock (Claude) の API key
- Semantic Scholar API key (optional)
- conda + poppler + chktex
- Python 3.11

我々の文脈では: **Claude Code が既に備える機能で writeup 相当を代替可能**（WebFetch, LaTeX生成, pandoc 呼び出し）。

## 8. 結論

AI-Scientist-v2 から採用すべき要素:
1. **Stage-based orchestration** (EPM 相当)
2. **Single-pass writeup + reflection stage**（Aider-style iteration を避ける）
3. **Page length constraint in prompt**
4. **構造化保存** (`logs/` に相当するディレクトリ)
5. **外部設定 file**（`paperize.yaml`）

我々の文脈で不要な要素:
1. Tree search（既に検証済みの token 群が入力なので探索不要）
2. VLM feedback（図が少ない）
3. Ideation phase（既に実行された検証の後処理が我々の要件）

## References

- [arXiv:2504.08066 — The AI Scientist-v2: Workshop-Level Automated Scientific Discovery via Agentic Tree Search](https://arxiv.org/abs/2504.08066)
- [GitHub: SakanaAI/AI-Scientist-v2](https://github.com/SakanaAI/AI-Scientist-v2)
- [Sakana Blog: AI Scientist First Publication](https://sakana.ai/ai-scientist-first-publication/)
- Local PDF snapshot (webfetch result, 8.5 MB, pages 1-20 read)

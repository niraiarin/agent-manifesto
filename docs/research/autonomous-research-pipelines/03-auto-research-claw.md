# Survey 3: AutoResearchClaw (aiming-lab, 2026)

> **Parent Issue**: #642
> **Survey Sub-Issue**: SS3
> **Status**: 深堀サーベイ完了 (2026-04-20)
> **Primary Source**: [GitHub: aiming-lab/AutoResearchClaw](https://github.com/aiming-lab/AutoResearchClaw)

---

## 1. What is it

**"Fully autonomous & self-evolving research from idea to paper"**。
AI-Scientist-v2 と同じ end-to-end scope だが、v2 より新しく、
**self-healing / multi-agent debate / HITL (Human-in-the-Loop)** に強み。

Tagline: "Chat an Idea. Get a Paper. 🦞"

**我々の文脈で特に注目すべき点**:
- 6 カテゴリの **Knowledge Base** による follow-up 追跡
- **MetaClaw** による **cross-run 学習**（前の run の lessons を次の run が使う）
- **30-day time decay** による知識退役（P3 と自然に対応）
- **SmartPause**: 動的な介入タイミング判定
- ACP-compatible で **Claude Code, Codex CLI, Gemini CLI, Copilot CLI 等**で動作

## 2. 23-Stage 8-Phase Pipeline

| Phase | Stages | 主要機能 |
|-------|--------|---------|
| **A Scoping** | 1-2 | topic → problem tree, research questions 抽出 |
| **B Literature** | 3-6 | OpenAlex / Semantic Scholar / arXiv から論文収集・スクリーニング・knowledge cards 構築 |
| **C Synthesis** | 7-8 | Multi-agent debate (Innovator / Pragmatist / Contrarian) で hypothesis 生成 |
| **D Design** | 9-11 | Hardware-aware experiment design, code 生成, resource 計画 |
| **E Execution** | 12-13 | Sandbox 実行, NaN/Inf fast-fail, **self-healing 最大 10 round** |
| **F Analysis** | 14-15 | Multi-agent 分析 → **PROCEED / REFINE / PIVOT** 自律判定 |
| **G Writing** | 16-19 | Outline → draft → peer review → revise (length guard + anti-disclaimer) |
| **H Finalization** | 20-23 | Quality gate (NeurIPS checklist, AI-slop detection), archive, LaTeX export, citation verify |

### 2.1 各 Phase の Stage 詳細（抜粋）

#### Phase A: Scoping
- Stage 1 (TOPIC_INIT): topic を structured problem tree に分解
- Stage 2 (PROBLEM_DECOMPOSE): research questions を抽出

#### Phase B: Literature Discovery
- Stage 3 (SEARCH_STRATEGY): Multi-source query expansion
- Stage 4 (LITERATURE_COLLECT): OpenAlex + Semantic Scholar + arXiv から取得
- Stage 5 (LITERATURE_SCREEN) **[GATE]**: relevance filtering
- Stage 6 (KNOWLEDGE_EXTRACT): Knowledge cards 構築

#### Phase C: Knowledge Synthesis
- Stage 7 (SYNTHESIS): Cluster findings, identify gaps
- Stage 8 (HYPOTHESIS_GEN): **Multi-agent debate** で testable hypotheses

#### Phase D: Experiment Design
- Stage 9 (EXPERIMENT_DESIGN) **[GATE]**: Hardware-aware planning
- Stage 10 (CODE_GENERATION): GPU/MPS/CPU adaptive Python
- Stage 11 (RESOURCE_PLANNING): compute needs 推定

#### Phase E: Execution
- Stage 12 (EXPERIMENT_RUN): sandbox 実行 + NaN/Inf detection
- Stage 13 (ITERATIVE_REFINE): **Self-healing loop**（後述）

#### Phase F: Analysis & Decision
- Stage 14 (RESULT_ANALYSIS): Multi-agent perspective analysis
- Stage 15 (RESEARCH_DECISION): **PROCEED / REFINE / PIVOT** 自律判定（後述）

#### Phase G: Paper Writing
- Stage 16 (PAPER_OUTLINE): Conference template 構造
- Stage 17 (PAPER_DRAFT): Section-by-section (5,000-6,500 words)
- Stage 18 (PEER_REVIEW): Evidence-methodology consistency
- Stage 19 (PAPER_REVISION): Length guard + anti-disclaimer

#### Phase H: Finalization
- Stage 20 (QUALITY_GATE) **[GATE]**: 4-layer audit (NeurIPS checklist, AI-slop detection)
- Stage 21 (KNOWLEDGE_ARCHIVE): **Lessons を 30-day decay で保存**
- Stage 22 (EXPORT_PUBLISH): LaTeX + BibTeX compile
- Stage 23 (CITATION_VERIFY): **4-layer citation integrity** (arXiv ID → CrossRef/DataCite DOI → title match → LLM relevance)

## 3. Knowledge Base（★我々への示唆が大）

6 カテゴリで永続的に追跡:

| Category | 追跡内容 |
|----------|---------|
| **Decisions** | rationale, stage, timestamp, approval status |
| **Experiments** | runs, metrics, failure modes, repair history |
| **Findings** | key results, novel insights, anomalies |
| **Literature** | collected papers, extraction metadata, relevance scores |
| **Questions** | **unresolved research directions, branching paths** ← follow-up 宿題相当 |
| **Reviews** | peer feedback, evidence gaps, revision notes |

**Backend**: markdown or obsidian; root dir configurable。
**30-day time-decay**: MetaClaw integration で次の run が前の lessons を使う（間接的な forgetting）。

→ 我々の P3 学習ライフサイクル（観察→仮説→検証→統合→**退役**）の「退役」部分と
完全に対応。30-day decay は我々の "アーカイブしてから忘れる" に直接 mappable。

## 4. Self-Healing Repair Loop（Stage 13）

最大 **10 rounds** の repair:

1. Sandbox で code 実行 → NaN/Inf fast-fail
2. AST-validated code + **immutable harness** で invalid mutation を防止
3. 失敗時: **error context 付き LLM repair prompt**
4. Rerun; ≥2 条件完了 → `min_completion_rate: 0.5` 閾値で proceed
5. Partial result capture

**config.arc.yaml**:
```yaml
repair:
  enabled: true
  max_cycles: 3
  min_completion_rate: 0.5
  # Optional: "Route repairs through OpenCode Beast Mode" for complex failures
```

## 5. PROCEED / REFINE / PIVOT 判定（Stage 15）

Stage 15 で自律判定:

- **PROCEED**: 結果が hypothesis を支持 → Stage 16 へ
- **REFINE**: parameters 調整可、hypothesis 有効 → **Stage 13 に戻る**（hp 変更）
- **PIVOT**: 根本的問題 → **Stage 8 に戻る**（hypothesis 再生成）

**Artifacts auto-versioned** — 各 loop 反復が record される。
Decision rationale は Knowledge Base に log。

→ **我々の Verifier pairwise PASS / CONDITIONAL / FAIL と完全に一致**。
/evolve の既存 3 judgment とも整合する。

## 6. Anti-Fabrication: VerifiedRegistry（★最重要）

**5 つの層で捏造を防ぐ**:

1. **Experiment Diagnosis & Repair (Stage 13)**: 失敗 → repair → completion 検証
2. **Claim Verification (Stage 23)**: 4-layer citation integrity + AI-generated text から inline claim 抽出
3. **Cross-Reference Check**: ungrounded claim を flag → **hallucinated refs 自動削除**
4. **Paper Guard (Stage 20)**: 4-layer audit + **AI-slop detection** + evidence-claim consistency scoring
5. **Unverified Sanitization**: 実験で tie できない数値は redact

さらに **Sentinel Watchdog**（background monitor）が常時走行:
- NaN/Inf detection
- paper-evidence consistency
- citation relevance scoring

→ PaperOrchestra の anti-hallucination rule を **システム全体に拡張した版**。

## 7. HITL Co-Pilot: 6 Intervention Modes

| Mode | Command | 介入頻度 |
|------|---------|---------|
| **Full Auto** | `--auto-approve` | なし |
| **Gate Only** | `--mode gate-only` | 3 gates (Stages 5, 9, 20) |
| **Checkpoint** | `--mode checkpoint` | 8 phase boundaries |
| **Co-Pilot** | `--mode co-pilot` | Critical stages のみ |
| **Step-by-Step** | `--mode step-by-step` | 全 stage 後 |
| **Custom** | `--mode custom` | `stage_policies` config で per-stage |

### Key Co-Pilot 特徴

- **Idea Workshop** (7-8): hypothesis を共同 brainstorm
- **Baseline Navigator** (9): baseline 提案 + human 追加削除 + reproducibility checklist
- **Paper Co-Writer** (16-19): section ごとに human edit
- **SmartPause**: **confidence-driven dynamic intervention** — auto で「人間 input が有効」と判定した時だけ pause
- **Cost Guardrails**: budget monitoring (50% / 80% / 100% threshold で pause)
- **Intervention Learning (ALHF)**: review pattern から次回 pause 判定を最適化
- **3 Adapters**: CLI / WebSocket / MCP

→ SmartPause は **我々の「force / warn / skill-driven」3 層制御の上位版**。

## 8. 出力: `artifacts/rc-YYYYMMDD-HHMMSS-<hash>/deliverables/`

```
deliverables/
├── paper_draft.md              # 5000-6500 words 全 section
├── paper.tex                   # NeurIPS/ICLR/ICML template
├── references.bib              # real BibTeX (auto-pruned)
├── verification_report.json    # 4-layer citation integrity
├── experiment_runs/            # code + results + JSON metrics
├── charts/                     # error bars + CIs 付き figures
├── reviews.md                  # multi-agent peer review
├── evolution/                  # self-learning lessons (30-day decay)
└── [other config artifacts]
```

→ 我々の `docs/papers/YYYY-MM-DD-<slug>/` 構造設計の直接のリファレンス。

## 9. Directory Structure（researchclaw パッケージ）

```
researchclaw/
├── cli.py, config.py, prompts.py, quality.py, report.py, writing_guide.py
├── agents/            # Agent implementations
├── skills/            # Skill modules
├── llm/               # LLM interfaces
├── memory/            # Memory / state
├── knowledge/         # Knowledge base
├── literature/        # Academic lit management
├── pipeline/          # Pipeline
├── experiment/        # Experimental features
├── dashboard/         # UI
├── server/            # Server infra
├── collaboration/     # Multi-agent collab
├── feedback/          # Feedback
├── hitl/              # Human-in-the-loop
├── mcp/               # MCP integration
├── metaclaw_bridge/   # MetaClaw integration
├── overleaf/          # Overleaf integration
├── docker/            # Container configs
├── data/, utils/, voice/, web/, wizard/, templates/
└── evolution.py, evolution_aevolve.py  # 進化的アルゴリズム
```

特筆: **evolution.py + evolution_aevolve.py** — 我々の `/evolve` と同じ名前。
アルゴリズム的 self-improvement を指す。

## 10. 呼び出し / Commands

### Setup
```bash
pip install -e .
researchclaw setup   # Interactive: OpenCode, Docker, LaTeX checks
researchclaw init    # Interactive: LLM provider, config.arc.yaml
```

### Run
```bash
researchclaw run --topic "Your research idea" --auto-approve
researchclaw run --topic "..." --mode co-pilot
```

### Runtime interaction (separate terminal)
```bash
researchclaw attach artifacts/rc-2026-xxx
researchclaw status artifacts/rc-2026-xxx
researchclaw approve artifacts/rc-2026-xxx --message "LGTM"
researchclaw reject artifacts/rc-2026-xxx --reason "Missing baseline"
researchclaw guide artifacts/rc-2026-xxx --stage 9 --message "Use ResNet-50"
```

### Skills
```bash
researchclaw skills list
researchclaw skills install /path/to/skill/
researchclaw skills validate ./my-skill
```

## 11. 我々への示唆

### 11.1 完全に mappable な要素

| AutoResearchClaw | 我々のプロジェクト | 採用状況 |
|-----------------|----------------------|---------|
| **Knowledge Base 6 categories** | `todos.md` を 6 category 化 or evidence/ 内 6 ファイル | ★★★ 採用 |
| **30-day time-decay** | ephemeral jsonl の退役期限化 | ★★★ 採用 |
| **MetaClaw lessons arc-* files** | `evidence/lessons.md` で前回の paperize の反省を記録 | ★ 採用 (軽量版) |
| **PROCEED / REFINE / PIVOT** | Verifier の 3 判定と一致 | ★★★ 既に整合 |
| **Anti-fabrication 5 layer** | Verifier + evidence/ + unverified tag | ★★ 採用 (軽量版) |
| **`[UNVERIFIED]` tag** | PaperOrchestra でも同じ | ★★ 採用 |
| **Sentinel Watchdog background monitor** | 我々の hook と近い | △ 要検討 |
| **HITL SmartPause** | 我々の「force / warn / skill」3 層と同じ思想 | ★★ 採用 |
| **evolution/ directory** | 我々の /evolve と名前一致 | ★ 命名整合 |

### 11.2 我々が省略すべき要素

- **Phase A-E 全て**（我々は experiment が既に終わっている）
- **Multi-agent debate**（我々は検証済み結果を formalize するだけ）
- **Self-healing repair loop**（検証は既に終わっている）
- **OpenAlex / Semantic Scholar / arXiv**（外部論文が主題ではない）
- **NeurIPS/ICLR template**（internal report 形式で十分）
- **Dashboard / WebSocket / Overleaf**（overengineering）

### 11.3 我々の `/paperize` 設計への直接的取り込み

Knowledge Base の 6-category 構造を **todos.md のテンプレート**として採用:

```markdown
# Research Follow-ups — <paperize-slug>

## Decisions
- [DEC-001] 2026-04-20 #641 hook 追加を pair-wise verifier で承認 (margin 0.82)

## Experiments  
- [EXP-001] 2026-04-18 commit faithfulness n=52 → Gemma 84.6% vs Qwen 53.8%

## Findings
- [FIN-001] Gemma が agent-manifesto ドメインで顕著に優位 (Δ +31pp)
- [FIN-002] 1/√K decay continues to K=64

## Literature
- [LIT-001] Kwok et al. 2026 — LLM-as-a-Verifier (reproduction successful)

## Questions (← Follow-up 宿題)
- [Q-001] Chatbot Arena (#626) を HF 認証後に実施
- [Q-002] Gemini 2.5 Flash 転移性 (#616) を API 調達後に実施
- [Q-003] criteria_detail の P2 token への拡張 (issue 未起票)

## Reviews
- [REV-001] PR #641 Verifier 検証 (score: 0.82 margin, 3/3 criteria)
```

### 11.4 30-day decay の実装案

`todos.md` の `Questions` category に timestamp を持たせ、**30 日経過したものは
`evidence/expired-questions.md` に移動する script** を用意する。これが P3 退役の
構造的強制になる。

## 12. 結論

AutoResearchClaw は我々の要件の **end-to-end 版**。我々に必要な要素は:

### 採用する要素
1. **Knowledge Base 6 category 構造** → `todos.md` テンプレートの骨格
2. **30-day time-decay** → `todos.md` → `expired/` への自動移動
3. **PROCEED / REFINE / PIVOT** の呼称を我々の判定と統一
4. **[UNVERIFIED] tag** で data の出所を明示
5. **`artifacts/rc-YYYYMMDD-HHMMSS-<hash>/`** のディレクトリ命名を参考に

### 不採用の要素
1. Phase A-F (我々は writeup のみ)
2. Multi-agent debate (既に検証済み結果の formalize が目的)
3. OpenAlex/arXiv 連携 (外部引用中心ではない)
4. Dashboard / WebSocket (overengineering)

## 13. 3 先行研究の統合総括

| 項目 | AI-Scientist-v2 | PaperOrchestra | AutoResearchClaw |
|------|-----------------|----------------|------------------|
| **焦点** | end-to-end | writeup 専用 | end-to-end + HITL |
| **skills 構造** | モノリシック | **skills-based** ★ | skills + modules |
| **Input** | markdown topic | idea + exp log | topic 1 行 |
| **核心** | tree search | 5-agent pipeline | 23-stage + KB |
| **Anti-hallu.** | 弱（reported citation error） | 強（Sem Scholar + AgentReview） | 最強（5 層 + watchdog） |
| **Follow-up** | なし | なし | **Knowledge Base 6 cat** ★ |
| **Decay** | なし | なし | **30-day** ★ |
| **Open source** | ✅ | ✅ (Ar9av 実装) | ✅ |
| **我々への適用性** | △ | ★★★ | ★★ (KB のみ) |

→ **PaperOrchestra の skills-based pipeline + AutoResearchClaw の Knowledge Base** が
我々の最適解と判定。

## References

- [GitHub: aiming-lab/AutoResearchClaw](https://github.com/aiming-lab/AutoResearchClaw)
- [researchclaw package source](https://github.com/aiming-lab/AutoResearchClaw/tree/main/researchclaw)
- [README_JA (Japanese)](https://github.com/aiming-lab/AutoResearchClaw/blob/main/docs/README_JA.md)
- [SHOWCASE.md](https://github.com/aiming-lab/AutoResearchClaw/blob/main/docs/showcase/SHOWCASE.md)

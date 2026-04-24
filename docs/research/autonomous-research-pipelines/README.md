# Autonomous Research Pipelines — Survey Records

> **Parent Issue**: #642
> **Purpose**: `.claude/metrics/p2-verified.jsonl` 論文化フローの設計に向けた先行研究サーベイ
> **Status**: 3 システムのサーベイ完了 (2026-04-20)、設計は別 issue で継続

## 目的

`p2-verified.jsonl`（git 非追跡の検証トークン log）が存在する時に:
1. 調査研究の最終結果を LaTeX → PDF に論文化
2. 後続の宿題 (follow-up) を保存
3. jsonl をフラッシュ

するフローを構造的に強制したい。設計前に先行研究を深堀し、共通要素・差分要素を把握する。

## サーベイ対象 (3 システム)

| # | System | Source | Focus |
|---|--------|--------|-------|
| 1 | **AI-Scientist-v2** | SakanaAI, arXiv 2504.08066 (2025-04) | end-to-end, agentic tree search |
| 2 | **PaperOrchestra** | Google Cloud AI, arXiv 2604.05018 (2026-04) | writeup 専用, skills-based |
| 3 | **AutoResearchClaw** | aiming-lab, GitHub | end-to-end + HITL + Knowledge Base |

## 個別サーベイ記録

1. [AI-Scientist-v2 深堀サーベイ](./01-ai-scientist-v2.md)
2. [PaperOrchestra 深堀サーベイ](./02-paper-orchestra.md)
3. [AutoResearchClaw 深堀サーベイ](./03-auto-research-claw.md)

## 横断比較

| 項目 | AI-Scientist-v2 | PaperOrchestra | AutoResearchClaw |
|------|-----------------|----------------|------------------|
| **焦点** | end-to-end | writeup 専用 | end-to-end + HITL |
| **skills 構造** | モノリシック | **skills-based** ★ | skills + modules |
| **Input** | markdown topic | idea.md + exp_log.md | topic 1 行 |
| **核心機構** | 4-stage tree search + EPM | 5-agent pipeline | 23-stage + Knowledge Base |
| **Anti-hallucination** | 弱 | 強 (Sem Scholar + AgentReview) | 最強 (5 層 + Sentinel) |
| **Follow-up tracking** | なし | なし | ★ Knowledge Base 6 cat |
| **Decay mechanism** | なし | なし | ★ 30-day |
| **Refinement halt rule** | reflection 1 回 | score non-decrease 厳格 | PROCEED/REFINE/PIVOT |
| **Verifier 写像性** | △ | ★★★ | ★★ |
| **Claude Code 互換** | △ | ★★★ | ★★ |
| **我々への適用性** | △ | ★★★ | ★★ |

## 我々の設計への採用マトリクス

### 中核骨格 → PaperOrchestra
- 5-agent pipeline (Outline → [Plotting ∥ LitReview] → Writing → Refinement)
- Skills-based architecture（`.claude/skills/paperize/` に自然 mapping）
- AgentReview halt rule（score non-decrease）
- `[UNVERIFIED]` tag

### Follow-up 追跡 → AutoResearchClaw
- Knowledge Base 6 category 構造を `todos.md` に採用
  (Decisions / Experiments / Findings / Literature / Questions / Reviews)
- 30-day time decay
- PROCEED / REFINE / PIVOT 判定 → 我々の既存 Verifier 判定と一致

### Orchestration 思想 → AI-Scientist-v2
- Experiment Progress Manager 相当の stage coordinator
- Single-pass writeup + reflection stage（Aider-style iteration は避ける）
- Page length constraint を prompt に
- 外部設定 file（`paperize.yaml`）

## Dog-Fooding 機会

- **Content Refinement Agent = 我々の Verifier pairwise (PR #637)**
  - 書く AI (Claude Opus) と verify する AI (Qwen logprob) が別モデル → P2 (検証の独立性) を自然に満たす
  - AgentReview の halt rule を直接 Verifier margin に mapping

## Next Steps

[#642 の Sub-Issue SS4] で 3 サーベイを統合した設計決定へ:
1. `/paperize` skill の SKILL.md 骨格
2. `references/` に配置する prompt / rubric / halt rule 定義
3. `scripts/` に配置する deterministic helpers
4. Trigger 機構（commit hook / session end / 明示実行）の判断
5. `paperize.yaml` の schema

## References

3 サーベイ記録の末尾 References セクション参照。

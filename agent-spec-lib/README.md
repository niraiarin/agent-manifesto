# agent-spec-lib

agent-manifesto 研究プロセスの型安全な Lean 表現。

## 位置づけ

- **目的**: GitHub Issue に依存した研究プロセス記録を、Lean 4 による型安全な tree structure に再設計
- **方針**: Atlas Computing が提案した speclib 構想 (2025-01) の具体的 instance として、研究プロセス領域に特化した domain-specific library として構築
- **根拠**: `docs/research/new-foundation-survey/10-gap-analysis.md` (104 Gap + 10 Warning、Verifier 3 ラウンド PASS)

## 現状: Phase 0 Week 1 (環境準備) 完了

- [x] ディレクトリ構造
- [x] `lean-toolchain` pin (v4.29.0、GA-T8)
- [x] `lakefile.lean` (Mathlib 依存、Week 6 で LeanHammer/CSLib 追加予定)
- [x] `AgentSpec.lean` (ルート、ロードマップ記載)
- [x] `AgentSpec/Core.lean` (最小プレースホルダ、sorry 0 / axiom 0)
- [x] `lake build AgentSpec` ✓ 確認済 (exit 0, 4 jobs)
- [x] Verifier Round 1 検証済み (2026-04-17、5 件 addressable を修正)

### G5-1 Section 3.5 Week 1 完了基準からの縮小定義

G5-1 Section 3.5 の当初計画は Week 1 で「Cslib 依存確立」を要求しているが、
GA-I5 (CSLib バージョン互換性未確認、low risk) に従い **Cslib 依存は Week 6 へ延期**。
Week 1 の完了基準を「ビルド環境の確立のみ（Mathlib + lean-toolchain pin + 最小 AgentSpec module）」に縮小して解釈する。この判断根拠は `../docs/research/new-foundation-survey/10-gap-analysis.md` GA-I5 を参照。

## Phase 0 ロードマップ（G5-1 Section 3.5 参照）

| Week | 作業 | 主 Gap | 完了基準 |
|------|------|------|---------|
| **1** | 環境準備 | GA-I5, GA-I7, GA-T8 | `lake build` 通る |
| 2-3 | Spine 層 (EvolutionStep, SafetyConstraint, LearningCycle, Observable) | GA-S1 umbrella 枠組 | 4 type class + dummy instance |
| 3-4 | Manifest 移植 (T1-T8 + P1-P6 → AgentSpec/Manifest/) | GA-I7 (再定義方針) | 既存 55 axioms (2026-04-17 実測、`grep -r "^axiom [a-z]" Manifest/ --include="*.lean"` ベース、CLAUDE.md の「53 axioms」は旧値) の import 可 |
| 4-5 | Process 層 (ResearchNode, FolgeID, Provenance, Edge, Retirement, Failure, State, Rationale) | GA-S2〜GA-S8 の高リスク 7 件 | handoff state machine 型化 |
| 5-6 | Tooling 層 (`agent_verify` tactic, `VcForSkill` VCG, SMT hammer) | GA-C7, GA-C9, GA-C26 | 5 定理 hammer 自動証明 |
| 6-7 | CI (`lake test`, `lake lint`, `checkInitImports`) | GA-I9, GA-I11 | GitHub Actions green |
| 7-8 | Verification (既存 1670 theorems のうち代表 100+ 再証明) + CLEVER 風自己評価 10-20 サンプル | GA-M1, GA-E1, GA-E7 | 再証明率 > 80%, 自己評価 > 60% |

## 関連ドキュメント

- `../docs/research/new-foundation-survey/00-synthesis.md` (統合まとめ)
- `../docs/research/new-foundation-survey/10-gap-analysis.md` (Gap Analysis)
- `../docs/research/new-foundation-survey/07-lean4-applications/G5-1-cslib-boole.md` (speclib 参照)
- `../research/lean4-handoff.md` (Lean 4 学習)
- `../research/survey_type_driven_development_2025.md` (TyDD サーベイ)

## ビルド

```bash
cd agent-spec-lib
lake update   # 初回のみ (Mathlib ダウンロード)
lake build    # AgentSpec.Core をビルド
```

初回ビルドは Mathlib のため 15-30 分かかる可能性あり (GA-E9: Lean compile 性能のスケール要測定)。

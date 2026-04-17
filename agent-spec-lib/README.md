# agent-spec-lib

agent-manifesto 研究プロセスの型安全な Lean 表現。

## 位置づけ

- **目的**: GitHub Issue に依存した研究プロセス記録を、Lean 4 による型安全な tree structure に再設計
- **方針**: Atlas Computing が提案した speclib 構想 (2025-01) の具体的 instance として、研究プロセス領域に特化した domain-specific library として構築
- **根拠**: `docs/research/new-foundation-survey/10-gap-analysis.md` (104 Gap + 10 Warning、Verifier 3 ラウンド PASS)

## 現状: Phase 0 Week 1 (環境準備 + TyDD/TDD 基盤) 完了

- [x] ディレクトリ構造
- [x] `lean-toolchain` pin (v4.29.0、GA-T8)
- [x] `lakefile.lean` (Mathlib 依存、Week 6 で LeanHammer/CSLib 追加予定)
- [x] `AgentSpec.lean` (ルート、Core + Test import)
- [x] `AgentSpec/Core.lean` (**SemVer refinement type + forward codec**、sorry 0 / axiom 0 / theorem 0 — TyDD-S4 準拠)
- [x] `AgentSpec/Test/CoreTest.lean` (**10 件の behavior assertion**、`example` ベース、`rfl` / `decide` 証明)
- [x] `artifact-manifest.json` (**GA-I1 対応、agent-spec-lib 用 manifest**、依存 edge + refs + build_status)
- [x] `lake build AgentSpec` ✓ 確認済 (exit 0, 5 jobs including Test)
- [x] Verifier Round 1-2 検証済み (2026-04-17)

### TyDD / TDD 原則の適用状況

| 原則 | Week 1 での実装 |
|---|---|
| **TyDD-S1** (Types first) | `version` を `String` から `SemVer` refinement type に型化 |
| **TyDD-S4** (Refinement type, GA-S18) | `SemVer` structure で Nat 非負制約 + preRelease Option 型 |
| **TyDD-F2** (Lattice 予備、GA-S15 基盤) | `Ord` / `LE` / `LT` instance on SemVer で lexicographic 順序、Week 4-5 の `ResearchSpec` Lattice への基盤 |
| **TyDD-F6** (Codec round-trip, GA-C2) | `SemVer.render` + `SemVer.parse` の **bidirectional** codec + 個別 + 有限量化 round-trip |
| **TyDD-H3** (BiTrSpec) | 個別 example + **`Fin 5³ = 125` ケースの `decide` 網羅検証**、普遍定理は Week 2 |
| **TyDD-H7** (3-level verify、GA-M12) | L3 Lean のみ (現 Week 1)、L2 SMT は Week 6、L1 pytest は Week 7 — README に宣言 |
| **Recipe 11** (Bidirectional Codec Round-Trip Testing) | 正例 7 件 + 負例 4 件 + 有限量化 125 ケース |
| **TDD** (Red→Green→Refactor) | `AgentSpec/Test/CoreTest.lean` に **24 件 `example`** 検証 |
| **GA-W7** (termination 保証) | `partial def` 不使用、明示的 recursive + `let rec go` で termination 自動推論 |
| **GA-C27** (Trusted code 最小化) | `native_decide` 不使用、全て `rfl` / `decide` |
| **GA-I1** (artifact-manifest) | `agent-spec-lib/artifact-manifest.json` で GA- 参照 + 依存 edge + codec_completeness + tydd_alignment |
| **GA-I9** (テストカバレッジ) | Test/CoreTest.lean で 24 件 behavior assertion + 125 ケース有限量化 |
| **GA-W4** (sorry accumulation) | sorry 0、axiom 0、theorem 0 |

### Verify Strategy (TyDD-H7 Minimal Viable Pipeline, GA-M12)

TyDD-H7 は「L1 pytest → L2 +Z3 SMT → L3 +Lean」の 3 段階検証 pipeline を提案。
本基盤の段階的導入計画:

| Level | 内容 | Week 1 状態 | 計画 |
|---|---|---|---|
| **L1** | pytest / 実行時 assert (Python 層) | 未実装 | Week 7 以降の Python 層追加時に導入 |
| **L2** | Z3 SMT solver による自動放電 | 未実装 | Week 6 で LeanHammer / Duper / Lean-Auto 統合時（GA-C7、GA-I5）|
| **L3** | Lean 型検査 + `decide` + `rfl` | **実装済** | Week 1 で完了（`lake build` + 24 `example` + 125 ケース有限量化）|

Week 1 は L3 単独で TyDD-H3 BiTrSpec の round-trip 性質を:
- **個別 example 検証**: 正例 7 件 + 負例 4 件 = 11 件
- **有限量化検証**: `List.range 5 × 5 × 5 = 125` ケースを `decide` で網羅
- **順序関係検証**: SemVer lexicographic ordering の 5 ケース

L1/L2 追加は後続 Week で `verify_level : Nat` パラメータ化して選択的に実施可能。

### G5-1 Section 3.5 Week 1 完了基準からの縮小定義

G5-1 Section 3.5 の当初計画は Week 1 で「Cslib 依存確立」を要求しているが、
GA-I5 (CSLib バージョン互換性未確認、low risk) に従い **Cslib 依存は Week 6 へ延期**。
Week 1 の完了基準を「ビルド環境の確立 + TyDD/TDD 基盤（Mathlib + lean-toolchain pin + SemVer + behavior test + artifact-manifest）」と定義する。
この判断根拠は `../docs/research/new-foundation-survey/10-gap-analysis.md` GA-I5 を参照。

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

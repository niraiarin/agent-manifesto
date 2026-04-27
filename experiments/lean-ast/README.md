# experiments/lean-ast/

Research #654 + Implementation #665 で構築した、Lean 本体 parser を用いた構造編集 CLI とその関連 artifact 群。

## 概要

Claude Code の Edit tool が file 全体を context に load するのに対し、`lean-cli` は Lean 4 parser で AST を取得して byte-preserving rewrite を実行することで context 消費ゼロを実現する。`.claude/hooks/lean-cli-route.sh` が PreToolUse Edit hook として team-wide に登録され (PR #682)、対応 pattern の `.lean` 編集を自動 routing する。

背景・経緯は Research Issue #654 / Implementation Issue #665 / PR #664 / PR #682 を参照。

## ディレクトリ構成

| Path | 内容 |
|---|---|
| [`lean-cli/`](lean-cli/) | Production-ready CLI binary (4 subcommand × 8 error_kind)。Impl-A #666 |
| [`rewrite-poc/`](rewrite-poc/) | byte-preserving rewrite algorithm の PoC + 14-pattern test。Sub-E #660、Impl-B #663 で atomic rename 追加 |
| [`hooks/`](hooks/) | PreToolUse Edit hook (`lean-cli-route.sh`) と Phase 1 unit tests + Phase 2 live verification kit。Impl-E #669 |
| [`concurrency-stress/`](concurrency-stress/) | Sub-F #661 binary-level race-free 検証 (N=8 TRIALS=30 = 280 parallel) |
| [`lake-concurrency/`](lake-concurrency/) | Impl-D #668 Lake build cache concurrent race 検証 |
| [`parse-smoketest/`](parse-smoketest/) | Sub-B #657 Lean.Parser API delta smoketest |

## 設計判断 (調査ログ)

| File | 内容 |
|---|---|
| [`FINDINGS.md`](FINDINGS.md) | tree-sitter / ast-grep / lean-lsp-mcp 等の Web research 結果と却下 rationale |
| [`cli-api-spec.md`](cli-api-spec.md) | Sub-A #656 で確定した API contract (4 subcommand × 8 error_kind) |
| [`api-delta.md`](api-delta.md) | Sub-B #657 Lean.Parser / Elab API delta |
| [`build-placement-decision.md`](build-placement-decision.md) | Sub-C #658 lakefile 配置判断 |
| [`startup-bench.md`](startup-bench.md) | Sub-D #659 Profile A / Profile B 起動コスト計測 |
| [`invocation-spec.md`](invocation-spec.md) | Sub-G #662 hook invocation pattern (採用 I2: subshell + lake env) |

## 使い方

### 基本: lean-cli を直接呼ぶ

```bash
cd experiments/lean-ast/lean-cli
lake build   # 初回のみ

# 4 subcommand
lake env lake exe lean-cli parse <file>                                          # AST JSONL
lake env lake exe lean-cli query <file> --kind axiom                             # フィルタ
lake env lake exe lean-cli edit <file> --replace-body <name> "<expr>" --output <file>
lake env lake exe lean-cli insert <file> --before <name> "<decl>" --output <file>
```

Error contract: `usage=64 io_read=1 parse_failure=2 ambiguous_name=3 invalid_range=4 name_not_found=5 io_write=6 internal_error=10`。

### 自動: PreToolUse hook 経由 (team default-on)

`.claude/settings.json` に `lean-cli-route.sh` が L1 file-guard の直後に登録済 (PR #682)。Claude Code の Edit tool で `.lean` file を編集すると、対応 pattern (`axiom` / `theorem` / `def` / `abbrev` / `instance` の単一宣言) で hook が自動的に lean-cli に routing する。

- L1 file-guard が **先に** 走り、test/spec パスの skip/xit 改竄をブロックする invariant を維持
- 非対応 pattern (multi-line signature、partial body edit、attribute 変更) と test/spec パス (`/test/`, `/spec/`, `_test.lean`, `_spec.lean` 等) は passthrough → Edit が通常実行
- lean-cli 失敗時 (parse_failure / name_not_found 等) も `additionalContext` を吐いて Edit に fallback

詳細: [`hooks/README.md`](hooks/README.md) と [`invocation-spec.md`](invocation-spec.md)。

### CI

[`.github/workflows/lean-cli.yml`](../../.github/workflows/lean-cli.yml) で以下を継続検証:

- `build-and-test` matrix (macOS + Ubuntu): `lake build` + Impl-A 統合 test (7) + Sub-E byte-preserving (14) + Impl-E hook unit (4)
- `perf-regression`: 22 warm 呼び出し p95 ≤ `CI_PERF_GATE_MS` (デフォルト 250ms、dev は 130ms)
- `lake-concurrency` (opt-in): `gh workflow run lean-cli.yml -f run_lake_concurrency=true` で Impl-D Lake stress を artifact 付きで実行

## 形式化

[`lean-formalization/Manifest/Models/Instances/LeanAstCli/Assumptions.lean`](../../lean-formalization/Manifest/Models/Instances/LeanAstCli/Assumptions.lean) (Impl-C #667):

| ID | 内容 | reviewInterval |
|---|---|---|
| LA-H1 | `IO.FS.writeBinFile` の small-buffer single `write(2)` atomicity (実測 280 parallel で 0 corruption) | 365 日 |
| LA-H2 | macOS base system に `flock(1)` 非対応 (mkdir-based advisory lock を採用) | 180 日 |
| LA-H3 | `importModules` per-process startup cost ~100ms (Sub-D 実測) | 180 日 |

各 Assumption は `TemporalValidity` (`sourceRef` + `lastVerified` + `reviewInterval`) 付きで永続化、Lean toolchain / macOS / runtime 変更時に refutation triggered で再検証する。

## ステータス

| Layer | Issue / PR | 状態 |
|---|---|---|
| Research | #654 (Sub-A〜G の 8 issues #656-#662) | CLOSED GO (CONDITIONAL) |
| Implementation | #665 (Impl-A〜F の 7 issues #663, #666-#670) | CLOSED GO |
| Research + Impl 統合 PR | [#664](https://github.com/niraiarin/agent-manifesto/pull/664) | MERGED (commit `54631cc`) |
| Team-wide hook 登録 PR | [#682](https://github.com/niraiarin/agent-manifesto/pull/682) | MERGED (commit `badec33`) |

15 issues + 2 PRs。研究 → 実装 → team-wide adoption の lifecycle が完了済。

## 関連リソース

- 上位プロジェクト全体像: [`../../README.md`](../../README.md)
- 公理系: [`../../lean-formalization/Manifest/`](../../lean-formalization/Manifest/)
- CLAUDE.md (Lean ファイル編集節): [`../../CLAUDE.md`](../../CLAUDE.md#lean-ファイル編集-lean)

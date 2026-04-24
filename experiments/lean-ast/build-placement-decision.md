# Build Placement Decision — Sub-C (#658) 成果物

対象: 新 Lean metaprogram CLI (`lean-cli` 仮称) の lakefile 配置判断 (Parent #654 の Gap 3 + Gap 8 統合)。

## 調査した 2 選択肢

### Option A: 既存 `lean-formalization/lakefile.lean` に追加 `lean_exe` を定義

```lean
-- 現在の lakefile.lean (抜粋)
package «agent-manifest»
require mathlib from git "https://..." @ "master"
lean_lib «Manifest» where srcDir := "."
lean_exe «extractdeps» where root := `ExtractDeps
-- ↓ 新規追加
lean_exe «lean-cli» where root := `LeanCli
```

### Option B: 別 package として分離 (`lean-formalization-cli/` 新規)

```
lean-formalization/            ← 既存、Manifest + extractdeps
lean-formalization-cli/        ← 新規、CLI 専用
  lakefile.lean                 (require mathlib 独立)
  LeanCli.lean
```

## 前提データ

### 本 PoC (Sub-B) の Lean.Parser 単体実装

parse-smoketest は `Init` imports のみで **10 MB binary**、**0.16s user / 0.53s wall** で動作。Mathlib 非依存で自立。

### 新 CLI の想定スコープ

Manifest ファイル (例: `Manifest/Axioms.lean`) を parse する際に、その file の `import` 宣言を解決する必要がある。Manifest の import chain は `Mathlib` を含むため、**実運用 CLI は Mathlib を import せざるを得ない**。

ただし **parse-only モード** (query 用) なら環境構築をスキップして header parse のみで済ませる設計も可能 → Mathlib 非依存で動作可能。

つまり:
- Query mode: Mathlib 不要、~10 MB binary
- Edit mode (post-edit type check 付き): Mathlib 必要、~188 MB binary

Sub-A (#656) の API 設計によっては 2 binary に分ける選択肢もあり。

### Mathlib cache 現状

本 project の主 worktree `/Users/nirarin/work/agent-manifesto/lean-formalization/.lake/`:

| 項目 | サイズ |
|---|---|
| `.lake/` 合計 | 3.5 GB |
| `.lake/packages/mathlib/` | 2.3 GB |
| `.lake/build/bin/extractdeps` | 188 MB |
| 新 stub (imports なし) | 10 MB |

### 2 exe 同居 build 検証

**実施**: 既存 lakefile に仮の `lean_exe «smoketest_stub»` を追加、`lake build extractdeps smoketest_stub` を実行。

```
$ time lake build extractdeps smoketest_stub
✔ [5/7] Built SmoketestStub (153ms)
✔ [6/7] Built SmoketestStub:c.o (196ms)
✔ [7/7] Built smoketest_stub:exe (187ms)
Build completed successfully (7 jobs).
lake build extractdeps smoketest_stub  0.49s user 1.18s system 43% cpu 3.802 total
```

**結果**: 3.8s wall で両 exe build 完了。Mathlib cache は共有、extractdeps は再 build 不要 (既 cache hit)。

## Trade-off 表

| 軸 | Option A (同一 lakefile) | Option B (別 package) |
|---|---|---|
| **Mathlib cache** | 共有 (2.3 GB 1 回) | 重複 (4.6 GB: 独立 checkout × 2) |
| **並列 build 時間** | 初回 Mathlib 1 回、以降 incremental | 初回 Mathlib 2 回 (×2 時間) |
| **依存管理の複雑性** | 単一 lakefile、単一 mathlib 版 | 独立 pin、version skew リスク |
| **運用 (CI / hook 呼び出し)** | `cd lean-formalization && lake exe lean-cli` | `cd lean-formalization-cli && lake exe lean-cli`、別 path |
| **独立リリース** | 不可 (lean-formalization と一緒に pin) | 可 (CLI 単体で version 管理) |
| **Binary サイズ** | 構成 imports に依存 (構造無関係) | 同左 |
| **既存 extractdeps との共存** | 検証済: 3.8s 追加 build | 不要 (元々独立) |

## 判断: **Option A (同一 lakefile) を推奨**

### 2 軸以上で明確に優位

1. **Mathlib cache 効率**: Option B は 2.3 GB 重複 → CI / fresh checkout で build 時間 2 倍
2. **依存管理の簡潔さ**: Mathlib version pin を 1 箇所で管理。Option B では version skew で CLI と Manifest で解釈差が生じうる (CLI が parse する file と CLI が使う parser の version が違うと不整合)
3. **運用簡潔性**: 既存 `cd lean-formalization && lake exe extractdeps` と同一 pattern で呼び出し可能

### Option B の唯一の利点 (独立リリース) はこの project では不要

Lean CLI はこの project の Manifest を parse するための project-specific tool であり、外部公開や独立リリースの予定なし。将来的に外部公開したくなったら分離する migration path は容易 (lean_exe を別 lakefile に切り出すだけ)。

## Gate 判定

### Gate 基準 (Sub-Issue #658 より)

> **PASS**: 1 つの選択肢が 2 軸以上（cache 効率 + 運用複雑性）で明確に優位、build 検証で `lake build` が通る

### 判定: **PASS**

- Option A が `Mathlib cache 効率` + `依存管理の簡潔さ` + `運用簡潔性` の 3 軸で明確に優位
- `lake build extractdeps smoketest_stub` が 3.8s wall で両 exe build 成功 (検証済)

### CONDITIONAL パスへの fork は不要

trade-off が拮抗していない、build 検証も通った → 新 sub-issue 起票は不要。

### Addressable finding

なし (Judge/Verifier 評価を経て 0 残存)。

## 次のアクション

- **Sub-D (#659)**: startup cost 計測の lakefile は Option A (同一 lakefile) で進める。Profile A (Mathlib なし) と Profile B (Mathlib あり) の 2 binary を追加することで 2 段階 Gate を満たす
- **Sub-G (#662)**: invocation path は `cd lean-formalization && lake env lake exe <cli>` を canonical に採用
- **Sub-E (#660)**: byte-preserving PoC も Option A の配置で実装、Elaborator smoketest で Mathlib 必要なら Profile B 側を使う

## Unaddressable

なし。

## 付記: 検証後の cleanup

実験で追加した `lean_exe «smoketest_stub»` + `SmoketestStub.lean` は検証直後に revert (git diff で lakefile pristine 確認済)。本研究の成果物として残すのは本 `build-placement-decision.md` のみ。`.lake/build/bin/smoketest_stub` は `.lake/` 内 (gitignore 対象) に残存するが無害。

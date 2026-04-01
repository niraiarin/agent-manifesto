# L1 安全境界の変更影響分析

## 使用したワークフロー

Spec-Driven Workflow の **Phase 4（保守）** に従い、`manifest-trace impact L1` で D13 推移的閉包を計算した。

---

## 1. L1 の依存関係（上流）

L1 は以下の2命題に依存している（`Ontology.lean:1114`）:

| 依存先 | 内容 |
|--------|------|
| **P1** | 自律性と脆弱性の共成長 |
| **T6** | 人間の最終決定権 |

つまり、L1 の安全境界は「P1: 自律性を拡張すれば脆弱性も増す」という原則と「T6: 人間が最終決定権を持つ」という基底公理の上に成り立っている。

---

## 2. L1 の影響範囲（下流 -- 推移的閉包）

`manifest-trace impact L1` の結果:

### 影響を受ける命題（3件）

| 命題 | 依存経路 | 内容 |
|------|----------|------|
| **L1** | （変更元） | 倫理・安全境界 |
| **D1** | D1 -> L1 | 構造的強制（L1-L6 全てを包含） |
| **D11** | D11 -> D1 -> L1 | 可観測性の運用化 |

D1（構造的強制）は L1-L6 全ての境界条件を束ねる設計原則であり、L1 が変わると D1 の前提条件が変わる。D11 は D1 に依存して可観測性の運用を規定しているため、推移的に影響を受ける。

### 影響を受ける実装ファイル（30件）

**直接的に L1 を実装しているファイル（要修正の可能性大）:**

- `.claude/hooks/l1-safety-check.sh` -- L1 の構造的強制の主防衛線
- `.claude/hooks/l1-file-guard.sh` -- L1 ファイル保護
- `.claude/rules/l1-safety.md` -- L1 の規範的ルール
- `.claude/rules/l1-sandbox-recommendation.md` -- L1 のサンドボックス推奨
- `.claude/settings.json` -- deny リスト（L1 の第二防衛線）
- `docs/implementation-boundaries.md` -- L1 の実装境界ドキュメント

**L1 を参照しているファイル（整合性確認が必要）:**

- `CLAUDE.md` -- プロジェクト全体の指示書
- `docs/design-development-foundation.md` -- D1 経由で L1 を参照
- `.claude/skills/evolve/SKILL.md`
- `.claude/skills/formal-derivation/SKILL.md`
- `.claude/skills/ground-axiom/SKILL.md`
- `.claude/skills/instantiate-model/SKILL.md`
- `.claude/skills/verify/SKILL.md`
- `.claude/agents/hypothesizer/AGENT.md`
- `.claude/agents/model-questioner.md`
- `.claude/hooks/p3-axiom-evidence-check.sh`
- `.claude/hooks/h5-doc-lint.sh`
- `scripts/check-loop.sh`
- `scripts/lint-doc-comments.py`
- `scripts/verify-preflight.sh`
- `research/claude-code-technical-spec.md`
- `research/step0b-prior-art-research.md`
- `CHANGELOG.md`, `README.md`

---

## 3. 再実行すべきテスト（22件）

### 必須: L1 直接テスト

**構造テスト（`tests/phase1/test-l1-structural.sh`）-- 8件:**

| テストID | 検証内容 |
|----------|----------|
| S1.1 | settings.json に hooks が存在する |
| S1.2 | PreToolUse Bash hook が登録されている |
| S1.3 | PreToolUse Edit hook が登録されている |
| S1.4 | PreToolUse Write hook が登録されている |
| S1.5 | deny リストが 10件以上ある |
| S1.6 | l1-safety-check.sh が存在し実行可能 |
| S1.7 | l1-file-guard.sh が存在し実行可能 |
| S1.8 | L1 rules ファイルが存在する |
| S1.9 | PostToolUse hooks が async-only |

**振る舞いテスト（`tests/phase1/test-l1-behavioral.sh`）-- 13件:**

| テストID | 検証内容 |
|----------|----------|
| B1.1-B1.8 | L1 安全チェックの実動作検証 |
| B2.1-B2.5 | L1 ファイルガードの実動作検証 |

### 推奨: 推移的影響テスト

| テストファイル | 理由 |
|----------------|------|
| `tests/phase5/test-axiom-quality.sh` | 公理の品質チェック（L1 が公理として健全か） |
| `tests/phase5/test-evolve-structural.sh` | 構造改善の整合性 |
| `tests/phase5/test-scripts-structural.sh` | スクリプト群の構造テスト |

### 安全策: 全テスト

変更が大きい場合は `bash tests/test-all.sh` で全 490+ テストを実行すること。

---

## 4. Lean 形式検証への影響

以下の Lean 定理が L1 に直接関連しており、L1 の定義変更時は `lake build Manifest` での再検証が必須:

| ファイル | 定理/定義 |
|----------|-----------|
| `Ontology.lean:1114` | `PropositionId.dependencies` の `.l1` エントリ |
| `Ontology.lean:659` | `BoundaryId.ethicsSafety` の定義 |
| `Ontology.lean:531` | `BoundaryLayer.fixed` の分類 |
| `Observable.lean:401` | `fixed_boundary_variables_mitigate_only` |
| `Traceability.lean:263` | `l1TraceMatrix` の定義 |
| `Traceability.lean:292-309` | `l1_poc_*` 定理群（閉環トレーサビリティの PoC） |
| `DesignFoundation.lean:533` | `d6_fixed_boundary_mitigated` |
| `Procedure.lean:174` | `modification_safety_chain` |

---

## 5. 変更時の推奨手順

Spec-Driven Workflow の「変更時の最小実行パス」に従う:

```
1. manifest-trace impact L1          <- 影響範囲の確認（本分析）
2. 変更を実施
3. bash tests/phase1/test-l1-structural.sh  <- 構造テスト再実行
4. bash tests/phase1/test-l1-behavioral.sh  <- 振る舞いテスト再実行
5. lake build Manifest               <- Lean 形式検証（0 sorry 確認）
6. bash scripts/trace-coverage.sh    <- カバレッジ維持確認
7. bash tests/test-all.sh            <- 全テスト回帰確認
8. /verify                           <- P2 独立検証
9. git commit (breaking change)      <- 互換性分類付きコミット
```

### 互換性分類

L1 は固定境界（`BoundaryLayer.fixed`）であり、D4 フェーズ順序の最上位に位置する。L1 の変更は:

- D1（構造的強制）の前提を変える
- D4 の「安全 -> 検証 -> 可観測性 -> 統治 -> 動的調整」の起点を変える
- 全ての後続フェーズの信頼性に影響する

したがって、ほぼ確実に **breaking change** に分類される。移行パスの明記が必須。

---

## 6. サマリ

| 項目 | 値 |
|------|-----|
| 影響命題数 | 3（L1, D1, D11） |
| 影響実装ファイル数 | 30 |
| 再実行テスト数 | 22（最小）/ 490+（安全策） |
| 影響 Lean 定理数 | 約 15 |
| 推奨互換性分類 | breaking change |
| 上流依存 | P1, T6 |

# trace-coverage.sh 19% → 100% 改善計画

## 現状分析

| 指標 | 値 |
|------|-----|
| 全命題数 | 36 (T1-T8, E1-E2, P1-P6, L1-L6, D1-D14) |
| カバー済み | 7 (T6, P4, L1, L5, D1, D5, D11) |
| 未カバー | 29 |
| カバレッジ | 19.4% |
| 総テスト数 | ~491 |
| アノテーション済み | Phase 1 のみ (25 テスト) |

## 根本原因

1. **Phase 2-5 のテストに `# @traces` アノテーションが一切ない** — Phase 1 の 2 ファイルだけがアノテーション済み
2. **trace-map.json にも Phase 1 しか登録されていない** — Phase 2-5 の ~466 テストが未登録
3. テスト自体は存在しているが、どの命題を検証しているかの宣言がない

## 改善手順

### Step 1: Phase 2-5 の既存テストにアノテーションを追加（効果: 大）

各テストファイルの `check` 呼び出しの直前に `# @traces` コメントを追加する。以下は各ファイルの分析に基づく具体的マッピング。

#### Phase 2: test-p2-structural.sh (8 テスト)

```bash
# @traces P2,E1
check "S2.1 Verifier agent definition exists" ...

# @traces P2,E1
check "S2.2 Verifier agent has model specified" ...

# @traces P2,E1
check "S2.3 Verifier agent is read-only" ...

# @traces P2
check "S2.4 Verify skill exists" ...

# @traces P2,D1
check "S2.5 P2 commit hook exists and executable" ...

# @traces P2,D1
check "S2.6 P2 hook registered in settings.json" ...

# @traces P2,E1
check "S2.7 Verify skill references D2 conditions" ...

# @traces P2,E1
check "S2.8 Verify skill references Subagent" ...
```

**新規カバー: P2, E1**

#### Phase 2: test-p2-behavioral.sh (3 テスト)

```bash
# @traces P2,D1
check_output "B2.1 High-risk commit triggers warning" ...

# @traces P2
check_output "B2.2 Non-commit command skipped" ...

# @traces P2,E1
# B2.3 Verifier agent is read-only
```

#### Phase 3: test-phase3-structural.sh (27 テスト)

```bash
# @traces P4,D1         — S3.1 PostToolUse hook
# @traces P4,D1         — S3.2 SessionStart hook
# @traces P4             — S3.3-S3.6 Metrics infrastructure
# @traces P4,D11         — S3.7 PostToolUse async
# @traces P4             — S3.8-S3.9 Metrics schema/coverage
# @traces P3,D5          — S3.25 h5-doc-lint
# @traces P3             — S3.26 p3-axiom-evidence-check
# @traces P4             — S3.27 p4-sync-counts-check
# @traces L5,D9          — S3.10-S3.24 Plugin drift tests
```

**新規カバー: P3（部分）, D9**

#### Phase 3: test-metrics-structural.sh (18 テスト)

```bash
# @traces P4,V2          — MT.4-MT.6 (V2 計測基盤)
# @traces P4,V4          — MT.7-MT.9 (V4 計測基盤)
# @traces P4,V5          — MT.10-MT.12 (V5 計測基盤)
# @traces P4,V7          — MT.13-MT.15 (V7 計測基盤)
# @traces P4,V1,V3       — MT.16-MT.18 (V1/V3 benchmark)
# @traces P4,V6          — MT.19-MT.21 (V6 artifact-manifest)
```

**新規カバー: （P4 強化）**

#### Phase 3: test-phase3-behavioral.sh (12 テスト)

```bash
# @traces P4,D11         — B3.1-B3.6 Metrics collector behavioral
# @traces P3             — B3.7-B3.8 h5-doc-lint behavioral
# @traces P3             — B3.9-B3.10 p3-axiom-evidence behavioral
# @traces P4             — B3.11-B3.12 p4-sync-counts behavioral
```

#### Phase 4: test-phase4-structural.sh (6 テスト)

```bash
# @traces P3,D1          — S4.1 Compatibility check hook exists
# @traces P3,D1          — S4.2 Hook registered
# @traces P3             — S4.3 Governed learning rules
# @traces P3             — S4.4-S4.6 Rules content
```

**P3 カバー確定**

#### Phase 4: test-phase4-behavioral.sh (4 テスト)

```bash
# @traces P3             — B4.1-B4.4 Compatibility check behavioral
```

#### Phase 5: test-dynamic-structural.sh (7 テスト)

```bash
# @traces D8             — S5.1-S5.4 Action space / D8 equilibrium
# @traces T6,D8          — S5.5 T6 human authority
# @traces D8,L4          — S5.6 Expansion defense design
# @traces D4             — S5.7 All 5 phase test dirs exist
```

**新規カバー: D8, L4, D4**

#### Phase 5: test-dynamic-behavioral.sh (6 テスト)

```bash
# @traces D8,L4          — B5.1-B5.2 Threshold checks
# @traces D8             — B5.3-B5.4 Expansion/contraction logic
# @traces D8             — B5.5 Defense design
# @traces T6             — B5.6 Human approval
```

#### Phase 5: test-axiom-quality.sh (9 テスト)

```bash
# @traces E2             — Q1 Sorry-free (形式検証の健全性)
# @traces E2             — Q2 Compression ratio (表現力)
# @traces E2             — Q3 lake build succeeds
# @traces P3             — Q4 All axioms have docstrings
# @traces D4             — Q5-Q6 Import DAG layer separation
# @traces E2             — Q7 Build warnings = 0
# @traces E2             — Q8 De Bruijn factor
# @traces P3,E2          — Q9 No unused axioms
```

**新規カバー: E2**

#### Phase 5: test-l5-ssot-structural.sh (~40 テスト)

```bash
# @traces L5             — 12.1-12.10 L5 Platform SSOT
# @traces L5,L2          — 12b.1-12b.9 Fallback strategy (L2: 資源制約)
```

**新規カバー: L2**

#### Phase 5: test-depgraph.sh (~65 テスト)

```bash
# @traces D13            — DG.01-DG.06 Dependency graph structure
# @traces D13            — DG.10-DG.13 Stats
# @traces D13            — DG.50-DG.56 Impact analysis
# @traces D13            — DG.130-DG.141 Diff
# @traces P3             — DG.150-DG.156 Classify (axiom hygiene)
# @traces D13            — DG.120-DG.128 Verify (DAG integrity)
```

**新規カバー: D13**

#### Phase 5: test-research-structural.sh (14 テスト)

```bash
# @traces P3             — 11.1-11.5 Research skill structure
# @traces D13            — 11.6 D13 reference
# @traces P3             — 11.7-11.14 Workflow, judge, gates
```

#### Phase 5: test-scripts-structural.sh (18 テスト)

```bash
# @traces P4             — SS.1-SS.6 sync-counts
# @traces P4             — CL.1-CL.5 check-loop
# @traces P2             — VP.1-VP.4 verify-preflight
# @traces D13            — MT.1-MT.3 manifest-trace derivations
```

#### Phase 5: test-evolve-structural.sh (大量テスト)

```bash
# @traces D9             — evolve skill structure, self-improvement
# @traces P3             — hypothesis lifecycle tests
# @traces T1,T2          — temporal identity / structure persistence tests
# @traces T3             — structure improvement accumulation
# @traces P5             — probabilistic interpretation
```

**新規カバー: D9, T1, T2, T3, P5**

### Step 2: trace-map.json を Phase 2-5 で拡充（アノテーションと並行）

`tests/trace-map.json` に Phase 2-5 のマッピングを追加する。方式 A（アノテーション）と方式 B（JSON）の両方から集計されるので、どちらか一方でよい。

**推奨**: アノテーション（方式 A）を正とし、trace-map.json は自動生成するスクリプトを作る方が保守コストが低い。

### Step 3: 残る未カバー命題の対策

Step 1-2 で既存テストにアノテーションを付けた後、以下の命題がなお未カバーの可能性がある。

| 命題 | 内容 | 対策 |
|------|------|------|
| **T4** | 構造は自身より長く生きる設計を含む | evolve テストで間接的にカバー可能。明示的テスト追加も検討 |
| **T5** | 改善は構造の中に蓄積する | evolve history テストでカバー可能 |
| **T7** | エージェントは構造に従うことで能力を得る | skill テストでカバー可能 |
| **T8** | 構造の改善は計測可能であるべき | metrics テスト（V1-V7）で間接カバー |
| **P1** | 構造は人間が読める形で存在する | CLAUDE.md / rules の可読性テスト追加 |
| **P6** | 失敗から学ぶ | evolve の loopback テストでカバー |
| **L3** | 計算資源の制約 | timeout / resource limit テスト追加 |
| **L6** | 外部依存の制約 | dependency テストでカバー |
| **D2** | コンテキスト分離 | verifier の独立性テスト（Phase 2）で間接カバー |
| **D3** | 段階的信頼獲得 | permission escalation テスト追加 |
| **D6** | 冪等性 | sync-counts --check の冪等性テスト追加 |
| **D7** | 再現性 | check-loop の再現性テスト追加 |
| **D10** | 明示的失敗 | hook の exit code テスト（既存）でカバー |
| **D12** | タスク設計 | task classification テスト追加 |
| **D14** | 監査可能性 | metrics JSONL の監査テストでカバー |

### Step 4: 自動化スクリプトの改善（オプション）

アノテーションから trace-map.json を自動生成するスクリプトを作成すれば、二重管理を避けられる:

```bash
#!/usr/bin/env bash
# generate-trace-map.sh — @traces アノテーションから trace-map.json を自動生成
```

## 作業の優先順位

1. **最大効果**: Phase 2-5 の既存テストに `# @traces` を追加する（~466 テスト分）。これだけで 19% → 約 80% に到達する見込み
2. **残り ~20%**: 上表の未カバー命題に対して、新規テストを追加するか、既存テストの解釈を拡張してアノテーション
3. **保守性**: trace-map.json 自動生成スクリプト

## 見積もり

| ステップ | 作業量 | カバレッジ到達見込み |
|----------|--------|---------------------|
| Step 1: 既存テストにアノテーション追加 | 2-3 時間 | ~80% (29/36) |
| Step 2: trace-map.json 拡充 | Step 1 と同時 | (同上) |
| Step 3: 不足分の新規テスト追加 | 1-2 時間 | ~95% (34/36) |
| Step 3b: 抽象命題の解釈マッピング | 30 分 | 100% (36/36) |
| Step 4: 自動生成スクリプト | 30 分 | (保守性向上) |

**合計: 約 4-6 時間で 100% 達成可能。**

核心は「テストは既にある。足りないのはアノテーションだけ」という点。テストを新規に書く必要があるのはごく一部。

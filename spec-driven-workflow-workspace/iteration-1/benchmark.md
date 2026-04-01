# Benchmark: spec-driven-workflow Iteration 1

## Assertion 結果

### Eval 1: 新規プロジェクト開始

| Assertion | With Skill | Without Skill |
|---|---|---|
| A1: Phase 参照 | PASS (Phase 0-4 全て明示) | FAIL (Step 1-5、Phase 概念なし) |
| A2: コマンド具体性 | PASS (/instantiate-model, /research, trace-coverage.sh, manifest-trace, /verify, lake build) | FAIL (具体コマンドなし) |
| A3: ツール連鎖 | PASS (Phase 0→1→2→3→4 の連鎖を最小実行パスとして図示) | FAIL (ツール連鎖なし) |
| A4: チェックポイント | PASS (0 sorry, Axiom Card, 保存拡大性, coverage 100%) | PARTIAL (「テストを全て通す」のみ) |
| A5: Lean 形式化への言及 | PASS (条件付き公理系, lake build, axiom 例4件, Axiom Card) | FAIL (Lean への言及なし) |
| A6: 定量的見積もり | PARTIAL (coverage 100% 目標のみ、工数見積もりなし) | PARTIAL (定量的非機能要件の例あり) |

**Eval 1 スコア**: With 5.5/6, Without 1.5/6

### Eval 2: 変更影響分析

| Assertion | With Skill | Without Skill |
|---|---|---|
| A1: Phase 参照 | PASS (Phase 4 保守を明示) | FAIL (Phase 概念なし) |
| A2: コマンド具体性 | PASS (manifest-trace impact L1, 9ステップの具体コマンド列) | PASS (manifest-trace impact L1, lake build, test-all.sh) |
| A3: ツール連鎖 | PASS (impact→テスト再実行→Lean build→coverage→test-all→verify→commit) | PASS (impact→テスト→Lean build→全テスト) |
| A4: チェックポイント | PASS (互換性分類=breaking change, 0 sorry, coverage維持) | PARTIAL (「全テスト」のみ) |
| A5: Lean 形式化への言及 | PASS (8件の具体的な Lean 定理/定義を列挙) | PASS (12ファイルの詳細な影響分析) |
| A6: 定量的見積もり | PASS (3命題, 30ファイル, 22テスト, 15定理) | PASS (3命題, 30+ファイル, 12 Leanファイル) |

**Eval 2 スコア**: With 6/6, Without 4.5/6

### Eval 3: カバレッジ改善

| Assertion | With Skill | Without Skill |
|---|---|---|
| A1: Phase 参照 | PASS (Phase 1 テスト計画に戻る) | FAIL (Phase 概念なし) |
| A2: コマンド具体性 | PASS (# @traces 具体例, trace-map.json, trace-coverage.sh) | PASS (# @traces 具体例, trace-coverage.sh) |
| A3: ツール連鎖 | PASS (各ファイル作業→coverage確認→次ファイルのループ) | PASS (Phase順にアノテーション→coverage確認) |
| A4: チェックポイント | PASS (各ステップ後に trace-coverage.sh で進捗確認) | PARTIAL (最終的な100%確認のみ) |
| A5: Lean 形式化への言及 | PARTIAL (Phase 1 参照のみ、Lean 詳細なし) | FAIL (Lean 言及なし) |
| A6: 定量的見積もり | PASS (ファイル別工数テーブル、合計3-4時間) | PASS (合計4-6時間) |

**Eval 3 スコア**: With 5.5/6, Without 3.5/6

## サマリ

| Eval | With Skill | Without Skill | Delta |
|---|---|---|---|
| 1: 新規プロジェクト | 5.5/6 (92%) | 1.5/6 (25%) | **+67%** |
| 2: 変更影響 | 6/6 (100%) | 4.5/6 (75%) | **+25%** |
| 3: カバレッジ | 5.5/6 (92%) | 3.5/6 (58%) | **+33%** |
| **平均** | **5.67/6 (94%)** | **3.17/6 (53%)** | **+42%** |

## タイミング

| Eval | With Skill (tokens) | Without Skill (tokens) | With Skill (sec) | Without Skill (sec) |
|---|---|---|---|---|
| 1 | 24,133 | 17,937 | 65.7 | 60.4 |
| 2 | 38,672 | 70,235 | 155.9 | 492.6 |
| 3 | 35,053 | 55,408 | 109.8 | 139.3 |
| **平均** | **32,619** | **47,860** | **110.5** | **230.8** |

## 分析

### スキルの主な価値

1. **Phase 構造による一貫性**: 全 eval で Phase 番号による明確な位置づけが提供された。without はアドホックな Step 番号
2. **コマンド連鎖の具体性**: with は実行すべきコマンドの正確な順序を提供。without は一般的なアドバイス傾向
3. **トークン効率**: with は平均 32K tokens、without は 48K tokens。スキルが「何をすべきか」を絞り込むことでトークン消費が32%削減

### 改善候補

1. **Eval 2 の差が小さい（+25%）**: without でもプロジェクトのコードを読んで具体的な分析ができた。スキルの価値は「手順の構造化」にある
2. **A5（Lean 形式化）が Eval 3 で弱い**: カバレッジ改善は実質的にアノテーション作業であり、Lean への言及が自然でない。これは問題ではなくタスクの性質
3. **工数見積もりの精度**: with はファイル別工数テーブルを出したが、without も合計見積もりは出せた

---
name: generate-plugin
user-invocable: true
description: >
  D17 state machine を駆動し、LLM の自己対話で条件付き公理系を生成し、
  Claude Code plugin を自動生成する。課題発見からパッケージングまでの
  end-to-end パイプライン。
  「plugin 生成」「generate plugin」「プラグイン」で起動。
---

# /generate-plugin — D17 自動 Plugin 生成

> D17 state machine を駆動し、一時的なエージェントの自己対話を通じて
> 条件付き公理系と Claude Code plugin を生成する。

## Manifesto Root Resolution

```bash
MANIFESTO_ROOT=$(bash .claude/skills/shared/resolve-manifesto-root.sh 2>/dev/null || echo "")
```

## D17 State Machine との対応

| D17 Step | 本スキルの Phase | 既存スキル | Verify Gate |
|----------|-----------------|-----------|-------------|
| 0 investigate | Phase 0 | /research | investigateStepValid |
| 1 extract | Phase 1 | 自己対話 (model-questioner 代替) | extractStepValid |
| 2 construct | Phase 2 | /instantiate-model scripts | constructStepValid |
| 3 derive | Phase 3 | /design-implementation-plan | — |
| 4 validate | Phase 4 | test suite | — |
| 5 feedback | Phase 5 | d17-state.sh + deferred-status.json | — |

## 状態永続化

D17 WorkflowState は `.claude/metrics/d17-state/<plugin-name>.json` に永続化。
`currentStep` は Lean と同一ロジック: 最初の null フィールドが現在のステップ。

```bash
# 状態管理
bash scripts/d17-state.sh init <plugin-name>
bash scripts/d17-state.sh current-step <plugin-name>
bash scripts/d17-state.sh transition <plugin-name> <step> <output-json>
bash scripts/d17-state.sh show <plugin-name>
```

## 実行手順

### Phase 0: 課題発見 + 調査 (D17 Step 0 investigate)

**入力**: なし（自律発見）または人間が課題を指定

**自律発見モード** (G1 で実証):
1. 運用テレメトリ（tool-usage.jsonl）からパターンマイニング
2. 仕様-実装 Gap（Lean vs hooks/tests）の検出
3. 失敗考古学（evolve-history.jsonl の rejected proposals）

**手順**:
1. 課題を特定し vision document を作成 → `runs/<plugin>/0-vision.md`
2. /research で対象プラットフォームの PD (Platform Decisions) を収集
3. PD を構造化 JSON として永続化 → `runs/<plugin>/0-platform-decisions.json`
4. verify-investigate-gate.sh で検証

**Verify Gate** (stepTransitionRisk = high):
```bash
bash scripts/verify-investigate-gate.sh runs/<plugin>/0-investigation-report.json
# investigateStepValid: passes >= 2 && categoriesCovered == total && decisions > 0 && sources > 0
```

**状態遷移**:
```bash
bash scripts/d17-state.sh transition <plugin> investigate '<InvestigationReport JSON>'
```

### Phase 1: 仮定抽出 (D17 Step 1 extract)

**自己対話プロトコル** (G3 で実証):

1. **Vision Generator**: investigation report から vision document を読み込み
2. **Vision Answerer**: model-questioner の Phase 0-1 質問に LLM 自身が回答
3. 各仮定を H 型に分類（T6: C 型は人間のみ）
4. 全仮定に TemporalValidity を付与（sourceRef, lastVerified, reviewInterval）
5. ModelSpec JSON として永続化 → `runs/<plugin>/1-model-spec.json`

**重要**: humanDecisionCount = 0（自己対話では C 型仮定を生成しない）。
人間の判断が必要な箇所は NOTE-C として記録し、T6 issue 化する。

**Verify Gate** (stepTransitionRisk = high):
```bash
bash scripts/verify-extract-gate.sh runs/<plugin>/1-model-spec.json
# extractStepValid: allHaveTemporalValidity && totalAssumptions > 0
```

**状態遷移**:
```bash
bash scripts/d17-state.sh transition <plugin> extract '<AssumptionSet JSON>'
```

### Phase 2: 条件付き公理系構築 (D17 Step 2 construct)

**手順**:
1. assumptions から Lean ファイルを生成:
   - `Assumptions.lean`: 全仮定を Lean structure として定義
   - `ConditionalDesignFoundation.lean`: 仮定から axiom/theorem を導出
2. `lake build Manifest` で検証

**Verify Gate** (stepTransitionRisk = high):
```bash
bash scripts/verify-construct-gate.sh lean-formalization Manifest
# constructStepValid: sorryCount == 0 && buildSuccess
```

**状態遷移**:
```bash
bash scripts/d17-state.sh transition <plugin> construct '<ConditionalAxiomBuildResult JSON>'
```

### Phase 3: 設計導出 + 実装 (D17 Step 3 derive)

**手順**:
1. 条件付き公理系の theorem/def から plugin の具体的成果物を導出:
   - hooks/: PreToolUse/PostToolUse hook scripts
   - hooks.json: hook 登録
   - plugin.json: メタデータ + derivedFrom トレーサビリティ
2. 各 hook script に SEP-H assumption への参照コメントを含める
3. POSIX 互換性を確保 (SEP-H9)
4. audit logging を PreToolUse 内に実装 (SEP-H10)

**状態遷移**:
```bash
bash scripts/d17-state.sh transition <plugin> derive '<DerivationOutput JSON>'
```

### Phase 4: 検証 (D17 Step 4 validate)

**手順**:
1. テストスクリプトを作成 → `runs/<plugin>/test-plugin.sh`
2. block テスト（危険操作 → exit 2）+ allow テスト（安全操作 → exit 0）
3. audit log 確認（blocked events が記録されること）
4. POSIX 互換性確認（grep -P 不使用）
5. CLAUDE_PLUGIN_ROOT 参照の正当性確認

**状態遷移**:
```bash
bash scripts/d17-state.sh transition <plugin> validate '<ValidationMetrics JSON>'
```

### Phase 5: フィードバック (D17 Step 5 feedback)

**手順**:
1. 実装中に発見された摩擦を列挙
2. 各摩擦を FeedbackAction に分類:

| FeedbackAction | トリガー | D13 リセット範囲 |
|---------------|---------|----------------|
| addAssumption | 仮定の不足 | assumptions 以降 |
| extendCoreAxiom | コア公理系の不足 | 全リセット |
| markOutOfScope | スコープ外 | validation のみ |
| improveWorkflow | ワークフロー改善 | 全リセット |

3. addAssumption → Assumptions.lean 更新 → lake build → Phase 1 に戻る
4. improveWorkflow → deferred-status.json に登録 → /evolve Observer が検出
5. 収束条件: addressable な摩擦が 0 件、または iteration >= 3

**状態遷移**:
```bash
bash scripts/d17-state.sh transition <plugin> feedback '<FeedbackAction JSON>'
```

## バンドルリソース

```
.claude/skills/generate-plugin/
├── SKILL.md                    # 本ファイル
├── scripts/
│   ├── d17-state.sh            # WorkflowState 永続化・遷移管理
│   ├── verify-investigate-gate.sh  # investigateStepValid
│   ├── verify-extract-gate.sh      # extractStepValid
│   └── verify-construct-gate.sh    # constructStepValid
└── runs/
    ├── demo-safety-plugin/     # G2 デモ用
    └── safety-plugin/          # G3-G5 実証用
        ├── 0-vision.md
        ├── 0-platform-decisions.json
        └── 1-model-spec.json
```

## 既知の制約

1. **自己対話では C 型仮定を生成できない** (T6)。人間の判断が必要な箇所は NOTE-C として記録
2. **generate-conditional-axiom-system.sh が自己対話 ModelSpec に非対応** (deferred: g5-f3)。現状は手書き Lean で代替
3. **dist/ が .gitignore で管理不能** (deferred: g5-f4)。plugin 出力先の設計変更が必要
4. **Lean ファイル生成は手動**。Assumptions.lean と ConditionalDesignFoundation.lean は LLM が直接書く

## 研究基盤

| 研究 | Issue | Judge | 実証内容 |
|------|-------|-------|---------|
| G1 課題発見 | #270 | PASS | 8 課題源、7 件自動発見 |
| G2 オーケストレーター | #271 | 4.0 | d17-state.sh + verify gates |
| G3 公理系自動生成 | #287 | **5.0** | 12 assumptions, 3 theorems, 88% recall |
| G4 パッケージング | #293 | 4.5 | 11/11 tests, 7 audit log |
| G5 フィードバック閉環 | #295 | PASS | 4 frictions → 構造反映 |

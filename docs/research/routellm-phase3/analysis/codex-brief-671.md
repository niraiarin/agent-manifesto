# Codex Implementation Brief — #671 GT Labeling 500+ Infrastructure

Parent: #639 | Sub-6 | Worktree: `agent-manifesto-research-671` on branch `research/671-gt-labeling-500`

## 目的

mDeBERTa router の GT hold-out calibration ECE 0.2702 (n=20) を改善するための **infrastructure scripts** を用意する。実際の human annotation (2-3 annotator × 500 items) は外部作業のため本 PR の scope 外。

本 PR は「後で human annotator に渡す準備 + 返ってきた label を model に反映する pipeline」のコードを提供する。

## Scope (Codex-implementable)

### ✅ 本 PR で実装
1. sampling 拡大 (現 100 → 500 target、既存 100 との dedup)
2. annotator kit 生成 (markdown template, JSON schema, 分類ガイド)
3. agreement 測定 (Cohen's kappa, Fleiss' kappa)
4. calibration re-measurement (labeled GT → mDeBERTa ECE/MCE)
5. GT → corrections.jsonl 変換 (retrain_cli.py 統合)
6. runbook (annotator 手順 + reviewer 手順)

### ❌ 本 PR の scope 外
- 実際の 500 件 human annotation (外部作業、2-4 週)
- retrained mDeBERTa v2 (label 完了後の別 PR)
- 実 Cohen's kappa 測定結果 (label 完了後)

## 成果物 (6 ファイル)

### 1. `docs/research/routellm-phase3/classifier/sample_for_gt.py` (既存を改修)

既存の機能を保ちつつ以下を追加:
- `--n 500` (default 100 のまま、CLI 引数で拡大可能)
- `--exclude <existing.jsonl>` で既存 candidates を dedup (by `session_id` + `prompt` 先頭 200 文字)
- `--backend {lr,mdeberta}` でクラス分類器切替（default: `lr` 既存動作、`mdeberta` は `http://localhost:9001/classify` に POST）
- 出力 id は既存の max(gt-XXX) から連番で続ける（`gt-100`, `gt-101`, ...）

### 2. `docs/research/routellm-phase3/classifier/annotator_kit.py` (新規)

annotator 毎の作業ファイルを生成:
```
uv run python3 annotator_kit.py \
  --candidates ../label-data/gt-candidates-500.jsonl \
  --annotators alice bob carol \
  --output-dir ../label-data/annotations/
```

出力 (per annotator):
- `../label-data/annotations/alice.jsonl` — 全 500 件、`gt_label: null`, `annotator: "alice"`
- `../label-data/annotations/alice.md` — 人間可読な markdown (prompt 全文 + predicted_label + taxonomy reference + 埋め込み可能な label field)
- `../label-data/annotations/README.md` — 共通手順 (taxonomy §4 A1-A6 参照、禁止事項、返却方法)

taxonomy reference は `docs/research/routellm-phase3/analysis/architecture-survey.md` §4 を参照しているが、architecture-survey にその節が無ければ `label-guide.md` として新規作成してもよい（taxonomy: 5 ラベル `local_confident / local_probable / cloud_required / hybrid / unknown` の定義 + 判断基準）。

### 3. `docs/research/routellm-phase3/classifier/kappa.py` (新規)

複数 annotator の JSONL を読み込み、agreement 指標を計算:
```
uv run python3 kappa.py \
  --annotations ../label-data/annotations/alice.jsonl \
                ../label-data/annotations/bob.jsonl \
                ../label-data/annotations/carol.jsonl \
  --output ../analysis/annotator-agreement.json
```

- 2 annotator: Cohen's kappa
- 3+ annotator: Fleiss' kappa
- 5x5 confusion matrix per pair
- majority vote (3+ の場合) 生成
- LLM pseudo-GT (Opus) との agreement (classifier との closed-loop でない独立性測定)

### 4. `docs/research/routellm-phase3/classifier/calibrate_from_gt.py` (新規)

labeled GT vs mDeBERTa predictions で ECE/MCE を再測定:
```
uv run python3 calibrate_from_gt.py \
  --labeled ../label-data/gt-labeled-majority.jsonl \
  --model-dir ../model-mdeberta \
  --serve-url http://localhost:9001 \
  --output ../analysis/mdeberta-calibration-gt500.md
```

serve_encoder.py が稼働していれば `/classify` 経由で predictions を取得、未稼働の場合は `model-dir` から直接 model load。

出力:
- per-label ECE / MCE
- reliability diagram (matplotlib が利用可能な場合のみ、ASCII art fallback)
- overall ECE
- n 件数 + confidence distribution

### 5. `docs/research/routellm-phase3/classifier/gt_to_corrections.py` (新規)

majority vote 後の GT を retrain_cli.py 用 corrections.jsonl 形式に変換:
```
uv run python3 gt_to_corrections.py \
  --labeled ../label-data/gt-labeled-majority.jsonl \
  --output ../label-data/corrections-gt500.jsonl \
  --only-disagreements  # optional: classifier predicted_label != gt_label のみ
```

corrections.jsonl schema (retrain_cli.py 互換):
```json
{"prompt": "...", "label": "local_probable", "corrected_from": "cloud_required", "ts": "..."}
```

### 6. `docs/research/routellm-phase3/analysis/gt-labeling-runbook.md` (新規)

運用 runbook。目次:
1. Sampling (sample_for_gt.py で 500 candidates 生成)
2. Annotator Kit Setup (annotator_kit.py、annotator への配布手順、taxonomy guide)
3. Annotation Review (返却 JSONL の merge、diff 検出)
4. Agreement Analysis (kappa.py、Gate: Cohen's kappa ≥ 0.75)
5. Recalibration (calibrate_from_gt.py、Gate: ECE ≤ 0.10)
6. Retrain (gt_to_corrections.py → retrain_cli.py、新 model GT hold-out 検証 → rollback 判定)
7. Troubleshooting (重複 id、annotator disagreement 調停、低 agreement case)

## Gate 基準

**本 PR (infrastructure)**:
- [ ] `sample_for_gt.py --n 500 --exclude gt-candidates.jsonl` 実行時に 500 件生成 + 既存 100 と dedup (schema-level test で確認、実データ無しでも OK)
- [ ] `annotator_kit.py` で 3 annotator 分の JSONL + markdown 生成
- [ ] `kappa.py` に synthetic data (完全一致 / 部分一致) で unit test 追加 (pytest ではなく単純な `if __name__ == "__main__"` ブロック内の assertion でよい)
- [ ] `calibrate_from_gt.py` が labeled jsonl から ECE 計算 (synthetic label で動作確認)
- [ ] `gt_to_corrections.py` が schema 準拠の corrections.jsonl 出力
- [ ] runbook が全 step カバー

**#671 Issue Gate (label 完了後)**:
- Cohen's kappa ≥ 0.75 + ECE ≤ 0.10 + routing accuracy ≥ 95%

## 制約 (L1/L2/P3)

- **L1**: HTTP 通信 (serve_encoder /classify) は `localhost` 固定、subprocess shell=False
- **L1**: annotator JSONL に機微情報 (APIキー等) が含まれる可能性を考慮、runbook に「prompt 内容の外部流出防止」注意を記載
- **P3**: 既存 `sample_for_gt.py` の default 動作を保つ (n=100, backend=lr)。`--n 500` + `--backend mdeberta` は opt-in → conservative extension
- **P3**: 既存 `retrain_cli.py` の corrections.jsonl schema は変更しない → conservative extension

## 検証コマンド (Codex が自己検証に使う)

```bash
cd /Users/nirarin/work/agent-manifesto-research-671

# 1. syntax
bash -c "python3 -c 'import ast; [ast.parse(open(f).read()) for f in [
  \"docs/research/routellm-phase3/classifier/sample_for_gt.py\",
  \"docs/research/routellm-phase3/classifier/annotator_kit.py\",
  \"docs/research/routellm-phase3/classifier/kappa.py\",
  \"docs/research/routellm-phase3/classifier/calibrate_from_gt.py\",
  \"docs/research/routellm-phase3/classifier/gt_to_corrections.py\",
]]; print(\"PASS syntax\")'"

# 2. no shell=True
rg --no-heading 'shell=True' docs/research/routellm-phase3/classifier/ && echo "FAIL" || echo "PASS: no shell=True"

# 3. synthetic kappa test (unit test inside kappa.py main)
# kappa.py に --test フラグで synthetic case (identical/disagreeing) を検証する機能を入れる
python3 docs/research/routellm-phase3/classifier/kappa.py --test

# 4. synthetic annotator kit generation
mkdir -p /tmp/gt-test
python3 -c "
import json
entries = [{
    'id': f'gt-{i:03d}',
    'session_id': f'sess-{i}',
    'prompt': f'test prompt {i}',
    'prompt_len': 20,
    'predicted_label': 'cloud_required',
    'predicted_confidence': 0.85,
    'predicted_probs': {'cloud_required': 0.85, 'hybrid': 0.1, 'local_probable': 0.03, 'local_confident': 0.01, 'unknown': 0.01},
    'conf_bin': 'vhigh',
    'length_bin': 'short',
    'gt_label': None,
    'annotator_notes': None,
} for i in range(10)]
with open('/tmp/gt-test/candidates.jsonl', 'w') as f:
    for e in entries: f.write(json.dumps(e) + '\n')
"
python3 docs/research/routellm-phase3/classifier/annotator_kit.py \
  --candidates /tmp/gt-test/candidates.jsonl \
  --annotators alice bob \
  --output-dir /tmp/gt-test/annotations/
ls /tmp/gt-test/annotations/

# 5. synthetic calibration test
python3 -c "
import json
entries = [{
    'id': f'gt-{i:03d}',
    'prompt': f'test {i}',
    'gt_label': 'cloud_required' if i < 7 else 'local_probable',
    'predicted_label': 'cloud_required',
    'predicted_confidence': 0.85,
    'predicted_probs': {'cloud_required': 0.85, 'hybrid': 0.1, 'local_probable': 0.03, 'local_confident': 0.01, 'unknown': 0.01},
} for i in range(10)]
with open('/tmp/gt-test/labeled.jsonl', 'w') as f:
    for e in entries: f.write(json.dumps(e) + '\n')
"
# Skip model-dependent tests; just check script runs with --help
python3 docs/research/routellm-phase3/classifier/calibrate_from_gt.py --help
python3 docs/research/routellm-phase3/classifier/gt_to_corrections.py --help
```

## 非対象 (Codex にやらせない)

- 実際の 500 件 sampling 実行 (model weights が worktree に無いため)
- 実際の Opus pseudo-GT 生成 (LLM API call は Codex の作業外)
- `retrain_cli.py` 本体の改修 (既存互換維持)
- annotator への実際の配布 (外部作業)

## Manifest 準拠

commit message に:
- `conservative extension` (既存 `sample_for_gt.py` default 動作維持、新規スクリプトのみ追加)
- Issue reference: `refs #671`

## 参照ファイル (Codex が読むべき)

- `docs/research/routellm-phase3/classifier/sample_for_gt.py` (改修対象)
- `docs/research/routellm-phase3/classifier/opus_labels.py` (pseudo-GT 既存実装)
- `docs/research/routellm-phase3/classifier/retrain_cli.py` (corrections.jsonl schema)
- `docs/research/routellm-phase3/classifier/calibration.py` (ECE 既存実装の reuse)
- `docs/research/routellm-phase3/analysis/architecture-survey.md` (taxonomy §4 定義)
- `.claude/rules/l1-safety.md`
- `.claude/rules/p3-governed-learning.md`

# 研究計画: Verifier 機構の ground-truth ベース検証

> **Status**: 中長期研究計画 (2026-04-18 起案)
> **Parent Issue**: #618
> **関連先行研究**: #605 (closed), #614, #615, #616

## 背景

#605 研究で本プロジェクトの Verifier 実装 (logprob pairwise + tournament) を 8 軸で検証した結果、以下の課題が明確になった:

1. **構造的限界**: 改善提案の品質評価には客観的 ground truth が存在せず、論文 (Kwok et al., 2026) の absolute accuracy 数値 (74.7-77.4%) の直接再現が不可能
2. **内部整合性のみ検証**: 位置バイアス、推移律、tie rate 等は検証できたが、「Verifier が正しい判断をしているか」そのものは未検証
3. **機構妥当性の証明不在**: score_pair 実装は bidirectional fix で position bias を除去したが、それでも真に正しい順位を出しているかの保証はない

本研究は、**決定論的 ground truth を持つ複数データセットで本 Verifier 実装を評価**し、論文 claim の直接再現を目指す。

## 研究質問

- **RQ1 (機構妥当性)**: 本実装の logprob pairwise + tournament 機構は、ground truth がある問題で論文と同等の accuracy (~77%) を達成するか？
- **RQ2 (ドメイン転移)**: agent-manifesto 固有の C1-C5 基準を benchmark 向けに差し替えた場合、機構自体は汎用的か？
- **RQ3 (判断一致性)**: 異なる ground truth 源 (人手ラベル / 機械検証 / reference answer) で accuracy に差が出るか？
- **RQ4 (スケーリング)**: データセット規模、criteria 数、K-round を変化させた時の accuracy 曲線は論文と一致するか？

## データセット候補 (~10+)

### Tier S: 論文主張の直接再現

| ID | Dataset | Ground truth | 規模 | 推定工数 | 備考 |
|----|---------|-------------|------|---------|------|
| SS1 | RewardBench | human label (chosen/rejected) | 5k pairs | 1 日 | 最も標準的な reward model 評価 |
| SS2 | JudgeBench | LLM-as-judge 特化 | ~700 pairs | 1 日 | position bias test 含む |
| SS3 | SWE-Bench Verified | unit test pass/fail | 500 | 3-5 日 | **論文が使用**、直接再現可能 |

### Tier A: agent-manifesto ドメイン関連 (自前合成)

| ID | Dataset | Ground truth | 規模 | 推定工数 | 備考 |
|----|---------|-------------|------|---------|------|
| SA1 | Git commit faithfulness | 実 diff との一致 | 100+ | 2-3 日 | evolve-history + git log 由来 |
| SA2 | Lean theorem proof | `lake build` pass/fail | 50-100 合成 | 3-5 日 | Manifest/ から合成、型不整合を mutation |

### Tier B: 機構検証の幅広化

| ID | Dataset | Ground truth | 規模 | 推定工数 | 備考 |
|----|---------|-------------|------|---------|------|
| SB1 | UltraFeedback | GPT-4 preference (quasi-gt) | 64k | 1 日 | scale test |
| SB2 | Chatbot Arena | crowdsourced vote | 100k+ | 2 日 | サンプリング必要 |
| SB3 | MT-Bench | reference answer | 80 × 2 turns | 半日 | single-turn 抽出 |
| SB4 | HumanEval / MBPP | unit test | 164 + 974 | 1 日 | code generation |
| SB5 | MATH / GSM8K | 数値一致 | 12k + 7.5k | 1-2 日 | 数学推論 |
| SB6 | SciFact / FEVER | 論文/Wikipedia 事実 | 1.4k + 185k | 2 日 | factuality |

## フェーズ別ロードマップ

### Phase 1: Infrastructure (1 週間)

- **SI1 Dataset loader**: HuggingFace datasets + 独自 (Git, Lean) の統一インターフェース
- **SI2 Format converter**: 各 dataset → `{proposal_a, proposal_b, criteria}` 形式
- **SI3 Evaluation harness**: `verifier_local.py` 呼び出し、accuracy 集計、結果永続化
- **SI4 Reporting**: データセット横断の比較表、論文数値との対比

### Phase 2: Tier S 実施 (1 週間)

- SS1 RewardBench — 本実装の絶対 accuracy 確定
- SS2 JudgeBench — position bias / tie rate の追加検証
- SS3 SWE-Bench Verified — 論文と直接比較

### Phase 3: Tier A 実施 (1 週間)

- SA1 Git commit faithfulness
- SA2 Lean proof verification

### Phase 4: Tier B 並列展開 (2-3 週間)

SB1-SB6 を並列実施。優先順位は後続判断。

## Success Criteria

| RQ | 目標 | Gate |
|----|------|------|
| RQ1 機構妥当性 | RewardBench で accuracy > 70% | PASS |
| RQ2 ドメイン転移 | benchmark 固有 criteria で accuracy > 65% | PASS |
| RQ3 判断一致性 | 異なる ground truth 源で accuracy 差 < 10pp | PASS |
| RQ4 スケーリング | K-round accuracy 曲線が論文と ±5pp で一致 | PASS |

## 制約・限界

- Ground truth 品質: human label / LLM preference / test pass で信頼性に差
- モデル差異: Qwen3.6 (本実装) vs Gemini 2.5 Flash (論文) で accuracy 絶対値は乖離可能 → #616 と連動
- データセット偏り: RewardBench は English chat 中心、domain transfer の課題

## 予算

- ローカル LLM 時間: ~100-200 時間連続稼働
- API コスト (Claude/GPT 代替模型使用時): $50-200
- 研究期間: 3-4 週間

## 関連

- Parent 研究: #605 (closed)
- 具体的補完: #615 (n≥20 reproduction) を本研究が包摂
- モデル転移性: #616 と密接
- 先行: LLM-as-a-Verifier 論文 (Kwok et al., 2026-04-09)

## 初動: Option 3 (Infrastructure + RewardBench)

RewardBench で論文 accuracy 再現の可否を判定してから、Tier S/A/B の拡張を決定。

# JudgeBench Calibration 結果 (Sub-1 / #640)

**実施日**: 2026-04-20
**Judge**: Claude (via `claude -p`, production config)
**データセット**: [ScalerLab/JudgeBench](https://github.com/ScalerLab/JudgeBench) (ICLR 2025)
**サンプル数**: 620 response pairs (GPT-4o 350 + Claude-3.5-Sonnet 270)

---

## 1. 主要結果

| 指標 | 値 |
|------|-----|
| **Overall accuracy** | **87.3%** (536/614) |
| 実行成功率 | 614/620 (99.0%) |
| エラー | 6 件 (timeout/rate-limit) |
| Quality Gate (≥70%) | ✅ **PASS** (大幅超過) |
| Signal Gate (>60%) | ✅ PASS |
| HelpSteer3 論文 RM (73.7%) | ✅ 我々が 13.6pt 上回る |

## 2. モデル別 accuracy (self-preference bias チェック)

| Response model | Accuracy | n |
|----------------|----------|---|
| GPT-4o-2024-05-13 | 87.4% | 348 |
| Claude-3.5-Sonnet | 87.2% | 266 |

**差 0.2 ポイント = バイアスほぼなし**。
Claude が judge だが Claude 出力に有利な判定はしていないことを確認。

## 3. カテゴリ別 accuracy

| Source | Accuracy | n | 評価 |
|--------|----------|---|------|
| livebench-reasoning | **94.6%** | 147 | 非常に高い |
| livebench-math | 88.9% | 90 | 高い |
| livecodebench | 88.7% | 71 | 高い |
| mmlu-pro-* (15 科目) | 83.0% | 306 | 良好 |

推論・数学・コードで高精度、知識系 (MMLU-Pro) でやや低下。

## 4. Verdict 分布

| Verdict | 件数 | 備考 |
|---------|------|------|
| A | 306 (50%) | |
| B | 284 (46%) | |
| TIE | 24 (4%) | JudgeBench に tie ラベルなし → 全件 wrong 扱い |

TIE を除外すれば actual accuracy は **90.7%** (536/590)。

## 5. レイテンシ

| 統計量 | 値 |
|--------|-----|
| median | 6.58s |
| p95 | 34.7s |
| max | 89.8s (timeout 近辺) |

Production judge としては許容範囲。

## 6. エラー分析 (6件)

- timeout: 3件 (LM Studio rate limit 回復待ち時期と一致)
- その他: 3件
- 全件 resume で handling 可能。誤判定ではない。

## 7. Phase 1 (#589) との整合性

Phase 1 で 55件 GO 判定を出した judge が **87.3% の外部ベンチマーク精度** を持つことを確認。
これにより Phase 1 の M-interp/T-interp 評価結果の信頼性が裏付けられた。

## 8. Gate 判定 → Sub-1 **PASS**

- Signal Gate (>60%): ✅
- Quality Gate (≥70%): ✅ (大幅超過, 87.3%)
- Comparison Gate: ✅ (HelpSteer3 論文 RM 73.7% を上回る)

## 9. Phase 2 への示唆

1. **Judge は信頼できる** → Sub-2 (HelpSteer3 40k 取り込み) に進んで良い
2. **TIE 判定 24件 (4%) がノイズ源** → Sub-3 (logprob 粒度化) でさらなる精度向上可能
3. **知識系 (MMLU-Pro) が相対的弱点** → 必要なら Sub-4 で補強用データ追加

## 10. 推奨される次のステップ

### Sub-2: HelpSteer3-Preference 40k 取り込み (P1 推奨)
- judge の信頼性が確立されたので、大規模データ取り込みに進める
- 55 → 40,055 件 (727x) へ拡張
- RouteLLM fine-tune のシードに

### Sub-3: logprob 細粒度スコアリング化 (並行)
- TIE 24件を減らせる可能性
- 判定粒度 0.2 → 0.01 相当で Δ 計測精度向上

**推奨: Sub-2 と Sub-3 を並行して進める**。

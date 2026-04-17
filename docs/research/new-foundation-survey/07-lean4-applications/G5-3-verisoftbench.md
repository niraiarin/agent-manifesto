# G5-3: VeriSoftBench — リポジトリ規模 Lean 4 形式検証ベンチマーク

**調査日**: 2026-04-17
**担当グループ**: G5-3（新基盤サーベイ）
**1 次情報**: arXiv:2602.18307 (v1, 2026-02-20), GitHub utopia-group/VeriSoftBench, project page

## 200 字要約

VeriSoftBench は 23 個の実世界 Lean 4 リポジトリから抽出した 500 proof obligation を保持する、業界初のリポジトリ規模形式検証ベンチマーク。最良モデル Gemini-3-Pro でも Pass@8 curated 41.0% / full 34.8%、Mathlib 特化 prover は 0%。G3 で扱った CLEVER (161 問) 等が個別問題レベルなのに対し、cross-module 依存と project-specific 定義を評価軸に持ち、agent-manifesto 新基盤（research tree 全体を Lean で管理）の将来評価尺度として直接採用可能。

---

## Section 1: VeriSoftBench 精読ノート

### 1.1 メタデータ

- **論文**: Xin, Chen, Durrett, Dillig, "VeriSoftBench: Repository-Scale Formal Verification Benchmarks for Lean", arXiv:2602.18307v1, 2026-02-20
- **著者所属**: Yutong Xin (UT Austin), Jocelyn Qiaochu Chen (NYU; 論文では Qiaochu Chen)、Greg Durrett (NYU), Işil Dillig (UT Austin)。1st/2nd 著者は equal contribution
- **カテゴリ**: cs.SE / cs.CL / cs.LG / cs.PL
- **リポジトリ**: https://github.com/utopia-group/VeriSoftBench（評価コード MIT、ベンチマーク対象リポジトリは原ライセンス保持）
- **プロジェクトページ**: https://utopia-group.github.io/VeriSoftBench/

### 1.2 ベンチマーク規模（定量）

| 項目 | 値 |
|---|---|
| 総タスク数 | **500 proof obligations** |
| ソースリポジトリ数 | **23 real-world Lean 4 repos** |
| curated context 平均トークン | **5,407**（通常リポ）/ **6,339**（大規模リポ） |
| full-repo context | 数十万〜数百万トークン。500 中 119 タスクが「hundreds of thousands of tokens」に到達 |
| 平均 transitive library deps | 11.2 |
| 平均 transitive project deps | 37.93（比較: Verina 3, PutnamBench 0.00） |
| 依存ネスト深度 | 約 50% のタスクが深さ ≥5、約 10% が深さ >12 |
| 最大 transitive dependencies | 480 |

### 1.3 対象領域（500 タスクの内訳）

| ドメイン | タスク数 |
|---|---|
| Applied Verification (ZK 回路、SNARK、smart contracts、最適化 など) | 195 |
| Compiler correctness | 84 |
| Type Systems | 82 |
| Frameworks (separation logic, Iris 系) | 79 |
| Semantics (PL semantics) | 60 |

### 1.4 23 ソースリポジトリ（同定分）

ArkLib, capless-lean, clean, lean-mlir, VCV-io, iris-lean, loom, splean, TTBFL, FVIntmax, juvix-lean, lean-formal-reasoning, wadray_verification, LeroyCompilerVerif, CvxLean, pcf-lean, LeanExprEvaluator, veil, verified-compiler, lean-hoare, IntroEffects, formal-snarks-project, Lentil。
最大規模は ArkLib と lean-mlir（full-context プロンプト事前生成で token 制限を回避）。

### 1.5 階層化コンテキスト構造（論文独自の工夫）

1. **Library** 層: Lean stdlib + Mathlib（平均 15.8 defs, 11.8 lemmas）
2. **Project** 層: リポジトリ全体定義（平均 33.7 defs, 7.8 lemmas）
3. **Local** 層: 同一ファイル（平均 5.6 defs, 5.4 lemmas, 約 1,673 chars）
4. **Theorem** 層: 対象 statement のみ

この 4 層は agent-manifesto の研究ツリー（axiom / theorem / application 層）と構造的に対応。

### 1.6 評価指標と protocol

- **指標**: `proof_success_rate_wo_fix` と `proof_success_rate_w_fix`（repair rounds あり / なし）
- **デフォルト**: Pass@k（k=1, 8）, 修復 r=3 rounds
- **context モード**: `filtered_context`（静的解析で依存抽出）と `full_context`（全リポジトリ）
- **成功判定**: k 候補 + 修復提案のいずれかが Lean 4 kernel で検証通過
- **サブセット**: VeriSoftBench-Aristotle（100 タスク）— 商用プロバーが API 制約で full 500 を回せないため

### 1.7 LLM 性能（Pass@8, r=3）

| モデル | Curated Context | Full Repo Context |
|---|---|---|
| Gemini-3-Pro | **41.0%** | **34.8%** |
| Claude Opus 4.5 | 31.2% | 23.2% |
| GPT-5.2 | 12.6% | 10.8% |
| Gödel-Prover-V2 (Mathlib 特化) | 5.6% † | **0.0%** ‡ |

† Curated Context 条件（500 task、context を依存抽出して与える）下での成績。Mathlib 外の project 定義には弱い。
‡ Full Repo Context 条件（500 task、リポ全体を context に含む）下での成績。Mathlib 外の定義解決に全滅し 0%。

VeriSoftBench-Aristotle（100 タスク）:
- Aristotle: **69%** (full context variant)
- Gemini-3-Pro: 65%

**重要観察**:
1. Mathlib 特化 prover は 0〜5.6% と崩壊 → 汎用 LLM の code reasoning 能力が優位
2. curated context が full repo を上回る（コンテキスト圧縮の必要性）
3. Spearman r=−0.359 (p<0.001): transitive dependency 数と成功率に中程度の負相関

### 1.8 失敗パターン

明示的 taxonomy は無いが、観察として:
- "多数の近傍シンボルの存在" ではなく "**multi-step derivation path を辿る**" ことに失敗
- 深さ ≥5 の依存ネストで成功率が顕著に低下
- Mathlib 特化モデルは project-specific な定義展開（unfold/simp lemma 選択）に対応不能

### 1.9 Dafny/F*/Coq への言及

- **Dafny**: DafnyBench を verification-oriented benchmark として引用（未評価）
- **Coq/Rocq**: 代替 ITP として言及のみ
- **F***: 言及なし
- 本論は **Lean 4 専用**

---

## Section 2: 既存ベンチマークとの比較（G3 調査との差別化）

G3 既調査ベンチマーク（CLEVER 161 問, VeriBench, VerifyThisBench, Vericoding, Verina）はすべて **個別問題レベル**（standalone、Mathlib 共有エコシステム内）。VeriSoftBench は **repository-scale** という新次元を持つ。

| ベンチマーク | 規模 | 言語 | Project-specific defs | Multi-module | Repo retrieval | Ground-truth proof |
|---|---|---|---|---|---|---|
| MiniF2F | ~488 | Lean | - | - | - | partial |
| ProofNet | ~371 | Lean | - | - | - | partial |
| PutnamBench | ~640 | Multi | - | - | - | partial |
| CLEVER (G3) | **161** | Lean | - | - | - | ✓ |
| Verina | ~189 | Lean | limited | - | - | ✓ |
| FVAPPS | ~4715 | Dafny/Lean | - | - | - | - |
| VeriBench (G3) | ~200 | Lean | - | - | - | partial |
| MiniCodeProps | ~177 | Lean | - | - | - | partial |
| **VeriSoftBench** | **500** | **Lean 4** | **✓** | **✓** | **✓** | **✓** |

平均 transitive project dependencies: VeriSoftBench **37.93** vs Verina 3 vs PutnamBench 0.00 — 2 桁の差。

### G3 との相補性

- **G3 CLEVER 等**: 個別 theorem の spec→proof 合成能力を測る → agent-manifesto の個別 axiom 証明や小規模 skill 改善の評価に適合
- **G5-3 VeriSoftBench**: リポジトリ全体の依存を解決しつつ証明を構成する能力を測る → agent-manifesto 新基盤（research tree 全体を Lean 化）の **統合評価** に適合

両者は評価尺度として **直交**。G3 は "局所品質"、G5-3 は "大域整合性" を測る。

---

## Section 3: 新基盤への適用案

### 3.1 採用可能性：高

理由:
1. 新基盤のコンセプト（research tree 全体を Lean で管理）と VeriSoftBench の設計思想（cross-file dependency, project-specific defs）が完全一致
2. ベンチマーク・データセット・評価コードが MIT で公開
3. 現時点で SOTA が 41% と余地が大きい → 新基盤での改善を示しやすい
4. 4 層階層化コンテキスト（Library / Project / Local / Theorem）が manifest の axiom / derivation / application 階層に自然写像

### 3.2 再帰評価：agent-manifesto 自身を課題として定義

**提案**: `lean-formalization/Manifest/` を 24 番目のソースリポジトリとして VeriSoftBench 形式に packaging し、以下を評価する:

- **定量**: 55 axioms / 1670 theorems / 0 sorry (2026-04-17 実測) から、各 theorem を「proof obligation タスク」として抽出 → Pass@8, r=3 で LLM 性能を測る
- **自己参照**: T1/T2/P2/P3/P4/V1-V7 の公理系そのものが benchmark 対象 → agent 自身がそれを解けるか測れる（D9 自己適用の実装）
- **比較軸**: agent-manifesto の dependency 平均深度を 23 個の既存リポと並べる → 設計品質の客観指標

### 3.3 Phase 別メトリクス

| Phase | VeriSoftBench 由来メトリクス | 目標 |
|---|---|---|
| Phase 0 (基盤) | proof_success_rate_wo_fix（自リポ内、curated） | ≥ 50% |
| Phase 1 (公理拡張) | 新規追加 axiom の dependency nesting depth 分布 | median ≤ 3 |
| Phase 2 (research tree 統合) | cross-module invariant 検証成功率 | ≥ 40% |
| Phase 3 (multi-instance) | full_repo context での Pass@8 | ≥ curated の 80% |
| Phase 4 (self-improve) | repair round r に対する回復率曲線 | r=3 で +15pp |
| Phase 5 (評価) | Gemini-3-Pro ベースラインからの Δ | ≥ +5pp |

### 3.4 評価コスト（新基盤での推定）

- 500 タスク × Pass@8 × 3 repair rounds = 最大 12,000 LLM 呼び出し
- Gemini-3-Pro/Claude Opus 4.5 API で概ね数百ドル〜数千ドル
- Lean 4 kernel 検証は CPU のみ、タスクあたり秒〜分のオーダー
- 自リポのみを対象にすれば 1670 theorem × 8 × 3 ≈ 40,080 呼び出し（サブセット抽出すれば削減可）

---

## Section 4: 限界と未解決問題

1. **依存解析の精度**: `filtered_context` は静的解析ベース。動的に展開される simp lemma / typeclass instance は取り逃す可能性
2. **Lean 特化**: Dafny/F*/Coq ベンチマークとの cross-language 比較は未整備。新基盤が多言語展開する場合に課題
3. **Pass@1 値の非公開**: 論文は Pass@8 中心。単発応答の信頼性を測るには追加実験が必要
4. **Leaderboard 不在**: GitHub README に公式 leaderboard なし。community adoption は未成熟（v1 公開から約 2 ヶ月）
5. **specialized prover の再評価**: Gödel-Prover-V2 0% は Mathlib 偏重の結果。RLHF/RL を project-context で再訓練した場合の上限は未知
6. **Ground-truth proof の品質**: 500 proofs すべてが最短・最適とは保証されない。LLM が異なる valid proof を出した場合の評価方針は曖昧
7. **agent-manifesto 固有の問題**: 本リポは Lean で書かれた "設計原則" であり、従来の "verified software" とは性質が異なる。VeriSoftBench の前提（リポが実ソフトウェアの正しさを証明する）から外れる可能性
8. **再帰評価のバイアス**: agent-manifesto を自己ベンチマーク化する場合、学習データリークの危険（Claude/GPT が本リポを訓練時に見ている可能性）

---

## Section 5: 出典 URL リスト

### 1 次情報
- [VeriSoftBench arXiv abstract (2602.18307)](https://arxiv.org/abs/2602.18307)
- [VeriSoftBench arXiv HTML v1](https://arxiv.org/html/2602.18307v1)
- [GitHub utopia-group/VeriSoftBench](https://github.com/utopia-group/VeriSoftBench)
- [VeriSoftBench project page](https://utopia-group.github.io/VeriSoftBench/)

### 比較ベンチマーク（G3 既調査含む）
- [VeriBench (OpenReview)](https://openreview.net/forum?id=rWkGFmnSNl)
- [Verina (arXiv:2505.23135)](https://arxiv.org/pdf/2505.23135)
- [Vericoding benchmark (arXiv:2509.22908)](https://arxiv.org/pdf/2509.22908)
- [Towards Repository-Level Program Verification with LLMs (arXiv:2509.25197)](https://arxiv.org/pdf/2509.25197)

### BibTeX
```bibtex
@misc{xin2026verisoftbenchrepositoryscaleformalverification,
  title={VeriSoftBench: Repository-Scale Formal Verification Benchmarks for Lean},
  author={Yutong Xin and Qiaochu Chen and Greg Durrett and Işil Dillig},
  year={2026},
  eprint={2602.18307},
  archivePrefix={arXiv},
  primaryClass={cs.SE},
  url={https://arxiv.org/abs/2602.18307}
}
```

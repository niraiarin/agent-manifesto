# G5-4: LeanDojo eco-system サーベイ

**担当グループ**: G5-4
**調査日**: 2026-04-17
**調査対象**: LeanDojo (NeurIPS 2023) および傘下プロジェクト群 (Lean Copilot, LeanAgent, LeanProgress, LeanIDE, TorchLean, BRIDGE, ReProver, LeanDojo-v2)
**目的**: 新基盤 (agent-manifesto-new-foundation) が Lean 4 研究プロセス管理を実装する際に、LeanDojo eco-system をどのレイヤで採用・差別化するかの判断材料を提供する。

## 200 字要約

LeanDojo は Caltech/Princeton Anandkumar 研を中心とする Lean 4 AI 証明 eco-system で、データ抽出・Python IPC・ベンチマーク (98,734 定理) を基盤に、ReProver (retrieval), LeanAgent (lifelong learning), LeanProgress (progress 予測), LeanDojo-v2 (統合フレームワーク) が連携する。新基盤は LeanDojo Python API を観測レイヤとして採用し、Gate 判定に LeanProgress、研究 Worker に LeanAgent パターンを転用し、マニフェスト公理系を LeanDojo Benchmark 形式で配布する方針で差別化可能。

---

## Section 1: LeanDojo (コア) 精読ノート

### 1.1 定義と目的

LeanDojo は Lean 4 リポジトリから (a) 証明データ (proof states, tactics, premises) を抽出し、(b) Lean プロセスとプログラム的に対話する Python ツールキット。NeurIPS 2023 (Datasets and Benchmarks Track) で発表。「Lean を gym-like な環境に変える」ことが設計思想の中心。

### 1.2 定量データ (一次情報)

| 指標 | 値 | 出典 |
|------|-----|------|
| LeanDojo Benchmark (Lean 3) | 98,734 定理 / 217,776 tactics / 130,262 premises | leandojo.org/leandojo.html |
| LeanDojo Benchmark 4 (Lean 4) | 122,517 定理 / 259,580 tactics / 167,779 premises | leandojo.org/leandojo.html |
| mathlib commit (benchmark 基点) | 19c869efa56bbb8b500f2724c0b77261edbfa28c | 同上 |
| GitHub star 数 (lean-dojo/LeanDojo) | 789 | github.com/lean-dojo/LeanDojo |
| Fork 数 | 117 | 同上 |
| 総コミット数 | 623 | 同上 |
| 最終リリース | v4.20.0 (2025-06-13) | 同上 |
| 対応 Lean version | v4.3.0-rc2 以降 | 同上 |
| 対応 Python version | 3.9 <= Python < 3.13 | 同上 |
| ライセンス | MIT | 同上 |

### 1.3 Python API (一次情報から確認済の要素)

- **trace**: Lean リポジトリ全体を追跡し、証明データを JSONL として抽出
- **Dojo class**: 証明環境 (gym-like) への interactive session
- **LeanGitRepo**: Git リポジトリ参照の抽象化
- **Theorem**: 定理単位のデータ構造 (full name, file path, source positions, URL, commit, statement)
- **IPC**: 元来 LeanDojo 本体は Lean プロセスと外部通信 (v1 系では Docker 依存)、v2 および LeanDojo-v2 は **Pantograph** (Lean 4 内で完結) に移行し、Docker 不要化・高速化

### 1.4 評価ワークフロー

- プロバー (ReProver 等) が Best-first Search で戦術を生成
- "proof within 10 minutes" を完了条件として評価
- miniF2F で 33 件、ProofNet で 39 件の新規証明が ReProver により発見済 (報告値)

### 1.5 システム要件

- Git >= 2.25, wget, elan
- GitHub 個人アクセストークン (rate limit 回避)
- Linux / Windows WSL / macOS
- 開発言語比: Python 69.2%, Jupyter Notebook 20.6%, Lean 10.2%

### 1.6 貢献機関と継続性

- コア機関: California Institute of Technology (Anima Anandkumar 研), Princeton University
- オリジナル LeanDojo 2023 の共著者所属: Caltech, NVIDIA, MIT, UC Santa Barbara, UT Austin
- v2 への継続開発が 2025-2026 に活発化しており eco-system としての持続性は高い

---

## Section 2: 傘下プロジェクト

### 2.1 ReProver (NeurIPS 2023)

Retrieval-Augmented Theorem Prover。LeanDojo 論文で同時発表された参照実装。

| 指標 | 値 |
|------|-----|
| 構成 | Retriever (ByT5 encoder) + Tactic Generator (ByT5 enc-dec) + Retrieval-Augmented Generator (ByT5 enc-dec) |
| 学習時間 | "only one GPU week" |
| データセット | LeanDojo Benchmark 4 (random / novel_premises splits) |
| star 数 | 322 |
| ライセンス | MIT |
| モデル配布 | Hugging Face Hub ユーザー `kaiyuy` |

評価指標は R@1 / R@10 / MRR (retrieval) + best-first 評価 (prover)。GPT-4 を上回る効果を報告 (pass@1 具体値は README には非公開、論文参照)。

### 2.2 Lean Copilot (G2 差分のみ)

G2 で精読済。LeanDojo eco-system における位置づけを差分として記載:

- LeanDojo は**外部から** Lean を叩く (Python から IPC)。Lean Copilot は **Lean 内部の tactic** として LLM 推論を呼ぶ (tactic inside Lean)。
- LeanProgress の `predict_steps_with_suggestion` が Lean Copilot 内に統合され、両者は**実行時に相互接続**する。
- 新基盤視点では Lean Copilot は「Lean セッション内側」のインテリジェンス、LeanDojo は「外側」のオーケストレーション層として役割分担。

### 2.3 LeanAgent (ICLR 2025)

- 論文: arXiv 2410.06209, "LeanAgent: Lifelong Learning for Formal Theorem Proving"
- GitHub: github.com/lean-dojo/LeanAgent (star 61)

| 機構 | 詳細 |
|------|------|
| Progressive Training | 新 repo ごとに 1 epoch 追加学習 |
| Curriculum Learning | 証明ステップ数の指数関数で難易度順序決定 |
| EWC (Elastic Weight Consolidation) | Fisher Information Matrix で過去知識保持 (ablation で使用) |
| Best-first Tree Search | sorry 定理の探索戦略 |
| Retriever | ByT5 ベース premise retriever |
| 分散学習 | Ray + PyTorch Lightning DDP |
| 既知 repo 数 | 約 250+ リポジトリを追跡、trace 問題や定理数不足で分類 |
| Lean Copilot との差 | Lean 内 tactic ではなく、**外部 agent** として複数 repo を横断し、累積知識を管理する agent loop |

新基盤視点: LeanAgent の「repo 単位でのデータベース管理 + 累積学習」は `/research` スキルの Gate-Driven Workflow にマップ可能 (Section 4 参照)。

### 2.4 LeanProgress (TMLR 2025)

- 論文: arXiv 2502.17925
- モデル: **DeepSeek Coder 1.3B** fine-tuned (MSE loss, AdamW, lr=1e-5, batch=4, weight decay=0.01)

| 指標 | 値 |
|------|-----|
| データセット | 約 80,000 proof trajectories (Lean Workbook Plus + Mathlib4) |
| 原データ偏り | 平均 2.47 ステップ (short proof 偏重) |
| バランス後平均 | 10.1 ステップ (stratified sampling 0.01-1.0) |
| 予測精度 | 75.8% |
| MAE | 3.15 |
| proof history あり vs なし | 75.8% vs 61.8% |
| Mathlib4 pass rate | 45.2% (vs ReProver baseline 41.4%, +3.8%) |
| Lean Copilot 統合 | `predict_steps_with_suggestion` tactic |
| 貢献者 | Robert Joseph George, Suozhi Huang, Peiyang Song, Anima Anandkumar (Caltech, Princeton) |

新基盤視点: LeanProgress の「残りステップ数予測」は Gate 判定における**漸近打ち切り判断**に直接転用可能 (Section 4)。

### 2.5 LeanIDE (開発中)

- 状態: 概念設計段階 (leandojo.org/leanide.html)
- 著者: Will Adkisson, Ryan Hsiang, Robert Joseph George, Anima Anandkumar
- 役割: LeanDojo/LeanAgent/LeanProgress の IDE 統合フロントエンド想定。コード未公開のため新基盤への即時影響はなし。

### 2.6 TorchLean (2026)

- 目的: PyTorch スタイルの verified NN API を Lean 4 で実装
- 検証対象: 普遍近似定理 (mechanized proof), 認証済ロバストネス, PINN 残差境界, Lyapunov 型 NN コントローラ
- 著者: Robert Joseph George, Jennifer Cruden, Xiangru Zhong, Huan Zhang, Anima Anandkumar
- リリース: PDF 公開済、コードは "coming soon"

新基盤視点: マニフェスト公理系は NN モデルを扱わないので直接の依存はないが、「実行セマンティクスと検証セマンティクスの一致」という設計思想は参考価値あり。

### 2.7 BRIDGE (2026)

- フルネーム: Building Representations In Domain Guided Program Synthesis
- 著者: Robert Joseph George, Carson Eisenach, Udaya Ghai, Dominique Perrault-Joncas, Anima Anandkumar, Dean Foster
- 情報量: arXiv 2026 preprint のみ確認、詳細は未精読 (本サーベイ範囲外)

### 2.8 LeanDojo-v2 (統合フレームワーク)

- GitHub: github.com/lean-dojo/LeanDojo-v2 (star 70, Apache-2.0, v1.0.8 2026-03-10)
- 機能: clone/trace 自動化、動的 DB、SFT + GRPO + retrieval 目的の policy 訓練、Pantograph 駆動、HuggingFace API 推論
- 依存: **Pantograph** (stanford-centaur/PyPantograph) - Lean 4 RPC server
- Multi-Modal Provers: HFProver / RetrievalProver / ExternalProver (tactic 生成 / 全証明生成 / 外部委譲)

---

## Section 3: eco-system 全体像の統合分析

### 3.1 依存グラフ (新基盤視点)

```
                    [Lean 4 本体]
                         |
              +----------+-----------+
              |                      |
      [LeanDojo v1]            [Pantograph]
       (Docker/IPC)         (Lean 内 RPC server)
              |                      |
              v                      v
   +----- mathlib trace -----+   +-----+
   |                          |  |
   v                          v  v
[LeanDojo Benchmark] <----- [LeanDojo-v2]
  (98k / 122k thms)         (統合フレームワーク)
   |                          |
   +----+--------+-----+------+
        |        |     |       |
        v        v     v       v
   [ReProver] [LeanAgent] [LeanProgress] [Lean Copilot]
   (NeurIPS23) (ICLR25)   (TMLR25)       (in-Lean tactic)
                                              |
                                              +-- 統合 --+
                                                         |
                                              [LeanIDE (計画中)]

  (別系統、同グループ) [TorchLean] [BRIDGE]
```

### 3.2 共通インフラ

- **共有データセット**: LeanDojo Benchmark / Benchmark 4 (mathlib trace) が全下流プロジェクトの訓練・評価基盤
- **モデル配布**: Hugging Face Hub (kaiyuy ユーザー / DeepSeek Coder fine-tunes)
- **IPC**: v1 系は Docker + subprocess、v2 系は Pantograph (Lean 4 内 RPC) に統一化の方向
- **認証**: GitHub personal access token 必須 (rate limit 対策のみ、独自認証レイヤはなし)
- **配布ライセンス**: MIT (core, ReProver) / Apache-2.0 (v2) が混在

### 3.3 レイヤ分担

| レイヤ | ツール | 役割 |
|--------|--------|------|
| Lean 実行 | Pantograph / Lean 本体 | kernel, tactic, elaborator |
| Lean 内 AI | Lean Copilot | in-Lean tactic (LLM 推論) |
| 外部 IPC | LeanDojo / PyPantograph | Python から Lean を叩く |
| データ抽出 | LeanDojo trace | mathlib → JSONL |
| データセット | LeanDojo Benchmark | 評価基盤 |
| 証明器 | ReProver | retrieval-augmented prover |
| Agent (累積学習) | LeanAgent | lifelong learning loop |
| 探索ガイド | LeanProgress | 残りステップ予測 |
| 統合 | LeanDojo-v2 | 全部まとめるフレームワーク |
| IDE | LeanIDE | フロントエンド (未完成) |
| 応用 | TorchLean, BRIDGE | NN / program synthesis 検証 |

### 3.4 G2 既調査ツールとの関係

G2 で精読した `Lean Copilot, APOLLO, Aristotle` は「プロバー / Lean 内 AI / 高次推論」という **個別機能** だが、LeanDojo はそれらを**駆動・評価する共通インフラ**。G2 精読内容を上位レイヤで統合する視点を本サーベイが追加する。

APOLLO / Aristotle は LeanDojo eco-system の**外部**プロジェクトだが、LeanDojo Benchmark を評価基盤として借用する点で間接依存がある (要追加調査)。

---

## Section 4: 新基盤への適用案

### 4.1 LeanDojo Python API の統合可能性

**方針 A (採用)**: LeanDojo / LeanDojo-v2 を新基盤 `research` pipeline の**観測レイヤ**として採用。

- 使用機能: `trace()` で agent-manifesto の `lean-formalization/Manifest/` を traced 済データセット化
- 55 axioms / 1670 theorems (2026-04-17 実測) を JSONL 化し、新基盤の公理系監査 (ground-axiom スキル) の入力とする
- Python 依存: 3.9 <= v < 3.13 の制約あり。現 agent-manifesto は Python を本質的に使っていないので導入コスト中程度
- Lean version 制約: v4.3.0-rc2 以降。現 manifesto は最新 Lean 4 なので問題なし

**方針 B (不採用)**: Pantograph を直接採用。理由: LeanDojo-v2 がラップしているので屋上屋。ただし長期的には Pantograph 直接の方が Docker-free で望ましい。

### 4.2 LeanAgent パターンの `/research` Worker への転用

LeanAgent の core idea は「repo 単位でのデータベース + 累積学習 + curriculum + EWC」。これは `/research` スキルの Gate-Driven Workflow と以下のように対応:

| LeanAgent 要素 | `/research` への転用 |
|----------------|----------------------|
| Progressive Training (1 epoch per repo) | Sub-issue ごとの incremental worktree 実験 |
| Curriculum Learning (ステップ数指数) | Gate の重み付け (複雑度順) |
| EWC (Fisher Information) | P3 退役ポリシーの形式化 - 古い MEMORY の重要度スコア |
| Repository database (250+ repos) | `.claude/handoffs/` + `.claude/metrics/` を統合した agent knowledge store |
| Best-first tree search | 複数 Gate の優先順位探索 |

実装提案: LeanAgent の `dynamic database` ソースコード構造を新基盤の `agent-memory/` モジュール設計の参考実装として読む。

### 4.3 LeanProgress の Gate 判定への応用

LeanProgress は「残りステップ数」を回帰モデルで予測する。これは新基盤の Gate 判定における重要な入力となる:

- **Gate 「実装すべきか？」**: 残りステップ予測値が閾値超過なら **defer** (別 issue に分割)
- **Gate 「検証完了か？」**: 予測残 0 ± MAE 3.15 の範囲なら **pass**
- **打ち切り判断**: 予測残 > 予算 × 安全係数なら **abort**
- 定量利得: Mathlib4 で +3.8% 改善 (41.4% → 45.2%) の実績あり。新基盤への transferability は要実験

実装: DeepSeek Coder 1.3B fine-tune を新基盤の検証 metrics (V1-V7) 予測に流用できる可能性。訓練データは `.claude/metrics/*.jsonl` 過去ログ。

### 4.4 agent-manifesto 公理系を LeanDojo Benchmark 形式で配布

**提案**: `lean-formalization/Manifest/` (55 axioms, 1670 theorems, 0 sorry — 2026-04-17 実測) を LeanDojo `trace()` にかけ、**Manifesto Benchmark** として公開。

- LeanDojo Benchmark 4 (122,517 定理) に対し、manifesto は 1670 定理で中規模だが「メタ公理系の benchmark」という独自ニッチ
- 配布形式: mathlib 互換 JSONL + LeanGitRepo pointer
- 効果: (1) 外部研究者が manifesto 上で新手法を評価可能 (2) ReProver / LeanAgent が manifesto 定理を自動で解く実験ができ、公理系の**機械可解性**が測定できる
- 互換性分類: **conservative extension** (既存 manifesto は変更せず、派生データを追加)

### 4.5 統合と差別化

| レイヤ | 新基盤の立場 |
|--------|------------|
| Lean 実行 | Lean 4 本体に依存 (差別化なし) |
| Lean 内 AI | Lean Copilot を採用候補 (G2 で精読済) |
| 外部 IPC | **LeanDojo Python API を採用** (方針 A) |
| データ抽出 | LeanDojo trace を採用 |
| データセット | manifesto を LeanDojo 形式で**逆提供** (4.4) |
| 証明器 | ReProver / LeanAgent を評価 baseline として使用 |
| Agent フレームワーク | **ここを差別化** - LeanAgent の lifelong learning + agent-manifesto の V1-V7 ガバナンス + P2/P3 の検証統治 |
| IDE | Claude Code を既存 IDE として活用 (LeanIDE は不要) |

新基盤の **差別化ポイント**: LeanDojo eco-system が「AI for Lean」(Lean を AI で解く) の方向に特化しているのに対し、新基盤は **「Lean for AI Agent」**(Lean で Agent の振る舞いを検証する) の方向。公理系 + formal derivation + gate-driven workflow という agent governance 層を提供する点が既存 eco-system にない。

---

## Section 5: 限界と未解決問題

1. **ReProver pass@1 の具体値未取得**: README / 公式サイトでは公開されず、元論文 arxiv 2306.15626 の本文にのみ記載 (WebFetch では abstract しか取得できなかった)。後続調査で PDF 直接取得が必要。
2. **LeanAgent のベンチマーク結果未確認**: 論文本体要精読 (arXiv 2410.06209)。
3. **LeanDojo-v2 ライセンスの曖昧性**: README は MIT、GitHub メタデータは Apache-2.0 と乖離。配布時にユーザー側で確認必須。
4. **Pantograph vs LeanDojo v1 の性能比較**: 速度改善は定性的報告のみ、定量値が未取得。
5. **BRIDGE の詳細未取得**: 2026 preprint は本サーベイ範囲外として保留。
6. **LeanIDE コード未公開**: 新基盤の IDE 統合検討では使えない。
7. **認証モデルの弱さ**: LeanDojo は GitHub PAT のみで rate limit 対策、独自認証はなし。プライベート manifesto を扱う場合は自前で保護が必要。
8. **APOLLO / Aristotle との interoperability**: G2 既調査プロジェクトと LeanDojo eco-system の実測定互換性は未確認、要追加実験。
9. **日本語コミュニティ**: 本 eco-system は英語圏 (Caltech, Princeton, NTU) 中心で、日本語での解説・再現実験情報が乏しい。
10. **Lean 4 version tracking**: LeanDojo は `v4.3.0-rc2 以降` と緩いが、mathlib 側の頻繁な version 変更で trace が壊れるリスクあり (LeanDojo v4.20.0 が 2025-06 なので比較的追従)。

---

## Section 6: 出典 URL リスト

### 一次情報 (WebFetch / WebSearch で取得確認済)

1. LeanDojo 公式サイト: https://leandojo.org/
2. LeanDojo 論文ページ: https://leandojo.org/leandojo.html
3. LeanDojo NeurIPS 2023 arXiv: https://arxiv.org/abs/2306.15626
4. LeanDojo GitHub: https://github.com/lean-dojo/LeanDojo
5. LeanDojo ドキュメント: https://leandojo.readthedocs.io/en/latest/ (403 エラー、部分取得)
6. ReProver GitHub: https://github.com/lean-dojo/ReProver
7. LeanAgent GitHub: https://github.com/lean-dojo/LeanAgent
8. LeanAgent 論文: https://arxiv.org/abs/2410.06209 (ICLR 2025)
9. LeanProgress 公式ページ: https://leandojo.org/leanprogress.html
10. LeanProgress 論文: https://arxiv.org/abs/2502.17925 (TMLR 2025)
11. LeanDojo-v2 GitHub: https://github.com/lean-dojo/LeanDojo-v2
12. LeanDojo-v2 PyPI: https://pypi.org/project/lean-dojo-v2/
13. TorchLean 公式ページ: https://leandojo.org/torchlean.html
14. LeanIDE 公式ページ: https://leandojo.org/leanide.html
15. Pantograph GitHub: https://github.com/leanprover/Pantograph
16. PyPantograph GitHub: https://github.com/stanford-centaur/PyPantograph
17. Pantograph 論文: https://arxiv.org/abs/2410.16429

### 間接参照 (本文内で引用のみ)

18. miniF2F benchmark (ReProver 評価対象)
19. ProofNet benchmark (ReProver 評価対象)
20. Hugging Face kaiyuy ユーザー (ReProver モデル配布)

### 関連 G シリーズ (本サーベイ内で参照)

- G2: AI × Lean 検証 (Lean Copilot, APOLLO, Aristotle 精読)
- G5-4 (本書): LeanDojo eco-system
- 今後調査推奨: G5-X として Pantograph 単独 + APOLLO/Aristotle vs LeanDojo interop

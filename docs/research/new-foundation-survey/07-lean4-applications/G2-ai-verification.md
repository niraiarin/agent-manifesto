# G2: AI による Lean 4 検証・証明生成 — 先行研究精読

作成日: 2026-04-17
対象: agent-manifesto 新基盤（Lean 言語による型安全な研究 tree 管理 + 自作 Pipeline）
担当グループ: G2（AI Verification）
姉妹サーベイ: `03-lean-metaprogramming.md`（Section 1.7 Duper / Lean-Auto）, `research/survey_type_driven_development_2025.md`（S2 Lean-Auto 統合詳細）

---

## 構成

- Section 1: 各対象の精読ノート（Mistral Leanstral / VentureBeat / Harmonic Aristotle / DeepMind AlphaProof / Lean Copilot / APOLLO / Goedel-Prover）
- Section 2: 横断的発見（LLM × Lean パターン分類）
- Section 3: 新基盤への適用案
- Section 4: 限界と未解決問題
- Section 5: 出典 URL リスト

---

## Section 1: 精読ノート

### 1.1 Mistral Leanstral (2026-03-16)

#### 概要

Mistral AI が 2026-03-16 に公開した、**Lean 4 形式検証専用のオープンソースコード生成エージェント**。コードと「その正しさの数学的証明」を同時生成し、Lean 4 でカーネル検証してから人間に提示する。

#### アーキテクチャ

- **モデル形式**: Mixture-of-Experts (MoE)、Mistral 自社の "highly sparse architecture"。Mixtral / Mistral Small 4 と同じパターン
- **総パラメータ数**: 120B
- **アクティブパラメータ数**: 6B（推論時）
- **エージェントワークフロー**（4 ステップ）:
  1. Specification Ingestion（仕様取り込み）
  2. Lean 4 Code Generation（コード生成）
  3. Automated Proof Checking（Lean カーネルで検証）
  4. Iterative Repair（コンパイラ出力で修復）
- **MCP 統合**: `lean-lsp-mcp` で LSP からの即時フィードバックを最大化するよう訓練

#### ベンチマーク（FLTEval）

FLTEval は Mistral 自身が公開した新ベンチマーク。**Fermat's Last Theorem 形式化プロジェクトの実 PR から派生**。imports / library deps / 多ファイル proof 構造を含む現実的環境を測定。「miniF2F のような競技数学から脱却」が明示目標。

| Model | Cost ($) | Score |
|-------|----------|-------|
| Haiku | 184 | 23.0 |
| Sonnet 4.6 | 549 | 23.7 |
| Opus 4.6 | 1,650 | 39.6 |
| **Leanstral pass@1** | **18** | **21.9** |
| **Leanstral pass@2** | **36** | **26.3** |
| **Leanstral pass@4** | **72** | **29.3** |
| **Leanstral pass@8** | **145** | **31.0** |
| **Leanstral pass@16** | **290** | **31.9** |

→ **コスト効率**: pass@2 で Sonnet を +2.6pt、コストは Sonnet の 1/15。Opus 単発との比較ではスコア劣後だがコスト 1/45。

#### 訓練データと手法

公式発表で**未公開**。技術レポートが後日公開予定とアナウンス済み（2026-04-17 時点では未公開）。

#### 失敗モード

公式発表で具体的記述なし。Opus 4.6 (39.6) が pass@16 (31.9) より高いことから、**多サンプリングよりも reasoning 強化が有効な領域がある**ことが示唆される。

#### オープン性

- ライセンス: **Apache 2.0**
- 重み: ダウンロード可能
- API: `labs-leanstral-2603`（限定期間 free / near-free）
- Mistral Vibe IDE に統合（`/leanstral` コマンド）
- ドキュメント: `docs.mistral.ai/models/leanstral-26-03`
- GitHub リポジトリ: 公式 URL は明示されず

#### Lean 4 への入力形式

**コード仕様 → Lean**。数学定理証明ではなくコード仕様検証（financial systems, authentication, cryptography 等）。

#### 検証の二値性活用

ワークフロー (4) Iterative Repair で Lean コンパイラの "通る/通らない" を直接 feedback ループに使用。pass@k のサンプリング戦略により「通った proof のみ採択」するシンプルな fail-stop パターン。

---

### 1.2 VentureBeat 記事: "Lean 4 — the new competitive edge in AI"

#### 概要

VentureBeat が 2025 年末〜2026 年初頭に公開した一般読者向け解説記事。AI ラボ間で Lean 4 採用が**戦略的差別化要因**になりつつある状況を整理。

#### 主要な主張（一次情報を引用）

- Lean 4 は「programming language and proof assistant」の二重性を持つ
- 「every theorem or program written in Lean4 must pass strict type-checking by Lean's trusted kernel, yielding a **binary verdict**」
- 「A Lean4 proof or program will behave **deterministically** – given the same input, it produces the same verified result every time」
- 「research groups and startups combining LLMs' natural language prowess with Lean4's formal checks to create AI systems that **reason correctly by construction**」

#### 言及されている AI ラボ

- **DeepMind**: AlphaProof（IMO silver medal、§1.4 で詳述）
- **Mistral**: Leanstral（§1.1 で詳述）

ByteDance Seed-Prover、Harmonic Aristotle、OpenAI（自然言語派）への言及は記事内で確認できず（ただし関連報道で並記される文脈は多数）。

#### 観点としての価値

- 「LLM と Lean は相補的」（natural language prowess + formal checks）という業界フレームを提供
- 「reason correctly by construction」という表現は agent-manifesto の D1（公理優先）/ D7（健全性優先）と整合
- ただし**技術的詳細は薄い**ため、本サーベイでは個別研究（§1.1, 1.3-1.7）を一次情報源とする

---

### 1.3 Harmonic Aristotle (2025-10, arxiv 2510.01346)

#### 概要

Harmonic AI 社の system。**IMO 2025 で 6 問中 5 問を Lean 4 で形式検証された証明として解いた（gold medal equivalent, 35/42）**。同時期の OpenAI/DeepMind の natural-language 解とは異なり、人間レビューを必要としない machine-checkable 出力を提供。

#### アーキテクチャ（3 コンポーネント）

1. **Lean Proof Search**: Monte Carlo Graph Search（**ツリーではなくハイパーグラフ**）。transformer-based policy + value function。PUCT 式変種で exploration bonus を prior policy で重み付け。AND/OR 構造（state は 1 child の action 成功で OK、action は全 child state 証明で OK）。bottleneck を minimax で優先。
2. **Lemma-based Informal Reasoning**: LLM が informal proof を生成 → 細かい lemma に分解 → lemma statement のみを Lean に formalize → コンパイラ feedback で iterative correction
3. **Geometry Solver (Yuclid engine)**: 数値ルールマッチを deduction の前段に。statement deduplication, echelon form storage, raw-pointer メモリ管理。**0.4 秒で 30 問中 17 問解く（AlphaGeometry-1 比 ~500× 高速）**

#### 訓練手法

- **Reinforcement Learning based on expert iteration**
- 発見した proof を nontriviality measures で filter
- generative policy + value function を proven states と nearby unproven states で学習
- **Test-time training**: 個別問題に対して search trace 上で iterative retrain（problem-specific specialization）

#### 訓練データ

contest mathematics fine-tuning + 広範な formal mathematics（Mathlib への novel 貢献を訓練中に生成: Niven's theorem, Gauss-Lucas theorem, eigenvalue-characteristic polynomial relations）。

#### IMO 2025 詳細結果

| 問題 | 解いたか | 特筆事項 |
|------|---------|---------|
| **P1 (Sunny Lines)** | YES | 通常の geometric approach ではなく **derangement ベースの algebraic proof** を発見。n≤5 で explicit counterexamples |
| P2 | NO | (combinatorics 系統で苦戦) |
| **P3 (Bonza Functions)** | YES | 問題文にない補助定義 `S(f) = {p | Prime(p) ∧ f(p)>1}` を novel に導入 |
| **P4 (Sums of 3 Divisors)** | YES | **formalization 中に informal 文の subtle error を訂正**。strictly / weakly / eventually decreasing を区別 |
| **P5 (Inekoalaty Game)** | YES | invariant `f(k) := k√2/(2k-1)` を合成、filter manipulation など高度技法を高校レベル問題に投入 |
| P6 | NO | |

#### 競技外能力

- Mathlib への定理貢献: Niven, Gauss-Lucas, eigenvalue-characteristic polynomial
- **Terence Tao "Analysis I" 教科書を validate**: 4 つの false exercises を発見、2 件で "stated hypotheses が unnecessary" と検出
- Homological algebra, Eisenstein series など advanced domain で proficiency

#### 失敗モード

- combinatorics 系統で弱い（P2, P6）
- Section 1.6 と同種の「正しい仕様の生成」問題は明示されないが、informal reasoning と formal lemma の橋渡しに iterative correction を必要とする＝1 発で正しい formalization は出ない

#### オープン性

- 論文: arxiv 2510.01346（公開）
- IMO 2025 解答: github.com/harmonic-ai/IMO2025（公開）
- モデル重みは**非公開**（Harmonic は 2025-11 に Series C で $120M 調達、商用化路線）

#### 比較対象

ByteDance **Seed-Prover** も IMO 2025 gold。差: Seed-Prover は完全 proof 生成 → iterative refinement、Aristotle は **tree search で step-by-step**。両者とも informal reasoning + formal feedback の hybrid を強調 → このパターンが「IMO レベル ATP の foundational approach」と論文が示唆。

---

### 1.4 AlphaProof (Google DeepMind, 2024 / Nature 2025)

#### 概要

DeepMind の system。**IMO 2024 で 28/42 点（silver medal threshold）**。AlphaProof が P1, P2, P6 を、AlphaGeometry 2 が P4 を解いた。P6 は 609 人中 5 人しか full points を取れなかった hardest 問題。

#### アーキテクチャ

- **Solver Network**: encoder-decoder transformer。code + math データで pretraining（一般 web text なし）。50 epochs、mixed task（next-token prediction + span reconstruction）。「12 trillion tokens seen by the encoder」
- **Formalizer Network**: Gemini を fine-tune。自然言語 theorem statement → Lean 形式言語に変換。**約 100 万の自然言語 statement を確率的に formalize して 80 million Lean theorem variants を生成**
- **AlphaZero loop**: tree search で proof 探索。**Product nodes (AND nodes) を導入**: 標準 OR ノードは「いずれかの子を証明」、product nodes は「全子を証明」が必要 → mathematical induction 等の独立 sub-goal に必須
- **Test-Time RL (TTRL)**: コンテスト中も学習ループ稼働。問題から自己生成した variation を proof し、その成功 proof で base model を強化

#### 訓練データ

- 自然言語 problem ~1M
- → Lean に auto-formalize して **80M variant**
- code + math だけで pretrain（汎用 LLM とは異なる）

#### 性能

- IMO 2024: 28/42（silver threshold）
- AlphaProof 単独: P1 (algebra), P2 (algebra), P6 (number theory)
- AlphaGeometry 2: P4 (geometry, **19 秒で**)
- 未解 (combinatorics): P3, P5
- 計算時間: 「up to three days」、最短「within minutes」

#### Nature 論文 (2025-11)

`s41586-025-09833-y` として正式出版。test-time compute scaling が「improved results over many orders of magnitude」と報告 → 計算資源で scaling 可能、algorithmic constraint ではない。

#### 失敗モード

- combinatorics で弱い（Aristotle と同傾向）
- 訓練 + コンテスト中の TTRL に「weeks」「up to 3 days」を要する → real-time use 不可

#### オープン性

- モデル重み: **非公開**
- formalizer / solver network 詳細: Nature 論文と blog post で部分開示
- 80M auto-formalized dataset: 非公開
- DeepMind blog: deepmind.google/blog/ai-solves-imo-problems-at-silver-medal-level/

#### Lean 4 への入力形式

**自然言語 → Lean**。formalizer network が auto-formalization 担当。stochastic formalization で 1 problem から複数 Lean variant を生成（proof 成功率を上げる）。

#### 検証の二値性活用

AlphaZero 報酬として Lean カーネルの「証明完了 / 未完」を直接使用。**1bit 報酬で expert iteration**。これが「通る/通らない」フィードバックの最も純粋な活用例。

---

### 1.5 Lean Copilot (arxiv 2404.12534, Song-Yang-Anandkumar)

#### 概要

LLM をネイティブ Lean tactic として統合する OSS フレームワーク。**Mathematics in Lean テキストブックで proof step の 74.2% を自動化（aesop の 40.1% に対し 85% 改善）**。人間補助時の手入力ステップは平均 2.08（aesop は 3.86）。

#### アーキテクチャ

- **3 つの tactic を露出**:
  - `suggest_tactics`: tactic 推薦
  - `search_proof`: LLM 生成 tactic + aesop で multi-step proof 探索
  - `select_premises`: Lean / mathlib4 から有用 premise を retrieve
- **Bundled models**（LeanDojo project から）:
  - tactic 生成: `ct2-leandojo-lean4-tacgen-byt5-small`
  - premise retrieval: `ct2-leandojo-lean4-retriever-byt5-small`
  - encoder: `ct2-byt5-small`
- **Runtime**: **CTranslate2** (C++ inference) を FFI で Lean から呼ぶ。CPU/GPU 両対応
- ローカル実行 or クラウド API

#### モデル規模

byt5-small ベース → ~300M parameters と推定（公式数値開示なし）。**§1.4 AlphaProof（数十 B）や §1.7 Goedel-Prover (8B-32B) と比較して桁違いに小さい**。

#### 訓練手法

LeanDojo プロジェクトの ReProver 系列を継承。supervised fine-tuning が中心。RL は使用せず。

#### 失敗モード

- byt5-small サイズの限界: 複雑な theorem では proof step suggestion 品質低下
- premise retrieval は埋め込みベース → semantic mismatch で関係ない premise を返す
- **CTranslate2 依存**: Lean 4 バージョン更新で互換性問題が発生し得る

#### オープン性

- ライセンス: **MIT**
- GitHub: github.com/lean-dojo/LeanCopilot
- 必要 Lean version: `lean4:v4.3.0-rc2` 以上
- インストール: `lake exe LeanCopilot/download` でモデルを `~/.cache/lean_copilot/` へ

#### 検証の二値性活用

`search_proof` が aesop と組合せて**多 step 探索を BFS/DFS で展開**、各 candidate を Lean kernel で検証。失敗 path は早期 prune。

#### Lean 4 への入力形式

**Lean proof state → Lean tactic**（Lean 内部で完結）。自然言語入力なし。

---

### 1.6 APOLLO (NeurIPS 2025, Ospanov-Farnia-Mohit)

#### 概要

「**LLM と Lean compiler の協調による自動 formal reasoning**」。LLM が初期 proof を生成 → 複数 agent が Lean compiler feedback を分析・修復 → 失敗 sub-lemma を isolate → automated solver を呼び出し。**miniF2F で sub-8B モデル SOTA 84.9%**。

#### アーキテクチャ（modular, model-agnostic）

- LLM が initial proof 生成
- Agent 群が:
  - syntax error 修復
  - Lean を使って proof 内のミスを特定
  - 失敗 sub-lemma を分離
  - automated solver 呼び出し
- **Recursive repair loop**: REPL で Lean と通信、proof state / errors / verification result を抽出
- 使用例:
  ```python
  manager = ApolloRepair(code=code, lemma_name='test',
      config=config, rec_depth=max_attempts, log_dir=problem_dir)
  final_proof_path = manager.run()
  ```

#### 評価モデル

| Model | Baseline | + APOLLO | Note |
|-------|---------|---------|------|
| Goedel-V2-8B | (32 samples) | **84.9%** | 63 samples で達成（**baseline は 32 だが APOLLO 込みで sub-8B SOTA**） |
| Goedel-Prover-SFT | - | 65.6% | sample 数を 25,600 → "few hundred" に削減 |
| o3-mini | 24.6% (8 samples) | 40.2% | +36.9% relative |
| o4-mini | 3-7% | >40% | 汎用 LLM でも大幅向上 |
| Kimina-Prover-Preview-Distill-7B | (評価あり) | (詳細不明) | |

#### 訓練データと手法

APOLLO 自体は訓練不要のフレームワーク（model-agnostic）。**プロンプトエンジニアリング + repair loop の orchestration が新規性**。

#### 失敗モード

- recursive depth で resource consumption が爆発し得る（`rec_depth` パラメータで制御）
- automated solver 部分の選択が固定的（aesop / decide / etc.）
- 「正しい sub-lemma 分割」が LLM 任せで、誤った分割で stuck する可能性

#### オープン性

- ライセンス: **MIT**
- GitHub: github.com/aziksh-ospanov/APOLLO
- OpenReview: openreview.net/forum?id=fxDCgOruk0
- NeurIPS 2025 poster: neurips.cc/virtual/2025/loc/san-diego/poster/116789

#### Lean 4 への入力形式

LLM の出力する Lean code → APOLLO が修復。**proof level での協調**（tactic 単位ではなく proof 全体）。

#### 検証の二値性活用

Lean compiler の error message を**構造化 feedback**として agent に流し、修復ターゲットを駆動。単純な「pass/fail」を超えて、**error の形（syntax / type / 未閉じ goal / etc.）で分岐**するパターン。

---

### 1.7 Goedel-Prover (V1 / V2, 2025-08)

#### 概要

Princeton / Goedel-LM チームによるオープンソース Lean 4 自動定理証明 LLM シリーズ。**Goedel-Prover-V2-32B が miniF2F で 88.0% pass@32（self-correction 付きで 90.4%）**。DeepSeek-Prover-V2-671B（<84%）を 1/20 のパラメータで上回る sample efficiency。

#### モデル系列とサイズ

- Goedel-Prover-SFT (V1): ~7B（推定 13B との表記もあり）
- **Goedel-Prover-V2-8B**: 8B
- **Goedel-Prover-V2-32B**: 32B
- 派生: **Leanabell-Prover** (CoT 拡張)

#### アーキテクチャと訓練 3 本柱

1. **Scaffolded Data Synthesis**: 難易度を漸増させた synthetic proof tasks で curriculum learning
2. **Verifier-Guided Self-Correction**: Lean コンパイラ feedback で proof 自己修正、**2 round の self-correction**
3. **Model Averaging**: 複数 checkpoint を combine して robustness 向上

ベース training pipeline は「standard expert iteration and reinforcement learning」。

#### データ生成

- ~1.64M formalized statements (`Goedel-Pset-v1`)
- ~800K verified proofs (`Goedel-Pset-v1-solved`)
- **Dual formalizers** + Lean compiler verification（双子の formalizer で diversity を確保し、verifier で gating）
- difficulty-ranked curriculum

#### ベンチマーク

| Benchmark | V2-8B | V2-32B | V2-32B (self-correct) |
|-----------|-------|--------|----------------------|
| **miniF2F (pass@32)** | 84.6% | 88.0% | **90.4%** |
| **PutnamBench** | - | 57 problems (pass@32) | 86 problems (pass@192) |
| **MathOlympiadBench** | - | (新規 360 IMO-level 公開) | - |

#### 失敗モード

- 詳細失敗分析は README に薄い
- pass@k 依存（pass@1 性能は大幅に低い） → **agentic 用途では sample budget が課題**
- combinatorics / olympiad 一部で stuck pattern

#### オープン性

- ライセンス: **Apache 2.0**
- GitHub: github.com/Goedel-LM/Goedel-Prover-V2
- 重み: HuggingFace `Goedel-LM/Goedel-Prover-V2-32B`, `-8B`
- データセット: HuggingFace に公開（formalized statements, proofs, MathOlympiadBench）
- 訓練 pipeline: 公開

#### Lean 4 への入力形式

**theorem statement (Lean) → proof (Lean tactics)**。informal natural language は formalizer 段階のみ。

#### 検証の二値性活用

- Expert iteration: pass した proof のみ次 iteration の SFT データとして採用
- Self-correction: compiler error → LLM に再投入して fix

#### 新基盤との関連

§1.6 APOLLO の **base model として最有力**（実際 APOLLO 評価で SOTA を達成）。OSS で改造可能 → agent-manifesto の自前 pipeline に組み込める唯一の選択肢。

---

## Section 2: 横断的発見 — LLM × Lean パターン分類

7 つの精読を通じて、**「LLM と Lean の interaction pattern」は粒度（granularity）と協調モード（collaboration mode）の 2 軸で分類できる**。

### 2.1 粒度軸（Tactic-level / Theorem-level / Proof-search-level）

| 粒度 | 説明 | 代表例 | 特徴 |
|------|------|--------|------|
| **Tactic-level** | LLM は次の 1 tactic を提案、Lean が即時検証 | Lean Copilot (§1.5), 既往の Duper (`03-` Section 1.7) | 軽量、IDE 統合容易、small model で十分 |
| **Theorem-level** | LLM が完全な proof を生成、Lean が pass/fail を返す | Goedel-Prover (§1.7), Mistral Leanstral (§1.1) | pass@k 依存、sample budget が大、MoE スケーリング |
| **Proof-search-level** | LLM がツリー/グラフ探索の policy/value を担当 | AlphaProof (§1.4), Aristotle (§1.3) | 最も sophisticated、TTRL/expert iteration、計算重い |
| **Repair-level**（新カテゴリ） | LLM 出力に対し agent 群が compiler feedback で修復 | APOLLO (§1.6) | model-agnostic、既存 LLM の sample efficiency を桁違い改善 |

### 2.2 協調モード軸

| モード | 説明 | 代表例 |
|--------|------|--------|
| **Hammer pattern** | LLM 生成 → Lean 検証 → 失敗なら破棄 | Mistral Leanstral pass@k |
| **RL feedback loop** | Lean の pass/fail を 1bit 報酬として LLM 訓練 | AlphaProof (TTRL), Aristotle (expert iteration), Goedel-Prover |
| **Tactic suggestion** | proof state → tactic候補、人間/aesop が採択 | Lean Copilot |
| **Iterative repair** | Lean error → LLM に feed して fix | APOLLO, Mistral Leanstral step (4) |
| **Lemma decomposition** | LLM が informal proof → Lean lemma に分解 → 個別証明 | Aristotle |
| **Auto-formalization** | 自然言語 statement → Lean statement | AlphaProof (formalizer network), Aristotle |

### 2.3 「informal + formal hybrid」が IMO レベルの foundational pattern

§1.3 Aristotle 論文と §1.4 AlphaProof Nature 論文の双方が、**informal reasoning と formal verification の hybrid アーキテクチャを「IMO レベル ATP の必須要素」**と位置付ける（ByteDance Seed-Prover も同様）。

- **informal LLM**: 創造性、direction、lemma 候補、informal proof sketch
- **formal Lean**: 健全性、deduplication、bottleneck minimax、最終 1bit 検証

### 2.4 既往サーベイとの相補性

`03-lean-metaprogramming.md` Section 1.7 と `survey_type_driven_development_2025.md` S2 は **Duper / Lean-Auto** という **symbolic ATP（SMT/superposition）バックエンド**を扱う。本サーベイ（G2）は **LLM ベース backend** を扱い、補完関係:

| 軸 | Duper / Lean-Auto (既往) | LLM ベース (本サーベイ) |
|---|---|---|
| 推論方式 | symbolic（first-order, monomorphization） | neural（transformer policy/value） |
| 検証形式 | Duper のみ proof reconstruction、SMT は smart sorry | 全 system が Lean kernel 検証必須 |
| ベンチマーク | miniF2F 36.6% (Lean-auto + Duper) | miniF2F 90.4% (Goedel-V2-32B + self-correct) |
| 用途 | 決定可能 fragment（first-order, EUF） | 帰納法・higher-order・creativity 必要な領域 |
| 計算コスト | 秒〜分 | 分〜日（特に AlphaProof 系） |

→ **将来的にはハイブリッド**: LLM が proof 全体構成、Duper/Lean-Auto が個別 sub-goal を closing するアーキテクチャが理論的最適（実装例: Aristotle の Geometry Solver は Yuclid という symbolic engine、Lean proof search 部分は neural）。

---

## Section 3: 新基盤への適用案

agent-manifesto 新基盤は「**Lean 言語による型安全な研究 tree 管理 + 自作 Pipeline**」。研究 node の生成・検証に LLM × Lean を組み込む 5 つの提案。

### 3.1 提案 A: Research Node の auto-formalization（AlphaProof パターン）

- 自然言語の研究 node 記述 → Lean による formal spec への変換に **formalizer network パターン**（§1.4）を採用
- ただし AlphaProof のような 80M variant は不要。研究 tree DSL は閉じた範囲なので **template-based formalization + LLM completion** で十分
- ハードルは「stochastic formalization」: 1 つの informal node から複数 formal candidate を生成し、Lean compiler で gating

### 3.2 提案 B: Pipeline 検証の hammer pattern（Mistral Leanstral パターン）

- `Spec = (T, F, ≤, Φ, I)` の `Φ` を Lean で検証する pipeline で、**Leanstral 型のコード+証明 同時生成**を活用
- pass@2 で Sonnet 超えのコスト効率は agent-manifesto の V5 (cost) / V7 (autonomy) を直接改善
- Leanstral 重みは Apache 2.0、ローカル MoE 推論は実用的（Active 6B）

### 3.3 提案 C: Tactic-level の小さな LLM 補助（Lean Copilot パターン）

- 研究 node の Lean 化を人間が書く際、Lean Copilot を IDE 統合
- byt5-small サイズ → **既存 PoC への組み込み障壁が低い**
- `select_premises` で Mathlib + 自前公理系から関連命題を retrieve

### 3.4 提案 D: APOLLO 型 repair loop で base LLM の sample efficiency 改善

- 自前 LLM や既存 OSS LLM (Goedel-Prover-V2 等) の出力に対し、APOLLO 型 repair loop を kernel に：
  - `lake build` の error stream → 構造化 feedback → LLM に再投入
- 既存 V4 (verification 効率) を桁違い改善できる可能性。具体的には APOLLO は Goedel-V2-8B の sample 数を 25,600 → "few hundred" に削減

### 3.5 提案 E: Aristotle 型 lemma decomposition for 大型研究目標

- 研究 tree の root node が「証明困難な命題」のとき、**Aristotle の lemma decomposition pipeline**を流用:
  1. 自然言語で informal proof sketch
  2. lemma に分解
  3. lemma statement のみを Lean に formalize
  4. 各 lemma を独立に証明（または sub-tree を生成）
- これは agent-manifesto の **D13（影響波及）+ D14（仮説駆動）の自然な拡張**
- 既存 `/research` skill の Gap Analysis → Sub-Issues フローと**構造的に同型**

### 3.6 統合視点: 4-layer architecture

新基盤の研究 tree pipeline で 4 layer に重ねる構成案:

```
[Layer 1: Auto-formalization]   informal node → Lean spec
   提案 A (AlphaProof formalizer pattern)

[Layer 2: Lemma decomposition]  spec → sub-lemmas (research tree)
   提案 E (Aristotle pattern)

[Layer 3: Proof generation]     sub-lemma → Lean proof
   提案 B (Leanstral hammer) or proposed C (Copilot tactic)

[Layer 4: Repair / orchestration]  failed proof → repaired
   提案 D (APOLLO pattern)
```

各 layer は独立 swap 可能（modular agent-manifesto と整合）。

---

## Section 4: 限界と未解決問題

### 4.1 「正しい仕様の生成」の困難性（最重要 unresolved）

**全 system が共通して苦手**: spec 自体が誤っていれば、Lean の検証は無意味（vacuous）。

- §1.3 Aristotle が IMO P4 で「informal 文の subtle error を formalization 中に訂正」できたのは**例外的成功**
- 逆に言えば、これが**数少ない確認可能な spec correction の事例**
- §1.1 Mistral Leanstral の "Specification Ingestion" がブラックボックス

→ agent-manifesto では **公理系 (T1-T8, E1-E2 等) が spec の anchor**、新基盤でもこの原則を継承する必要がある。LLM 単体に spec 生成を任せない。

### 4.2 計算コストの非線形性

- AlphaProof: 「up to 3 days」/ 問題、weeks の training
- Aristotle: test-time training で specialization、コスト未公開だが大きい
- Goedel-Prover-V2: pass@32 で 88% だが pass@1 性能は大幅低下
- Leanstral: pass@16 で +290 ドル/run

→ **agent-manifesto V5 (cost) で実用化に難**。APOLLO 型 sample efficiency 改善が必須。

### 4.3 Combinatorics 領域での共通の弱さ

- Aristotle: P2, P6 失敗
- AlphaProof: P3, P5 失敗
- 両者とも IMO の **combinatorics 問題で stuck pattern**

→ neural policy が「離散構造の case 分析を幅広く展開する」のが苦手。新基盤の研究 tree でも combinatorial sub-tree は人間 or symbolic ATP に escape する設計が必要。

### 4.4 オープンモデルの限界

- 完全 OSS で重み公開: Goedel-Prover-V2 (32B, Apache 2.0), Leanstral (120B/A6B, Apache 2.0), Lean Copilot (~300M, MIT)
- 重み非公開: AlphaProof, Aristotle（商用化）
- → **新基盤は OSS のみで構成可能だが、IMO レベル性能は出せない**。Goedel-V2 + APOLLO orchestration が現実的最大値

### 4.5 「形式化したものしか検証できない」根本制約

- Lean の型システムが trust base、kernel 検証は強力
- だが、**Lean に書けないもの（例: 物理的世界、人間の意図、設計 intent の倫理性）は検証外**
- agent-manifesto の L1 (安全境界) や T6 (人間の最終決定権) は **Lean では捕捉できない領域**

→ 新基盤でも「Lean 検証の外側に必ず人間判断 layer を残す」設計（D4 フェーズ順序の最外殻）が必要。

### 4.6 ベンチマーク自体の歪み（FLTEval が指摘）

- miniF2F は競技数学に偏り、**現実的 proof engineering（imports, library deps, multi-file）を測れない**
- Mistral が FLTEval を新規公開した動機もここ
- 新基盤の研究 tree は multi-file / cross-module proof を扱うので、**FLTEval 的評価が直接適用可能**

### 4.7 LLM の「仕様の意味理解」の限界

- §1.6 APOLLO の repair loop は syntactically correct fix を生成するが、**意味的に正しい lemma decomposition が常にできるとは限らない**
- §1.3 Aristotle の lemma generation も「nontriviality measure で filter」する後処理が必要 → **生成段階で全部正しくできない**

→ 新基盤では「LLM 生成 lemma を独立 verifier (P2) で再評価する loop」が必要。これは agent-manifesto の P2 (Cognitive Separation of Concerns) と同じ哲学。

---

## Section 5: 出典 URL リスト

### 一次情報源（公式 blog, 論文, GitHub）

#### Mistral Leanstral
- 公式発表: https://mistral.ai/news/leanstral
- ドキュメント: https://docs.mistral.ai/models/leanstral-26-03
- 解説記事 (二次): https://aiautomationglobal.com/blog/mistral-leanstral-formal-code-verification-2026
- 報道: https://www.theregister.com/2026/03/17/mistral_leanstral_ai_code_verification_tool/

#### Harmonic Aristotle
- 論文 (arxiv): https://arxiv.org/abs/2510.01346
- 論文 PDF: https://harmonic.fun/pdf/Aristotle_IMO_Level_Automated_Theorem_Proving.pdf
- 論文 HTML: https://arxiv.org/html/2510.01346v1
- IMO 2025 解答: https://github.com/harmonic-ai/IMO2025
- DeepWiki: https://deepwiki.com/harmonic-ai/IMO2025
- Series C 報道: https://www.businesswire.com/news/home/20251125727962/

#### AlphaProof
- DeepMind 公式 blog: https://deepmind.google/blog/ai-solves-imo-problems-at-silver-medal-level/
- Nature 論文: https://www.nature.com/articles/s41586-025-09833-y
- Julian.ac 解説 (Nature 論文): https://www.julian.ac/blog/2025/11/13/alphaproof-paper/
- PubMed: https://pubmed.ncbi.nlm.nih.gov/41225005/

#### Lean Copilot
- arxiv: https://arxiv.org/abs/2404.12534
- GitHub: https://github.com/lean-dojo/LeanCopilot
- LeanDojo 親プロジェクト: https://github.com/lean-dojo/LeanDojo

#### APOLLO
- NeurIPS 2025 poster: https://neurips.cc/virtual/2025/loc/san-diego/poster/116789
- OpenReview: https://openreview.net/forum?id=fxDCgOruk0
- GitHub: https://github.com/aziksh-ospanov/APOLLO

#### Goedel-Prover
- GitHub V2: https://github.com/Goedel-LM/Goedel-Prover-V2
- HuggingFace モデル (32B): https://huggingface.co/Goedel-LM/Goedel-Prover-V2-32B
- HuggingFace モデル (8B): https://huggingface.co/Goedel-LM/Goedel-Prover-V2-8B
- 解説: https://www.emergentmind.com/topics/goedel-prover

### 二次情報源（解説記事、比較記事）

- VentureBeat (Lean 4 competitive edge): https://venturebeat.com/ai/lean4-how-the-theorem-prover-works-and-why-its-the-new-competitive-edge-in
- Sequoia Inference (IMO 2025 三者比較): https://inferencebysequoia.substack.com/p/the-2025-imo-winners-circle-how-three
- The Decoder (verification bottleneck): https://the-decoder.com/ai-startup-tackles-bottleneck-where-people-spend-more-time-checking-ai-content-than-creating-it/
- Scientific American (AlphaProof): https://www.scientificamerican.com/article/ai-reaches-silver-medal-level-at-this-years-math-olympiad/

### 既往サーベイ（重複回避の対象、本サーベイは相補）

- `docs/research/new-foundation-survey/03-lean-metaprogramming.md` Section 1.7 (Duper / Lean-Auto)
- `research/survey_type_driven_development_2025.md` S2 (Lean-Auto integration patterns)
- `research/lean4-handoff.md` Section 2 (general Lean 4 tooling landscape)

---

## メタデータ

- 調査範囲: 7 系統（Mistral Leanstral / VentureBeat / Aristotle / AlphaProof / Lean Copilot / APOLLO / Goedel-Prover）
- WebFetch 一次情報取得回数: 14（うち成功 11, 429/403/404 で 3 回 retry）
- WebSearch 補完: 4
- 既往サーベイとの重複チェック: 完了（Duper / Lean-Auto は本サーベイ範囲外、§2.4 で相補性を整理）
- 互換性分類: **conservative extension** （既存サーベイに新ファイル追加のみ）

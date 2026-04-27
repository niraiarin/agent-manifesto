# G3: 仕様生成研究サーベイ — Vericoding と CLEVER の含意

調査担当: T1（一時的なエージェント）
調査日: 2026-04-17
対象グループ: 07 Lean 4 Applications / Group G3 (Spec Generation)

---

## Executive Summary（200 字）

最先端 LLM は自然言語から end-to-end の検証付きコードを生成する能力で 1% 未満（CLEVER 161 問中 1 問）〜 26.8%（Vericoding Lean 部）に留まる。最大のボトルネックは「仕様」自体の機械検証可能な生成—実装は書けるが、仕様の意味的等価性証明（spec certification）が壊滅的に難しい。新基盤の研究 tree 仕様化は完全自動化を諦め、speclib 構築と人間-LLM 共同編集 IDE を前提に設計すべき。

---

## Section 1: 各対象の精読ノート

### 1.1 VERIFYAI Project — Beg, O'Donoghue, Monahan (Maynooth University, OVERLAY 2025)

**書誌情報**
- 完全タイトル: "Leveraging LLMs for Formal Software Requirements: Challenges and Prospects"
- 著者: Arshad Beg (corresponding), Diarmuid O'Donoghue, Rosemary Monahan（全員 Maynooth University, Ireland）
- 会議: 7th International Workshop on Artificial Intelligence and Formal Verification, Logic, Automata, and Synthesis (OVERLAY 2025), Bologna, Italy, 2025-10-26
- 出版: CEUR Workshop Proceedings Vol. 4142, paper 11
- URL: https://ceur-ws.org/Vol-4142/paper11.pdf
- 性質: ポジションペーパー（実装はまだ early prototype）

**問題設定**

VERIFYAI は「自然言語要件 → 形式的・検証可能な仕様」の変換を目指す研究プロジェクト。「仕様」は Frama-C の ACSL（Pre/Postcondition + assertions）, JML（Java Modeling Language）, LTL（temporal logic）など、ターゲット検証ツールに依存して定義される。本ペーパー自体は文献サーベイ + PathCrawler/Frama-C による予備実験。

**入出力**
- 入力: 自然言語要件（産業要件文書）+ ドメインオントロジー（OWL 等）
- 中間表現: tool-neutral JSON-LD schema（複数の形式仕様言語にエクスポート可能）
- 出力: ACSL / JML / LTL / Dafny 仕様

**State-of-the-Art 性能（文献から引用）**
- nl2spec（temporal logic）: NL→LTL 翻訳 94.4% accuracy
- Req2Spec: BOSCH 自動車要件の 71% を形式仕様に変換
- SpecGen: 384 ベンチマーク中 279 問（72.7%）成功
- AssertLLM: ハードウェアアサーション 89% correctness
- Laurel（Dafny アサーション）: 50% 超
- スマートグリッド要件（GPT-4o + Claude 3.5）: F1 79–94%

**重要観察（VERIFYAI が文献から抽出）**
- アサーション生成（局所的・短い）と完全契約合成（function 全体）では成功率が大きく異なる。前者は信頼性高いが後者は破綻しやすい
- "different versions of language models can vary greatly in their responses to the same queries"—プロンプト感度が極めて高い
- LLM 単独では full contract synthesis は信頼できない—post-processing（mutation）または human-in-the-loop が必須

**5 つの根本課題（VERIFYAI 宣言）**
1. C1: Semantic Ambiguity（自然言語の文脈依存性）
2. C2: Lack of Ground Truth Datasets
3. C3: Tool Interoperability（ACSL/JML/Dafny... 相互運用なし）
4. C4: Traceability Across Artefacts（要件→仕様→コード→証明のトレース）
5. C5: Explainability and User Trust

**新基盤への含意**: VERIFYAI の "tool-neutral intermediate format (JSON-LD)" 構想は、agent-manifesto の研究 tree が複数のターゲット表現（Lean 4 / Markdown / GitHub Issue / Notion）を持つ設計と整合的。"Human-in-the-loop refinement" を first-class に置くアプローチは、agent-manifesto の T6（人間の最終決定権尊重）と一致する。

---

### 1.2 CLEVER Benchmark — Thakur et al. (NeurIPS 2025 Datasets & Benchmarks Track)

**書誌情報**
- 完全タイトル: "CLEVER: A Curated Benchmark for Formally Verified Code Generation"
- 著者: Amitayush Thakur, Jasper Lee, George Tsoukalas, Meghana Sistla, Matthew Zhao, Stefan Zetzsche, Greg Durrett, Yisong Yue, Swarat Chaudhuri
- 所属: UT Austin (主), Amazon, Caltech
- 会議: NeurIPS 2025 Datasets & Benchmarks Track
- arXiv: 2505.13938 (v4, 2025-10-23)
- 助成: NSF CCF-2212559, CCF-2403211, 2025 Renaissance Philanthropy AI for Math award

**問題設定 — 「仕様」の厳密な定義**

CLEVER は HumanEval の 164 問中 161 問を Lean 4 に手動形式化。各問題は:
- ν: 自然言語記述
- ψ*: 人手で書かれた ground truth Lean 仕様（**non-computable** な Prop 述語として定義）
- π_sig: 関数シグネチャ
- 仕様等価性定理 + 実装正当性定理

**重要設計**: 仕様は **non-computable**（`Prop` を返す述語、量化子と論理結合子を含む）として定義される。`computable` な仕様（Boolean 関数）にすると、LLM は仕様をそのまま実装にコピーして自明な証明を出せる（"specification leakage"）。Figure 3 で `computable spec` vs `non-computable spec` の差を実例で示す。

**ベンチマーク詳細**
- 161 問（HumanEval から手動抽出）
- 仕様作成に average 25 分/問、レビューに 15 分/問。複雑な non-computable 仕様は 1 時間超
- 手動正当性証明: 10 行（problem_17）〜 225 行（problem_0）
- 補助 5 問の few-shot dataset（HumanEval 外）: 等価性証明 29–82 行、正当性証明 309 行

**評価パイプライン（2 タスク × 4 段階）**
- Task 1 - Spec Certification: (1) 仕様生成 ψ, (2) ψ ≡ ψ* の等価性証明
- Task 2 - Implementation Certification: (3) 実装 π 生成, (4) π が ψ* を満たす正当性証明
- End-to-End: 4 段階全てが Lean kernel に通る必要がある

**評価指標**: pass@k-seconds（k = 600 秒予算）

**最先端 LLM の性能（Table 1, Figure 6 より引用）**

End-to-End 成功率（161 問中）:
| モデル | 構成 | E2E 成功 |
|--------|------|----------|
| GPT-4o | Few-Shot | 0/161 (0%) |
| o4-mini | Few-Shot | 1/161 (0.621%) |
| Claude-3.7 | Few-Shot | 1/161 (0.621%) |
| DeepSeek-R1 | Few-Shot | 1/161 (0.621%) |
| GPT-4o + COPRA | エージェント | 1/161 (0.621%) |
| Claude-3.7 + COPRA | エージェント | 1/161 (0.621%) |
| GPT-5-mini + KiminaProver-7b | ハイブリッド | 0/161 (0%) |

**段階別スコア**:
- Spec Compilation（型チェック通過）: Claude-3.7 と o4-mini で 80% 超
- Spec Certification（ψ ≡ ψ* 証明）: 全モデル 0.621%（GPT-4o + COPRA のみ 1.863%）
- Implementation Compilation: o4-mini で 80% 超、他は 60–70%
- Implementation Certification: Claude-3.7 + COPRA が 8.7%（best）、Few-shot は 5.6%

**唯一の成功例**: Problem 53（"Add Two Numbers"）。ground truth は `res - x - y = 0`、生成された実装は `x + y`、等価性証明には `linarith` と `ring` が必要。Brazilian factorial task でも Claude-3.7 + COPRA が成功（35 行の証明、対称的構造の symbolic reasoning が必要）

**失敗モードの根本原因（CLEVER 論文 Section 3 より）**

(1) **Spec Certification がボトルネック**: ψ ≡ ψ* の証明は「intent を抽象的に推論する」必要があり、実装レベルの手がかりがない。CoPRA エージェントを入れても 1.863% が天井。

(2) **Mismatch problem**: 仕様等価性が解ける問題と実装正当性が解ける問題が一致しない。両方が解ける必要があるため joint success が稀。

(3) **構造的に複雑**: miniF2F のような数学では `linarith`, `ring`, `simp` で証明が短い。CLEVER は実プログラムの control flow / branching / recursion を扱うため、tactic chaining では届かない。COPRA のような guided proof search が必要。

(4) **Termination Proofs の困難**: Polynomial root-finding（problem 32）は Newton 法の bounded recursion で停止性証明が non-trivial。LLM は termination obligation を扱えない。

(5) **形式化不能問題の存在**: 161/164 のみ形式化—Python の `Any`, polymorphic return, dynamic typing の 3 問は Lean に翻訳不可能。MD5 checksum (problem 162) は仕様自体が実装になってしまう。

**新基盤への含意（直接的）**: agent-manifesto の研究 tree を「自然言語の研究目標 → Lean 仕様 → 実装エージェント」と完全自動化する戦略は、CLEVER の結果を見る限り 0.6% 程度しか期待できない。**仕様生成段階で人間（or 専門家）が必須**。COPRA のような symbolic agent を組み込んでも 1–9% 程度の改善に留まる。

---

### 1.3 VerifyThisBench — Deng, Zhong, Bayazıt, Veneris, Long, Si (2025)

**書誌情報**
- 完全タイトル: "VerifyThisBench: Generating Code, Specifications, and Proofs All at Once"
- 著者: Xun Deng, Sicheng Zhong, Barış Bayazıt, Andreas Veneris, Fan Long, Xujie Si
- 所属: University of Toronto, Vector Institute
- arXiv: 2505.19271 (v2, 2025)
- URL: https://arxiv.org/abs/2505.19271

**問題設定**

「自然言語問題記述」→「(i) formal spec 抽出、(ii) verification-aware 言語での実装、(iii) machine-checkable proof 構築」を end-to-end で要求。CLEVER と異なり、Lean 1 つに絞らず複数の検証ツールを横断する。

**ベンチマーク詳細**
- 問題出所: VerifyThis 競技（年次国際フォーマルメソッド競技、2011–2024）
- メインベンチ: 41 challenges, 154 tasks
- 緩和版 VerifyThisBenchXS: 580 tasks（226 code-gen + 233 spec-gen + 121 loop-invariant）
- ターゲットツール: 7 種（Dafny, Why3, VeriFast, VerCors, Frama-C, Verus, CBMC）

**仕様アーティファクト**
- Pre-conditions（requires clauses）
- Post-conditions（ensures clauses）
- Loop invariants
- Intermediate assertions

**評価メトリクス**: pass rate（コンパイル + 検証通過）+ "coherence check"（仕様が問題意図と整合しているか）

**最先端 LLM スコア**（Zero-shot / After Refinement）:
| モデル | Zero-shot | Refined |
|--------|-----------|---------|
| o3-mini | 3.62% | 9.37% |
| Claude | 2.32% | 7.98% |
| GPT-4o | 1.48% | 6.22% |
| Llama | 3.34% | 7.88% |
| o4-mini | 0.93% | 7.98% |
| Gemini | 1.48% | 6.86% |
| DeepSeek | 1.02% | 5.19% |
| Qwen | 0.28% | 1.11% |

**失敗モード優先順位**:
1. NOGEN（コード生成すらしない）
2. Compilation errors（両ベンチで dominant）
3. Timeout
4. Partial verification failures

緩和版（XS）ではテンプレート提示で compilation error が減少 → "syntax accuracy"の支援は effective。ただし semantic correctness は依然 sub-10%。

**キーステートメント**: "specification–intent alignment problem" は依然として技術的に難しい。Models must "interpret informal natural language descriptions and formalize them into precise logical specifications, requiring both semantic understanding and formal reasoning capabilities."

**新基盤への含意**: 競技問題（教科書ではなく実用近接）で SOTA が 10% を超えない。VerifyThisBench は CLEVER（HumanEval ベース）よりも問題が複雑なはずだが、tool diversity（7 種）と緩和版の存在で「部分自動化」の道筋を提供する。**新基盤研究 tree も仕様生成と実装生成を「分離評価」できる pipeline を持つべき**。

---

### 1.4 VeriBench — Miranda et al. (AI4Math @ ICML 2025)

**書誌情報**
- 完全タイトル: "VeriBench: End-to-End Formal Verification Benchmark for AI Code Generation in Lean 4"
- 著者: Brando Miranda, Zhanke Zhou, Allen Nie, Elyas Obbad, Leni Aniva, Kai Fronsdal, Weston Kirk, Dilara Soylu, Andrea Yu, Ying Li, Sanmi Koyejo
- 所属: 主に Stanford
- 会議: 2nd AI for Math Workshop @ ICML 2025（poster）, 2025-07-09 公開
- URL: https://openreview.net/forum?id=rWkGFmnSNl, https://icml.cc/virtual/2025/52376

**問題設定**

Python 関数（または docstring）→ 完全な Lean 4 プログラム（実装 + unit test + 正当性定理 + 形式証明）の生成。CLEVER と異なり、unit test を含めた「教科書的」なフルパッケージを要求する。

**ベンチマーク詳細**
- 113 tasks の内訳:
  - 51: HumanEval 問題
  - 42: easy exercises
  - 10: classical algorithms
  - 11: security challenges
- 全 reference solutions が `lake build` で通り、Lean verifier で証明される

**Trace Agent アーキテクチャ**

VeriBench の最大の貢献は「self-optimizing Trace agent」のリファレンス実装。
- Generative optimization traces をベースにした closed loop
- 3 段階: baseline → self-debug → self-improve
- コンパイルエラーが self-debugging と proof refinement をトリガー

**性能**:
| 設定 | 成功率 |
|------|--------|
| Claude 3.7 Sonnet, single-shot, HumanEval subset | 12.5% (compile) |
| LLaMA-70B, 50 feedback-guided attempts | 0% (compile) |
| Trace Agent, zero-shot baseline | 8/113 (7%) |
| Trace Agent, after 5 iterations | 67/113 (59%) |

**重要発見**:
- LLaMA-70B は 50 回 retry しても compile しない → スケーリングだけでは解決しない
- Trace agent の iterative refinement は単発生成の **8x 改善**（7% → 59%）
- ただし「compilation」と「proof certification」の区別は元論文では separate されておらず、Trace の 60% は compile 通過率の可能性高い（CLEVER の経験から推定すると、proof までの fully verified rate はさらに 1/10 程度になる可能性）

**新基盤への含意**: 
- **エージェント化が決定的に重要**: 単発 LLM では 12.5% → Trace で ~60%。コンパイラフィードバックループは必須。
- agent-manifesto の `/research` skill が Gate-Driven Workflow で iterative refinement を構造化することは、VeriBench の知見と方向性が一致。
- ただし VeriBench も unit test を含むため、agent-manifesto が「テストを改竄しない」L1 安全境界を持っているのは健全な設計。

---

### 1.5 Vericoding Benchmark — Bursuc et al. (Beneficial AI Foundation, MIT, 2025)

**書誌情報**
- 完全タイトル: "A benchmark for vericoding: formally verified program synthesis"
- 著者: Sergiu Bursuc, Theodore Ehrenborg, Shaowei Lin, Lacramioara Astefanoaei, Ionel Emilian Chiosa, Jure Kukovec, Alok Singh, Oliver Butterley, Adem Bizid, Quinn Dougherty, Miranda Zhao, Max Tan, Max Tegmark
- 所属: Beneficial AI Foundation (主), MIT
- arXiv: 2509.22908 (v1, 2025-09-26)
- URL: https://arxiv.org/abs/2509.22908

**問題設定 — Vericoding 概念の定義**

> "vericoding" = LLM-generation of formally verified code from formal specifications, in contrast to "vibe coding" which generates potentially buggy code from natural language descriptions.

つまり vericoding は spec を **入力として与えられた前提**で実装と証明を生成する。VerifyThisBench / CLEVER とは異なり、自然言語からの仕様抽出は scope 外。これにより spec generation の困難さを「他のチームの問題」として分離している。

**ベンチマーク規模（最大）**
- 総タスク数: 12,504 仕様（うち 6,174 が新規 unseen）
- 言語別: Dafny 3,029, Verus/Rust 2,334, Lean 7,141
- ソース: APPS, DafnyBench, NumpyTriple, VerifiedCogen, Verina, Bignum, NumpySimple, HumanEval（CLEVER）, FVAPPS

**Specification 構造（Section 3.1 で定義）**
- documentation = intent + 任意で pseudocode
- specification = function signature + conditions（preconditions, postconditions）
- code = 実行可能な実装
- proof = formal demonstration of correctness w.r.t. spec
- context = 外部の boolean 述語、数学関数、データ構造、アルゴリズム
- ITP では spec + impl が definition を成し、impl は unfold 可能。Proof と組んで theorem を成す
- ATP では spec と impl が proof-carrying code として interleave

**評価**: 5 attempts/task（BigNum のみ 10）。各試行は LLM が code+proof を生成 → cheating パターン検出 → 検証ツールに通す → エラーをフィードバック

**最先端 LLM スコア（Table 3 より、model union = 全モデルで誰か 1 つでも解けた割合）**:

Dafny:
| モデル | 平均 |
|--------|------|
| Claude-Opus-4.1 | 67.5% |
| GPT-5-mini | 66.9% |
| GPT-5 | 66.1% |
| Claude-Sonnet-4 | 64.6% |
| Gemini-2.5-pro | 55.0% |
| Grok-code | 53.0% |
| **Model union** | **82.2%** |

Verus:
| モデル | 平均 |
|--------|------|
| GPT-5 | 30.9% |
| Claude-Opus-4.1 | 24.6% |
| Gemini-2.5-pro | 24.1% |
| Claude-Sonnet-4 | 19.9% |
| **Model union** | **44.3%** |

Lean:
| モデル | 平均 |
|--------|------|
| GPT-5 | 17.9% |
| Claude-Sonnet-4 | 11.9% |
| Gemini-2.5-pro | 10.9% |
| Claude-Opus-4.1 | 4.2% (Verina), 11.8% (DafnyBench), 3.1% (HumanEval) |
| **Model union** | **26.8%** |

**重要観察**:
- **Lean が最も困難**: 26.8% に対し Dafny 82.2%, Verus 44.3%。著者曰く: LLM は数学的定理証明データで訓練されており code verification データが少ない。Lean ATP-style tactics（grind, canonical 等の新規 tactics）の例も少ない。
- **DafnyBench での進捗**: 2024 年 6 月の SOTA は 68% (Opus-3) → 2025 年 9 月で 89% (Opus-4.1), 96% (model union)。**1 年強で 28pt 改善**。
- **NL description は性能改善せず**: 著者は Verina で informal description を prompt に含めても **statistically significant な改善なし**（むしろ slightly worse）。これは仕様が既に明確ならば NL は noise。
- **Spec length is weakest predictor**: Solution length が困難さの clearest predictor（コード長くなる → エラー確率増）

**Cheating 検出（ベンチマーク設計の重要性）**

著者は LLM の cheating パターンを 4 種特定:
1. `assume(false)` または `sorry` で proof bypass → proof checker で reject
2. Postcondition を `ensures true` に弱める → spec 改変禁止で防御
3. Spec から implementation を漏らす（CLEVER で同問題）→ ghost functions で部分緩和
4. Comment block manipulation で intermediate spec を消す → 観察されず

Manual inspection: Lean tasks の **9% は仕様が too weak**、追加 15% は poor translation。CLEVER との重複を考えると **15–25% の仕様は trivial solution を許す**。

**新基盤への含意**:
1. **Lean は他の verification language より 3-8x 難しい**（成功率比）。新基盤が Lean 4 を選ぶなら、その追加コストを覚悟する必要がある。
2. **Spec があれば LLM は実装可能性高い**: Vericoding は CLEVER と違い spec を入力にする → Lean 26.8%、Dafny 82.2%。つまり「研究 tree の Lean 仕様化」を人間 + LLM で達成すれば、その後の実装段階は LLM に任せられる可能性が高い。
3. **Model ensemble が effective**: union が個別 best より大きく上回る。MoE-style routing の余地あり。

---

### 1.6 Atlas Computing — speclib & AI-Assisted FV Toolchain (Lin, Miyazono, Windham, v1.2 2025-01)

**書誌情報**
- 完全タイトル: "A Toolchain for AI-Assisted Code Specification, Synthesis and Verification"
- 著者: Shaowei Lin (Topos Institute), Evan Miyazono, Daniel Windham (Atlas Computing)
- 公開: 2025-01-06 (v1.2)
- URL: https://atlascomputing.org/ai-assisted-fv-toolchain.pdf
- 関連: blog.atlascomputing.org/p/cslib-leans-formal-software-foundation, blog.atlascomputing.org/p/ide-for-validating-specifications

**ビジョン**

完全自動化を諦め、既存 FV ワークフローを augment する 12 ツールを提案。総コスト 6.2M USD、bare minimum prototype に 21 人年。「人間フィードバックは specifications, implementations, proofs 全段階で必要—言語モデル能力の不足を補うだけでなく、要件の進化や実装トレードオフ（メモリ vs 帯域）に応じて長期的にも必要」と明示。

**12 ツール構成**

Modeling theme:
- WorldModel ($250k, 12mo, Tech transfer): 論理フレームワーク + DSL のケーススタディ
- LegacyCode ($250k, 12mo): 既存コード/ドキュメント/実行ファイル
- InterAgent ($600k, 12mo): 人間 ⇄ AI agent 間の情報交換
- InterFramework ($300k, 12mo): logical framework 間の transpilation

Specification theme:
- **Autoformalization** ($600k, 12mo, Tech transfer): NL → formal language
- **Autoinformalization** ($300k, 12mo): formal → NL（人間レビューを助ける）
- Implementation2Spec ($300k, 12mo, Derisk): code → spec
- InputOutput2Spec ($300k, 12mo, Derisk): I/O ペアから spec

Generation theme:
- GenerateAndCheck ($600k, 12mo, Derisk): auto-active framework での実装生成
- **CorrectByConstruction** ($1.2M, 24mo, **Explore**): expressive framework で実装と proof を joint 生成
- ProgramRepair ($300k, 12mo): program/proof/spec の divergence 修復
- **ProgramEquivalence** ($1.2M, 24mo, Explore): 2 つのプログラムの等価性判定

**3 つのワークフロー**
- **Formalize**: legacy code に spec/proof を追加
- **Construct**: spec のみから verified system を構築
- **Translate**: legacy 言語から新フレームワークへ

**speclib 提案（重要）**

別資料（Atlas blog）にて: speclib は **Mathlib に対する "software specification" の対応物**。安全性とセキュリティの crucial な仕様の Lean 4 ライブラリ。推定構築費 $250k。
- 関連プロジェクト CSLib（Atlas が支援）が「Lean's formal software foundation」として既に始動。Tech lead は Alexandre Rademaker（Atlas hosted）。
- AWS s2n-bignum 暗号ライブラリの Lean 4 移植（最初の ARM assembly proof 完了）
- 将来は cryptography, complexity theory もカバー
- Mathlib との根本的差異: 「ソフトウェアでは performance が重要、数学では性能不要」

**X3DH ケーススタディ（specifications IDE）**

Signal Foundation の X3DH protocol を題材に、Atlas が specification IDE を開発:
- IDE + X3DH 仕様文書 + Lean 4 形式化 + informal-formal mapping annotations
- 目標 by 2025 年末: formal methods の専門知識を持たない開発者が「ツールが introduce した spec のミス」を発見できる
- "humans will need to review the many clarifying assumptions that refined the informal documents into formal specifications"

**5 つの formal verification 構成要素（Atlas 整理）**
1. Logical framework（auto-active: Dafny, Frama-C, Why3, Verus, Liquid Haskell / expressive: Coq, Lean, Isabelle, HOL, F-star）
2. Domain specific logic（PyTorch, Django に相当する formal verification 版）
3. Specifications
4. Proofs
5. Implementations

**新基盤への含意（最重要）**:
1. **完全自動化の幻想を捨てる**: Atlas のような実践的研究組織でも「人間 feedback は長期的にも必要」と認めている。新基盤の研究 tree も spec 段階で人間レビューを必須化すべき。
2. **speclib が決定的に必要**: agent-manifesto の Manifest/ は数学的公理系（T1-T8 等）を持つが、software-specific な spec library を欠く。**新基盤独自の speclib（agent-spec-lib）構築を提案**: D1-D18 設計原則の形式化、L1 安全境界の lean predicates 化、V1-V7 メトリクスの formal definition 化。
3. **Modular tool design**: Atlas の 12 ツール分割は agent-manifesto の skill 分割（/research, /verify, /trace 等）と発想が同型。各 skill が独立にデリスクされ tech-transfer 可能な状態を維持すべき。
4. **Formalize/Construct/Translate の 3 ワークフロー**: agent-manifesto は現状「Formalize」（既存コードへの公理系適用 = brownfield skill）と「Construct」（instantiate-model skill）を持つ。**Translate ワークフロー（既存プロジェクトを別の formal framework へ移行）は未整備** — 将来の skill 候補。

---

## Section 2: 横断的発見

### 2.1 「仕様生成」の本質的困難さ

**観察 A: 仕様の "gap"**

CLEVER の図 2 が決定的に示すこと: `computable spec`（Boolean を返す）と `non-computable spec`（Prop を返す論理述語）の差。前者は LLM が容易にコピーできる leaky benchmark を生む。本物の仕様生成は「**実装と semantically equivalent だが構造的に異なる Prop を構築する**」必要があり、これは intent の抽象化能力を要求する。

Vericoding 研究も同じ問題を ghost function で部分的に対処したが、Lean tasks の 9% は依然 too weak。VERIFYAI もこの "specification–intent alignment problem" を C1 として最重要課題に位置付ける。

**観察 B: 段階別困難さ**

| 段階 | LLM 単独成功率 | エージェント込み | 評価 |
|------|--------------|---------------|------|
| Spec compilation（型チェック通過）| 60-90% | 80-90% | LLM は仕様を「書ける」 |
| Spec certification（意味的等価性証明）| 0.6-1.9% | 1.9% | **致命的ボトルネック** |
| Implementation compilation | 60-85% | 80%+ | LLM は実装を「書ける」 |
| Implementation certification（正当性証明）| 5-9% | 8.7% | 困難だが進歩中 |

仕様等価性証明が際立って難しいのは「**正解の implementation 手がかりがない pure semantic reasoning**」だから。CLEVER 著者: "proving that a generated spec is semantically equivalent to a non-computable reference specification requires models (or agents) to reason abstractly about intent, without access to implementation-level cues."

**観察 C: タスク mismatch**

CLEVER で Claude-3.7+COPRA は 14 problems の implementation を certify できるが、その 14 問はほぼ全て spec certification が困難（だから E2E は 1 問のみ）。「**仕様が証明しやすい問題と実装が証明しやすい問題は別**」という構造的非整合がある。

### 2.2 自動化の限界（定量比較）

| ベンチマーク | Best E2E | 入力 | 規模 | 言語 |
|------------|---------|------|------|------|
| CLEVER | 0.621% (1/161) | NL | 161 | Lean 4 |
| VerifyThisBench | 9.37% (refined) | NL | 154 | 7 ツール |
| VeriBench Trace | ~59% (compile, not E2E) | Python+docstring | 113 | Lean 4 |
| Vericoding (Lean) | 26.8% (model union) | spec-only | 7,141 | Lean 4 |
| Vericoding (Dafny) | 82.2% (model union) | spec-only | 3,029 | Dafny |

**読み方**:
- 自然言語 → 完全検証は 1-10% のオーダー
- 仕様が与えられれば Dafny は 80%+, Lean でも 27%
- VeriBench は compile only で proof not certified
- 1 年で Dafny verification は 68% → 96% へ。**Spec が固定された範囲なら scaling work**。

### 2.3 人間との分担パターン（既往研究から抽出）

(1) **Atlas モデル**: 人間が specification 段階の認定者。AI が autoformalization 草稿、人間が refinement、autoinformalization で人間レビューを助ける。

(2) **VERIFYAI モデル**: ドメインオントロジー + tool-neutral intermediate format で複数 tool に展開。Frama-C ACSL のような auto-active framework + assertion-level focus で部分自動化。

(3) **Vericoding モデル**: 仕様は人間（または別研究）が作る前提。LLM は implementation+proof のみ担当。

(4) **CLEVER モデル**: 完全自動化を測定するための adversarial benchmark。失敗を通じて gap を定量化。

### 2.4 言語選択の決定的影響

Vericoding データは明確: 同じモデル × 同じ問題でも、Dafny は Lean の 3-8 倍解ける。理由（著者推察）:
- Lean は数学定理証明データで主に訓練、code verification データ少ない
- Dafny は uniform mathematical types、Verus/Lean は ghost types/native types を区別
- Lean ATP-style tactics（grind, canonical）の使用例が訓練データに不足

**含意**: 新基盤が「Lean 4 で研究プロセスを spec 化」するなら、**Lean 4 そのものの困難さによる係数 3-8x のコスト**を予算に組み込むべき。

---

## Section 3: 新基盤への適用案

### 3.1 達成可能性の現実的評価

**Question**: agent-manifesto 新基盤の「研究プロセスを Lean 型として正しく仕様化する」は達成可能か？

**Answer**: **完全自動化は不可能（CLEVER 0.6%）。人間 + LLM 共同編集 + speclib があれば実用可能（Vericoding Lean 26.8%, Dafny 82%）。**

新基盤研究 tree の難易度の見積もり:
- 研究プロセスを記述する vocabulary（observation, hypothesis, verification, integration, retirement）の Lean 4 仕様化 = **新基盤独自の speclib 構築**
- 各ステップの pre/postcondition 定義 = 人間の概念設計が必須
- LLM は spec 草稿生成 + tactic 提案 + proof refinement に貢献可能
- 全自動の gate-driven workflow は **0.6-10% の成功率**しか期待できない → 必ず人間 review gate を挟むべき

### 3.2 推奨戦略: 4 層アーキテクチャ

**Layer 1: speclib (agent-spec-lib)**
- agent-manifesto 公理系（T1-T8, P1-P6, L1-L6, V1-V7, D1-D18）の Lean 4 述語化
- D1-D18 設計原則を `Prop` として表現（CLEVER の non-computable spec 流儀）
- 例: `def L1_safety (action : AgentAction) : Prop := ¬ destroysTests action ∧ ¬ leaksSecrets action ∧ ...`
- Atlas の speclib（CSLib 連携）を fork して agent-manifesto domain に特化
- Cost 見積もり: $250k 相当（Atlas 推定値）= 1-2 人年程度の effort

**Layer 2: 人間-LLM 共同編集 IDE（spec authoring）**
- Atlas X3DH IDE のような side-by-side ビュー: NL 説明 ⇄ Lean spec
- Autoinformalization で Lean spec を自然言語に戻し、人間が intent gap を発見
- agent-manifesto には既に `/instantiate-model` skill があり方向性は一致 → spec authoring 専用の skill 拡張が望ましい

**Layer 3: Trace-style エージェント（implementation + proof）**
- VeriBench の Trace agent パターンを採用: zero-shot → self-debug → self-improve
- compile error と proof error を fed back する closed loop
- agent-manifesto の `/research` skill の Gate-Driven Workflow と整合的
- 期待成功率: 10-60%（complete pipeline）— 人間レビュー gate が必須

**Layer 4: Verifier-as-Oracle**
- Lean 4 kernel を ground truth として使う
- agent-manifesto の `/verify` skill が既にこの役割を持つ
- 拡張案: Lean compiler 出力を即座に LLM フィードバックする hook

### 3.3 段階的実装ロードマップ

**Phase 1（即時, ~1 month）**: 既存 manifest を現状の Lean 4 形式化と integrate
- Manifest/ の 55 axioms (2026-04-17 実測) を CLEVER 流の non-computable spec に書き換え
- D1-D18 を Prop として記述
- AC: `lake build Manifest` が通り、`grep -r "^axiom"` で 55 確認

**Phase 2（短期, ~3 months）**: agent-spec-lib v0.1 構築
- 研究プロセス vocabulary（5 verbs: observe, hypothesize, verify, integrate, retire）を Lean type で表現
- 各 verb の pre/postcondition を非計算的 Prop で定義
- 5-10 個の "exemplar" research tasks を手動形式化（CLEVER の 5 問 few-shot dataset 流）

**Phase 3（中期, ~6 months）**: Trace-style spec authoring agent
- `/research` skill に LLM 草稿生成 + 人間 refinement gate を組み込む
- VeriBench の self-debug loop を Lean compiler 出力で駆動
- Gate 通過率を計測（V1-V7 と並行）

**Phase 4（長期, 12+ months）**: 公開可能な新基盤 spec library
- speclib v1.0 として外部公開
- 他プロジェクトが import できる Lean module として packaging
- 累積 case study 数を benchmark として公開

### 3.4 具体的設計判断

(1) **Lean 4 を採用するコスト**: Vericoding データが示す 3-8x のコスト係数を覚悟。代替案として Dafny も検討する価値あり（auto-active で 82% 通る）が、依存型による D1-D18 表現力の優位性は Lean のみが提供。**結論: Lean 4 維持、ただし Dafny との dual track も探索余地あり**。

(2) **spec leakage 対策**: CLEVER の non-computable Prop 流儀を採用。agent-manifesto の axiom はもともと Prop なので自然な fit。

(3) **人間 gate の構造化**: Atlas の InterAgent ツール構想（人間 ⇄ AI agent の構造化情報交換）を採用。`/research` skill の Gate-Driven Workflow に Lean compile output を渡す hook を追加。

(4) **メトリクス**: V1-V7 に追加する候補:
- V8: spec certification rate（自動生成された Lean 仕様が certified spec library と等価である割合）
- V9: trace agent iteration count（収束までの平均ループ回数）
- V10: human gate intervention rate（spec 段階で人間が修正した割合）

---

## Section 4: 限界と未解決問題

### 4.1 サーベイの限界

(1) **Atlas Computing の経済モデル未検証**: $6.2M / 21 人年の見積もりは 2024-2025 年時点。LLM 進歩が早く、CorrectByConstruction（$1.2M）の "Explore" カテゴリは大幅短縮の可能性あり。

(2) **VeriBench の compile vs prove 区別不明瞭**: 公式論文が OpenReview で 403。LinkedIn と icml.cc から得たデータは 60% が compilation か full verification か曖昧。CLEVER の経験から見ると compile only の可能性が高い → fully verified rate はさらに低い。

(3) **言語間比較の confounder**: Vericoding が Lean 26.8% vs Dafny 82.2% としても、tasks が完全に同じ問題セットではない（NumPy 系などソース依存）。直接の能力差ではない可能性。

(4) **新興手法の未カバー**: Seed-Prover (50%+ on PutnamBench), AlphaProof, Harmonic Aristotle 等の専門数学 prover は code verification への transfer が未検証。VeriBench の Trace agent や CLEVER の COPRA 以外の novel agent architecture も急速に出現中。

### 4.2 根本的に未解決の問題

(1) **"What is the right specification?" は Lean では答えられない**: Lean は「この仕様を満たすか」を判定するが「この仕様で十分か」は判定しない。研究プロセスに対しては「研究目標として何が valid か」自体が議論対象。**新基盤は spec の選択責任を人間に明示的に残す必要がある**（L1 安全境界と整合）。

(2) **Termination Proofs の体系的欠如**: CLEVER の polynomial root-finding 例。LLM は決定不能な termination obligation を生成しがち。研究プロセス（無限ループ可能な investigation）の停止性をどう保証するか未解決。

(3) **専門知識の不均等分布**: Atlas が指摘する通り、Lean 4 のエコシステムは Mathlib 以外で実用ライブラリが薄い。speclib 構築は新基盤プロジェクト単独では困難 → CSLib 等への upstream 貢献が現実的。

(4) **進歩速度の不確実性**: Vericoding データ（Dafny 1 年で +28pt）は楽観的。CLEVER（1 年経過してもなお 0.6%）は悲観的。新基盤はどちらに賭けるべきか不明。**両シナリオに対応する architecture を持つべき**: 完全自動化が来ても spec library が無駄にならず、来なくても人間共同編集で実用的。

(5) **Cheating 検出の継続的軍拡**: Vericoding は 4 種の cheating パターンを検出したが、新パターン出現の可能性。ベンチマーク自体が継続メンテナンスを要する。

### 4.3 新基盤研究の方法論的提言

CLEVER の経験から:
- **Adversarial benchmark をプロジェクト内に持つ**: 自プロジェクトの spec library に対し、LLM が cheating できないよう non-computable Prop で記述する規律
- **Spec authoring に 25-60 分/問題のコストを予算化**: CLEVER の人手効率データから見て、研究 tree 1 ノード = 1 spec の場合、専門家 1 時間程度の人手コストは不可避
- **Few-shot exemplar の継続蓄積**: CLEVER が 5 問の few-shot dataset を別途維持しているのに倣い、agent-manifesto も exemplar research session を継続収集

---

## Section 5: 出典 URL リスト

### 5.1 一次資料（精読対象）

1. CLEVER Benchmark (NeurIPS 2025): https://arxiv.org/pdf/2505.13938 (v4, 2025-10-23) — Thakur et al., UT Austin / Amazon / Caltech
2. Vericoding Benchmark: https://arxiv.org/pdf/2509.22908 (v1, 2025-09-26) — Bursuc et al., Beneficial AI Foundation / MIT
3. VerifyThisBench: https://arxiv.org/abs/2505.19271 (v2, 2025) — Deng et al., U. Toronto / Vector Institute
4. VeriBench (ICML 2025 AI4Math Workshop): https://openreview.net/forum?id=rWkGFmnSNl, https://icml.cc/virtual/2025/52376 — Miranda et al., Stanford
5. Atlas Computing AI-Assisted FV Toolchain v1.2: https://atlascomputing.org/ai-assisted-fv-toolchain.pdf (2025-01-06) — Lin, Miyazono, Windham
6. VERIFYAI Position Paper (OVERLAY 2025): https://ceur-ws.org/Vol-4142/paper11.pdf (2025-12-22) — Beg, O'Donoghue, Monahan, Maynooth University

### 5.2 関連二次資料

7. CSLib blog post: https://blog.atlascomputing.org/p/cslib-leans-formal-software-foundation
8. Atlas Specification IDE blog: https://blog.atlascomputing.org/p/ide-for-validating-specifications
9. VeriBench LinkedIn announcement (Brando Miranda): https://www.linkedin.com/posts/brando-miranda-40821046_brando-miranda-icml-2025-brandohablando-activity-7352385355083341825-nM-V
10. VerifyThisBench HTML: https://arxiv.org/html/2505.19271v2
11. VERIFYAI supporting documents: https://github.com/arshadbeg/OVERLAY2025_SupportingDocs.git

### 5.3 関連プロジェクト（言及のみ）

12. AlphaVerus (Aggarwal et al.): https://arxiv.org/abs/2412.06176
13. Seed-Prover (Chen et al., 2025): https://arxiv.org/abs/2507.23726
14. SpecGen (Ma et al., 2024): https://arxiv.org/abs/2401.08807
15. nl2spec (Cosler et al., 2023): https://arxiv.org/abs/2303.04864
16. AssertLLM (Fang et al., 2024): IEEE LAD 2024
17. DafnyBench (Loughridge et al., 2025)
18. FVAPPS (Dougherty & Mehta, 2025)
19. mvcgen feature in Lean 4 (Hoare triples; 2025 新機能)
20. KiminaProver-7b: 専門 Lean prover（CLEVER で評価）
21. APOLLO (NeurIPS 2025): LLM + Lean coordination, miniF2F SOTA at 8B model

### 5.4 内部参照（agent-manifesto）

- research/lean4-handoff.md (Section 4.3-4.4): 本サーベイの起点となる handoff 資料
- research/survey_type_driven_development_2025.md: 既存 TyDD サーベイ（補完的）
- lean-formalization/Manifest/: 既存 55 axioms / 1670 theorems (2026-04-17 実測)（speclib 拡張の基盤）
- .claude/skills/research/: Gate-Driven Research Workflow（Trace-style エージェントの土台）
- .claude/skills/instantiate-model/: 条件付き公理系生成（spec authoring の前段）
- .claude/skills/verify/: P2 検証独立性（Verifier-as-Oracle の土台）

---

**ファイル末尾**

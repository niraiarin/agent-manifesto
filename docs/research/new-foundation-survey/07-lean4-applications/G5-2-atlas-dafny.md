# G5-2: ATLAS (Dafny 大規模検証済みコード合成) — 言語選択の根本原因と Lean 転用戦略

調査担当: T1（一時的なエージェント）
調査日: 2026-04-17
対象グループ: 07 Lean 4 Applications / Group G5-2 (ATLAS & Dafny Ecosystem)
前提: G3 (Vericoding Benchmark) の結果 — **Lean 26.8% vs Dafny 82.2%**

---

## Executive Summary（200 字）

ATLAS は TACO-verified から 2.7K の検証済み Dafny プログラムを合成し、task 分解で 19K 学習例を抽出、Qwen 2.5 7B Coder を fine-tune して DafnyBench +24pt (Pass@1 31.8%→55.8%、Pass@5/10 56.9%、論文 abstract 表記「+23pt」は Pass@5/10 基準の丸めと推定) / DafnySynthesis +50pt (Pass@5 65.8%) を達成した。Dafny 優位の根源は Z3/SMT による proof obligation 自動放電 (miniF2F-Dafny の validation 問題 44.7% が空証明で通る)。Lean への転用は不可能ではなく、soundness/completeness lemma パターンと task 分解戦略は移植価値が高いが、spec と proof を分離する必要がある。hybrid 案（Dafny を実装検証、Lean を公理層）は短期的には合理的。

---

## Section 1: ATLAS 論文の精読ノート

### 1.1 書誌情報

- 完全タイトル: "ATLAS: Automated Toolkit for Large-Scale Verified Code Synthesis"
- 著者: Mantas Bakšys (University of Cambridge), Stefan Zetzsche (AWS UK), Olivier Bouissou (AWS US), Remi Delmas (AWS), Soonho Kong (AWS), Sean B. Holden (Cambridge)
- arXiv: 2512.10173 (v1: 2025-12-11, v2: 2026-02-02)
- 会議: POPL 2026 — Dafny Workshop, 2026-01-11, Rennes, France (session "LLMs in Auto-Active Verification", 16:00-16:18)
- 分類: cs.SE (Software Engineering)

### 1.2 問題設定

**データボトルネック問題**: LLM を auto-active verification (Dafny, Verus, F*) に適用する最大障害は「検証済みコード」の希少性。GitHub に生コードは豊富だが、仕様・実装・証明が三位一体で verify される形式の code corpus は極小（DafnyBench = 782 問、DafnySynthesis = 228 問程度）。Lean/Mathlib 側で機械生成データによる prover 訓練が成功している（DeepSeek-Prover, Seed-Prover 等）ことに着想し、その成功を Dafny ドメインに転写する試み。

### 1.3 パイプライン（6 段階）

**入力**: TACO-verified dataset (LeetCode-style Python 問題 + unit tests + reference solution)

1. **Task Generation**: Python reference solution から method signature 抽出
2. **Specification Synthesis**: LLM が `requires` / `ensures` 節を生成。unit test + LLM 生成 variant を Dafny 内 test case として結合
3. **Implementation Synthesis**: 凍結された spec と test case を与えて LLM が実装生成。3 段階 validation:
   - (a) contract adherence (predicate/function/method 適合)
   - (b) Dafny verifier 全 proof obligation 放電
   - (c) test case コンパイルと実行
4. **Proof Synthesis**: invariant・補助 lemma を LLM が追加
5. **Verification**: Dafny verifier (Boogie → Z3)
6. **Repair**: 失敗時は error message を LLM にフィードバックして iterative refinement

### 1.4 Soundness/Completeness 枠組み（ATLAS の核心技術）

単なる spec 生成ではなく、生成された spec が「強く、意味的に正しい」ことを保証する 3 種類の補題を自動構築:

- **Soundness Lemma**: 「仕様が意図を捉えているなら、既知の正解 (test case) を instantiate すれば contract が成立するはず」→ false なら spec が strict すぎる
- **Completeness Lemma (Contradiction 版)**: pre/postcondition を仮定し出力を否定、矛盾を導出する。成立しない → spec が weak すぎる
- **Completeness Lemma (Perturbation 版)**: LLM で出力を系統的に摂動し、contract が依然成立するか確認。成立する → 制約が足りない（「rejected であるべき行動を accept している」）

この仕組みが「computable spec で LLM が spec を実装にコピーする」G3 CLEVER の specification leakage 問題を部分的に解決する。

### 1.5 規模と内訳

**出力プログラム規模**: 2,700 本の完全検証済み Dafny program

**訓練例 19,385 件の task 分解内訳**:

| Task 種別 | 件数 | 比率 |
|---|---|---|
| NL-to-Code Synthesis | 2,751 | 14.19% |
| NL-to-Spec Synthesis | 5,225 | 14.19% (注: 原文の百分率表記は誤記の可能性 — 実値 26.95%) |
| Spec-to-Code Synthesis | 2,751 | 14.19% |
| Specification Repair | 2,353 | 12.14% |
| Implementation Repair | 4,562 | 23.53% |
| Proof Infilling | 1,743 | 8.99% |

**キーポイント**: 失敗した生成試行を「廃棄」ではなく Repair タスクの学習データに変える。これが「program あたり 7+ training example」の秘密で、名目上はデータ効率 7x。

### 1.6 性能結果

**DafnyBench** (782 問, 予定義 contract に assertion/invariant を埋めるタスク):

| モデル | Pass@1 | Pass@5 | Pass@10 |
|---|---|---|---|
| Base Qwen 2.5 7B Coder | 31.8% | 32.4% | 32.4% |
| **ATLAS Qwen 2.5 7B** | **55.8%** | **56.9%** | **56.9%** |
| Claude 3 Opus (baseline) | 53.8% | 65.0% | 67.8% |
| Claude Opus 4.1 (frontier) | — | — | 89.2% |

**DafnySynthesis** (228 問, MBPP 由来, 非自明な仕様を要求する end-to-end 合成):

| モデル | Pass@1 | Pass@3 | Pass@5 |
|---|---|---|---|
| Base Qwen 2.5 7B Coder | 7.5% | 13.2% | 15.8% |
| **ATLAS Qwen 2.5 7B** | **39.0%** | **57.0%** | **65.8%** |
| GPT-4 (baseline) | 33.1% | 49.4% | 53.4% |

**Qwen 2.5 7B という軽量モデルが GPT-4 を Pass@5 で +12.4pt 上回る**ことが本研究の最も強い主張。

### 1.7 難易度別成功率（合成パイプライン側）

| 難易度 | 成功率 | 成功時平均文字数 | 失敗時平均文字数 |
|---|---|---|---|
| EASY | 47.14% | 3,848 | 6,531 |
| MEDIUM | 24.98% | 4,902 | 6,879 |
| HARD | 20.70% | 5,692 | 7,270 |
| VERY HARD | 19.93% | 5,637 | 7,102 |

**観察**: 失敗コードは短いのでなく「冗長で複雑だが最終的に incorrect」— 安易な fail ではない高度な失敗パターン。

### 1.8 ドメイン別成功率 (skill 分類)

- 最高: data structure (14.1%), search (13.1%)
- 最低: range query (4.4%), sorting (6.1%)
- range query が困難なのは「interval に対する quantified property」を spec に書く必要があるため

### 1.9 訓練詳細

- **Base model**: Qwen 2.5 7B Coder (open-source, 検証知識は最小限)
- **Fine-tuning**: Hugging Face TRL による LoRA supervised fine-tuning
- **Compute**: 8× NVIDIA H100 GPUs
- **Epochs**: 最大 10、cross-entropy loss + gradient clipping

### 1.10 Ablation 結果

DafnyBench では soundness/completeness check 除去の影響は軽微 (Pass@10: 56.9% → 56.4%)。これは DafnyBench が contract を予定義で与えるため spec quality が影響しないから。一方 **DafnySynthesis では effect あり**: s&c 除去で Pass@5 が 65.8% → 58.4%、test case 除去で 59.6%。つまり spec を LLM が生成する end-to-end 合成で初めて ATLAS の妙味が出る。

### 1.11 Limitations（原著）

- 7B パラメータは plateau 早く、frontier model (Opus 4.1 = 89.2%) には届かない
- DafnyBench では s&c の利点が活かせない（contract 予定義）
- 将来研究: RL with verifier-based reward, HILBERT / SeedProver 型 agentic loop

### 1.12 データ/コード公開

原論文本文では明示 URL なし（WebFetch で確認）。Stefan Zetzsche 個人サイト (zetzsche.st) と AWS 内部 release に依存する可能性。G5-2 時点では HuggingFace dataset の公開 URL を特定できていない — 要追加調査。

---

## Section 2: Dafny vs Lean 言語選択の深掘り（G3 Vericoding 差の根本原因）

### 2.1 性能差の事実

G3 調査で確認された数値:

- Vericoding: Lean 26.8% vs Dafny 82.2% (差 55.4pt)
- DafnyBench: frontier Claude Opus 4.1 で 89.2%、ATLAS 7B で 56.9%
- miniF2F-Dafny: Dafny verifier が test 244 問中 99 問 (40.6%), validation 244 問中 109 問 (44.7%) を**空の証明 `{}` で自動検証**

Lean 側では Mathlib と KiminaProver/Seed-Prover 等の専門 prover を組み合わせても 50-60% 程度が上限（G3 参照）。

### 2.2 根本原因 — Dafny 優位の 4 要因

**要因 1: Z3/SMT による一階論理 proof obligation の自動放電**

Dafny の verifier は program を Boogie IR に翻訳し、一階論理の verification condition を生成して Z3 に投げる。Z3 は NIA/LIA/array theory/uninterpreted function を自動処理するため、「ループ不変条件が与えられればその下で post が成立すること」の多くは SMT で閉じる。**LLM は事実の insight (invariant guess, lemma statement) だけ提供すればよく、proof step を明示する必要がない**。

Lean は dependently-typed calculus で native に推論するため、`omega`, `linarith`, `decide`, `simp` といった tactic を明示呼出しせねばならず、各 step が kernel 検証を通る必要がある。LLM は「どの tactic を呼ぶか」「どの補題を適用するか」を決定する必要があり、選択肢空間が遥かに広い。

**要因 2: 仕様と実装の一体構文（syntactic coupling）**

Dafny では `method f(x: int) returns (y: int) requires P(x) ensures Q(x, y) { /* imperative body */ }` のように、仕様と実装が一つの宣言に同居する。LLM はコード生成の自然なフォーマットで両者を一緒に produce できる。

Lean では `def f : ... := ...` と `theorem f_correct : ∀ x, P x → Q x (f x) := ...` を分離する必要がある。後者は証明項であり、tactic 言語での構築が必要。**LLM の「コード生成」タスクと「証明生成」タスクが言語内で分離されている**のは LLM にとって不利。

**要因 3: Proof obligation の自動生成**

Dafny は ensure/require/invariant から verification condition を自動生成する。ユーザは「何が成立するか」だけ述べればよい。

Lean は「何を証明するか」(goal) と「どう証明するか」(tactic sequence) の両方をユーザが構築する。mvcgen (Hoare triple 機能, G3 参照) のような新機能で改善中だが、Dafny のレベルに達するには時間がかかる。

**要因 4: エコシステムの spec 密度**

Dafny は「仕様を書くための言語」として設計され、標準ライブラリ・ベンチマーク・チュートリアルが全て spec + proof の形で提供される。LLM の訓練 corpus 内で「検証済みコード」として認識される signal が強い。Lean は Mathlib の定理集が主で、「検証付きプログラム」のサンプル（`List.sorted`, `Finset.max` の実装検証等）は相対的に少ない。

### 2.3 Lean が負けている構造的理由

(a) **表現力が証明負担を増やす**: Lean の依存型は higher-order・data-dependent property を表現できるが、その表現力が「LLM が探索すべき proof 空間」を指数的に膨らませる。Dafny の「一階論理に閉じる」制約は expressivity の犠牲だが SMT 自動化の利益は巨大。

(b) **Tactic 言語の習熟不足**: LLM は tactic の使い分け (`simp`, `omega`, `aesop`, `exact?`) を人間プログラマ並に使いこなせない。pre-training corpus の Lean proof が少ない、tactic の選択が context-dependent、エラーメッセージが理解しにくい等。

(c) **Proof search の探索空間**: hammer tactics (Lean-Auto, Duper) は存在するが、Dafny の Z3 統合ほど透過的ではない。Lean-Auto は external ATP (Vampire, E-prover) への bridge を提供するが、成熟度は Boogie/Z3 に劣る。

### 2.4 逆に Lean が勝る領域

- higher-order property の定式化（ATLAS が扱う LeetCode 問題のレベルではあまり顕在化しない）
- 依存型による invariant の型レベル強制
- Mathlib の depth（Dafny にはこの深さの数学ライブラリが無い）
- 定理証明としての完全性（Dafny は proof object を生成しない — Z3 の「成功した」を信じるだけ）

**研究ノード仕様化 (agent-manifesto の新基盤コンテキスト)** では、Lean の表現力が必要になる局面（例: 高階の observation operator、依存型を使った gate 状態の型）と、Dafny の自動化が有効な局面（例: 単純な research step の pre/postcondition）が混在する。

---

## Section 3: Lean への転用戦略

### 3.1 完全移植は不可能、パターン移植は可能

ATLAS の**アーキテクチャ**（6 段階 pipeline, soundness/completeness lemma, task 分解）は言語非依存。**LLM に渡す prompt** と **verifier との対話プロトコル**が Dafny 特化。Lean 版を作るには以下の置換が必要:

| ATLAS (Dafny) | Lean 4 版への置換 |
|---|---|
| `requires` / `ensures` clause | `def f (x : α) : β := ...` + `theorem f_spec : ∀ x, P x → Q x (f x) := ...` |
| Z3 による自動 discharge | `simp`, `omega`, `decide`, `aesop`, `Lean-Auto` hammer |
| Boogie IR 経由の VC 生成 | mvcgen による Hoare triple 生成 (実験中) |
| Soundness lemma (test-case 代入) | `#eval` による具体値評価 + `decide` 証明 |
| Completeness (contradiction) | `by_contradiction` + `omega` / `decide` |
| Completeness (perturbation) | mutation testing を Lean `#eval` 上で実行 |

### 3.2 パターン別の移植優先度

**高優先度（明確に移植価値あり）**:

1. **Task 分解戦略**: 1 program → 7+ training example への変換は言語独立に有効。Lean 版 TACO を作れば、(NL→def, NL→theorem, def→theorem, spec-repair, proof-repair, tactic-infill) の 6 種 task を構築可能
2. **Soundness lemma (具体例代入による spec 検証)**: CLEVER の non-computable spec 流儀と組み合わせて「spec が cheating していないか」の自動チェックになる
3. **Repair を学習データに変える発想**: 失敗試行を捨てず、error message + 修正パッチ pair として蓄積する。agent-manifesto の `.claude/metrics/` と整合

**中優先度（条件付きで有効）**:

4. **Perturbation による完全性テスト**: Lean では `#eval` で具体値は出るが、mutation は Dafny より構造化が難しい (型システムが strict)。tactic の world で代わりに proof mutation を試す余地あり
5. **LoRA fine-tuning of open model**: Lean の proof corpus が少ないため、Mathlib + CLEVER-Lean + Vericoding-Lean を統合した訓練 dataset 構築が前提条件

**低優先度 / 再設計必要**:

6. **Iterative refinement with compiler error feedback**: Lean のエラーメッセージは Dafny より難解。tactic 失敗時の「次に何を試すべきか」のシグナルが弱い。Lean Copilot 系の aesop with LLM の成熟が先

### 3.3 Hybrid 戦略 — 「Dafny を実装層、Lean を公理層」

**発想**: 全てを Lean で書こうとせず、役割分担。

```
┌────────────────────────────────────────────┐
│  Layer 公理系 (Lean 4)                     │
│  - T1-T8, E1-E2, P1-P6, L1-L6,             │
│    V1-V7, D1-D18 を Prop として定義        │
│  - 高階性質・依存型による研究 tree 型        │
│  - 55 axioms + 1670 theorems の既存遺産    │
├────────────────────────────────────────────┤
│  Layer 実装検証 (Dafny, 新規導入)          │
│  - 研究プロセスの具体ステップ (observe,     │
│    hypothesize, verify) の関数実装          │
│  - pre/post を Lean Prop から翻訳           │
│  - ATLAS パイプラインで spec-impl 合成     │
├────────────────────────────────────────────┤
│  Layer 接続 (bridge)                       │
│  - Lean → Dafny の spec 翻訳規則           │
│  - Dafny 検証結果を Lean-level の certificate│
│    として取り込む (trust annotation)        │
└────────────────────────────────────────────┘
```

**妥当性の検討**:

- (+) 既存 Manifest/ 公理系（55 axioms、1670 theorems — 2026-04-17 実測）は Lean で構築済み。捨てない
- (+) 研究ノードの具体的処理（parse observation, verify hypothesis）は一階論理で十分表現可能。Dafny が fit
- (+) ATLAS の 2.7K dataset + Qwen-ATLAS model が既に公開予定 → 新基盤が Dafny 実装層を持てば即座に 57% の baseline 性能を享受
- (−) Dafny↔Lean の翻訳規則自体が新規研究テーマで、翻訳の soundness 証明が必要
- (−) 2 言語運用は operational cost 増。人間担当者が両言語の熟練を要する
- (−) P2 検証独立性の観点で、Dafny 検証結果を Lean に「信じさせる」のは新たな trust boundary

**判定**: **中長期的には妥当だが Phase 1-2 では採用すべきでない**。Phase 3 以降、Lean 単独で限界を感じた時点で再検討。

---

## Section 4: 新基盤への適用案（研究ノード自動合成への ATLAS パターン）

### 4.1 マッピング: 研究ノード合成 → ATLAS pipeline

agent-manifesto 新基盤の「研究ノード自動合成」(Survey → Gap → Hypothesis → Decomposition → Implementation) を ATLAS の 6 段階パイプラインに写像:

| ATLAS ステージ | 研究ノード版 |
|---|---|
| Task Generation (Python 実装 → method sig) | Survey 結果から Research Gap 候補の抽出 |
| Specification Synthesis (requires/ensures) | Gap に対する Hypothesis の pre/postcondition 定式化 |
| Implementation Synthesis | Hypothesis 検証手順 (実験設計 / subtask 分解) の合成 |
| Proof Synthesis | 検証結果を既存公理系から導出可能と示す proof 構築 |
| Verification | Lean による結論の kernel-check + /verify による independent review |
| Repair | Gate 失敗時の fallback loop (観察データの追加, 仮説修正) |

### 4.2 Soundness/Completeness の研究版

ATLAS の「仕様が cheating していないか」検査を研究文脈に翻訳:

- **Soundness**: 生成された Research Hypothesis が「既知の事実 (exemplar research tasks)」を否定しない。つまり `H ∧ known_facts ⊬ ⊥`
- **Completeness (contradiction)**: Hypothesis を仮定し、結論を否定しても矛盾しない ⇒ Hypothesis が weak すぎる
- **Completeness (perturbation)**: 文脈を少し摂動 (観察データの 10% 変化) しても結論が変わるか ⇒ robustness チェック

### 4.3 Phase 設計

**Phase 1 — 公理層整備と ATLAS pattern preparation (即時, ~1 month)**

- 前提: G3 の Phase 1 成果 (Manifest/ の non-computable Prop 化) を共有
- 新規: ATLAS 論文を `docs/research/` に internalization
- 成果物: Lean-ATLAS feasibility study（本 G5-2 文書 + Phase 2 計画書）
- AC: 次フェーズに進む go/no-go 判定

**Phase 2 — exemplar research task 手動形式化 (短期, ~3 months)**

- 5-10 個の「良い研究ノード」を Lean 4 で完全形式化（ATLAS の手動 few-shot seed に相当）
- 各 exemplar に (observation, hypothesis, verification_outcome) の triple を具備
- task 分解: 1 exemplar から 6+ training datapoint を抽出 (NL↔spec↔impl の 3 方向 + repair 3 種)
- AC: 30-60 datapoint の内部 training set 構築、Qwen fine-tune の PoC run

**Phase 3 — ATLAS 流 pipeline の Lean 版 PoC (中期, ~6 months)**

- Task Generator: 新基盤内部の research corpus (handoff logs, `.claude/metrics/`) から Gap 候補を自動抽出
- Spec Synthesizer: LLM + `/instantiate-model` skill を統合し、Hypothesis の Lean spec 案を生成
- Impl Synthesizer + Verifier: `/research` skill の Gate-Driven Workflow + Lean kernel check
- Repair Loop: 失敗試行を `.claude/metrics/research-repair.jsonl` に蓄積し再学習 dataset 化
- AC: 1 週間 unattended 稼働で 5-10 新規 research node を生成、人間 gate 通過率 >30%

**Phase 4 — soundness/completeness gate の本格実装 (中期, ~9 months)**

- 各 Hypothesis に対し 3 種の lemma を自動構築 (soundness, contradiction, perturbation)
- Lean kernel で lemma の立証可否を判定し、判定結果を V 系列メトリクスに反映
- V 追加候補: V8 spec certification rate, V9 hypothesis robustness score, V10 perturbation survival rate

**Phase 5 — Qwen-ATLAS-style fine-tuned model の内製 (長期, 12+ months)**

- Lean corpus (Mathlib + CLEVER + Vericoding Lean + 新基盤 exemplar) で LoRA fine-tune
- 8× H100 相当の計算資源が必要（AWS or local GPU cluster）
- ATLAS 同等の 7B LoRA で Dafny と同じ +24pt / +50pt（論文表記「+23pt」は Pass@5/10 基準）が実現できるかが賭け
- 代替: Claude / GPT 系 frontier model の few-shot で済ます判断 (コスト vs 自律性のトレードオフ)

### 4.4 既存スキル接続

- `/research` skill → Task Generation / Repair loop の実装母体
- `/instantiate-model` → Spec Synthesis の人間-AI 協調 front-end
- `/verify` → Verification stage (独立検証), soundness lemma judgment
- `/formal-derivation` → Phase 2 の exemplar 手動形式化の実行環境
- `/evolve` → パイプライン自体の P3 学習統治 (成功・失敗パターンの蓄積)

### 4.5 期待成果の見積もり

ATLAS の数値を Lean context で割引くと (Lean↔Dafny 係数を G3 Vericoding の 26.8/82.2 ≈ 0.33 と仮定):

- DafnyBench-equivalent Lean benchmark: base 10% → ATLAS-Lean で 18-19%
- DafnySynthesis-equivalent: base 2-3% → ATLAS-Lean で 20-22%

この数値は**frontier Claude/GPT を使う場合**で、7B Qwen fine-tune 版はさらに低い可能性。妥当な目標は「Phase 5 end で Lean-ATLAS が human+LLM 協調の半自動で 30-40% 成功率」。

---

## Section 5: 限界と未解決問題

### 5.1 ATLAS 自体の限界

(1) **TACO-verified 限定**: ソースが LeetCode-style 問題のみ。algorithmic task に強いが、systems programming / concurrent code / cryptographic protocol 等は範囲外。研究ノード合成には「非 algorithmic」ドメインが多いため直接適用に限界

(2) **7B モデル plateau**: Claude Opus 4.1 の 89.2% vs ATLAS 7B の 56.9%。fine-tune はあくまで open model 底上げで、frontier 性能には届かない

(3) **Soundness/completeness の limited coverage**: test case が捉えられる spec 欠陥のみ検出。「概念的に間違っているが test で露呈しない」欠陥は漏れる

(4) **データ公開状況が不明**: 現時点 (2026-04-17) で GitHub / HuggingFace の公式 URL を特定できず。reproducibility リスク

### 5.2 Lean 転用上の未解決問題

(5) **Lean-Auto / Duper の成熟度不足**: Z3 統合ほどシームレスではない。ATLAS パイプラインを Lean で動かすには hammer tactic の信頼性向上が前提

(6) **Task 分解の 6 種類が Lean で成立するか未検証**: proof-infilling が Lean では「tactic 列穴埋め」になるが、tactic の前後関係が strict で Dafny の assertion 挿入より難度高い

(7) **翻訳 Dafny↔Lean の soundness**: hybrid 案を採る場合、Dafny 検証結果を Lean kernel に「信じさせる」のに `trust` annotation が必要。P2 検証独立性と衝突

(8) **Termination の未解決 (G3 既出)**: 研究プロセスは無限ループ可能な investigation を含むため、Dafny の `decreases` 節も Lean の `termination_by` も機械的には埋まらない

### 5.3 研究ノード合成ドメイン固有の未解決問題

(9) **「研究 Gap が valid か」は形式化不可能**: Hypothesis の意味的妥当性判断は axiom 化できない概念領域。人間 review gate は不可避 (L1 と整合)

(10) **研究 corpus の枯渇**: TACO が 2.7K 問題を提供するが、内部 research corpus に 100+ exemplar を蓄積するのにプロジェクト期間が必要。cold start 問題

(11) **Evaluation benchmark が無い**: DafnyBench / DafnySynthesis 相当の「研究ノード品質」ベンチマークが存在しない。自作する必要あり (Adversarial benchmark の prescripion と整合)

(12) **ATLAS と Vericoding / CLEVER の差分評価が必要**: ATLAS は synthesis pipeline, Vericoding は benchmark, CLEVER は benchmark。直接比較はできず、ATLAS が達成した改善が他ベンチに transfer するかは別評価が必要

### 5.4 方法論的提言

- **Hybrid 判断は Phase 3 末で再評価**: Phase 1-2 は Lean 一本で、成功率が見えた時点で Dafny 実装層を追加するか判定
- **ATLAS 公式データ公開を追跡**: arXiv v3 / GitHub release を quarterly にチェック。公開されれば即座に Lean 翻訳の検討材料
- **Repair loop を metrics に接続**: 失敗試行の error message を `.claude/metrics/` に蓄積する仕組みを Phase 2 までに整備。P4 可観測性と整合
- **Qwen-ATLAS モデルの試用**: 公開されれば claude-code-router 経由で local inference 環境から呼び出せるか検証（既存の local-llm-routing プロジェクトと連携）

---

## Section 6: 出典 URL リスト

### 6.1 一次資料（本調査の主対象）

1. **ATLAS arXiv 論文**: https://arxiv.org/abs/2512.10173 (v1: 2025-12-11, v2: 2026-02-02) — Bakšys, Zetzsche, Bouissou, Delmas, Kong, Holden
2. **ATLAS PDF**: https://arxiv.org/pdf/2512.10173
3. **ATLAS HTML**: https://arxiv.org/html/2512.10173v1
4. **POPL 2026 発表ページ**: https://popl26.sigplan.org/details/dafny-2026-papers/7/ATLAS-Automated-Toolkit-for-Large-Scale-Verified-Code-Synthesis
5. **Dafny Workshop POPL 2026**: https://popl26.sigplan.org/home/dafny-2026

### 6.2 補完的一次資料（Dafny vs Lean 比較）

6. **miniF2F-Dafny (Dafny auto-active での定理証明)**: https://arxiv.org/html/2512.10187v1
7. **Vericoding Benchmark (G3 で既調査)**: https://arxiv.org/pdf/2509.22908
8. **Dafny 公式 doc — Verification Optimization**: https://dafny.org/latest/VerificationOptimization/VerificationOptimization
9. **Dafny 公式リポジトリ**: https://github.com/dafny-lang/dafny
10. **Lean-Auto (SAS 2025)**: https://link.springer.com/chapter/10.1007/978-3-031-98682-6_10
11. **Velvet (Lean 内 auto-active verifier)**: https://github.com/verse-lab/velvet

### 6.3 関連二次資料

12. **VeriBench (G3 既出)**: https://openreview.net/pdf?id=rWkGFmnSNl — Lean vs Dafny のパラダイム差異議論あり
13. **Stefan Zetzsche 個人サイト**: https://zetzsche.st/news.html
14. **LinkedIn POPL 2026 Dafny workshop announcement**: https://www.linkedin.com/posts/stefan-zetzsche-881555168_the-talks-accepted-at-the-dafny-workshop-activity-7395498320586248192-_idZ
15. **Lean vs Dafny discussion (leanprover-community)**: https://leanprover-community.github.io/archive/stream/113489-new-members/topic/Lean.20vs.20Dafny.3A.20Why.20can't.20I.20just.20put.20a.20bunch.20of.20assertions.html
16. **Leaning Into Coding Interview — Lean 4 vs Dafny (Nathan Taylor)**: https://ntaylor.ca/posts/proving-the-coding-interview-lean/

### 6.4 先行研究（ATLAS が inspiration とした）

17. **DafnyBench**: Loughridge et al., 2024-2025 (G3 経由で既出)
18. **DafnySynthesis**: MBPP 由来 228 問ベンチマーク (原論文参照)
19. **TACO dataset**: LeetCode-style Python 問題集 (ATLAS の入力)
20. **DeepSeek-Prover / Seed-Prover (Lean 先行)**: https://arxiv.org/abs/2507.23726 — 機械生成データによる Lean prover 訓練の成功例

### 6.5 内部参照（agent-manifesto / 新基盤）

- `docs/research/new-foundation-survey/07-lean4-applications/G3-spec-generation.md` — Vericoding / CLEVER の精読（本調査の前提）
- `docs/research/new-foundation-survey/07-lean4-applications/G1-cedar-aws.md`, `G2-ai-verification.md`, `G4-meta-views.md` — 姉妹調査
- `lean-formalization/Manifest/` — 既存 55 axioms / 1670 theorems（ATLAS pattern の Lean 適用先）
- `.claude/skills/research/` — Gate-Driven Workflow（Task Generation / Repair loop の土台）
- `.claude/skills/instantiate-model/` — Spec authoring 前段
- `.claude/skills/verify/` — Verifier-as-Oracle、soundness judgment の土台
- `docs/research/local-llm-routing.md` — Qwen-ATLAS local inference 時に接続

---

**ファイル末尾**

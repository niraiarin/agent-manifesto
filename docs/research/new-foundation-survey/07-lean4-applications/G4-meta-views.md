# G4: Lean 4 メタ視点・サーベイ・将来予測

作成日: 2026-04-17
担当: G4 (新基盤研究サーベイ)
位置付け: 新基盤の Lean 4 採用判断のためのメタレベル根拠収集
関連: `research/lean4-handoff.md` Section 3.3 / Section 6, 既往の `03-lean-metaprogramming.md`（技術詳細）と相補的

---

## Section 1: 各対象の精読ノート

### 1.1 AMO-Lean / Truth Research ZK (LambdaClass, 2026-02-16)

**1 次情報 URL**: https://blog.lambdaclass.com/amo-lean-towards-formally-verified-optimization-via-equality-saturation-in-lean-4/
**リポジトリ**: github.com/lambdaclass/truth_research_zk

#### 主張の核心

「Mathlib の代数定理 → equality saturation の書き換え規則 → 最適化された C/Rust コード生成」を end-to-end で実装したシステム。各書き換えに対応する Lean 証明が存在し、構造的整合性 (structural consistency) を保証する：「the rules that the E-Graph applies are mechanically extracted from the same theorems that prove their correctness」。

従来の verified compiler（CertiCoq, Peregrine, CompCert）は「既存の C コードの意味保存」に注力するのに対し、AMO-Lean は仕様（Lean の `MatExpr` DSL）から C プログラムを「導出」する立場。

#### Pipeline 詳細

```
Mathlib Theorem
    ↓ (MetaM extraction via #compile_rules command)
Verified Rewrite Rule (LHS → RHS, with proof)
    ↓ (e-graph saturation; flat hash tables, integer-indexed)
E-Graph (E-Nodes / E-Classes)
    ↓ (Cost Model Extraction; canonical ordering for termination)
MatExpr DSL → Σ-SPL → C (with AVX2 SIMD intrinsics)
```

メタプログラミング階層は `MetaM` モナド経由で `forallTelescope` で量化子を開き、`Pattern` 型に再帰的に変換した上で `RewriteRule` を生成する。

#### 具体例

- 分配則: `a × (b + c) → a × b + a × c`（`ring` タクティクで証明）
- 単位元消去: `a × 1 → a`, `a + 0 → a`
- Cooley-Tukey FFT 同型: `DFT_{mn} = (DFT_m ⊗ I_n) · T_n^{mn} · (I_m ⊗ DFT_n) · L_n^{mn}` を saturation で発見
- Kronecker 積分解 `I_m ⊗ A_n` をループ展開（gather/scatter 構造）に降下
- SIMD: `A ⊗ I_ν` は trivially vectorize 可能

#### 検証カバレッジ（出版時点）

- 19/20 rewrite 規則が形式検証済み（E-Graph モジュール内 0 sorry）
- 18/19 MatExpr lowering constructor が形式証明済み
- `simplify_sound`（scalar rewriter 健全性）形式証明済み
- E-Graph 合成的健全性: "Valid informal argument; formalization in progress"
- 唯一の axiom: `applyIndex_tensor_eq`（順列のテンソル積。`#eval` で全使用サイズについて exhaustive 検証）
- テストカバレッジ: 2850+ tests, 64/64 Plonky3 bit-exact, 120 pathological vectors, UBSan clean

#### Timeline / TRL

- ステージ: プロトタイプ／研究段階
- 生成 C は意図的に簡素（~300 行、ホットパスで動的割当・関数ポインタなし → CompCert 互換サブセット）
- 「In principle, a fully verified chain is possible: AMO-Lean が代数最適化の意味保存を保証し、CompCert が C コンパイルの意味保存を保証する」と将来構想を提示

#### 競合との対比

| 項目 | LLVM/GCC | egg (Willsey 2021) | AMO-Lean |
|------|----------|---------------------|----------|
| 規則の起源 | hardcoded heuristics | Rust 実装 | **Lean 定理（証明付き）** |
| 規則の正しさ | 想定 | テスト | **形式証明** |
| コスト model | 固定 | カスタマイズ可 | カスタマイズ可・パラメータ化 |
| 生成コード保証 | なし | 意味等価をテスト | **意味等価を証明** |

ただしコスト model は「the only unverified component that affects result quality」と認められている（最適性は保証されないが正しさは保証される、という分離）。

#### 設計的トレードオフ

「theoretical completeness」を犠牲にして「termination 保証」を得るため、可換演算には canonical ordering を強制し、双方向規則を避ける。signal processing 領域ではこのトレードオフが許容される。

#### 主要引用

- Willsey et al. "egg: Fast and Extensible Equality Saturation" (POPL 2021)
- Franchetti et al. SPIRAL code generator (IEEE 2005)
- Harvey "Faster arithmetic for number-theoretic transforms" (JSC 2014)
- 関連: CertiCoq, Peregrine, egglog (Datalog + equality saturation)
- 2025 続報: Slotted E-Graphs (PLDI 2025) — 束縛変数を E-graph で扱う拡張、Lean に proof tactic として統合

---

### 1.2 Lean 4 Theorem Prover: Survey & Advances (Tang, 2025-01-28)

**1 次情報 URL**: https://arxiv.org/abs/2501.18639 (cs.LO, cs.PL)
**著者**: Xichen Tang
**所属情報**: arXiv ページから取得不可（PDF 取得不能の制約）

#### 主張の核心

Lean 4 のアーキテクチャ・型システム・メタプログラミング・応用を包括的に概観する survey。設計目標: "designed to facilitate both mathematical rigor and computational efficiency"。メタプログラミング枠組みは "enables the creation of custom proof procedures, enhancing Lean 4's usability and flexibility"。

#### 取得できた範囲

- 型系: dependent type theory ベース、`Prop` と `Type` の階層分離
- タクティクス: `exact`, `apply`, `rewrite`, `simp`, `linarith` 等が標準装備
- 比較対象: Coq (Rocq), Isabelle/HOL, Agda
- Lean 4 の強み: "performance, usability, and the flexibility of its type system"
- 応用: critical software systems, cryptographic applications, systems engineering
- 将来方向: 量子計算、ニューラルネットワーク検証への拡張

#### 制約と補完

このページからは Mathlib の定量データや具体的比較表は取得できなかった。以下、独立検索で補完した（出典は Section 5）。

**Mathlib 公式統計（2026-04 時点）**:
- 定理数: **270,602**
- 定義数: **129,422**
- 貢献者数: **772**
- 推定コード行数: ~2.1M LOC, ~8000 ファイル（2025 年末時点）

**比較プロベーラの状況**（2025-09 時点 Wikipedia 集計）:
> "only six systems have formalized proofs of more than 70% of the [Freek Wiedijk's 100 theorems]: Isabelle, HOL Light, Lean, Rocq, Metamath and Mizar"

3 大ライブラリ:
- Isabelle: Archive of Formal Proofs (AFP)
- Lean: Mathlib (上記)
- Rocq (旧 Coq): Mathematical Components

#### Lean 4 vs 他プロベーラの定性的差分

| 観点 | Lean 4 | Coq/Rocq | Isabelle/HOL | Agda |
|------|--------|----------|--------------|------|
| 基礎 | Calculus of Constructions + 帰納型 | 同 (CIC) | 高階論理 (HOL) | Martin-Löf type theory |
| 数学への自然さ | 高（CIC） | 高 | 中（HOL は弱い） | 高 |
| 古典 vs 構成 | 既定構成的、選択公理 opt-in | 同 | 古典中心 | 構成的 |
| メタプログラミング | **Lean 自身で書く（同言語）** | Ltac/Ltac2/MetaCoq | ML/Eisbach | reflection |
| エディタ統合 | LSP first-class, VS Code 公式 | CoqIDE, Proof General | jEdit, VS Code | Emacs 中心 |
| C FFI | direct | OCaml extraction | code generation | extraction |
| 速度 | 高速コンパイル指向 | 中速 | 中速 | 遅い傾向 |
| 産業採用例 | AWS Cedar, AMO-Lean, Leansec | CompCert, Project Everest | seL4 | 限定的 |

#### Timeline / TRL

論文自体は 2025-01 公開、survey 性質のため特定の TRL 主張なし。エコシステム成熟度の言及あり（"extensive growth of Lean 4's mathematical library"）。

---

### 1.3 Martin Kleppmann "AI will make formal verification go mainstream" (2025-12-08)

**1 次情報 URL**: https://martin.kleppmann.com/2025/12/08/ai-formal-verification.html
**著者**: Martin Kleppmann（Cambridge University 准教授、*Designing Data-Intensive Applications* 著者）

#### 主張の核心（3 段論法）

1. **前提 1**: "formal verification is about to become vastly cheaper" （LLM が proof script を書けるため）
2. **前提 2**: "AI-generated code needs formal verification so that we can bypass human review"
3. **前提 3**: "the precision of formal verification counteracts the imprecise and probabilistic nature of LLMs"
4. **結論**: "formal verification is likely to go mainstream"

#### 経済性の転換

これまで形式検証が普及しなかった理由は単純な経済性:
> "for most systems, the expected cost of bugs is lower than the expected cost of using the proof techniques that would eliminate those bugs."

具体例として seL4: "20 person-years and 200,000 lines of Isabelle code – or 23 lines of proof and half a person-day for every single line of implementation"。さらに「世界に proof system を扱える人は数百人程度（推測）」。

#### LLM が変える理由（hallucination 親和性）

> "writing proof scripts is one of the best applications for LLMs. It doesn't matter if they hallucinate nonsense, because the proof checker will reject any invalid proof and force the AI agent to retry."

→ 二値判定 (decidable) なフィードバックループが LLM 学習との相性で最大の効力を発揮する領域。

#### Timeline 予測

- 具体的な数値や年限なし: "in the next few years", "the foreseeable future"
- 限定要因の予測: "soon the limiting factor will not be the technology, but the culture change"

#### 言及プロベーラ・プロジェクト

- Proof assistants: Rocq, Isabelle, Lean, F*, Agda（**Lean を特別視せず併記**）
- 既存検証ソフトウェア: seL4, CompCert, Project Everest
- 最新の AI 検証ツール: **Harmonic's Aristotle**, **Logical Intelligence**, **DeepSeek-Prover-V2**（"getting pretty good at writing Lean proofs"）
- 概念: "vericoding" vs "vibecoding" (arxiv 2509.22908)

#### 反論の予防的処理

> "That doesn't mean software will suddenly be bug-free... the challenge will move to correctly defining the specification: that is, how do you know that the properties that were proved are actually the properties that you cared about?"

→ ボトルネックが「証明生成」から「仕様生成」に移動する、という診断。これは G4 担当域の handoff Section 4.1（「何を証明すべきか」問題）と完全に一致。

#### 自然言語仕様への展望

> "I could also imagine AI agents helping with the process of writing the specifications, translating between formal language and natural language."

これは VERIFYAI / CLEVER / VerifyThisBench 系研究と接続する（handoff Section 4.3）。

#### 新基盤への含意

- Kleppmann は **Lean を特別視していない**。Coq/Isabelle/F*/Agda を併記。これは「現時点で Lean 4 が支配的ではないがメインストリーム化の波に乗る候補の一つ」という冷静な評価
- 「culture change」がボトルネックという診断 → agent-manifesto の「マニフェスト＝構造的強制」アプローチが、まさにこの culture gap を埋める設計に整合
- 経済性転換のキードライバは LLM。ゆえに新基盤の設計は **LLM 親和性を第一級制約**にすべき

---

### 1.4 LLM-Based Theorem Provers (Emergent Mind topic)

**1 次情報 URL**: https://www.emergentmind.com/topics/llm-based-theorem-provers

#### 主張の核心

LLM 定理証明器を「hybrid systems that integrate large language models with symbolic proof techniques to automate formal reasoning」と定義。proof assistant 統合、合成データ生成、RL 訓練、neuro-symbolic 協調により急進展中。

#### ベンチマーク到達状況（2025-09 時点）

| システム | miniF2F | ProofNet | クエリ数 |
|---------|---------|----------|---------|
| **BFS-Prover-V2** (Xin et al., 2025-09) | **95.08%** | 41.4% | - |
| ProofAug+ERP | 56.1% | - | 500 |
| ProofAug (mixed, curated) | 66.0% | - | 2100 |
| HybridProver (Hu, 2025-05) | 59.4% | - | 128 |
| **STP (Self-Play)** (Dong, 2025-01) | 65.0% | 23.9% | 3200 |
| MA-LoT (Lean4) (Wang, 2025-03) | 61.07% | - | 128 |
| LEGO-Prover (2023) | 50.0% | - | 100 |

→ miniF2F は 2 年で 50% → 95% に跳ね上がり、PutnamBench / FLTEval などより難しいベンチに重心が移行中。

#### 補完情報（独立検索）

- **AlphaProof + AlphaGeometry-2** (DeepMind, 2024): IMO 2024 で銀メダル相当（5 問中 3 問解答）
- **Aristotle** (Harmonic, 2025-07-28): IMO 2025 で 6 問中 5 問正解 = 金メダル相当。Nature 論文 (2025) に掲載
- **Seed-Prover** (ByteDance, 2025): IMO 2025 金メダル相当
- **Leanstral** (Mistral AI, 2026-03-16): 初の Lean 4 用オープンソース AI 検証エージェント、Apache 2.0、6B active parameters。FLTEval pass@2 で 26.3 (vs Claude Sonnet 4.6 の 23.7)、コストは 1 task $36 vs Sonnet $549（**93% 削減**）

#### アーキテクチャ・パターン

1. Whole-proof generation with validation
2. Stepwise/tactic generation with tree search (BFS, beam, MCTS)
3. Modular/block-based generation using lemmas
4. Neuro-symbolic hybridization (LLM + ATP)
5. Meta-collaboration（証明合成と修正を分離）
6. Offline lemma extraction for symbolic prover augmentation
7. Self-play で datasete 生成

#### Lean 4 特化度

> "deployed across Lean, Isabelle, Coq, and domain-specific formal verification pipelines"

しかし **2025 年の主要 SOTA システムは大半が Lean 4 ベース**:
- BFS-Prover-V2 → Lean
- STP → Lean
- MA-LoT → 明示的に "Lean4"
- AlphaProof → Lean
- Aristotle → Lean
- Leanstral → Lean

Lean 4 が de facto standard for LLM-driven theorem proving と化している（理由は次節）。

#### Lean 4 が選ばれる理由

1. **Mathlib の規模**: 270K+ theorems が RAG / fine-tuning データとして使える
2. **エラーメッセージの構造化**: tactic mode のエラーが LLM がパース・修正しやすい
3. **メタプログラミングが Lean 自身**: 合成データ生成スクリプトを Lean で書ける
4. **コミュニティの開放性**: Zulip での議論が公開・アーカイブされ訓練データに使える
5. **モダンな言語設計**: 関数型として直接 LLM training データに適合

#### Frontier Challenges

- "Out-of-domain generalization remains a bottleneck"
- 「真に novel な深い概念補題」の生成が困難
- 「formal proof-checker errors を人間理解可能な指針にマッピング」する難しさ
- multi-agent system の compute / latency tradeoff
- 「scalability to new formalism」が大きなエンジニアリング負荷

---

## Section 2: 横断的発見

### 2.1 Lean 4 採用の合理性 (4 つの一致した signal)

| Signal | Source | 観察 |
|--------|--------|------|
| Mathlib 規模 | mathlib_stats | 270K theorems / 129K defs / 772 contributors → 圧倒的 corpus |
| LLM プロベーラの選択 | Emergent Mind, AlphaProof, Aristotle, Leanstral | 2025 年の SOTA は Lean 4 集中 |
| 産業導入 | AWS Cedar, AMO-Lean | 形式モデル（Lean）/ 本番コード（Rust/C）の二層化が成功パターン |
| メインストリーム化予測 | Kleppmann | Lean を特別視しないが「culture が limiting factor」 |

→ **4 signal の一致は採用判断として強い根拠**。ただし Kleppmann の「Lean を特別視しない」立場は重要な留保（Section 4 で詳述）。

### 2.2 メインストリーム化のタイムライン推定

直接の数値予測は Kleppmann すら避けているが、間接 signal を統合:

| 年 | 観察事象 | 解釈 |
|---|---------|------|
| 2024 | AlphaProof 銀メダル, AWS Cedar 公開 | "技術的可能" 段階 |
| 2025 | Aristotle 金, BFS-Prover 95%, AMO-Lean | "技術的優位" 段階 |
| 2026 | Leanstral オープン化、コスト 93% 削減 | **"経済的逆転" 段階** |
| 2027-2028 (推定) | LLM コスト + Mathlib 規模で形式検証コストが従来 ~10x cheaper | "アーリーアダプター流入" 段階 |
| 2029-2030 (推定) | 規制業種（医療・航空・金融）で標準化議論 | "メインストリーム化" 段階 |

**Kleppmann の「culture change が限定要因」との整合**: 技術的成熟は 2026 で大半達成、残り 3-5 年は採用文化の変化。これは **新基盤プロジェクト (agent-manifesto) が 2026 年に開始する正当性を強める**（先行者として culture を形成する側に立てる）。

### 2.3 競合 prover との比較サマリ

| 観点 | Lean 4 が優位 | 他が優位 |
|------|-------------|---------|
| 数学ライブラリ規模 | Mathlib 270K | Isabelle AFP（数値非取得だが大規模） |
| LLM tooling | 圧倒的（2025 SOTA 集中） | - |
| OS 検証実績 | - | Isabelle (seL4) |
| C コンパイラ検証 | AMO-Lean (新興) | Coq (CompCert は実績 15 年) |
| 暗号スタック | - | F* (Project Everest) |
| 学習教材 | NNG, Mathematics in Lean | Software Foundations (Coq) は古典 |
| メタプロ | Lean 自身で書ける | Coq/Isabelle は外部 ML |
| エディタ UX | LSP first-class | 各 prover 専用 IDE |

→ **「LLM が主役の時代において Lean 4 は支配的」**だが、「OS 検証や暗号など特定領域では他 prover が依然優位」。新基盤の用途（agent との協働による設計開発基礎論の形式化）は **前者領域**にぴったりはまる。

### 2.4 4 source 横断の知見統合

- AMO-Lean → 「Lean を gateway にして他言語へ降下する」アーキテクチャの実例
- Tang survey → Lean 4 の包括的アーキテクチャ整理（教科書的価値）
- Kleppmann → メインストリーム化の経済的論理と限定要因の診断
- Emergent Mind → 数値ベンチマークによる進捗の客観的測定

これら 4 source は相互独立かつ相互補強的。**いずれか単一に基づく判断より、4 source の triangulation で得られる結論は格段に強い**。

---

## Section 3: 新基盤への適用案

### 3.1 Lean 4 採用の長期的妥当性

**結論: 2026-2030 の 5 年スパンで Lean 4 採用は「現時点で正しい賭け」と判断できる。**

根拠:

1. **Mathlib のロックイン効果**: 270K theorems は Coq Mathematical Components（数万規模）を桁違いに凌駕。一度 Lean を選べば「他 prover で同じ corpus を再構築するコスト」が長期的に Lean を defacto standard にする
2. **LLM tooling の集中**: 主要 SOTA システム (AlphaProof, Aristotle, Leanstral, BFS-Prover-V2, STP) が Lean 4 ベース。Network effect が強化される
3. **メタプログラミング親和性**: Lean 自身で metaprogramming できる設計 → agent が Lean のサブエージェントを生成しやすい（agent-manifesto の T1/T2 ループとの自然な相性）
4. **二層アーキテクチャの実証**: AWS Cedar の「Lean モデル＋本番 Rust」「差分テストで一致確認」パターンが production-ready。AMO-Lean は「Lean 仕様＋C 生成」で同パターンを compiler optimization に拡張済み

### 3.2 AMO-Lean パターンの研究 tree 適用

agent-manifesto 内部には既に類似構造がある:

| AMO-Lean | agent-manifesto |
|----------|-----------------|
| Mathlib 代数定理 | `lean-formalization/Manifest/` の axioms (T1-T8, P1-P6 等) |
| `#compile_rules` で書き換え規則を抽出 | `/spec-driven-workflow` で公理 → テスト計画導出 |
| E-Graph saturation | （未実装、検討余地） |
| MatExpr DSL → C | 公理 → スキル / フック / テストへの降下 |

**適用可能パターン (案)**:

1. **「公理 → 派生スキル」の自動化**: `/ground-axiom` を `#compile_rules` 風に拡張し、axiom card から運用ツール（hook, skill, test）を機械的に生成する
2. **Equality saturation の研究 tree への応用**: 設計選択肢が複数の同値変換で表現できる場合、e-graph で全候補を保持し、コスト関数（V1-V7 のメトリクス）で最適解を選ぶ
3. **「証明付き降下」の段階的導入**: AMO-Lean の `simplify_sound` のように、各変換ステップに Lean 証明を付与する。最初は L1（安全境界）の変換のみに限定

### 3.3 メタプログラミングの位置付け

既往の `03-lean-metaprogramming.md` が技術詳細をカバーするので、本ドキュメントは「**なぜ Lean 4 のメタプロが新基盤にとって critical か**」というメタ視点だけ補足:

- Lean 4 メタプロは、agent (LLM) が「Lean コンパイラを操作するスクリプト」を Lean で書ける → agent 自身が verification engine を拡張可能
- これは agent-manifesto の「T1（一時性）が T2（永続性）を改善する」の数学的実現基盤
- 他 prover（Coq Ltac, Isabelle Eisbach）はメタ言語が proof assistant 本体と異なる → agent の自己改善ループに摩擦が大きい

### 3.4 採用シナリオ (1 ページ要約)

```
Phase 1 (2026 H1): 公理系 (lean-formalization/) を Lean 4 で確立 [完了済み]
Phase 2 (2026 H2): 公理 → 派生スキル の trace を /trace skill で機械化 [進行中]
Phase 3 (2026-2027): AMO-Lean パターンで「公理 → 運用ツール」を #compile_rules 風に自動化
Phase 4 (2027): Mathlib との接続。設計開発基礎論 (D1-D9) の数学的根拠を Mathlib で grounding
Phase 5 (2028+): culture change の波に乗り、外部プロジェクトに本基盤を提供（plugin 配布）
```

---

## Section 4: 限界とリスク

### 4.1 Lean 4 を選ぶ固有リスク

| リスク | 重大度 | 顕在化 signal | 緩和策 |
|--------|-------|-------------|--------|
| Lean 4 仕様の breaking change | 中 | Lean 3 → 4 の前例（数年で Mathlib 全面移植） | mathlib4 安定化フェーズに入っており再発確率は低い。pin したバージョン使用 |
| 産業採用が頭打ちになるリスク | 低-中 | Kleppmann が Lean を特別視せず併記 | 二層アーキテクチャ（Lean 仕様＋他言語実装）で部分的に他 prover に切替可能な設計 |
| LLM-prover の主流が他言語に移るリスク | 低 | 現時点では Lean 集中 | 抽象 layer (axiom card) を保ち、proof backend を差し替え可能にする |
| Mathlib の「数学偏重」とソフトウェア仕様の乖離 | 中-高 | speclib 提案 (handoff Section 4.3) はまだ未成熟 | 自前で「ソフトウェア仕様 mathlib」を `lean-formalization/Manifest/` で構築する選択肢 |
| 教育・採用コスト | 中 | 「世界に数百人」(Kleppmann) | LLM-assisted onboarding が緩和。Mistral Leanstral 等のオープンツール活用 |
| 形式化ギャップ（仕様 vs 実装） | 高 | Kleppmann の最重要警告 | AWS Cedar 方式の差分テスト + agent-manifesto の P2（独立検証）で多重防御 |

### 4.2 「culture change が限定要因」リスクへの応答

Kleppmann の最重要診断は「技術的問題は解決される、文化が問題」。agent-manifesto は **マニフェスト＝構造的強制** で文化の慣性を低減する設計。これは Kleppmann 予測の弱点に対応する **構造的回答**を持っている。

具体的対応:
- L1 安全境界: hook で強制 → 個別エンジニアの善意に依存しない
- P3 学習統治: 互換性分類が強制 → 知識の退役を構造化
- T1 一時性: agent ごとに独立 context → 文化の継承は構造に集約

### 4.3 「Lean を特別視しない」立場への反論

Kleppmann が Lean を特別視しない理由は推定 2 つ:
1. Cambridge の研究文化は Isabelle/HOL（同大学発祥）への親和性が高い
2. Kleppmann 自身の研究領域（distributed systems）は TLA+ や Coq の影響が強い

しかし 2025 年の **LLM-driven theorem proving** という具体的文脈では Lean 4 は明確に支配的（Section 1.4 参照）。新基盤は LLM 協働を第一級制約にするので、この文脈では Lean 4 が優位。

### 4.4 AMO-Lean パターンの限界

- E-Graph cost model は unverified（最適性は保証されない）
- canonical ordering で termination を保証する代わりに theoretical completeness を犠牲
- 生成 C は CompCert 互換サブセット限定（汎用 C には未対応）

新基盤への教訓: 「**全部を verified にする必要はない。意味保存（safety）と最適性（liveness）を分離して、前者だけ verify する**」。これは agent-manifesto の L1（安全）と V1-V7（観測指標）の分離に整合。

---

## Section 5: 出典 URL リスト

### 1 次情報（WebFetch で取得）

1. AMO-Lean blog (LambdaClass, 2026-02-16): https://blog.lambdaclass.com/amo-lean-towards-formally-verified-optimization-via-equality-saturation-in-lean-4/
2. Tang "Lean 4 Survey & Advances" (Emergent Mind ページ, 2025-01-28): https://www.emergentmind.com/papers/2501.18639
3. Tang 元論文 (arXiv abs page): https://arxiv.org/abs/2501.18639
4. Kleppmann "AI will make formal verification go mainstream" (2025-12-08): https://martin.kleppmann.com/2025/12/08/ai-formal-verification.html
5. LLM-Based Theorem Provers (Emergent Mind topic): https://www.emergentmind.com/topics/llm-based-theorem-provers
6. Mathlib Statistics (公式, 動的更新): https://leanprover-community.github.io/mathlib_stats.html

### 補完情報（WebSearch 経由）

7. Mathlib GitHub: https://github.com/leanprover-community/mathlib4
8. Mathlib Initiative roadmap: https://mathlib-initiative.org/roadmap/
9. Mathlib formalisation contributions: https://www2.mathematik.hu-berlin.de/~rothganm/mathlib_contributions.html
10. Lean 4 use case (Mathlib): https://lean-lang.org/use-cases/mathlib/
11. Aristotle paper (Harmonic, 2025-07): https://arxiv.org/abs/2510.01346
12. AlphaProof Nature 論文 (2025): https://www.nature.com/articles/s41586-025-09833-y
13. Leanstral 解説: https://emelia.io/hub/leanstral-mistral-ai-formal-verification
14. Leanstral 6B parameters: https://topaiproduct.com/2026/03/16/leanstral-uses-6b-active-parameters-to-beat-models-100x-its-size-at-formal-proofs/
15. Lean Together 2026: https://leanprover-community.github.io/lt2026/
16. Lean Community Zulip case study: https://zulip.com/case-studies/lean/
17. AWS Cedar use case: https://lean-lang.org/use-cases/cedar/
18. Cedar 論文 (arXiv): https://arxiv.org/html/2407.01688v1
19. Lean vs Rocq cultural chasm: https://artagnon.com/logic/leancoq
20. Proof assistant Wikipedia: https://en.wikipedia.org/wiki/Proof_assistant
21. egg POPL 2021: https://dl.acm.org/doi/10.1145/3434304
22. Slotted E-Graphs (PLDI 2025): https://steuwer.info/files/publications/2025/PLDI-Slotted-E-Graphs.pdf
23. Guided Equality Saturation (POPL 2024): https://dl.acm.org/doi/10.1145/3632900
24. HEC ATC 2025: https://www.usenix.org/system/files/atc25-yin.pdf
25. Manifold prediction market (mathlib 10M LOC by 2030): https://manifold.markets/mjmandl/will-lean-mathlib-contain-more-than

### 関連参照（既往サーベイ）

26. agent-manifesto handoff: `/Users/nirarin/work/agent-manifesto/research/lean4-handoff.md`
27. 既往 type-driven survey: `/Users/nirarin/work/agent-manifesto/research/survey_type_driven_development_2025.md`
28. 関連グループ: `03-lean-metaprogramming.md`（同サーベイ内、技術詳細担当）

---

## 補遺: 数値スナップショット (2026-04-17 時点)

| 指標 | 値 | 出典 |
|------|---|------|
| Mathlib 定理数 | 270,602 | mathlib_stats.html |
| Mathlib 定義数 | 129,422 | 同上 |
| Mathlib 貢献者数 | 772 | 同上 |
| Mathlib LOC（推定） | ~2.1M | WebSearch 統合 |
| miniF2F SOTA | 95.08% (BFS-Prover-V2) | Emergent Mind |
| ProofNet SOTA | 41.4% (BFS-Prover-V2) | 同上 |
| FLTEval pass@2 (Leanstral) | 26.3 (vs Sonnet 23.7) | byteiota / Mistral |
| Leanstral コスト削減 | 93% ($36 vs $549/task) | 同上 |
| seL4 検証コスト | 23 行証明 / 1 行実装 | Kleppmann |
| AMO-Lean 検証カバレッジ | 19/20 規則, 18/19 構成子 | LambdaClass |
| Lean 4 SOTA 占有率 (LLM 定理証明) | 主要 6 システム中 5+ | 推定（AlphaProof/Aristotle/Leanstral/BFS/STP/MA-LoT） |

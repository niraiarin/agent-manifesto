# Lean 4 学習・サーベイ Handoff 資料

作成日: 2026-04-17
対象: Claude Code への引き継ぎ用

---

## 1. 理論的基礎（会話で構築した理解）

### 1.1 Curry-Howard 対応

型＝命題、項（値）＝証明。関数の型シグネチャが命題を表し、関数本体がその証明を構成する。

```lean
-- 「AならばA」の証明 = 恒等関数
theorem identity (A : Prop) : A → A :=
  fun (a : A) => a
```

対応表:

| 論理の世界         | プログラミングの世界       |
|-------------------|------------------------|
| 命題 (Proposition) | 型 (Type)              |
| 証明 (Proof)       | 項・値 (Term / Value)   |
| 命題が真である      | その型に属する値が存在する |
| 含意 A → B         | 関数型 A → B            |
| 連言 A ∧ B         | 直積型 (A, B)           |
| 選言 A ∨ B         | 直和型 A ⊕ B            |
| ∀x, P(x)          | 依存関数型 (x : α) → P x |

### 1.2 BHK 解釈（Brouwer-Heyting-Kolmogorov 解釈）

命題 P を「P の証明全体の集合」と同一視する構成的論理の意味論。

- P が真 ⟺ 集合 P が空でない（住人が存在する）
- P が偽 ⟺ 集合 P が空集合

論理結合子は集合演算として定義される:

| 論理     | 集合論的定義                  |
|---------|----------------------------|
| A → B   | A から B への関数の集合 B^A    |
| A ∧ B   | 直積 A × B                  |
| A ∨ B   | 直和 A ⊔ B                  |
| ⊥ (偽)  | 空集合 ∅                    |
| ¬A      | A → ∅                      |

等式型の集合論的定義:

- Eq(a, b) = { refl } （a と b が同一のとき）
- Eq(a, b) = ∅ （a と b が異なるとき）

→ 「でっちあげ」が不可能な理由: Eq(3, 5) は空集合なので、属する元を構成できない。

### 1.3 依存型 (Dependent Types)

型が値を含み、型チェック時に値の計算と比較ができる仕組み。Javaの型システムとの決定的な違い。

```lean
-- 戻り値の型が引数 n, m の値に依存する
def concat (a : Vec α n) (b : Vec α m) : Vec α (n + m) := ...
```

全称命題の表現に不可欠:

```lean
-- 「すべての自然数 n について n + 0 = n」
theorem add_zero (n : Nat) : n + 0 = n := ...
```

### 1.4 帰納的定義と帰納法

すべての自然数は 0 と succ の2規則で生成される。有限の関数で無限個の証明をカバーする。

帰納法の証明 = n を受け取って Eq(n+0, n) の元を返す**関数**を構成すること。

```lean
theorem zero_add (n : Nat) : 0 + n = n := by
  induction n with
  | zero => rfl
  | succ k ih => simp [Nat.add]
```

Lean における全データ型は帰納的に定義され、対応する帰納法の原理が自動生成される。

### 1.5 型チェッカの2段階

| 状況                                    | 型チェッカの対応                       |
|----------------------------------------|--------------------------------------|
| 具体的な値同士（`2+3` と `5`）            | 計算して比較するだけ（definitional equality） |
| 定義に従い簡約できる式（`n+0` と `n`）     | 定義を展開して一致を確認                |
| 計算だけでは示せない式（`0+n` と `n`）     | 人間が帰納法などの証明を与える必要がある（propositional equality）|

### 1.6 タクティクス一覧

| 用途       | 主なタクティクス                  |
|-----------|-------------------------------|
| 計算で閉じる | `rfl`, `norm_num`, `decide`   |
| 構造分解    | `induction`, `cases`          |
| 仮定の利用  | `exact`, `apply`, `assumption`|
| 書き換え    | `rw`, `simp`                  |
| ゴール操作  | `intro`, `constructor`, `left`, `right` |
| 自動証明    | `omega`, `linarith`, `aesop`  |

---

## 2. Lean 4 の境界条件

### 2.1 停止性

- すべての関数は必ず停止しなければならない
- 理由: 無限ループを許すと `loop : False := loop` で `False` の証明が捏造でき、体系全体が崩壊する
- `partial` キーワードで停止しない関数を書けるが、証明には使えない

### 2.2 公理（証明なしに受け入れるもの）

Lean 4 カーネル:
- `propext`: 命題の外延性（同値な命題は等しい）
- `Quot`: 商型の存在

Mathlib が追加:
- `Classical.choice`: 選択公理 → 排中律と `Decidable` が得られる

### 2.3 構成的 vs 古典的のトレードオフ

- 構成的: 「存在する」＝具体例を示せる。計算可能なプログラムを抽出できる
- 古典的（選択公理使用）: 「存在するが具体例は不明」な値を使える。表現力は上がるが計算可能性を失う
- Lean は `Prop`（証明の世界）と `Type`（計算の世界）を分離して両方を使い分ける

### 2.4 ゲーデルの不完全性定理

- Lean の無矛盾性（`False` の証明が構成できない）は Lean 自身の中では証明できない
- 十分に強い形式体系すべてに共通する原理的制約
- 実用上はほぼ問題にならない（カーネルは数千行、多数の研究者が検証済み）

---

## 3. ソフトウェア工学における Lean 4 の応用

### 3.1 本番ソフトウェアの正しさの証明

**主要事例: AWS Cedar**

- Cedar: AWSのオープンソース認可ポリシー言語
- 本番コードは Rust、形式モデルを Lean で作成（本番の約1/10のサイズ）
- Lean モデルに対してセキュリティ性質（健全性・完全性）を証明
- 数百万件のランダム入力で Lean モデルと Rust 本番コードの一致を確認（差分テスト）
- 「Lean で直接アプリを書く」のではなく「仕様を Lean で書いて証明し、本番コードを検証する」アプローチ

参考リンク:
- 公式紹介: https://lean-lang.org/use-cases/cedar/
- 論文: https://arxiv.org/html/2407.01688v1
- AWS ブログ: https://aws.amazon.com/blogs/opensource/lean-into-verified-software-development/
- Cedar Analysis: https://aws.amazon.com/blogs/opensource/introducing-cedar-analysis-open-source-tools-for-verifying-authorization-policies/

### 3.2 AI の出力を形式検証する

- LLM の推論・コード生成の各ステップを Lean 4 の型チェッカで検証
- Lean の二値性（通るか通らないか）が RL の報酬としても使いやすい

主要プロジェクト:
- **Harmonic Aristotle**: 数学問題の解答を Lean 4 で形式検証してからユーザーに提示。IMO 2025 金メダルレベル
- **AlphaProof (Google DeepMind, 2024)**: Lean 4 で数学的命題を IMO 銀メダルレベルで証明
- **Mistral Leanstral (2026年3月)**: コード＋形式証明を同時生成するオープンソース AI エージェント。FLTEval ベンチマーク pass@2 で 26.3（Claude Sonnet の 23.7 を上回る）

参考リンク:
- Leanstral: https://aiautomationglobal.com/blog/mistral-leanstral-formal-code-verification-2026
- VentureBeat 記事: https://venturebeat.com/ai/lean4-how-the-theorem-prover-works-and-why-its-the-new-competitive-edge-in

### 3.3 コンパイラ最適化の正しさの証明

- **AMO-Lean**: Mathlib の代数的定理を書き換え規則としてコンパイルし、コード最適化に使用。各変換ステップに Lean 証明が付く

参考リンク:
- ブログ: https://blog.lambdaclass.com/amo-lean-towards-formally-verified-optimization-via-equality-saturation-in-lean-4/

---

## 4. ソフトウェア検証の核心的課題

### 4.1 「何を証明すべきか」問題

ソフトウェア検証では「仕様の選択は人間の責任」。Lean は「この仕様を満たすか？」を Yes/No 判定するが、「この仕様で十分か？」は判定しない。

例: `reverse` 関数に対して「2回適用で元に戻る」を証明しても、恒等関数もこれを満たす。真に「逆順にする」ことを保証するには、インデックスレベルの仕様（各位置の要素が反転している）を別途定義・証明する必要がある。

### 4.2 LLM による自動化の現状

検証プロセスの3段階と自動化の進捗:

| 段階 | 内容 | LLM による自動化の成熟度 |
|------|------|----------------------|
| 仕様生成 | 「正しい」とは何かを形式定義 | 初期段階（最も困難） |
| 実装生成 | 仕様を満たすコードを書く | 挑戦中 |
| 証明生成 | 実装が仕様を満たすことを証明 | 実用レベルに接近 |

### 4.3 仕様生成に関する最新研究

- **VERIFYAI プロジェクト**: 自然言語要件 → 形式仕様の自動変換を目指す
  - 参考: https://ceur-ws.org/Vol-4142/paper11.pdf

- **CLEVER ベンチマーク (NeurIPS 2025)**: 自然言語 → 仕様生成 → 実装 → 証明の End-to-End パイプライン評価。最先端 LLM でも 161 問中 1 問程度しか成功しない
  - 参考: https://arxiv.org/pdf/2505.13938

- **VerifyThisBench (2025)**: 自然言語記述から仕様・実装・証明を一括生成
  - 参考（言及元）: https://arxiv.org/pdf/2509.22908

- **VeriBench (ICML 2025)**: Python コード → Lean 4 の検証付き実装に変換。Claude 3.7 Sonnet でコンパイル成功率 12.5%、Trace エージェントで約 60%
  - 参考: https://openreview.net/forum?id=rWkGFmnSNl

- **仕様ライブラリ (speclib) の提案**: Mathlib（数学定義ライブラリ）に相当する「ソフトウェア仕様ライブラリ」を構築すべきという提案
  - 参考: https://atlascomputing.org/ai-assisted-fv-toolchain.pdf

### 4.4 証明生成に関する最新研究

- **Lean Copilot**: LLM がタクティクスを提案。証明ステップの 74.2% を自動化
  - 参考: https://arxiv.org/abs/2404.12534

- **APOLLO (NeurIPS 2025)**: LLM + Lean コンパイラの協調。miniF2F で 8B 未満モデル SOTA (84.9%)
  - 参考: https://neurips.cc/virtual/2025/loc/san-diego/poster/116789

- **Goedel-Prover**: オープンソースの Lean 4 向け自動定理証明 LLM シリーズ。Expert iteration + scaffolded data synthesis
  - 参考: https://www.emergentmind.com/topics/goedel-prover

- **Vericoding (2025)**: "vibecoding" に対する "vericoding"（形式検証付きコード生成）という概念を提唱
  - 参考: https://arxiv.org/pdf/2509.22908

---

## 5. 学習リソース

| リソース | URL | 内容 |
|---------|-----|------|
| Theorem Proving in Lean 4 | https://leanprover.github.io/theorem_proving_in_lean4/ | 公式チュートリアル |
| Mathematics in Lean | https://leanprover-community.github.io/mathematics_in_lean/ | Mathlib を使った数学の形式化 |
| Natural Number Game | https://adam.math.hhu.de/#/g/leanprover-community/NNG4 | ブラウザ上で自然数の性質を証明するゲーム |
| Lean 4 Metaprogramming Book | https://leanprover-community.github.io/lean4-metaprogramming-book/ | タクティクス自作等の上級向け |
| Lean 公式サイト | https://lean-lang.org/ | エコシステム全体の情報 |
| Lean Community Events | https://leanprover-community.github.io/events.html | カンファレンス・ワークショップ一覧 |

### 注目イベント（2026年）
- Software Verification in Lean 2026 (Paris, April 20, 2026)
- TYPES 2026 (Gothenburg, May 4-8, 2026)
- Lean Together 2026 (virtual, January 19-23, 2026)

---

## 6. 参考文献・サーベイ論文

- **Lean 4 Theorem Prover: Survey & Advances** (2025年1月): アーキテクチャ・型システム・メタプログラミング・応用の包括的サーベイ
  - https://www.emergentmind.com/papers/2501.18639

- **Martin Kleppmann "AI will make formal verification go mainstream"** (2025年12月): AI による形式検証のメインストリーム化予測
  - https://martin.kleppmann.com/2025/12/08/ai-formal-verification.html

- **Amazon Science: How the Lean language brings math to coding** (2024年8月)
  - https://www.amazon.science/blog/how-the-lean-language-brings-math-to-coding-and-coding-to-math

- **LLM-Based Theorem Provers (Emergent Mind トピック)**: 最新の LLM 定理証明器の包括的まとめ
  - https://www.emergentmind.com/topics/llm-based-theorem-provers

-----

## 7. Atlas Computing ツールチェイン提案書の分析

### 7.1 文書概要

- **タイトル**: A Toolchain for AI-Assisted Code Specification, Synthesis and Verification
- **著者**: Shaowei Lin (Topos Institute), Evan Miyazono, Daniel Windham (Atlas Computing)
- **URL**: https://atlascomputing.org/ai-assisted-fv-toolchain.pdf
- **バージョン**: 1.2 (2025-01-06)
- **Atlas Computing**: https://atlascomputing.org/

形式検証を AI でスケールさせるための12のツール群を提案。全体の最小プロトタイプに約21人年・$6M超と見積もり。仕様生成・実装生成・証明生成を独立した問題として分離し、それぞれに LLM を組み合わせたツールを構想している。

### 7.2 提案された12プロジェクトと後続研究の対応

#### Modeling テーマ

|プロジェクト        |内容                                 |後続研究の状況                                   |
|--------------|-----------------------------------|------------------------------------------|
|WorldModel    |論理フレームワークとドメイン特化論理のケーススタディ         |CSLib (2026) が計算機科学ドメインのライブラリを構築中         |
|LegacyCode    |レガシーコード・ドキュメント・実行可能プログラムのケーススタディ   |体系的な研究はまだ限定的                              |
|InterAgent    |人間と AI エージェントの協調                   |Lean Copilot, APOLLO 等が部分的に実現             |
|InterFramework|論理フレームワーク間の変換（Lean ↔ Coq ↔ Dafny 等）|Aeneas (Rust → Lean) 等の個別ツールは存在するが汎用基盤は未構築|

#### Specification テーマ

|プロジェクト             |内容              |後続研究の状況                                     |
|-------------------|----------------|--------------------------------------------|
|Autoformalization  |自然言語 → 形式言語     |VerifyThisBench, FVAPPS (2025) が自然言語→仕様生成を評価|
|Autoinformalization|形式言語 → 自然言語     |研究は存在するが大規模な評価は少ない                          |
|Implementation2Spec|コード実装 → 仕様の逆方向生成|CLEVER が仕様生成をタスクに含むが、コード→仕様の直接変換ツールは未実現     |
|InputOutput2Spec   |入出力ペア → 仕様の推定   |体系的な研究はまだ非常に限定的                             |

#### Generation テーマ

|プロジェクト               |内容                       |後続研究の状況                                  |
|---------------------|-------------------------|-----------------------------------------|
|GenerateAndCheck     |auto-active フレームワーク向け実装生成|ATLAS (Dafny向け, 2025) が2.7K検証済みプログラムを合成  |
|CorrectByConstruction|表現力の高いフレームワーク向け実装＋証明の同時生成|VeriBench, CLEVER 等が Lean 4 で評価中。成功率は依然低い|
|ProgramRepair        |プログラム・証明・仕様の乖離の修復        |VeriSoftBench (2026) がリポジトリ規模のベンチマークを提供開始|
|ProgramEquivalence   |2つのプログラムの等価性・乖離の判定       |個別研究は存在するが、包括的ツールは未構築                    |

### 7.3 speclib 構想と CSLib

Atlas が提案した最も野心的な構想の一つが **speclib**（仕様ライブラリ）。Mathlib が数学定義を集積したように、セキュリティ・安全性に関する仕様のライブラリを Lean 上に構築するという提案（推定コスト $250k）。

これに部分的に対応するプロジェクトとして **CSLib（Lean Computer Science Library）** が2026年に登場:

- URL: https://cslib.io
- 論文: https://arxiv.org/html/2602.04846v1
- アルゴリズム、データ構造、計算理論（オートマトン、線形論理等）の形式化を進行中
- 2026年末までに学部レベルのアルゴリズム・データ構造コースの多くをカバー予定
- **Boole フレームワーク**: SMT ベースのハンマーとの連携による検証条件の自動生成

ただし CSLib は計算機科学の理論寄りであり、Atlas が構想した「セキュリティ・安全性仕様のライブラリ」とは焦点が異なる。speclib の本来の構想（認可ポリシーの正しさ、暗号プロトコルの安全性等のドメイン仕様）を直接実現するプロジェクトはまだ存在しない。

### 7.4 まだ実現されていない主要ギャップ

1. **コード → 仕様の逆生成（Implementation2Spec）**: レガシーコードから仕様を推定する汎用ツール
1. **入出力 → 仕様（InputOutput2Spec）**: テストケースやログから仕様を逆算する手法
1. **論理フレームワーク間の汎用変換（InterFramework）**: Lean ↔ Coq ↔ Dafny ↔ Verus 間の証明相互運用
1. **ドメイン特化仕様ライブラリ（speclib の本来の構想）**: セキュリティ・安全性・暗号等の仕様カタログ

### 7.5 関連する追加リンク

- **ATLAS (Dafny向け検証済みコード合成パイプライン)**
  - 論文: https://arxiv.org/abs/2512.10173
  - POPL 2026 で発表: https://popl26.sigplan.org/details/dafny-2026-papers/7/ATLAS-Automated-Toolkit-for-Large-Scale-Verified-Code-Synthesis
- **VeriSoftBench (リポジトリ規模の形式検証ベンチマーク)**
  - 論文: https://arxiv.org/html/2602.18307
- **Lean4Lean (Lean の型チェッカを Lean 自身で検証)**
  - 論文: https://arxiv.org/abs/2403.14064
  - ゲーデルの不完全性定理との関連で興味深い: Lean のカーネルの部分的な正しさを Lean 内で証明する試み
- **Vericoding ベンチマーク (vibecoding に対する vericoding)**
  - 論文: https://arxiv.org/pdf/2509.22908
- **LeanDojo エコシステム (AI 駆動の Lean 定理証明)**
  - サイト: https://leandojo.org/
  - Lean Copilot, LeanAgent, LeanProgress 等を含む

---

## 8. 会話中に読了した書籍

- **「ゼロから始めるLean言語入門：手を動かして学ぶ形式数学ライブラリ開発」** (Asei Inoue 著)
  - ファイルパス: `/mnt/user-data/uploads/セ_ロから始めるLean言語入門_手を動かして学ふ_形式数学ライフ_ラリ開発.pdf`
  - 内容: Lean 4 の基礎から Mathlib 開発まで。自然数の証明、タクティクス、帰納法、Quotient 型等をカバー




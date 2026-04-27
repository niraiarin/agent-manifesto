# G5-1: CSLib / Boole — Atlas speclib の唯一の現存実装を精読し、新基盤 Phase 0（agent-spec-lib）の直接参照を確立する

作成日: 2026-04-17
担当: G5-1（新基盤研究サーベイ・グループ G5-1）
対象: CSLib 公式サイト、CSLib 論文（arXiv:2602.04846）、CSLib Spine 論文（arXiv:2602.15078）、Boole フレームワーク（cslib リポジトリ Boole-sandbox ブランチ + Strata boole ブランチ）、周辺の Lean-Auto/Duper/LeanHammer/lean-smt 動向
翻訳対象用語: T1（一時的インスタンス）, T2（永続構造）, P2（検証分離）, P3（学習統治）, P4（可観測性）, L1（安全境界）, V1-V7（健全性指標）, D4（フェーズ順序）, D13（影響波及）
既往サーベイとの相補関係: G3（仕様生成）Section 1.6 で要約された Atlas speclib 構想を「実在物」レベルまで具体化し、G4（メタ視点）で整理された「Lean 4 の工業化動向」に domain library の実装事例を接続する。本ノートは G3 の「speclib が決定的に必要」提言（ID P0 Item、00-synthesis.md Row 497）に対する技術的裏付け文書として位置付ける

---

## Executive Summary（200 字）

CSLib は 2026-02-04 公開の「Mathlib for CS」構想を、Lean 4 Apache-2.0 / Stars 491 / Forks 121 / Commits 436 / Releases 19（v4.29.0-rc6 時点、2026-03-29 現在）の実在するリポジトリとして提供する。Cslib.lean は約 100 の public import を束ね、Computability（DA/NA/Turing/URM）・Foundations（LTS/Inference Systems）・Languages（λ-calc/CCS）・Logics（Linear Logic/HML）・Crypto（Perfect Secrecy/OTP）・Algorithms（MergeSort + TimeM）を公開済み。Boole は同リポジトリ Boole-sandbox ブランチおよび abdoo8080/Strata:boole に配置された IVL で、Boogie 流儀を Lean 4 上に再実装し `StrataVerify` コマンドで SMT（cvc5/Z3）ハンマーへ VC を送出する。LeanHammer（Mathlib 33.3% 証明、miniCTX-v2 79.4% 相対維持）と lean-smt が上流で使われる。新基盤 agent-spec-lib は「CSLib への直接貢献」ではなく **Cslib 依存サブライブラリ（`Cslib.Research.*` 相当の上位層）** として設計すべき。

---

## Section 1: 各対象の精読ノート

### 1.1 CSLib 公式サイト（cslib.io）— プロジェクト・ゴールと組織体制

**1 次情報 URL**: https://cslib.io
**最終取得**: 2026-04-17

#### ミッション・ビジョン

サイトの headline は "A Focused Effort on Formalizing Computer Science in Lean"。公開されている 4 つの柱は:

1. **Formalizing CS Foundations** — 計算モデル、複雑性解析（TimeM 等）
2. **Reasoning about Code** — 検証技法、実コードに対する推論
3. **Repository of Verified Code** — アルゴリズム・データ構造の検証実装
4. **AI Integration** — 学習データセット、AI 支援ツール（LLM/hammer）との接続

#### 資金提供者・パートナー

- Amazon、Google DeepMind、FORM（デンマーク、Fabrizio Montesi の所属 University of Southern Denmark が関与）、Stanford Center for Automated Reasoning

agent-manifesto 文脈への翻訳: **speclib 構想の「産業側スポンサー」としての Atlas Computing は前面には出ていないが、G3 1.6 で確認した通り Alexandre Rademaker は Atlas hosted の tech lead としてコア著者に名を連ねている**（Section 1.2 参照）。CSLib は Atlas の speclib 提案（推定 $250k）を待たずに、既存コミュニティ主導で先行立ち上げた実装と読める。つまり新基盤が「Atlas speclib の domain-specific instance」を名乗るには、CSLib への参照 or サブ化が自然な座標になる。

#### 統治・リポジトリ

- GitHub: https://github.com/leanprover/cslib（leanprover 組織配下 — Lean FRO オーナーシップ下に入っている）
- ライセンス: Apache-2.0
- Issue tracker: GitHub Issues（32 open / 2026-03-29 時点）
- Discussion: Lean Zulip の `cslib` ストリーム（公開論文で明記）
- Organisation.md / Notation.md / CONTRIBUTING.md / CODE_OF_CONDUCT.md を備え、ガバナンス文書が分離配置されている

agent-manifesto 翻訳: `.claude/rules/` と docs/design-development-foundation.md で T2 永続構造を分離している発想と一致。ガバナンス文書を「コード本体と別ファイルで正典化する」パターンは CSLib と共有できる。

#### 観察 — speclib の現時点カバー率

サイトはアルゴリズム・計算理論・オートマトン・論理・暗号の順で Pillar を提示するが、**Atlas speclib 構想が強調していた「セキュリティ仕様」「認可」「運用安全性」は現時点で Crypto の Perfect Secrecy 以外ほぼ未カバー**。したがって、新基盤（agent-manifesto 研究プロセス公理系）は「CSLib に欠けている Atlas 本来カバー対象」である「研究安全性・プロセス統治」層を先取り埋めるポジションに立てる。

---

### 1.2 CSLib 論文（arXiv:2602.04846v1, 2026-02-04）— 設計哲学と 2 本柱アーキテクチャ

**1 次情報 URL**: https://arxiv.org/abs/2602.04846, https://arxiv.org/html/2602.04846v1, https://arxiv.org/pdf/2602.04846
**Subject**: cs.LO, cs.PL / 提出 2026-02-04

#### 書誌

- タイトル: *CSLib: The Lean Computer Science Library*
- 著者（8 名）: Clark Barrett, Swarat Chaudhuri, Fabrizio Montesi, Jim Grundy, Pushmeet Kohli, Leonardo de Moura, Alexandre Rademaker, Sorrachai Yingchareonthawornchai
- 所属: Amazon、Stanford University、Google DeepMind、University of Texas at Austin、University of Southern Denmark、Lean FRO、Atlas Computing、Getulio Vargas Foundation、ETH Zürich
- Steering Committee: Barrett, Chaudhuri, Grundy, Kohli, Montesi, de Moura（Rademaker / Yingchareonthawornchai は共同執筆者だが Steering に含まれない）

#### Abstract 原文（翻訳前）

> "CSLib is an open-source framework for proving computer-science-related theorems and writing formally verified code in the Lean proof assistant. It aims to be for CS what Mathlib is for mathematics. By vastly enhancing CS knowledge in Lean, CSLib enables broad use in education/research and facilitates engineering of large-scale verified systems."

agent-manifesto 翻訳: 「CS にとっての Mathlib」を自認する野心。新基盤の agent-spec-lib が成立するには、agent-manifesto が「**Research Process Governance（研究プロセス統治論）にとっての Mathlib**」を担う必要がある、という座標が得られる。

#### モチベーション（Mathlib の限界と CS 空白）

- 「Mathlib は数学で成功したが、CS 理論・実務における universal repository は今日まで存在しなかった」
- 実証的な参照: **seL4 は 20 人年以上・480,000 行の Isabelle** という法外コスト — 現場に展開可能な規模では機能していない
- ゆえに「一貫したフレームワーク」として CS 領域を整備し、教育・研究・実運用の 3 者に同時提供する

agent-manifesto 翻訳: seL4 の 480,000 行基準は、新基盤が「Lean で公理系 + 証明」と名乗るときに避けるべき anti-pattern。**D4（フェーズ順序）の原則**と組み合わせ、新基盤は「最小公理 + 強い tactic + hammer」路線を選ぶべき（後述 Section 3）。

#### 2 本柱アーキテクチャ（論文 Section 2）

**Pillar 1 — 形式化 CS 知識**:

- 計算モデル: λ-calculus、resource-bounded Turing 機械、deterministic / nondeterministic / probabilistic / quantum computation
- 仕様記法: temporal logic、Hoare logic、separation logic、linear logic
- アルゴリズム・データ構造

**Pillar 2 — 日常コードの推論基盤（= Boole）**:

- 「pseudocode のように見え、人間に読める IVL」
- Strata フレームワーク（deep embedding）と Loom（shallow embedding）を統合
- `#prove_vcs` コマンドで Lean ゴールを生成し、SMT ハンマーで自動消化

#### 論文に現れる具体的な formal object（= 新基盤が直接再利用できる候補）

- **LTS（Labelled Transition System）と bisimulation の定義**: CSLib.Foundations.Semantics.LTS に配置、Christopher Henson と Fabrizio Montesi による "Spine" 論文（arXiv:2602.15078, Section 1.4 参照）で扱い方詳述
- **Merge Sort と時間複雑度 n·log₂ n の上界定理**: CSLib.Algorithms 配下、後述の TimeM モナドを複雑性追跡に使用
- **TimeM モナド**: `TimeM α` は「計算結果 α + 時間コスト」のペア、bind で合成時コストを加算。**新基盤の V1-V7 メトリクスを Lean 型として埋め込むときの直接の雛形**
- **HML（Hennessy-Milner Logic）**: 別論文 arXiv:2602.15409 で CSLib.Logics.HML として詳述（表明論理、bisimulation との対応）

#### Boole / SMT hammer 記述

- 図 6 の `#prove_vcs` コマンド例、図 7 の生成ゴール実例
- `lean-smt` を経由して cvc5/Z3 に VC を送出
- 「various hammers」（CSLib 論文 Section 2.2）— 執筆時点で LeanHammer、Duper、Lean-Auto が射程
- Boole は「**Boogie を Lean 4 上でネイティブ実装**」するために、IVL の VCG（verification condition generator）を Lean 側で deep embed し、SMT-LIB の subset に対して Lean 側で semantics を証明する構造を取る（論文 Section 2.2 + Section 1.3 参照）

#### コミュニティ・教育

- Lean Zulip の CSLib チャンネル（active）
- 「AI 生成コードは人間レビューで排除」するレビュー方針を明記（CONTRIBUTING.md との整合）
- 2026 年目標: 学部アルゴリズムコース相当 + 計算論主要モデル
- 2027 年目標: complexity theory、concurrency、secure compilation、randomized / quantum algorithms、そして「少なくとも 1 つの substantial real-world system の end-to-end 検証」

#### 論文で言及されている重要な参考文献（agent-manifesto にとって重要な系譜）

| No. | 文献 | 新基盤への含意 |
|-----|------|--------------|
| [18] | Hubert et al. AlphaProof 2025 | AI 証明能力の実証 — G2 既往サーベイと繋がる |
| [22] | Klein et al. seL4 2009 | 「汚染コスト」のベースライン — 新基盤の適正規模の根拠 |
| [27] | Leino Boogie 2 2008 | Boole の設計祖先 — 新基盤 IVL 化する場合の jumping point |
| [31] | de Moura & Ullrich Lean 4 2021 | 基盤定義 |
| [41] | Mathlib 2019 | 設計 rolemodel |

---

### 1.3 CSLib GitHub リポジトリ（leanprover/cslib）— 実装規模と運用

**1 次情報 URL**: https://github.com/leanprover/cslib（本体）, https://github.com/leanprover/cslib/blob/main/Cslib.lean（ルート）, https://github.com/leanprover/cslib/blob/main/CONTRIBUTING.md
**最終取得**: 2026-04-17（main ブランチ、Reservoir 統計は 2026-03-29 時点）

#### リポジトリ統計（定量）

| 指標 | 値 | 出典 |
|------|------|------|
| Stars | 491（Reservoir 値は 460 と微差、GitHub 直値優先） | github.com/leanprover/cslib |
| Forks | 121 | 同上 |
| Commits（main） | 436 | 同上 |
| Open Issues | 32 | 同上 |
| Open PRs | 55 | 同上 |
| Releases | 19（最新 v4.29.0-rc6、公式リリースは v4.29.0 が 2026-03-31） | Reservoir + GitHub Releases |
| Lean toolchain 対応範囲 | v4.25.1 〜 v4.29.0-rc6 | Reservoir |
| License | Apache-2.0 | GitHub |
| Dependents（他 Lean パッケージからの依存） | 3 | Reservoir |

#### ルートモジュール（Cslib.lean）— 129 行 / 約 100 public import

確認できた主要モジュール階層（網羅ではないが agent-manifesto 転用の観点で重要な束）:

```
Cslib/
├── Algorithms/
│   └── Lean/            # MergeSort, TimeM
├── Computability/
│   ├── Automata/        # DA, NA, EpsilonNA, Acceptors
│   ├── Languages/       # Regular, Omega-Regular, Congruences
│   ├── Machines/        # Single Tape Turing
│   └── URM/             # Unlimited Register Machine
├── Crypto/
│   └── Protocols/       # Perfect Secrecy, One-Time Pad
├── Foundations/
│   ├── Data/            # BiTape, StackTape, OmegaSequence
│   ├── Semantics/       # LTS, FLTS
│   ├── Logic/           # Inference Systems
│   └── Syntax/          # Congruence, Substitution
├── Languages/
│   ├── CCS/             # Calculus of Communicating Systems
│   ├── CombinatoryLogic/
│   └── LambdaCalculus/  # STLC, Fsub, Untyped
└── Logics/
    ├── HML/             # Hennessy-Milner Logic
    └── LinearLogic/     # CLL, Cut Elimination
```

#### 依存関係（lakefile.toml）

- Mathlib に依存（CSLib Spine 論文で明示 — big-O / 確率論 / 線形代数を再利用）
- `require cslib from git "https://github.com/leanprover/cslib" @ "main"` で他プロジェクトから使用可能 — つまり **新基盤が Cslib 依存パッケージとして agent-spec-lib を配置できる形式的経路が既に確立している**

#### CONTRIBUTING.md の要点

1. **レビュープロセス**: 最低 1 人の関連メンテナー承認、メジャー開発は事前 Zulip 協議
2. **Naming**: ドメイン適合の変数名を自由使用（例: LTS では `State`、`μ`）— Mathlib より柔軟
3. **Docstring**: 全 definition / theorem の文書化必須、外部出典を明記
4. **テスト**:
   - `lake test`（CslibTests/ を走らせる）
   - `lake exe checkInitImports`（Cslib.Init の import 検証）
   - `lake lint`（環境リンター）
   - `lake exe lint-style`（テキストリンター）
5. **AI 生成コード**: 「生成/仕様洗練/予想の証明に生成 AI は有用」だが「貢献はレビュー可能・保守可能であるべき」と明記 — 新基盤 P2（検証分離）と実質同義
6. **PR タイトル**: `feat` / `fix` / `doc` / `style` / `refactor` / `test` / `chore` / `perf` で始まる必須 — agent-manifesto P3 の互換性分類（conservative extension / compatible change / breaking change）と相補的に併用可能
7. **新モジュール追加**: `lake exe mk_all --module` で全ファイル import 化、`lake shake` で最小 import 最適化
8. **Mathlib スタイル準拠**: 概ね Mathlib の「コーディング・文書スタイル」に従うが、notation は再利用性を考慮し「型クラス化 or 局所スコープ」

#### Boole の実在位置

- `cslib/Cslib/Languages/Boole`（Boole-sandbox ブランチ、まだ main にマージされていない） — プロトタイピング段階
- 同じく `abdoo8080/Strata:boole` ブランチに Strata dialect として定義 — Abdalrhman Mohamed (Abdoo) の work
- 確認できたディレクトリ: `MergeSort/`、`NumericalAnalysis/`、`examples/`、`README.md`
- `StrataVerify Examples/SimpleProc.boogie.st` で「解析 → 型チェック → VCG → SMT」を一貫実行

#### 観察 — agent-manifesto への転用可能性（暫定）

- **コーディングスタイル**: agent-manifesto のコードベース（lean-formalization/Manifest/、55 axioms / 1670 theorems — 2026-04-17 実測）は既に Mathlib 依存。CSLib スタイルに移すコスト低
- **テストインフラ**: `lake test` / `lake lint` は agent-manifesto の tests/test-all.sh と二重管理になっているが、CSLib パターンに寄せれば単一化可能
- **PR 接頭辞**: 新基盤の commit 互換性分類と組合せ、`feat(conservative extension): ...` 形式にできる

---

### 1.4 CSLib Spine 論文（arXiv:2602.15078）— spine アーキテクチャと再利用パターン

**1 次情報 URL**: https://arxiv.org/html/2602.15078
**タイトル**: *Computer Science as Infrastructure: the Spine of the Lean Computer Science Library (CSLib)*
**著者**: Christopher Henson (Drexel University), Fabrizio Montesi (University of Southern Denmark)

#### Spine（背骨）の構成要素

1. **Abstract Reduction Systems + LTS を type class で統合**:
   - 「前者は二項関係、後者は transition label で parametrise された関係」
   - `ReductionSystem` / `LTS` type class から multistep reduction、reachable states、image operation が自動導出される
2. **HasContext / Congruence type class**: 言語理論の再帰パターン（compositional equivalence 等）を共通化
3. **HasFresh class**: computable fresh variable 生成（locally nameless 実装で必須）
4. **Mathlib 基盤上での runtime 再利用**: linters、テスト、CI、`grind` tactic

#### Spine 上で成立する major development

- Behavioral equivalences: bisimilarity、similarity、trace equivalence
- CCS（Calculus of Communicating Systems）
- λ-calculi（polymorphism、subtyping）— locally nameless 表現
- 将来計画: π-calculus、nominal transition systems、時間複雑度付きアルゴリズム、binding infrastructure の自動生成

agent-manifesto 翻訳: 新基盤の公理系（T1-T8、P1-P6、D1-D18）を Lean 化するときに、**「研究プロセスの spine」として LTS 相当の `ResearchEvolutionStep` 型クラス**を先に定義し、そこから T3（自己適用）、D13（影響波及）、P3（学習統治）を projection / specialization として導出する設計が自然（Section 3 詳述）。

---

### 1.5 Boole フレームワーク（cslib Boole-sandbox + Strata:boole）— SMT ハンマー連携の具体像

**1 次情報 URL**:
- https://github.com/leanprover/cslib/tree/Boole-sandbox/Cslib/Languages/Boole
- https://github.com/abdoo8080/Strata/tree/boole

#### アーキテクチャ（論文 + リポジトリから再構成）

```
[Lean 4 specification + Boole program in #strata macro]
        ↓
[Strata core dialect parser (Lean 4 metaprogramming)]
        ↓
[Boole dialect AST: Expr / Stmt / Proc (Boogie 系)]
        ↓  verification condition generator (VCG)
[Lean Prop goals]
        ↓  compile → SMT-LIB subset
[SMT-LIB subset with Lean-verified semantics]
        ↓
[cvc5 / Z3 / veriT] ─ proof ─→ [lean-smt reconstruction] ─→ [Lean kernel check]
```

#### 重要ポイント

- **Loom (shallow) + Strata (deep) の統合**: Loom は「Lean の型と直接 embed」、Strata は「独立 AST で semantics を明示」。Boole は両者の良いとこ取り
- **VC を SMT-LIB subset にコンパイル**: subset の semantics を Lean で定義、SMT ソルバの答えを Lean Prop に lift
- **SMT solver**: 論文は cvc5 / Z3 を明記（lean-smt は両対応、cvc5 は veriT より高性能と報告）
- **開発ステージ**: Boole-sandbox ブランチ名が示す通りまだ実験段階（2026-04 時点で main 未マージ）

#### Boole が支えるユースケース（CSLib 論文 Figure 7 等から）

- 「pseudocode のように見える IVL にスペックを書く → `#prove_vcs` で Lean ゴール生成 → SMT で自動」
- 対象: 命令型プログラムの検証（sort、numerical analysis 等）
- 長期目標: 「real programming languages（C、Rust 等）の semantics を Lean で形式化 → Boole に翻訳 → Boole の検証ツールで verify」という翻訳ワークフロー

---

### 1.6 周辺 SMT ハンマー生態系（Boole が依拠するスタック）

**1 次情報 URL**:
- https://arxiv.org/html/2505.15796v1（lean-smt）
- https://arxiv.org/pdf/2505.14929（Lean-Auto）
- https://arxiv.org/html/2506.07477v1（LeanHammer / Premise Selection）
- https://github.com/leanprover-community/lean-auto
- https://reservoir.lean-lang.org/@JOSHCLUNE/Hammer

#### lean-smt（2025-05）

- Lean ゴールを SMT-LIB に変換、SMT 証明を Lean 証明に再構成
- 比較対象: Sledgehammer + veriT、Duper
- **主要結果**: Sledgehammer ベンチマークで「cvc5 > veriT」の差により、lean-smt が優位
- Mathlib 評価は「premise selection 機構が Lean になく false positive が多い」ため除外 — ここが LeanHammer 登場理由

#### Lean-Auto（2025-05）

- Lean 4 と ATP（Z3、CVC5）のインターフェース、premise selection + translation + proof reconstruction の 3 段構成
- 「Lean-auto + Duper」は Mathlib ベースの benchmark で **36.6%** を解き、前記ベストを 5.0pp 上回る

#### LeanHammer（2026-06）

- **初の end-to-end domain-general Lean hammer**: premise selection（ニューラル）+ Aesop + Lean-auto + Duper
- Mathlib 500 定理 test set: cumulative 33.3% 証明、Recall@32 = 72.7%
- **ReProver 比 150% 改善**、パラメータ数は小さい（82M vs 218M）
- miniCTX-v2 generalization: Mathlib 73.5% / miniCTX 79.4% 相対維持（Carleson、ConNF、Foundation dataset）
- Runtime: premise selection ~1s、pipeline 平均 <10s/theorem
- 誤り分析: 21.7% が Lean-auto translation 失敗、43.6% が Zipperposition で証明不能 — **これらが Boole の改善余地**

agent-manifesto への数値感覚の較正:

- 新基盤公理系（50+ axioms、数百 theorems）の規模は miniCTX-v2 の「Foundation dataset」と類似オーダー
- LeanHammer の 79.4% 相対維持は「未知の domain 公理系にも即戦力で効く」ことを示唆
- ただし **21.7% + 43.6% = 65.3%** が hammer 不能領域に落ちるため、**新基盤でも「手動証明 + typed hole + 人間レビュー」の併用は不可避**（G3 の CLEVER 知見と整合）

---

## Section 2: 横断的発見

### 2.1 speclib 実現パターン — 3 層設計が成立している

論文・spine 論文・リポジトリ構造を総合すると、CSLib は以下 3 層で speclib を実現している:

| 層 | 役割 | 具体例 | 新基盤対応 |
|---|---|---|---|
| L1. Spine（型クラス層） | 領域横断の再利用構造 | ReductionSystem、LTS、HasContext、HasFresh | `ResearchEvolutionStep`、`VerificationBoundary`、`SafetyConstraint` 型クラス |
| L2. Theory（固有領域） | 各 CS 分野の形式化 | Computability、Logics.LinearLogic、Crypto | Manifest の T1-T8、P1-P6、D1-D18 を各サブディレクトリに分解 |
| L3. Tooling（検証自動化） | Boole、lean-smt、hammer | `#prove_vcs`、`#strata`、`grind` | `/verify` skill 経由で hammer 呼び出し、既存 `tests/test-all.sh` と併走 |

**発見 1**: speclib は単なる「定義カタログ」ではなく **「型クラス spine + 領域理論 + 検証 tooling」の 3 点セット**。Atlas の抽象提案を CSLib は spine 論文で具体化した。新基盤が speclib を名乗るには同じ 3 層を揃える必要がある。

**発見 2**: Cslib.lean の 100+ import は「グループ化された universe export」として機能し、下流プロジェクトは `import Cslib` 一発で全機能にアクセスできる。agent-spec-lib も同じ形式（`import AgentSpec` が一元入口）を採れば、新基盤 skill 群（/research、/verify、/trace）からの使いやすさが確保できる。

### 2.2 Mathlib との対比 — 3 つの設計差分

| 側面 | Mathlib | CSLib | 新基盤への示唆 |
|------|---------|-------|-------------|
| Naming | 厳格な数学命名（`Nat.add_comm`） | ドメイン自由（`State`、`μ`） | 研究プロセス語彙（`Hypothesis`、`Axiom`、`Evolution`）をそのまま使える |
| Notation | 局所スコープ中心 | 型クラス化 + 局所スコープ | `T1` `P2` 等の short name を局所 notation 化可能 |
| 依存方向 | 独立（自己完結） | Mathlib 依存 | 新基盤は Mathlib + CSLib に依存する 2 段下流に立つ |
| AI レビュー | 禁止気味 | 「生成 AI 使用可、ただしレビュー可能性必須」 | agent-manifesto と自然に整合 |
| リリース頻度 | 高速（toolchain 追随） | v4.25.1〜v4.29.0-rc6 追随（積極的） | lakefile の toolchain pin 方針は CSLib に合わせるのが安全 |

**発見 3**: CSLib の命名自由度は、agent-manifesto のように **「日本語 + 英語記号 + 独自公理 ID（T1、D4 等）」混在のドメイン語彙**を Lean 化するときに決定的に有利。Mathlib 方針だけだと語彙表現が痩せる。

### 2.3 SMT 統合戦略 — 「hammer が効かない 65%」への対策

CSLib + Boole + LeanHammer の組合せでも、hammer 不能領域は 60% 前後残る（Section 1.6）。CSLib が採る対処:

1. **Spine 型クラスで自動導出を最大化**: multistep、image、reachable 等は type class で一度定義すれば無数の実例に適用 — 手動証明を書く必要がない
2. **Boole を「pseudocode に近い IVL」として設計**: 人間が読める IVL は LLM プロンプトにも優しく、証明困難時の人間介入が容易
3. **TimeM 等の embedded monad**: 複雑性を値に埋め込むことで、型レベルで性質を強制 — 証明を書かずに済む

**発見 4**: 新基盤の agent-spec-lib も、V1-V7 メトリクスや P3 学習ライフサイクル（観察→仮説化→検証→統合→退役）を **TimeM 様の monad / indexed type** に埋め込めれば、証明負荷を大幅に減らせる。

### 2.4 「speclib は静的カタログではなく動的ライブラリ」という観察

CSLib のリリースペース（v4.25.1 → v4.29.0-rc6 を 19 リリースで追随）は、**「公理・定理を固定資産として蓄積する」**のではなく、**「Lean 4 の言語進化と同速で追従・リファクタする」**ことを前提にしている。これは agent-manifesto の T2（永続構造）が、静的保存ではなく「世代を越えて改善し続ける」という最上位使命と整合する。

### 2.5 CSLib が未カバーの speclib 領域（新基盤のブルーオーシャン）

Atlas speclib 構想との差分:

| 領域 | Atlas 想定 | CSLib 現状 | 新基盤の機会 |
|------|-----------|-----------|-------------|
| 暗号アルゴリズム仕様 | coverage 想定 | Crypto / Perfect Secrecy のみ | 新基盤対象外（G1 Cedar 系が担当） |
| セキュリティ仕様（認可） | Cedar 系、X3DH | ほぼ無し | 新基盤対象外（G1 担当） |
| **研究プロセス安全性** | 言及なし | **無し** | **新基盤の独占領域** |
| **Agent governance 公理系** | 言及なし | **無し** | **新基盤の独占領域** |
| 運用ツール仕様（CI、hook） | 言及なし | 無し | 新基盤で一部カバー可能 |
| 複雑性解析 | 言及なし | TimeM で雛形 | 新基盤 V5（コスト）に転用 |

**発見 5**: 「Agent の研究プロセス・governance」は CSLib にも Atlas にも存在しない **完全な空白**。新基盤が agent-spec-lib を最初の domain-specific instance として打ち立てる正当性が、実在する先行ライブラリの欠落から演繹的に示せる。

---

## Section 3: 新基盤 Phase 0 への適用案 — agent-spec-lib の具体設計

### 3.1 戦略判断: 「CSLib への貢献」vs「独立プロジェクト」

**結論**: **CSLib に依存する独立サブライブラリ `agent-spec-lib`** として立ち上げる（2 段下流 Lean パッケージ）。理由 3 点:

1. **スコープの非重複**: agent-manifesto の研究プロセス公理系は CSLib のカバー対象（計算理論・オートマトン・λ-calc 等）と被らない。直接 PR しても `Cslib/Research/*` のような「別階層」になり、CSLib メンテナーのレビュー負荷が増える割に相互益が薄い
2. **リリース独立性**: CSLib は Lean toolchain 追随で高頻度リリース。新基盤は T2 永続構造として「破壊的変更のない成長」を重視するため、リリース緊密結合は望ましくない
3. **ライセンス・ガバナンス独立**: agent-manifesto は Apache-2.0（CSLib と同じ）のため相互利用は容易だが、「公理系の最終決定権」は新基盤プロジェクト側に残したい（T6 人間権威、P3 学習統治）

ただし **Cslib/Foundations/Semantics/LTS や Cslib/Foundations/Logic/InferenceSystems は直接依存**して再利用する。これにより「新基盤だけのためにゼロから LTS を再発明」する無駄を避ける。

### 3.2 agent-spec-lib のディレクトリ構造案

CSLib Spine 論文の 3 層設計をそのまま踏襲:

```
agent-spec-lib/
├── AgentSpec.lean                        # ルート import 束（Cslib.lean 模倣）
├── AgentSpec/
│   ├── Spine/                            # 型クラス層（L1）
│   │   ├── EvolutionStep.lean           # ResearchEvolutionStep type class（LTS 類似）
│   │   ├── SafetyConstraint.lean        # L1 安全境界の type class
│   │   ├── VerificationBoundary.lean    # P2 検証分離の type class
│   │   ├── LearningCycle.lean           # P3 観察→仮説→検証→統合→退役 の monad
│   │   └── Observable.lean              # P4 可観測性の type class（V1-V7 metric ごとに instance）
│   ├── Manifest/                         # 領域理論層（L2）— 既存 Manifest/ を移植
│   │   ├── Temporality/                 # T1-T8
│   │   ├── Principles/                  # P1-P6
│   │   ├── Limits/                      # L1-L6
│   │   ├── Validators/                  # V1-V7
│   │   └── Design/                      # D1-D18
│   ├── Process/                          # 研究プロセス具体化層
│   │   ├── Hypothesis.lean              # 仮説 first-class（G3 の P0 gap 対応）
│   │   ├── Failure.lean                 # 失敗 first-class（G3 の P0 gap 対応）
│   │   ├── Evolution.lean               # skill 進化の axiomatic model
│   │   └── HandoffChain.lean            # T1 連鎖 + T2 構造
│   └── Tooling/                          # 検証自動化層（L3）
│       ├── HammerBridge.lean            # lean-smt / LeanHammer 経由 VC 送出
│       ├── VcForSkill.lean              # skill 仕様の VCG
│       └── CoverageCheck.lean           # trace skill の Lean 証明化
├── AgentSpecTests/                       # CslibTests 模倣
├── lakefile.toml                         # require Cslib, require Mathlib
├── lean-toolchain                        # Cslib と同じ v4.29.0 pin
├── CONTRIBUTING.md                       # CSLib 方針 + 互換性分類追加
└── ORGANISATION.md                       # 統治文書
```

agent-manifesto の既存 `lean-formalization/Manifest/` は Section 3.3 の移植戦略に従って `AgentSpec/Manifest/` へ段階的に移す。

### 3.3 公理系（T1-T8、P1-P6、D1-D18）を扱う Boole hammer パターン

Boole は「命令型コードに対する VC」を SMT に送る設計だが、agent-manifesto の公理系は **宣言的な Prop** が中心。したがって「Boole そのもの」より **LeanHammer + lean-smt を直接使う** のが素直。ただし Boole の発想を応用して、skill 仕様の VC 生成に以下の pattern を採る:

#### パターン A: skill ステップの Hoare-style 仕様

```lean
-- /research skill の 1 ステップを Hoare triple として書く
theorem research_step_sound :
  ∀ (pre : ResearchState) (step : ResearchEvolutionStep),
    precond pre →
    postcond (apply step pre) := by
  intro pre step h
  -- ここで LeanHammer / lean-smt が効く
  grind  -- CSLib の推奨 tactic
```

#### パターン B: 公理の relative consistency を hammer で自動化

```lean
-- T1（一時性）と P3（学習統治）が独立であることの hammer 証明
theorem T1_independent_of_P3 : ¬ (T1_axiom ↔ P3_axiom) := by
  -- 反例モデルを構築
  hammer  -- LeanHammer が premise selection + Duper で自動
```

**期待成功率**: LeanHammer の Mathlib 33.3%、miniCTX 相対 79.4% から推定すると、agent-manifesto 公理系で **20-30% 前後** は自動化可能（公理系の規模・慣れていない領域であることを割引）。残りは手動 + typed hole + 人間レビュー。

#### パターン C: Boole を「研究プロセスの IVL」として将来拡張

現時点では不要だが、将来 agent-manifesto が「研究プロセスの手続き的記述（skill 実行シーケンス）」を形式化するときに、Boole 流の IVL を導入する道は開かれている:

```
#strata (boole-like DSL for research workflow)
procedure run_research(hypothesis h) {
  requires { isWellFormed(h) };
  ensures { exists (v : Verdict), Verified(h, v) };
  ...
}
#prove_vcs  -- hammer が VC を自動消化
```

これは G3 1.6 の Atlas 「Translate ワークフロー」と同型で、既存 skill 群を IVL として再記述する場合のロードマップになる。

### 3.4 「研究プロセス公理」を新しいサブライブラリとして追加する戦略

CSLib の Spine 論文の示唆通り、**研究プロセスにおける LTS 類似物を最初に spine 化する**のが鍵。

#### ステップ 1: ResearchEvolutionStep type class を定義

```lean
class ResearchEvolutionStep (S : Type u) where
  transition : S → S → Prop
  hypothesis : S → Option Hypothesis
  verdict : S → Option Verdict
  observation : S → Observable  -- V1-V7 tuple
```

これは CSLib の `LTS` を「研究プロセス」に specialize したもの。

#### ステップ 2: P3 学習サイクルを indexed monad として埋め込む

```lean
inductive LearningStage
  | Observation
  | Hypothesis
  | Verification
  | Integration
  | Retirement

def LearningM (s : LearningStage) (α : Type u) : Type u := ...
-- stage transition が型レベルで強制される
```

CSLib の TimeM モナドの類推。V1-V7 メトリクスを値として持ち歩き、bind でメトリクス変化を合成する。

#### ステップ 3: Mathlib / CSLib の既存結果を再利用

- `Cslib.Foundations.Semantics.LTS` から bisimulation / trace equivalence を import し、「2 つの skill が観察可能性質において等価」を bisimilarity として形式化
- `Cslib.Foundations.Logic.InferenceSystem` を P3 学習ライフサイクルの健全性証明に流用

#### ステップ 4: Tooling 層で hammer 呼び出しを標準化

```lean
-- /verify skill 内部で呼ばれる tactic bundle
macro "agent_verify" : tactic => `(tactic| first | grind | hammer | sorry)
```

`sorry` を残して CI で検出 → 人間レビューに回す、という P2 / T6 準拠ワークフロー。

### 3.5 Phase 0 ロードマップ（6-8 週間想定）

| Week | 作業 | 完了基準 |
|------|------|---------|
| 1 | agent-spec-lib リポジトリ初期化、`lakefile.toml` で Cslib 依存確立、lean-toolchain pin | `lake build` が通る |
| 2-3 | Spine 層（EvolutionStep、SafetyConstraint、LearningCycle、Observable）定義、Cslib.LTS 再利用確認 | 4 type class すべてに dummy instance あり |
| 3-4 | Manifest 移植: T1-T8 + P1-P6 を `AgentSpec/Manifest/` 配下に整理、docstring 強化 | 既存 55 axioms すべて import 可能 |
| 4-5 | Process 層: Hypothesis、Failure、Evolution、HandoffChain の inductive 型定義 | `.claude/skills/handoff` の state machine が型として表現される |
| 5-6 | Tooling 層: LeanHammer bridge、`agent_verify` tactic、`VcForSkill` VCG | 少なくとも 5 定理を hammer で自動証明 |
| 6-7 | CI: CSLib スタイルの `lake test` / `lake lint` / `lake exe checkInitImports` 導入 | GitHub Actions が green |
| 7-8 | Verification: 既存 1670 theorems のうち代表 100+ を新構造下で再証明、CLEVER 風自己評価 10-20 サンプル | 再証明率 > 80%、自己評価 > 60% |

### 3.6 CSLib への upstream 貢献機会（副次的）

独立サブライブラリ路線を採っても、以下は CSLib 本体への PR が望ましい:

1. **spine 層で発見した改善**（HasFresh の高速化、LTS の追加 lemma）— CSLib コミュニティで共有
2. **docstring 翻訳**（agent-manifesto は日英併記に実績） — i18n の先行事例として
3. **AI 生成コードのレビュー指針**（P2、P3 実運用知見） — CONTRIBUTING.md 強化に貢献

---

## Section 4: 限界と未解決問題

### 4.1 CSLib が含まない領域（新基盤が自力で埋める必要あり）

1. **「研究プロセスの形式化」そのもの**: LTS / CCS は抽象機械の formalism だが、「研究仮説 → 実験 → 論文」のような非線形ワークフローの公理化は未踏。CSLib spine 論文の π-calculus 拡張予定が最も近いが、まだ数年先
2. **人間介入の first-class 表現**: CSLib は全自動検証志向、人間レビューは CI / PR レベル。agent-manifesto の T6（人間権威）を Lean 型として埋め込むパターンは未存在
3. **Failure / Hypothesis の first-class 化**: G3 P0 gap で指摘された「失敗と仮説の inductive type」は、CSLib にも存在しない — **新基盤オリジナル貢献の余地**
4. **時間軸の扱い**: TimeM は「計算時間」のモナドだが、「研究の時系列（T1 連鎖、P3 退役）」を扱うモナドは存在しない

### 4.2 Boole の現状の限界

1. **Boole-sandbox ブランチは未マージ**（2026-04 時点） — production 品質ではない
2. **対応言語は命令型中心** — 宣言的公理系には直接フィットしない
3. **SMT 不能領域 60%+** — LeanHammer の数字から推定、手動証明は必須
4. **Strata 依存** — abdoo8080/Strata の独自実装、長期メンテナンス保証は未確立

### 4.3 Atlas speclib 構想との未解決ギャップ

- Atlas の X3DH 「specification IDE」構想は CSLib に直接対応物なし — 仕様書と形式コードの往復インターフェースは別途必要
- Atlas の「informal-formal mapping annotations」は CSLib のコメント規約では不十分 — Verso block や Literate Lean が候補

### 4.4 定量的に不明な残項目

| 項目 | 現状 | 埋め方 |
|------|------|------|
| CSLib の総行数 | 論文・サイトとも非公表 | `git clone && cloc` で直接計測（本サーベイ範囲外） |
| CSLib の総定理数 | 非公表 | `grep -r "^theorem " Cslib/` で直接計測（agent-manifesto の build command と同じ） |
| Boole の成熟度スコア | 非公表 | Boole-sandbox → main マージのタイミングを watch |
| CSLib 貢献者数 | Reservoir / GitHub で今後確認 | GitHub Insights で contributors タブ確認 |

### 4.5 ワークフロー上のリスク

- **依存 pinning の事故**: Cslib + Mathlib + Lean toolchain の 3 重依存で破壊的変更が発生したときの agent-spec-lib リバウンドコスト
- **hammer の不再現性**: LeanHammer のニューラル premise selection は非決定的要素あり、CI で flaky になり得る（Zulip の「reproducible SAT/SMT reasoning」topic で議論中）

---

## Section 5: 出典 URL リスト

### 1 次情報（WebFetch 取得済）

1. CSLib 公式サイト — https://cslib.io
2. CSLib 論文 HTML — https://arxiv.org/html/2602.04846v1
3. CSLib 論文 abstract — https://arxiv.org/abs/2602.04846
4. CSLib 論文 PDF — https://arxiv.org/pdf/2602.04846
5. CSLib GitHub リポジトリ — https://github.com/leanprover/cslib
6. CSLib ルートモジュール（Cslib.lean） — https://github.com/leanprover/cslib/blob/main/Cslib.lean
7. CSLib CONTRIBUTING.md — https://github.com/leanprover/cslib/blob/main/CONTRIBUTING.md
8. CSLib Reservoir ページ — https://reservoir.lean-lang.org/@leanprover/cslib
9. CSLib Spine 論文 — https://arxiv.org/html/2602.15078
10. HML in CSLib 論文（参照のみ） — https://arxiv.org/abs/2602.15409
11. Boole sandbox ブランチ — https://github.com/leanprover/cslib/tree/Boole-sandbox/Cslib/Languages/Boole
12. Strata boole ブランチ — https://github.com/abdoo8080/Strata/tree/boole

### 2 次情報・周辺生態系

13. lean-smt 論文 HTML — https://arxiv.org/html/2505.15796v1
14. lean-smt 論文 PDF — https://arxiv.org/pdf/2505.15796
15. Lean-Auto 論文 HTML — https://arxiv.org/html/2505.14929
16. Lean-Auto 論文 PDF — https://arxiv.org/pdf/2505.14929
17. Lean-Auto GitHub — https://github.com/leanprover-community/lean-auto
18. LeanHammer / Premise Selection 論文 — https://arxiv.org/html/2506.07477v1
19. Hammer Reservoir — https://reservoir.lean-lang.org/@JOSHCLUNE/Hammer
20. Boogie IVL プロジェクト — https://www.microsoft.com/en-us/research/project/boogie-an-intermediate-verification-language/
21. Lean Zulip — Duper トピック — https://leanprover-community.github.io/archive/stream/113488-general/topic/Duper.html
22. Lean Zulip — reproducible SAT/SMT — https://leanprover-community.github.io/archive/stream/270676-lean4/topic/reproducible.20SAT.2FSMT.20reasoning.html

### agent-manifesto 内部参照

23. G3 仕様生成サーベイ（相補的先行） — `docs/research/new-foundation-survey/07-lean4-applications/G3-spec-generation.md` Section 1.6（Atlas speclib）
24. G4 メタ視点サーベイ（相補的先行） — `docs/research/new-foundation-survey/07-lean4-applications/G4-meta-views.md` Section 1.1（AMO-Lean 等）
25. 全体 Synthesis — `docs/research/new-foundation-survey/00-synthesis.md` Rows 496-497（P0 gap: 仕様等価性 + speclib 必須性）
26. 基盤 Manifest — `/Users/nirarin/work/agent-manifesto/lean-formalization/Manifest/`（55 axioms、1670 theorems — 2026-04-17 実測）
27. 新基盤 Manifest — `/Users/nirarin/work/agent-manifesto-new-foundation/lean-formalization/Manifest/`（移植対象）

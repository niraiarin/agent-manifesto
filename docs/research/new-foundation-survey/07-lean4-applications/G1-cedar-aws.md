% G1: AWS Cedar における Lean 4 本番応用事例（精読サーベイ）
% 作成日: 2026-04-17
% 担当: G1（新基盤研究サーベイ・グループ G1）
% 対象: Lean 4 を本番システムへ応用した先行研究 5 リンクの 1 次情報精読
% 翻訳対象用語: T1（一時的インスタンス）, T2（永続構造）, P2（検証分離）, P3（学習統治）, P4（可観測性）, V1-V7（健全性指標）, D13（影響波及）

---

## Section 1: 各リンク先の精読ノート

### 1.1 lean-lang.org/use-cases/cedar/（Lean 公式 Cedar 紹介ページ）

**URL**: https://lean-lang.org/use-cases/cedar/

#### 目的・問題設定

Cedar は AWS のオープンソース認可ポリシー言語であり、その policy evaluator / authorizer / validator を Lean で形式モデル化し、本番 Rust 実装と並走させることで、認可システムの正しさ・セキュリティ性質を高度に保証することが目的。Cedar は IAM-like の細粒度アクセス制御のための DSL であり、誤った認可決定はセキュリティ違反に直結するため、TCB（trusted computing base）の検証が要件。

#### アーキテクチャ

「executable formal models in Lean alongside the production Rust implementation」という二系統並走モデル。Lean モデルは「mathematical documentation」として読みやすさを優先、Rust は最適化と実用性を優先。両者の振る舞い同値性は differential testing で保証。

#### 証明された性質

「critical correctness and security properties」が証明されたとあるが、本ページでは具体的な定理列挙なし（詳細は arxiv 論文に譲る）。3 コンポーネント（evaluator, authorizer, validator）を対象。

#### 検証戦略

「AWS generates millions of random inputs and verifies that both the Lean model and Rust implementation produce identical outputs」— 数百万件のランダム入力で Lean モデルと Rust 実装の出力を直接比較する **differential random testing (DRT)** が中核。

#### Lean モデルの規模

「approximately 10 times smaller than the production code」— 相対比のみ。絶対値は本ページでは未開示（詳細は arxiv 論文）。

#### 採用上の課題と解決

「Accessible to software engineers」「Writing models and proofs in Lean follows familiar programming paradigms」— Lean が（数学者だけでなく）ソフトウェアエンジニアにとってもアクセシブルであるとの主張。プログラミング言語としての設計を強調。

#### 公開リポジトリ・性能数値

- リポジトリ: `https://github.com/cedar-policy/cedar-spec`
- 性能: **Lean モデル 5 microseconds / Rust 7 microseconds** per test case（本ページの記述）。Lean が高速な理由は DRT を成立させる前提条件である（モデルが遅いと数百万件比較が回らない）。
- Lean バージョン・Mathlib 依存: 本ページでは未開示。

#### 新基盤への含意

- 「Lean モデル ≒ 仕様 ≒ 文書」という三位一体の役割は、agent-manifesto の **公理系（T2）** と完全に同型である。研究プロセスの記録もまた、Lean 文書を canonical source とし、Pipeline からの実行物（Issue 表示、トレース、バリデータ）を派生物として扱う、という設計を裏付ける。

---

### 1.2 arxiv 2407.01688v1（"Cedar: A New Language for Authorization"-related Lean VGD 論文）

**URL**: https://arxiv.org/html/2407.01688v1

これが本サーベイの最も定量データの濃い 1 次情報源。

#### 目的・問題設定

Cedar 認可エンジンは「TCB（trusted computing base）」の中核であり、誤りはセキュリティ事故に直結する。本論文は Cedar チームが採用した **Verification-Guided Development (VGD)** プロセスを提案し、その有効性を実測データで示す。重要な発見:

> 「While implementing the formal model and carrying out proofs of soundness of the Cedar policy validator, we found and fixed four bugs.」

> 「Constructing them helped us uncover and fix a non-termination bug in our definition of the Cedar validator, which would have been difficult to detect through testing.」

つまり **Lean 証明の構成行為そのものがバグ発見器として働いた**。これは agent-manifesto の P2（検証分離）の理論的根拠を強化する: 検証は単なる事後チェックではなく、仕様の精緻化プロセスを駆動する。

#### アーキテクチャ（VGD の二段構成）

**Stage 1**: Lean で simple, readable モデル + 機械化された性質証明
**Stage 2**: Rust で本番コード + DRT で Lean モデルとの行動同値性を経験的に検証

明示的に **却下された代替案**:
- **Lean → C 抽出（CompCert 流）**: 「require maintaining generated, unreadable C code with limited library support」
- **Rust 直接検証**: Aeneas, Kani, Prusti は「lack maturity for industrial-scale code」

採用結果:
> 「Using DRT and PBT we have so far found and fixed 21 bugs in various Cedar components.」

#### 証明された性質（7 つ）

1. **Forbid Trumps Permit**: forbid policy が満たされたら必ず deny
2. **Default Deny**: permit が満たされなければ deny
3. **Explicit Allow**: allow されたなら何らかの permit が満たされていた
4. **Order Independence**: ポリシー評価順序に依存しない
5. **Sound Slicing**: ポリシースライシング後も同じ決定が得られる
6. **Validation Soundness**: validator が受理したポリシーは type error を起こさない
7. **Termination**: Cedar の関数は必ず停止する

主定理（Forbid Trumps Permit）の Lean 文:

```lean
theorem forbid_trumps_permit (request : Request)
(entities : Entities) (policies : Policies) :
(∃ (policy : Policy),
policy ∈ policies ∧
policy.effect = forbid ∧
satisfied policy request entities) →
(isAuthorized request entities policies).decision = deny
```

Validation Soundness は「the most involved proof we have done so far」で、proof:model 比 = **3.4:1** 全体（後述 Table 1）。

#### 検証戦略（DRT の詳細）

cargo-fuzz を fuzz harness として使用。「randomly generate millions of inputs—access requests, entities, and policies—and send them to both the Lean model and the corresponding Rust production implementation」。

**Type-directed input generation**:
> 「we first generate a schema, then an entity store that conforms to the schema, and then policies and requests that access those entities in conformance with the schema」

これにより well-typed 入力で core logic を深く探索。同時に non-typed generator も併用してエラー処理経路もカバー。

**Properties Tested（Table 2 抜粋）**:

| Property | Generator | Bugs Found |
|---|---|---|
| ABAC authorizer parity | Type-directed ABAC | 6 |
| RBAC authorizer parity | Multiple RBAC policies | 0 |
| Validator parity | Type-directed ABAC | 4 |
| Parser roundtrip | ABAC | 6 |
| Formatter roundtrip | ABAC | 2 |
| Validation soundness | Type-directed ABAC | 3 |

合計 **21 件**のバグが DRT/PBT で発見・修正された。

#### Lean モデル規模（Table 1）

| Component | Lean Model (LOC) | Lean Proofs (LOC) | Rust Prod (LOC) | Rust Tests (LOC) | Rust Other (LOC) |
|---|---|---|---|---|---|
| Custom sets/maps | 244 | 681 | n/a | n/a | n/a |
| Parser | n/a | n/a | 4,114 | 3,599 | n/a |
| Evaluator/Authorizer | 897 | 347 | 4,877 | 7,061 | n/a |
| Validator | 532 | 4,686 | 6,702 | 9,798 | n/a |
| **Total** | **1,673** | **5,714** | **15,693** | **20,458** | **31,391** |

重要観察:
- **Lean Model : Rust Prod ≈ 1 : 9.4**（順序通り 10 倍小さい）
- **Lean Proof : Lean Model ≈ 3.4 : 1**（証明は本体の 3 倍以上）
- **Validator** は Proof:Model 比が **8.8 : 1** で突出（532 LOC モデル、4686 LOC 証明）— Validation Soundness の難易度を示す

#### 性能・テスト規模

- 全証明検証 + モデル実行用コンパイル: **約 3 分（185 秒）**
- Lean モデル実行: **median 6 microseconds**（authorizer）
- Rust 実装: **median 10 microseconds**（authorizer）
- Fuzzing インフラ: Amazon ECS、4096 CPU units（4 vCPUs）+ 8GB memory
- Fuzzing 実行時間: **6 hours daily** per target
- カバレッジ: 6 時間で block coverage が saturate

#### 採用上の課題

- **Well-foundedness 要求**: Lean は再帰関数の停止性を要求するため、循環不変条件を持つ標準 Set/Map は使用不可。「We worked around this by developing custom set and map datatypes」（244 LOC のカスタム実装）
- **ライブラリ不足**: Parser はモデル化されていない。「there is currently no library support for parser generators, and it is unclear what properties we could prove about a parser model」
- **DRT で見逃したバグ（"anti-trophy"）**: 低確率でしか triggered しない bug が production に流出した事例あり（Table 4）

#### 公開リポジトリ・スタック

- リポジトリ: `https://github.com/cedar-policy`（および `cedar-policy/cedar-spec`）
- Lean 4（具体バージョン番号は本論文では明示なし）
- Mathlib 依存については「extensive library of theorems」とあるが、特定モジュール名・バージョン番号は本論文では明示されず

#### バグ事例（DRT で発見された 21 件のうち）

- IPv6 アドレスパース（::記法）の不一致
- Extension function 命名差異（`lessThan` vs `lt`）
- Parser のエスケープシーケンス処理
- Formatter が record のコメントを脱落
- Validator における unspecified entity types の型処理誤り
- Rust の IP アドレスパース用パッケージのバグ → カスタム実装に置換

#### 新基盤への含意

- **Custom set/map 244 LOC** は、agent-manifesto の研究 tree でも well-founded な順序保証を要する場面（依存グラフ、半順序、退役クロージャ）で同様のカスタム実装が必要になる可能性を示唆する
- **Proof:Model 比 3.4** は、Lean モデルの規模見積もり時に証明コストを 3-4 倍として算入すべき経験則を与える

---

### 1.3 AWS ブログ「Lean into Verified Software Development」

**URL**: https://aws.amazon.com/blogs/opensource/lean-into-verified-software-development/

#### 目的・問題設定

AWS が Cedar に Lean を採用した理由を **3 つの属性** で説明:
1. **Fast runtime**: DRT を成立させる速度
2. **Extensive libraries**: 再利用可能な検証済みデータ構造
3. **Small TCB**: コミュニティ貢献を独立検証なしに採用可能

#### アーキテクチャ

二段構成の Verification-Guided Development:
- **Phase 1**: Lean で executable formal model + 機械化証明
- **Phase 2**: Rust で性能・利便性を最適化した本番コード

主要 API のシグネチャ例:
```lean
def isAuthorized
  (req : Request)
  (entities : Entities)
  (policies : Policies) : Response
:= ...
```

#### 証明された性質

- **forbid_trumps_permit**: 「if a collection of policies contains a forbid that is satisfied by a given request and entities, then calling isAuthorized on these inputs always returns deny」
- **Validator Soundness**: 「if the validator accepts a policy, evaluating the policy won't result in a type error」

#### 検証戦略

> 「we confirm that the code matches the model by using differential random testing. This involves generating millions of random inputs and checking that both model and code produce the same output on every input」

**リリース基準**:
> 「A new version of Cedar isn't released unless its model, proofs, and differential tests are up to date」

これは agent-manifesto の P3（学習統治）に直接対応する **構造的強制**。リリース行為が形式検証の up-to-date 性に縛られる。

#### Lean モデル vs 本番コード（このブログの数値）

| Component | Lean Model | Lean Proof | Rust Prod |
|---|---|---|---|
| Custom sets/maps | 244 | 681 | N/A |
| Evaluator/Authorizer | 897 | 347 | 13,664 |
| Validator | 532 | 4,686 | 11,251 |
| **Total** | **1,673** | **5,714** | **24,915** |

Validator は Rust 実装の **10X smaller**。

注: arxiv 論文（1.2）の Rust Prod 列とブログの Rust Prod 列で数字が異なる（論文 = 4,877 / 6,702、ブログ = 13,664 / 11,251）。論文は「Prod / Tests / Other」を分離、ブログはおそらく Test を含む合計で報告。**1 次情報の中でも区分の取り方で数字が変動**するため、引用時は分母を明記する必要がある。

#### 採用上の課題

- **学習曲線**: 「a steep learning curve. You need to learn which tactics to use, and when and how to use them」
- **Termination 要求**: 「all recursive definitions be well-founded」 → custom data types で回避
- **開発コスト**: Validator soundness 証明は **18 person-days** で完成

#### 性能・公開資源

- Lean evaluation: **5 microseconds** / Rust: **7 microseconds**
- 全証明検証時間: **185 seconds**
- リポジトリ: `cedar-policy/cedar-spec`（仕様）, `cedar-policy/cedar`（本番）
- コミュニティ: `lean-lang.org`, `leanprover.zulipchat.com`

#### 新基盤への含意

- 「Validator soundness で 18 person-days」という数値は、agent-manifesto で公理系の中核定理（例: ConservativeExtension, Trace coverage）を形式化する際の labor cost 見積もりの基準点になる

---

### 1.4 AWS ブログ「Introducing Cedar Analysis: Open-Source Tools for Verifying Authorization Policies」

**URL**: https://aws.amazon.com/blogs/opensource/introducing-cedar-analysis-open-source-tools-for-verifying-authorization-policies/

#### 目的・問題設定

ポリシーセット **間の関係性**（同値、より制限的、より許容的、shadowing 等）を **形式的に判定するツール**を OSS として公開。VGD で証明された Lean モデルを基盤に、ユーザーがポリシー変更の影響を機械的に検証できるようにする。

#### 導入されたツール

1. **Cedar Symbolic Compiler**: 「translates Cedar policies into mathematical formulas that can be automatically analyzed」
2. **Cedar Analysis CLI**: 解析機能を実演する reference implementation

#### 検証可能な性質

- **Equivalence**: 2 つのポリシーセットが厳密に同じ要求を allow するか
- **More/Less Permissive**: 一方が他方より許容的・制限的か
- **Incomparability**: 互いに片方ずつしか allow しない要求があるか
- **Shadowed permits**: 既存 permit に包摂されて効果のない permit
- **Impossible conditions**: 矛盾条件で永遠に allow されない permit
- **Forbid overrides**: deny に上書きされて効果のない permit
- **Complete denials**: 特定 action 全体を必ず deny するポリシーセット

#### 検証実装

> 「Cedar Analysis uses Satisfiability Modulo Theories (SMT) to reason about policies」

SMT solver: **CVC5** を使用。Symbolic Compiler 自体は **Lean で実装**: 「implemented in Lean, which is both a functional programming language and a proof assistant」。これにより compiler の **健全性（soundness）**と**完全性（completeness）**が形式証明されている:

> 「provides 'soundness' (confirmed properties hold across all scenarios) and 'completeness' (violations indicate genuine policy problems without false positives)」

#### アーキテクチャ・パイプライン

```
Cedar Policy
    ↓
Symbolic Compiler (Lean 実装、健全性・完全性証明済み)
    ↓
SMT Formula
    ↓
CVC5 Solver
    ↓
Analysis Result (Equivalence / Subsumption / etc.)
```

これは agent-manifesto の **DSL → AST → Lean → SMT → Test → Code** Pipeline と構造的にほぼ同型。Cedar チームの設計は新基盤の Pipeline 設計の最強の参照実装。

#### ユースケース例

ブログでは photo-sharing app のポリシーをリファクタリングする例を提示:
- 単一複雑 permit を 3 つに分割した結果、意図せず "More Restrictive" になっていることを Analysis CLI が検出 → 修正

ユーザーが投げられる問い:
- 「Are these two policies equivalent?」
- 「Does this change to my policies grant any new, unintended permissions?」
- 「Will this policy refactoring break any existing access patterns?」
- 「Could my newly added policy accidentally deny all access?」

#### 公開資源

- リポジトリ: `https://github.com/cedar-policy/cedar-spec`（Apache 2.0）
- Playground: `https://www.cedarpolicy.com/`
- Slack: `https://cedar-policy.slack.com`

#### 規模・限界

- Cedar 全体: ~1.17M downloads（採用規模の指標）
- 本ブログでは benchmarks/性能数値の開示なし
- 限界: CLI は「subset of potential analysis capabilities」「reference implementation」

#### 新基盤への含意

- **Lean で実装された compiler 自体に健全性・完全性が証明されている**点が決定的に重要。agent-manifesto の Pipeline（DSL parser, AST 変換, Lean 生成, SMT 生成）も、Pipeline 自体を Lean で実装することで、Pipeline の正しさを公理系内で証明可能になる（Pipeline ≒ Symbolic Compiler の役割）

---

### 1.5 Amazon Science「How the Lean Language Brings Math to Coding and Coding to Math」

**URL**: https://www.amazon.science/blog/how-the-lean-language-brings-math-to-coding-and-coding-to-math

#### 全体観

Leo de Moura が 2013 年に Lean を起動し、自動定理証明と対話的定理証明の橋渡しを目的とした。Lean 4 は self-hosting で、IDE・パッケージマネージャを備えた full programming language。AWS が Lean に投資する戦略的位置付けを示す記事。

#### Cedar の位置付け

Cedar チームは「executable formal model of each core component of the Cedar runtime (such as the authorization engine) and static-analysis tools (such as the type checker)」を構築。Lean モデルは「a highly readable specification, allowing the team to prove key correctness properties」。

#### AWS の他の Lean 採用事例（4 つ）

1. **Cedar**: 認可ポリシー（本サーベイの対象）
2. **LNSym**: Armv8 暗号機械語の symbolic simulator（block ciphers, secure hashes 検証）
3. **SampCert**: 形式検証された差分プライバシーライブラリ。AWS Clean Rooms で稼働。「the only verified implementation of the discrete Gaussian sampler」
4. **AILean**: LLM による証明自動化と UX 強化の研究

#### Lean Mathlib の規模（2024-07 時点）

- **1.58 million lines of code**
- **300 名以上**の数学者が貢献
- 「at least a decade younger than comparable libraries」にもかかわらず最大規模

#### Leo de Moura の引用

> 「all proofs and definitions can be exported and independently audited and checked. This is a crucial feature... because it eliminates the trust bottleneck」

これは agent-manifesto の P2（検証分離）と直接対応する哲学。「独立して監査・検証可能」であることが集合知形成の前提。

#### Mathlib と本番検証の接続

SampCert は Mathlib に「heavily」依存。差分プライバシーの正しさを示すために Fourier 解析・数論・トポロジーが必要。すなわち **純粋数学ライブラリが production security system の検証基盤**として機能する。

#### Lean Focused Research Organization（2023 設立）

「decentralized innovation」を強調。教育目的で「children use Lean as a playground for learning mathematics, progressing at their own paces and receiving instantaneous feedback」を目指す。

#### 新基盤への含意

- **Lean Mathlib (1.58M LOC)** という巨大な事前検証済みライブラリの存在は、agent-manifesto の公理系を Mathlib 上に積む合理性を裏付ける（特に半順序・整列・推移閉包など研究 tree で必要な構造）
- **AWS が Lean を 4 領域に並行投資**している事実は、Lean が研究 prototype ではなく **production engineering の選択肢** として確立しつつあることを示す

---

## Section 2: 横断的発見

### 2.1 モデル / 実装分離パターン（VGD: Verification-Guided Development）

5 リンク全てに共通する設計原則は **二系統並走** + **同値性の経験的検証**:

| 層 | 実装言語 | 役割 | 検証手段 |
|---|---|---|---|
| Spec / Model | Lean 4 | readable, mathematical, executable | 形式証明（forbid_trumps_permit 等 7 性質） |
| Production | Rust | 性能・診断・実用性 | 単体テスト + DRT で Lean モデルとの parity |
| Bridge | cargo-fuzz | 数百万件入力で同値性を経験的に検証 | type-directed generation + non-typed generation |

これは agent-manifesto の **公理系（Lean Manifest）** + **実装（.claude/skills, scripts）** + **/trace** の三層と完全同型。新基盤では:
- 公理系層 = Lean Manifest（既存 55 axioms, 1670 theorems, 0 sorry）+ 新たに研究 tree 公理を追加
- 実装層 = Pipeline 出力（GitHub Issue 表示、artifact-manifest, propagate.sh）
- Bridge 層 = /trace + DRT 相当のランダムテスト（Pipeline 入出力同値性の fuzz）

### 2.2 差分テスト（DRT）戦略の鍵

Cedar チームの DRT が成立した条件:

1. **Lean モデルが速い**: 5-6μs / 評価 → 数百万件比較が 6 時間で完走
2. **Type-directed 入力生成**: schema → entity store → policies → requests の段階的生成で well-typed 深部に到達
3. **複数 generator 併用**: type-directed と non-typed の両方で coverage を補完
4. **Fuzzing インフラ**: ECS で 4 vCPU + 8GB を nightly run
5. **構造的強制**: 「リリース時に model/proofs/DRT が up-to-date でなければリリース不可」

新基盤への移植可能パターン:
- 研究ノードの parser → AST → Lean type 変換を differential test 化
- propagate.sh の依存伝播ロジックを Lean モデル化し、Python 実装との parity を fuzz で検証
- 「リリース基準としての DRT」= GitHub Actions で全 manifest-trace + Lean build + propagate diff が green でないと merge 不可

### 2.3 Lean 規模比の経験則

| 指標 | Cedar 実測値 | 適用ガイドライン |
|---|---|---|
| Lean Model : Rust Prod | 1 : 9.4（順序通り 10 倍小さい） | 仕様は実装の 1/10 を目安 |
| Lean Proof : Lean Model | 3.4 : 1（全体平均） | 証明コストはモデルの 3-4 倍 |
| Validator Proof : Model | 8.8 : 1（最難証明） | 健全性・完全性の主定理は 10 倍前後を覚悟 |
| 全証明検証時間 | 185 秒（1673 LOC モデル + 5714 LOC 証明） | 1000 LOC あたり ~25 秒 |
| Validator soundness の labor | 18 person-days | 中核定理 1 件 = 約 3-4 週間 |

agent-manifesto 現状: 55 axiom, 1670 theorem, 0 sorry（CLAUDE.md 記載）。Cedar の Validator が 532 LOC モデル + 4686 LOC 証明 = 5218 LOC で 18 人日と仮定すると、現状の Manifest は概算で **数百人日相当** の累積投資（順序的）。新基盤の研究 tree 公理拡張は 1 公理あたり数日 -数週間で見積もるのが妥当。

### 2.4 Lean が production language として機能する条件

5 リンク横断で抽出される必要条件:

1. **Fast runtime**（DRT 成立の前提）
2. **Small TCB**（外部貢献の信頼確保）
3. **Extensive libraries**（Mathlib 1.58M LOC 等）
4. **Mature IDE**（interactive feedback）
5. **Decentralized auditability**（Leo de Moura の引用通り）
6. **Self-hosting / extensibility**（Lean 4 が Lean で実装）

agent-manifesto はこのうち 1, 4, 5 は既存 Lean 4 を採用することで自動的に得る。2, 3, 6 は Pipeline 設計の自由度に直結（特に 6: Pipeline 自体を Lean で実装すれば、変換規則の正しさを公理系内で証明可能）。

### 2.5 仕様策定行為自体がバグ検出器

> 「While implementing the formal model and carrying out proofs of soundness of the Cedar policy validator, we found and fixed four bugs.」（arxiv 1.2）
> 「Constructing them helped us uncover and fix a non-termination bug」（同上）

これは agent-manifesto の P2（検証の独立性）と P3（学習統治）の核心。**証明構成を強制すること自体が仕様精緻化を駆動する**。/research スキルが Pipeline で公理を更新する強制力を持つことで、判断の言語化が促進される。

### 2.6 Compiler 自体に証明をつけるパターン（Cedar Symbolic Compiler）

Cedar Analysis（1.4）の Symbolic Compiler は Lean で実装され、健全性・完全性が形式証明されている。これは新基盤の Pipeline 設計に **決定的な含意**を持つ:

- Pipeline（DSL → AST → Lean → SMT → Test → Code）の各変換段階を **Lean で実装**することで、変換そのものの正しさを公理系内で証明可能
- これにより Pipeline 出力（Issue 表示、artifact-manifest）は「Lean で正しさが証明された関数の評価結果」として canonical 性を継承
- agent-manifesto T1/T2 の理論的整合性: 一時的な Pipeline 実行（T1）が永続的な公理系（T2）から導出される、という関係が形式的に成立

---

## Section 3: 新基盤への適用案

### 3.1 全体マッピング: Cedar VGD → 新基盤

| Cedar 構成要素 | agent-manifesto 新基盤 対応 |
|---|---|
| Lean Model（評価器・認可器・検証器） | 研究プロセス公理系（ResearchTree, Survey, Gap, Hypothesis, Decomposition, Implementation の inductive 型 + 半順序関係） |
| Rust Production Implementation | Pipeline 実装（Python or Lean 自体）+ GitHub Issue 表示層 + artifact-manifest |
| forbid_trumps_permit 等 7 性質 | tree 不変条件（acyclic, retire closure, evidence chain, scope subsumption 等） |
| cargo-fuzz による DRT | Pipeline 入出力 differential test（spec ↔ generated code の parity） |
| Cedar Symbolic Compiler（Lean 実装） | DSL parser + Lean elab + SMT codegen を Lean 内で実装し、変換正しさを公理化 |
| Validator Soundness 18 人日 | 中核公理（Trace coverage 完全性、Conservative extension 性）の labor 見積もり基準 |
| Custom Set/Map 244 LOC | well-founded 必須箇所（依存閉包、半順序整列、退役クロージャ）のためのカスタムデータ型 |

### 3.2 研究 tree → Lean モデル → Pipeline → 実装 の対応関係

```
研究 tree（人間の概念）
    ↓ /research skill が判断を Lean DSL に翻訳
Lean source（canonical, T2: 永続）
    ↓ Pipeline Stage 1: parser → AST
Internal AST
    ↓ Pipeline Stage 2: type-check via Lean elab
Verified Lean model（型安全性保証済み）
    ↓ Pipeline Stage 3a: SMT codegen     ↓ Stage 3b: Test gen     ↓ Stage 3c: Issue gen
SMT verification          property-based tests          GitHub Issue (read-only)
    ↓ CVC5 solve              ↓ pytest                       ↓ gh CLI
Soundness/Completeness    Behavioral parity              Visualization layer
results                   (DRT relative to Lean)         (T1: 一時的)
```

Cedar との対応:
- **Stage 1-2** = Cedar の Lean Model 構築 + 型チェック
- **Stage 3a** = Cedar Symbolic Compiler + CVC5
- **Stage 3b** = Cedar の cargo-fuzz DRT
- **Stage 3c** = Cedar には対応物なし（agent-manifesto 固有: Issue 同期）

### 3.3 段階的導入計画（Cedar の経験を踏まえた優先順位）

**Phase 1（1-2 ヶ月）: Spec の Lean 化**
- ResearchTree, Node 型を inductive で定義（high-tokenizer の `Spec = (T, F, ≤, Φ, I)` を流用）
- 半順序関係（精緻化、依存、退役）を Lean inductive type で表現
- 不変条件 5-7 件を `theorem` として宣言（証明は次フェーズ）
- Cedar の Custom Set/Map 244 LOC を参考に well-founded データ型整備

**Phase 2（2-3 ヶ月）: 中核証明**
- Conservative extension 性質を最初の中核定理として証明（Cedar Validator soundness ≈ 18 人日 の見積もり）
- Trace coverage 完全性
- Retire closure の正しさ

**Phase 3（1-2 ヶ月）: Pipeline 実装**
- DSL → AST parser を Lean macro/elab で実装（Cedar Symbolic Compiler を参考）
- AST → SMT codegen
- AST → GitHub Issue codegen（read-only 表示）

**Phase 4（継続）: DRT 構築**
- Pipeline 入出力の type-directed generator
- 既存 propagate.sh の挙動と Lean モデルの parity を fuzz で検証
- リリース基準: 「Lean build + DRT + manifest-trace all green」

### 3.4 既存資産の活用

- **lean-formalization/Manifest/**: 既存 55 axiom, 1670 theorem の上に研究 tree 公理を追加（conservative extension）
- **artifact-manifest.json**: Cedar の `cedar-spec` リポジトリ構造を参考に、Lean source / proofs / DRT inputs / generated code を分離して manage
- **/trace スキル**: Cedar の DRT に相当する構造的検証ツールとして Pipeline 出力 vs 公理系の parity 検査に拡張
- **propagate.sh**: Pipeline Stage 3c（Issue codegen）として再位置付け

### 3.5 V1-V7 への影響予想

| 指標 | 期待方向 | 根拠 |
|---|---|---|
| V1（公理依存度） | 増加（公理追加） | 研究 tree 公理の追加 |
| V2（証明充実度） | 増加 | Cedar 比 3.4:1 の経験則で proof 累積 |
| V3（実装一致度） | 増加 | DRT で Pipeline と公理系の parity 強制 |
| V4（テスト独立性） | 増加 | DRT が独立検証層として機能 |
| V5（自動化率） | 増加 | Pipeline 自動化で deterministic 負荷を撤廃 |
| V6（学習効率） | 増加 | 公理系から Issue が自動派生し、判断履歴が tree に蓄積 |
| V7（人間介入 budget） | 減少（介入が増える時期） | Phase 1-2 で公理化作業の人間判断が一時的に増える |

---

## Section 4: 限界と未解決問題

### 4.1 Cedar が解決していない領域

1. **Parser の形式化未解決**: Cedar は parser を Lean モデル化していない（「no library support for parser generators」）。新基盤の DSL parser を Lean で実装するには、parser combinator の選択（Lean 標準の Parsec vs 自作）と健全性証明手段が未解決
2. **DRT の漏れ**: Cedar の anti-trophy（DRT で見逃されたバグ）が示すように、確率的検証は 100% 保証ではない。新基盤でも Pipeline 出力の corner case はカバーしきれない可能性
3. **Lean 4 → external tools の相互運用**: Cedar Symbolic Compiler は CVC5 に依存。新基盤が SMT を使う場合、SMT solver 自体は trusted となる（Lean の小さな TCB という美徳が一部失われる）

### 4.2 Cedar からは導出できない agent-manifesto 固有問題

1. **GitHub Issue との双方向同期**: Cedar には Issue 同期相当の機能なし。新基盤では Issue 状態（open/closed/PR linked）の Lean モデルへの逆流が必要だが、これは Cedar の知見から直接導出できない
2. **退役（retirement）の表現**: 認可ポリシーは「常に有効」が前提だが、研究ノードは退役する。Cedar には退役表現なし。前回サーベイ（00-synthesis 2.1）でも全 PKM ツールに欠落と指摘されている課題
3. **LLM が生成した公理の信頼性**: Cedar の Lean モデルは人間が書く前提。新基盤では /research スキル経由で LLM が公理を草稿することが想定され、公理草稿の検証手順が別途必要（formal-derivation スキルの活用）
4. **半順序の判定可能性**: Cedar は順序関係（forbid trumps permit など）が決定可能。研究 tree の「精緻化関係」「親子関係」は decidable に保つ設計判断が必要

### 4.3 定量データの不確実性

- arxiv 論文（1.2）とブログ（1.3）で Rust LOC の数値が異なる（区分の取り方が違う）。新基盤で同様の数値を引用する際は、必ず計測対象範囲を明記する必要
- Lean バージョン・Mathlib 依存バージョンが 5 リンクのいずれにも明示されていない。Cedar の cedar-spec リポジトリの `lakefile.lean` / `lean-toolchain` を直接確認する必要がある（次ラウンドの調査対象）
- 全証明検証時間 185 秒は 2024 時点の値。Lean 4 の elaboration 高速化が進む 2026 年現在では更に短縮されている可能性

### 4.4 採用上のリスク（学習曲線）

- Cedar チームの「steep learning curve」評価は専門ソフトウェアエンジニア前提。agent-manifesto の利用者基盤（一時的 LLM インスタンス + 人間レビュアー）にとっては更に高いハードル
- T1（一時的インスタンス）が Lean 構文の知識を毎回ゼロから獲得する必要があるため、Pipeline DSL は **Lean syntax の薄いラッパ** として設計し、Lean 直接書き換えを最小化する必要

---

## Section 5: 出典 URL リスト

1. AWS Cedar 公式紹介: <https://lean-lang.org/use-cases/cedar/>
2. Cedar 論文 (arxiv 2407.01688v1): <https://arxiv.org/html/2407.01688v1>
3. AWS ブログ「Lean into Verified Software Development」: <https://aws.amazon.com/blogs/opensource/lean-into-verified-software-development/>
4. AWS ブログ「Introducing Cedar Analysis」: <https://aws.amazon.com/blogs/opensource/introducing-cedar-analysis-open-source-tools-for-verifying-authorization-policies/>
5. Amazon Science「How the Lean Language Brings Math to Coding and Coding to Math」: <https://www.amazon.science/blog/how-the-lean-language-brings-math-to-coding-and-coding-to-math>

### 関連 1 次資源（次ラウンドで確認推奨）

- Cedar 仕様リポジトリ: <https://github.com/cedar-policy/cedar-spec>（Lean version, Mathlib 依存の確認）
- Cedar 本番リポジトリ: <https://github.com/cedar-policy/cedar>
- Cedar Playground: <https://www.cedarpolicy.com/>
- Lean Zulip コミュニティ: <https://leanprover.zulipchat.com/>
- Cedar Slack: <https://cedar-policy.slack.com>

---

## 既往サーベイとの差分

本グループは G1 として、既往の `01-knowledge-graph-tools.md` ~ `06-internal-assets.md` および `research/survey_type_driven_development_2025.md` でカバーされていない以下の知見を加える:

- **Lean の本番投入の経済性** (Validator 18 人日、3.4:1 の proof:model 比、5μs evaluation 等の定量データ)
- **VGD パターンの 5 構成要素** (Lean spec / Rust prod / DRT / cargo-fuzz / type-directed gen)
- **Cedar Symbolic Compiler パターン** (Pipeline 自体を Lean で実装し変換正しさを公理化)
- **DRT が成立する条件** (model 速度、type-directed gen、構造的強制としてのリリース基準)
- **AWS の Lean 投資 4 領域** (Cedar / LNSym / SampCert / AILean) と Mathlib 1.58M LOC の規模

これらは TyDD サーベイ（Lean-Auto, Liquid Haskell 等の理論サイド）や既往 6 グループ（PKM, Provenance, Build Graph 等の隣接ツール群）では扱われていない、**Lean を本番システムに投入した際の経験則・経済性データ**として補完的に位置づけられる。

# 閉環トレーサビリティ: 条件付き公理系と成果物の完全対応

Research #191, Sub-Issue #192

## 研究の動機

設計書を条件付き公理系（Lean 文書）として定義するとき、そこから生まれる成果物（テスト、実装、設定）との間に閉じたトレーサビリティの環を構築する方法を確立する。

核心的な問いは以下の通りである：

> 条件付き公理系の各命題に対して、(1) 全件テスト計画が系統的に導出され、(2) 各テストと実装オブジェクトが完全に対応し、(3) 実装から公理系への帰着が機械的に検証可能であるような閉じた環を、どのように構成するか。

```
条件付き公理系（Lean 設計書）
    ↓ ① 命題 → テスト計画の導出
テストスイート（各テストが命題IDを持つ）
    ↓ ② テスト ↔ 実装オブジェクトの完全対応
実装オブジェクト群
    ↓ ③ 実装 → 命題への帰着検証
条件付き公理系 ── 閉じた輪
```

---

## 1. Requirements Traceability 古典

### 1.1 Gotel & Finkelstein (1994)

**"An Analysis of the Requirements Traceability Problem"**
ICRE '94, pp. 94-101. IEEE.

**貢献:**
- トレーサビリティの基礎的定義: 要件のライフを順方向・逆方向の両方で追跡する能力
- **pre-RS / post-RS トレーサビリティ** の区別:
  - pre-RS: 要件策定前（なぜその要件が存在するか）
  - post-RS: 要件策定後（要件が設計・実装・テストにどう反映されるか）
- 100+ 実務者への実証研究: トレーサビリティ問題の多くは pre-RS に起因
- **Contribution Structure**: 誰がどの要件の策定に寄与したかのモデル

**本プロジェクトとの接点:**
- pre-RS = 公理の数学的根拠（Axiom Card の Basis / Refutation condition）
- post-RS = 公理 → 定理 → テスト → 実装のトレース（`/trace` スキル）
- pre-RS が困難という知見は、公理根拠のワークフロー（`/ground-axiom`）の必要性を支持

### 1.2 Ramesh & Jarke (2001)

**"Toward Reference Models for Requirements Traceability"**
IEEE TSE, Vol. 27, No. 1, pp. 58-93.

**貢献:**
- 26 組織への実証研究に基づく参照モデル
- **4つのトレースリンク型**:
  1. **Satisfies**: 設計要素が要件を満たす
  2. **Depends_on**: 要件間の依存関係
  3. **Evolves**: 時間的変化（バージョニング）
  4. **Rationale**: 意思決定の根拠

**本プロジェクトの概念への対応:**

| RT リンク型 | 公理系での対応 | 実装 |
|---|---|---|
| Satisfies | `Γ ⊢ φ` 判定（定理が公理を満たす） | Lean 型検査 |
| Depends_on | `PropositionId.dependencies` | `Ontology.lean` |
| Evolves | AGM 信念改訂（拡張・改訂・縮約） | `VersionTransition` in `Evolution.lean` |
| Rationale | 公理の根拠記録 | Axiom Card の Basis フィールド |

- Low-end / High-end の区別: 本プロジェクトは Axiom Card + 依存グラフ + D13 影響伝播で high-end に位置

### 1.3 Spanoudakis & Zisman (2005)

**"Software Traceability: A Roadmap"**
Handbook of Software Engineering and Knowledge Engineering, Vol. 3, pp. 395-428.

**貢献:**
- 最も包括的な **8 つのトレースリンク型** の分類:

| # | リンク型 | 定義 | 公理系での対応 |
|---|---|---|---|
| 1 | Dependency | e1 の存在が e2 に依存 | `PropositionId.dependencies` |
| 2 | Generalisation/Refinement | 複合要素の分解・精緻化 | 公理 → 定理の導出チェーン |
| 3 | Evolution | e1 が e2 に進化 | `CompatibilityClass` (P3) |
| 4 | Satisfiability | e1 が e2 を充足 | Lean 型検査による `Γ ⊢ φ` |
| 5 | Overlap | 共通の特徴への言及 | 複数命題が同一公理に依存 |
| 6 | Conflict | 二要素間の矛盾 | 公理間の矛盾検出（一貫性検証） |
| 7 | Rationalisation | 作成・進化の根拠 | Axiom Card |
| 8 | Contribution | 成果物への寄与 | エージェントインスタンスの寄与追跡 |

### 1.4 Mäder & Gotel (2012)

**"Towards Automated Traceability Maintenance"**
Journal of Systems and Software, Vol. 85, No. 10, pp. 2205-2227.

**貢献:**
- トレースリンクの **自動保守**（作成ではなく保守）
- **Traceability Information Model (TIM)**: プロジェクトごとに許容されるリンク型を定義するグラフ
- **6 つの基本開発活動**: 追加・削除・置換・統合・分割・変更
- 19 ルール / 67 代替案のルールカタログ → **精度 95%以上**

**本プロジェクトとの接点:**
- 6 つの開発活動は公理系操作に直接対応:
  - 追加 = 新公理の追加（conservative extension）
  - 削除 = 公理の退役（P3 retirement）
  - 置換 = 公理の改訂（AGM revision）
  - 統合 = 重複公理の統合
  - 分割 = 複合公理の分解
  - 変更 = 定義の精緻化
- TIM = `artifact-manifest.json` + `Ontology.lean` 依存グラフ
- **UML の半形式性による限界は Lean 4 では解消**: 型検査が完全に形式的な変更検出を提供

### 1.5 Cleland-Huang et al. (2014)

**"Software Traceability: Trends and Future Directions"**
FOSE 2014, ACM, pp. 55-69.

**貢献:**
- トレーサビリティシステムの **7 つの品質目標**:
  1. Purposed（目的適合）
  2. Cost-Effective（費用対効果）
  3. Configurable（構成可能）
  4. Trusted（信頼できる）
  5. Scalable（拡張可能）
  6. Portable（移植可能）
  7. Valued（価値がある）
- 統合的目標: **Ubiquitous**（意識せずとも常に存在する）

**本プロジェクトとの接点:**
- IR ベースのトレースリンク回復は本プロジェクトでは不要（Lean 4 が型レベルで正確な依存情報を提供）
- **Ubiquitous traceability** の理想は hook による自動強制（P4）と一致
- 7 品質目標は `/trace` スキルの評価フレームワークとして利用可能

---

## 2. 仕様駆動開発の方法論

### 2.1 B-Method / Event-B

**参考:** Abrial, "The B-Book" (1996), "Modeling in Event-B" (2010)

**方法:** 集合論 + 述語論理に基づく状態機械仕様。段階的精緻化（stepwise refinement）で抽象仕様から具体実装へ。

**トレーサビリティ機構:**
- 各精緻化ステップで **証明義務（proof obligation）** が自動生成される:
  - **INV**: 具象イベントが接着不変量を保存
  - **GRD**: 具象ガードが抽象ガード以上に強い
  - **SIM**: 具象動作が抽象動作をシミュレート
  - **FIS**: 具象動作が実行可能
- 精緻化チェーン自体がトレーサビリティ成果物

**本プロジェクトへの示唆:**
- **接着不変量（gluing invariant）** = 抽象層と具象層の間の証明可能な関係。`PropositionCategory.strength` 順序と `dependency_respects_strength` がこれに対応
- 証明義務の自動生成パターンは Lean 4 メタプログラミングで実現可能
- 実績: パリ地下鉄14号線（SIL4、25年以上フィールド欠陥ゼロ）

### 2.2 TLA+ / PlusCal

**参考:** Lamport, "Specifying Systems" (2002); Newcombe et al., "How Amazon Web Services Uses Formal Methods" (CACM, 2015)

**方法:** 時相論理（Temporal Logic of Actions）。`Spec == Init /\ [][Next]_vars /\ Liveness`

**トレーサビリティ機構:**
- 仕様は設計文書として実装と**並行して**維持される
- AWS の PObserve: 実行ログを事後的に形式仕様と照合
- TLA PreCheck: TLA+ 仕様と TypeScript 実装が同一の状態グラフを生成することを証明

**本プロジェクトへの示唆:**
- **PObserve パターン**: hook によるエージェント行動ログ → 公理系との事後照合。`.claude/metrics/tool-usage.jsonl` がこの方向
- 仕様-実装ギャップが TLA+ の本質的限界。Lean 4 はこのギャップを型レベルで解消

### 2.3 Isabelle/HOL, Lean 4, 検証済みソフトウェア

**参考:** Klein et al., "seL4" (SOSP 2009); CakeML; Lean4Lean (2024)

**方法:** 依存型理論 / 高階論理。証明 = プログラム（Curry-Howard 対応）。

**トレーサビリティ機構:**
- **証明搬出コード（proof-carrying code）**: 証明そのものがトレーサビリティ成果物
- seL4: 抽象仕様 → 実行可能仕様 → C 実装の3段階精緻化。バイナリまで検証
- CakeML: HOL 仕様 → 検証済み ML コード → 検証済みコンパイラ → 信頼されたバイナリ

**本プロジェクトへの示唆:**
- 本プロジェクトは既にこのスペクトラムの最強位置にある
- seL4 の3段階精緻化 = T 公理（抽象）→ 導出原理 → 実装制約
- Lean 4 のコード生成器は **未検証** — 信頼基盤（TCB）の限界として文書化すべき
- Lean4Lean の自己検証 = D9（自己適用）の形式的対応物

### 2.4 Design by Contract

**参考:** Meyer, "Object-Oriented Software Construction" (1997)

**方法:** Hoare 論理に基づく事前条件・事後条件・クラス不変量。コードに直接埋め込み。

**トレーサビリティ機構:**
- **仕様と実装の距離ゼロ**: 同一ファイル、同一言語
- 実行時検査で違反を即座に検出
- 静的検証: SPARK Ada（航空宇宙）、AutoProof（Eiffel）

**本プロジェクトへの示唆:**
- **共配置原則**: Axiom Card が Lean 定義に隣接して配置されている（既に実践済み）
- 事前条件/事後条件 = 条件付き公理の活性化条件
- **局所性の限界**: DbC はメソッドレベル。システムレベルの性質には D13 影響伝播のような合成機構が必要

---

## 3. 条件付き公理系への対応表

### 3.1 RT リンク型と公理系操作の対応

| RT リンク型 | 公理系操作 | Lean 4 実装 | 検証方法 |
|---|---|---|---|
| Satisfy | `Γ ⊢ φ` 判定 | `theorem` 宣言の型検査 | `lake build` (0 sorry) |
| Derive | Conservative extension | `ExtensionKind` + `definitional_implies_conservative` | `Terminology.lean` |
| Evolve | AGM 信念改訂 | `VersionTransition` + `CompatibilityClass` | `Evolution.lean` + P3 hook |
| Refine | 段階的精緻化 | `dependency_respects_strength` | `Ontology.lean` |
| Rationalize | 公理根拠の記録 | Axiom Card (Layer/Basis/Refutation) | `/ground-axiom` |
| Contribute | エージェント寄与の追跡 | `Co-Authored-By` + git history | git blame |

### 3.2 閉環の完全性検証

閉じた環の各リンクの検証方法:

| リンク | 形式的条件 | 現行の検証 | ギャップ |
|---|---|---|---|
| 命題 → テスト | `∀ p : PropositionId, ∃ t : TestId, tests(t, p)` | `manifest-trace coverage` | **テストケース粒度の対応なし** |
| テスト → 実装 | `∀ t : TestId, ∃ i : ImplId, implements(i, tested_by(t))` | テスト実行時に暗黙検証 | **明示的な対応関係なし** |
| 実装 → 命題 | `∀ i : ImplId, ∃ p : PropositionId, justifies(p, i)` | `artifact-manifest.json` refs | **ファイル粒度のみ** |
| 環の閉包 | 二部グラフの入次数・出次数 ≥ 1 | `/trace violations` | **3層統合の検証なし** |

### 3.3 Event-B 証明義務との類推

| Event-B PO | 閉環トレーサビリティでの対応 |
|---|---|
| 全 PO が放出される | 全公理が `0 sorry` |
| Dead event 検出 | `/trace coverage` によるカバーされていない命題の検出 |
| Deadlock freedom | 閉環検査（ダングリングリンクなし） |
| Guard strengthening | 具象公理の前提条件が抽象公理の前提条件を含意 |
| Simulation | 具象理論が抽象理論のモデル |

---

## 4. テスト生成の手法

### 4.1 形式仕様からの性質ベーステスト

- **Plausible** (Lean 4): `Decidable` な命題に対するランダムサンプリングテスト
- **SlimCheck** (Mathlib): Plausible の前身。`Testable` / `SampleableExt` インスタンスが必要
- **QuickChick** (Coq): 最も成熟した基礎的 PBT フレームワーク。テストコード自体の正しさを証明

**適用可能性:** 本プロジェクトの公理の多くは存在量化子 + opaque 型を使用しており、直接的な `Decidable` インスタンスの導出が困難。翻訳層（公理 → 判定可能な性質）が必要。

### 4.2 ミューテーションテスト

1. 公理を変異させる（例: `dependency_respects_strength` の不等号を反転）
2. 既存テストが変異を検出するか確認
3. テストが通過する → トレーサビリティギャップ（その公理を検証するテストが不在）

**Lean 4 の利点:** 形式部分では、公理の変異は下流の定理の型検査失敗を引き起こす — コンパイラ自体がミューテーション検出器として機能。運用テスト（`tests/test-all.sh`）については別途ミューテーション解析が必要。

### 4.3 系統的テストケース導出

| 対象 | テスト導出方法 | 現行カバレッジ |
|---|---|---|
| 各 `axiom` | 否定したら失敗するテストを導出 | 部分的（Phase ベース） |
| 各 `theorem` | Lean コンパイル自体がテスト | 完全（0 sorry） |
| 各 `def`/`structure` | Plausible で性質テスト | 未実装 |

---

## 5. 特定されたギャップと次のアクション

### 5.1 Lean 4 における保存拡大性の自動検証器がない

- 現行: 人間による分類 + `axiom` 宣言数のカウント
- 必要: 「このファイルは T₀ に新しい公理を追加しない」のメタプログラム検証
- Lean4Lean は検証済みチェッカーだが conservative extension 判定は未公開

### 5.2 Plausible/PBT が未統合

- 公理は宣言されているが性質テストされていない
- キー公理への `Decidable`/`Testable` インスタンスの追加で自動テスト生成が可能に

### 5.3 運用テストのミューテーションカバレッジ解析がない

- 形式部分は自己防御的（Lean がミューテーションを拒否）
- 314 シェルテストには系統的ミューテーションカバレッジ解析がない

### 5.4 AGM 公準の検証

- `Evolution.lean` が AGM 的操作をエンコードしているが、Gärdenfors の6公準が `VersionTransition` に対して成立することの形式証明がない

---

## 参考文献

### Requirements Traceability 古典

- [R01] Gotel, O.C.Z. and Finkelstein, A.C.W. (1994) "An Analysis of the Requirements Traceability Problem." ICRE '94, pp. 94-101.
- [R02] Ramesh, B. and Jarke, M. (2001) "Toward Reference Models for Requirements Traceability." IEEE TSE, 27(1), pp. 58-93.
- [R03] Spanoudakis, G. and Zisman, A. (2005) "Software Traceability: A Roadmap." Handbook of SE and KE, Vol. 3, pp. 395-428.
- [R04] Mäder, P. and Gotel, O. (2012) "Towards Automated Traceability Maintenance." JSS, 85(10), pp. 2205-2227.
- [R05] Cleland-Huang, J. et al. (2014) "Software Traceability: Trends and Future Directions." FOSE 2014, pp. 55-69.

### 仕様駆動開発

- [R06] Abrial, J.-R. (1996) "The B-Book." Cambridge University Press.
- [R07] Abrial, J.-R. (2010) "Modeling in Event-B." Cambridge University Press.
- [R08] Lamport, L. (2002) "Specifying Systems." Addison-Wesley.
- [R09] Newcombe, C. et al. (2015) "How Amazon Web Services Uses Formal Methods." CACM, 58(4).
- [R10] Jackson, D. (2006) "Software Abstractions." MIT Press.
- [R11] Meyer, B. (1997) "Object-Oriented Software Construction." 2nd ed. Prentice Hall.

### 形式検証

- [R12] Klein, G. et al. (2009) "seL4: Formal Verification of an OS Kernel." SOSP.
- [R13] Kumar, R. et al. (2014) "CakeML: A Verified Implementation of ML." POPL.
- [R14] de Moura, L. et al. (2021) "The Lean 4 Theorem Prover and Programming Language." CADE.
- [R15] Hargoniemi et al. (2024) "Lean4Lean: Verifying a Typechecker for Lean, in Lean."

### 理論的基盤

- [R16] Alchourrón, Gärdenfors, Makinson (1985) "On the Logic of Theory Change." J. Symbolic Logic.
- [R17] Kuncar, O. and Popescu, A. (2018) "Model-Theoretic Conservative Extension for Definitional Theories."
- [R18] Paraskevopoulou, Z. and Hritcu, C. (2015) "Foundational Property-Based Testing." ITP.

### Event-B とトレーサビリティ

- [R19] "Extracting Traceability between Predicates in Event-B Refinement." IEEE (2018).
- [R20] "An Approach of Requirements Tracing in Formal Refinement." (2009).

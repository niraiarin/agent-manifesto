# G5-5: Lean4Lean 差分サーベイ（既往 S3 との delta）

作成日: 2026-04-17
担当: G5-5（新基盤研究サーベイ）
位置付け: 既往サーベイ `research/survey_type_driven_development_2025.md` S3 節との **差分のみ** を抽出。重複調査は回避。
1 次情報:
- arXiv 2403.14064 v3 (2025-09-14, submitted to CPP 2026)
- github.com/digama0/lean4lean（master, 最新 2026-04-13）
- WITS 2026 @ POPL 2026 プログラム（2026-01-17, Rennes）

**200 字要約**: S3 以降、Lean4Lean は `whnf.WF`（2025-09）・`isDefEqCore.WF`（2025-09）を完了し、S3 時点で open だった **Unique Typing Conjecture 2.7 を 2026-01-31 に証明（injectivity modulo）**、Church-Rosser・standardization も 2026-Q1 に proved。一方 v3 で `looseBVarRange_eq` が「unsound assumption」に降格、`hasLooseBVars` overflow 等 2 件の新規 kernel soundness 問題が追加。Lean4 は「ほぼ ground-up 書き直し」で soundness record が「no longer spotless」と v3 で明記。agent-manifesto の「kernel 信頼」前提は依然妥当だが、根拠は「独立再実装」であって「Godel 的に閉じた自己検証」ではない。

---

## Section 1: S3 との差分（新しい知見のみ）

S3 がカバー済みの内容（two-layer architecture, Type Regularity, 20–50% overhead, looseBVarRange bug, Godel 限界の言及）は繰り返さない。

### 1.1 Open Conjecture の多くが 2025-Q3 以降に解決

S3 時点で open だった conjecture と、2026-04 時点の解決状況:

| 予想 (S3) | S3 時点 | 新状況 | 根拠 |
|---|---|---|---|
| `whnf.WF`（WHNF 計算の健全性） | open | **proved (2025-09-26)** | commit "feat: whnf'.WF finished" |
| `whnfCore'.WF` | open | **proved (2025-09-25)** | commit "feat: whnfCore'.WF finished" |
| `isDefEqCore.WF`（定義的等価コアの健全性） | open | **proved (2025-09-28)** | commit "feat: isDefEqCore'.WF finished" |
| Conjecture 2.7 (Unique Typing) | open（v3 で "downgraded from theorem to conjecture"） | **proved (2026-01-31), modulo injectivity** | commit "feat: unique typing proved (modulo injectivity)" |
| Church-Rosser (confluence) | 未言及 in v3 body | **proved (2026-01-02〜01-04)** | commit "feat: church_rosser and consequences", "feat: ParRed triangle lemma" |
| Standardization theorem | 未言及 | **proved (2026-02-02)** | commit "feat: standardization theorem" |
| `normalizeAux` soundness | 未言及 | **proved (2026-03-08)** | commit "feat: soundness of normalizeAux" |
| Conjecture 2.9 (Definitional Inversion: sort-inv, forallE-inv, sort/forall disjointness) | open | **依然 open** | unique typing は "modulo injectivity" と明記 |
| Conjecture 2.10 (Strengthening) | open | 本調査時点で直接の解決 commit なし | — |

→ **S3 時点の "open conjectures" リストは 2026-Q1 でほぼ埋まった**。残るのは injectivity 系（2.9）と strengthening（2.10）。injectivity は依然「stratified typing が substitution を保存しない」という S3 記載の障害に阻まれている。

### 1.2 v3 論文で新規に明示された「降格された仮定」

S3 には記載されていない v3 (2025-09) の重要な変更:

- **`looseBVarRange_eq` は "unsound assumption" と明記**（v3 §4.1 末尾）。S3 ではこの bug が「発見・修正された」として扱われたが、v3 では「fix は Expr.data を opaque 化して `loosebVarRange` を抽象化することで masking したに過ぎず、定義上 `loosebVarRange e < 2^20` が unconditional に証明できる実装のままで、反例が到達不能であることを Lean の logic が知らない」と明示。
- 引用: "we are still relying on an unsound assumption (loosebVarRange_eq), because the definition of loosebVarRange is still visible and so one can prove that e.g. loosebVarRange e < 2^20 unconditionally, which means that loosebVarRange cannot be the 'correct' definition, which means the theorem isn't provable even though all counterexamples are unreachable (but Lean's logic doesn't know that)."
- → S3 の「bug was found and fixed」という整理は部分的に誤解を招く。**正確には「bug は特定され、exploit 不能にしたが、"correct" definition には到達していない」。**

### 1.3 新規に発見された kernel soundness 関連 issue（S3 以降）

`bugs-found.md` は `looseBVarRange`（Zulip スレ）に加え以下を追加:

| Lean4 Issue | 概要 | 状態 | Soundness 影響 |
|---|---|---|---|
| #10475 "Kernel bug: collecting fvars in `infer_let`" | `infer_let` が let 本体の型内の依存を無視し、loose fvars を含む式を check 結果として返しうる | Closed 2025-09-20 (PR #10476) | Kernel invariant「check 後の式は well-formed」を破る |
| #10511 "Substring comparison not reflexive" | 不正 UTF-8 を含む `Substring` が自身と等しくならず、`ExprMap`（`Expr` 内部で使用）の HashMap 運用を破る | Closed 2025-09-22 (PR #10552) | 直接の soundness というより kernel 内部状態の一貫性 |

→ S3 の「1 bug found」表現は古い。**2025-09 時点で少なくとも 3 件の kernel 関連 issue が lean4lean 起源で修正**されている。

### 1.4 「deliberate divergences」の体系化（S3 未言及）

`divergences.md` が体系化された（S3 に該当記述なし）。主な項目:

1. `reduceBool` の reduction を **サポートしない**（C コンパイラ経由で外部呼び出し可能なため、kernel 実装から切り離すと「意味論的に unsound by design」と Carneiro が明言。Mathlib は `reduceBool` を避けている）
2. Primitive definition checking: 本家 kernel は trusted prelude 前提で skip する checks を lean4lean では実施（より保守的）
3. Literal type existence check を追加
4. Level normalization: "experimental new algorithm... complete for level algebra"
5. `ensureSort` の順序が本家と異なる（monad 設計の違い）

→ **"lean4lean = C++ kernel の完全コピー" という S3 の記述は近似**。実際は「soundness の観点で strictly safer な divergences を複数含む」。

### 1.5 WITS 2026 Keynote（2026-01-17, S3 時点の "予定" の実行結果）

- Keynote 1 (09:00): **Mario Carneiro, "Lean4Lean: Mechanizing the Metatheory of Lean"** (60min)
- Keynote 2 (16:00): Meven Lennon-Bertrand, "Verifying Dependent Type-checkers" (60min)
- 関連発表: András Kovács "Observing Definitional Equality"（定義的等価の観察可能性）

→ Dependent typechecker 検証は 2026 時点で「isolated effort」ではなく **workshop 規模のサブコミュニティ** として確立。MetaCoq / Lean4Lean の "双方向交流" が公式化しつつある（Lennon-Bertrand が両方に関与）。

### 1.6 再現コード: Coquand-Abel 非終了（v3 §3.2.1）

S3 は「Lean type theory is non-terminating due to Coquand-Abel」と抽象化して記述。v3 は **実行可能な Lean code として掲載**:

```lean
def True' := ∀ p : Prop, p → p
def om : True' → True' := fun A =>
  @cast (True' → True') A
    (propext ⟨fun _ => a, fun _ => id⟩)
    (fun z => z (True' → True') id z)
def Om : True' := om (True' → True') id om
#reduce Om   -- whnf nontermination
```

impredicativity + proof irrelevance + subsingleton elimination の合成。**kernel は「loop forever しない」のではなく「timeout と depth limit で経験的に止まっている」**。これが fuel=1000 設計の実運用的根拠となる。

### 1.7 独立再実装の根拠と FVS=4 手法（v3 §3.2.1, S3 未言及）

v3 が明示する核心的主張: proof assistant の信頼性確保には **3 手段** が必要:
1. testing
2. **independent reimplementation**（真の独立性のため Scala/Rust 実装 `trepplein`, `nanoda_lib` を引用）
3. formal verification

lean4lean は (2)+(3) のハイブリッド。

技術的ハイライト: lean4lean の kernel は mutual recursion の call graph 上 **Feedback Vertex Set = 4**（`isDefEqCore, whnfCore, whnf, inferType`）。この 4 関数を `Methods` record に外出しし `RecM = ReaderT Methods M` で untangling → 依存順に個別定義。DTT kernel の Lean による形式化の一般的 idiom として提示。

---

## Section 2: Lean4Lean の進展と新基盤への信頼度評価

### 2.1 agent-manifesto の「kernel 信頼」前提への含意

agent-manifesto は現状 55 axiom / 1670 theorem / 0 sorry (2026-04-17 実測) を Lean 4 に依拠。この信頼の構造的根拠を再評価:

| 信頼の根拠 | S3 時点 | 2026-04 時点 | 新基盤への含意 |
|---|---|---|---|
| Lean 4 実装の（実装バグなしの）正しさ | lean4lean が実装の一部を検証 | **`inferType`, `whnf`, `isDefEqCore` の WF がすべて proved** | 実装バグの検出力は質的に向上。ただし lean4lean が検証した `Lean.Expr` 処理範囲の外（elaborator, tactic framework 等）は依然 unverified |
| Lean 4 theoretical soundness | MLTT ベース、Carneiro 2019 proof (ZFC with n inaccessibles) | v3 で「Lean 4 への書き直しで soundness proof は **"no longer directly applicable"** と明示」 | **信頼の根拠が弱まった方向。**agent-manifesto の公理系が Lean 4 特有の機能（nested inductives, η for structures）に依存している場合、soundness の argument に穴がある |
| Conjecture 依存の主要 metatheorem | Unique typing 未証明 | **Unique typing proved (modulo injectivity)** | Kernel の termination 関連定理に依拠する設計判断は安全度が向上 |
| kernel への bug report 経路 | 1 bug (looseBVarRange) | 3+ bugs, かつ一部は「masked, not fully fixed」 | kernel bug が **今後も発見される可能性が高い**。新基盤は「kernel は無謬」ではなく「kernel は継続的に改善中」を前提にすべき |

### 2.2 新基盤で追加する axiom（AssumptionId, ResearchId 等）と kernel soundness

agent-manifesto が導入する領域 axiom（`AssumptionId`, `ResearchId` 等）は **Lean kernel の soundness には影響しない**。これらは:
- 型論理的には `opaque` / `axiom` 宣言で導入される固有名/構造
- kernel の typing rule はこれらを T-CONST / T-EXTRA で uniform に扱う
- lean4lean が検証する範囲は `inferType` / `whnf` / `isDefEqCore` の **algorithmic correctness** であり、環境に登録される固有 axiom の semantic content には依存しない

**含意**: 新基盤の axiom 追加は Lean4Lean の進展と **直交**。axiom 自体の "soundness" は領域モデルでの整合性（agent-manifesto 側の `ground-axiom` skill の責務）であり、kernel との関係では consistency が問題なのは `False` を証明しないこと（= axiom が satisfiable な model を持つこと）のみ。

ただし以下の設計上の注意:
- 新基盤が `native_decide` や `reduceBool` に依存する自動化を入れる場合、lean4lean は **これらを検証しない**（divergences.md 1 項目）。`decide` 経由なら OK だが `native_decide` は trusted compilation を増やす
- 新基盤が `opaque` で性能のため wrapper を被せる場合、lean4lean の `looseBVarRange_eq` パターン（"opaque で masking しただけ」の技法）は **応急処置であって真の証明ではない** ことを意識すべき。agent-manifesto の公理化戦略としては「opaque の内実が見えない」ことを能動的に望むのは危険

### 2.3 Performance の最新データ（S3 と同じ出典だが追補情報）

v3 Figure 2（mathlib4 rev. 526c94c, 12-core i7-1255U, single-threaded）:

| Package | lean4checker (C++) | lean4lean (Lean) | ratio |
|---|---|---|---|
| Lean | 37.01 s | 44.61 s | 1.21x |
| Batteries | 32.49 s | 45.74 s | 1.40x |
| Mathlib (+Batteries+Lean) | 44.54 min | 58.79 min | 1.32x |

→ S3 記載の「20–50% overhead」は **v3 で「around 30% slower」と修正**。主要因は「Lean compiler and data representation shortcomings compared to C++」。Carneiro は「Lean compiler の改善で速度は縮む見込み。より多く verify しても regression させない」と明言。

**新基盤への含意**: 本番 CI で lean4lean による二重検証を入れるなら、フル mathlib 相当で追加 ~15 min。agent-manifesto 規模（55 axiom, 1670 theorems）なら数十秒〜数分オーダーで済む可能性が高く、高リスク変更の `/verify` パスに組み込む価値あり。

---

## Section 3: ゲーデル不完全性との関連の詳細分析

### 3.1 v3 論文での明示的定式化

S3 は Godel を抽象的に言及。v3 §3.2.1 は **run-time の文章として明示**:

> "It is unlikely that we can prove termination of a typechecker for Lean in Lean, because although the soundness proof from [6] does not depend on termination, MetaRocq's does [24], and generally termination measures for DTT require large cardinals of comparable strength to the proof theory. **We are up against Gödel's incompleteness theorem, so anything that would imply the unconditional soundness of Lean won't be directly provable.**"

これは 2 段構え:
1. **直接的: Lean の consistency を Lean 内で証明できない**（Godel 第 2 不完全性）
2. **間接的: typechecker の termination 証明にも Con(Lean) 相当の力が必要** → termination を Lean 内で証明するのも原理的に不可能

### 3.2 Lean4Lean が実際に取っている戦略

不完全性に抵触しない「部分的正しさ」の積層:

```
[Layer A] 実装 → 仕様の refinement
    inferType_impl(e) succeeds ⇒ ∃ α. TrExpr(e, e_v) ∧ VEnv ⊢ e_v : α
    (termination は fuel で chop; fuel 切れは deepRecursion エラーとして明示的に失敗)

[Layer B] 仕様 → モデル論的健全性
    VEnv ⊢ e_v : α ⇒ [Carneiro 2019 の ZFC+inaccessibles モデル]
    ← v3 で明示: "no longer directly applicable" to Lean 4

[Layer C] Con(Lean) 自体
    ← 原理的に Lean 内で証明不可能（Godel）。Carneiro 2019 は外側 (ZFC) で行う
```

**Lean4Lean が実現するのは Layer A のみ**。Layer B は Lean 4 では「proof of concept for Lean 3 core; Lean 4 拡張では修復作業中」の状態。Layer C は fundamental barrier。

### 3.3 新基盤のマニフェスト設計への教訓

v3 冒頭の「cautionary tale」は agent-manifesto に直接刺さる:

> "It is not sufficient to see a prior system and hope to do better through sheer force of will. We are all human, and mistakes in both the theory and the implementation happen as a matter of course. **The way to do better is not to rewrite, but to set up a process that structurally ensures that mistakes are either prevented or corrected.**"

agent-manifesto の D1–D18 設計原則、特に **P2（検証の独立性）と P4（可観測性）** は、Lean 4 チームが Lean 3 → Lean 4 書き直しで「soundness record が no longer spotless」になった教訓と平仄。**「書き直し」ではなく「構造的に間違いを検出する process」** の側に立つ。

さらに:
- **T6（人間の最終決定権）** は「kernel 無謬」を仮定しない設計として合理化される。Godel 的に閉じた自己検証は不可能なので、外部（人間・独立実装）のチェックポイントが必須
- **E1（自己レビュー禁止）** は Lean4Lean が選んだ「independent reimplementation」戦略の proof assistant 版

### 3.4 Self-verification の "useful boundary"

Lean4Lean が示した実用的な分離:
- **証明可能**: 個別 kernel 関数の algorithmic correctness（partial correctness, given fuel）
- **証明不可能**: Con(Lean), Lean kernel の全面的 termination, Lean kernel の unconditional soundness
- **条件付き証明可能**: Carneiro 2019 型の「Lean ⊆ ZFC + n inaccessibles」という **外側の体系への相対化**

新基盤が axiom を追加するとき、「その axiom の soundness を Lean 内で証明する」という目標は **Godel 的に意味がない**。目標は「axiom を追加しても既存の Mathlib/Lean4Lean で証明された性質を破らない」という **conservative extension** 性質（P3 の "conservative extension" 分類と整合）。

---

## Section 4: 限界と未解決問題

### 4.1 Lean4Lean の 2026-04 時点の未完了範囲

v3 本文 + commit history から:

1. **Conjecture 2.9（Definitional Inversion）の完全解決**: unique typing は proved だが modulo injectivity。sort-inv / forallE-inv / sort-forallE disjoint が依然 open
2. **Conjecture 2.10（Strengthening）**: open
3. **inductive types の形式化**: "Currently, Lean4Lean contains a complete implementation of inductive types, including nested and mutual inductives, but not much work has been done on the theoretical side, defining what an inductive specification should generate."（v3 §6）
4. **η for structures**: 「decision procedure は incomplete だが implement。soundness には影響しないはず」と書かれているのみ（v3 §6.1）
5. **quot 型のメタ理論**: §5 に declaration レベルの扱いはあるが、quot の性質に関する verified theorem は限定的
6. **Native reduction (`reduceBool`, `native_decide`)**: 意図的に verify 対象外。"unsound by design" と Carneiro が明言
7. **Elaborator, tactic framework, module system**: lean4lean の範囲外。Lean compiler の残り大部分

### 4.2 agent-manifesto の信頼の穴（Lean4Lean では埋まらない）

| 穴 | 説明 | 緩和策 |
|---|---|---|
| Elaborator bug | `theorem` / `def` の elaboration（特に implicit args, typeclass resolution）は Lean4Lean 対象外 | Lean4Lean の CLI で .olean を再検証すれば kernel-level の最終結果は double check される |
| Module system / import | import 順序、circular dependency 検出 | lean4lean は kernel レベルで再検証するのみ |
| `native_decide` を使った axiom 正当化 | コンパイラ経由の計算結果を信頼 | agent-manifesto 側で `native_decide` を禁止するか、使用箇所を `/trace` で明示 |
| Lean compiler 自体の bug | Lean binary の RTS, Lake build, FFI | 外部（人間・CI の別実装）に頼るしかない |
| `axiom` 宣言の意味論的整合性 | Lean4Lean は axiom を形式的に受け入れるだけ。「その axiom が consistent な model を持つ」は別問題 | agent-manifesto の `ground-axiom` workflow がカバーすべき領域 |

### 4.3 「新基盤 Lean 採用の信頼度」総合評価

- **+**: 2025-09〜2026-03 の大幅な metatheory 進展により、kernel 中核の formal verification は「研究プロトタイプ」から「mathlib を本番検証できる tool」に到達
- **+**: Unique typing / Church-Rosser / standardization / WHNF soundness がすべて 2026-Q1 に揃い、S3 時点の「未証明 conjecture」ほぼ解消
- **−**: `looseBVarRange` 等の「masked, not truly fixed」soundness gap が残存し、v3 で明示的に admitted
- **−**: Lean 4 全体の soundness proof は Carneiro 2019 (Lean 3) の **直接適用不能** 状態が v3 で公式確認
- **−**: Conjecture 2.9（Definitional Inversion）は "stratified typing doesn't preserve substitution" という **S3 と同じ barrier** に阻まれ続けている
- **=**: 新基盤で追加する領域 axiom は Lean kernel soundness に直交。kernel の進展/停滞とは独立

**結論**: 新基盤の Lean 4 採用判断は **「kernel は完璧」ではなく「kernel は継続的に構造的検証される」を前提にする** のが適切。マニフェストの P2/P4/T6/E1 はこの前提と整合。

---

## Section 5: 出典 URL リスト

### 1 次情報
- Lean4Lean 論文 v3 (arXiv, 2025-09-14): https://arxiv.org/abs/2403.14064
- Lean4Lean 論文 PDF 直接: https://arxiv.org/pdf/2403.14064v3
- GitHub リポジトリ: https://github.com/digama0/lean4lean
- `bugs-found.md`: https://github.com/digama0/lean4lean/blob/master/bugs-found.md
- `divergences.md`: https://github.com/digama0/lean4lean/blob/master/divergences.md
- commit history: https://github.com/digama0/lean4lean/commits/master

### Kernel bug report（lean4lean 起源）
- Zulip "Soundness bug: hasLooseBVars is not conservative"（bugs-found.md からリンク）
- leanprover/lean4#10475 "Kernel bug: collecting fvars in infer_let": https://github.com/leanprover/lean4/issues/10475
- leanprover/lean4#10511 "RFC: Make Substring comparison reflexive": https://github.com/leanprover/lean4/issues/10511

### WITS 2026 @ POPL 2026
- WITS 2026 ホーム: https://popl26.sigplan.org/home/wits-2026
- WITS 2026 プログラム: https://popl26.sigplan.org/program/program-wits-2026/
- 日時: 2026-01-17, Rennes, France, Salle 13
- 関連 Keynote: Meven Lennon-Bertrand "Verifying Dependent Type-checkers"

### 独立再実装への参照（v3 内引用）
- trepplein (Scala): https://github.com/gebner/trepplein
- nanoda_lib (Rust): https://github.com/ammkrn/nanoda_lib
- lean4checker (Lean + C++ FFI): https://github.com/leanprover/lean4checker
- Rocq critical bugs: https://github.com/rocq-prover/rocq/blob/master/dev/doc/critical-bugs.md

### 関連既往サーベイ
- S3 原典: `/Users/nirarin/work/agent-manifesto/research/survey_type_driven_development_2025.md` §S3 (L115–165)

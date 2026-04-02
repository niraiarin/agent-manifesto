---
name: ground-axiom
user-invocable: true
description: >
  公理の数学的根拠を検証し、形式証明とトレーサビリティを確立する。
  各 axiom について (1) 根拠となる数理理論を特定、(2) 核心的定理を Lean で形式証明、
  (3) Axiom Card に導出チェーンを記載、(4) 降格可能なら降格。
  #157 の反復ワークフロー。
  「公理の根拠」「ground axiom」「数学的裏付け」「axiom grounding」
  「公理検証」で起動。
---

# 公理の数学的根拠検証 (Axiom Grounding)

指定された axiom の数学的根拠を検証し、
形式証明とトレーサビリティを確立する反復ワークフロー。

## Manifesto Root Resolution

このスキルは agent-manifesto リポジトリのファイル（Lean 形式化、scripts/）を参照する。
実行前に以下でリポジトリルートを解決すること:

```bash
MANIFESTO_ROOT=$(bash .claude/skills/shared/resolve-manifesto-root.sh 2>/dev/null || echo "")
```

解決できない場合はユーザーに案内する。以降の `lean-formalization/` および `scripts/` への参照は `${MANIFESTO_ROOT}/` を前置して解決する。

## 背景

#157（公理系の数理的基盤整備）の中核プロセス。
T4 (`output_nondeterministic`) で確立されたパターンを全 axiom に適用する。

### 確立されたパターン

| パターン | 内容 | 結果 |
|---|---|---|
| **根拠検証** | 数理理論の特定 → Lean 形式証明 → Axiom Card 記載 | axiom 維持、根拠明示 |
| **型制約埋め込み** | 構造体に不変条件を追加 → axiom が自明に | axiom → theorem 降格 |

### 学んだ教訓（#158, #160, #163, #164 から）

1. 公理の「上流化」（1 axiom → 2+ bridge axioms）は公理インフレであり避ける
2. opaque 具体化は axiom 降格に寄与しない（型の中身を見ても因果関係は出てこない）
3. 目的は「降格」ではなく「数学的裏付けの検証」。裏付けが取れれば axiom のまま正当
4. Foundation ファイルは必ず `Manifest.lean` から import する（オーファン防止）
5. 依存グラフツール (#158) は事前条件として `depgraph.json` が最新であること

## ワークフロー

### Step 0: 事前条件

```bash
# depgraph.json が最新であることを確認（なければ生成）
# Note: Lean ファイル変更後は必ず再生成すること
if [ ! -f depgraph.json ]; then
  scripts/depgraph.sh generate
fi
# Lean ファイルを変更した後は明示的に再生成する:
#   scripts/depgraph.sh generate
```

### Step 1: 対象選定

```bash
# 全 axiom の分類と根拠状況を確認
scripts/depgraph.sh classify

# 対象 axiom の依存関係を確認
scripts/depgraph.sh subgraph <axiom_name> --format=json
scripts/depgraph.sh impact <axiom_name>
```

対象は以下のいずれかに分類される:

| 状態 | 判断 | アクション |
|---|---|---|
| **Axiom Card なし** (no-card) | まず Axiom Card を作成（Step 1a） | Step 1a → Step 2 |
| **Card あり、根拠未検証** (derivable / derivable? / unknown) | 本ワークフローの対象 | Step 2 → Step 3 |
| **Card あり、design-axiom** | 設計判断の根拠を明示 | Step 2 → Step 5（形式証明は任意） |
| **true-axiom** (contract) | 契約であることを明示 | Step 5 のみ |

### Step 1a: Axiom Card のブートストラップ（no-card の場合）

no-card axiom に対して Axiom Card を新規作成する。

```lean
/-- [Axiom Card]
    Layer: <層の判定（下記参照）>
    Content: <axiom の Lean 宣言から内容を記述>
    Basis: <根拠の種類を特定（下記参照）>
    Source: <該当する設計文書・マニフェスト箇所>
    Refutation condition: <この公理が偽になる条件> -/
```

**Layer の判定基準:**

| axiom の性質 | Layer |
|---|---|
| 物理的・環境的制約 | T₀ (Environment-derived) |
| 自然科学的事実 | T₀ (Natural-science-derived) |
| 社会的契約・合意 | T₀ (Contract-derived) |
| 経験的仮説（反駁可能） | Γ \ T₀ (Hypothesis-derived) |
| 設計判断 | Γ \ T₀ (Design-derived) |
| 測定可能性の主張 | Γ \ T₀ (Measurability) |

**Basis の特定手順:**
1. axiom の Lean 宣言を読み、何を主張しているか把握する
2. その主張が成り立つ理由を自問する（なぜこれが真か？）
3. Step 2 の根拠対応表から該当する数理理論を特定する
4. 特定できない場合は `/research` で先行研究を調査する

**Refutation condition の書き方:**
- 「この公理が偽になるのはどういう状況か」を記述する
- T₀ の場合: "Not applicable (T₀)" は避ける。代わりに具体的な反駁条件を書く
  例: "If computational resources become unlimited (e.g., infinite energy)"
- Γ \ T₀ の場合: 必ず反駁条件を記述する（反駁可能性が E の定義的性質）

### Step 2: 根拠の特定

対象 axiom の Axiom Card（`Basis:` フィールド）を読み、
主張の数学的根拠を特定する。

| Basis の種類 | 対応する数理理論 | 参照すべき先行研究 |
|---|---|---|
| 確率論・サンプリング | Kolmogorov 公理、softmax | Gao & Pavel 2017, Jang 2017 |
| 制御理論・フィードバック | Internal Model Principle, DPI | Francis & Wonham 1976, Cover & Thomas 1991 |
| 情報理論 | Shannon エントロピー, IB | Shannon 1948, Tishby 1999 |
| プロセス分離 | CCS, π計算, セッション型 | Milner 1989, Honda 1993 |
| 統計的検定 | Neyman-Pearson, バイアス | Neyman & Pearson 1933, Podsakoff 2003 |
| リスク・セキュリティ | 攻撃面モデル, 最小権限 | Manadhata & Wing 2011, Saltzer & Schroeder 1975 |
| 測定可能性 | 操作的定義, GQM | Basili & Rombach 1988 |
| 設計判断 | トレードオフ理論 | 該当分野の理論 |
| 契約・合意 | 社会契約, 権限モデル | — （数学的導出不可） |

根拠が不明な場合は `/research` スキルで先行研究を調査する。

### Step 3: 形式証明の構築

根拠となる数理理論の核心的定理を `Manifest/Foundation/` に Lean で形式証明する。

**ディレクトリ構成:**
```
Manifest/Foundation/
  Probability.lean      — 確率論（softmax, 分布, サンプリング）[T4]
  ControlTheory.lean    — 制御理論（フィードバック, DPI）[T5]
  InformationTheory.lean — 情報理論（エントロピー, 相互情報量）[T3]
  ProcessModel.lean     — プロセスモデル（セッション分離）[T1]
  StatisticalTesting.lean — 統計的検定（独立性, 検出力）[E1]
  RiskTheory.lean       — リスク理論（攻撃面, 単調性）[E2]
  Measurement.lean      — 測定理論（操作的定義）[V1-V7]
```

**形式証明の要件:**
- 0 sorry
- Mathlib の型を活用（`PMF`, `StrictMono`, `MeasureTheory` 等）
- doc comment に根拠文献の引用を含める

**Foundation ファイルの登録（必須）:**

新しい Foundation ファイルを作成したら、必ず `Manifest.lean` に import を追加する。
これを忘れると `lake build Manifest` で型検査されないオーファンファイルになる。

```bash
# Manifest.lean に import を追加
echo 'import Manifest.Foundation.新ファイル名' >> lean-formalization/Manifest.lean

# 追加後に必ずビルド確認
cd lean-formalization && lake build Manifest
```

**形式証明の範囲:**
- axiom が主張する内容の **数学的裏付け** となる定理を証明する
- axiom そのものを theorem に降格する必要はない（降格可能な場合はする）
- 「この数学的事実が成り立つ → この axiom の主張は正当」という関係を示す

### Step 4: 降格可能性の判定

形式証明ができたら、axiom を theorem に降格できるか判定する。

| パターン | 判定基準 | アクション |
|---|---|---|
| **型制約埋め込み** | 構造体の不変条件として表現可能 | 降格する |
| **空真** | 他の axiom の下で前提が常に偽 | 降格する |
| **条件付き導出** | 条件を追加すれば theorem にできる | axiom 維持（根拠を記載） |
| **導出不可能** | 型や定義から証明できない | axiom 維持（根拠を記載） |

降格する場合:
```bash
# 変更前のスナップショット
cp depgraph.json depgraph-before.json

# Lean コード変更
# axiom → theorem

# 検証
lake build Manifest
scripts/depgraph.sh diff depgraph-before.json
scripts/depgraph-verify.sh
SYNC_SKIP_TESTS=1 bash scripts/sync-counts.sh --update
```

### Step 4a: 変更波及の再帰的検証

axiom の変更（降格、Axiom Card 更新、Foundation 追加）を行ったら、
**グラフ上の関連要素を全て検証し、必要なら修正する**。

`lake build` は型エラーを検出するが、doc comment の記述整合性や
トレーサビリティの正確性は検出しない。このステップでそれを補う。

#### 4a-1. 依存グラフの再生成と影響範囲の取得

**Step 4 で Lean ファイルを変更した後は、必ず `depgraph.json` を再生成してから impact を実行する。**
再生成せずに impact を実行すると、変更前のグラフで影響範囲を計算してしまう。

```bash
# 必須: Lean 変更後にグラフを再生成
scripts/depgraph.sh generate

# 変更した要素の影響範囲を取得（BFS 推移閉包 — 再帰的に全影響を返す）
scripts/depgraph.sh impact <変更した要素名>

# サブグラフとして構造を確認
scripts/depgraph.sh subgraph <変更した要素名> --direction=up --format=json
```

#### 4a-2. 各影響要素の検証

影響を受ける各要素について、以下を確認する:

| 検証項目 | 確認内容 | 確認方法 | 修正が必要な例 |
|---|---|---|---|
| **Lean 型検査** | `lake build Manifest` が通るか | `lake build Manifest` | 降格で型が変わり依存 theorem が壊れた |
| **doc comment の参照** | 変更した要素を参照する doc comment は正確か | `grep -rl '<要素名>' Manifest/ --include="*.lean"` で参照箇所を列挙し読む | 「axiom X に基づく」→ X が theorem に降格 |
| **Derivation Card** | 導出チェーンの参照は有効か | 同上 grep で Derivation Card を探す | 根拠の axiom 名が変わった |
| **Axiom Card の Basis** | 根拠の記述が変更を反映しているか | 同上 | 前提 axiom が降格された |
| **Axiom Card の Refutation condition** | 反駁条件が変更を反映しているか | 同上 | 降格により不要になった反駁条件 |
| **Mathematical grounding セクション** | Foundation 参照が有効か | 同上 | Foundation の定理名が変わった |
| **Manifest.lean import** | Foundation ファイルの import が正しいか | `grep 'Foundation' Manifest.lean` | 新 Foundation の import 漏れ / 削除した Foundation の残骸 |
| **PropositionId.dependencies** | Ontology.lean の依存定義と整合するか | `Ontology.lean` の `PropositionId.dependencies` を読む | 依存構造が変わった |
| **depgraph-verify.sh** | 構造的整合性が保たれているか | `scripts/depgraph-verify.sh` | DAG 破壊、孤立ノード増加 |

#### 4a-3. 再帰的修正

修正を行った場合、**修正した要素自体の影響範囲も検証する**（再帰）。
ただし **検証済み要素のセットを管理し、同じ要素を再検証しない**。

```
verified = {}
queue = impact(A)

while queue is not empty:
  X = queue.pop()
  if X in verified: skip
  X を検証（4a-2 の 9 項目）
  verified.add(X)
  if X を修正した:
    depgraph.sh generate  # グラフ再生成
    queue += impact(X) - verified  # 新規影響のみ追加
```

**終了条件（不動点）:** queue が空（全影響要素が検証済みで、追加の修正が不要）。

**ループバックルール:**
- 4a 中に **Axiom Card の doc comment を修正** した場合 → 4a 内で完結（Step 5 不要）
- 4a 中に **新しい Foundation 証明が必要** と判明した場合 → Step 3 に戻る。Step 3 完了後に Step 4a を再開
- 4a 中に **Lean の定理本体を修正** した場合 → `lake build` で型検査後、4a を続行

#### 4a-4. 修正の記録

影響範囲の検証結果を記録する:

```markdown
#### 波及検証

| 影響要素 | 検証結果 | 修正内容 |
|---|---|---|
| `context_bounds_action` | doc comment 修正 | 「axiom context_finite」→「theorem context_finite」 |
| `d11_context_finite` | 整合 | 修正不要 |
```

### Step 5: Axiom Card の更新

Axiom Card に数学的根拠の導出チェーンを記載する。

**テンプレート:**

```lean
/-- [Axiom Card]
    Layer: T₀ (分類)
    Content: 公理の内容
    Basis: 根拠の説明

    Mathematical grounding (Foundation/対応ファイル.lean):
      [R1] 著者 (年, arXiv:XXXX.XXXXX) — 定理名: 内容の要約
      [R2] 著者 (年) — 定理名: 内容の要約
      Formally proven: 定理名1, 定理名2 (0 sorry)

    Source: manifesto.md の対応箇所
    Refutation condition: 反駁条件 -/
```

根拠文献の引用ルール:
- 学術論文: 著者, 年, arXiv ID または venue
- 教科書: 著者, 年, 章・定理番号
- 形式証明: Lean ファイル名 + 定理名

### Step 6: 検証と記録

```bash
# ビルド確認
cd lean-formalization && lake build Manifest

# 変更があった場合
scripts/depgraph.sh rebuild  # generate + diff + verify

# テスト
bash tests/phase5/test-depgraph.sh
```

**P2 検証（新しい Foundation ファイルがある場合）:**

Foundation ファイルは永続する構造的コードなので、コミット前に `/verify` を実行する。

```
/verify Foundation/新ファイル名.lean
```

Issue にコメントとして結果を記録:
```markdown
### [YYYY-MM-DD] <axiom_name> の数学的根拠検証

**根拠理論**: [理論名]
**形式証明**: Foundation/XXX.lean — 定理名1, 定理名2 (0 sorry)
**降格**: 可能/不可能 (理由)
**Axiom Card**: 更新済み — [R1], [R2] の導出チェーン

**トレーサビリティ**:
[R1] → [R2] → Foundation/XXX.lean:定理名 → Axiom Card
```

## 完了基準

各 axiom について以下が全て満たされた状態:

| # | 基準 | 確認方法 |
|---|---|---|
| 1 | Axiom Card が存在する | `grep -rl 'Axiom Card' Manifest/ --include="*.lean"` で対象 axiom のファイルがヒット |
| 2 | `Basis:` に根拠が記載されている | Axiom Card の Basis フィールドが空でない |
| 3 | 数学的根拠が `Foundation/` に形式証明されている | `lake build Manifest.Foundation.XXX` 成功, 0 sorry |
| 4 | Foundation ファイルが `Manifest.lean` から import されている | `grep 'Foundation' Manifest.lean` |
| 5 | Axiom Card に文献引用の導出チェーンがある | `Mathematical grounding` セクションに [R1]→[R2]→... 形式 |
| 6 | 降格可能性が判定されている | Derivation Card（降格済み）または Axiom Card（維持理由記載） |
| 7 | 影響範囲の波及検証が完了している | Step 4a の記録テーブルに全影響要素がリスト |
| 8 | `depgraph-verify.sh` PASS | スクリプト実行 |

## 全 axiom の進捗追跡

`scripts/depgraph.sh classify` の出力に対して、
各 axiom の根拠検証状況を管理する。
（no-card axiom の件数は `classify` の実行結果で確認すること。固定値をハードコードしない。）

状態:
- `grounded` — 根拠検証完了（形式証明 + Axiom Card 更新済み）
- `demoted` — theorem に降格済み
- `in-progress` — 作業中
- `pending` — 未着手
- `not-applicable` — 契約由来等で数学的導出が不可能（根拠は「契約」として記載）

## アンチパターン

| やってはいけないこと | 理由 | 代わりに |
|---|---|---|
| 1 axiom → 2+ bridge axioms | 公理インフレ (#164 FAIL) | 根拠を Axiom Card に記載 |
| opaque 具体化で降格を試みる | 因果関係は型から出ない (#163 FAIL) | 数理理論を Foundation に形式化 |
| 形式証明なしに Axiom Card だけ更新 | 検証可能性がない | Foundation/ に Lean で証明 |
| 全 axiom を一括処理 | 品質が下がる | 1 つずつ丁寧に |
| Foundation ファイルを Manifest.lean に import しない | オーファン — `lake build` で検査されない | 作成直後に import 追加 + ビルド確認 |
| `lake build Manifest` だけで Foundation を検証した気になる | import がなければ Foundation は検査対象外 | `lake build Manifest.Foundation.XXX` を個別に確認 |
| 変更した要素の影響範囲を検証しない | doc comment やトレーサビリティの不整合が残る | Step 4a で再帰的に検証 |
| `lake build` 成功で波及検証を省略する | 型エラーは検出するが意味的整合性は検出しない | Step 4a の 9 項目を全て確認 |
| Lean 変更後に `depgraph.sh generate` せず impact を実行 | 変更前のグラフで影響範囲を計算してしまう | Step 4a-1 で必ず再生成してから impact |
| 検証済み要素を再検証する（visited-set なし） | 無限ループまたは無駄な再検証 | 4a-3 の visited set で管理 |

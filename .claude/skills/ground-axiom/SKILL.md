---
name: ground-axiom
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

## 背景

#157（公理系の数理的基盤整備）の中核プロセス。
T4 (`output_nondeterministic`) で確立されたパターンを全 axiom に適用する。

### 確立されたパターン

| パターン | 内容 | 結果 |
|---|---|---|
| **根拠検証** | 数理理論の特定 → Lean 形式証明 → Axiom Card 記載 | axiom 維持、根拠明示 |
| **型制約埋め込み** | 構造体に不変条件を追加 → axiom が自明に | axiom → theorem 降格 |

### 学んだ教訓（#160, #163, #164 から）

1. 公理の「上流化」（1 axiom → 2+ bridge axioms）は公理インフレであり避ける
2. opaque 具体化は axiom 降格に寄与しない（型の中身を見ても因果関係は出てこない）
3. 目的は「降格」ではなく「数学的裏付けの検証」。裏付けが取れれば axiom のまま正当

## ワークフロー

### Step 1: 対象選定

```bash
# 全 axiom の分類と根拠状況を確認
scripts/depgraph.sh classify

# 対象 axiom の依存関係を確認
scripts/depgraph.sh subgraph <axiom_name> --format=json
scripts/depgraph.sh impact <axiom_name>
```

選定基準:
- Axiom Card がない (no-card) → まず Axiom Card を作成
- 根拠が未検証 (derivable / derivable? / unknown) → 本ワークフローの対象
- true-axiom (contract) → 根拠は「契約」であることを明示して完了

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
| 1 | Axiom Card が存在する | `grep -l 'Axiom Card' Manifest/*.lean` |
| 2 | `Basis:` に根拠が記載されている | Axiom Card の Basis フィールド |
| 3 | 数学的根拠が `Foundation/` に形式証明されている | `lake build`, 0 sorry |
| 4 | Axiom Card に文献引用の導出チェーンがある | [R1]→[R2]→... 形式 |
| 5 | 降格可能性が判定されている | Derivation Card または Axiom Card に記載 |
| 6 | `depgraph-verify.sh` PASS | スクリプト実行 |

## 全 axiom の進捗追跡

`scripts/depgraph.sh classify` の出力に対して、
各 axiom の根拠検証状況を管理する。

状態:
- `grounded` — 根拠検証完了（形式証明 + Axiom Card 更新済み）
- `demoted` — theorem に降格済み
- `in-progress` — 作業中
- `pending` — 未着手
- `not-applicable` — 契約由来等で数学的導出が不可能（根拠は「契約」として記載）

## アンチパターン

| やってはいけないこと | 理由 | 代わりに |
|---|---|---|
| 1 axiom → 2+ bridge axioms | 公理インフレ | 根拠を Axiom Card に記載 |
| opaque 具体化で降格を試みる | 因果関係は型から出ない (#163 FAIL) | 数理理論を Foundation に形式化 |
| 形式証明なしに Axiom Card だけ更新 | 検証可能性がない | Foundation/ に Lean で証明 |
| 全 axiom を一括処理 | 品質が下がる | 1 つずつ丁寧に |

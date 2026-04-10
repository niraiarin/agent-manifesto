---
name: design-implementation-plan
user-invocable: true
description: >
  マニフェスト準拠の設計実装計画書を任意のプラットフォーム向けに生成する。
  D1-D18 設計原則をプロバイダプリミティブ（Claude Code, GitHub Actions, CI/CD 等）に
  マッピングし、フェーズ別ロードマップ、テストケース、V1-V7 計測設計を含む計画書を出力する。
  「実装計画」「設計計画」「ロードマップ」「design plan」「implementation plan」
  「何から実装すべき」で起動。
dependencies:
  invokes:
    - skill: research
      type: soft
      phase: "Step 0c"
      condition: "設計分析が必要な場合"
    - skill: verify
      type: soft
      phase: "Step 9"
      condition: "self-application"
    - skill: instantiate-model
      type: hard
      phase: "Step 9d feedback loop"
      condition: "FeedbackReport 生成時"
---
<!-- @traces P6, D5, D12, D14 -->

# Design Implementation Plan Generator

マニフェスト準拠システムの設計実装計画書を、指定された Provider に最適化して生成する。

## Manifesto Root Resolution

このスキルは agent-manifesto リポジトリのファイルを参照する。
実行前に以下でリポジトリルートを解決すること:

```bash
MANIFESTO_ROOT=$(bash .claude/skills/shared/resolve-manifesto-root.sh 2>/dev/null || echo "")
```

解決できない場合はユーザーに案内する。以降のファイルパスは `${MANIFESTO_ROOT}/` を前置して解決する。

## 前提知識

このスキルは以下のファイルを参照する:

1. `${MANIFESTO_ROOT}/docs/design-development-foundation.md` — D1–D18 の設計開発基礎論（プラットフォーム非依存）
2. `${MANIFESTO_ROOT}/lean-formalization/Manifest/DesignFoundation.lean` — D1–D18 の Lean 形式検証（`SelfGoverning` typeclass, `DesignPrinciple` 型, `assumptionImpact` 等を含む）
3. `${MANIFESTO_ROOT}/lean-formalization/Manifest/Ontology.lean` — `SelfGoverning` typeclass の定義（Section 7 の構造的強制メカニズム）
4. `${MANIFESTO_ROOT}/lean-formalization/Manifest/Axioms.lean` — T1–T8 公理（T₀ base theory）
5. `${MANIFESTO_ROOT}/lean-formalization/Manifest/Ontology.lean` — 境界条件（L1–L6）の定義と詳細
6. `${MANIFESTO_ROOT}/lean-formalization/Manifest/Observable.lean` — 変数（V1–V7）の定義と詳細

**重要:** `SelfGoverning` typeclass は、原理を定義する型が自己適用（Section 7）を
型レベルで強制するメカニズムである。このスキルが生成する計画書、
およびこのスキル自身も、この原則に従う。

## 入力

ユーザーから以下を受け取る:

- **Provider 名**: 対象プラットフォーム（例: Claude Code, GitHub Actions, 任意のCI/CD）
- **Provider のプリミティブ一覧**（任意）: Provider が持つ機能の一覧。省略された場合は Provider 名から推定するか、ユーザーに確認する。

## D17 演繹的設計ワークフローとの対応

このスキルは D17 (DesignFoundation.lean) の state machine の Step 3 (derive) に該当する。
D17 の全ワークフロー内での位置:

```
Step 0 investigate → /research で Provider 調査（本スキルの Step 0）
Step 1 extract     → /instantiate-model Phase 0-1 で仮定抽出
Step 2 construct   → /instantiate-model Phase 2-3 で条件付き公理系構築
Step 3 derive      → **本スキル**（条件付き公理系からの設計導出）
Step 4 validate    → /verify + derivation accuracy 測定
Step 5 feedback    → /research Gate 判定
```

**重要**: 本スキルは条件付き公理系（Step 2 の出力）を入力として使うべきであり、
コア公理系 (T/E/P/D) から直接設計を導出してはならない（D17 ワークフロー違反）。

### D17 出力型の適合

本スキルの出力は D17 の `DerivationOutput` に適合すべき:
- 導出された設計判断のリスト（各判断に CC axiom basis を明記）
- 全 CC axiom が少なくとも 1 件の導出に寄与していること

## 実行手順

### Step 0: Provider 仕様調査 + PoC

**設計の前に、Provider の実態を把握する。**
推測に基づく設計は「美しいが動かない」計画書を生み出す。
P4（可観測性先行）と同じ原理: 観測してから設計する。

#### 0a: 公式ドキュメントの精読

Provider の公式ドキュメントを読み、以下を**実際の仕様として**確認する:

- 各プリミティブの入出力スキーマ（JSON 構造、引数、戻り値）
- 設定ファイルの正確なフォーマットと配置場所
- プリミティブ間の連携方法と制約（例: Hook から Subagent を起動できるか？）
- バージョン依存の挙動差異

ドキュメントが不足している場合は WebFetch / WebSearch で補完する。
「たぶんこう動くだろう」で進めない。

#### 0b: 先行事例の調査

同じ Provider で類似の制約実装を行った事例がないか調査する:

- 公開リポジトリ（GitHub 等）での設定ファイルの実例
- Provider のコミュニティ/フォーラムでの議論
- 既存のプラグインやスキルで参考になるもの

#### 0c: 網羅性検証（D17 Step 0 品質保証 #277）

**T4（確率的出力）対策**: 単一の調査パスでは PD の網羅性が保証されない。

**手法 1: 複数エージェント並列調査**
- 2 つ以上の独立した subagent に同じ調査を並列実行させる
- 各 subagent の PD リストの union を取る
- 1 エージェントでは見落とす PD を確率的に回収

**手法 2: 反復的深掘り (loop)**
- Pass 1: 全ドキュメントページから PD 収集
- Pass 2: 発見したプリミティブごとに内部構造を深掘り
- Pass 3: サブプリミティブ間の関係性を調査
- 収束条件: 新規 PD 発見数が前回比 5% 未満

**手法 3: カテゴリベース網羅性チェック**

Provider のプリミティブカテゴリを事前定義し、各カテゴリの PD 件数を検証:

```markdown
| カテゴリ | 期待 PD 数 | 実際 | 充足 |
|---------|----------|------|------|
| hooks   | ≥ 5      | ?    | ?    |
| permissions | ≥ 3  | ?    | ?    |
| memory  | ≥ 3      | ?    | ?    |
| agents  | ≥ 3      | ?    | ?    |
| skills  | ≥ 3      | ?    | ?    |
| security | ≥ 3     | ?    | ?    |
| settings | ≥ 2     | ?    | ?    |
```

カテゴリ内 PD 数が 0 の場合は調査不足の警告を出す。

**D17 出力型の適合条件**:

```
investigateStepValid report =
  report.investigationPasses >= 2 &&
  report.categoriesCovered == report.categoriesTotal &&
  report.decisionCount > 0 &&
  report.sourceCount > 0
```

#### 0d: PoC（Proof of Concept）

> Note: 旧 Step 0c。網羅性検証 (0c) の追加により番号が変更。

D1 マッピングのうち、最もリスクが高い構成（= 想定通りに動かない可能性が高いもの）について、
最小限の PoC を作成して実際に動作確認する。

**PoC で検証すべきこと:**
- 構造的強制のプリミティブ（例: Hook）が、想定した入力に対して想定した出力を返すか
- ブロック/許可の判定が実際のランタイムで機能するか
- D2（Worker/Verifier 分離）の実現に必要なプリミティブ間連携が動作するか

**PoC の結果を記録する。** 想定と実態の乖離があれば、Step 2 以降の設計に反映する。
乖離が大きい場合は、マッピング戦略自体を見直す。

#### 0e: 調査結果のサマリ

Step 0 の成果を以下の形式でまとめる:

```markdown
### Provider 仕様調査結果

#### 確認済みの仕様
| プリミティブ | 確認した仕様 | 情報源 |
|------------|------------|--------|

#### 想定と実態の乖離
| 想定 | 実態 | 設計への影響 |
|------|------|------------|

#### PoC 結果
| PoC 内容 | 結果 | 判明した制約 |
|---------|------|------------|
```

### Step 1: 基礎資料の読み込み

以下のファイルを読み込む:

- `docs/design-development-foundation.md` の D1–D18 全文
- `lean-formalization/Manifest/Ontology.lean` の L1–L6（境界条件セクションの doc comment）
- `lean-formalization/Manifest/Observable.lean` の V1–V7（変数セクションの doc comment）
- `lean-formalization/Manifest/Axioms.lean` の T1–T8, `EmpiricalPostulates.lean` の E1–E2, `Principles.lean` の P1–P6

### Step 2: Provider プリミティブの列挙

Provider が持つ全プリミティブを列挙する。各プリミティブについて以下を整理する:

| プリミティブ | 永続性 | 強制力 | スコープ |
|------------|--------|--------|---------|
| （名前） | T1（セッション内）/ T2（永続） | 構造的 / 手続的 / 規範的 | ユーザー / プロジェクト / グローバル |

### Step 3: D1 マッピング — 強制のレイヤリング

マニフェストの各制約（T/E/P/L/V）を、Provider のプリミティブに配置する。

**配置ルール（D1 から導出）:**
- L1（倫理・安全）→ 構造的強制力を持つプリミティブに配置。規範的プリミティブのみでの L1 実装は **D1 違反**。
- P2（検証）→ 手続的強制力以上のプリミティブに配置。
- L6（設計規約）→ 規範的プリミティブでも可。

出力形式:

```markdown
### 強制レイヤー配置表

| 制約 | 強制レイヤー | Provider プリミティブ | 根拠 |
|------|------------|--------------------|----- |
| L1   | 構造的     | （具体名）          | D1: 固定境界は構造的強制 |
| P2   | 手続的     | （具体名）          | D1: 検証は手続的強制以上 |
| ...  | ...        | ...                | ... |
```

### Step 4: D2 マッピング — Worker/Verifier 分離

P2 の構造的実現方法を Provider のプリミティブで設計する。

**確認する3条件（D2）:**
1. コンテキスト分離: Worker と Verifier が異なるコンテキストで動作するか
2. バイアス非共有: Worker の中間状態が Verifier に漏洩しないか
3. 独立起動: Verifier が Worker から独立に起動されるか

Provider のプリミティブの中から、3条件を満たす構成を特定する。
満たせない場合は代替策を提案し、**残存リスクを明記する**。

### Step 5: D3 マッピング — 可観測性の実現

V1–V7 の各変数について、Provider 上での測定方法を設計する。

**各変数に対して D3 の3条件を確認:**
1. 現在値が測定可能か → どのプリミティブで測定するか
2. 劣化が検知可能か → 閾値と警告の仕組み
3. 改善が検証可能か → Before/After の比較手段

### Step 6: D4 に従ったフェーズ設計

D4 の5フェーズに従って、実装計画を構成する:

```
Phase 1: 安全基盤 (L1)
  目標: L1 制約が構造的に強制される状態
  成果物: （Provider 固有）
  受け入れテスト: （D5 に従う）
  完了時の自己適用: 以降の開発は L1 準拠で行われる

Phase 2: 検証基盤 (P2)
  目標: Worker/Verifier 分離が構造的に実現される状態
  成果物: （Provider 固有）
  受け入れテスト: （D5 に従う）
  完了時の自己適用: 以降の開発成果物は独立検証される

Phase 3: 可観測性 (P4)
  目標: V1–V7 が測定可能な状態
  成果物: （Provider 固有）
  受け入れテスト: （D5 に従う）
  完了時の自己適用: 以降の品質劣化が検知可能になる

Phase 4: 統治 (P3)
  目標: 知識統合が互換性分類を経て統治される状態
  成果物: （Provider 固有）
  受け入れテスト: （D5 に従う）
  完了時の自己適用: 以降の構造変更が統治される

Phase 5: 動的調整
  目標: 投資サイクルが機能し行動空間が動的に調整される状態
  成果物: （Provider 固有）
  受け入れテスト: （D5 に従う）
  完了時の自己適用: 完全マニフェスト準拠
```

### Step 7: D5 に従ったテストケース設計

各フェーズの受け入れテストを設計する。

**テストの種類（D5）:**
- **構造的テスト**: 構成の存在を確認（決定論的）
  - 例: 「Hook が登録されているか」「Verifier Agent が存在するか」
- **行動的テスト**: 実際に実行して結果を確認（確率的、T4 対応で複数回実行）
  - 例: 「L1 違反操作がブロックされるか」「Verifier が誤りを検出するか」

テスト設計の原則:
- 各 axiom/theorem に対して**違反シナリオ**と**準拠シナリオ**のペアを書く
- 形式仕様の各ケース（Lean の match 分岐、inductive の構成子）に対して、少なくとも1つのテストが対応すること。名前レベルの参照ではなく、ケースレベルの対応を確認する（FB-2 D5 三層断裂の教訓）
- テストは実装に先行する（テストファースト）
- テストが通過する = マニフェスト準拠の証拠

### Step 8: D6–D9 の検証

- **D6（三段設計）**: 境界→緩和策→変数の対応が Provider 上で明確か
- **D7（信頼の非対称性）**: 行動空間の拡張が段階的であるか、L1 防御が構造的か
- **D8（均衡探索）**: 拡張トリガーと**縮小トリガー**の両方が設計されているか
- **D9（メンテナンス）**: 計画自体の更新手順が含まれているか

### Step 8b: D10–D14 の検証

D10–D14 は D1–D9 を補完する設計定理。Provider マッピングにおいて以下を検証する。

#### D10（構造永続性）: T1 + T2

エージェントは一時的だが構造は永続する。

- Provider のプリミティブを **T1（セッション内で消滅）** と **T2（セッション跨ぎで永続）** に分類する
- 改善の蓄積は T2 プリミティブを通じてのみ可能
- T2 プリミティブで作成される構造は、**書いたエージェントの文脈なしに読める**か確認する

確認項目:
- [ ] 各プリミティブの T1/T2 分類が Step 2 の表に含まれている
- [ ] 設計判断・学習は T2 プリミティブに符号化される手順がある
- [ ] T1 プリミティブに蓄積された情報が消失するリスクが識別されている

#### D11（コンテキスト経済）: T3 + D1 + D3

コンテキスト（作業メモリ）は有限であり、全構造要素にコンテキストコストがある。

- D1 の強制レイヤーとコンテキストコストは**逆相関**する:
  構造的強制（低コスト）> 手続的強制（中コスト）> 規範的指針（高コスト）
- 規範的指針の肥大化は V2（コンテキスト効率）を直接劣化させる
- 構造的強制への昇格はコンテキスト経済の観点からも正当化される

確認項目:
- [ ] Provider の各プリミティブにコンテキストコスト（高/中/低）が割り当てられている
- [ ] 規範的指針の肥大化リスクが識別されている
- [ ] D3 に従い、コンテキストコストが測定可能である（V2 計測手段が Step 5 に含まれる）

#### D12（制約充足タスク設計）: P6 + T3 + T7 + T8

タスク遂行は有限リソース下の制約充足問題（CSP）である。

- 「常に小さく分割する」は原理ではない。制約値（コンテキスト余裕、時間、精度要求）に応じて最適粒度が異なる
- タスク分解・並列化は CSP の解であり、原理ではない
- タスク設計自体が P2 の検証対象

確認項目:
- [ ] Provider のタスク分割手段（サブエージェント、並列実行等）が列挙されている
- [ ] 分割粒度の判断基準が T3/T7/T8 の制約値に基づいている
- [ ] タスク設計の検証手順が Step 4 (D2) と連携している

#### D13（前提否定の影響波及）: P3 + Section 8 + T5

前提が否定されたとき、依存する全導出を特定し再検証する。

- Provider の依存追跡手段（バージョン管理、設定の依存関係、テストカバレッジ等）を特定する
- 条件付き公理系の仮定 (C/H) が失効した場合の影響波及パスを設計する
- TemporalValidity (#225) に基づき、仮定の見直しメカニズムを含める

確認項目:
- [ ] Provider 上での依存追跡手段が特定されている
- [ ] 前提変更時の影響集合の計算方法がある（手動 or 自動）
- [ ] 条件付き公理系の仮定に TemporalValidity（sourceRef, lastVerified, reviewInterval）が設定されている

#### D14（検証順序の制約充足性）: P6 + T7 + T8

有限リソース下では検証順序が結果に影響する。最適な順序は公理で定まらない。

- 検証順序の選択は P6 の CSP の一部
- 本プロジェクトの /research では fail-fast（リスク降順）を設計規約として採用
- 具体的な順序決定方法は L6（設計規約）レベルの判断

確認項目:
- [ ] Provider 上での検証順序の選択基準が明示されている
- [ ] 検証コストが非一様であることが認識されている
- [ ] 選択基準が L6 の設計規約として記録されている（公理として主張しない）

### Step 9b: Derivation Accuracy 測定 + Miss 分析（D17 Step 4）

**D17 state machine の Step 4 (validate) に該当。**

導出した設計判断 (DD) と Step 0 で収集した PD を比較し、accuracy を測定する。

#### 9b-1: PD との照合

各 PD を以下に分類:
- **Match**: DD が PD に直接対応
- **Partial**: 方向性は合致するが具体度が異なる
- **Miss**: DD にない（PD が導出されなかった）
- **Over-derivation**: DD にあるが PD にない

#### 9b-2: Miss の原因分類

各 Miss を D1 の 3 層スコープ判定で分類:

| 分類 | 判定基準 | 対処 |
|------|---------|------|
| **仮定不足** | 設計原理レベルだが CC 仮定がない | → FeedbackAction.addAssumption |
| **スコープ外** | 実装詳細、CLI/UX、外部プロトコル | → FeedbackAction.markOutOfScope |
| **構造的限界** | 公理系の存在論に概念がない（例: B4） | → 記録のみ、人間判断 (T6) |

#### 9b-3: FeedbackReport 生成

```markdown
### Derivation Accuracy Report

| 指標 | 値 |
|------|-----|
| Total PD | N |
| Match | N (X%) |
| Partial | N (X%) |
| Miss | N (X%) |
| Scoped PD | N |
| Scoped recall (match+partial) | X% |

### Miss 分析

| PD | 原因 | FeedbackAction |
|----|------|----------------|
| PD-N | 仮定不足: XXX | addAssumption("...") |
| PD-N | スコープ外: XXX | markOutOfScope("PD-N") |
| PD-N | 構造的限界: XXX | (記録のみ) |

### 判定

**収束条件**: miss のうち「仮定不足」に分類されるものが **0 件** → 収束。
残存する miss は「スコープ外」と「構造的限界」のみ。
「仮定不足」が 1 件以上 → /instantiate-model に FeedbackReport を渡してループ。
```

#### 9b-4: フィードバックループ

miss に「仮定不足」が残存する場合:
1. addAssumption アクションを /instantiate-model に渡す
2. /instantiate-model が仮定を追加して条件付き公理系を再構築
3. 再構築された条件付き公理系で Step 3 (derive) からやり直す
4. iteration 上限: 3 回（D15a: retry bound）。上限到達時は残存を人間に委ねる (T6)

## 出力

以下の構成の設計実装計画書を生成する:

```markdown
# 設計実装計画書: [Provider 名]

## 0. Provider 仕様調査結果
（Step 0 の結果: 確認済み仕様、想定と実態の乖離、PoC 結果）

## 1. Provider プリミティブ一覧
（Step 2 の結果）

## 2. 強制レイヤー配置表
（Step 3 の結果: 全 T/E/P/L → Provider プリミティブの対応）

## 3. Worker/Verifier 分離設計
（Step 4 の結果: 3条件の充足状況と構成）

## 4. 可観測性設計（V1–V7 測定方法）
（Step 5 の結果: 各 V の測定手段）

## 5. フェーズ別実装計画
（Step 6 の結果: Phase 1–5 の具体的成果物とテスト）

## 6. テストケース一覧
（Step 7 の結果: 各フェーズの構造的/行動的テスト）

## 7. D6–D14 チェックリスト
（Step 8 + 8b の結果）

## 8. リスクと未解決事項
（Provider の制約により D が完全に実現できない場合の記録）

## 9. 自己適用の検証結果
（Step 9 の結果: D2/D4/D9 の自己適用状況）
```

### Step 9: 自己適用の検証（Section 7 + SelfGoverning）

**このステップは出力の検証ではなく、生成プロセス自体の検証。**

DesignFoundation.lean の `SelfGoverning` typeclass が要求するように、
設計実装計画書を生成する行為自体が D1–D18 に従っているかを検証する。

確認項目:

1. **D2 自己適用**: この計画書は誰が検証したか？生成者（Worker）と検証者（Verifier）は分離されているか？
   - 計画書の生成後、独立した検証（人間レビューまたは別エージェント）を経るべき
   - 自己レビュー（生成した AI が自分で品質基準をチェック）は E1 違反

2. **D4 自己適用**: この計画書の生成は、どの DevelopmentPhase に属するか？
   - 計画書の生成は Phase 1（安全基盤）に先立つ設計行為
   - したがって、計画書生成時点では L1 の構造的強制はまだない
   - この制約を明記し、Phase 1 完了後に計画書を再検証する手順を含める

3. **D9 自己適用**: この Skill 自身の更新手順は定義されているか？
   - 以下の「Skill 自身のメンテナンス」セクションで定義する

## Skill 自身のメンテナンス（D9 自己適用）

このスキルは `SelfGoverning` の原則に従い、自身の更新を統治する。

### 更新トリガー

以下のいずれかが発生した場合、このスキルの更新を検討する:

- `docs/design-development-foundation.md` の D1–D18 に変更があった
- `DesignFoundation.lean` に新しい型・定理が追加された
- テスト実行で品質基準を満たさない出力が繰り返し生成された
- 新しい Provider への適用で、Step 2–8 が不十分であることが判明した
- `SelfGoverning` typeclass の要件が変更された

### 更新の互換性分類

スキルの変更を P3 の互換性分類で分類する:

- **保守的拡張**: Step の説明の明確化、例の追加、新しい品質基準の追加
- **互換的変更**: Step の順序変更なしでの内容修正、出力フォーマットの微修正
- **破壊的変更**: Step の追加・削除・順序変更、出力フォーマットの構造変更、品質基準の削除

### 更新の検証

更新後、以下を実施する:
1. 既存のテストケース（Claude Code 等）で再実行し、品質基準を満たすことを確認
2. 更新内容が `DesignFoundation.lean` の `SelfGoverning` 要件と整合することを確認
3. 破壊的変更の場合、既存の設計実装計画書への影響を評価する

## 品質基準

### 出力に対する品質基準

生成された計画書は以下を満たすこと:

- [ ] Provider の仕様が公式ドキュメントに基づいて調査されている（Step 0a）
- [ ] リスクの高い構成について PoC が実施されている（Step 0c）
- [ ] 想定と実態の乖離が記録されている（Step 0d）
- [ ] D1–D18 の全原理が Provider プリミティブにマッピングされている
- [ ] L1 が構造的強制で実装されている（D1）
- [ ] P2 が3条件を満たす形で実現されている（D2）
- [ ] V1–V7 の各変数に測定方法が割り当てられている（D3）
- [ ] フェーズ順序が D4 の依存構造に従っている
- [ ] 各フェーズに受け入れテストがある（D5）
- [ ] 各 Lean 形式仕様（axiom/theorem）に対応するテストケースが特定されている（D5: 形式仕様→テスト）
- [ ] 三者間の対応が逆引き可能な表として提供されている（D5 + Section 8: 順序情報の自己内包）
- [ ] 三段設計（境界→緩和策→変数）が明示されている（D6）
- [ ] 拡張と縮小の両トリガーがある（D8）
- [ ] 計画自体の更新手順が含まれている（D9）

### プロセスに対する品質基準（Section 7 自己適用）

生成プロセス自体が以下を満たすこと:

- [ ] 計画書は生成者以外によって検証される（D2: Worker/Verifier 分離）
- [ ] 計画書が属する DevelopmentPhase が明示されている（D4）
- [ ] Phase 1 完了後の再検証手順が含まれている（D4 自己適用）
- [ ] Skill 自身の更新トリガーと互換性分類が定義されている（D9 自己適用）

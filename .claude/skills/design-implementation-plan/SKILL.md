---
name: design-implementation-plan
description: >
  Generate a manifest-compliant design implementation plan for any platform.
  Maps D1–D9 design principles to provider primitives (Claude Code, GitHub Actions,
  CI/CD, etc.) with phased roadmap, test cases, and V1–V7 measurement design.
  Use this skill whenever the user wants to: create an implementation plan or roadmap
  for the manifesto, apply L1–L6 or V1–V7 to a real environment, map D1–D9 to a
  specific provider, design Worker/Verifier separation, plan phased implementation,
  set up manifest compliance for a project, or asks "what should we implement first".
  Always use this for any request about building or designing a manifest-compliant system.
---

# Design Implementation Plan Generator

マニフェスト準拠システムの設計実装計画書を、指定された Provider に最適化して生成する。

## 前提知識

このスキルは以下のファイルを参照する:

1. `docs/design-development-foundation.md` — D1–D9 の設計開発基礎論（プラットフォーム非依存）
2. `lean-formalization/Manifest/DesignFoundation.lean` — D1–D9 の Lean 形式検証（`SelfGoverning` typeclass, `DesignPrinciple` 型を含む）
3. `lean-formalization/Manifest/Ontology.lean` — `SelfGoverning` typeclass の定義（Section 7 の構造的強制メカニズム）
4. `manifesto.md` — 公理系の原典（T/E/P）
5. `lean-formalization/Manifest/Ontology.lean` — 境界条件（L1–L6）の定義と詳細
6. `lean-formalization/Manifest/Observable.lean` — 変数（V1–V7）の定義と詳細

**重要:** `SelfGoverning` typeclass は、原理を定義する型が自己適用（Section 7）を
型レベルで強制するメカニズムである。このスキルが生成する計画書、
およびこのスキル自身も、この原則に従う。

## 入力

ユーザーから以下を受け取る:

- **Provider 名**: 対象プラットフォーム（例: Claude Code, GitHub Actions, 任意のCI/CD）
- **Provider のプリミティブ一覧**（任意）: Provider が持つ機能の一覧。省略された場合は Provider 名から推定するか、ユーザーに確認する。

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

#### 0c: PoC（Proof of Concept）

D1 マッピングのうち、最もリスクが高い構成（= 想定通りに動かない可能性が高いもの）について、
最小限の PoC を作成して実際に動作確認する。

**PoC で検証すべきこと:**
- 構造的強制のプリミティブ（例: Hook）が、想定した入力に対して想定した出力を返すか
- ブロック/許可の判定が実際のランタイムで機能するか
- D2（Worker/Verifier 分離）の実現に必要なプリミティブ間連携が動作するか

**PoC の結果を記録する。** 想定と実態の乖離があれば、Step 2 以降の設計に反映する。
乖離が大きい場合は、マッピング戦略自体を見直す。

#### 0d: 調査結果のサマリ

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

- `docs/design-development-foundation.md` の D1–D9 全文
- `lean-formalization/Manifest/Ontology.lean` の L1–L6（境界条件セクションの doc comment）
- `lean-formalization/Manifest/Observable.lean` の V1–V7（変数セクションの doc comment）
- `manifesto.md` の T1–T8, E1–E2, P1–P6

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
- テストは実装に先行する（テストファースト）
- テストが通過する = マニフェスト準拠の証拠

### Step 8: D6–D9 の検証

- **D6（三段設計）**: 境界→緩和策→変数の対応が Provider 上で明確か
- **D7（信頼の非対称性）**: 行動空間の拡張が段階的であるか、L1 防御が構造的か
- **D8（均衡探索）**: 拡張トリガーと**縮小トリガー**の両方が設計されているか
- **D9（メンテナンス）**: 計画自体の更新手順が含まれているか

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

## 7. D6–D9 チェックリスト
（Step 8 の結果）

## 8. リスクと未解決事項
（Provider の制約により D が完全に実現できない場合の記録）

## 9. 自己適用の検証結果
（Step 9 の結果: D2/D4/D9 の自己適用状況）
```

### Step 9: 自己適用の検証（Section 7 + SelfGoverning）

**このステップは出力の検証ではなく、生成プロセス自体の検証。**

DesignFoundation.lean の `SelfGoverning` typeclass が要求するように、
設計実装計画書を生成する行為自体が D1–D9 に従っているかを検証する。

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

- `docs/design-development-foundation.md` の D1–D9 に変更があった
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
- [ ] D1–D9 の全原理が Provider プリミティブにマッピングされている
- [ ] L1 が構造的強制で実装されている（D1）
- [ ] P2 が3条件を満たす形で実現されている（D2）
- [ ] V1–V7 の各変数に測定方法が割り当てられている（D3）
- [ ] フェーズ順序が D4 の依存構造に従っている
- [ ] 各フェーズに受け入れテストがある（D5）
- [ ] 三段設計（境界→緩和策→変数）が明示されている（D6）
- [ ] 拡張と縮小の両トリガーがある（D8）
- [ ] 計画自体の更新手順が含まれている（D9）

### プロセスに対する品質基準（Section 7 自己適用）

生成プロセス自体が以下を満たすこと:

- [ ] 計画書は生成者以外によって検証される（D2: Worker/Verifier 分離）
- [ ] 計画書が属する DevelopmentPhase が明示されている（D4）
- [ ] Phase 1 完了後の再検証手順が含まれている（D4 自己適用）
- [ ] Skill 自身の更新トリガーと互換性分類が定義されている（D9 自己適用）

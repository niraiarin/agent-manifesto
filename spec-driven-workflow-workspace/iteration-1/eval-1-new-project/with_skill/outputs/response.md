# IoT デバイス監視システム: 仕様駆動開発ワークフロー

## 結論: Phase 0（設計）から始める

仕様駆動開発では、実装もテストも後回しにし、まず **条件付き公理系（Lean 設計書）** を生成するところから始めます。以下に具体的な手順を示します。

---

## Phase 0: 設計 -- 条件付き公理系の生成

### Step 0-1: ビジョンの聞き取り (`/instantiate-model`)

最初に `/instantiate-model` を実行してください。対話的にプロジェクトのビジョンを引き出します。

```
/instantiate-model
```

このスキルが以下を段階的に聞き取ります:

- **ドメイン**: IoT デバイス監視、センサーデータの異常検知
- **制約**: 物理的制約（センサーの精度・遅延）、法的制約（データ保護）、契約的制約（SLA）
- **仮定**: 未検証の前提（例: センサーは常に正常なデータ形式を送る、ネットワーク遅延は N ms 以下）

異常検知に特有の聞き取り項目の例:

| 項目 | 質問例 |
|---|---|
| 異常の定義 | 閾値超過? 統計的外れ値? パターン逸脱? |
| 検知の時間要件 | リアルタイム? バッチ? 許容遅延は? |
| 誤検知の許容度 | False positive と false negative のどちらが深刻か? |
| センサー種別 | 温度・振動・電流など、何種類のセンサーか? |
| データ量 | デバイス数、サンプリングレート |

### Step 0-2: Gap Analysis (`/research`)

技術的ギャップを構造化します。

```
/research
```

IoT 異常検知で典型的な調査項目:

- 異常検知アルゴリズムの選定（統計的手法 vs ML）
- リアルタイム処理基盤（ストリーム処理 vs バッチ）
- センサーデータのプロトコル（MQTT, CoAP, HTTP）
- 既存の異常検知ライブラリ/フレームワーク

`/research` は Parent Issue + Sub-Issues（Gate 付き）を GitHub に生成します。各 Sub-Issue の Gate 判定が PASS になるまで Phase 1 には進みません。

### Step 0-3: 条件付き公理系の生成

`/instantiate-model` が以下のような Lean 文書を出力します:

```
出力先: lean-formalization/Manifest/Project/IoTMonitoring.lean
```

公理系の構造:

```
T_0 (基底理論: T1-T8, E1-E2)
  union Gamma\T_0 (プロジェクト固有の条件)
    |- D_IoTMonitoring (導出される義務)
```

プロジェクト固有の条件 (Gamma\T_0) の例:

- `axiom sensor_data_finite : ...` -- センサーデータは有限精度
- `axiom anomaly_decidable : ...` -- 異常は判定可能
- `axiom detection_latency_bounded : ...` -- 検知遅延に上限がある
- `axiom false_positive_rate_bounded : ...` -- 誤検知率に上限がある

### Step 0-4: 保存拡大性の確認

```bash
cd lean-formalization
export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest
```

チェック項目:
- 0 sorry で通ること
- 全 axiom に Axiom Card（Layer / Basis / Refutation condition）があること
- 新規 axiom が T_0 と矛盾しないこと

---

## Phase 1: テスト計画 -- 命題からのテスト導出

Phase 0 の条件付き公理系が完成したら、各命題に対応するテストケースを設計します。

### テスト設計の例

```bash
# @traces sensor_data_finite
check "sensor data precision within bounds" ...

# @traces anomaly_decidable
check "anomaly detection returns definite result" ...

# @traces detection_latency_bounded
check "detection completes within SLA" ...
```

### カバレッジ確認

```bash
bash scripts/trace-coverage.sh
# Coverage: N / M (100%) を目指す
```

全命題に少なくとも1つのテストが対応するまで Phase 2 に進まないこと。

---

## Phase 2: 実装 -- TDD で構築

テストが先、実装が後。

1. **Red**: テストを書く（まだ FAIL する）
2. **Green**: テストが通る最小の実装を書く
3. **Refactor**: コード品質を改善

成果物を `artifact-manifest.json` に登録:

```json
{
  "id": "service:anomaly-detector",
  "refs": ["anomaly_decidable", "detection_latency_bounded"],
  "path": "src/anomaly_detector.py"
}
```

---

## Phase 3: 検証 -- 閉環の確認

```bash
# カバレッジ確認
bash scripts/trace-coverage.sh

# 半順序違反検出
manifest-trace violations

# 全体健全性
manifest-trace health

# 独立検証
/verify

# Lean ビルド
export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest

# 全テスト
bash tests/test-all.sh
```

コミット時は互換性分類を付与:

```
git commit -m "IoT Monitoring: 異常検知の条件付き公理系を追加 (conservative extension)"
```

---

## Phase 4: 保守 -- 変更影響の追跡

運用開始後、公理を変更する場合:

```bash
# 影響範囲を特定
manifest-trace impact anomaly_decidable

# 影響テストを再実行
bash tests/test-all.sh

# メトリクス確認
/metrics
```

---

## まとめ: 最小実行パス

```
/instantiate-model        <-- Phase 0: ビジョン聞き取り + 公理系生成
  |
/research                 <-- Phase 0: Gap Analysis (異常検知手法の調査)
  |
lake build Manifest       <-- Phase 0: 保存拡大性の確認
  |
テスト作成 + # @traces    <-- Phase 1: 各命題にテストを対応付け
  |
trace-coverage.sh         <-- Phase 1: カバレッジ 100% を確認
  |
実装 + artifact-manifest  <-- Phase 2: TDD で実装
  |
manifest-trace violations <-- Phase 3: 閉環トレーサビリティ検証
/verify                   <-- Phase 3: 独立検証
  |
git commit (with compat)  <-- 互換性分類付きコミット
```

## 最初の一手

今すぐ以下を実行してください:

```
/instantiate-model
```

対話が始まり、IoT 監視システムの要件・制約・仮定を整理して、条件付き公理系の骨格を生成します。自然言語の要件定義書ではなく、Lean の型検査が通る公理系が設計書になる点が、このワークフローの核心です。

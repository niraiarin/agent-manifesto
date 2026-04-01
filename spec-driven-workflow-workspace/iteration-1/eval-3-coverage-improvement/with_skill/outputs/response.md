# trace-coverage.sh 19% → 100% への改善計画

## 現状分析

```
Coverage: 7 / 36 (19.4%)
Uncovered: T1 T2 T3 T4 T5 T7 T8 E1 E2 P1 P2 P3 P5 P6 L2 L3 L4 L6
           D2 D3 D4 D6 D7 D8 D9 D10 D12 D13 D14
```

- **方式A**（`# @traces` アノテーション）: Phase 1 の `test-l1-structural.sh` のみ（10件）
- **方式B**（`trace-map.json`）: Phase 1 の2ファイルのみ（23テストケース）
- **Phase 2-5**: 合計 196 テストケースが存在するが、`# @traces` も `trace-map.json` エントリもゼロ

## 根本原因

テスト自体は既に存在している。不足しているのはテストではなく **トレーサビリティ・アノテーション** のみ。つまり「テストが命題を検証しているという宣言」が欠けている。

## 推奨アプローチ: 2段階で進める

### 第1段階: 既存テストへのアノテーション追加（主要作業）

SKILL.md の Phase 1 手順に従い、既存テストに `# @traces` と `trace-map.json` エントリを追加する。テストを新たに書く必要はほぼない。

#### ファイル別の作業計画

| ファイル | テスト数 | 対応する命題（推定） | 工数目安 |
|---|---|---|---|
| `phase2/test-p2-structural.sh` | 8 | **P2**, E1, D2 | 15分 |
| `phase2/test-p2-behavioral.sh` | 0* | P2 | 別途確認 |
| `phase3/test-phase3-structural.sh` | 27 | **P4**, D11, **P3**, D1 | 30分 |
| `phase3/test-metrics-structural.sh` | 18 | **P4**, D11 (V1-V7基盤) | 20分 |
| `phase3/test-phase3-behavioral.sh` | 0* | P4 | 別途確認 |
| `phase4/test-phase4-structural.sh` | 6 | **P3**, D4 | 10分 |
| `phase4/test-phase4-behavioral.sh` | 0* | P3 | 別途確認 |
| `phase5/test-depgraph.sh` | 87 | **D13**, D4, D12 | 60分 |
| `phase5/test-axiom-quality.sh` | 9 | **E2**, T8, D9 | 15分 |
| `phase5/test-dynamic-structural.sh` | 7 | **D8**, L4, D7 | 10分 |
| `phase5/test-dynamic-behavioral.sh` | 6 | **D8**, D7 | 10分 |
| `phase5/test-scripts-structural.sh` | 18 | D11, D13, P4 | 20分 |
| `phase5/test-research-structural.sh` | 0* | P3 | 別途確認 |
| `phase5/test-evolve-structural.sh` | 0* | P3, D9 | 別途確認 |
| `phase5/test-l5-ssot-structural.sh` | 0* | **L5** | 別途確認 |

*（`check` 関数を使わない形式、または空ファイルの可能性あり。`check_block`/`check_allow` 等の別関数名の可能性もある）

#### 各テストファイルでの作業手順

1. テストファイルを読み、各 `check` の内容が **どの命題を検証しているか** を判定する
2. `# @traces <命題ID>` を各 `check` の直前行に追加する
3. `trace-map.json` の `mapping` に当該ファイルのエントリを追加する
4. `bash scripts/trace-coverage.sh` で進捗確認

**具体例**（`phase2/test-p2-structural.sh` の場合）:

```bash
# 変更前:
check "S2.1 Verifier agent definition exists" \
  "[ -f '$BASE/.claude/agents/verifier.md' ]"

# 変更後:
# @traces P2,E1
check "S2.1 Verifier agent definition exists" \
  "[ -f '$BASE/.claude/agents/verifier.md' ]"
```

`trace-map.json` への追加:
```json
"phase2/test-p2-structural.sh": {
  "S2.1": { "primary": "P2", "secondary": ["E1"] },
  "S2.2": { "primary": "P2", "secondary": ["E1"] },
  ...
}
```

### 第2段階: カバレッジギャップの解消

第1段階完了後に `trace-coverage.sh` を再実行し、まだ UNCOVERED な命題を特定する。

以下の命題は既存テストだけではカバーが難しい可能性がある:

| 命題 | 内容 | 対策 |
|---|---|---|
| **T1** (一時性) | インスタンスの一時性 | Phase 5 の evolve/dynamic テストに紐づけるか、新規テスト |
| **T2** (構造の永続性) | 構造がインスタンスより長く生きる | テストの存在自体が T2 の証拠 → メタテスト |
| **T3** (蓄積の場所) | 改善は構造の中に蓄積 | evolve-structural で紐づけ可能 |
| **T4** (意図の不在) | エージェントに意図はない | 概念的命題 → Lean theorem で十分か判断 |
| **T5** (構造的強制) | 強制は構造で行う | Phase 1 の hook テストで紐づけ可能 |
| **T7** (破壊の不可逆性) | 信頼の蓄積は不可逆 | 概念的 → Lean 定理で代替可能 |
| **P1** (不可分性) | 効率と安全はトレードオフしない | L1 テストの一部を紐づけ |
| **P5** (確率的解釈) | 確率 < 1 の世界 | behavioral テストに紐づけ可能 |
| **P6** (可逆的選好) | 選好は可逆 | adjust-action-space テストに紐づけ |
| **L2** (冗長性) | 二重防御 | Phase 1 の hook + deny テストに紐づけ |
| **L3** (透明性) | 操作の透明性 | metrics テストに紐づけ可能 |
| **L6** (帰属) | 構造への帰属 | Lean build テストに紐づけ |
| **D6** (経時安定) | 長期安定性 | P3 互換性分類テストに紐づけ |
| **D10** (構造的保証) | 仕組みで保証する | hook テストに紐づけ |
| **D14** (表現標準) | Axiom Card 標準 | axiom-quality テストに紐づけ |

**方針**: 既存テストの範囲で紐づけられる命題を最大限紐づけた上で、どうしてもカバーできない概念的命題（T4, T7 等）については:
- Lean 形式証明（theorem）がテストの代替として機能するか評価する
- 必要なら最小限のメタテストを新規追加する

## 実行順序の推奨

spec-driven-workflow の Phase 順序に従い、以下の順で進める:

```
1. Phase 2 テスト (8件)          ← P2, E1 がカバーされる → 最も簡単
2. Phase 3 テスト (45件)         ← P3, P4 がカバーされる → 中核
3. Phase 4 テスト (6件)          ← P3, D4 の追加カバー
4. Phase 5 テスト (127件)        ← D8, D9, D13 等の大量カバー → 最大工数
5. ギャップ分析 + 補完テスト     ← 残り命題の対処
```

各ステップ後に `trace-coverage.sh` を実行して進捗を確認する。

## 工数見積もり

| 作業 | 見積もり |
|---|---|
| 第1段階: アノテーション追加 (196件) | 3-4時間 |
| 第2段階: ギャップ分析 + 補完 | 1-2時間 |
| trace-map.json 整合性確認 | 30分 |
| **合計** | **5-7時間** |

当初の11時間見積もりより短い理由: テストの新規作成は不要で、アノテーション追加はパターン化された機械的作業が中心であるため。

## 自動化の余地

アノテーション追加作業の大部分は機械的判断で可能:
- ファイル名に `p2` → P2、`phase3` + `metrics` → P4、`depgraph` → D13 といったヒューリスティック
- テスト名に含まれるキーワード（`compatibility` → P3、`deny` → L1 等）

スクリプトで候補を自動生成し、人間がレビューする方式が最も効率的。

## チェックポイント（SKILL.md Phase 1 準拠）

- [ ] 全命題に少なくとも1つのテストが対応（`trace-coverage.sh` で 100%）
- [ ] 高強度命題（T/E、strength >= 4）は複数テストでカバー
- [ ] `trace-map.json` が全 Phase のテストを含む
- [ ] `# @traces` アノテーションと `trace-map.json` の整合性が取れている

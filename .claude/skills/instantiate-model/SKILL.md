---
name: instantiate-model
description: >
  認識論的層モデルのインスタンシエーション・ワークフロー。人間のプロジェクトの
  ビジョンを聞き取り、要件・仮定・制約を引き出し、EpistemicLayerClass の
  公理体系に準拠した条件付き公理体系を Lean 文書として生成する。
  「モデル生成」「instantiate」「層モデル」「条件付き公理」「公理体系を生成」で起動。
---

# /instantiate-model

> **Portability: repo-only** — このスキルは agent-manifesto リポジトリ内でのみ動作する。
> .claude/agents/model-questioner.md、lean-formalization/Manifest/Models/ への深い依存があり、plugin 単体での利用は不可。

認識論的層モデルのインスタンシエーション・ワークフロー。

人間のプロジェクトのビジョンを聞き取り、要件・仮定・制約を引き出し、
EpistemicLayerClass の公理体系に準拠した条件付き公理体系を Lean 文書として生成する。

## 起動トリガー

「モデル生成」「instantiate」「層モデル」「条件付き公理」「公理体系を生成」で起動。

## ワークフロー概要

```
Phase 0: ビジョンの聞き取り
  ↓
Phase 1: 要件・仮定・制約の引き出し
  ↓
Phase 2: LLM 内部で構造推論 + 公理系照合
  ↓ 矛盾あり → Phase 3 → Phase 1 or 2 に戻る
  ↓ 矛盾なし
ModelSpec JSON 生成
  ↓
check-monotonicity.sh（事前検証）
  ↓ 違反あり → 修正（H なら自律、C なら Phase 3）→ 再検証
  ↓ 違反なし
generate-conditional-axiom-system.sh（Lean 生成）
  ↓
lake build（最終検証）
  ↓ 失敗 → フィードバック → 修正 → 再生成
  ↓ 成功
✓ 完了（git commit 提案）
```

## 使用するコンポーネント

### エージェント

- `.claude/agents/model-questioner.md` — Phase 0-3 の対話と推論

### スクリプト（コードによるルール）

- `lean-formalization/Manifest/Models/extract-dependency-graph.sh` — 依存グラフ抽出
- `lean-formalization/Manifest/Models/check-monotonicity.sh` — 単調性事前検証
- `lean-formalization/Manifest/Models/generate-conditional-axiom-system.sh` — Lean コード生成

### Lean ファイル（入力/出力）

- `lean-formalization/Manifest/EpistemicLayer.lean` — 公理体系 (A)。**Read-only**
- `lean-formalization/Manifest/Models/Assumptions/EpistemicLayer.lean` — 仮定の蓄積 (C∪H)
- `lean-formalization/Manifest/Models/ConditionalAxiomSystem.lean` — 条件付き公理体系 (D)

## 実行手順

### Step 1: 対話（Phase 0-1）

model-questioner エージェントを起動し、人間との対話を行う。

```
Phase 0: 「どんなものを作ろうとしていますか？」
Phase 1: 回答から要件・仮定・制約を引き出す
```

### Step 2: 構造推論（Phase 2）

model-questioner エージェントの Phase 2 を実行する。
内部で依存グラフ抽出と公理系照合を行う。

```bash
# 依存グラフの抽出（Phase 2 の入力）
bash lean-formalization/Manifest/Models/extract-dependency-graph.sh
```

### Step 3: 矛盾解消（Phase 3、必要な場合のみ）

Phase 2 で矛盾が検出された場合、人間に平易な言葉で確認する。

### Step 4: ModelSpec JSON の生成

Phase 2 の出力を JSON ファイルに書き出す。

### Step 5: 事前検証

```bash
bash lean-formalization/Manifest/Models/check-monotonicity.sh -f model-spec.json
```

- 違反あり + justification が H のみ → LLM が自律修正して再検証
- 違反あり + justification に C 含む → Phase 3 に戻る
- 違反なし → Step 6 へ

### Step 6: Lean コード生成 + 検証

```bash
bash lean-formalization/Manifest/Models/generate-conditional-axiom-system.sh \
  -f model-spec.json \
  -o lean-formalization/Manifest/Models/ConditionalAxiomSystem.lean
```

自動で `lake build` が実行される。失敗したら Step 5 に戻る。

### Step 7: Assumptions の更新

Phase 1-3 で得た C と H を `Assumptions/EpistemicLayer.lean` に書き出す。

### Step 8: 完了

git commit を提案する（人間の承認を待つ）。

## S=(A,C,H,D) の追跡

| 概念 | ファイル | 管理 |
|------|---------|------|
| A (公理体系) | EpistemicLayer.lean | Read-only |
| C (人間判断) | Assumptions/EpistemicLayer.lean `[C]` | Phase 1 で蓄積 |
| H (LLM推論) | Assumptions/EpistemicLayer.lean `[H]` | Phase 2 で蓄積 |
| D (導出) | ConditionalAxiomSystem.lean | 生成スクリプトで出力 |

C と H は Lean の `EpistemicSource` 型で型レベルで区別される。

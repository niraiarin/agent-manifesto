# instantiate-model

認識論的層モデルのインスタンシエーション・ワークフロー。

人間のプロジェクトのビジョンを聞き取り、要件・仮定・制約を引き出し、
EpistemicLayerClass の公理体系に準拠した条件付き公理体系を Lean 文書として生成する。

## 起動トリガー

`/instantiate-model` または「モデル生成」「instantiate」「層モデル」「条件付き公理」「公理体系を生成」

## ワークフロー

```
Phase 0: ビジョンの聞き取り
  ↓
Phase 1: 要件・仮定・制約の引き出し
  ↓
Phase 2: LLM 内部で構造推論 + 公理系照合
  ↓ 矛盾あり → Phase 3 → Phase 1 or 2 に戻る
  ↓ 矛盾なし
Phase 3: 条件付き公理体系の生成（Lean 文書）
```

## 出力

EpistemicLayerClass に準拠した条件付き公理体系（Lean 4 ファイル）

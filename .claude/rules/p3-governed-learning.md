---
paths: ["**"]
---

<!-- @traces P3, D13 -->

# P3: 学習の統治

知識統合のライフサイクル: 観察 → 仮説化 → 検証 → 統合 → 退役

## 互換性分類

構造（.claude/, tests/, manifesto 関連ファイル）を変更する場合、
コミットメッセージに以下のいずれかを含めること:

- **conservative extension**: 既存が全てそのまま有効。追加のみ
- **compatible change**: 既存ワークフローは継続可能。一部前提が変化
- **breaking change**: 既存ワークフローの一部が無効。移行パスを明記

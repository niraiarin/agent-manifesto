# trace

全成果物の半順序導出・カバレッジ検出・逸脱検出スキル。

P4（可観測性）+ D13（影響波及）の運用ツール。
公理系から実装が漏れている状況、実装が公理系から逸脱している状況を
自動的・機械的に検出する。

## 起動トリガー

`/trace` または「トレース」「カバレッジ」「coverage」「逸脱」「deviation」「半順序」「partial order」

## 検出対象

- **カバレッジギャップ**: 公理系に定義があるが実装が存在しない
- **逸脱**: 実装が公理系の定義から外れている

## 対象成果物

hooks, skills, agents, rules, tests と公理系（T/E/P/L/D）の半順序関係を導出する。

## Lean 形式化との対応

- 命題間半順序 (`PropositionId.dependencies`)
- 認識論的強度 (`PropositionCategory.strength`)
- D13 影響波及 (`d13_propagation`, `affected`)
- 推移的依存 (`TransitivelyDependsOn`)

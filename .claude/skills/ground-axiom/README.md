# ground-axiom

公理の数学的根拠を検証し、形式証明とトレーサビリティを確立するスキル。

各 axiom について (1) 根拠となる数理理論を特定、(2) 核心的定理を Lean で形式証明、
(3) Axiom Card に導出チェーンを記載、(4) 降格可能なら降格する。

## 起動トリガー

`/ground-axiom` または「公理の根拠」「数学的裏付け」「axiom grounding」「公理検証」

## パターン

| パターン | 内容 | 結果 |
|---------|------|------|
| 根拠検証 | 数理理論の特定 → Lean 形式証明 → Axiom Card 記載 | axiom 維持、根拠明示 |
| 型制約埋め込み | 構造体に不変条件を追加 → axiom が自明に | axiom → theorem 降格 |

## 背景

GitHub Issue #157（公理系の数理的基盤整備）の中核プロセス。
T4 (`output_nondeterministic`) で確立されたパターンを全 axiom に適用する。

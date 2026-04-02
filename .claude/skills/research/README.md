# research

Gate-Driven Research Workflow を実行する P3（学習の統治）の運用インスタンス。

実装前の技術的リサーチを構造化された手順で進める。

## 起動トリガー

`/research` または「リサーチ」「調査」「研究」「Gap Analysis」

## ワークフロー

```
Gap Analysis → Parent Issue → Sub-Issues (with Gates)
                                  ↓
                          Git Worktree (isolated)
                                  ↓
                          Experiment → Results (issue comment)
                                  ↓
                          Gate Judgment
                         ╱      │       ╲
                      PASS  CONDITIONAL  FAIL
                       │        │         │
                     Close   Sub-issue  Escalate
```

## 特徴

- 各サブイシューに Gate（合否判定基準）を設定
- Git Worktree で隔離された実験環境を使用
- 実験結果を GitHub Issue コメントに記録
- Gate 判定で PASS/CONDITIONAL/FAIL を判断

---
paths: ["**"]
---

# L1 補強: Sandbox の推奨

Trail of Bits の知見（Step 0b）:
「sandbox なしでは deny rules は Bash コマンドをバイパスできる」

## 推奨設定

settings.json に以下を追加することで、deny rules が OS レベルで強制される:

```json
{
  "sandbox": {
    "enabled": true,
    "pathPrefixes": [
      "/path/to/project"
    ]
  }
}
```

## 現状

- Hooks が主防衛線（Phase 1 PoC で検証済み）
- deny rules は補助的（間接実行でバイパス可能 — PoC 3）
- Sandbox はさらなる深層防御として推奨されるが、環境依存のため自動有効化しない

## 有効化の判断

sandbox の有効化は人間の判断で行う（T6）。
有効化すると Bash コマンドの実行がプロジェクトディレクトリに制限される。

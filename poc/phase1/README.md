# Phase 1 PoC: Hook 動作検証

## 検証項目

1. PreToolUse Hook が exit 2 で実際にツール実行をブロックするか
2. exit 0 + JSON (permissionDecision: ask) で確認プロンプトが出るか
3. deny rules が sandbox なしでどこまで有効か
4. Hook の stderr メッセージがユーザーに表示されるか

## 実行方法

各 PoC は `claude -p` (headless) で実行し、結果を記録する。

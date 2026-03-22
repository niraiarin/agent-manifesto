# Step 0c: PoC 結果

## PoC 1: PreToolUse exit 2 ブロック
- **結果: PASS**
- exit 2 でツール実行がブロックされ、Claude は「blocked by hook」と認識
- stderr メッセージが Claude のコンテキストに入る

## PoC 2: permissionDecision: ask
- **結果: PASS（条件付き）**
- exit 0 + JSON `ask` は機能する
- headless + allowedTools では自動許可される（interactive でのみ確認表示）

## PoC 3: deny rules のバイパス
- **結果: deny rules は間接実行をブロックしない**
- `echo DENIED_TEST` → deny が機能（permission_denials に記録）
- `bash -c 'echo DENIED_TEST'` → deny をバイパス（モデルが自主拒否したが構造的保証なし）
- **教訓: deny rules だけでは L1 の構造的強制にならない。Hook による内容検査が必須**

## PoC 4: stderr メッセージ + 選択的ブロック
- **結果: PASS**
- Hook が stdin の JSON を読み、コマンド内容を検査してブロック/許可を判定
- stderr のメッセージが Claude に伝わり、ブロック理由を認識

## Phase 1 再設計への含意

1. **deny rules は補助的。Hook が主要な強制手段。** deny rules は「明らかに危険なパターン」の第一防衛線だが、バイパス可能。Hook が stdin の JSON からコマンド内容を解析して判定する構成が必要。
2. **exit 2 + stderr が正しいブロックパターン。** stdout の JSON は exit 2 時に無視される。ブロック理由は stderr に書く。
3. **exit 0 + JSON permissionDecision は機能する。** ask（確認要求）、allow（許可）、deny（拒否）の3状態が使える。
4. **sandbox を有効にすれば deny rules も OS レベルで強制される。** ただし sandbox の設定方法と制約は別途 PoC が必要。

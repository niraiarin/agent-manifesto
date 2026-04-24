# Handoff Resume
git_sha: d6e29f6
branch: research/594-golden-dataset
skill: research
phase: Sub-3 バッチ実験 + M-interp エラー調査
intent: Local LLM ルーティング実現可能性検証 (#589)。Claude Code スキル処理を Local LLM に委譲できるか品質比較実験で検証する。

## Progress
### Done
- 研究ノート `docs/research/local-llm-routing.md` (1,400行+)
- Parent Issue #589, PR #598 作成
- Sub-1 #592 **PASS**: ccr v2.0.0 + Ollama + tool calling 動作確認
- Sub-2 #594 **CONDITIONAL PASS**: 比較実験基盤構築
- **#595 PASS**: `eval "$(ccr activate)" && claude -p` で CLAUDE.md/tools が Local LLM に自動転送
- Sub-3 実験設計修正: run-comparison.sh, evaluate.sh, run-all.sh, evaluate-all.sh, generate-variants.py
- **6モデル比較実験 (M-interp)**:
  - gemma4:e4b-128k (4.5B): delta=1.2 FAIL
  - gpt-oss-120b (120B): delta=0.6 FAIL
  - Qwen3.5-27b (27B): delta=0.5 PASS境界
  - Opus-distilled-v2 (27B): delta=0.1 **PASS (Cloud同等)**
  - gemma-4-26b-a4b (MoE 4B active): delta=1.0 FAIL
  - qwen3.6-35b-a3b (MoE 3B active, q4): delta=0.5 不安定
  - qwen3.6-35b-a3b (FP16): M-interp avg delta=0.4, T-interp delta=0.2 **PASS**
- **T-interp 26件バッチ**: avg_delta=0.07, pass_rate=69% (エラー0件)
- **M-interp 15件評価** (29件中15件有効): avg_delta=0.37, pass_rate=67%
- Go/No-Go 判定文書 `docs/research/golden-dataset/analysis/go-no-go.md` 作成
- ccr パッチ 2箇所: reasoning→thinking 変換 + 空content フォールバック (cli.js, バックアップ .bak あり)
- ccr EHOSTUNREACH: SSH tunnel (autossh + launchd) で恒久回避
- LM Studio API → OpenAI API endpoint 切替済み

### Remaining
- **M-interp エラー率 52% (15/29) の根本原因解消** ← 最優先
- エラー解消後に M-interp 29件の再バッチ + evaluate
- Go/No-Go 判定文書の最終更新
- Sub-4: RouteLLM データ変換

## Next Steps
1. `claude -p --verbose` で M-interp FAILED ケースの詳細ログを取得。エラー発生箇所を特定
2. ccr のマルチターン tool_use 応答の content block 変換を修正 (ccr #1329 参考)
3. 修正後に M-interp 29件を再バッチ実行 (`run-all.sh --task M-interp --local-only`)
4. `evaluate-all.sh --task all` で全件評価、最終集計
5. Go/No-Go 判定文書を最終更新して PR #598 マージ

## Files Modified
- `docs/research/golden-dataset/` — worktree research-594 内 (scripts, inputs 55件, outputs, evaluations)
- `docs/research/local-llm-routing.md` — worktree research-594 内
- `~/.claude-code-router/config.json` — qwen3.6-35b-a3b, localhost:11234 (SSH tunnel)
- `~/.volta/.../claude-code-router/dist/cli.js` — パッチ2箇所 (バックアップ .bak あり)
- `~/Library/LaunchAgents/com.lmstudio.tunnel.plist` — autossh SSH tunnel 自動起動

## Worktrees
- `agent-manifesto-research-594` (research/594-golden-dataset) — メイン作業場所

## Key Decisions
- **ccr デフォルト**: `lm-studio,qwen3.6-35b-a3b` (FP16, LM Studio 192.168.10.90:1234)
- **SSH tunnel**: `autossh -M 0 -N -L 11234:localhost:1234 192.168.10.90` (launchd で自動起動)
- **LM Studio endpoint**: OpenAI API に切替 (LM Studio API だと tool_calls の形式が合わない)
- **M-interp エラーの根本原因** (verbose で確認済み):
  1. LLM が Skill/Bash ツールを呼び出す (content 空 + tool_use block)
  2. Claude Code がツール実行、結果を tool_result として返す
  3. ccr が 2ターン目のリクエストを OpenAI 形式に変換する際に content block が壊れる
  4. Claude Code が `Content block is not a text block` エラー
  5. ccr #1329 (empty content with tool_calls) と同じ根本原因
- **品質を決める3要因**: active params, quantization, 蒸留
- **C5 (ドメイン知識) がボトルネック**: C1-C4 は安定して 4-5、C5 の差でPASS/FAIL が決まる

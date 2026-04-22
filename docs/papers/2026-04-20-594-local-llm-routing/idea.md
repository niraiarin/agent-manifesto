# Research Idea

**Hypothesis**: Claude Code の judgmental スキル（M-interp メトリクス解釈、T-interp トレーサビリティ解釈）を、Cloud LLM (Claude Opus) から Local LLM (qwen3.6-35b-a3b BF16) に委譲しても品質が Cloud 相当を保てる。

**Rationale**: Cloud コストをゼロ化しつつ Claude Code agent framework の pass-through (`eval "$(ccr activate)" && claude -p`) を使えば CLAUDE.md / rules / memory / tools (~32K tokens) がそのまま Local LLM の system prompt に注入される（#595 で実証）。品質差は Local モデルの active params × quantization × 蒸留の 3 軸で決まる。

**Thread (see experimental_log.md)**:
- thread-A: ccr + llama-server 環境構築 (Sub-1 #592, commits e1da87b)
- thread-B: 7 モデル比較実験 (M-interp / T-interp, commits 6ea6824..da8c7b6)
- thread-C: ccr / undici タイムアウト根本原因解消 + BF16 統一再バッチ (commits d6e29f6, e31b388, 459cc8b, df966c7)
- thread-D: Sub-4 RouteLLM preference data 生成 (commit d15182b `9159f62c` 相当)

Internal citations: PR #598 (Sub-2/3 基盤, merged), issues #589 (parent) / #594 (sub) / #595 (context 転送), commit d15182b (Sub-4), df966c7 (BF16 55/55).

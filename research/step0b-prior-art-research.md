# Step 0b: Prior Art Research — Claude Code Safety & Governance Implementations

> 調査日: 2026-03-22

## 主要な実装事例

### 1. Hook 実装

| プロジェクト | 特徴 | マニフェストとの関連 |
|------------|------|-------------------|
| [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) | 全13+イベント型のPythonベースhook参照実装 | ライフサイクル全体の観測・介入が可能であることを実証 |
| [disler/claude-code-damage-control](https://github.com/disler/claude-code-damage-control) | YAML設定の3層パス保護（zeroAccess/readOnly/noDelete）+ `ask: true` パターン | 段階的強制（block/ask/allow）= D1 の3層に対応 |
| [trailofbits/claude-code-config](https://github.com/trailofbits/claude-code-config) | セキュリティ監査会社による本番構成。deny rules + hooks + sandbox の多層防御 | **sandbox なしでは deny rules は Bash をバイパス可能**という重要な知見 |
| [Dicklesworthstone/destructive_command_guard](https://github.com/Dicklesworthstone/destructive_command_guard) | Rust製、SIMD高速パターンマッチ。コンテキスト感知（mention vs execution 区別） | 意味論的解析の先行事例。エージェント信頼度レベル設定あり |
| [kenryu42/claude-code-safety-net](https://github.com/kenryu42/claude-code-safety-net) | Plugin形式。再帰的シェルラッパー検出（5階層）、strict/paranoidモード | 強制レベルの段階設計。間接的なコマンド実行の検出 |

### 2. プロンプトインジェクション防御

| プロジェクト | 特徴 | マニフェストとの関連 |
|------------|------|-------------------|
| [vaporif/parry-guard](https://github.com/vaporif/parry-guard) | ML(DeBERTa)ベースのインジェクションスキャン。**CLAUDE.md自体のスキャンも行う** | 統治構成自体の保護（メタ制約）。唯一の自己保護実装 |
| [lasso-security/claude-hooks](https://github.com/lasso-security/claude-hooks) | 50+インジェクションパターン、5攻撃カテゴリ。意図的にwarn-not-block | hard/soft 制約の区別。false positive への対応設計 |
| [dwarvesf/claude-guardrails](https://github.com/dwarvesf/claude-guardrails) | full/lite 2バリアント。信頼度に応じた構成切り替え | コンテキスト依存の制約適用 |

### 3. エージェント・検証パターン

| プロジェクト | 特徴 | マニフェストとの関連 |
|------------|------|-------------------|
| [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) | code-reviewer agent (model: opus)、proactive review パターン | Verifier に Worker より高性能モデルを使用。P2 の実装例 |
| [trailofbits/skills](https://github.com/trailofbits/skills) | 監査推論スキル（line-by-line, First Principles, 5 Whys） | 行動制約だけでなく**推論過程の制約**（認識論的制約） |
| Anthropic公式 security-review | GitHub Action。言語非依存のAIセキュリティレビュー | **「prompt injection に対して hardened ではない」と明示** |

### 4. 学術研究

| 論文 | 内容 | マニフェストとの関連 |
|------|------|-------------------|
| Agent Behavioral Contracts (ABC), Bhardwaj 2026 | C = (P, I, G, R)。Drift Bounds Theorem: γ > α なら D* = α/γ | 最も近い学術的フレームワーク。(P,I,G,R) ≒ Lean の axiom 構造 |
| AgentSpec, ICSE 2026 | trigger/predicate/enforcement の DSL。>90% unsafe 防止 | preventive/corrective の区別 = D1 の構造的/手続的に対応 |
| Agent-C, Dong et al. 2025 | 時相安全制約の DSL + SMT ソルビング | 時相制約（X の後に Y してはならない）= 現行実装に欠けている |

## Phase 1 再設計への7つの教訓

1. **多層防御がコンセンサス**: deny rules + hooks + sandbox + 自然言語。単一層は信頼しない
2. **exit code プロトコル**: 0 = allow, 2 = block (stderr表示), 0 + JSON `ask` = 確認要求
3. **自己保護が未解決**: 統治構成自体の改竄防止は parry-guard のみ。noDeletePaths は部分的
4. **時相制約がない**: 「X の後に Y してはならない」は全実装で欠落。学術的には Agent-C が対処
5. **hard/soft 制約の区別は普遍的**: 絶対ブロック vs 警告/確認。ABC が形式化
6. **監査証跡は稀**: rulebricks のみ。ほとんどは block-and-forget
7. **行動ドリフトは認識されているが未解決**: ABC の Drift Bounds Theorem が理論的基盤

## 想定と実態の乖離（Phase 1 に影響）

| 想定 | 実態 | 情報源 |
|------|------|--------|
| deny rules で十分 | **sandbox なしでは Bash がバイパス可能** | Trail of Bits |
| PostToolUse でブロック可能 | **PostToolUse はブロック不可** (Step 0a で確認済み) | 公式ドキュメント |
| 単純な regex で安全 | **間接実行（bash -c, python -c）のパターンが必要** | destructive_command_guard |
| CLAUDE.md のルールは遵守される | **指示数が増えると遵守率が低下** | HumanLayer blog |
| 自己レビューで検証可能 | **E1 違反。独立したコンテキストの Verifier が必要** | ABC 論文 |

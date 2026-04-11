import Manifest.Models.Assumptions.EpistemicLayer

/-!
# Claude Code Conditional Design Foundation - Assumptions

条件付き公理系 S=(A,C,H,D) の Claude Code インスタンスにおける仮定を定義する。

## 認識論的出自

- **C (Human Decision)**: Claude Code をこのプロジェクトの実行環境として選定した
  人間の設計判断。T6（人間の最終決定権）に基づく。
- **H (LLM Inference)**: Claude Code のドキュメント・実装から LLM が推論した
  プラットフォーム特性。各 H に反証条件を付与。

## TemporalValidity

全ての仮定に TemporalValidity を付与する。Claude Code はアクティブに開発中の
プラットフォームであり、仕様変更が頻繁に起こりうる。
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest
open Manifest.Models.Assumptions

-- ============================================================
-- C: 人間の設計判断
-- ============================================================

/-- CC-C1: L1 制約は PreToolUse hook で構造的に強制する。
    人間がこのプロジェクトで選択した設計方針。 -/
def cc_c1 : Assumption := {
  id := "CC-C1"
  source := .humanDecision 1 "L1-enforcement-method" "2025-06-01"
  content := "L1（倫理・安全）制約は PreToolUse hook で構造的に強制する。hook は exit 2 + stderr でツール実行をブロックする。"
  validity := some {
    sourceRef := ".claude/settings.json + .claude/hooks/l1-safety-check.sh"
    lastVerified := "2026-04-08"
    reviewInterval := some 90
  }
}

/-- CC-C2: 破壊的操作は settings.json の deny rules で補助的に制限する。
    hook が主防衛線であり、deny rules は深層防御。 -/
def cc_c2 : Assumption := {
  id := "CC-C2"
  source := .humanDecision 1 "deny-rules-design" "2025-06-01"
  content := "破壊的操作（rm -rf, git push --force 等）は settings.json の deny rules で補助的に制限する。ただし deny rules は間接実行でバイパス可能であり、hook が主防衛線。"
  validity := some {
    sourceRef := ".claude/settings.json permissions.deny"
    lastVerified := "2026-04-08"
    reviewInterval := some 90
  }
}

/-- CC-C3: 検証は subagent で行う（P2 Worker/Verifier 分離）。 -/
def cc_c3 : Assumption := {
  id := "CC-C3"
  source := .humanDecision 1 "verification-method" "2025-06-01"
  content := "P2 検証は Agent tool で起動される subagent（verifier 型）で行う。Worker と Verifier はプロセスレベルで分離される。"
  validity := some {
    sourceRef := ".claude/agents/verifier.md + .claude/skills/verify/SKILL.md"
    lastVerified := "2026-04-08"
    reviewInterval := some 90
  }
}

/-- CC-C4: 規範的指針は .claude/rules/ と CLAUDE.md に配置する。 -/
def cc_c4 : Assumption := {
  id := "CC-C4"
  source := .humanDecision 1 "normative-placement" "2025-06-01"
  content := "D1 の規範的指針レイヤーに属する制約は .claude/rules/*.md と CLAUDE.md に配置する。毎セッション読み込まれ、コンテキストを消費する（D11）。"
  validity := some {
    sourceRef := ".claude/rules/ + CLAUDE.md"
    lastVerified := "2026-04-08"
    reviewInterval := some 180
  }
}

/-- CC-C5: スキルは再利用可能な手順をセッション跨ぎで永続化する（D10）。 -/
def cc_c5 : Assumption := {
  id := "CC-C5"
  source := .humanDecision 1 "skill-persistence" "2025-06-01"
  content := "スキル（.claude/skills/*/SKILL.md）はセッション跨ぎで永続する構造であり、エージェントの発見・手順をT2プリミティブとして符号化する。"
  validity := some {
    sourceRef := ".claude/skills/"
    lastVerified := "2026-04-08"
    reviewInterval := some 180
  }
}

-- ============================================================
-- H: LLM 推論
-- ============================================================

/-- CC-H1: PreToolUse hook はエージェントがバイパスできない。
    hook 実行はハーネスレベルで強制される。
    反証条件: (1) hook 実行のオプトアウト、(2) cwd 移動による hook パス解決失敗（#414 で対処済み）。 -/
def cc_h1 : Assumption := {
  id := "CC-H1"
  source := .llmInference
    ["CC-C1"]
    "Claude Code が hook 実行をオプトアウト可能にした場合、または hook スクリプトのパスが相対パスで cwd がプロジェクトルート外にある場合（#414 で hook 内 cwd 正規化により対処済み。新規 hook 追加時にも同パターンが発生しうる）"
  content := "PreToolUse hook はエージェントの裁量でスキップできない。ハーネス（Claude Code ランタイム）がツール実行前に必ず hook を実行し、exit 2 でブロックする。これにより D2 の executionAutomatic 条件が満たされる。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/hooks"
    lastVerified := "2026-04-08"
    reviewInterval := some 60
  }
}

/-- CC-H2: Agent tool で起動された subagent は独立したコンテキストウィンドウを持つ。
    D2 の contextSeparated 条件を満たす。 -/
def cc_h2 : Assumption := {
  id := "CC-H2"
  source := .llmInference
    ["CC-C3"]
    "Agent tool が親コンテキストを共有する仕様変更があった場合に反証される"
  content := "Agent tool で起動された subagent は親とは独立したコンテキストウィンドウで動作する。Worker の思考過程・中間状態は subagent に漏洩しない。ただし同一モデルファミリのため evaluatorIndependent=false。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/agent-tool"
    lastVerified := "2026-04-08"
    reviewInterval := some 60
  }
}

/-- CC-H3: Permission deny rules はハーネスレベルで強制されるが、間接実行でバイパス可能。
    したがって deny rules 単独は structural ではなく procedural に分類すべき。 -/
def cc_h3 : Assumption := {
  id := "CC-H3"
  source := .llmInference
    ["CC-C2"]
    "Claude Code が deny rules をサンドボックスレベルで強制するようになった場合に反証される（現在は sandbox オプションで可能だが未有効化）"
  content := "Permission deny rules はパターンマッチベースであり、bash -c 等の間接実行でバイパス可能（PoC 3 で検証済み）。hook と組み合わせることで実効的な構造的強制を達成するが、deny rules 単独では procedural レベル。"
  validity := some {
    sourceRef := ".claude/rules/l1-sandbox-recommendation.md"
    lastVerified := "2026-04-08"
    reviewInterval := some 90
  }
}

/-- CC-H4: CLAUDE.md と .claude/rules/ は毎セッション読み込まれ、コンテキストを消費する。
    D11 のコンテキストコスト分析の根拠。 -/
def cc_h4 : Assumption := {
  id := "CC-H4"
  source := .llmInference
    ["CC-C4"]
    "Claude Code がルールの遅延読み込み or 選択的読み込みを実装した場合に反証される"
  content := "CLAUDE.md と .claude/rules/*.md は SessionStart 時にコンテキストウィンドウに読み込まれる。追加するごとにコンテキストコストが増加する。hook はコンテキストに読み込まれず、コンテキストコスト 0。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/memory#project-instructions"
    lastVerified := "2026-04-08"
    reviewInterval := some 60
  }
}

/-- CC-H5: PostToolUse hook は非同期実行可能で、ツール実行をブロックしない。
    P4 メトリクス収集に適する。 -/
def cc_h5 : Assumption := {
  id := "CC-H5"
  source := .llmInference
    ["CC-C1"]
    "PostToolUse の async オプションが削除された場合に反証される"
  content := "PostToolUse hook は async: true で非同期実行が可能。また PostToolUse は exit 2 でもブロックできない（仕様上の制約）。したがって P4 メトリクス収集には適するが、L1 強制には不適。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/hooks"
    lastVerified := "2026-04-08"
    reviewInterval := some 60
  }
}

/-- CC-C6: Auto memory は git リポジトリ単位でスコープされる。
    同一 repo 内の全 worktree とサブディレクトリが 1 つの memory を共有。 -/
def cc_c6 : Assumption := {
  id := "CC-C6"
  source := .humanDecision 1 "memory-scope" "2025-06-01"
  content := "Auto memory は git リポジトリ単位でスコープされる。~/.claude/projects/<project>/memory/ に保存。git 外ではプロジェクトルートを使用。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/memory"
    lastVerified := "2026-04-09"
    reviewInterval := some 90
  }
}

/-- CC-H6: 同一イベントの全 matching hooks は並列実行される。
    競合する判定は deny > defer > ask > allow の優先順位で解決。 -/
def cc_h6 : Assumption := {
  id := "CC-H6"
  source := .llmInference
    ["CC-C1"]
    "Claude Code が hooks を逐次実行に変更した場合に反証される"
  content := "同一イベントに対してマッチする全 hooks は並列実行される。同一ハンドラは重複排除される。競合する判定（allow vs deny）は deny > defer > ask > allow の優先順位で解決。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/hooks"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- CC-H7: Auto mode は LLM を classifier として使用し、自然言語ルールで動的にツール許可を判定する。
    D1 の procedural 層に AI-assisted enforcement を追加。 -/
def cc_h7 : Assumption := {
  id := "CC-H7"
  source := .llmInference
    ["CC-C2"]
    "Auto mode が廃止されるか、ルールベース（非 AI）に変更された場合に反証される"
  content := "Auto mode は AI classifier で自然言語 policy rules（autoMode.allow, autoMode.soft_deny）を評価し、ツール許可を動的に判定する。allow/soft_deny を設定するとデフォルトリスト全体が置換される。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/permissions"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

-- CC-C7 は欠番（初期設計時に統合されたため）。番号の連続性より既存参照の安定性を優先。

/-- CC-C8: D18 (マルチエージェント協調) の Claude Code 実現として、
    Subagent (1:N in-session delegation) と Agent Teams (N:N cross-session coordination) の
    2 つの異なる協調プリミティブを使用する。

    Subagent の行動特性は CC5/CC5b/CC6 で既にカバー。
    Agent Teams の行動特性（独立コンテキスト、共有タスクリスト、TeammateIdle hook）は
    D18 + D2 (独立性条件) から導出可能であり、独立した仮定は不要。
    本仮定は「2 つのプリミティブが存在し区別される」というプラットフォーム事実のみを仮定する。 -/
def cc_c8 : Assumption := {
  id := "CC-C8"
  source := .humanDecision 1 "coordination-primitives" "2025-06-01"
  content := "D18 の実現として Subagent (Agent tool, 1:N, session 内) と Agent Teams (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS, N:N, session 間) の 2 つの協調プリミティブを使用する。使い分けは D18 + D12 (CSP) に基づく: 単発委譲は Subagent、複数エージェント協調は Agent Teams。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/sub-agents"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

-- ============================================================
-- C/H: #311 Managed Agents ギャップ分析で追加
-- ============================================================

/-- CC-C9: MCP proxy + HashiCorp Vault を使用して credential を structural に隔離する。
    Agent は認証情報に直接アクセスせず、MCP server 経由でのみ認証済み API を呼出す。
    ccEnforcementLayer .mcpServer = .procedural を前提として、
    Vault 統合により credential 次元のみ structural に昇格する。 -/
def cc_c9 : Assumption := {
  id := "CC-C9"
  source := .humanDecision 1 "credential-isolation-method" "2026-04-10"
  content := "MCP proxy + HashiCorp Vault で credential を structural に隔離する。Agent → MCP server (credential なし) → Vault から取得 → API 呼出 → sanitized response。mcpServer プリミティブ自体は procedural だが、Vault 統合により credential 次元の enforcement が structural に昇格する。"
  validity := some {
    sourceRef := "https://developer.hashicorp.com/validated-patterns/vault/ai-agent-identity-with-hashicorp-vault"
    lastVerified := "2026-04-10"
    reviewInterval := some 90
  }
}

/-- CC-C10: CC の自律レベルを preApproved とする設計判断。
    auto mode (CC-H7) を有効化し、事前承認範囲内で自律動作させる。
    デフォルト (supervised) からの意図的な昇格。 -/
def cc_c10 : Assumption := {
  id := "CC-C10"
  source := .humanDecision 1 "autonomy-level" "2026-04-10"
  content := "CC の自律レベルを preApproved に設定する。auto mode (CC-H7) を有効化し、事前承認範囲内で自律動作させる。supervised（全ツール確認）からの意図的な昇格。"
  validity := some {
    sourceRef := ".claude/settings.json autoMode"
    lastVerified := "2026-04-10"
    reviewInterval := some 90
  }
}

/-- CC-H8: Agent SDK のセッションは JSONL でローカル保存され、resume by ID で手動回復可能。
    自動クラッシュ回復は提供されない。 -/
def cc_h8 : Assumption := {
  id := "CC-H8"
  source := .llmInference
    ["CC-C1"]
    "Agent SDK が自動クラッシュ回復を実装した場合に反証される（journaled → durable に昇格）"
  content := "Agent SDK は会話履歴を ~/.claude/projects/<cwd>/<id>.jsonl に自動保存する。resume(session_id) で手動再開可能。ただし自動クラッシュ回復はなく、ファイル変更は persist されない（会話コンテキストのみ）。"
  validity := some {
    sourceRef := "https://code.claude.com/docs/en/agent-sdk/sessions"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H9: Managed Agents のセッションは append-only イベントログとしてサーバサイドに永続化される。
    自動クラッシュ回復 + 位置指定アクセス (getEvents) を提供。 -/
def cc_h9 : Assumption := {
  id := "CC-H9"
  source := .llmInference
    ["CC-C9"]
    "MA がセッションログのクラッシュ回復保証を廃止、または getEvents API を削除した場合に反証される"
  content := "MA のセッションは append-only イベントログとしてサーバサイドに永続。harness はステートレスで、クラッシュ後に wake(sessionId) + getEvents() で再開可能。Engineering blog 引用: 'Because the session log sits outside the harness, nothing in the harness needs to survive a crash.'"
  validity := some {
    sourceRef := "https://www.anthropic.com/engineering/managed-agents"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H10: CC sandbox 有効時、ファイルシステムは Seatbelt (macOS) / bubblewrap (Linux) で
    カーネルレベル隔離。ネットワークは proxy + allowlist だが dangerouslyDisableSandbox
    エスケープハッチが存在（user 承認必要、allowUnsandboxedCommands=false で無効化可能）。 -/
def cc_h10 : Assumption := {
  id := "CC-H10"
  source := .llmInference
    ["CC-C1"]
    "CC sandbox が syscall フィルタリングを追加、または dangerouslyDisableSandbox が廃止された場合に反証される"
  content := "CC sandbox: filesystem=structural (Seatbelt/bwrap, kernel-level)。network=procedural (proxy+allowlist だが dangerouslyDisableSandbox あり — agent が起動可能だが user 承認必要。domain fronting bypass も文書化済み)。process=normative (syscall フィルタリングなし)。credential=procedural (CC-H3 により deny rules はバイパス可能)。"
  validity := some {
    sourceRef := "https://code.claude.com/docs/en/sandboxing"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H11: Docker hardened 構成 (--cap-drop ALL, --seccomp, --read-only, --network none) で
    filesystem/network/process が structural に到達。credential は env var 経由のため procedural。 -/
def cc_h11 : Assumption := {
  id := "CC-H11"
  source := .llmInference
    ["CC-C9"]
    "Docker の seccomp デフォルトプロファイルからブロック対象 syscall が削減された場合、または --cap-drop ALL の挙動が変更された場合に反証される"
  content := "Docker hardened: filesystem=structural (--read-only+tmpfs)、network=structural (--network none, kernel-level)、process=structural (--cap-drop ALL+seccomp)、credential=procedural (env var injection — プロセス内からアクセス可能)。"
  validity := some {
    sourceRef := "https://docs.docker.com/engine/security/"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-H12: MA limited networking 構成で filesystem/network/credential が structural。
    process の隔離技術（gVisor, Firecracker 等）は公式に非公開のため procedural に分類。 -/
def cc_h12 : Assumption := {
  id := "CC-H12"
  source := .llmInference
    ["CC-C9"]
    "MA が隔離技術を公開し gVisor/Firecracker と確認された場合（process が structural に昇格）、またはコンテナ隔離が廃止された場合に反証される"
  content := "MA limited: filesystem=structural (per-session isolated container)、network=structural (limited+allowed_hosts)、process=procedural (isolation exists but technology undocumented)、credential=structural (Vault+MCP proxy, credentials never reach sandbox)。"
  validity := some {
    sourceRef := "https://platform.claude.com/docs/en/managed-agents/environments"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H13: MA default (unrestricted) networking では全 outbound トラフィックが許可される。
    limited への明示的変更が必要。 -/
def cc_h13 : Assumption := {
  id := "CC-H13"
  source := .llmInference
    ["CC-H12"]
    "MA のデフォルト networking が limited に変更された場合に反証される"
  content := "MA default: networking.type='unrestricted' が初期値。全 outbound トラフィック許可（safety blocklist のみ）。production 利用には 'limited' + allowed_hosts の明示設定が推奨される。"
  validity := some {
    sourceRef := "https://platform.claude.com/docs/en/managed-agents/environments"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H14: CC は coupled アーキテクチャ（harness と実行が同一プロセス）。
    MA は decoupled（ステートレス harness がセッションログ経由で実行を委譲）。 -/
def cc_h14 : Assumption := {
  id := "CC-H14"
  source := .llmInference
    ["CC-C1", "CC-H9"]
    "CC が decoupled アーキテクチャを採用した場合、または MA が coupled に変更された場合に反証される"
  content := "CC: coupled (harness=Claude Code process, 実行=同一プロセス内)。MA: decoupled (harness=ステートレスループ, セッション=外部ログ, sandbox=使い捨てコンテナ)。"
  validity := some {
    sourceRef := "https://www.anthropic.com/engineering/managed-agents"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H15: CC は PreToolUse hook で動的インターセプション（block/modify/inject）が可能。
    MA は always_ask で runtime pause + external allow/deny のみ（入力修正・コンテキスト注入不可）。 -/
def cc_h15 : Assumption := {
  id := "CC-H15"
  source := .llmInference
    ["CC-H1", "CC-H7"]
    "MA が hook 相当のインターセプション機能（入力修正、コンテキスト注入）を追加した場合に反証される"
  content := "CC: dynamicHook (PreToolUse で deny/updatedInput/systemMessage)。MA: dynamicConfirmation (always_ask で session pause + user.tool_confirmation allow/deny。入力修正・コンテキスト注入は不可)。"
  validity := some {
    sourceRef := "https://platform.claude.com/docs/en/managed-agents/permission-policies"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

-- ============================================================
-- C/H: #399 バージョン管理と協調開発
-- ============================================================

/-- CC-C11: branch 命名は skill 名に対応する慣習。
    evolve/run-N, research/NNN-topic。D10（構造的永続性）の操作インスタンス。 -/
def cc_c11 : Assumption := {
  id := "CC-C11"
  source := .humanDecision 1 "branch-naming" "2026-04-10"
  content := "branch 命名は skill に対応: evolve/run-{N} は /evolve、research/{issue}-{topic} は /research。skill 名が VCS 名前空間に符号化される。"
  validity := some {
    sourceRef := ".claude/skills/evolve/SKILL.md + .claude/skills/research/scripts/worktree.sh"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-C12: PR は squash merge。1 issue = 1 commit on main。
    P3（学習の統治）の互換性分類と組み合わせて原子的な変更履歴を維持する。 -/
def cc_c12 : Assumption := {
  id := "CC-C12"
  source := .humanDecision 1 "merge-strategy" "2026-04-10"
  content := "PR は squash merge (gh pr merge --squash --delete-branch)。main 上で 1 issue = 1 commit。P3 互換性分類がコミットメッセージに含まれる。"
  validity := some {
    sourceRef := ".claude/skills/evolve/scripts/pr-workflow.sh"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-C13: worktree は親ディレクトリに隔離配置。
    P2（認知的関心の分離）の物理的実現。 -/
def cc_c13 : Assumption := {
  id := "CC-C13"
  source := .humanDecision 1 "worktree-isolation" "2026-04-10"
  content := "worktree は ../<repo>-research-<ISSUE> に配置。メインリポジトリと物理的に分離し、P2 の認知的関心の分離を VCS レベルで実現する。"
  validity := some {
    sourceRef := ".claude/skills/research/scripts/worktree.sh"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-C14: issue は Parent/Sub-Issue パターンで構造化。
    /research の Gate 付きリサーチで使用。 -/
def cc_c14 : Assumption := {
  id := "CC-C14"
  source := .humanDecision 1 "issue-structure" "2026-04-10"
  content := "issue は Parent/Sub-Issue パターン。Parent issue が研究テーマ、Sub-issue が個別 Gate を持つ。マークダウンテンプレートで構造化。"
  validity := some {
    sourceRef := ".claude/skills/research/SKILL.md"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

-- ============================================================
-- C/H: #400 エージェント実行基盤と指示設計
-- ============================================================

/-- CC-C15: SKILL.md の標準構造。
    frontmatter → @traces → 本文 → Traceability セクション。D10 のテンプレート。 -/
def cc_c15 : Assumption := {
  id := "CC-C15"
  source := .humanDecision 1 "skill-template" "2026-04-10"
  content := "SKILL.md は標準構造に従う: YAML frontmatter (name, description, dependencies, agents) → <!-- @traces --> アノテーション → 本文 → Traceability セクション。全 12 スキルがこの慣習に従う。"
  validity := some {
    sourceRef := ".claude/skills/*/SKILL.md"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-C16: Agent モデル選択基準。
    hypothesizer=opus（創造的推論）、observer/verifier/integrator=sonnet（効率重視）。 -/
def cc_c16 : Assumption := {
  id := "CC-C16"
  source := .humanDecision 1 "agent-model-selection" "2026-04-10"
  content := "Agent モデル選択: hypothesizer=opus (創造的推論が必要)、observer/verifier/integrator=sonnet (構造化タスク、効率重視)。verifier と hypothesizer は effort: high。"
  validity := some {
    sourceRef := ".claude/agents/hypothesizer.md + .claude/agents/verifier.md"
    lastVerified := "2026-04-10"
    reviewInterval := some 90
  }
}

/-- CC-C17: TaskClassification (deterministic/judgmental) を各スキルステップに付与。
    D12（制約充足タスク設計）の操作インスタンス。 -/
def cc_c17 : Assumption := {
  id := "CC-C17"
  source := .humanDecision 1 "task-classification-per-step" "2026-04-10"
  content := "各スキルの各ステップに TaskClassification (deterministic/bounded/judgmental) を付与する。deterministic はスクリプト化、judgmental は LLM/人間が担当。mixed_task_decomposition で分離する。"
  validity := some {
    sourceRef := "lean-formalization/Manifest/TaskClassification.lean"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-H16: gh CLI は sandbox の excludedCommands で外部通信が許可される。
    sandbox 有効時でも gh コマンドは実行可能。 -/
def cc_h16 : Assumption := {
  id := "CC-H16"
  source := .llmInference
    ["CC-C1"]
    "sandbox が excludedCommands 機能を廃止した場合に反証される"
  content := "gh CLI は sandbox の excludedCommands: [\"gh *\"] で例外扱い。sandbox 有効時でも GitHub API への通信が許可される。settings.json で設定。"
  validity := some {
    sourceRef := ".claude/settings.json sandbox.excludedCommands"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H17: マージ済み evolve/* branch は PR マージ時に自動削除。
    research/* branch は T6 により人間判断で削除。 -/
def cc_h17 : Assumption := {
  id := "CC-H17"
  source := .llmInference
    ["CC-C12"]
    "pr-workflow.sh が --delete-branch を使わなくなった場合に反証される"
  content := "evolve/* branch は gh pr merge --delete-branch で自動削除。research/* branch は worktree.sh の cleanup で T6（人間判断）に委ねられる。cleanup ポリシーが branch 種別で異なる。"
  validity := some {
    sourceRef := ".claude/skills/evolve/scripts/pr-workflow.sh + .claude/skills/research/scripts/worktree.sh"
    lastVerified := "2026-04-10"
    reviewInterval := some 90
  }
}

/-- CC-H18: gh auth status が全 gh コマンドの前提条件。
    未認証時は全 GitHub 操作が失敗する。 -/
def cc_h18 : Assumption := {
  id := "CC-H18"
  source := .llmInference
    ["CC-H16"]
    "gh が認証なしで公開リポジトリ操作を許可する変更があった場合に反証される"
  content := "gh CLI は gh auth login/status で認証済みであることが前提。settings.local.json で Bash(gh auth:*) を allow 設定。新環境セットアップ時に必要だがドキュメント未記載。"
  validity := some {
    sourceRef := ".claude/settings.local.json"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H19: hook stdin 仕様: INPUT=$(cat) で JSON を受け取り、
    .tool_input.* で内容にアクセス。全 hook で統一パターン。 -/
def cc_h19 : Assumption := {
  id := "CC-H19"
  source := .llmInference
    ["CC-H1"]
    "Claude Code が hook stdin のフォーマットを変更した場合に反証される"
  content := "hook は stdin から JSON を受け取る (INPUT=$(cat))。tool_input フィールドでツールの引数にアクセス。session_id でセッション識別。jq が必須の外部依存。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/hooks"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H20: hook state file パターン: /tmp/${hook}-warned-${SESSION} で段階的応答。
    1 回目は警告（exit 0）、2 回目以降はブロック（exit 2）。 -/
def cc_h20 : Assumption := {
  id := "CC-H20"
  source := .llmInference
    ["CC-H1", "CC-H19"]
    "hook が stateless な設計に変更された場合、または SESSION 変数が廃止された場合に反証される"
  content := "p2-verify-on-commit, p3-compatibility-check, p3-axiom-evidence-check の 3 hook が /tmp/${name}-warned-${SESSION} パターンを使用。初回は touch + 警告、次回は -f チェック + ブロック。セッション終了で自動クリア。"
  validity := some {
    sourceRef := ".claude/hooks/p2-verify-on-commit.sh + p3-compatibility-check.sh + p3-axiom-evidence-check.sh"
    lastVerified := "2026-04-10"
    reviewInterval := some 90
  }
}

/-- CC-H21: PreToolUse Edit は変更後のファイル内容を読めない。
    hook が見られるのは tool_input.new_string（置換文字列）のみ。 -/
def cc_h21 : Assumption := {
  id := "CC-H21"
  source := .llmInference
    ["CC-H1"]
    "Claude Code が PreToolUse Edit に変更後ファイル内容を含めるようになった場合に反証される"
  content := "PreToolUse Edit hook は tool_input.file_path, old_string, new_string を受け取る。変更後のファイル全体は見えないため、「Edit の結果がファイルを壊すか」は判定不可。D1 の構造的強制の境界。"
  validity := some {
    sourceRef := "https://docs.anthropic.com/en/docs/claude-code/hooks"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

/-- CC-H22: UserPromptSubmit と TaskCompleted は利用可能な hook イベント。
    CLAUDE.md の Hook セクションに記載漏れ。V5/V7 計測基盤。 -/
def cc_h22 : Assumption := {
  id := "CC-H22"
  source := .llmInference
    ["CC-H1"]
    "これらのイベント種別が廃止された場合に反証される"
  content := "UserPromptSubmit (p4-v5-approval-tracker.sh) と TaskCompleted (p4-v7-task-tracker.sh) は有効な hook イベント。settings.json で定義済みだが CLAUDE.md の Hook セクションに未記載。"
  validity := some {
    sourceRef := ".claude/settings.json hooks"
    lastVerified := "2026-04-10"
    reviewInterval := some 60
  }
}

-- ============================================================
-- C/H: #405 エージェント・人間の相互作用
-- ============================================================

/-- CC-C18: hook 変更は /tmp スクリプト経由で人間に委譲する。
    T6（人間の最終決定権）+ D1（自己保護）の操作インスタンス。 -/
def cc_c18 : Assumption := {
  id := "CC-C18"
  source := .humanDecision 1 "hook-delegation-to-human" "2026-04-10"
  content := "hook ファイルの変更は L1 自己保護でエージェントが直接編集不可。/tmp/setup-*.sh にスクリプトを生成し、人間に実行を依頼する。T6 と D1 の組み合わせ。"
  validity := some {
    sourceRef := "~/.claude/projects/-Users-nirarin-work-agent-manifesto/memory/feedback_hook_human_setup.md"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-C19: critical リスクの変更は人間レビュー必須。
    CC6（4/4 独立性条件未達）から導かれる運用要件。 -/
def cc_c19 : Assumption := {
  id := "CC-C19"
  source := .humanDecision 1 "critical-risk-human-review" "2026-04-10"
  content := "critical リスクの変更は人間レビュー必須。CC subagent は 3/4 独立性条件のみ（evaluatorIndependent=false）のため、critical には不十分。verify/SKILL.md で明記。"
  validity := some {
    sourceRef := ".claude/skills/verify/SKILL.md"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-C20: セッション間の情報永続化は 3 媒体で行う。
    T1（セッション有界性）→ T2（構造永続性）の橋渡し。 -/
def cc_c20 : Assumption := {
  id := "CC-C20"
  source := .humanDecision 1 "session-persistence-media" "2026-04-10"
  content := "セッション間の情報永続化: (1) MEMORY.md — ユーザー/フィードバック/プロジェクト知識、(2) evolve-history.jsonl — /evolve の実行履歴、(3) GitHub issue コメント — 研究の経緯と判断根拠。各媒体の使い分けは情報の種類と寿命に基づく。"
  validity := some {
    sourceRef := "~/.claude/projects/-Users-nirarin-work-agent-manifesto/memory/MEMORY.md + .claude/metrics/evolve-history.jsonl"
    lastVerified := "2026-04-10"
    reviewInterval := some 180
  }
}

/-- CC-H23: Agent 間の情報受け渡しは結果のみ（意図説明なし）。
    P2 の framingIndependent を実現。 -/
def cc_h23 : Assumption := {
  id := "CC-H23"
  source := .llmInference
    ["CC-H2"]
    "verify/SKILL.md が Worker の意図共有を許可する変更があった場合に反証される"
  content := "Verifier → Worker 間は結果のみ渡す。Worker が『何が正しいか』を Verifier に伝えない (framingIndependent)。verify/SKILL.md で明記: 「Worker の意図説明を含めない」。"
  validity := some {
    sourceRef := ".claude/skills/verify/SKILL.md"
    lastVerified := "2026-04-10"
    reviewInterval := some 90
  }
}

/-- CC-H24: skill 間の入出力契約が dependency-graph.yaml で宣言されている。
    例: /research の Gap Analysis → /spec-driven-workflow の Phase 1 入力。 -/
def cc_h24 : Assumption := {
  id := "CC-H24"
  source := .llmInference
    ["CC-C5"]
    "dependency-graph.yaml が廃止、またはスキル間契約が非構造的に戻った場合に反証される"
  content := "skill 間の入出力契約は dependency-graph.yaml の invoked_by/expected_output で宣言。/research → /spec-driven-workflow、/verify → /evolve 等。双方のスキルで相互参照。"
  validity := some {
    sourceRef := ".claude/skills/dependency-graph.yaml"
    lastVerified := "2026-04-10"
    reviewInterval := some 90
  }
}

/-- CC-H25: Judge の addressable/unaddressable 分類と最大 2 回の減点解消ループ。
    P3（学習の統治）の評価プロセス実装。 -/
def cc_h25 : Assumption := {
  id := "CC-H25"
  source := .llmInference
    ["CC-C3"]
    "judge.md のプロセスが変更された場合に反証される"
  content := "Judge は減点を addressable（現スコープで対処可能）と unaddressable（構造的限界）に分類。addressable は修正→再判定を最大 2 回ループ。2 回で解消しない場合はプロセス問題として人間に報告。"
  validity := some {
    sourceRef := ".claude/agents/judge.md + ~/.claude/projects/-Users-nirarin-work-agent-manifesto/memory/feedback_judge_deductions.md"
    lastVerified := "2026-04-10"
    reviewInterval := some 90
  }
}

-- ============================================================
-- C/H: #401 形式検証ツールチェーン
-- ============================================================

/-- CC-C21: Axiom Card のフォーマット標準。
    Layer, Content, Basis, Source, Refutation condition の 5 フィールド。 -/
def cc_c21 : Assumption := {
  id := "CC-C21"
  source := .humanDecision 1 "axiom-card-format" "2026-04-11"
  content := "Axiom Card は [Axiom Card] ヘッダーに続き Layer, Content, Basis, Source, Refutation condition の 5 フィールドを持つ。p3-axiom-evidence-check.sh がフィールド存在を hook で検証する。"
  validity := some {
    sourceRef := "lean-formalization/Manifest/Axioms.lean + .claude/hooks/p3-axiom-evidence-check.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-C22: Derivation Card のフォーマット標準。
    Derives from, Proposition, Content, Proof strategy の 4 フィールド。 -/
def cc_c22 : Assumption := {
  id := "CC-C22"
  source := .humanDecision 1 "derivation-card-format" "2026-04-11"
  content := "Derivation Card は [Derivation Card] ヘッダーに続き Derives from, Proposition, Content, Proof strategy の 4 フィールドを持つ。manifest-trace がパースしてトレーサビリティを検証する。"
  validity := some {
    sourceRef := "lean-formalization/Manifest/Procedure.lean + scripts/manifest-trace"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-C23: sync-counts.sh のスコープは Manifest/*.lean + Framework/*.lean のみ。
    Models/, Foundation/ は除外。 -/
def cc_c23 : Assumption := {
  id := "CC-C23"
  source := .humanDecision 1 "sync-counts-scope" "2026-04-11"
  content := "sync-counts.sh は Manifest/*.lean と Manifest/Framework/*.lean のみをカウント。Manifest/Models/ と Manifest/Foundation/ は除外。カウント対象の非対称性は意図的。"
  validity := some {
    sourceRef := "scripts/sync-counts.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-H27: Lean 4 で import は doc comment より前に書く必要がある。 -/
def cc_h27 : Assumption := {
  id := "CC-H27"
  source := .llmInference
    ["CC-C23"]
    "Lean 4 が import の位置制約を変更した場合に反証される"
  content := "import 文は doc comment (開始タグ: slash-dash-bang) より前に配置する。Lean 4 のパーサ要件。CLAUDE.md に記載済みだが 1 行のみ。"
  validity := some {
    sourceRef := "https://lean-lang.org/lean4/doc/"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-H28: opaque 型は deriving Repr が効かず、手動で Repr インスタンスが必要。 -/
def cc_h28 : Assumption := {
  id := "CC-H28"
  source := .llmInference
    ["CC-C23"]
    "Lean 4 が opaque 型の deriving Repr をサポートした場合に反証される"
  content := "opaque 型を含む構造体で deriving Repr を使うと、opaque 型の Repr インスタンスがないためコンパイルエラーになる。手動で Repr インスタンスを定義する必要がある。"
  validity := some {
    sourceRef := "lean-formalization/Manifest/Ontology.lean"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-H29: Verso HTML 生成で非 ASCII 文字は slug 中で ___ に変換される。 -/
def cc_h29 : Assumption := {
  id := "CC-H29"
  source := .llmInference
    ["CC-C23"]
    "Verso が slug 生成アルゴリズムを変更した場合に反証される"
  content := "Verso HTML 生成で非 ASCII 文字は slug 中で ___ に変換。h5-doc-lint.sh が python3 scripts/lint-doc-comments.py を呼び出して H5 ドキュメントコメントの lint を実行する。"
  validity := some {
    sourceRef := "scripts/lint-doc-comments.py"
    lastVerified := "2026-04-11"
    reviewInterval := some 90
  }
}

-- ============================================================
-- C/H: #402 実行環境と依存管理
-- ============================================================

/-- CC-C24: elan/lake の PATH export が全スクリプトで必要。 -/
def cc_c24 : Assumption := {
  id := "CC-C24"
  source := .humanDecision 1 "elan-path-requirement" "2026-04-11"
  content := "Lean 関連スクリプトは export PATH=\"$HOME/.elan/bin:$PATH\" が必要。CLAUDE.md の Build Commands に記載されているが、各スクリプトでの必要性は暗黙。"
  validity := some {
    sourceRef := "CLAUDE.md Build & Test Commands"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-H30: macOS BSD sed は -i '' を使用。Linux は -i（引数なし）。 -/
def cc_h30 : Assumption := {
  id := "CC-H30"
  source := .llmInference
    ["CC-C24"]
    "macOS が GNU sed を標準採用した場合に反証される"
  content := "macOS BSD sed は -i の後に空文字列 '' が必要 (sed -i '' 's/...')。Linux GNU sed は -i のみ。tac も macOS 不在で tail -r フォールバックが必要。wc -l は macOS で前置スペースあり tr -d ' ' が必要。"
  validity := some {
    sourceRef := "scripts/sync-counts.sh + .claude/hooks/p2-verify-on-commit.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-H31: jq は全 hook の暗黙の前提条件。不在時は silent failure。 -/
def cc_h31 : Assumption := {
  id := "CC-H31"
  source := .llmInference
    ["CC-H19"]
    "全 hook に jq の存在チェックが追加された場合に反証される"
  content := "15/18 の hook ファイルが jq を使用（46 箇所）。command -v jq ガードは 0 件。jq 不在時は silent failure（shell parse error で exit 非0、ただし exit 2 ではないためブロックしない）。"
  validity := some {
    sourceRef := ".claude/hooks/*.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 90
  }
}

/-- CC-H32: python3 は h5-doc-lint.sh の暗黙の前提条件。CLAUDE.md 未記載。 -/
def cc_h32 : Assumption := {
  id := "CC-H32"
  source := .llmInference
    ["CC-H1"]
    "h5-doc-lint.sh が python3 依存を除去した場合に反証される"
  content := "h5-doc-lint.sh は python3 scripts/lint-doc-comments.py を呼び出す。python3 は hook の動作条件だが CLAUDE.md の Build & Test Commands に未記載。"
  validity := some {
    sourceRef := ".claude/hooks/h5-doc-lint.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 90
  }
}

-- ============================================================
-- C/H: #403 品質検証の設計パターン
-- ============================================================

/-- CC-C25: テストは Phase 1-5 に分類。D4（フェーズ順序）準拠。 -/
def cc_c25 : Assumption := {
  id := "CC-C25"
  source := .humanDecision 1 "test-phase-classification" "2026-04-11"
  content := "テストは 5 Phase に分類: Phase 1=L1 安全性、Phase 2=P2 検証、Phase 3=P4 可観測性、Phase 4=P3 統治、Phase 5=構造品質。D4 のフェーズ順序に準拠。"
  validity := some {
    sourceRef := "tests/test-all.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-C26: Phase 1-2 は critical。失敗時は後続 Phase をスキップ。 -/
def cc_c26 : Assumption := {
  id := "CC-C26"
  source := .humanDecision 1 "critical-phase-policy" "2026-04-11"
  content := "Phase 1 (L1) と Phase 2 (P2) は critical phase。これらが fail すると後続の Phase 3-5 をスキップする。D4 の「先行フェーズを壊す変更は後続の信頼性を損なう」を実装。"
  validity := some {
    sourceRef := "tests/test-all.sh CRITICAL_PHASES"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-H33: check() 関数パターンに 2 つの variant がある。 -/
def cc_h33 : Assumption := {
  id := "CC-H33"
  source := .llmInference
    ["CC-C25"]
    "check() 関数が統一された場合に反証される"
  content := "check() 関数に 2 variant: (a) 2引数 (name, eval-string) — 構造テスト用、(b) 3引数 (id, name, command-array) — カバレッジテスト用。CLAUDE.md に未記載。"
  validity := some {
    sourceRef := "tests/test-l1-structural.sh + tests/test-axiom-card-coverage.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 90
  }
}

/-- CC-H34: XFAIL + baseline パターンは既知の進行中ギャップにのみ使用。 -/
def cc_h34 : Assumption := {
  id := "CC-H34"
  source := .llmInference
    ["CC-C25"]
    "XFAIL パターンが廃止された場合に反証される"
  content := "XFAIL + baseline パターンは「既知の進行中ギャップ」にのみ使用。FAIL カウントをインクリメントしない。利用条件は各テストのコメントに暗黙的に記載。"
  validity := some {
    sourceRef := "tests/test-refs-integrity.sh + tests/test-axiom-card-coverage.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 90
  }
}

/-- CC-H35: テスト命名規則: S1.x（構造）、B2.x（振る舞い）、AC.x（カバレッジ）、RI.x（整合性）。 -/
def cc_h35 : Assumption := {
  id := "CC-H35"
  source := .llmInference
    ["CC-C25"]
    "テスト命名規則が変更された場合に反証される"
  content := "テスト ID は Phase.番号 形式: S=structural、B=behavioral、AC=axiom-card、RI=refs-integrity、DG=depgraph、WC=workflow-conformance。trace-map.json がテスト→命題マッピングを管理。"
  validity := some {
    sourceRef := "tests/trace-map.json"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

-- ============================================================
-- C/H: #404 データスキーマ契約
-- ============================================================

/-- CC-C27: deferred-status.json が deferred items の正規ソース。 -/
def cc_c27 : Assumption := {
  id := "CC-C27"
  source := .humanDecision 1 "deferred-canonical-source" "2026-04-11"
  content := "deferred-status.json が deferred items の正規ソース。evolve-history.jsonl の .deferred[] は使用しない。schema_version, last_updated_run, items を含む。"
  validity := some {
    sourceRef := ".claude/metrics/deferred-status.json"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-C28: p2-verified.jsonl の検証トークンは TTL 10 分（epoch ベース）。 -/
def cc_c28 : Assumption := {
  id := "CC-C28"
  source := .humanDecision 1 "p2-token-ttl" "2026-04-11"
  content := "p2-verified.jsonl の検証トークンは TTL=600 秒（10 分）。epoch フィールドで時刻を記録し、p2-verify-on-commit.sh が AGE を計算して有効性を判定する。"
  validity := some {
    sourceRef := ".claude/hooks/p2-verify-on-commit.sh TTL=600"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

/-- CC-H36: evolve-history.jsonl の書き込み元は evolve-metrics-recorder.sh（PostToolUse hook）。
    observe.sh は読み取り専用。 -/
def cc_h36 : Assumption := {
  id := "CC-H36"
  source := .llmInference
    ["CC-H5"]
    "evolve-metrics-recorder.sh が廃止された場合に反証される"
  content := "evolve-history.jsonl の書き込みは evolve-metrics-recorder.sh (PostToolUse hook) が担当。observe.sh は読み取り専用。#404 issue の記載（observe.sh writes）は誤り。"
  validity := some {
    sourceRef := ".claude/hooks/evolve-metrics-recorder.sh + scripts/observe.sh"
    lastVerified := "2026-04-11"
    reviewInterval := some 90
  }
}

/-- CC-H37: artifact-manifest.json の _comment エントリはクエリ時に除外が必要。 -/
def cc_h37 : Assumption := {
  id := "CC-H37"
  source := .llmInference
    ["CC-C27"]
    "artifact-manifest.json が _comment パターンを廃止した場合に反証される"
  content := "artifact-manifest.json の artifacts 配列に _comment オブジェクトが混在。jq '.artifacts[] | .path' は null を返す。select(has(\"path\")) 等の防御的クエリが必要。"
  validity := some {
    sourceRef := "artifact-manifest.json"
    lastVerified := "2026-04-11"
    reviewInterval := some 90
  }
}

/-- CC-H38: データ形式の使い分け: JSON=構成, YAML=宣言, JSONL=ログ（append-only）。 -/
def cc_h38 : Assumption := {
  id := "CC-H38"
  source := .llmInference
    ["CC-C27", "CC-C28"]
    "プロジェクトのデータ形式方針が変更された場合に反証される"
  content := "データ形式の暗黙の使い分け: JSON=構造化設定/マニフェスト（mutable）、YAML=宣言的定義（dependency-graph.yaml）、JSONL=時系列ログ（append-only、evolve-history.jsonl, p2-verified.jsonl 等）。明文化された基準はない。"
  validity := some {
    sourceRef := ".claude/metrics/ + .claude/skills/dependency-graph.yaml"
    lastVerified := "2026-04-11"
    reviewInterval := some 180
  }
}

-- ============================================================
-- C/H: hook パス解決（セッション中に発見）
-- ============================================================

/-- CC-H26: hook コマンドは $CLAUDE_PROJECT_DIR で絶対パス化する必要がある。
    settings.json の相対パス (bash .claude/hooks/...) は hook runner の CWD が
    project root と異なる場合に失敗する。 -/
def cc_h26 : Assumption := {
  id := "CC-H26"
  source := .llmInference
    ["CC-H1"]
    "Claude Code が hook runner の CWD を project root に固定した場合に反証される"
  content := "hook コマンドは $CLAUDE_PROJECT_DIR を使って絶対パス化する。settings.json の相対パス (bash .claude/hooks/...) は hook runner の CWD 依存で不安定。相対パスだと全 hook が 'No such file or directory' で非稼働になる（exit 127、非ブロック）。"
  validity := some {
    sourceRef := ".claude/settings.json hooks"
    lastVerified := "2026-04-11"
    reviewInterval := some 60
  }
}

-- ============================================================
-- 仮定の一覧
-- ============================================================

/-- Claude Code インスタンスの全仮定。 -/
def allAssumptions : List Assumption :=
  [cc_c1, cc_c2, cc_c3, cc_c4, cc_c5, cc_c6, cc_c8, cc_c9, cc_c10,
   cc_c11, cc_c12, cc_c13, cc_c14, cc_c15, cc_c16, cc_c17, cc_c18, cc_c19, cc_c20,
   cc_c21, cc_c22, cc_c23, cc_c24, cc_c25, cc_c26, cc_c27, cc_c28,
   cc_h1, cc_h2, cc_h3, cc_h4, cc_h5, cc_h6, cc_h7,
   cc_h8, cc_h9, cc_h10, cc_h11, cc_h12, cc_h13, cc_h14, cc_h15,
   cc_h16, cc_h17, cc_h18, cc_h19, cc_h20, cc_h21, cc_h22, cc_h23, cc_h24, cc_h25,
   cc_h26, cc_h27, cc_h28, cc_h29, cc_h30, cc_h31, cc_h32, cc_h33, cc_h34, cc_h35,
   cc_h36, cc_h37, cc_h38]

end Manifest.Models.Instances.ClaudeCode

import Manifest.Models.Assumptions.EpistemicLayer

/-!
# Claude Code 条件付き設計基礎 — 仮定 (C/H)

条件付き公理系 S=(A,C,H,D) の Claude Code インスタンスにおける仮定を定義する。

## 認識論的出自

- **C (Human Decision)**: Claude Code をこのプロジェクトの実行環境として選定した
  人間の設計判断。T6（人間の最終決定権）に基づく。
- **H (LLM Inference)**: Claude Code のドキュメント・実装から LLM が推論した
  プラットフォーム特性。各 H に反証条件を付与。

## 時間的有効性 (#225)

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
    hook 実行はハーネスレベルで強制される。 -/
def cc_h1 : Assumption := {
  id := "CC-H1"
  source := .llmInference
    ["CC-C1"]
    "Claude Code が hook 実行をオプトアウト可能にした場合に反証される"
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
    "Docker の seccomp デフォルトプロファイルが大幅に緩和された場合に反証される"
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
-- 仮定の一覧
-- ============================================================

/-- Claude Code インスタンスの全仮定。 -/
def allAssumptions : List Assumption :=
  [cc_c1, cc_c2, cc_c3, cc_c4, cc_c5, cc_c6, cc_c8, cc_c9, cc_c10,
   cc_h1, cc_h2, cc_h3, cc_h4, cc_h5, cc_h6, cc_h7,
   cc_h8, cc_h9, cc_h10, cc_h11, cc_h12, cc_h13, cc_h14, cc_h15]

end Manifest.Models.Instances.ClaudeCode

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

-- ============================================================
-- 仮定の一覧
-- ============================================================

/-- Claude Code インスタンスの全仮定。 -/
def allAssumptions : List Assumption :=
  [cc_c1, cc_c2, cc_c3, cc_c4, cc_c5, cc_h1, cc_h2, cc_h3, cc_h4, cc_h5]

end Manifest.Models.Instances.ClaudeCode

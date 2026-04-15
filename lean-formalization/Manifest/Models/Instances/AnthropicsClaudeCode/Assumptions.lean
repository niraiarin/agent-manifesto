import Manifest.Models.Assumptions.EpistemicLayer

/-!
# AnthropicsClaudeCode Conditional Axiom System - Assumptions

条件付き公理系 S=(A,C,H,D) の AnthropicsClaudeCode インスタンスにおける仮定を定義する。

## 認識論的出自

- **C (Human Decision)**: anthropics/claude-code をエージェントハーネスとして
  使用する際の人間の設計判断。T6（人間の最終決定権）に基づく。
- **H (LLM Inference)**: anthropics/claude-code のソースコード・ドキュメントから
  LLM が推論したプラットフォーム特性。各 H に反証条件を付与。

## Temporal Validity

全ての仮定に TemporalValidity を付与する。anthropics/claude-code はアクティブに
開発中のオープンソースプロジェクトであり、仕様変更が頻繁に起こりうる。

## derivedFromPDs

各仮定は brownfield Phase 1 で収集した 302 platform decisions を根拠として参照する。
-/

namespace Manifest.Models.Instances.AnthropicsClaudeCode

open Manifest
open Manifest.Models.Assumptions

-- ============================================================
-- C: 人間の設計判断
-- ============================================================

/-- ECC-C1: 安全制約は PreToolUse hooks (exit 2 = block) で構造的に強制する。
    derivedFromPDs: PD-050, PD-071, PD-255, PD-256 -/
def ecc_c1 : Assumption := {
  id := "ECC-C1"
  source := .humanDecision 1 "L1-enforcement-method" "2026-04-12"
  content := "L1（安全境界）制約は PreToolUse hooks（exit 2 でブロック）で構造的に強制する。7 hook event types、JSON stdin/stdout contract、stderr でブロック理由表示。"
  validity := some {
    sourceRef := "hooks/ directory"
    lastVerified := "2026-04-12"
    reviewInterval := some 90
  }
}

/-- ECC-C2: 検証は multi-agent review（parallel reviewer dispatch + confidence scoring）で行う。
    derivedFromPDs: PD-150, PD-152, PD-264, PD-265 -/
def ecc_c2 : Assumption := {
  id := "ECC-C2"
  source := .humanDecision 1 "verification-method" "2026-04-12"
  content := "P2 検証は multi-agent review で行う。code-reviewer + language-specific + domain-specific の並列 dispatch。1-5 confidence scoring、senior reviewer escalation、phase-ordered review（security → correctness → style）。"
  validity := some {
    sourceRef := "agents/code-reviewer.md"
    lastVerified := "2026-04-12"
    reviewInterval := some 90
  }
}

/-- ECC-C3: Permission model は allow/deny lists + tool-specific scoping + sandbox の多層構成。
    derivedFromPDs: PD-001, PD-234, PD-255, PD-258 -/
def ecc_c3 : Assumption := {
  id := "ECC-C3"
  source := .humanDecision 1 "permission-model" "2026-04-12"
  content := "Permission model は allow/deny lists、tool-level permission scoping（allowed-tools frontmatter）、OS-level sandbox（filesystem + network restrictions）の多層構成。managed settings hierarchy（enterprise/org/project）で管理。"
  validity := some {
    sourceRef := "settings.json schema"
    lastVerified := "2026-04-12"
    reviewInterval := some 90
  }
}

/-- ECC-C4: スキルは skills/<name>/SKILL.md に永続化し、slash commands で呼び出す。
    derivedFromPDs: PD-112, PD-113, PD-118 -/
def ecc_c4 : Assumption := {
  id := "ECC-C4"
  source := .humanDecision 1 "skill-persistence" "2026-04-12"
  content := "スキルは skills/<name>/SKILL.md に永続化する。slash commands で呼び出し。dependency declarations、invocation graph、version tracking を含む skill architecture。"
  validity := some {
    sourceRef := "skills/"
    lastVerified := "2026-04-12"
    reviewInterval := some 90
  }
}

/-- ECC-C5: Git workflow は conventional commits + single-message multi-tool PR creation。
    derivedFromPDs: PD-002, PD-174, PD-177 -/
def ecc_c5 : Assumption := {
  id := "ECC-C5"
  source := .humanDecision 1 "git-workflow" "2026-04-12"
  content := "Git workflow は conventional commits、single-message multi-tool PR creation、branch protection。CI/CD は GitHub Actions で自動化（testing、release pipeline、deployment gates）。"
  validity := some {
    sourceRef := ".github/workflows/"
    lastVerified := "2026-04-12"
    reviewInterval := some 90
  }
}

/-- ECC-C6: Issue lifecycle は single-source-of-truth module + reaction-based exemptions で管理。
    derivedFromPDs: PD-008, PD-010, PD-011, PD-028 -/
def ecc_c6 : Assumption := {
  id := "ECC-C6"
  source := .humanDecision 1 "issue-lifecycle" "2026-04-12"
  content := "Issue lifecycle は issue-lifecycle module（shared label/timeout/message definitions）で管理。10+ thumbs-up で stale 免除。human comment で auto-label 除去。runtime label fetching で bot-only 操作。"
  validity := some {
    sourceRef := "issue-lifecycle.ts"
    lastVerified := "2026-04-12"
    reviewInterval := some 90
  }
}

/-- ECC-C7: Agent delegation は role-based agent specs + parallel execution で行う。
    derivedFromPDs: PD-119, PD-120, PD-142 -/
def ecc_c7 : Assumption := {
  id := "ECC-C7"
  source := .humanDecision 1 "agent-delegation" "2026-04-12"
  content := "Agent delegation は role-based agent specs（capability declarations, tool access boundaries）、parallel task execution、worktree-based file isolation で行う。MCP integration で外部サービス接続。"
  validity := some {
    sourceRef := "agents/"
    lastVerified := "2026-04-12"
    reviewInterval := some 90
  }
}

/-- ECC-C8: Plugin ecosystem は manifest.json + hook directories + versioning conventions で構成。
    derivedFromPDs: PD-077, PD-100, PD-126 -/
def ecc_c8 : Assumption := {
  id := "ECC-C8"
  source := .humanDecision 1 "plugin-architecture" "2026-04-12"
  content := "Plugin ecosystem は manifest.json schema、hook directories（CLAUDE_PLUGIN_ROOT）、versioning conventions で構成。multi-plugin loading と hook execution order で composition。per-project local config でオーバーライド。"
  validity := some {
    sourceRef := "plugins/"
    lastVerified := "2026-04-12"
    reviewInterval := some 90
  }
}

-- ============================================================
-- H: LLM 推論
-- ============================================================

/-- ECC-H1: PreToolUse hooks の exit 2 はエージェントが構造的にバイパスできない。
    derivedFromPDs: PD-050, PD-071 -/
def ecc_h1 : Assumption := {
  id := "ECC-H1"
  source := .llmInference
    ["ECC-C1"]
    "Claude Code が hook exit 2 をオプトアウト可能にした場合"
  content := "PreToolUse hooks の exit 2 はエージェントが構造的にバイパスできない（Claude Code ランタイム強制）。stderr 出力がブロック理由として表示される。PostToolUse は exit 2 を無視する仕様。"
  validity := some {
    sourceRef := "hooks/ directory"
    lastVerified := "2026-04-12"
    reviewInterval := some 60
  }
}

/-- ECC-H2: Hook I/O protocol は JSON stdin（tool_name, tool_input）+ exit code semantics。
    derivedFromPDs: PD-052, PD-053, PD-054 -/
def ecc_h2 : Assumption := {
  id := "ECC-H2"
  source := .llmInference
    ["ECC-C1"]
    "Hook I/O protocol が JSON 以外のフォーマットに変更された場合"
  content := "Hook I/O: JSON stdin with tool_name/tool_input fields。stdout で tool input modifications（JSON merge）。stderr で user messages。exit 0 = allow, exit 2 = block（PreToolUse のみ）。"
  validity := some {
    sourceRef := "hooks/ directory"
    lastVerified := "2026-04-12"
    reviewInterval := some 60
  }
}

/-- ECC-H3: Sandbox enforcement は OS-level で filesystem + network を制限する。
    derivedFromPDs: PD-234, PD-360, PD-362 -/
def ecc_h3 : Assumption := {
  id := "ECC-H3"
  source := .llmInference
    ["ECC-C3"]
    "Sandbox の実装方式が OS-level enforcement から別の方式に変更された場合"
  content := "Sandbox は OS-level enforcement で filesystem path restrictions（write-only directories）、network host allowlists を強制。excludedCommands で build tool（lake, cargo 等）を除外可能。"
  validity := some {
    sourceRef := "settings.json sandbox section"
    lastVerified := "2026-04-12"
    reviewInterval := some 60
  }
}

/-- ECC-H4: Managed settings は enterprise/org/project の 3 レベル merge で適用。
    derivedFromPDs: PD-237, PD-238, PD-337 -/
def ecc_h4 : Assumption := {
  id := "ECC-H4"
  source := .llmInference
    ["ECC-C3"]
    "Managed settings の merge semantics が変更された場合"
  content := "Managed settings は enterprise → organization → project の 3 レベルで JSON merge 適用。上位レベルの設定が下位を制約可能（strict mode 強制等）。managed-settings.json と managed-settings.d/ ディレクトリ。"
  validity := some {
    sourceRef := "managed-settings.json"
    lastVerified := "2026-04-12"
    reviewInterval := some 60
  }
}

/-- ECC-H5: Multi-agent review は confidence 1-5 scoring + senior escalation で合意形成。
    derivedFromPDs: PD-152, PD-153, PD-265 -/
def ecc_h5 : Assumption := {
  id := "ECC-H5"
  source := .llmInference
    ["ECC-C2"]
    "Review confidence scoring の仕組みが廃止された場合"
  content := "Multi-agent review は 1-5 confidence scoring（mandatory justification）で合意形成。disagreement は senior reviewer escalation で解決。phase-ordered: security → correctness → style。"
  validity := some {
    sourceRef := "agents/code-reviewer.md"
    lastVerified := "2026-04-12"
    reviewInterval := some 60
  }
}

/-- ECC-H6: Parallel agent search は keyword diversity + result deduplication で精度向上。
    derivedFromPDs: PD-003, PD-169 -/
def ecc_h6 : Assumption := {
  id := "ECC-H6"
  source := .llmInference
    ["ECC-C7"]
    "Parallel search pattern が sequential に変更された場合"
  content := "Parallel agent search は 5+ agents が diverse keywords で同時検索し、result deduplication で統合する。concurrent execution pattern により latency を最小化。"
  validity := some {
    sourceRef := "agents/ + commands/"
    lastVerified := "2026-04-12"
    reviewInterval := some 60
  }
}

/-- ECC-H7: Memory は persistent file-based で user/feedback/project/reference の 4 型。
    derivedFromPDs: PD-280, PD-281 -/
def ecc_h7 : Assumption := {
  id := "ECC-H7"
  source := .llmInference
    ["ECC-C4"]
    "Memory system が file-based から別の永続化方式に変更された場合"
  content := "Memory は persistent file-based system。4 types: user（プロフィール）, feedback（行動修正）, project（進行中の作業）, reference（外部リソース）。staleness detection + MEMORY.md index。"
  validity := some {
    sourceRef := "CLAUDE.md memory section"
    lastVerified := "2026-04-12"
    reviewInterval := some 60
  }
}

/-- ECC-H8: CI/CD は GitHub Actions + issue template auto-labeling + deployment gates。
    derivedFromPDs: PD-300, PD-305, PD-317 -/
def ecc_h8 : Assumption := {
  id := "ECC-H8"
  source := .llmInference
    ["ECC-C5"]
    "CI/CD が GitHub Actions 以外のプラットフォームに移行した場合"
  content := "CI/CD は GitHub Actions ベース。issue templates に required fields + auto-labeling。release pipeline + deployment gates。analytics logging 統合。token scoping で permission boundary 管理。"
  validity := some {
    sourceRef := ".github/workflows/"
    lastVerified := "2026-04-12"
    reviewInterval := some 60
  }
}

-- ============================================================
-- allAssumptions
-- ============================================================

/-- 全仮定のリスト。 -/
def allAssumptions : List Assumption :=
  [ecc_c1, ecc_c2, ecc_c3, ecc_c4, ecc_c5, ecc_c6, ecc_c7, ecc_c8,
   ecc_h1, ecc_h2, ecc_h3, ecc_h4, ecc_h5, ecc_h6, ecc_h7, ecc_h8]

end Manifest.Models.Instances.AnthropicsClaudeCode

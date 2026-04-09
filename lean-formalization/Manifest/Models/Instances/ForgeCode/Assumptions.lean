import Manifest.Models.Assumptions.EpistemicLayer

/-!
# ForgeCode 条件付き設計基礎 — 仮定 (C/H)

条件付き公理系 S=(A,C,H,D) の ForgeCode インスタンスにおける仮定を定義する。

## 認識論的出自

- **C (Human Decision)**: ForgeCode をエージェントプラットフォームとして使用する際の
  人間の設計判断。T6（人間の最終決定権）に基づく。
- **H (LLM Inference)**: ForgeCode のソースコード・ドキュメントから LLM が推論した
  プラットフォーム特性。各 H に反証条件を付与。

## 時間的有効性 (#225)

全ての仮定に TemporalValidity を付与する。ForgeCode はアクティブに開発中の
オープンソースプラットフォームであり、仕様変更が頻繁に起こりうる。

## derivedFromPDs

各仮定は platform-decisions.json の PD-ID を根拠として参照する（D17 Step 0→1 トレーサビリティ）。
-/

namespace Manifest.Models.Instances.ForgeCode

open Manifest
open Manifest.Models.Assumptions

-- ============================================================
-- C: 人間の設計判断
-- ============================================================

/-- FC-C1: L1 制約はポリシーエンジン (Deny rules) + AGENTS.md 規範で強制する。
    ForgeCode には Claude Code の PreToolUse hook に相当するブロック機構がないため、
    Policy の Deny ルールが主防衛線、AGENTS.md が規範的補完。
    derivedFromPDs: PD-1, PD-2, PD-3, PD-74 -/
def fc_c1 : Assumption := {
  id := "FC-C1"
  source := .humanDecision 1 "L1-enforcement-method" "2026-04-09"
  content := "L1（倫理・安全）制約は ForgeCode のポリシーエンジン（Deny ルール）で構造的に強制し、AGENTS.md で規範的に補完する。ポリシーエンジンは Allow/Deny/Confirm の 3 値を持ち、Deny は即座にブロックする。"
  validity := some {
    sourceRef := "crates/forge_domain/src/policies/engine.rs"
    lastVerified := "2026-04-09"
    reviewInterval := some 90
  }
}

/-- FC-C2: 検証は sage エージェント（read-only）への Task 委譲で行う（P2 Worker/Verifier 分離）。
    sage はツールホワイトリストにより書き込み不可が構造的に保証される。
    derivedFromPDs: PD-11, PD-12, PD-13 -/
def fc_c2 : Assumption := {
  id := "FC-C2"
  source := .humanDecision 1 "verification-method" "2026-04-09"
  content := "P2 検証は sage エージェント（read-only）への Task 委譲で行う。sage は write/shell/patch ツールを持たず、構造的に副作用なし。forge (Worker) と sage (Verifier) はコンテキスト分離される。"
  validity := some {
    sourceRef := "crates/forge_repo/src/agents/sage.md"
    lastVerified := "2026-04-09"
    reviewInterval := some 90
  }
}

/-- FC-C3: 規範的指針は AGENTS.md に配置する。
    ForgeCode の AGENTS.md は Claude Code の CLAUDE.md に相当。
    derivedFromPDs: PD-74, PD-75 -/
def fc_c3 : Assumption := {
  id := "FC-C3"
  source := .humanDecision 1 "normative-placement" "2026-04-09"
  content := "D1 の規範的指針レイヤーに属する制約は AGENTS.md に配置する。AGENTS.md は ~/forge/ → git root → cwd の順に検索され、システムプロンプトの一部として読み込まれる。"
  validity := some {
    sourceRef := "https://forgecode.dev/docs/custom-rules/"
    lastVerified := "2026-04-09"
    reviewInterval := some 180
  }
}

/-- FC-C4: スキルは SKILL.md 形式で .forge/skills/ に永続化する（D10）。
    Claude Code の SKILL.md フォーマットと互換。
    derivedFromPDs: PD-51, PD-52, PD-56 -/
def fc_c4 : Assumption := {
  id := "FC-C4"
  source := .humanDecision 1 "skill-persistence" "2026-04-09"
  content := "スキル（.forge/skills/<name>/SKILL.md）はセッション跨ぎで永続する構造であり、セッション開始時に自動ロードされる。Claude Code の SKILL.md と互換のフォーマット。project > global > built-in の優先順位。"
  validity := some {
    sourceRef := "https://forgecode.dev/docs/skills/"
    lastVerified := "2026-04-09"
    reviewInterval := some 180
  }
}

/-- FC-C5: Plan-then-Act ワークフローで計画と実行を分離する。
    muse (read-only planning) → human review → forge (implementation)。
    derivedFromPDs: PD-47, PD-11 -/
def fc_c5 : Assumption := {
  id := "FC-C5"
  source := .humanDecision 1 "plan-act-separation" "2026-04-09"
  content := "タスク実行は Plan-then-Act パターンに従う。muse エージェント（計画、read-only）が実装計画を作成し、人間がレビューした後、forge エージェント（実装、read-write）が実行する。計画と実行のコンテキスト分離により context thrashing を防ぐ。"
  validity := some {
    sourceRef := "https://forgecode.dev/docs/plan-and-act-guide/"
    lastVerified := "2026-04-09"
    reviewInterval := some 90
  }
}

/-- FC-C6: D18（マルチエージェント協調）の実現として Task tool による
    エージェント間委譲を使用する。
    derivedFromPDs: PD-14, PD-15 -/
def fc_c6 : Assumption := {
  id := "FC-C6"
  source := .humanDecision 1 "coordination-primitive" "2026-04-09"
  content := "D18 の実現として Task tool によるエージェント間委譲を使用する。Task tool calls は並列実行され（他のツールは逐次）、agent-as-tool パターンで再帰的問題解決が可能。カスタムエージェントは .forge/agents/ に Markdown + YAML frontmatter で定義。"
  validity := some {
    sourceRef := "crates/forge_domain/src/tools/catalog.rs (Task)"
    lastVerified := "2026-04-09"
    reviewInterval := some 90
  }
}

/-- FC-C7: Git worktree sandbox で実験的変更を隔離する。
    OS レベルのサンドボックスではなく、ファイルシステムレベルの隔離。
    derivedFromPDs: PD-59, PD-60 -/
def fc_c7 : Assumption := {
  id := "FC-C7"
  source := .humanDecision 1 "sandbox-method" "2026-04-09"
  content := "実験的変更は --sandbox フラグによる git worktree 隔離で行う。OS レベルのプロセスサンドボックスではなく、git/filesystem レベルの隔離。既存 worktree があれば再利用する。"
  validity := some {
    sourceRef := "crates/forge_main/src/sandbox.rs"
    lastVerified := "2026-04-09"
    reviewInterval := some 90
  }
}

-- ============================================================
-- H: LLM 推論
-- ============================================================

/-- FC-H1: ポリシーエンジンの Deny はエージェントがバイパスできない。
    ポリシー評価はランタイムレベルで全操作（read/write/execute/fetch）に適用される。
    derivedFromPDs: PD-1, PD-3, PD-4 -/
def fc_h1 : Assumption := {
  id := "FC-H1"
  source := .llmInference
    ["FC-C1"]
    "ForgeCode がポリシー評価をオプトアウト可能にした場合、またはポリシーエンジンが削除された場合に反証される"
  content := "ポリシーエンジンの Deny ルールはランタイムが全 read/write/execute/fetch 操作に対して評価する。エージェントの裁量でスキップできない。ただし OS レベルの強制ではないため、shell 経由の間接実行に対する完全な防御ではない可能性がある。"
  validity := some {
    sourceRef := "crates/forge_domain/src/policies/engine.rs"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- FC-H2: sage エージェントは構造的に書き込み不可。ツールホワイトリストに
    write/shell/patch が含まれないことで保証される。
    derivedFromPDs: PD-12, PD-13, PD-18 -/
def fc_h2 : Assumption := {
  id := "FC-H2"
  source := .llmInference
    ["FC-C2"]
    "sage にwrite/shell/patch ツールが追加された場合に反証される"
  content := "sage エージェントのツールリストは sem_search, search, read, fetch のみ。ツール制限はエージェント定義レベルで静的に設定され、ランタイムが強制する。sage は D2 の contextSeparated + executionAutomatic 条件を構造的に満たす。ただし同一モデルファミリのため evaluatorIndependent=false。"
  validity := some {
    sourceRef := "crates/forge_repo/src/agents/sage.md"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- FC-H3: Doom loop 検出がランタイムレベルで非収束を検知し介入する。
    D15b（非収束→人間介入）の構造的実装。
    derivedFromPDs: PD-42, PD-43 -/
def fc_h3 : Assumption := {
  id := "FC-H3"
  source := .llmInference
    ["FC-C1"]
    "doom loop 検出が削除されるか、検出後に自動終了ではなくメッセージ注入のみになった場合の挙動変更で反証される（現在はメッセージ注入）"
  content := "Doom loop 検出は連続同一呼び出し [A,A,A,A] と反復パターン [A,B,C][A,B,C][A,B,C] の 2 種を閾値 3 で検知する。検知時はメッセージ注入（終了ではなく誘導）で対応する。D15b の「非収束→介入」を構造的に実装。"
  validity := some {
    sourceRef := "crates/forge_app/src/hooks/doom_loop.rs"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- FC-H4: Task tool による並列委譲は、他のツールとは異なる実行モデルを持つ。
    Task のみ並列、他は逐次。これは意図的なアーキテクチャ判断。
    derivedFromPDs: PD-15, PD-14 -/
def fc_h4 : Assumption := {
  id := "FC-H4"
  source := .llmInference
    ["FC-C6"]
    "全ツールが並列実行されるようになった場合、またはTask のみ逐次になった場合に反証される"
  content := "オーケストレータは Task tool calls を他のツールと分離し、Task のみ join_all で並列実行する。非 Task ツールは UI 同期ハンドシェイク付きで逐次実行される。この非対称性は、エージェント間委譲は独立しているが、ファイル操作等は順序保証が必要というドメイン知識に基づく。"
  validity := some {
    sourceRef := "crates/forge_app/src/orch.rs"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- FC-H5: コンテキスト圧縮は tool-call/result ペアの原子性を保証する。
    ペアの途中で切断しない。D15c（eviction 不変性）の具体化。
    derivedFromPDs: PD-33, PD-34, PD-35 -/
def fc_h5 : Assumption := {
  id := "FC-H5"
  source := .llmInference
    ["FC-C3"]
    "圧縮がペア原子性を保証しなくなった場合に反証される"
  content := "ForgeCode のコンテキスト圧縮は Evict(percentage) + Retain(count) の二重戦略で、min/max で合成可能。圧縮時に tool-call と対応する tool-result のペアを分断しない原子性不変条件がある。システムメッセージは決して削除されない。"
  validity := some {
    sourceRef := "crates/forge_domain/src/compact/"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- FC-H6: Mandatory todo_write がタスク完了率を大幅に改善する。
    タスク追跡の構造的強制は D15a/D15b の実効性を高める。
    derivedFromPDs: PD-44, PD-45, PD-46 -/
def fc_h6 : Assumption := {
  id := "FC-H6"
  source := .llmInference
    ["FC-C5"]
    "todo_write が任意になった場合、またはタスク追跡なしで同等の成果が得られるエビデンスが出た場合に反証される"
  content := "todo_write の強制化はパス率を 38% → 66% に改善した（TermBench 2.0）。Pending → InProgress → Completed|Cancelled の状態機械で、pending_todos ハンドラが未完了項目を検知して早期終了を防止する。タスク追跡がハーネスレベルで強制される点が特徴。"
  validity := some {
    sourceRef := "https://forgecode.dev/blog/benchmarks-dont-matter/"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- FC-H7: Tiered thinking policy はフェーズに応じて推論深度を動的に調整する。
    これは D16c（リソース配分は寄与度に応じる）の推論コストへの適用。
    derivedFromPDs: PD-48, PD-19 -/
def fc_h7 : Assumption := {
  id := "FC-H7"
  source := .llmInference
    ["FC-C5"]
    "全ターンで均一な推論深度に変更された場合に反証される"
  content := "Tiered thinking policy: ターン 1-10 は high thinking（計画・構造把握）、ターン 11+ は low thinking（機械的実行）、検証スキル起動時は再び high thinking。推論コストの非一様配分により、限られたリソースでの品質最大化を図る。"
  validity := some {
    sourceRef := "https://forgecode.dev/blog/benchmarks-dont-matter/"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- FC-H8: ファイルスナップショットにより変更前の状態が保存され、Undo が可能。
    D15c（eviction feasibility）のファイル操作版。
    derivedFromPDs: PD-81, PD-26 -/
def fc_h8 : Assumption := {
  id := "FC-H8"
  source := .llmInference
    ["FC-C7"]
    "スナップショット機構が削除された場合、またはUndo がファイル操作以外に拡張された場合に更新が必要"
  content := "ForgeCode はファイル変更前にタイムスタンプ付きスナップショットをパスベースハッシュで保存する。Undo ツールがスナップショットから復元を行う。これにより実験的変更の安全な取り消しが git worktree sandbox と独立に可能。"
  validity := some {
    sourceRef := "crates/forge_domain/src/snapshot.rs"
    lastVerified := "2026-04-09"
    reviewInterval := some 90
  }
}

/-- FC-H9: ツール名が LLM の訓練データパターンに意図的に合わせられている。
    加えてランタイム補正層が命名不一致を吸収する。
    derivedFromPDs: PD-23, PD-24 -/
def fc_h9 : Assumption := {
  id := "FC-H9"
  source := .llmInference
    ["FC-C1"]
    "ツール名の訓練データ整合方針が放棄された場合、または補正層が削除された場合に反証される"
  content := "ForgeCode はツール名・パラメータ名を LLM の訓練データに頻出するパターンに意図的に合わせている（例: old_string/new_string）。さらにランタイム補正層が実行前に命名不一致を検出・修正する。これにより tool-call エラー率を削減する。D16b（入力設計→出力品質）の実装。"
  validity := some {
    sourceRef := "https://forgecode.dev/blog/benchmarks-dont-matter/"
    lastVerified := "2026-04-09"
    reviewInterval := some 60
  }
}

/-- FC-H10: ForgeCode の設計哲学は「制約による品質」— アーキテクチャが
    解法を 1 つに絞ることでレビュー容易性と正確性を高める。
    derivedFromPDs: PD-12, PD-18, PD-23, PD-42 -/
def fc_h10 : Assumption := {
  id := "FC-H10"
  source := .llmInference
    ["FC-C1", "FC-C2"]
    "ForgeCode が設計哲学を転換し、制約よりも柔軟性を優先するようになった場合に反証される"
  content := "ForgeCode の設計哲学 'Simple Over Easy' は、アーキテクチャ制約により解法を一意に絞ることで品質を確保する。ツールホワイトリストによるエージェント能力制限、ポリシーエンジンによる操作制限、doom loop 検出による非収束防止はすべてこの哲学の具現化。D1（構造的強制）の設計思想と高い親和性を持つ。"
  validity := some {
    sourceRef := "https://forgecode.dev/blog/simple-is-not-easy/"
    lastVerified := "2026-04-09"
    reviewInterval := some 180
  }
}

/-- FC-H11: ForgeCode はエージェントごとに異なるプロバイダ/モデルを設定可能。
    これにより sage を異なるモデルファミリで動かすことで evaluatorIndependent=true を
    達成可能（ただしデフォルトでは同一プロバイダ）。
    derivedFromPDs: PD-57, PD-58 -/
def fc_h11 : Assumption := {
  id := "FC-H11"
  source := .llmInference
    ["FC-C2", "FC-C6"]
    "エージェントごとのプロバイダ/モデル設定が廃止された場合に反証される"
  content := "ForgeCode はカスタムエージェント定義で provider と model を個別に指定可能。sage を異なるモデルファミリ（例: Anthropic の forge に対して OpenAI の sage）で動かすことで、D2 の evaluatorIndependent=true を設定レベルで達成可能。ただしデフォルト設定では同一プロバイダを使用するため、明示的な設定変更が必要。"
  validity := some {
    sourceRef := "crates/forge_domain/src/agent.rs (provider, model fields)"
    lastVerified := "2026-04-09"
    reviewInterval := some 90
  }
}

-- ============================================================
-- 仮定の一覧
-- ============================================================

/-- ForgeCode インスタンスの全仮定。 -/
def allAssumptions : List Assumption :=
  [fc_c1, fc_c2, fc_c3, fc_c4, fc_c5, fc_c6, fc_c7,
   fc_h1, fc_h2, fc_h3, fc_h4, fc_h5, fc_h6, fc_h7, fc_h8, fc_h9, fc_h10, fc_h11]

end Manifest.Models.Instances.ForgeCode

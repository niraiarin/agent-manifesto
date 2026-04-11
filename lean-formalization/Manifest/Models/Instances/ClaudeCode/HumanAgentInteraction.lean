import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions
import Manifest.Models.Instances.ClaudeCode.ConditionalDesignFoundation

/-!
# Claude Code Conditional Axiom System - Human-Agent Interaction

T6（人間の最終決定権）の運用インスタンス、Agent 間のコンテキスト遷移、
Judge の評価プロセスを条件付き公理として構造化する。

## 位置づけ

```
T6, T1, T2, P2, D2, D5, P3 (core axioms, プラットフォーム非依存)
  ↓ 条件付き導出（CC-C18~C20, CC-H23~H25）
HAI1-HAI6 (このファイル, 運用パターン固有)
```

## 反証トリガー

二重:
1. CC プラットフォーム仕様変更（hook 仕様、Agent tool 仕様等）
2. プロジェクト運用方針変更（T6 遅延パターン、Judge プロセス等）

CC 仕様が不変でも運用方針の変更で独立に反証されうる。
InstructionDesign.lean（CC 固有パターン）とは独立。

## Design Policy

- 手書き（人間・エージェント相互作用の意味的推論が必要）
- 各 HAI axiom に Derivation Card を付与
- 0 sorry を維持
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest

-- ============================================================
-- T6 遅延パターンの型定義
-- ============================================================

/-- エージェントの自己変更が制限される理由。
    D1（構造的強制）の自己保護機能。 -/
inductive SelfModificationBarrier where
  | hookSelfProtection  -- hook ファイルが L1 guard で保護されている
  | settingsProtection  -- settings.json が変更禁止
  | blockingHookLoop    -- blocking hook が修正方向の Edit もブロック
  deriving BEq, Repr

/-- 自己変更制限時の解決方法。T6 遅延パターン。 -/
inductive ResolutionMethod where
  | tmpScript     -- /tmp/setup-*.sh にスクリプト生成 → 人間に実行依頼
  | humanSed      -- 人間が直接 sed/vi で修正
  | issueCreation -- issue を作成して後続セッションに委譲
  deriving BEq, Repr

/-- 解決方法が T6（人間の最終決定権）を満たすか。
    全ての解決方法で人間が最終実行者。 -/
def satisfiesT6 : ResolutionMethod → Bool
  | .tmpScript     => true  -- 人間がスクリプトを確認・実行
  | .humanSed      => true  -- 人間が直接操作
  | .issueCreation => true  -- 人間が issue を判断

/-- [Derivation Card]
    Derives from: T6 (human authority), D1 (enforcement layering), CC-C18
    Proposition: HAI1
    Content: All resolution methods for self-modification barriers satisfy T6.
      When agent cannot modify governance infrastructure (hooks, settings),
      it delegates to human. The delegation itself is a T6 operational instance.
    Proof strategy: intro + cases -/
theorem hai1_all_resolutions_satisfy_t6 :
  ∀ (r : ResolutionMethod), satisfiesT6 r = true := by
  intro r; cases r <;> rfl

-- ============================================================
-- HAI2: Critical リスクと人間レビュー (T6 + D2)
-- ============================================================

/-- リスクレベルごとの検証要件。
    CC6（critical は CC subagent では不十分）の運用拡張。 -/
inductive ReviewRequirement where
  | subagentSufficient  -- subagent のみで検証可能
  | humanRequired       -- 人間レビュー必須
  deriving BEq, Repr

/-- リスクレベル→検証要件マッピング。CC-C19 に基づく。 -/
def reviewForRisk : VerificationRisk → ReviewRequirement
  | .low      => .subagentSufficient
  | .moderate => .subagentSufficient
  | .high     => .subagentSufficient  -- CC5: 3/4 条件で十分
  | .critical => .humanRequired       -- CC6: 4/4 必要だが未達

/-- [Derivation Card]
    Derives from: T6 (human authority), D2 (worker-verifier separation),
                  CC-C19, CC5, CC6
    Proposition: HAI2
    Content: Critical risk changes require human review.
      CC subagent satisfies only 3/4 independence conditions (CC5).
      Critical risk requires 4/4 (CC6). The gap is filled by T6: human review.
    Proof strategy: rfl -/
theorem hai2_critical_needs_human :
  reviewForRisk VerificationRisk.critical = .humanRequired := by rfl

/-- [Derivation Card]
    Derives from: CC5 (hook-invoked subagent satisfies high)
    Proposition: HAI2b
    Content: High risk is the maximum that subagent alone can handle.
    Proof strategy: rfl -/
theorem hai2b_high_subagent_sufficient :
  reviewForRisk VerificationRisk.high = .subagentSufficient := by rfl

-- ============================================================
-- HAI3: セッション間永続化媒体 (T1 → T2 橋渡し)
-- ============================================================

/-- セッション間で情報を永続化する媒体。
    T1（エージェントはセッション有界）→ T2（構造は永続）の橋渡し。 -/
inductive PersistenceMedium where
  | memory         -- MEMORY.md: ユーザー知識、フィードバック、プロジェクト情報
  | evolveHistory  -- evolve-history.jsonl: /evolve 実行履歴（append-only）
  | issueComment   -- GitHub issue コメント: 研究の経緯と判断根拠
  | leanFile       -- Lean ファイル: 公理・定理（最も永続的）
  | skillFile      -- SKILL.md: 手順の永続化
  deriving BEq, Repr

/-- 媒体の永続性レベル（高い = より長く生存）。 -/
def persistenceLevel : PersistenceMedium → Nat
  | .memory        => 1  -- セッション跨ぎだが退役可能
  | .evolveHistory => 2  -- append-only、プロジェクト寿命
  | .issueComment  => 3  -- GitHub 上に永続、検索可能
  | .skillFile     => 4  -- git 管理、バージョン追跡
  | .leanFile      => 5  -- 形式検証済み、最高の信頼性

/-- [Derivation Card]
    Derives from: T1 (session boundedness), T2 (structure outlives agent), CC-C20
    Proposition: HAI3
    Content: Persistence media have a hierarchy.
      Lean files are the most persistent (T2, formally verified).
      Memory is the least persistent (can be retired per P3).
      This hierarchy guides "what to preserve" decisions in context transitions.
    Proof strategy: simp on persistenceLevel -/
theorem hai3_persistence_hierarchy :
  persistenceLevel .memory < persistenceLevel .leanFile ∧
  persistenceLevel .evolveHistory < persistenceLevel .skillFile := by
  simp [persistenceLevel]

-- ============================================================
-- HAI4: Agent 間情報フロー (P2 framingIndependent)
-- ============================================================

/-- Agent 間の情報共有レベル。 -/
inductive InfoSharingLevel where
  | resultOnly     -- 結果のみ（意図説明なし）= framingIndependent
  | withIntent     -- 結果 + 意図説明 = framing dependent
  | fullContext    -- 全コンテキスト共有 = NOT context separated
  deriving BEq, Repr

/-- 情報共有レベルが P2 の framingIndependent を満たすか。 -/
def isFramingIndependent : InfoSharingLevel → Bool
  | .resultOnly  => true   -- Verifier が自分の基準で判断
  | .withIntent  => false  -- Worker の意図に影響される
  | .fullContext => false  -- コンテキスト分離も失われる

/-- [Derivation Card]
    Derives from: P2 (cognitive separation), D2 (verification independence), CC-H23
    Proposition: HAI4
    Content: Result-only information sharing satisfies framingIndependent.
      Verifier does not receive Worker's intent, so it judges by its own criteria.
      This is explicitly documented in verify/SKILL.md.
    Proof strategy: rfl -/
theorem hai4_result_only_framing_independent :
  isFramingIndependent .resultOnly = true := by rfl

/-- [Derivation Card]
    Derives from: HAI4, CC-H23
    Proposition: HAI4b
    Content: Sharing intent violates framingIndependent.
    Proof strategy: rfl -/
theorem hai4b_intent_violates :
  isFramingIndependent .withIntent = false := by rfl

-- ============================================================
-- HAI5: Skill 間 I/O 契約 (D5)
-- ============================================================

/-- skill 間の入出力契約が宣言されているか。
    D5（仕様→テスト→実装）: skill の連鎖も仕様で宣言されるべき。 -/
inductive ContractStatus where
  | declared    -- dependency-graph.yaml の invoked_by/expected_output で宣言
  | undeclared  -- 暗黙の依存
  deriving BEq, Repr

/-- 契約の宣言状態が D5 を満たすか。 -/
def satisfiesD5 : ContractStatus → Bool
  | .declared   => true
  | .undeclared => false

/-- [Derivation Card]
    Derives from: D5 (spec-test-impl), CC-H24
    Proposition: HAI5
    Content: Declared skill-to-skill I/O contracts satisfy D5.
      dependency-graph.yaml provides the specification layer for inter-skill dependencies.
      Undeclared dependencies violate D5 (implementation without specification).
    Proof strategy: constructor with rfl -/
theorem hai5_declared_satisfies_d5 :
  satisfiesD5 .declared = true ∧
  satisfiesD5 .undeclared = false := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- HAI6: Judge 評価の有界反復 (P3)
-- ============================================================

/-- Judge の減点分類。 -/
inductive DeductionClass where
  | addressable    -- 現在のスコープ内で対処可能
  | unaddressable  -- 構造的限界、人間に報告
  deriving BEq, Repr

/-- 減点が自動解消可能か。 -/
def canAutoResolve : DeductionClass → Bool
  | .addressable   => true   -- 修正→再判定ループ
  | .unaddressable => false  -- 人間判断が必要

/-- 減点解消ループの最大回数。
    D15a（有限リソース下の retry bound）に基づく。 -/
def maxResolutionRounds : Nat := 2

/-- [Derivation Card]
    Derives from: P3 (governed learning), D15 (harness engineering), CC-H25
    Proposition: HAI6
    Content: Judge deduction resolution is bounded.
      Addressable deductions enter a fix→re-judge loop (max 2 rounds).
      Unaddressable deductions are reported to human (T6).
      Exceeding 2 rounds indicates a process problem, not a content problem.
    Proof strategy: constructor with rfl/omega -/
theorem hai6_bounded_resolution :
  canAutoResolve .addressable = true ∧
  canAutoResolve .unaddressable = false ∧
  maxResolutionRounds = 2 := by
  refine ⟨rfl, rfl, ?_⟩; rfl

end Manifest.Models.Instances.ClaudeCode

import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions
import Manifest.Models.Instances.ClaudeCode.ConditionalDesignFoundation

/-!
# Claude Code 条件付き公理系: バージョン管理と協調開発 (#399)

Git/GitHub をバージョン管理プラットフォームとして使用する際の
運用パターンを条件付き公理として構造化する。

## 位置づけ

```
D10, P3, P2, P4, D9 (DesignFoundation.lean, プラットフォーム非依存)
  ↓ 条件付き導出（CC-C11~C14, CC-H16~H18）
VCS1-VCS5 (このファイル, Git/GitHub 固有)
```

## 反証トリガー

Git/GitHub の仕様変更、または VCS プラットフォーム移行時に
このファイル全体が再検証対象となる。
ConditionalDesignFoundation.lean（CC プリミティブ固有）とは
独立に反証されうる。

## 設計方針

- 手書き（VCS 運用パターンの意味的推論が必要）
- 各 VCS axiom に Derivation Card を付与
- 0 sorry を維持
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest

-- ============================================================
-- VCS プリミティブの存在論的定義
-- ============================================================

/-- branch の種別。skill 名前空間に対応する。 -/
inductive BranchKind where
  | evolve    -- /evolve skill。evolve/run-{N}
  | research  -- /research skill。research/{issue}-{topic}
  | feature   -- 一般的な feature 開発
  deriving BEq, Repr

/-- PR のマージ戦略。 -/
inductive MergeStrategy where
  | squash     -- 1 PR = 1 commit on main（現在の選択）
  | merge      -- マージコミット
  | rebase     -- リベース
  deriving BEq, Repr

/-- マージ後の branch 処理方針。 -/
inductive BranchCleanup where
  | autoDelete   -- --delete-branch で自動削除
  | humanDecide  -- T6: 人間が判断
  deriving BEq, Repr

-- ============================================================
-- VCS1: Branch 命名と skill の対応 (D10)
-- ============================================================

/-- branch が skill に対応するか。
    D10（構造的永続性）: skill 名が VCS 名前空間に符号化される。 -/
def branchHasSkillAlignment : BranchKind → Bool
  | .evolve   => true   -- /evolve skill
  | .research => true   -- /research skill
  | .feature  => false  -- 汎用

/-- [Derivation Card]
    Derives from: D10 (structural permanence), CC-C11
    Proposition: VCS1
    Content: evolve and research branches encode skill identity in VCS namespace.
      This is D10's operational instance: skill names persist as branch naming conventions.
    Proof strategy: constructor with rfl -/
theorem vcs1_skill_aligned_branches :
  branchHasSkillAlignment .evolve = true ∧
  branchHasSkillAlignment .research = true := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- VCS2: Squash merge と P3 の互換性分類
-- ============================================================

/-- squash merge は原子的な変更を保証するか。
    P3 互換性分類と組み合わせて、main 上で
    1 issue = 1 commit = 1 互換性分類 を実現する。 -/
def ensuresAtomicChange : MergeStrategy → Bool
  | .squash => true   -- 複数コミットを 1 つに圧縮
  | .merge  => false  -- マージコミット追加、個別コミット残存
  | .rebase => false  -- 個別コミットが main に展開される

/-- [Derivation Card]
    Derives from: P3 (governed learning), CC-C12
    Proposition: VCS2
    Content: Squash merge ensures atomic changes on main.
      Combined with P3 compatibility classification per commit,
      this guarantees 1 issue = 1 commit = 1 classification on main.
    Proof strategy: rfl -/
theorem vcs2_squash_ensures_atomic :
  ensuresAtomicChange .squash = true := by rfl

-- ============================================================
-- VCS3: Worktree 隔離と P2
-- ============================================================

/-- worktree は物理的に分離された作業ディレクトリを提供するか。
    P2（認知的関心の分離）の VCS レベル実現。 -/
def providesPhysicalIsolation : BranchKind → Bool
  | .research => true   -- ../repo-research-ISSUE に隔離
  | .evolve   => true   -- worktree モードで隔離可能
  | .feature  => false  -- 通常はメインリポジトリ内

/-- [Derivation Card]
    Derives from: P2 (cognitive separation), CC-C13
    Proposition: VCS3
    Content: Research branches use worktree for physical isolation.
      This realizes P2 at the VCS level: research work is physically
      separated from the main repository.
    Proof strategy: rfl -/
theorem vcs3_research_isolated :
  providesPhysicalIsolation .research = true := by rfl

-- ============================================================
-- VCS4: Branch cleanup と D9 + T6
-- ============================================================

/-- branch 種別ごとの cleanup 方針。
    D9（自己メンテナンス）と T6（人間の最終決定権）の交差点。 -/
def branchCleanupPolicy : BranchKind → BranchCleanup
  | .evolve   => .autoDelete   -- 自動削除（D9: 自己メンテナンス）
  | .research => .humanDecide  -- 人間判断（T6: 研究 branch は成果物を含みうる）
  | .feature  => .humanDecide  -- 人間判断

/-- [Derivation Card]
    Derives from: D9 (self-maintenance), T6 (human authority), CC-H17
    Proposition: VCS4
    Content: Branch cleanup policy differs by kind.
      evolve branches are auto-deleted (D9: automated maintenance).
      research branches defer to human (T6: may contain valuable artifacts).
    Proof strategy: constructor with rfl -/
theorem vcs4_cleanup_policy_differs :
  branchCleanupPolicy .evolve = .autoDelete ∧
  branchCleanupPolicy .research = .humanDecide := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- VCS5: gh auth 前提条件 (L2)
-- ============================================================

/-- 外部ツールの認証状態。
    L2（リソース制約）: 外部サービスへのアクセスは認証を前提とする。 -/
inductive AuthState where
  | authenticated    -- 認証済み
  | unauthenticated  -- 未認証
  deriving BEq, Repr

/-- 認証状態が VCS 操作を許可するか。 -/
def canPerformVcsOps : AuthState → Bool
  | .authenticated   => true
  | .unauthenticated => false

/-- [Derivation Card]
    Derives from: CC-H18
    Proposition: VCS5
    Content: VCS operations require authenticated state.
      gh auth status must succeed before any gh command.
      This is an operational prerequisite not documented in CLAUDE.md.
      Not mapped to a specific L-boundary (authentication is an external dependency,
      not an ontological or resource constraint).
    Proof strategy: constructor with rfl -/
theorem vcs5_auth_required :
  canPerformVcsOps .authenticated = true ∧
  canPerformVcsOps .unauthenticated = false := by
  exact ⟨rfl, rfl⟩

end Manifest.Models.Instances.ClaudeCode

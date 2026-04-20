-- Spine 層: ResearchGoal + ResearchContext (GA-S10 研究目的 + Sub-Issue 間伝搬 context)
-- Day 55: 2 structure + inheritFrom helper、Rationale 必須化 (Day 45-48 pattern 継承)
import Init.Core
import Init.Data.List.Basic
import AgentSpec.Spine.Rationale

/-!
# AgentSpec.Spine.ResearchGoal: 研究目的 + context 伝搬 (GA-S10、Spine 層)

GA-S10「研究目的（researchGoal）と現 context が Issue 自然言語のみ、Sub-Issue 間で
伝搬されない」問題を解消。`ResearchGoal` で研究目的、`ResearchContext` で
assumptions/constraints を型化、Sub-Issue 生成時に inherit する helper 提供。

Day 44 Rationale / Day 51 State / Day 53 ResearchSpec / Day 54 ResearchNode と同
Spine layer pattern、Rationale 必須化 (GA-S8 B-2 sprint 方針を継続)。

## 設計 (10-gap-analysis.md §GA-S10 + synthesis §6.2)

    structure ResearchGoal where
      title : String
      description : String
      rationale : Rationale          -- なぜこの目的を設定するか

    structure ResearchContext where
      parentGoalId : Option String   -- 親 goal 参照 (ない = root goal)
      assumptions : List String      -- 前提事項 (C-type/H-type、Day N+ で Assumption 型化候補)
      constraints : List String      -- 制約 (Day N+ で Constraint 型化候補)
      rationale : Rationale          -- この context を定義した判断根拠

    def ResearchContext.inheritFrom (parent : ResearchContext) (newRationale : Rationale)
        : ResearchContext  -- assumptions/constraints を継承、新 rationale で上書き

Sub-Issue 生成時: child_context = parent_context.inheritFrom new_rationale。

## TyDD 原則 (Day 1-54 確立パターン適用)

- **Pattern #5**: structure + def helper
- **Pattern #6** (sorry 0): structure + deriving + helper def で完結
- **Pattern #7**: artifact-manifest 同 commit
- **Pattern #8**: title/description/assumptions/constraints/parentGoalId 全て予約語非該当

## Day 55 意思決定ログ (GA-S10 conservative、sprint 最終日)

### D1. ResearchGoal と ResearchContext を別 structure に分離
- **代案 A**: `structure ResearchGoal` に context field を内包 (1 structure で goal+context)
- **採用**: 2 structure 分離
- **理由**: GA-S10 原文「ResearchGoal / Context 型」と separate 明示。
  (a) 同一 goal に対し複数 context が存在可能 (異なる assumptions 下の変種)。
  (b) context は Sub-Issue 間で伝搬する概念、goal は node 固有。
  (c) 将来的に ResearchNode (Day 54) が goal + context を個別参照する設計に拡張可能。

### D2. parentGoalId は Option String (Day 54 ResearchNode のパターン踏襲)
- **代案 A**: `parentGoal : ResearchGoal` (直接参照)
- **採用**: `parentGoalId : Option String` (hole-driven)
- **理由**: (a) 直接参照は recursive structure となり Day 29 決定と衝突 (Spine 層は minimal)。
  (b) Sub-Issue tree 構造は Day 41 HandoffChain や Day 54 ResearchNode の String ID 参照
  パターンと対称。(c) root goal は parentGoalId = none で型表現。

### D3. inheritFrom helper で Sub-Issue 伝搬を明示
- assumptions + constraints は parent からそのまま継承、rationale のみ新 (child 判断根拠)。
- parentGoalId は child の場合 parent の id に設定 (現在は String なので caller responsibility、
  Day N+ で ResearchGoal に `id` field 追加時に自動化検討)。
-/

namespace AgentSpec.Spine

/-- GA-S10 ResearchGoal: 研究目的 (title + description + rationale)。

    研究 tree 各 node の目的を型レベルで明示、自然言語のみの Issue comment 問題を解消。
    Rationale 必須化 (Day 45-48 GA-S8 pattern 継承)。 -/
structure ResearchGoal where
  /-- 研究目的の title (short identifier)。 -/
  title : String
  /-- 研究目的の description (長文 narrative)。 -/
  description : String
  /-- この目的を設定した判断根拠 (Day 45-48 Rationale 必須化)。 -/
  rationale : Rationale
  deriving DecidableEq, Inhabited, Repr

/-- GA-S10 ResearchContext: Sub-Issue 間で伝搬する context (assumptions + constraints + rationale)。 -/
structure ResearchContext where
  /-- 親 goal への参照 ID (root goal は none)。 -/
  parentGoalId : Option String
  /-- 前提事項 (Day N+ で C-type/H-type/S-type Assumption 型に refactor 候補)。 -/
  assumptions : List String
  /-- 制約 (Day N+ で Constraint 型化候補)。 -/
  constraints : List String
  /-- この context を定義した判断根拠 (Day 45-48 Rationale 必須化)。 -/
  rationale : Rationale
  deriving DecidableEq, Inhabited, Repr

namespace ResearchGoal

/-- 自明な goal (test fixture、空 title/description + trivial rationale)。 -/
def trivial : ResearchGoal :=
  { title := "", description := "", rationale := Rationale.trivial }

/-- Smart constructor: title + description から trivial rationale 付きで構築。 -/
def ofTitle (title : String) (description : String) : ResearchGoal :=
  { title := title, description := description, rationale := Rationale.trivial }

/-- Smart constructor: title + description + rationale 全指定。 -/
def mk' (title : String) (description : String) (rationale : Rationale) : ResearchGoal :=
  { title := title, description := description, rationale := rationale }

end ResearchGoal

namespace ResearchContext

/-- 自明な root context (test fixture、parent なし / 空 assumptions / 空 constraints)。 -/
def trivial : ResearchContext :=
  { parentGoalId := none,
    assumptions := [],
    constraints := [],
    rationale := Rationale.trivial }

/-- Smart constructor: root context (parent なし)。 -/
def root (assumptions : List String) (constraints : List String)
    (rationale : Rationale) : ResearchContext :=
  { parentGoalId := none,
    assumptions := assumptions,
    constraints := constraints,
    rationale := rationale }

/-- Smart constructor: child context (parent ID 指定)。 -/
def child (parentId : String) (assumptions : List String) (constraints : List String)
    (rationale : Rationale) : ResearchContext :=
  { parentGoalId := some parentId,
    assumptions := assumptions,
    constraints := constraints,
    rationale := rationale }

/-- Sub-Issue 生成時の context 継承 (assumptions/constraints を parent からそのまま継承、
    rationale は child 判断根拠で上書き、parentGoalId は child が parent を参照)。 -/
def inheritFrom (parent : ResearchContext) (parentId : String)
    (newRationale : Rationale) : ResearchContext :=
  { parentGoalId := some parentId,
    assumptions := parent.assumptions,
    constraints := parent.constraints,
    rationale := newRationale }

/-- root context 判定 (parentGoalId = none)。 -/
def isRoot (ctx : ResearchContext) : Bool :=
  ctx.parentGoalId.isNone

/-- assumption を append する helper (immutable)。 -/
def addAssumption (ctx : ResearchContext) (a : String) : ResearchContext :=
  { ctx with assumptions := ctx.assumptions ++ [a] }

/-- constraint を append する helper (immutable)。 -/
def addConstraint (ctx : ResearchContext) (c : String) : ResearchContext :=
  { ctx with constraints := ctx.constraints ++ [c] }

end ResearchContext

end AgentSpec.Spine

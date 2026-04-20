-- Provenance 層: ResearchAgent (PROV-O 三項の Agent、Day 10 で 4 type 完備)
-- Q3 案 A: structure ResearchAgent { identity, role : Role } + inductive Role 3 variant
-- 02-data-provenance §4.1 PROV-O 100% 忠実実装
import Init.Core

/-!
# AgentSpec.Provenance.ResearchAgent: PROV-O 三項の Agent

Phase 0 Week 4-5 Provenance 層の Day 10 構成要素。02-data-provenance §4.1 PROV-O の
`ResearchAgent` を Lean 化、Day 8 Verdict + Day 9 ResearchEntity + ResearchActivity と
合わせて Provenance 層 4 type 完備 (PROV-O 三項統合完了)。

## 設計 (Section 2.18 Q3 案 A 確定、02-data-provenance §4.1 通り)

    structure ResearchAgent where
      identity : String  -- LLM session ID, human ID 等
      role : Role        -- Researcher | Reviewer | Verifier

    inductive Role where
      | Researcher       -- 主研究者
      | Reviewer         -- レビュアー
      | Verifier         -- 検証者

`identity` は Day 10 hole-driven で `String`、Day 11+ で型化検討
(LLM session ID と human ID を sum type で区別する案 C は別設計、Day 11+ 検討)。

## Mapping (Day 10、ResearchEntity 5 constructor 拡張案を採用)

Day 10 設計判断で **ResearchEntity に `Agent (a : ResearchAgent)` constructor を追加**
(5 constructor へ拡張)。これにより `ResearchAgent.toEntity` Mapping を Day 9 同パターンで提供。

PROV-O では Entity と Agent は別概念だが、Lean 統合的扱いとして 5 constructor を採用。
PROV-O `wasAttributedTo` 関係は別 inductive で Day 11+ で表現予定 (Section 2.10 Day 11+)。

## TyDD 原則 (Day 1-9 確立パターン適用)

- **Pattern #5** (def Prop signature): structure + inductive Role 先行
- **Pattern #6** (sorry 0): structure + inductive + deriving + helper で完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): `Researcher` / `Reviewer` / `Verifier` / `identity` / `role` 全て予約語ではない

## Day 10 意思決定ログ

### D1. structure ResearchAgent + inductive Role (Q3 案 A、PROV-O 100% 忠実)
- **代案 B**: structure { identity : String } のみ (Role は Day 11+ 拡充)
- **代案 C**: inductive ResearchAgent { LLM (sessionId : String), Human (id : String) }
  (T1 一時性踏襲、別設計)
- **採用**: 案 A (structure + Role inductive)
- **理由**: 02-data-provenance §4.1 PROV-O 100% 忠実、TyDD-S1、Role inductive で Day 11+ 拡充容易。
  案 C は T1 一時性との連携を Day 11+ で検討、PROV-O 通りの扱いを優先。

### D2. ResearchEntity 5 constructor 拡張採用 (Day 10 設計判断)
- **代案 A**: ResearchEntity 4 constructor 維持、ResearchAgent は独立 (PROV-O 区別を保つ)
- **採用**: ResearchEntity に `Agent (a : ResearchAgent)` constructor 追加 (5 constructor)
- **理由**: Lean 統合的扱いで Mapping 関数の uniformity を維持 (Day 9 4 toEntity と同パターン)。
  PROV-O `wasAttributedTo` 関係は別 inductive (Day 11+ で AttributionRelation 等) で表現可能。

### D3. identity を String で hole-driven (Day 11+ で型化検討)
- **採用**: `String`
- **理由**: Hypothesis (Day 6) / Failure (Day 6) と同パターン、Day 10 minimal scope。

## Day 24 追記 (Role.toCtorIdx long-deferred investigation 解消、RetirementLinterCommand.lean D14 参照)

`Role` inductive に `deriving DecidableEq, Inhabited, Repr` が付与されているため Lean 4 が auto-gen
helpers (rec / casesOn / noConfusion / toCtorIdx 等) を生成する。**Lean 4 4.29.0 upstream (since 2025-08-25)
で `toCtorIdx` は `ctorIdx` に rename され、backward compat のため旧名 `Role.toCtorIdx` が
`@[deprecated newName := Role.ctorIdx]` として残っている**。この結果 Day 18-22 の
`#check_retired_in_namespace_with_depth AgentSpec.Provenance 2` で `Role.toCtorIdx` が retired 判定
されていた (Day 20-22 で長期繰り延べだった Role.toCtorIdx 現象の root cause)。

agent-spec-lib 本体は `Role.toCtorIdx` を直接参照していない (deriving の副産物のみ) ため、本 file
に code 変更は不要。Lean 4 upgrade 時に他 auto-gen helper (sizeOf 等) も同 rename パターンに
従う可能性あり (backward-compat 付き deprecated alias として残る)。
-/

namespace AgentSpec.Provenance

/-- 研究プロセスの participant role (02-data-provenance §4.1 PROV-O Role)。 -/
inductive Role where
  /-- 主研究者 (proposes hypotheses, conducts experiments)。 -/
  | Researcher
  /-- レビュアー (peer review、critical evaluation)。 -/
  | Reviewer
  /-- 検証者 (formal verification、proof checking)。 -/
  | Verifier
  deriving DecidableEq, Inhabited, Repr

/-- 02-data-provenance §4.1 PROV-O `ResearchAgent` の Lean 化
    (Day 10 Q3 案 A: structure + Role inductive 3 variant)。

    `identity` は Day 10 hole-driven で `String` (LLM session ID, human ID 等)、
    Day 11+ で sum type 化検討。`role` は Researcher / Reviewer / Verifier の 3 variant。 -/
structure ResearchAgent where
  /-- agent identifier (Day 10 hole-driven: String、Day 11+ で型化検討)。 -/
  identity : String
  /-- agent role (Researcher / Reviewer / Verifier)。 -/
  role : Role
  deriving DecidableEq, Inhabited, Repr

namespace ResearchAgent

/-- 自明な agent (test fixture)、anonymous Researcher。 -/
def trivial : ResearchAgent := { identity := "trivial-agent", role := .Researcher }

/-- Researcher role 判定。 -/
def isResearcher (a : ResearchAgent) : Bool :=
  match a.role with
  | .Researcher => true
  | _ => false

/-- Reviewer role 判定。 -/
def isReviewer (a : ResearchAgent) : Bool :=
  match a.role with
  | .Reviewer => true
  | _ => false

/-- Verifier role 判定。 -/
def isVerifier (a : ResearchAgent) : Bool :=
  match a.role with
  | .Verifier => true
  | _ => false

/-- Smart constructor: identity 指定 + Researcher role。 -/
def mkResearcher (identity : String) : ResearchAgent :=
  { identity := identity, role := .Researcher }

/-- Smart constructor: identity 指定 + Reviewer role。 -/
def mkReviewer (identity : String) : ResearchAgent :=
  { identity := identity, role := .Reviewer }

/-- Smart constructor: identity 指定 + Verifier role。 -/
def mkVerifier (identity : String) : ResearchAgent :=
  { identity := identity, role := .Verifier }

end ResearchAgent

end AgentSpec.Provenance

-- Spine 層: State (GA-S7 Type-Safe State Machine、LifeCyclePhase + AllowedTransition)
-- Day 51 hole-driven: 05-plaintext-issue-tracker.md §4.1/§4.3 仕様準拠、8 variant + Prop 遷移関係
-- 各 Process 型への attach は Day 52+ で別検討 (Day 44 Rationale と同パターン、breaking 回避)
import Init.Core

/-!
# AgentSpec.Spine.State: Type-Safe State Machine (GA-S7、Spine 層)

GA-S7 は「Issue state が open/closed の 2 値のみ」「Org-mode 風状態遷移なし」の問題。
Lean 型で不正遷移を compile-time error 化する研究 tree leaf の state machine を Spine 層に導入。

Day 51 hole-driven: structure/inductive + Prop のみ、attach は Day 52+。Day 44 Rationale
と同パターンで独立 Spine module 配置 (layer 整合性維持)。

## 設計 (05-plaintext-issue-tracker.md §4.1/§4.3 仕様準拠)

8 variant LifeCyclePhase:
- `Proposed`: 作業開始前 (initial phase)
- `Investigating`: 調査中
- `Specifying`: 仕様確定中
- `Implementing`: 実装中
- `Reviewing`: レビュー中
- `Verified`: 検証完了 (non-terminal、Retired への遷移可)
- `Retired`: 退役済 (terminal)
- `Cancelled`: 中止 (terminal)

AllowedTransition は直列主経路 + レビュー差戻し (Reviewing → Implementing) + 任意状態から
Cancelled + Verified → Retired の 8 遷移で構成。Linear の 6 categories に「Proposed/Investigating/
Specifying」を研究特化追加した拡張版。

## TyDD 原則 (Day 1-49 確立パターン適用)

- **Pattern #5** (def Prop signature): `AllowedTransition` は inductive Prop、`transition` は def
- **Pattern #6** (sorry 0): inductive + deriving + Prop 直接展開で完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 済、本ファイル追加と同 commit
- **Pattern #8** (Lean 4 予約語回避): 全 variant / constructor 名は予約語ではない

## Day 51 意思決定ログ (GA-S7 conservative 着手、Day 50 median subagent 提案準拠)

### D1. 8 variant LifeCyclePhase (vs Linear 6 or 4 minimal)
- **代案 A**: Linear 6 (Backlog/Todo/InProgress/InReview/Done/Canceled) 直輸入
- **代案 B**: 4 minimal (Proposed/Active/Done/Cancelled)
- **採用**: 8 variant (05-plaintext-issue-tracker.md §4.1 spec 忠実)
- **理由**: 研究 tree 固有の「Investigating / Specifying」は Linear の Backlog/Todo と別概念。
  deep-research 特有の "仕様検討フェーズ" を型で区別する価値。Linear の Backlog/Todo 相当は
  Proposed に統合 (研究プロセスで「未着手」の細分化は不要)。

### D2. AllowedTransition inductive Prop (vs Bool 関数 or Decidable)
- **代案 A**: `def isAllowed : LifeCyclePhase → LifeCyclePhase → Bool`
- **採用**: inductive Prop (05-plaintext-issue-tracker.md §4.3 spec 忠実)
- **理由**: Lean の型 system が「遷移 proof を要求する関数」を直接表現できる
  (`def transition (current next : LifeCyclePhase) (proof : AllowedTransition current next)`)。
  Bool では不正遷移時の Lean compile-time error が得られない。Decidable instance は Day 52+
  で decide の dispatch 用に追加検討。

### D3. Day 51 は Rationale 保持せず (Spine 並列、Day 50 median subagent 提案)
- **代案**: `structure State { phase : LifeCyclePhase, rationale : Rationale }`
- **採用**: LifeCyclePhase inductive 単独 (Rationale 非保持)
- **理由**: LifeCyclePhase は判断ではなく状態値、judgmental 情報 (Rationale) は遷移 event 側に
  付与するのが自然。Day 52+ で `StateTransitionEvent` 等の Process 層 event 型を導入する際に
  rationale : Rationale 必須化 (Day 47 Evolution.refineWith と同 pattern)。
-/

namespace AgentSpec.Spine

/-- GA-S7 LifeCyclePhase (Day 51 8 variant、05-plaintext-issue-tracker.md §4.1 仕様準拠)。

    研究 tree leaf の type-safe state machine の状態値。Linear 6 categories を研究
    プロセス固有 (Proposed/Investigating/Specifying) で拡張した 8 variant。 -/
inductive LifeCyclePhase where
  /-- 作業開始前 (initial phase、新 node のデフォルト)。 -/
  | Proposed
  /-- 調査中 (research / literature survey フェーズ)。 -/
  | Investigating
  /-- 仕様確定中 (spec decision フェーズ)。 -/
  | Specifying
  /-- 実装中 (implementation フェーズ)。 -/
  | Implementing
  /-- レビュー中 (review / verification フェーズ)。 -/
  | Reviewing
  /-- 検証完了 (non-terminal、Retired 遷移候補)。 -/
  | Verified
  /-- 退役済 (terminal、Retirement event 後)。 -/
  | Retired
  /-- 中止 (terminal、任意状態から遷移可)。 -/
  | Cancelled
  deriving DecidableEq, Inhabited, Repr

/-- GA-S7 AllowedTransition (Day 51 inductive Prop、05-plaintext-issue-tracker.md §4.3 仕様準拠)。

    許可遷移 8 件:
    - 直列主経路: Proposed → Investigating → Specifying → Implementing → Reviewing → Verified
    - レビュー差戻し: Reviewing → Implementing (rework)
    - 退役: Verified → Retired
    - 中止: 任意状態 → Cancelled (universal cancellation) -/
inductive AllowedTransition : LifeCyclePhase → LifeCyclePhase → Prop where
  /-- 調査開始遷移。 -/
  | proposed_to_investigating : AllowedTransition .Proposed .Investigating
  /-- 仕様確定遷移。 -/
  | investigating_to_specifying : AllowedTransition .Investigating .Specifying
  /-- 実装開始遷移。 -/
  | specifying_to_implementing : AllowedTransition .Specifying .Implementing
  /-- レビュー開始遷移。 -/
  | implementing_to_reviewing : AllowedTransition .Implementing .Reviewing
  /-- 検証完了遷移。 -/
  | reviewing_to_verified : AllowedTransition .Reviewing .Verified
  /-- レビュー差戻し (rework)。 -/
  | reviewing_to_implementing : AllowedTransition .Reviewing .Implementing
  /-- 退役遷移 (検証完了後)。 -/
  | verified_to_retired : AllowedTransition .Verified .Retired
  /-- 中止遷移 (任意状態から)。 -/
  | any_to_cancelled {p : LifeCyclePhase} : AllowedTransition p .Cancelled

namespace LifeCyclePhase

/-- 初期状態 (新 node のデフォルト)。 -/
def initial : LifeCyclePhase := .Proposed

/-- 終端状態判定 (Retired または Cancelled)。 -/
def isTerminal : LifeCyclePhase → Bool
  | .Retired => true
  | .Cancelled => true
  | _ => false

/-- Active (進行中) 判定 (Investigating / Specifying / Implementing / Reviewing)。 -/
def isActive : LifeCyclePhase → Bool
  | .Investigating => true
  | .Specifying => true
  | .Implementing => true
  | .Reviewing => true
  | _ => false

end LifeCyclePhase

/-- 型 safe な状態遷移 (proof を伴う)。不正遷移は AllowedTransition の proof 構築失敗で
    compile-time error となる。 -/
def transition (current next : LifeCyclePhase)
    (_proof : AllowedTransition current next) : LifeCyclePhase := next

end AgentSpec.Spine

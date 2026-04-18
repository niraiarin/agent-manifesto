-- Provenance 層: RetiredEntity (Day 12、02-data-provenance §4.4 退役 entity の構造的検出)
-- Q1 A 案 + Q2 A-Minimal: structure RetiredEntity + inductive RetirementReason + Test
-- Q3 案 A: RetirementReason 4 variant 型化 (Refuted/Superseded/Obsolete/Withdrawn)
-- Q4 案 A: separate structure 配置 (Day 11 ProvRelation パターン踏襲、ResearchEntity 拡張不要)
import Init.Core
import AgentSpec.Provenance.ResearchEntity
import AgentSpec.Process.Failure

/-!
# AgentSpec.Provenance.RetiredEntity: 退役 entity の構造的検出 (Day 12、A-Minimal)

Phase 0 Week 4-5 Provenance 層の Day 12 構成要素。Day 11 で **PROV-O §4.1 完全カバー到達**
(4 type + 3 main relation) を達成、Day 12 で **§4.4 退役 entity の構造的検出** を Lean 化:

- `RetirementReason`: 退役理由 4 variant (PROV-O §4.4 retirement reasons 対応)
- `RetiredEntity`: 退役 entity の structural record (entity + reason)

これらは PROV-O §4.4 `wasInvalidatedAt` / `wasRetired` 概念に対応し、Lean では separate
structure (Day 11 ProvRelation パターン踏襲) で表現。

## 設計 (Section 2.22 Q1-Q4 確定)

    inductive RetirementReason where
      | Refuted (failure : Failure)               -- 反証退役 (Failure 経由)
      | Superseded (replacement : ResearchEntity) -- 後継退役
      | Obsolete                                  -- 陳腐化退役
      | Withdrawn                                 -- 自発撤回

    structure RetiredEntity where
      entity : ResearchEntity
      reason : RetirementReason

separate structure (Q4 案 A、ResearchEntity 拡張不要 backward compatible) で entity と
理由を strict pair として保持。`Refuted (failure : Failure)` payload で Day 6 Failure 経由
表現も型レベルで両立 (案 C の利点を吸収)。

## DecidableEq 省略 (Day 9-11 同パターン継続)

ResearchEntity が recursive Evolution を含むため `deriving DecidableEq` 不可
(`RetirementReason.Superseded` payload に ResearchEntity を含むため継承)。
Inhabited / Repr のみ deriving、DecidableEq 手動実装は Day 13+ 検討
(Section 2.21 / 2.22 に記録)。

## 層依存性

- `AgentSpec.Provenance.ResearchEntity` (Superseded payload + RetiredEntity.entity field)
- `AgentSpec.Process.Failure` (Refuted payload)

Day 9 確立の namespace extension pattern による layer architecture (Spine + Process +
Provenance + Cross test の 4 layer) 内、新たな循環依存問題なし。

## TyDD 原則 (Day 1-11 確立パターン適用)

- **Pattern #5** (def Prop signature): structure + inductive 先行
- **Pattern #6** (sorry 0): structure + inductive + deriving + smart constructor で完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化 + Day 10 v2 拡張済 (Provenance 検出可能)
- **Pattern #8** (Lean 4 予約語回避): `RetiredEntity` / `RetirementReason` / `Refuted` /
  `Superseded` / `Obsolete` / `Withdrawn` は予約語ではない (PROV-O §4.4 命名規約準拠)

## Day 12 意思決定ログ

### D1. RetirementReason を inductive 4 variant 型化 (Q3 案 A)
- **代案 B**: `reason : String` (Day 6 Failure 同 hole-driven)
- **代案 C**: `reason : Failure` (Failure 経由のみ、case 限定)
- **採用**: 案 A 4 variant inductive
- **理由**: 02-data-provenance §4.4 retirement reasons (refuted / superseded / obsolete /
  withdrawn) の semantic 区別が型レベルで強制、TyDD-S1 + S4 P2 (Refinement)。
  `Refuted (failure : Failure)` payload で案 C (Failure 経由) の利点も吸収、
  `Superseded (replacement : ResearchEntity)` payload で後継参照を型化。
  案 B (String) は弱 refinement (S4 P2 退ける)。

### D2. separate structure 配置 (Q4 案 A、ResearchEntity 拡張不要)
- **代案 B**: `ResearchEntity` に `Retired (e : ResearchEntity) (reason : RetirementReason)`
  constructor 追加 (6 constructor 化、Day 10 D2 5 constructor 拡張パターン踏襲)
- **代案 C**: separate structure + `WasRetiredBy` PROV-O relation (Day 11 パターン拡張)
- **採用**: 案 A separate structure
- **理由**: Day 11 ProvRelation パターン踏襲、TyDD-S1 + 02-data-provenance §4.4 1:1 対応、
  retirement は entity の状態遷移ではなく独立 entity-pair (PROV pattern)、
  `ResearchEntity` 拡張不要 (backward compatible)。Day 13+ で `WasRetiredBy` PROV-O
  relation を auxiliary relations と同時追加するパスを開ける (案 C の利点も将来吸収可能)。
  案 B は recursive entity (Retired wrapping Hypothesis 等)、DecidableEq さらに難化。

### D3. 1 ファイル統合配置 (`RetiredEntity.lean`)
- **代案**: 2 separate ファイル (RetirementReason.lean + RetiredEntity.lean)
- **採用**: 1 ファイル `RetiredEntity.lean` に統合
- **理由**: RetirementReason は RetiredEntity 専用の payload type、密接に関連、
  1 ファイルで cohesion 高い、import 簡素化 (Day 11 ProvRelation の 3 structure 統合と同パターン)。

## Day 14 意思決定ログ (linter A-Minimal 実装)

### D1. Lean 4 標準 `@[deprecated]` attribute による退役 entity 警告 (Q1 A 案 + Q2 A-Minimal)
- **代案 B**: custom attribute `@[retired]` + elaborator hook (A-Compact)
- **代案 C**: custom linter (`Lean.Elab.Command` 拡張、A-Standard)
- **代案 D**: elaborator による型レベル強制 (compile error 化、A-Maximal)
- **採用**: 案 A 標準 `@[deprecated]` attribute 付与 (test fixture 対象、A-Minimal)
- **理由**: Day 1-13 で custom Lean compiler 拡張はやっていない新分野、minimal で学習 +
  設計判断を集めて Day 15+ で段階的拡張パスを開ける (A-Compact → A-Standard → A-Maximal)。
  Lean 4 標準機能のみで学習コスト最小、Day 14 1 日で完結。

### D2. test fixture 対象、production code 変更なし (Q3 案 A)
- **代案 B**: production code に helper 関数 + 直接構築 deprecated 警告
- **代案 C**: namespace marker function (`Retired.markDeprecated`)
- **採用**: 案 A test fixture (新規 `*Deprecated` 4 variant fixture を追加) 対象のみ
- **理由**: backward compatible (既存 `RetiredEntity.trivial` / smart constructor / structure 自体には影響なし)、
  案 B (helper) は既存 smart constructor と重複、案 C (marker) は新運用パターンで概念重複。
  test 内で `set_option linter.deprecated false in` で warning 抑制し build PASS 維持、
  外部利用箇所では warning 発生で linter 効果確認可能。

## Day 14 `@[deprecated]` 使用例 (production code から外部利用箇所への gentle warning)

外部利用者が以下の deprecated fixture を参照すると Lean 4 linter が warning を発生:

    -- 利用側 (warning 発生):
    #check RetiredEntity.refutedTrivialDeprecated  -- warning: deprecated, use ...

    -- 利用側 (warning 抑制):
    set_option linter.deprecated false in
    example := RetiredEntity.refutedTrivialDeprecated  -- no warning

これは PROV-O §4.4 「退役済 entity 参照は警告」semantic を Lean 4 標準機能で
A-Minimal 実装したもの。Day 15+ で custom attribute (`@[retired]`) や custom linter
(Lean.Elab.Command 拡張) で精緻化予定。
-/

namespace AgentSpec.Provenance

/-! ### `RetirementReason`: 退役理由 4 variant (PROV-O §4.4) -/

/-- 02-data-provenance §4.4 retirement reasons の Lean 化 (Day 12 Q3 案 A)。

    退役 entity の根本原因を 4 variant で型レベル区別:
    - `Refuted (failure : Failure)`: 反証退役 (Day 6 Failure 経由、案 C 利点吸収)
    - `Superseded (replacement : ResearchEntity)`: 後継退役 (後継 entity を型化参照)
    - `Obsolete`: 陳腐化退役 (環境変化、外部要因)
    - `Withdrawn`: 自発撤回 (errata、判断変更)

    Day 6 Failure の `FailureReason.Retired` (String successor) と異なり、
    `Superseded` は ResearchEntity 直接参照で Provenance 層 entity 整合性を強制。
    DecidableEq 省略 (Superseded payload の ResearchEntity recursive 制約継承)。 -/
inductive RetirementReason where
  /-- 反証退役: Failure (4 variant のうち HypothesisRefuted ほか) を経由した退役。 -/
  | Refuted (failure : AgentSpec.Process.Failure)
  /-- 後継退役: 別 ResearchEntity に置き換えられた退役 (replacement 参照)。 -/
  | Superseded (replacement : ResearchEntity)
  /-- 陳腐化退役: 外部要因 (環境変化、依存変更) による退役、payload なし。 -/
  | Obsolete
  /-- 自発撤回退役: errata / 判断変更による退役、payload なし。 -/
  | Withdrawn
  deriving Inhabited, Repr

/-! ### `RetiredEntity`: 退役 entity の structural record -/

/-- 02-data-provenance §4.4 `wasInvalidatedAt` / `wasRetired` 概念の Lean 化 (Day 12 Q4 案 A)。

    退役 entity と理由を separate structure で保持 (Day 11 ProvRelation パターン踏襲)。
    `entity` field で退役対象 ResearchEntity を、`reason` field で 4 variant 退役理由を保持。

    例: `Hypothesis` entity が `Failure` 経由で退役した場合、
        `{ entity := .Hypothesis hyp, reason := .Refuted failure }` -/
structure RetiredEntity where
  /-- 退役対象 entity (ResearchEntity 5 constructor のいずれか)。 -/
  entity : ResearchEntity
  /-- 退役理由 (4 variant のうち 1 つ)。 -/
  reason : RetirementReason
  deriving Inhabited, Repr

namespace RetiredEntity

/-- Smart constructor: entity と reason を直接指定。 -/
def mk' (entity : ResearchEntity) (reason : RetirementReason) : RetiredEntity :=
  { entity := entity, reason := reason }

/-- Smart constructor: Refuted variant (Failure 経由退役)。 -/
def refuted (entity : ResearchEntity) (failure : AgentSpec.Process.Failure) : RetiredEntity :=
  { entity := entity, reason := .Refuted failure }

/-- Smart constructor: Superseded variant (後継退役)。 -/
def superseded (entity : ResearchEntity) (replacement : ResearchEntity) : RetiredEntity :=
  { entity := entity, reason := .Superseded replacement }

/-- Smart constructor: Obsolete variant (陳腐化退役)。 -/
def obsolete (entity : ResearchEntity) : RetiredEntity :=
  { entity := entity, reason := .Obsolete }

/-- Smart constructor: Withdrawn variant (自発撤回退役)。 -/
def withdrawn (entity : ResearchEntity) : RetiredEntity :=
  { entity := entity, reason := .Withdrawn }

/-- 自明な fixture: trivial Hypothesis Entity の Obsolete 退役。 -/
def trivial : RetiredEntity :=
  { entity := ResearchEntity.trivial, reason := .Obsolete }

/-- `reason` accessor の alias (Day 6 Failure.whyFailed と同パターン)。 -/
def whyRetired (r : RetiredEntity) : RetirementReason := r.reason

/-! ### Day 14 deprecated fixture (linter A-Minimal 実装、Q3 案 A test fixture のみ対象)

これら 4 variant fixture は `@[deprecated]` attribute 付与で外部利用時に warning を
発生させる (PROV-O §4.4 退役 entity 参照警告の Lean 4 標準機能実装)。

利用側で `set_option linter.deprecated false in` により warning 抑制可能 (test 用途)。
production code (RetiredEntity structure / smart constructor 自体) は backward compatible
で変更なし。Day 15+ で custom attribute / linter / elaborator に段階的拡張予定。 -/

/-- Refuted variant の deprecated fixture (Day 14 D1 linter A-Minimal 実装)。 -/
@[deprecated "退役済 entity - RetirementReason を確認 (Day 14 linter A-Minimal)" (since := "2026-04-18")]
def refutedTrivialDeprecated : RetiredEntity :=
  refuted ResearchEntity.trivial AgentSpec.Process.Failure.trivial

/-- Superseded variant の deprecated fixture (Day 14 D1 linter A-Minimal 実装)。 -/
@[deprecated "退役済 entity - RetirementReason を確認 (Day 14 linter A-Minimal)" (since := "2026-04-18")]
def supersededTrivialDeprecated : RetiredEntity :=
  superseded ResearchEntity.trivial ResearchEntity.trivial

/-- Obsolete variant の deprecated fixture (Day 14 D1 linter A-Minimal 実装)。 -/
@[deprecated "退役済 entity - RetirementReason を確認 (Day 14 linter A-Minimal)" (since := "2026-04-18")]
def obsoleteTrivialDeprecated : RetiredEntity :=
  obsolete ResearchEntity.trivial

/-- Withdrawn variant の deprecated fixture (Day 14 D1 linter A-Minimal 実装)。 -/
@[deprecated "退役済 entity - RetirementReason を確認 (Day 14 linter A-Minimal)" (since := "2026-04-18")]
def withdrawnTrivialDeprecated : RetiredEntity :=
  withdrawn ResearchEntity.trivial

end RetiredEntity

end AgentSpec.Provenance

-- Provenance 層: RetirementLinter (Day 15、A-Compact custom attribute @[retired] Hybrid macro)
-- Q1 A 案 + Q2 A-Compact-Hybrid: Lean 4 elab macro で @[retired] を @[deprecated] に展開
-- Q3 案 B: 新 module (RetiredEntity.lean 変更なし、macro 専用隔離)
import Lean

/-!
# AgentSpec.Provenance.RetirementLinter: A-Compact custom attribute `@[retired]` (Day 15、Hybrid macro 実装)

Phase 0 Week 4-5 Provenance 層の Day 15 構成要素。Day 14 で **linter A-Minimal**
(Lean 4 標準 `@[deprecated]` 4 fixture) を確立、Day 15 で **A-Compact Hybrid macro**:
`@[retired "msg" "since"]` attribute syntax を Lean 4 elab macro で
`@[deprecated "msg" (since := "since")]` に展開する形で custom attribute を提供。

Day 14 の段階的拡張パス (A-Minimal → A-Compact → A-Standard → A-Maximal) の第 2 段階。
Day 14 A-Minimal を backward compatible に保ち (既存 `@[deprecated]` fixture も動作)、
PROV-O `@[retired]` semantic を型レベルで直接表現可能に。

## 設計 (Section 2.28 Q1-Q4 確定)

    -- syntax 定義:
    syntax (name := retired) "retired " str ppSpace str : attr

    -- macro 展開:
    macro_rules
      | `(attr| retired $msg:str $since:str) =>
        `(attr| deprecated $msg:str (since := $since:str))

`$msg:str` / `$since:str` 型注釈は Lean 4 `deprecated` parser が第一位置に `ident` を
期待する仕様に合わせて必要 (型注釈なしだと `msg` が `ident` と解釈されて build error)。
Day 15 Subagent 検証 I1 (改訂 71) で docstring と実装の整合を確認。

これにより利用側で以下が可能:

    @[retired "退役済 entity - RetirementReason を確認" "2026-04-19"]
    def someDeprecatedFixture : ... := ...

    -- 展開後 (Lean 4 macro 処理):
    @[deprecated "退役済 entity - RetirementReason を確認" (since := "2026-04-19")]
    def someDeprecatedFixture : ... := ...

## Day 14 との backward compatibility

Day 14 で `@[deprecated]` 直接付与した 4 fixture (refutedTrivialDeprecated 等) は
変更なしで動作継続。Day 15 `@[retired]` は並存する新しい記法 (より PROV-O semantic に近い)。
利用側が選択可能:

- Day 14 直接記法: `@[deprecated "msg" (since := "date")]`
- Day 15 PROV-O 記法: `@[retired "msg" "date"]` (macro 展開後は等価)

## TyDD 原則 (Day 1-14 確立パターン適用)

- **Pattern #5** (def Prop signature): macro_rules 定義は syntax 先行
- **Pattern #6** (sorry 0): macro のみで完結 (no proof obligation)
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化 + Day 10 v2 拡張済
- **Pattern #8** (Lean 4 予約語回避): `retired` は予約語ではない (Lean 4 attribute name として有効)

## Day 15 意思決定ログ

### D1. Hybrid macro で Day 14 backward compatibility + PROV-O semantic 両立 (Q2 A-Compact-Hybrid)
- **代案 A**: A-Minimal 相当 (`register_simp_attr` で marker 役のみ、検出 logic は `@[deprecated]` に委譲)
- **代案 B**: A-Compact-True (custom elaborator hook で `@[retired]` 自前検出、`@[deprecated]` 不要)
- **採用**: 案 A-Compact-Hybrid (Lean 4 elab macro で `@[retired]` を `@[deprecated]` に展開)
- **理由**: Day 14 A-Minimal backward compatible 維持 (既存 fixture は動作継続)、
  macro 機能学習で Day 16+ A-Standard custom linter (Lean.Elab.Command 拡張) への前提準備。
  A-Minimal は marker 役のみで強制化効果は Day 14 と同じ、A-Compact-True は Lean 4 Elab
  knowledge 学習で Day 15 1 日 scope 超過。

### D2. 新 module (RetirementLinter.lean) に macro 定義のみ、RetiredEntity.lean は変更なし (Q3 案 B)
- **代案 A**: RetiredEntity.lean MODIFY (macro 定義 + 4 fixture を `@[retired]` に置換)
- **代案 C**: manual elaborator (`Lean.Elab.attribute`) で `@[deprecated]` と同等の処理自前実装
- **採用**: 案 B 新 module
- **理由**: Day 14 RetiredEntity.lean backward compatible 維持 (production code 変更なし)、
  新分野 (macro) を専用 module で隔離 (RetirementLinter.lean)、
  Day 16+ で A-Standard custom linter (Lean.Elab.Command 拡張) として更に拡張する base lib に。
  案 A は production code MODIFY が大きく Day 14 backward compatibility 損なう恐れ、
  案 C は Lean 4 internals 深く学習で scope 超過。

### D3. syntax 定義で `retired "msg" "since"` 形式採用 (2 引数 str 連接)
- **代案**: `retired "msg"` (since 省略可、Day 14 `@[deprecated "msg"]` 相当)
- **採用**: 2 引数 str 連接 (`retired "msg" "since"`)
- **理由**: Day 14 evaluator I2 教訓で `(since := "...")` 推奨確認済、
  Day 15 で since を必須にすることで attribute assumption の explicit 化を macro 側で強制
  (TyDD-S4 P5 explicit assumptions 6 度目強適用)。
  macro 定義は単一形式で単純化、利用側は「全ての `@[retired]` は since 指定必須」の規約に統一。

### Day 15 Subagent 検証結果 (改訂 71)

Subagent 検証 PASS (addressable 0 → 1、informational 2):
- I1 (addressable、改訂 71 で対処): macro RHS と docstring の齟齬
  → docstring の展開形式を実装 ($msg:str / $since:str 型注釈付き) に合わせて更新
  (理由: Lean 4 `deprecated` parser の第一引数が ident を期待する仕様、型注釈なしだと build error)
- I2 (informational、対処不要): build PASS は self-reported (Subagent が Lean build を
  自前実行不可のため監査記録として明示)
- I3 (informational、対処不要): `ppSpace` は pretty-printer directive (parsing には必須でない、
  harmless cosmetic)、attr-category syntax での慣習として保持
-/

namespace AgentSpec.Provenance

/-! ### `@[retired]` custom attribute (Day 15 A-Compact Hybrid macro) -/

/-- Day 15 A-Compact: `@[retired "msg" "since"]` を `@[deprecated "msg" (since := "since")]`
    に展開する Hybrid macro。Day 14 A-Minimal backward compatible。

    例:
        @[retired "退役済 entity - RetirementReason を確認" "2026-04-19"]
        def myFixture : RetiredEntity := ...

        -- 展開後:
        @[deprecated "退役済 entity - RetirementReason を確認" (since := "2026-04-19")]
        def myFixture : RetiredEntity := ...
 -/
syntax (name := retired) "retired " str ppSpace str : attr

macro_rules
  | `(attr| retired $msg:str $since:str) =>
    `(attr| deprecated $msg:str (since := $since:str))

end AgentSpec.Provenance

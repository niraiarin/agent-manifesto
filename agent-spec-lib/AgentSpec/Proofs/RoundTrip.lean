-- GA-C2 (Bidirectional Codec): round-trip 定理の induction 証明基盤
-- Week 2 Day 1: 補題収集 + universal signature + 範囲拡張 bounded 証明
-- Week 2 Day 2-5 で induction proof 本体を実装予定
import AgentSpec.Core

/-!
# AgentSpec.Proofs.RoundTrip: SemVer codec round-trip 定理 (GA-C2, TyDD-H3)

## Week 2 Day 1 の成果

- **補題リストの集約**: universal 定理証明に必要な Lean core / Mathlib 補題を
  `docstring` セクション「必要な補題」にリスト化
- **universal signature の宣言**: `roundTripUniversal : Prop` を `def` で定義
  （opaque identity を保持し hole-driven 開発に適合）、後続 Day で
  `theorem roundTripUniversal_proved : roundTripUniversal` を証明
- **bounded 証明の範囲拡張**: Week 1 の `Fin 5³ = 125` を `Fin 7³ = 343` に拡張
- **base case 証明**: `parse (render ⟨0, 0, 0, none⟩) = some ⟨0, 0, 0, none⟩`

## 必要な補題（Day 2-5 で収集・証明予定）

### Lean core / Init
- `String.toList_ofList : ∀ l, (String.ofList l).toList = l`
- `Nat.toString_eq` / `Nat.repr` の canonical 形式

### 補助定理（本 module で定義予定）
- `consumeNat_renderNat : consumeNat (Nat.toString n).toList = some (n, [])`
  - → Nat.toString が数字のみを出力し、consumeNat が逆変換として機能することの主張
- `consumeChar_dot_of_renderWithDot : consumeChar '.' ('.' :: rest) = some rest`
  - → 基本的な consumeChar の動作確認（`rfl` で証明可能）
- `parseList_renderList : parseList (render v).toList = some v`
  - → 最終的な目標となる補題

### Mathlib（Week 6 以降の LeanHammer / Duper 統合時に活用）
- SMT hammer 経由で `String.toString`, `Nat.toString` 関連の補題を自動発見

## TyDD 原則

- **TyDD-F6 / H3** (Codec round-trip): universal theorem を型レベルで宣言
- **GA-W4** (sorry 0): Day 1 時点で `sorry` 不使用、bounded 証明と signature のみ
- **GA-C27** (Trusted code 最小化): `native_decide` 不使用、`decide` のみ
- **hole-driven development** (TyDD-S1 benefit #7): universal signature を先行宣言し、
  proof 本体を後続 Day で埋める
-/

namespace AgentSpec.Proofs.RoundTrip

open AgentSpec

/-! ### 補助 Bool 関数と Prop signature -/

/-- `parse (render v) = some v` を Bool で判定する補助関数。
    `decide` で有限領域の universal 検証を効率化。 -/
def roundTripOk (v : SemVer) : Bool :=
  match SemVer.parse v.render with
  | none => false
  | some v' => v = v'

/-- universal round-trip 定理 (GA-C2 完全化): 全ての SemVer について
    `parse ∘ render = some` が成立することの Prop 表現。

    Week 2 Day 2-5 で `induction` による proof を実装予定。
    Day 1 時点では signature のみ宣言（hole-driven development）。

    `def` を使用し `abbrev` は避ける — `abbrev` だと定義が透過的に展開されて
    signature の独立性（「証明対象の命題」としての identity）が失われる。 -/
def roundTripUniversal : Prop :=
  ∀ v : SemVer, SemVer.parse v.render = some v

/-! ### Day 1 で証明可能な範囲 -/

/-- base case: 全 0 stable release の round-trip。 -/
theorem roundTrip_zero_stable :
    SemVer.parse (SemVer.render ⟨0, 0, 0, none⟩) = some ⟨0, 0, 0, none⟩ := by
  decide

/-- base case: version 値 (`⟨0, 0, 1, some "phase0-week1"⟩`) の round-trip。 -/
theorem roundTrip_version : SemVer.parse version.render = some version := by
  decide

/-- stable release の bounded universal: `Fin 7³ = 343` ケースを `decide` で網羅検証。
    Week 1 の 125 ケースから範囲拡張 (5→7、約 2.7 倍)。 -/
theorem roundTrip_bounded_stable_7 :
    (List.range 7).all fun m =>
      (List.range 7).all fun n =>
        (List.range 7).all fun p =>
          roundTripOk ⟨m, n, p, none⟩ := by
  decide

/-! ### Day 5: 補助 lemma の段階的証明 + bounded 拡張 -/

/-- consumeChar が指定文字 + 任意 rest を一致時に消費する (rfl で証明可能)。 -/
theorem consumeChar_dot_cons (rest : List Char) :
    SemVer.consumeChar '.' ('.' :: rest) = some rest := rfl

/-- consumeChar が不一致時に none を返す (rfl で証明可能)。 -/
theorem consumeChar_dot_mismatch (c : Char) (h : c ≠ '.') (rest : List Char) :
    SemVer.consumeChar '.' (c :: rest) = none := by
  show (if c = '.' then some rest else none) = none
  simp [h]

/-- consumeChar の空リスト動作: 何も消費できない。 -/
theorem consumeChar_dot_nil :
    SemVer.consumeChar '.' [] = none := rfl

/-- charToDigit? は 0-9 で some、それ以外で none。Day 6 で consumeNat の
    universal proof に活用予定。 -/
theorem charToDigit?_zero : SemVer.charToDigit? '0' = some 0 := rfl
theorem charToDigit?_nine : SemVer.charToDigit? '9' = some 9 := rfl

/-! ### 範囲拡張 bounded universal: 7³ → 8³ (Day 5)

    Day 1 の 7³ = 343 ケースを 8³ = 512 ケースに拡張。
    `decide` の heartbeat 制約 (default 200000) のため 10³ = 1000 ケースは
    timeout。8³ = 512 が現実的上限。10³ 達成は Lean-Auto 統合 (Week 6) 待ち。
    finite-bounded universal proof として GA-C2 / TyDD-H3 の保証強化に寄与
    (ただし真の universal proof ではない)。 -/

/-- stable release の bounded universal (8³ = 512 ケース)。Day 1 の 7³ から拡張。 -/
theorem roundTrip_bounded_stable_8 :
    (List.range 8).all fun m =>
      (List.range 8).all fun n =>
        (List.range 8).all fun p =>
          roundTripOk ⟨m, n, p, none⟩ := by
  decide

/-! ### Day 6+ / Week 3 残課題 (universal proof 構造)

universal `roundTripUniversal_proved : roundTripUniversal` を完成させるには
以下の補題が必要:

1. **consumeNat correctness** (難易度: 高):
   ```
   consumeNat (Nat.toString n).toList = some (n, [])
   ```
   `Nat.toString` の equational behavior (decimal digit decomposition) を inductive に
   解明する必要あり。Lean 4 core / Mathlib `Nat.Digits` 関連 lemma の調査含む。

2. **String/List interconversion** (難易度: 中):
   ```
   (String.ofList l).toList = l
   ```
   Lean 4 core の `String.toList_ofList` を活用。

3. **parseList の inductive 構造** (難易度: 高):
   render が出力する形式 ("M.N.P" or "M.N.P-X") の各部分を順次消費することの証明。
   match 各分岐の正当性を induction で示す。

4. **roundTripUniversal_proved 結合** (難易度: 中):
   上記 1-3 を組合わせて全 SemVer に対する round-trip を結合。

**推定工数**: 100+ 行の Lean、Day 6-Week 3 で段階的に対処。Lean-Auto / Duper 統合
(Week 6) で SMT hammer による自動証明発見の可能性もあり。
-/

end AgentSpec.Proofs.RoundTrip

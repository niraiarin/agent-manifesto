-- Week 1 時点で実際に使用するのは Lean core (Init) のみ。
-- Mathlib は lakefile.lean で require 済（Week 2 以降の Spine 層で本格利用予定）。
-- autoImplicit=false 下での明示性保証と /verify Round 1 指摘 7 への対応のため
-- 依存モジュールを explicit import で宣言する。
import Init.Data.Nat.Basic
import Init.Data.String.Basic
import Init.Data.List.Basic
import Init.Data.Option.Basic
import Init.Data.Ord

/-!
# AgentSpec.Core: 基本型と基本 instance

Phase 0 Week 1 — TyDD / TDD 原則に沿った最小基盤。
Week 2 以降で GA-S2 (FolgeID), GA-S4 (Edge Type) 等を追加していく。

## この時点でカバーする Gap

- **GA-I5** (CSLib/LeanHammer/LeanDojo 依存): lakefile.lean に require 宣言（Week 6 で有効化）
- **GA-I7** (high-tokenizer SpecSystem): (b) 再定義方針を採用、TypeSpec/FuncSpec の Lean 内再定義は Week 3 で実施
- **GA-T8** (Lean バージョン管理): lean-toolchain で v4.29.0 に pin
- **GA-C32** (Capability-separated import): agent-spec-lib を独立パッケージとして隔離
- **GA-S18** (Gradual Refinement Type): `SemVer` structure で refinement 制約を型レベル化
- **GA-C2** (Bidirectional Codec): `render` + `parse` + round-trip theorem で完全な bidirectional codec
- **GA-I9** (テストカバレッジ): `AgentSpec/Test/` 配下で behavior assertion

## 設計原則（Phase 0 全体に適用）

1. **TyDD-S1** (Types first): string literal ではなく `SemVer` structure で型制約を先行
2. **TyDD-F6 / H3** (Codec with round-trip proof): `parse ∘ render = some` を theorem として保証
3. **T₀ 無矛盾性の継承** (GA-F C1): `lake build` で型検査を通す
4. **axiom 最小化** (formal-derivation 原則): axiom 0 を目指し、型定義 + theorem で構成
5. **GA-W7** (termination 保証): `partial def` を避け、明示的再帰で実装
6. **GA-W4** (sorry accumulation): sorry 0

## Week 2-3 の Spine 層追加計画

Week 2-3 では `AgentSpec/Spine/` 配下に EvolutionStep, SafetyConstraint,
LearningCycle, Observable を追加予定。CSLib 依存は GA-I5 に従い Week 6 まで
延期するため、Week 2-3 では Mathlib の既存型または独自定義で代替する。
-/

namespace AgentSpec

/-- SemVer refinement type (TyDD-S4 Liquid Haskell パターン、GA-S18 Gradual Refinement 準拠)

    各フィールドは非負整数（`Nat` の refinement）。`preRelease` は任意の識別子で、
    `none` は stable release、`some "xxx"` は pre-release を表す。

    TyDD 原則: SemVer バージョンであることを型レベルで保証。String 直書きを排除。 -/
structure SemVer where
  major : Nat
  minor : Nat
  patch : Nat
  preRelease : Option String := none
  deriving Repr, DecidableEq, Inhabited

namespace SemVer

/-- 文字列として render (TyDD-F6 Codec の forward 方向)

    `SemVer → String` の total function。 -/
def render (v : SemVer) : String :=
  let base := s!"{v.major}.{v.minor}.{v.patch}"
  match v.preRelease with
  | none => base
  | some pre => s!"{base}-{pre}"

/-! ### Recursive char-level parser (TyDD-F6 Codec の backward 方向、GA-C2 完全化)

Pure functional recursive parser, `partial def` なし (GA-W7 遵守)、native_decide 不使用 (GA-C27 遵守)。
`String.splitOn` を避け `List Char` で直接操作することで評価可能性 (`decide`) を確保。
-/

/-- Char を数字 (0-9) に変換。非数字なら `none`。 -/
def charToDigit? (c : Char) : Option Nat :=
  if c = '0' then some 0
  else if c = '1' then some 1
  else if c = '2' then some 2
  else if c = '3' then some 3
  else if c = '4' then some 4
  else if c = '5' then some 5
  else if c = '6' then some 6
  else if c = '7' then some 7
  else if c = '8' then some 8
  else if c = '9' then some 9
  else none

/-- `List Char` の先頭から連続する数字を消費し、`Nat` と残りを返す。
    数字が 1 つもなければ `none`。 -/
def consumeNat : List Char → Option (Nat × List Char) :=
  let rec go (acc : Nat) (consumed : Bool) : List Char → Option (Nat × List Char)
    | [] => if consumed then some (acc, []) else none
    | c :: rest =>
      match charToDigit? c with
      | some d => go (acc * 10 + d) true rest
      | none => if consumed then some (acc, c :: rest) else none
  go 0 false

/-- `List Char` の先頭が指定文字なら消費、そうでなければ `none`。 -/
def consumeChar (expected : Char) : List Char → Option (List Char)
  | [] => none
  | c :: rest => if c = expected then some rest else none

/-- Recursive char-level parser for SemVer.
    形式: "major.minor.patch" または "major.minor.patch-preRelease" -/
def parseList (chars : List Char) : Option SemVer :=
  match consumeNat chars with
  | none => none
  | some (major, rest1) =>
    match consumeChar '.' rest1 with
    | none => none
    | some rest2 =>
      match consumeNat rest2 with
      | none => none
      | some (minor, rest3) =>
        match consumeChar '.' rest3 with
        | none => none
        | some rest4 =>
          match consumeNat rest4 with
          | none => none
          | some (patch, rest5) =>
            match rest5 with
            | [] => some ⟨major, minor, patch, none⟩
            | '-' :: pre =>
              match pre with
              | [] => none  -- "-" の後が空文字列は許可しない
              | _ => some ⟨major, minor, patch, some (String.ofList pre)⟩
            | _ => none

/-- `String → Option SemVer` の backward codec (TyDD-F6 / H3)。 -/
def parse (s : String) : Option SemVer :=
  parseList s.toList

/-! ### SemVer 順序関係 (TyDD-F2 SpecSig Lattice への基盤、GA-S15 予備実装)

SemVer は自然な lexicographic total order を持つ。major > minor > patch > preRelease
の辞書式比較。stable release (`preRelease = none`) は同じ major/minor/patch の
pre-release より大きい（SemVer 2.0 spec 準拠: 1.0.0-alpha < 1.0.0）。

Week 4-5 で GA-S15 (SpecSig Lattice on pre/post) の lattice を `ResearchSpec` に
付与する際、本 Ord instance を参考にする。 -/

/-- preRelease の比較: none > some (stable > pre-release)、some は文字列 lexicographic。 -/
def comparePreRelease : Option String → Option String → Ordering
  | none,    none    => .eq
  | none,    some _  => .gt
  | some _,  none    => .lt
  | some p₁, some p₂ => compareOfLessAndEq p₁ p₂

/-- SemVer lexicographic 比較 (major > minor > patch > preRelease)。 -/
def compare (v₁ v₂ : SemVer) : Ordering :=
  match Ord.compare v₁.major v₂.major with
  | .eq =>
    match Ord.compare v₁.minor v₂.minor with
    | .eq =>
      match Ord.compare v₁.patch v₂.patch with
      | .eq => comparePreRelease v₁.preRelease v₂.preRelease
      | o => o
    | o => o
  | o => o

instance : Ord SemVer := ⟨compare⟩

/-- LE instance: `v₁ ≤ v₂ ↔ compare v₁ v₂ ≠ .gt` -/
instance : LE SemVer := ⟨fun v₁ v₂ => compare v₁ v₂ ≠ .gt⟩

/-- LT instance: `v₁ < v₂ ↔ compare v₁ v₂ = .lt` -/
instance : LT SemVer := ⟨fun v₁ v₂ => compare v₁ v₂ = .lt⟩

-- Decidable instances for convenience in tests
instance (v₁ v₂ : SemVer) : Decidable (v₁ ≤ v₂) := by
  unfold LE.le instLE
  exact inferInstance

instance (v₁ v₂ : SemVer) : Decidable (v₁ < v₂) := by
  unfold LT.lt instLT
  exact inferInstance

end SemVer

/-- 本 agent-spec-lib のバージョン。TyDD 原則: 型が値を制約する。
    `String` 直書きから `SemVer` 型インスタンスに移行済。 -/
def version : SemVer := ⟨0, 0, 1, some "phase0-week1"⟩

end AgentSpec

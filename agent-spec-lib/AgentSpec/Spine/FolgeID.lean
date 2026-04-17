-- GA-S2 (FolgeID): Folgezettel ID 型と半順序 instance
-- Week 2 Day 1: hole-driven signature + 最小 prefix order 実装
-- Week 2 Day 3-5 で PartialOrder/Ord instance を追加予定
import Init.Data.List.Basic
import Init.Data.Sum.Basic

/-!
# AgentSpec.Spine.FolgeID: Folgezettel ID 型 (GA-S2)

GitHub Issue 番号 "#599" の魔法依存を、型安全な階層識別子に置き換える。

## 設計 (synthesis §4.1 #2, GA-S2)

- `path : List (Nat ⊕ Char)` で根から末端へのパスを表現
  - `Nat` は分岐子番号、`Char` はサブ識別子（例: "1.2a" → `[inl 1, inl 2, inr 'a']`）
- 半順序 `≤` は **prefix order**（Folgezettel の自然な partial order）
  - `a ≤ b` ⇔ `a.path` が `b.path` の prefix
  - root (`⟨[]⟩`) は全ての FolgeID の prefix

## TyDD 原則

- **TyDD-S1** (Types first): Nat 直書きから refinement された structure に型化
- **TyDD-H3** (Hole-driven development): Week 2 Day 1 は signature 中心。
  `Ord`/`PartialOrder`/`DecidableEq` instance は段階的追加
- **GA-W4** (sorry 0): 実装は prefix 判定のみで完結、sorry 回避

## Week 2 以降の拡張計画

- **Day 3-5**: `Ord FolgeID` lexicographic total order、`PartialOrder` instance、
  sibling ordering, linearize/unlinearize
- **Week 3**: Provenance (GA-S3) との統合
-/

namespace AgentSpec.Spine

/-- Folgezettel path の segment: `Nat` (分岐子番号) ⊕ `Char` (サブ識別子)。

    例: "1.2a" は `[inl 1, inl 2, inr 'a']` として path 表現される。 -/
abbrev FolgePathSegment : Type := Nat ⊕ Char

/-- Folgezettel ID (GA-S2): Issue 番号 "#N" を置き換える型安全な階層識別子。

    `path` は根から末端へのパス列。root は `⟨[]⟩`。

    ## 半順序

    `a ≤ b` ⇔ `a.path` が `b.path` の prefix。これは反射的・推移的・反対称的
    （標準的な prefix partial order）。

    Week 2 Day 3-5 で `PartialOrder` instance を追加予定。 -/
structure FolgeID where
  path : List FolgePathSegment
  deriving DecidableEq, Inhabited, Repr

namespace FolgeID

/-- List レベルの prefix 判定。`decide` のため structure pattern を避け、
    直接 `List FolgePathSegment` で再帰する。 -/
def listIsPrefixOf : List FolgePathSegment → List FolgePathSegment → Bool
  | [], _ => true
  | _ :: _, [] => false
  | s₁ :: rest₁, s₂ :: rest₂ =>
    if s₁ = s₂ then listIsPrefixOf rest₁ rest₂ else false

/-- prefix 判定。`a.isPrefixOf b = true` ⇔ `a.path` が `b.path` の prefix。 -/
def isPrefixOf (a b : FolgeID) : Bool :=
  listIsPrefixOf a.path b.path

/-- LE instance: FolgeID partial order (prefix 順序)。

    `a ≤ b` ⇔ `a` が `b` の祖先（自身含む）。 -/
instance instLE : LE FolgeID := ⟨fun a b => listIsPrefixOf a.path b.path = true⟩

/-- Decidable instance は `inferInstanceAs` で List レベルの Bool 等価判定に委譲する。
    unfold の脆弱性（anonymous instance 名依存）を回避する。 -/
instance (a b : FolgeID) : Decidable (a ≤ b) :=
  inferInstanceAs (Decidable (listIsPrefixOf a.path b.path = true))

/-- root FolgeID = 空 path。全ての FolgeID の祖先（prefix）。 -/
def root : FolgeID := ⟨[]⟩

/-- 子 FolgeID の構築: 親 `a` に segment `s` を追加する。

    例: `a.path = [inl 1]` のとき `a.child (inl 2) = ⟨[inl 1, inl 2]⟩`。 -/
def child (a : FolgeID) (s : FolgePathSegment) : FolgeID :=
  ⟨a.path ++ [s]⟩

end FolgeID

end AgentSpec.Spine

-- GA-S4 (Edge Type Inductive): ResearchNode 間の関係を型レベルで区別
-- Week 2 Day 2: hole-driven signature。FolgeID を endpoint 代用とし、
-- Week 4-5 で ResearchNode 型定義後に dependent type
-- `inductive ResearchEdge : ResearchNode → ResearchNode → Type` に refactor 予定。
import Init.Data.List.Basic
import AgentSpec.Spine.FolgeID

/-!
# AgentSpec.Spine.Edge: ResearchNode 間 Edge Type (GA-S4)

## 設計 (synthesis §4.1, GA-S4)

- 関係種別 `EdgeKind` を inductive で枚挙: PROV-style 6 種
  - `wasDerivedFrom` (派生): 親 → 子
  - `refines` (洗練): 抽象 → 具体
  - `refutes` (反駁): 反証関係
  - `blocks` (依存阻害): 依存ブロック
  - `relates` (関連): 弱い関連
  - `wasReplacedBy` (置換): 退役 → 後継
- structure `Edge { src dst : FolgeID, kind : EdgeKind }` で Edge を表現
  - `from`/`to` は Lean 4 予約語のため `src`/`dst` に命名
  - 当面は FolgeID を endpoint とするが、Week 4-5 で ResearchNode に置換予定
  - `src = dst` （自己 edge）も型レベルでは許容（運用で禁止）

## TyDD 原則 (Day 1 確立パターン適用、Section 10.2)

- **Pattern #1** (segment abbrev): 不要（EdgeKind は inductive で十分）
- **Pattern #6** (sorry/axiom 0): 全て deriving + 構造的等価性で実装
- **Pattern #7** (artifact-manifest 同 commit 反映): 別 commit で対処

## Week 4-5 への遷移計画

```lean
    -- 現在（Day 2）:
    structure Edge where
      src  : FolgeID
      dst  : FolgeID
      kind : EdgeKind

    -- Week 4-5 (ResearchNode 定義後):
    inductive ResearchEdge : ResearchNode → ResearchNode → Type where
      | wasDerivedFrom : ResearchEdge a b
      | refines        : ResearchEdge a b
      -- ...
```
-/

namespace AgentSpec.Spine

/-- Edge の関係種別 (GA-S4 PROV-style 6 種)。

    Lean inductive enum として宣言。Week 4-5 で `ResearchEdge` の constructor に変換予定。 -/
inductive EdgeKind where
  | wasDerivedFrom  -- 派生関係
  | refines         -- 洗練関係（抽象→具体）
  | refutes         -- 反駁関係
  | blocks          -- 依存阻害
  | relates         -- 弱い関連
  | wasReplacedBy   -- 置換（退役→後継）
  deriving DecidableEq, Inhabited, Repr

/-- Edge structure (GA-S4): 2 つの FolgeID 間の関係。

    Day 2 では endpoint を FolgeID で代用。Week 4-5 で
    `ResearchEdge : ResearchNode → ResearchNode → Type` に refactor 予定。

    `from`/`to` は Lean 4 予約語のため `src`/`dst` を採用。 -/
structure Edge where
  src  : FolgeID
  dst  : FolgeID
  kind : EdgeKind
  deriving DecidableEq, Inhabited, Repr

namespace Edge

/-- 自己 edge かどうかの判定（運用上は禁止だが型レベルでは許容）。 -/
def isSelfLoop (e : Edge) : Bool :=
  e.src = e.dst

/-- 反対方向の edge 構築（同 kind を維持）。
    `relates` のような対称関係や、`wasDerivedFrom` の逆向き参照に利用。 -/
def reverse (e : Edge) : Edge :=
  { src := e.dst, dst := e.src, kind := e.kind }

end Edge

end AgentSpec.Spine

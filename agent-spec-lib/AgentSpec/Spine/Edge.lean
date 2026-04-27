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

    -- 現在（Day 2）:
    structure Edge where
      src  : FolgeID
      dst  : FolgeID
      kind : EdgeKind

    -- Week 4-5 (ResearchNode 定義後、Section 2.8 S4 P2 / F8 適用):
    inductive ResearchEdge : (k : EdgeKind) → (src dst : ResearchNode)
        → (h : src ≠ dst) → Type where
      | wasDerivedFrom : ResearchEdge .wasDerivedFrom a b h
      | refines        : ResearchEdge .refines a b h
      -- ...

## Day 2 意思決定ログ（後続セッション参照用）

詳細は docs Section 2.8 / 2.9 / 12.6 / 10.2 を参照。本 module 固有の判断点のみ要約。

### D1. EdgeKind を inductive enum とする選択（commit `58b75a0`）
- **代案 A**: `inductive ResearchEdge : ResearchNode → ResearchNode → Type` (GA-S4 最終形)
- **採用**: enum + structure 迂回実装
- **理由**: Day 2 時点で ResearchNode 未定義。dependent type 化は Week 4-5 で実施
  （Section 2.8 で計画化）。

### D2. field 名 `src` / `dst` 採用（commit `58b75a0`）
- **代案 A**: `from` / `to` (graph theory 慣習)
- **採用**: `src` / `dst`
- **理由**: `from` は Lean 4 予約語（ビルドエラーで判明）。Section 10.2 Pattern #8 として明文化。

### D3. `isSelfLoop` を Bool 関数とする選択（commit `58b75a0`）
- **代案 A**: `{e : Edge // e.src ≠ e.dst}` の subtype refinement で型レベル排除
- **採用**: Bool 関数で実行時判定
- **理由**: Day 2 hole-driven 段階。refinement 設計は dependent type 化と同時に
  Week 4-5 で実施するのが自然（Section 2.8 S4 P2）。

### D4. `Edge.reverse` の kind 不変設計（commit `58b75a0`）
- **代案 A**: kind ごとに reverse 動作を分岐
- **採用**: kind を保持した uniform reverse
- **理由**: kind の意味論制約は PROV-strict / research-mode 分離（Week 6-7）と
  併せて検討。reverse は graph 操作プリミティブとし、意味論妥当性は呼び出し側責任。
- **検証**: 全 6 variant について `reverse.reverse = id` を Test/Spine/EdgeTest.lean で検証。

### D5. `deriving DecidableEq, Inhabited, Repr` を採用（Pattern #3 部分違反容認）
- **代案 A**: instance を明示命名で Pattern #3 厳格適用
- **採用**: `deriving` で anonymous instance 自動生成
- **理由**: deriving は Lean 4 の標準命名規約で安定した名前を生成。
  Pattern #3 の意図は unfold の脆弱性回避だが、deriving では unfold 不要のため違反の害がない。
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

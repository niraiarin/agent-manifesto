# Phase 5: Manifest Evolution — 引き継ぎファイル

## 状態サマリ

Phase 1–5 完了。全 theorem sorry-free。lake build 通過。

| Phase | 内容 | axiom 数 | sorry | theorem 数 |
|-------|------|---------|-------|-----------|
| 1 | Ontology + T1–T8 | 13 | 0 | — |
| 2 | E1–E2 | 4 | 0 | — |
| 3 | P1–P6 (theorems) | — | 0 (Phase 4 で解消) | 14 |
| 4 | V1–V7 Observable | 20 | 0 | — |
| 5+ | Evolution + Observable + Workflow + Meta | 4 | 0 | 36 |
| **合計** | | **41 axioms** | **0 sorry** | **50 theorems** |

## ファイル構成

```
lean-formalization/
├── lakefile.lean              # Verso project config (Lean 4 v4.25.0)
├── lean-toolchain             # leanprover/lean4:v4.25.0
├── Manifest.lean              # Root module (imports all)
├── Manifest/
│   ├── Ontology.lean          # 基本型 + opaque 述語 (全モジュールの基盤)
│   ├── Axioms.lean            # T1–T8 (13 axioms)
│   ├── EmpiricalPostulates.lean # E1–E2 (4 axioms)
│   ├── Observable.lean        # V1–V7 + Observable/Measurable (20 axioms)
│   ├── Principles.lean        # P1–P6 (14 theorems, 0 sorry)
│   ├── Evolution.lean         # ← Phase 5 の実装先 (現在 placeholder)
│   ├── Workflow.lean          # Placeholder (Phase 3+)
│   └── Meta.lean              # Placeholder (Phase 3+)
├── lean-formalization-details.md  # 設計判断ログ (#1–#16)
└── references/                # スキル・パターン集
```

## Import DAG (循環なし)

```
Ontology ← Axioms
         ← EmpiricalPostulates
         ← Observable ← (Axioms も import)
         ← Evolution   ← Phase 5 で拡張
Principles ← Ontology, Axioms, EmpiricalPostulates, Observable
Manifest   ← 全モジュール
```

## Phase 5 のスコープ

### 必須タスク

1. **Evolution.lean の実装: バージョン間の互換性遷移**
   - `CompatibilityClass` (既に Principles.lean に定義済み) を使った Manifest バージョン遷移の型
   - ManifestVersion 型の定義
   - バージョン間遷移の性質:
     - conservativeExtension の連鎖は conservativeExtension
     - breakingChange の後は移行パスが必要
     - compatibleChange の推移性
   - manifesto.md Section 7「進化する構造としてのマニフェスト」の形式化

2. **既存の CompatibilityClass との接続**
   - Principles.lean の `CompatibilityClass`, `KnowledgeIntegration`, `isGoverned` を
     Evolution 層で再利用（import Manifest.Principles するか、共通部分を Ontology に移すか判断）

### 任意タスク (時間があれば)

3. **robustStructure の具体化** — P5 の安全性制約を Evolution の文脈で使用
4. **systemHealthy の変数ごと閾値** — 一律 threshold → 変数ごと閾値への拡張
5. **Pareto フロンティアの形式化** — paretoImprovement の到達不能領域

## 既存の関連定義 (再利用すべきもの)

### Principles.lean より

```lean
inductive CompatibilityClass where
  | conservativeExtension
  | compatibleChange
  | breakingChange
  deriving BEq, Repr

structure KnowledgeIntegration where
  before       : World
  after        : World
  compatibility : CompatibilityClass

def isGoverned (ki : KnowledgeIntegration) : Prop := ...

def robustStructure (st : Structure) (safety : World → Prop) : Prop := ...
```

### Observable.lean より

```lean
def Observable (P : World → Prop) : Prop := ...
def Measurable (m : World → Nat) : Prop := ...
def systemHealthy (threshold : Nat) (w : World) : Prop := ...
def paretoImprovement (w w' : World) : Prop := ...
```

### Ontology.lean より

```lean
opaque canTransition (agent : Agent) (action : Action) (w w' : World) : Prop
-- Structure, World, Agent 等の基本型すべて
```

## 設計上の注意点

1. **循環依存の回避**: Evolution.lean が Principles.lean を import すると、
   Principles → Observable → ... の下流すべてに依存する。
   CompatibilityClass を Ontology.lean に移す方が import DAG がクリーンになる可能性あり。

2. **axiom vs theorem**: Evolution 層の性質は T1–T8 + E1–E2 から導出可能か要検討。
   導出可能なら theorem、新規仮定が必要なら axiom。新規 axiom を追加する場合は
   空虚性・トートロジー性・反証可能性の3観点でレビュー（Phase 4 の慣例）。

3. **lake build 未実施**: Phase 4 まで VM に Lean がなく未ビルド。
   Phase 5 着手前に `lake build` で Phase 1–4 の型検査を通すことを推奨。

4. **設計判断の記録**: 新しい設計判断は `lean-formalization-details.md` に
   #17 から連番で追記（Phase 1–4 の慣例）。

## マニフェスト原文の関連箇所

- `manifesto.md` Section 3, P3 — 学習の統治、互換性分類
- `manifesto.md` Section 5 — 制約という進化圧
- `manifesto.md` Section 7 — マニフェスト自身のメンテナンス、進化する構造
- `constraints-taxonomy.md` Part IV — 分類自体のメンテナンス

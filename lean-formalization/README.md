# Lean 4 形式化 — マニフェスト公理系

マニフェスト公理系を Lean 4 の型システムで機械検証可能な仕様として形式化したもの。（原典は `archive/manifesto.md` に保管。Lean 形式化が権威的ソース。）
モジュール構造は `EpistemicLayerClass`（認識論的層構造）に基づく。

## ステータス

```
lake build Manifest  →  Build completed successfully
```

| 指標 | 値 |
|------|-----|
| axiom | 53 (T: 15, E: 4, V: 25, App: 20, Structural: 1) |
| theorem | 462 (全て sorry-free) |
| sorry | 0 |
| compression | 8.71x (462 theorems / 53 axioms) |
| Lean ソース | ~9,000 行 (16 モジュール + root) |
| テスト | 529 acceptance tests |

## 認識論的層構造（Epistemic Layer Architecture）

モジュールは以下の 3 Tier に分類される。
Tier B の命題層は `PropositionCategory.strength`（EpistemicLayer.lean で形式化）に基づく。

```
                    ┌─────────────────────────────────┐
  Tier A            │  Ontology.lean                   │  定義的基盤（型のみ、命題なし）
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┴──────────────────┐
  Tier B            │  命題層（strength 降順）          │
  (epistemic)       │                                  │
                    │  5: Axioms.lean          T1-T8   │  constraint（T₀, 縮小不可）
                    │  4: EmpiricalPostulates  E1-E2   │  empiricalPostulate（反証可能）
                    │  3: Principles.lean      P1-P6   │  principle（T+E から導出）
                    │  2: Observable.lean      V1-V7   │  boundary + designTheorem（混在）
                    │  1: DesignFoundation     D1-D14  │  designTheorem（設計定理）
                    │  0: (hypothesis)                  │  （専用モジュールなし）
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┴──────────────────┐
  Tier C            │  メタ理論・応用                    │
  (meta/app)        │                                  │
                    │  Meta.lean              統計・分類 │
                    │  EpistemicLayer.lean     層構造    │
                    │  Evolution.lean         互換性    │
                    │  Workflow.lean          学習      │
                    │  Terminology.lean       用語      │
                    │  Procedure.lean         手続き    │
                    │  FormalDerivationSkill   スキル    │
                    │  ConformanceVerification 準拠検証  │
                    │  AxiomQuality.lean      品質指標  │
                    │  EvolveSkill.lean       /evolve   │
                    └─────────────────────────────────┘
```

## モジュール一覧

### Tier A: 定義的基盤

| モジュール | 内容 |
|-----------|------|
| **Ontology.lean** | World, Agent, Session, Structure, PropositionCategory, PropositionId 等の型定義。全モジュールの基盤。命題なし（定義的拡大のみ） |

### Tier B: 命題層（strength 降順）

| strength | モジュール | 内容 | axioms | theorems |
|----------|-----------|------|--------|----------|
| 5 | **Axioms.lean** | T1-T8 拘束条件。根ノード（依存なし）、AGM 縮小禁止 | 13 | 0 |
| 4 | **EmpiricalPostulates.lean** | E1-E2 経験的公準。反証可能な経験的仮定 | 4 | 0 |
| 3 | **Principles.lean** | P1-P6 基盤原理。T+E から導出される定理群 | 0 | 14 |
| 2-1 | **Observable.lean** | V1-V7 可観測変数 + トレードオフ + Goodhart 防御 + 投資サイクル | 25 | 23 |
| 1 | **DesignFoundation.lean** | D1-D14 設計開発基礎論。T/E/P/L から導出 | 0 | 41 |

### Tier C: メタ理論・応用

| モジュール | 内容 | axioms | theorems |
|-----------|------|--------|----------|
| **Meta.lean** | AxiomSystemProfile, 層の独立性, 反証影響分析 | 0 | 12 |
| **EpistemicLayer.lean** | 認識論的層の6性質, EpistemicLayerClass typeclass, LayerAssignment | 0 | 47 |
| **Evolution.lean** | ManifestVersion, 互換性格子, Section 7 自己適用 | 0 | 16 |
| **Workflow.lean** | LearningPhase, Gate, VerificationTiming, 学習ライフサイクル | 0 | 7 |
| **Terminology.lean** | 用語リファレンスの形式化（ExtensionKind, AxiomKind 等） | 0 | 23 |
| **Procedure.lean** | T₀/Γ\T₀ 分類規則, AGM 操作許可, 手順書形式化 | 0 | 25 |
| **FormalDerivationSkill.lean** | 形式的導出スキルの自己検証（Phase, Step, Strategy 等） | 20 | 35 |
| **ConformanceVerification.lean** | 3 軸準拠検証（分類・規則・用語） | 3 | 17 |
| **AxiomQuality.lean** | 圧縮比, Coverage, Quality Profile | 0 | 11 |
| **EvolveSkill.lean** | /evolve スキルの形式評価 | 0 | 29 |

## Import DAG

```
Ontology ← Axioms
         ← EmpiricalPostulates
         ← Observable        ← Axioms
         ← Principles        ← Axioms, EmpiricalPostulates, Observable
         ← Evolution         ← Axioms, EmpiricalPostulates
         ← Workflow          ← Axioms
         ← Meta              ← Axioms, EmpiricalPostulates, Observable
         ← Terminology
         ← DesignFoundation  ← Axioms, EmpiricalPostulates, Observable, Principles

FormalDerivationSkill ← Ontology, DesignFoundation
Procedure            ← FormalDerivationSkill, Terminology
EpistemicLayer       ← Ontology, Procedure
ConformanceVerification ← Procedure, Terminology, Axioms, EmpiricalPostulates, Observable, Meta
AxiomQuality         ← Meta, Procedure, Terminology
EvolveSkill          ← Workflow, Evolution, DesignFoundation

Manifest             ← 全 16 モジュール
```

## マニフェストとの対応

| マニフェスト | Lean 形式化 | 認識論的層 |
|------------|------------|-----------|
| T1-T8（拘束条件） | `axiom` — 証明なしで仮定 | constraint (5) |
| E1-E2（経験的公準） | `axiom` — 反証可能 | empiricalPostulate (4) |
| P1-P6（基盤原理） | `theorem` — T/E から導出 | principle (3) |
| V1-V7（変数） | `opaque` + `Measurable` axiom | boundary (2) |
| L1-L6（境界条件） | `BoundaryLayer`, `BoundaryId` | boundary (2) |
| D1-D14（設計定理） | `theorem` — T/E/P/L から導出 | designTheorem (1) |
| Section 6（投資サイクル） | `trust_accumulates_gradually` 等 | designTheorem (1) |
| Section 7（自己適用） | `manifest_persists_as_structure` 等 | designTheorem (1) |

## Models/PoC — 認識論的層モデルのインスタンシエーション

`EpistemicLayerClass` を任意のドメインでインスタンス化する PoC パイプライン。
Phase 0-3 の一気通貫テストで 500 シナリオ（200+ ドメイン）の形式検証を完了。

| コンポーネント | 役割 |
|--------------|------|
| `generate-conditional-axiom-system.sh` | ModelSpec JSON → Lean 4 コード生成 |
| `check-monotonicity.sh` | 層割り当ての単調性検証 |
| `test-coverage/` | カバレッジテストパイプライン（[詳細](Manifest/Models/PoC/test-coverage/README.md)） |

```
500 シナリオ = Round 1 (S1-S300, LLM) + Round 2 (S301-S500, LLM Phase 0-3) + Synthetic (100)
BUILD PASS: 532 / BUILD FAIL: 0 / 単調性違反(意図的): 47
```

## ビルド

```sh
# Lean 4 v4.25.0 + elan が必要
export PATH="$HOME/.elan/bin:$PATH"
lake build Manifest
```

## 関連ファイル

- `lean-formalization-details.md` — 設計判断ログ
- `SKILL.md` — Lean 4 Manifest スキル定義
- `references/` — オントロジーパターン集、axiom カタログ、抽出ガイド

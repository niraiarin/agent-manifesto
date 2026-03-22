# Lean 4 形式化 — マニフェスト公理系

[マニフェスト](../manifesto.md)の公理系（T1–T8, E1–E2, P1–P6, V1–V7）を
Lean 4 の型システムで機械検証可能な仕様として形式化したもの。

## ステータス

```
lake build Manifest → Build completed successfully (11 jobs)
```

| 指標 | 値 |
|------|-----|
| axiom | 41 (T: 13, E: 4, V+投資: 24) |
| theorem | 50 (全て sorry-free) |
| sorry | 0 |
| Lean ソース | ~2,800 行 (8 モジュール) |

## モジュール構成

```
Manifest/
├── Ontology.lean           # 基本型 + opaque 述語 (全モジュールの基盤)
│                           # World, Agent, Session, Structure, CompatibilityClass,
│                           # BoundaryLayer, BoundaryId, Mitigation 等
├── Axioms.lean             # T1–T8 拘束条件 (13 axioms)
├── EmpiricalPostulates.lean # E1–E2 経験的公準 (4 axioms)
├── Observable.lean         # V1–V7 + トレードオフ + Goodhart + 投資サイクル (24 axioms)
│                           # HealthThresholds, Pareto, robustStructure 具体化
├── Principles.lean         # P1–P6 基盤原理 (14 theorems, 0 sorry)
├── Evolution.lean          # ManifestVersion, 互換性格子構造, Section 7 自己適用
├── Workflow.lean           # 学習ライフサイクル, Gate, KnowledgeItem
└── Meta.lean               # 公理の認識論的地位, 反証影響分析, AxiomSystemProfile
```

### Import DAG (循環なし)

```
Ontology ← Axioms
         ← EmpiricalPostulates
         ← Observable ← Axioms
         ← Evolution  ← Axioms, EmpiricalPostulates
         ← Workflow   ← Axioms
         ← Meta       ← Axioms, EmpiricalPostulates, Observable
Principles ← Ontology, Axioms, EmpiricalPostulates, Observable
Manifest   ← 全モジュール
```

## マニフェストとの対応

| マニフェスト | Lean 形式化 |
|------------|------------|
| T1–T8（拘束条件） | `axiom` — 証明なしで仮定する命題 |
| E1–E2（経験的公準） | `axiom` — docstring で `[empirical]` マーク |
| P1–P6（基盤原理） | `theorem` — T/E からの導出。sorry 0 |
| V1–V7（変数） | `opaque` + `Measurable` axiom |
| L1–L6（境界条件） | `BoundaryLayer`, `BoundaryId` — 三段構造 |
| Section 6（投資サイクル） | `trust_accumulates_gradually`, `trust_drives_investment` 等 |
| Section 7（自己適用） | `manifest_persists_as_structure`, `stasisUnhealthy` 等 |
| Part IV（分類メンテナンス） | `ReviewSignal`, `review_within_framework` |

## ビルド

```sh
# Lean 4 v4.25.0 + elan が必要
lake build Manifest
```

## 関連ファイル

- `lean-formalization-details.md` — 設計判断ログ (#1–#32) + 整合性チェック
- `HANDOFF.md` — 状態サマリと引き継ぎ情報
- `SKILL.md` — Lean 4 Manifest スキル定義（参考資料）
- `references/` — オントロジーパターン集、axiom カタログ、抽出ガイド

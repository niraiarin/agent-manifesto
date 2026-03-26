import Manifest.Ontology
import Manifest.Axioms
import Manifest.EmpiricalPostulates
import Manifest.Principles
import Manifest.Workflow
import Manifest.Observable
import Manifest.Meta
import Manifest.Evolution
import Manifest.DesignFoundation
import Manifest.FormalDerivationSkill
import Manifest.Terminology
import Manifest.Procedure
import Manifest.ConformanceVerification
import Manifest.AxiomQuality
import Manifest.EvolveSkill
import Manifest.EpistemicLayer

/-!
# Agent Manifest — Formal Specification

マニフェスト「永続する構造と一時的なエージェントの協約」の
公理系を Lean 4 で形式化した仕様書。

63 axioms, 316 theorems, 0 sorry. Compression 5.01x.

## モジュール構成（認識論的層構造）

モジュールは `EpistemicLayerClass`（EpistemicLayer.lean）に基づき 3 Tier に分類される。

### Tier A: 定義的基盤

- **Ontology** — 論議領域の型定義（World, Agent, Session, Structure, PropositionCategory 等）

### Tier B: 命題層（`PropositionCategory.strength` 降順）

| strength | モジュール | 内容 |
|----------|-----------|------|
| 5 | **Axioms** | T1–T8 拘束条件（T₀, 根ノード, 縮小不可） |
| 4 | **EmpiricalPostulates** | E1–E2 経験的公準（反証可能） |
| 3 | **Principles** | P1–P6 基盤原理（T+E から導出） |
| 2-1 | **Observable** | V1–V7 可観測変数 + トレードオフ + Goodhart 防御 |
| 1 | **DesignFoundation** | D1–D14 設計開発基礎論 |

### Tier C: メタ理論・応用

- **Meta** — 公理系のメタ性質（AxiomSystemProfile, 層の独立性）
- **EpistemicLayer** — 認識論的層の6性質, EpistemicLayerClass typeclass, LayerAssignment
- **Evolution** — バージョン互換性分類, Section 7 自己適用
- **Workflow** — 学習ライフサイクル, Gate, VerificationTiming
- **Terminology** — 用語リファレンスの形式化
- **Procedure** — T₀/Γ\T₀ 分類規則, AGM 操作, 手順書形式化
- **FormalDerivationSkill** — 形式的導出スキルの自己検証
- **ConformanceVerification** — 3 軸準拠検証
- **AxiomQuality** — 圧縮比, Coverage, Quality Profile
- **EvolveSkill** — /evolve スキルの形式評価
-/

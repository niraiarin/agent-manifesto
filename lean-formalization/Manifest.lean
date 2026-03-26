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

## モジュール構成

- **Ontology** — 基本型定義 (World, Agent, Session, Structure, ...)
- **Axioms** — 拘束条件 T1–T8 の axiom 宣言
- **EmpiricalPostulates** — 経験的公準 E1–E2 の axiom 宣言
- **Principles** — 基盤原理 P1–P6 の theorem 導出
- **Workflow** — ワークフロー遷移規則 (Phase 3+)
- **Observable** — 可観測性 V1–V7 (Phase 4)
- **Meta** — メタ定理: 無矛盾性・実行可能性 (Phase 3+)
- **Evolution** — バージョン互換性分類 (Phase 5)

## 現在のフェーズ: Phase 5 完了

- Phase 1: Ontology + T1–T8 axiom 化 ✓
- Phase 2: E1–E2 経験的公準 axiom 化 ✓
- Phase 3: P1–P6 基盤原理 theorem 導出 ✓
- Phase 4: V1–V7 Observable 変数 ✓
- Phase 5: Evolution バージョン互換性 ✓
-/

/-!
# AgentSpec.Core: 基本型と基本 instance

Phase 0 Week 1 — 最小プレースホルダ。
Week 2 以降で GA-S2 (FolgeID), GA-S4 (Edge Type) 等の具体型を追加していく。

## この時点でカバーする Gap

- **GA-I5** (CSLib/LeanHammer/LeanDojo 依存): lakefile.lean に require 宣言（Week 6 で有効化）
- **GA-I7** (high-tokenizer SpecSystem): (b) 再定義方針を採用、TypeSpec/FuncSpec の Lean 内再定義は Week 3 で実施
- **GA-T8** (Lean バージョン管理): lean-toolchain で v4.29.0 に pin
- **GA-C32** (Capability-separated import): agent-spec-lib を独立パッケージとして隔離、外部からの副作用的 import を最小化

## 設計原則（Phase 0 全体に適用）

1. **T₀ 無矛盾性の継承**（GA-F C1）: `lake build` で型検査を通す
2. **axiom 最小化**（formal-derivation 設計原則）: axiom 0 を目指し、型定義 + theorem で構成
3. **GA-W7 (termination 保証)**: `partial def` を避ける、必要時は明示的にマーク
4. **GA-W4 (sorry accumulation)**: sorry を使わない、CI で grep 検査予定
-/

/-!
## Week 2-3 の Spine 層追加計画

Week 2-3 では `AgentSpec/Spine/` 配下に EvolutionStep, SafetyConstraint,
LearningCycle, Observable を追加予定。G5-1 Section 3.5 の当初計画は
Cslib.LTS の再利用を想定していたが、CSLib 依存は GA-I5 に従い Week 6 まで
延期するため、Week 2-3 では Mathlib の `Mathlib.Order.BoundedOrder` 等の
既存型または独自定義で代替する。
-/

namespace AgentSpec

/-- プレースホルダ。Week 2 で正式な FolgeID / NodeID 等に置き換える。
    `#eval version` で compile が通ることを確認できる。 -/
def version : String := "0.0.1-phase0-week1"

-- 注: 旧 `theorem version_nonempty` は trivially-true (Verifier Round 1 指摘 1)
-- のため削除。Week 2 以降で実質的な型定義と定理を追加していく。

end AgentSpec

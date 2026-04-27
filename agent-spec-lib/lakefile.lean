-- agent-spec-lib: agent-manifesto 研究プロセスの Lean 型表現
-- Phase 0 Week 1: 環境準備（Mathlib 依存のみ、CSLib/LeanHammer は Week 6 で追加予定）
-- 参照: docs/research/new-foundation-survey/10-gap-analysis.md GA-I5, GA-T2, GA-T8

import Lake
open Lake DSL

package «agent-spec-lib» where
  -- Day 162 (PI-7 Phase 1 acceptance #4): semantic version
  -- Day 188 (Phase 5 α、Day 187 user direction で rc1 維持 → stable bump 振替): v0.1.0 stable
  version := v!"0.1.0"
  leanOptions := #[
    -- GA-C27 (Trusted code 最小化): native_decide を型検査外の信頼根とする拡張を明示的に禁止
    ⟨`autoImplicit, false⟩,
    -- 廃止予定 API 使用時の警告 (GA-W7 の termination 保証はコード設計レベル：partial def 回避 + fuel pattern、lakefile レベルでは直接対応不可)
    ⟨`linter.deprecated, true⟩
  ]

-- GA-I7 Phase 0: TypeSpec/FuncSpec は high-tokenizer 由来だが、
-- upstream 依存を避けて re-definition 方針を採用（Pass 6 判断 B 準拠）

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.29.0"

-- Week 6 で追加予定（GA-C7 SMT ハンマー統合、GA-I5 CSLib/LeanHammer 依存）:
-- require auto from git
--   "https://github.com/leanprover-community/lean-auto.git" @ "v4.29.0-hammer"
-- require Duper from git
--   "https://github.com/leanprover-community/duper.git" @ "v4.29.0"
-- require CSLib from git
--   "https://github.com/cs-lib-lean/cslib.git" @ "main"

@[default_target]
lean_lib «AgentSpec» where
  -- 到達不能タクティクへの警告（記録目的、Mathlib コンパイル時には無視される weak. プレフィックス形式）
  -- GA-C31 / GA-W7 の partial def 防止はコード設計レベル対応（fuel pattern 等）で実現
  leanOptions := #[⟨`weak.linter.unreachableTactic, true⟩]

-- Week 2 Day 2 で分離: test lib は本番 AgentSpec から独立してビルドされる
-- 対処: Verifier Round 3 indicate 3、/verify Round 1 指摘 4、Day 1 /verify R1 I1
lean_lib «AgentSpecTest» where
  leanOptions := #[⟨`weak.linter.unreachableTactic, true⟩]

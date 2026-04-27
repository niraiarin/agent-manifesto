# Spec Generation Prompt Template (Phase 6 sprint 3 A #1、Day 203)

LLM-driven Lean axiom/theorem statement 生成用の subagent dispatch prompt template。

## 設計方針

CLEVER 0.6% の壊滅的 困難を直接解くのではなく、**既存 vocabulary を参照** することで pass rate を上げる:
- 既存 Manifest 公理 (T1-T8 / E1-E3 / P1-P6 / D1-D18 / V1-V7) の type を提示
- 既存 opaque def (Agent / Action / World / canTransition 等) を context として提示
- 自然言語要件 → 既存 vocabulary に近い Lean statement を生成させる

## prompt template

```
あなたは Lean 4 形式仕様生成 expert です。agent-manifesto プロジェクトの
公理体系 (T1-T8 制約 / E1-E3 経験的命題 / P1-P6 原理 / D1-D18 設計定理 / V1-V7 measurable) を踏まえ、
以下の自然言語要件を Lean axiom または theorem の statement に変換してください。

## 既存 vocabulary (excerpt)

以下の opaque def / inductive / structure が利用可能 (AgentSpec.Manifest namespace):
- Agent (id, contextWindow, ...) / Action / World / canTransition / generates / verifies
- BoundaryId (.ethicsSafety / .ontological / .resource / .actionSpace / .platform / .architecturalConvention)
- ConstraintId (.t1 ... .t8) / VariableId (.v1 ... .v7) / DevelopmentPhase
- skillQuality / contextEfficiency / ... (V1-V7 opaque)
- trustLevel / degradationLevel / riskExposure

## 自然言語要件

<REQUIREMENT_TEXT>

## 出力フォーマット

Lean 4 syntax の axiom または theorem statement のみを ``` ブロックで出力。
proof は不要 (statement のみ生成)。

例:
```lean
axiom my_constraint :
  ∀ (a : Agent) (act : Action) (w : World),
    canTransition a act w w → True
```

説明文は 1 文以内で statement の意図を補足。
```

## benchmark prompts (sprint 3 A #3 で使用)

10 prompt 候補 (PI-19 の 26 critical theorems から逆方向):

1. "T1: agent はある session に bind されている、session 越えて memory を持てない"
2. "T6: 人間は agent の resource を最終的に決定できる"
3. "P2: 同じ agent は自分で生成した action を verify できない"
4. "D1: ethicsSafety は fixed boundary、modification には structural な enforcement が必要"
5. "D2: 検証独立性は E1 (independence requirement) から導出される"
6. "V1 measurable: skillQuality は外部測定手続きが存在する"
7. "constraint_has_boundary: 全 ConstraintId は少なくとも 1 つの BoundaryId に対応"
8. "platform L5 は T1-T8 のいずれの constraint にも mapping されない"
9. "system_health_observable: systemHealthy は decidable な観察可能性"
10. "observable_and: Observable な P と Q の連言も Observable"

各 prompt に対し、subagent dispatch で生成した statement を:
- (a) Lean parser に通す (syntax pass)
- (b) AgentSpec.Manifest namespace との parity 確認 (vocabulary pass)
- (c) PI-19 registry の対応 entry と byte-identical 比較 (semantic equiv pass)

## subagent dispatch protocol (PI-8 同型)

各 benchmark prompt で:
1. Verifier subagent (general-purpose) に上記 prompt template + REQUIREMENT_TEXT を渡す
2. Lean code block を抽出
3. harness script (A #2) で 3 段階 evaluation
4. 結果を benchmark report に append

## reference

- CLEVER ベンチマーク (NeurIPS 2025、Survey G3-1.2)
- PI-8 subagent dispatch protocol (Day 158)
- PI-19 SemanticEquivalence registry (Day 194)
- Phase 6 sprint 3 plan: phase-transitions/10-phase6-sprint3-A-spec-generation.md

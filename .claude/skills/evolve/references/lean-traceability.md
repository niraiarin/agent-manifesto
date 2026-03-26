# Lean 形式化 逆引きチェックリスト

各 Lean ケース・定理が、対応するテストと SKILL.md の実行手順に展開されていることを確認するための逆引き表。
（Section 7/9 テストは `tests/phase5/test-evolve-structural.sh` 内の記述名称）

## validPhaseTransition 逆引きチェックリスト

各 Lean ケースが、対応するテストと SKILL.md の実行手順に展開されていることを確認するための逆引き表。
（Section 7 テストは `tests/test-evolve-structural.sh` 内の記述名称）

| Lean ケース（Workflow.lean `validPhaseTransition`） | テスト（Section 7） | SKILL.md ステップ | Gap |
|--------------------------------------------------|-------------------|-----------------|-----|
| observation → hypothesizing | "Lean trace: observation -> hypothesizing (Phase 1->2 in SKILL.md)" | Step 1: Observer 起動 | なし |
| hypothesizing → verification | "Lean trace: hypothesizing -> verification (Phase 2->3 in SKILL.md)" | Step 2: Hypothesizer 起動 | なし |
| verification → integration | "Lean trace: verification -> integration (Phase 3->4 in SKILL.md)" | Step 3: Verifier 起動 | なし |
| integration → retirement | "Lean trace: integration -> retirement (Phase 4->5 in SKILL.md)" | Step 5/6: Integrator + 退役処理 | なし |
| verification → hypothesizing (FAIL loopback) | "Lean trace: verification -> hypothesizing (FAIL loopback in SKILL.md)" | Step 3 FAIL 分析（ループバック） | なし |
| verification → observation (observation_error loopback) | "Lean trace: verification -> observation (observation_error loopback)" | Step 3 FAIL 分析（observation_error → Phase 1） | なし |
| retirement → observation (cycle) | "Lean trace: retirement -> observation (cycle in SKILL.md)" | Step 6 → Step 1（次サイクル） | なし |

## その他の Lean 定義 — テスト対応追加行

| スキルの概念 | テスト（Section 3 / Step） | 備考 | Gap |
|------------|--------------------------|------|-----|
| `integrationGateCondition` | test-evolve-structural.sh Section 3 | 統合ゲートの 3 条件を確認 | なし |
| `retirementCandidate` | SKILL.md Step 6 | 退役基準 A（breakingChange）と基準 B（6ヶ月）の区別 | なし |

## Workflow.lean 追加定理 逆引きチェックリスト（Run 40 追加）

| Lean 定理（Workflow.lean） | SKILL.md での運用化 | 備考 | Gap |
|---------------------------|---------------------|------|-----|
| `no_self_phase_transition` | 各 Phase は明確に分離（Phase 1→2→3→4→5 の線形進行） | 同一 Phase 内でのループは禁止。FAIL ループバックも verification→hypothesizing であり自己遷移ではない | なし |
| `full_cycle_exists` | アーキテクチャ図: Phase 1→2→3→4→5 の全フェーズが存在 | Step 1→Step 6 の完全サイクル | なし |
| `retirement_only_after_integration` | Step 6: 退役は Step 5（統合）の後にのみ実行 | 基準 A/B とも統合済み知識が対象 | なし |
| `no_self_knowledge_transition` | KnowledgeStatus の各状態は一方向に遷移 | no_self_phase_transition の知識状態版 | なし（Run 56 で Section 7 にテスト追加済み） |
| `knowledge_full_cycle_exists` | 知識は observed から retired まで全状態を通過可能 | full_cycle_exists の知識状態版 | なし（Run 56 で Section 7 にテスト追加済み） |
| `integration_requires_verification` | Step 2-3: 検証なしの統合は禁止（PASS_LIST 空 → Phase 4 不可） | ゲート判定で構造的に強制 | なし |
| `feedback_precedes_improvement` | Step 3→Step 5 の順序（T5 のワークフロー層表現） | 検証済みのみ統合可能 | なし（Run 56 で Section 7 にテスト追加済み） |

## Evolution.lean 逆引きチェックリスト（Run 40 追加）

### 互換性分類の代数的性質

| Lean 定理/定義（Evolution.lean） | SKILL.md での運用化 | 備考 |
|--------------------------------|---------------------|------|
| `CompatibilityClass` (inductive) | Step 5: 互換性分類の 3 値 | conservative / compatible / breaking |
| `CompatibilityClass.join` (def) | Step 5: 複数改善のコミット時に互換性分類を合成 | 最悪の分類が支配する |
| `CompatibilityClass.le` (def) | 互換性の順序: conservative < compatible < breaking | H4 仮説の形式的根拠 |
| `conservativeExtension_le` | H4: conservative extension が最小（最も安全） | H4 の形式的正当化 |
| `breakingChange_ge` | breaking change が最大（最も制限的） | P3 hook での検証根拠 |
| `compatibility_join_comm` | 合成順序に依存しない（改善 A+B = B+A） | 統合順序の自由度を保証 |
| `compatibility_join_assoc` | 3 件以上の改善の合成は結合的 | バッチ統合の正当性 |
| `compatibility_join_idem` | 同一分類の合成は冪等 | 重複分類の安全性 |
| `conservative_extension_transitive` | conservative の連鎖は conservative | H4: conservative 優先戦略の安全性根拠 |
| `compatible_change_closed` | compatible 以下の合成は compatible 以下 | compatible change の安全な合成 |
| `breaking_change_dominates` | 1 つでも breaking があれば全体が breaking | Step 5: 互換性分類付きコミット |

### バージョン履歴

| Lean 定理/定義（Evolution.lean） | SKILL.md での運用化 | 備考 |
|--------------------------------|---------------------|------|
| `ManifestVersion` (structure) | evolve-history.jsonl の run 番号 | バージョン構造体 |
| `VersionTransition` (structure) | 各 Run の改善遷移 | from→to + compatibility |
| `validVersionTransition` (def) | evolve-history.jsonl のバージョン記録（単調増加） | バージョン番号の単調増加 |
| `breakingChangeRequiresEpochBump` (def) | breaking change 時のエポック増加要件 | Step 5: breaking → epoch bump |
| `VersionHistory` (def) | evolve-history.jsonl の遷移列 | 型エイリアス |
| `historyCompatibility` (def) | evolve-history.jsonl の互換性フィールド | 遷移列全体の互換性計算 |
| `empty_history_conservative` | 初回 evolve は conservative（恒等元） | Run 1 の初期状態 |
| `two_conservative_compose` | 2 つの conservative 遷移の合成は conservative | 複数 conservative 改善の安全性 |

### マニフェスト自己適用

| Lean 定理/定義（Evolution.lean） | SKILL.md での運用化 | マニフェスト概念 |
|--------------------------------|---------------------|-----------------|
| `isManifestStructure` (def) | D9: SKILL.md 自体が構造の一種 | manifest は Structure |
| `governedTransition` (def) | 全バージョン遷移は P3 統治下 | governed = true |
| `stasisUnhealthy` (def) | 引き継ぎ条件: 不正な deferral は stasisUnhealthy | 静止は不健全 |
| `ReviewSignal` (inductive) | D9: 分類見直しのシグナル種別 | empirical / formal / external |
| `ClassificationReview` (structure) | D9: 互換性分類の見直し構造体 | review_within_framework の前提 |
| `safeVersionTransition` (def) | P5: 安全性制約の遷移前後保持 | robustStructure の Evolution 適用 |
| `manifest_persists_as_structure` | T2: /evolve の構造はセッションを超えて永続 | T2 自己適用 |
| `ungoverned_manifest_change_irreversible` | P3c: 統治なき破壊的変更は不可逆 | 引き継ぎ条件の理論的根拠 |
| `review_within_framework` | D9: 分類の見直しは framework 内で対処可能 | 自己硬直化防止 |
| `manifesto_probabilistically_interpreted` | T4: 各 evolve 実行は非決定的（P2 の限界の根拠） | T4 自己適用 |
| `manifesto_evaluation_requires_independence` | P2: 検証分離（Verifier は独立コンテキスト） | E1 自己適用 |
| `manifesto_scope_risk_coscaling` | P1/E2: 適用範囲拡大 → リスク拡大 | E2 自己適用 |

## EvolveSkill.lean 全定理 逆引きチェックリスト（Run 39 追加）

| Lean 定理（EvolveSkill.lean） | φ | SKILL.md ステップ | テスト（Section 9） |
|-------------------------------|---|-------------------|---------------------|
| `phase_order_aligns_with_workflow` | φ₁ | Step 1→5 のフェーズ順序 | "φ₁: phase order" |
| `evolve_full_cycle_matches_workflow` | φ₁ | Step 6 → Step 1（サイクル） | "φ₁: full cycle" |
| `all_phases_have_agents` | φ₂ | アーキテクチャ図 | "φ₂: all phases have agents" |
| `all_agents_used` | φ₂ | アーキテクチャ図（4 エージェント） | "φ₂: all agents used" |
| `evolve_verifier_sufficient_for_low` | φ₃ | Step 3: P2 の限界（low レベル） | "φ₃: verifier sufficient for low" |
| `evolve_verifier_insufficient_for_moderate` | φ₃ | Step 3: P2 の限界（moderate 不十分） | "φ₃: verifier insufficient moderate" |
| `evolve_verifier_insufficient_for_high` | φ₃ | Step 3: リスク判定（high は人間レビュー推奨） | "φ₃: verifier insufficient high" |
| `evolve_verifier_insufficient_for_critical` | φ₃ | Step 3: リスク判定（critical は自動停止） | "φ₃: verifier insufficient critical" |
| `integration_gate_structure` | φ₄ | Step 4: 人間承認 + Step 5: 統合 | "φ₄: integration gate" |
| `evolve_no_verification_bypass` | φ₅ | Step 2-3: 検証なしの統合禁止 | "φ₅: no verification bypass" |
| `conservative_strategy_safe` | φ₆ | H4 仮説（conservative extension 優先） | "φ₆: conservative strategy safe" |
| `breaking_change_propagates` | φ₆ | Step 5: 互換性分類付きコミット | "φ₆: breaking change propagates" |
| `retirement_criteria_dual` | φ₇ | Step 6: 基準 A / 基準 B | "φ₇: retirement criteria dual" |
| `formal_retirement_matches_workflow` | φ₇ | Step 6: 基準 A（breakingChange） | "φ₇: formal retirement" |
| `all_components_enumerated` | φ₈ | D9 セクション: 構成要素リスト | "φ₈: all components enumerated" |
| `observability_first` | φ₉ | Step 1: Observer が最初のフェーズ | "φ₉: observability first" |
| `verification_precedes_integration` | φ₉ | Step 3 → Step 5 の順序 | "φ₉: verification precedes integration" |
| `all_hypotheses_enumerated` | φ₁₀ | 仮説テーブル（H1-H5） | "φ₁₀: all hypotheses enumerated" |
| `hypothesis_count` | φ₁₀ | 仮説数 = 5 | "φ₁₀: hypothesis count" |
| `deferral_requires_justification` | φ₁₁ | Step 0: 引き継ぎ条件（3 条件） | "φ₁₁: deferral requires justification" |
| `deferral_status_exhaustive` | φ₁₁ | Step 0: DeferralStatus（open/resolved/abandoned） | "φ₁₁: deferral status exhaustive" |
| `loopback_target_valid_transition` | φ₁₂ | Step 3: FAIL 分析（ループバック遷移の有効性） | "φ₁₂: loopback target valid transition" |
| `loopback_agent_determined` | φ₁₃ | Step 3: Orchestrator が loopbackTarget で委任先を決定 | "φ₁₃: loopback agent determined" |
| `observation_error_loops_to_observer` | φ₁₄ | Step 3: observation_error → Observer（Phase 1） | "φ₁₄: observation_error loops to observer" |
| `hypothesis_error_loops_to_hypothesizer` | φ₁₅ | Step 3: hypothesis_error → Hypothesizer（Phase 2） | "φ₁₅: hypothesis_error loops to hypothesizer" |
| `precondition_error_no_loopback` | φ₁₆ | Step 3: precondition_error → ループバックなし | "φ₁₆: precondition_error no loopback" |
| `loopback_budget_is_parameter` | φ₁₇ | Step 3: ループバック予算は T6 パラメータ（公理的導出なし） | "φ₁₇: loopback budget is parameter" |
| `untracked_forward_reference_violates_d3` | — | Step 7: notes/deferred 整合性（D3 前提引用追跡） | テスト欠如: Section 9 に専用テストなし（Section 10 で間接的に確認） |
| `evolve_skill_compliant` | φ合成 | 全体の準拠性（φ₁∧φ₂∧φ₃∧φ₅∧φ₉） | "evolve_skill_compliant" |

## Procedure.lean Structure-AGM Bridge 定理 逆引きチェックリスト（Run 55 追加）

| Lean 定理（Procedure.lean） | SKILL.md での運用化 | 備考 | Gap |
|---------------------------|---------------------|------|-----|
| `manifest_contraction_forbidden'` | P3: manifest への縮小は禁止（L1 境界の形式的根拠） | structurePartition .manifest = .baseTheory → contraction 禁止 | なし（Run 56 で Section 13 にテスト追加済み） |
| `manifest_revision_forbidden` | P3: manifest への revision も禁止（T₀ 変更禁止の Structure 版） | contraction と同様に permittedOp = false | なし（Run 56 で Section 13 にテスト追加済み） |
| `non_manifest_all_ops_permitted` | P3: 非 manifest 構造（skill/test/document 等）は全 AGM 操作が許可 | StructureKind ≠ .manifest → 全 op = true | なし（Run 56 で Section 13 にテスト追加済み） |
| `empty_world_no_contraction_affected` | P3: 空の構造セットでは contraction の影響集合は空 | World.structures = [] → contractionAffected 発生なし | なし（Run 56 で Section 13 にテスト追加済み） |
| `manifest_no_contraction_affected` | P3: manifest は contraction が禁止されているため影響集合は発生しない | manifest 縮小禁止 → 影響波及なし | なし（Run 56 で Section 13 にテスト追加済み） |
| `contraction_affected_trans` | P3: contraction 影響の推移性（reachableVia の推移性から導出） | s → mid → t の波及は s → t に集約 | なし（Run 56 で Section 13 にテスト追加済み） |

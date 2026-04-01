# Lean 形式化 逆引きチェックリスト

各 Lean ケース・定理が、対応するテストと SKILL.md の実行手順に展開されていることを確認するための逆引き表。
（Section 7/9 テストは `tests/phase5/test-evolve-structural.sh` 内の記述名称）

## validPhaseTransition 逆引きチェックリスト

各 Lean ケースが、対応するテストと SKILL.md の実行手順に展開されていることを確認するための逆引き表。
（Section 7 テストは `tests/phase5/test-evolve-structural.sh` 内の記述名称）

| Lean ケース（Workflow.lean `validPhaseTransition`） | テスト（Section 7） | SKILL.md ステップ | Gap |
|--------------------------------------------------|-------------------|-----------------|-----|
| observation → hypothesizing | "Lean trace: observation -> hypothesizing (Phase 1->2 in SKILL.md)" | Step 1: Observer 起動 | なし |
| hypothesizing → verification | "Lean trace: hypothesizing -> verification (Phase 2->3 in SKILL.md)" | Step 2: Hypothesizer 起動 | なし |
| verification → judge | — (Phase 3→3.5 未形式化) | Step 3: Verifier PASS → Judge 評価 | **Gap**: Workflow.lean に judge フェーズ未定義。Phase 3.5 は SKILL.md で運用的に導入されたが Lean 形式化が追随していない |
| judge → integration | — (Phase 3.5→4 未形式化) | Step 3.5: Judge PASS → Integrator 起動 | **Gap**: 同上。judge→integration の遷移が validPhaseTransition に未追加 |
| verification → integration | "Lean trace: verification -> integration (Phase 3->4 in SKILL.md)" | Step 3: Verifier 起動（Judge 省略時のフォールバック） | なし |
| integration → retirement | "Lean trace: integration -> retirement (Phase 4->5 in SKILL.md)" | Step 5/6: Integrator + 退役処理 | なし |
| verification → hypothesizing (FAIL loopback) | "Lean trace: verification -> hypothesizing (FAIL loopback in SKILL.md)" + "Lean trace: verification -> hypothesizing exists in Workflow.lean" | Step 3 FAIL 分析（ループバック） | なし |
| verification → observation (observation_error loopback) | "Lean trace: verification -> observation (observation_error loopback)" | Step 3 FAIL 分析（observation_error → Phase 1） | なし |
| retirement → observation (cycle) | "Lean trace: retirement -> observation (cycle in SKILL.md)" | Step 6 → Step 1（次サイクル） | なし |

## その他の Lean 定義 — テスト対応追加行

| スキルの概念 | テスト（Section 3 / Step） | 備考 | Gap |
|------------|--------------------------|------|-----|
| `integrationGateCondition` | phase5/test-evolve-structural.sh Section 3 | 統合ゲートの 3 条件を確認 | なし |
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
| `evolve_full_cycle_matches_workflow` | φ₁ | Step 6 → Step 1（サイクル） | "φ₁: phase order" (full cycle subset) |
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
| `all_hypotheses_enumerated` | φ₁₀ | 仮説テーブル（H1-H6） | "φ₁₀: all hypotheses enumerated" |
| `hypothesis_count` | φ₁₀ | 仮説数 = 6 | "φ₁₀: hypothesis count" |
| `deferral_requires_justification` | φ₁₁ | Step 0: 引き継ぎ条件（3 条件） | "φ₁₁: deferral requires justification" |
| `deferral_status_exhaustive` | φ₁₁ | Step 0: DeferralStatus（open/resolved/abandoned） | "φ₁₁: deferral status exhaustive" |
| `loopback_target_valid_transition` | φ₁₂ | Step 3: FAIL 分析（ループバック遷移の有効性） | "φ₁₂: loopback target valid transition" |
| `loopback_agent_determined` | φ₁₃ | Step 3: Orchestrator が loopbackTarget で委任先を決定 | "φ₁₃: loopback agent determined" |
| `observation_error_loops_to_observer` | φ₁₄ | Step 3: observation_error → Observer（Phase 1） | "φ₁₄: observation_error loops to observer" |
| `hypothesis_error_loops_to_hypothesizer` | φ₁₅ | Step 3: hypothesis_error → Hypothesizer（Phase 2） | "φ₁₅: hypothesis_error loops to hypothesizer" |
| `precondition_error_no_loopback` | φ₁₆ | Step 3: precondition_error → ループバックなし | "φ₁₆: precondition_error no loopback" |
| `loopback_budget_is_parameter` | φ₁₇ | Step 3: ループバック予算は T6 パラメータ（公理的導出なし） | "φ₁₇: loopback budget is parameter" |
| `untracked_forward_reference_violates_d3` | φ₁₁系 | Step 7: notes/deferred 整合性（D3 前提引用追跡） | "φ₁₁系: untracked_forward_reference_violates_d3" |
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

## Observable.lean — V1-V7 可観測性定理 逆引きチェックリスト（Run 74 追加）

Observable（可観測性）に関する定理群。P4/D3 の形式的裏付け。

| Lean 定理（Observable.lean） | SKILL.md での運用化 | 備考 | Gap |
|------------------------------|---------------------|------|-----|
| `measurable_threshold_observable` | P4: 各 Vi の閾値比較は Observable | D3 可観測性の形式的基盤 | なし |
| `all_variables_measurable` | P4: V1-V7 全変数が Measurable | D3 全変数観測可能の前提 | なし |
| `observable_and` | P4: Observable 性質の連言は Observable | system_health_observable の前提 | なし |
| `observable_not` | P4: Observable 性質の否定は Observable（Run 71） | degradation_detectable_observable の前提 | なし |
| `observable_or` | P4: Observable 性質の選言は Observable（Run 71） | Observable の完全ブール代数閉包 | なし |
| `system_health_observable` | P4: システム健全性は Observable（Run 27 で axiom→theorem） | V1-V7 全閾値比較の連言 | なし |
| `degradation_detectable_observable` | D3 条件 2: 劣化検出は Observable（Run 71） | system_health_observable の否定 | なし |
| `measurable_below_threshold_observable` | P4: 閾値未満比較も Observable（Run 71） | measurable_threshold_observable の dual | なし |

## DesignFoundation.lean 全定理 逆引きチェックリスト（Run 62 追加）

D1–D14 の設計基礎論定理を原則別に整理する。

### D1: 強制のレイヤリング原理

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d1_fixed_requires_structural` | L1 安全境界は構造的強制（Hook/deny）を必要とする | L1 は文書規範だけでは不十分 |
| `d1_enforcement_monotone` | 強制強度は単調増加（構造 ≥ 確率的 ≥ 文書） | 強制のレイヤリング順序 |
| `critical_requires_all_four` | critical リスクは 4 層全て必要 | Verifier 判定の理論的根拠 |
| `subagent_only_sufficient_for_low` | low リスクはサブエージェントで十分（φ₃） | Verifier リスク判定の補足 |
| `d2_from_e1` | E1（評価独立性）から D2（Worker/Verifier 分離）を導出 | P2 独立検証の形式的根拠 |

### D3: 可観測性先行

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d3_observability_precedes_improvement` | Step 1: Observer が最初（D3 先行条件） | φ₉ observability_first の根拠 |
| `d3_partial_observability_insufficient` | /metrics で V1–V7 全計測が必要 | 部分観測では改善不可 |
| `d3_full_observability_sufficient` | P4 ダッシュボードで全変数観測可能 → 改善条件充足 | D3 充足の形式的条件 |
| `d3_human_readable_insufficient` | 人間可読だけでは不十分（機械可読が必要） | メトリクス自動収集の根拠 |

### D4: 漸進的自己適用

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d4_no_self_dependency` | フェーズは自己依存を持たない（循環禁止） | D4 フェーズ順序の非循環性 |
| `d4_full_chain` | Phase 1→2→3→4→5 の完全チェーン存在 | full_cycle_exists の設計版 |
| `d4_phase_completion_persists` | フェーズ完了は後続フェーズで保持 | 前フェーズの結果は失われない |
| `developmentPhaseOrder_injective` | DevelopmentPhase の半順序は単射（Run 61） | 半順序型クラスの整合性 |
| `developmentPhase_le_refl` | DevelopmentPhase 反射律 | 半順序型クラスインスタンス |
| `developmentPhase_le_trans` | DevelopmentPhase 推移律 | 半順序型クラスインスタンス |
| `developmentPhase_le_antisymm` | DevelopmentPhase 反対称律 | 半順序型クラスインスタンス |
| `developmentPhase_lt_iff_le_not_le` | DevelopmentPhase 狭義順序定義 | 半順序型クラスインスタンス |
| `d4_d9_from_first_phase` | D4 フェーズ順序 + D9 自己適用は第 1 フェーズから成立 | D4×D9 の合成定理 |
| `dependency_d1_d2_d4_consistent` | D1/D2/D4 の三原則は矛盾なく共存 | 設計基礎論の整合性証明 |

### D5: 仕様・テスト・実装の三層対応

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d5_test_has_precision` | テストは仕様の精密化（精度 > 仕様） | 受け入れテストの役割 |
| `d5_layer_sequential` | spec → test → impl の線形順序 | 三層の依存方向 |
| `d5_structural_test_deterministic` | 構造テストは決定論的 | test-all.sh の理論的根拠 |
| `specLayerOrder_injective` | SpecLayer 半順序は単射（Run 61） | 半順序型クラスの整合性 |
| `specLayer_le_refl` | SpecLayer 反射律 | 半順序型クラスインスタンス |
| `specLayer_le_trans` | SpecLayer 推移律 | 半順序型クラスインスタンス |
| `specLayer_le_antisymm` | SpecLayer 反対称律 | 半順序型クラスインスタンス |
| `specLayer_lt_iff_le_not_le` | SpecLayer 狭義順序定義 | 半順序型クラスインスタンス |

### D6: 三段設計（境界→緩和策→変数）

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d6_fixed_boundary_mitigated` | L1 固定境界は緩和策で補完される | L1 + Hook の二層構造の根拠 |
| `d6_stage_sequential` | 境界→緩和策→変数の線形順序 | 設計段階の依存方向 |
| `d6_no_reverse` | 逆順の設計段階遷移は禁止 | 変数→緩和策→境界への後退不可 |
| `designStageOrder_injective` | DesignStage 半順序は単射（Run 61） | 半順序型クラスの整合性 |
| `designStage_le_refl` | DesignStage 反射律 | 半順序型クラスインスタンス |
| `designStage_le_trans` | DesignStage 推移律 | 半順序型クラスインスタンス |
| `designStage_le_antisymm` | DesignStage 反対称律 | 半順序型クラスインスタンス |
| `designStage_lt_iff_le_not_le` | DesignStage 狭義順序定義 | 半順序型クラスインスタンス |

### D7: 信頼の非対称性

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d7_accumulation_bounded` | 信頼蓄積は有界（上限 maxTrust） | 過信への警戒 |
| `d7_damage_unbounded` | 信頼毀損は無界（下限なし） | P2 独立検証を要する理由 |

### D8: 均衡探索

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d8_overexpansion_risk` | 過大拡張はリスクを高める | /adjust-action-space の根拠 |
| `d8_capability_risk` | 能力とリスクは共スケール（E2 の設計版） | 行動空間拡大時の注意 |

### D9: メンテナンス原理（自己適用）

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d9_update_classified` | 構造更新は互換性分類が必要（P3 hook） | コミットメッセージ分類の根拠 |
| `d9_self_applicable` | D9 自身も D9 の適用対象（自己参照） | /evolve スキル自体の更新にも適用 |
| `d9_all_principles_enumerated` | D1–D14 の原則が全て列挙されている | 設計基礎論の完全性 |

### D10: 構造永続性

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d10_agent_temporary_structure_permanent` | T1（一時エージェント）/ T2（永続構造）の設計版 | CLAUDE.md 最上位使命の形式化 |
| `d10_epoch_monotone` | エポック番号は単調増加 | breaking change 時の epoch bump |

### D11: コンテキスト経済

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d11_enforcement_cost_inverse` | 強制コストと有効性は逆相関 | 構造的強制が最も費用対効果高い |
| `d11_structural_minimizes_cost` | 構造的強制は最小コストで最大効果 | Hook 優先の根拠 |
| `d11_context_finite` | コンテキストウィンドウは有限（L4 の設計版） | SKILL.md の compact 設計根拠 |

### D12: 制約充足によるタスク設計

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d12_task_is_csp` | タスクは制約充足問題（CSP）として定式化可能 | /design-implementation-plan の根拠 |
| `d12_task_design_probabilistic` | タスク設計は確率的（P5 の設計版） | T4 非決定性の設計版 |

### D13: 前提否定の影響波及

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d13_coherence_implies_propagation` | 整合性のある前提否定は影響を波及させる | 退役処理が必要な理由 |
| `d13_retirement_requires_feedback` | 退役は必ずフィードバックを要する（Step 6） | 退役後の観察継続 |
| `d13_constraint_negation_has_impact` | 制約の否定は必ず影響を持つ | L1 変更禁止の理論的根拠 |
| `d13_l5_limited_impact` | L5（確率的解釈）は影響が限定的 | P5 の設計的位置づけ |
| `manifest_has_widest_impact` | manifest 変更は最も広い影響範囲を持つ | T0 変更禁止の形式的根拠 |
| `design_convention_has_impact` | 設計規約の変更も影響を持つ（非ゼロ） | CLAUDE.md 変更時の注意 |

### D14: 検証順序の制約充足性

| Lean 定理（DesignFoundation.lean） | SKILL.md での運用化 | 備考 |
|-----------------------------------|---------------------|------|
| `d14_verification_order_is_csp` | 検証順序は CSP として定式化可能（D4 フェーズ順序の充足性） | D4 フェーズ順序と D12 CSP の合成 |

## 逆方向マッピング: SKILL.md ステップ → Lean 定義名

SKILL.md の各ステップから、関連する Lean 定義・定理を逆引きするためのテーブル。
SKILL.md 変更時に影響する Lean 定義を即座に特定するために使用する。

| SKILL.md ステップ | 関連 Lean 定義名 | Lean ファイル |
|-------------------|-----------------|--------------|
| Step 0: 引き継ぎ条件 | `deferral_requires_justification`, `deferral_status_exhaustive`, `stasisUnhealthy` | EvolveSkill.lean, Evolution.lean |
| Step 1: Observer 起動 | `observability_first`, `validPhaseTransition` (observation→hypothesizing) | EvolveSkill.lean, Workflow.lean |
| Step 1.5: 観察結果永続化 | — (T2 永続性の運用化、直接対応する定理なし) | — |
| Step 2-3: Hypothesizer/Verifier ループ | `integration_requires_verification`, `evolve_no_verification_bypass`, `loopback_target_valid_transition`, `loopback_agent_determined` | Workflow.lean, EvolveSkill.lean |
| Step 2-3: FAIL 分析ループバック | `hypothesis_error_loops_to_hypothesizer`, `observation_error_loops_to_observer`, `precondition_error_no_loopback`, `loopback_budget_is_parameter` | EvolveSkill.lean |
| Step 3: Verifier リスク判定 | `evolve_verifier_sufficient_for_low`, `evolve_verifier_insufficient_for_moderate`, `evolve_verifier_insufficient_for_high`, `evolve_verifier_insufficient_for_critical` | EvolveSkill.lean |
| Step 4: 人間承認 + 統合ゲート | `integration_gate_structure`, `integrationGateCondition` | EvolveSkill.lean, Workflow.lean |
| Step 5: 互換性分類付きコミット | `CompatibilityClass.join`, `breaking_change_dominates`, `conservative_strategy_safe`, `breaking_change_propagates`, `breakingChangeRequiresEpochBump` | Evolution.lean, EvolveSkill.lean |
| Step 6: 退役処理 | `retirementCandidate`, `retirement_criteria_dual`, `formal_retirement_matches_workflow`, `retirement_only_after_integration` | Workflow.lean, EvolveSkill.lean |
| アーキテクチャ全体 | `all_phases_have_agents`, `all_agents_used`, `all_components_enumerated`, `evolve_skill_compliant` | EvolveSkill.lean |
| 仮説テーブル | `all_hypotheses_enumerated`, `hypothesis_count` | EvolveSkill.lean |
| D9 自己適用 | `isManifestStructure`, `governedTransition`, `manifest_persists_as_structure` | Evolution.lean |
| P4 可観測性基盤 | `measurable_threshold_observable`, `all_variables_measurable`, `observable_and`, `observable_not`, `observable_or`, `system_health_observable`, `degradation_detectable_observable`, `measurable_below_threshold_observable` | Observable.lean |
| P3 基底理論保護 | `manifest_contraction_forbidden'`, `manifest_revision_forbidden`, `non_manifest_all_ops_permitted`, `t0_contraction_forbidden` | Procedure.lean |
| D1 強制レイヤリング | `d1_fixed_requires_structural`, `d1_enforcement_monotone`, `critical_requires_all_four`, `subagent_only_sufficient_for_low`, `d2_from_e1` | DesignFoundation.lean |
| D3 可観測性先行 | `d3_observability_precedes_improvement`, `d3_full_observability_sufficient`, `d3_partial_observability_insufficient`, `d3_human_readable_insufficient` | DesignFoundation.lean |
| D4 フェーズ順序 | `d4_no_self_dependency`, `d4_full_chain`, `d4_phase_completion_persists`, `developmentPhase_le_refl`, `developmentPhase_le_trans`, `developmentPhase_le_antisymm`, `d4_d9_from_first_phase`, `dependency_d1_d2_d4_consistent` | DesignFoundation.lean |
| D5 三層対応 | `d5_test_has_precision`, `d5_layer_sequential`, `d5_structural_test_deterministic`, `specLayer_le_refl`, `specLayer_le_trans`, `specLayer_le_antisymm` | DesignFoundation.lean |
| D6 三段設計 | `d6_fixed_boundary_mitigated`, `d6_stage_sequential`, `d6_no_reverse`, `designStage_le_refl`, `designStage_le_trans`, `designStage_le_antisymm` | DesignFoundation.lean |
| D7-D9 信頼・均衡・保守 | `d7_accumulation_bounded`, `d7_damage_unbounded`, `d8_overexpansion_risk`, `d8_capability_risk`, `d9_update_classified`, `d9_self_applicable`, `d9_all_principles_enumerated` | DesignFoundation.lean |
| D10-D14 拡張原則 | `d10_agent_temporary_structure_permanent`, `d10_epoch_monotone`, `d11_structural_minimizes_cost`, `d12_task_is_csp`, `d13_coherence_implies_propagation`, `manifest_has_widest_impact`, `d14_verification_order_is_csp` | DesignFoundation.lean |

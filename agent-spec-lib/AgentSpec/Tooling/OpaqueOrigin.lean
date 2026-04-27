/-! # OpaqueOrigin — opaque def semantic origin registry (PI-13、Day 160 + Day 172 expansion)

`AgentSpec.Manifest.Ontology` の `opaque` 宣言は型上「存在のみ」を主張するが、
semantic 意図 (どの benchmark / どの measure / どの操作的定義) は docstring 依存で
Lean 側で構造的に追跡されない (構文/意味 × 対象/メタ 評価 弱点 #3)。

本 file は registry pattern で各 opaque def の semantic origin を **Lean 値として** 持つ。
Day 172 で initial 10 → 32 entry (Ontology の opaque 全件) に拡充。

## Registry schema

`(opaque_name : String) × (origin : String) × (description : String)`
-/

namespace AgentSpec.Tooling

/-- Opaque def の semantic origin registry (Day 172 完全版、32/32 entry)。 -/
def opaqueOriginRegistry : List (String × String × String) := [
  -- 識別子型 (5 件)
  ("AgentId", "Lean opaque (identity 型のみ、structure に bind)",
   "Agent の識別子。Agent.id field の型"),
  ("SessionId", "T1 (session_bounded) 由来の opaque",
   "Session の識別子。T1 で session 境界の identity を提供"),
  ("StructureId", "T2 (structure_persists) 由来の opaque",
   "Structure の識別子。永続知識単位の identity"),
  ("ProcessId", "Process scheduler 由来の opaque",
   "Process の識別子。processImproved 関数の domain"),
  ("ResourceId", "T7 (resource_finite) 由来の opaque",
   "Resource の識別子。globalResourceBound と組合せ"),
  -- 状態 / 関係 (8 件)
  ("WorldHash", "Lean Hashable instance 想定の opaque",
   "World の hash 値。状態同一性の identity"),
  ("ContextItem", "T3 (context_finite) 由来の opaque",
   "Context window 内の単位情報"),
  ("canTransition", "T4 (output_nondeterministic) 由来の opaque",
   "状態遷移可能性関係。validTransition の base"),
  ("generates", "P2 (cognitive separation) 由来の opaque",
   "Agent が action を生成する関係。verifies と対"),
  ("verifies", "P2 (cognitive separation) 由来の opaque",
   "Agent が action を verify する関係。generates と分離が必要"),
  ("sharesInternalState", "P2 / E1 由来の opaque",
   "2 agent が internal state を共有する関係。validSeparation の阻害条件"),
  ("interpretsStructure", "P5 (interpretation_nondeterminism) 由来の opaque",
   "Agent が structure を action に解釈する関係"),
  ("processImproved", "P3 (governed_learning) 由来の opaque",
   "Process が世界 w から w' に improve した関係"),
  -- 数値 metric (10 件)
  ("precisionContribution", "T8 (task_has_precision) 由来の opaque",
   "Context item の task に対する精度寄与度"),
  ("globalResourceBound", "T7 (resource_finite) 由来の opaque",
   "Global resource 上限値。executionDuration が share"),
  ("executionDuration", "T7 由来の opaque",
   "Task 実行時間。globalResourceBound 内に収まる必要"),
  ("actionSpaceSize", "L4 (action space) 由来の opaque",
   "Agent の世界に対する action space サイズ"),
  ("riskExposure", "E2 (capability_risk_coscaling) 由来の opaque",
   "Agent の risk 露出度。capability と co-scale"),
  ("worldOutput", "T4 (output_nondeterministic) 由来の opaque",
   "世界からの output 値"),
  ("trustLevel", "design judgment T6 (P1b unprotected_expansion_destroys_trust) 由来",
   "Agent への信頼度。投資行動の変動から間接観測"),
  ("trustIncrementBound", "P1b 由来の opaque (信頼漸進蓄積 bound)",
   "trustLevel の増加幅 bound。trust_accumulates_gradually で利用"),
  ("investmentLevel", "P1b (trust_drives_investment) 由来の opaque",
   "Resource 投資レベル。trust と co-scale"),
  ("collaborativeValue", "P1b (overexpansion_reduces_value) 由来の opaque",
   "Agent-human 協働価値。actionSpace 過拡張で減少しうる"),
  -- 命題 / 状態 (2 件)
  ("riskMaterialized", "E2 / P1b 由来の opaque",
   "Agent への risk が顕在化した状態。trust_decreases_on_materialized_risk で利用"),
  ("degradationLevel", "P4 設計 (P4b degradation_is_gradient) 由来",
   "system 劣化レベル。V1-V7 時間変化から計算"),
  -- V 系列 (V1-V7, 7 件)
  ("skillQuality", "benchmark.json GQM Q1 (with/without comparison)",
   "V1 スキル品質。skill 定義の精度・有効性"),
  ("contextEfficiency", "observe.sh proxy: recent_avg / cumulative_avg",
   "V2 context 効率。タスク完成率/消費 token"),
  ("outputQuality", "benchmark.json GQM Q1 + observe.sh test_pass_rate",
   "V3 出力品質。code/design/docs の品質"),
  ("gatePassRate", "tool-usage.jsonl: Bash passed / (passed + blocked)",
   "V4 gate 通過率。各フェーズ初回 gate clear"),
  ("proposalAccuracy", "v5-approvals.jsonl: approved / total",
   "V5 提案精度。設計提案の hit rate"),
  ("knowledgeStructureQuality", "memory_entries + last_update_days_ago + retired_count",
   "V6 知識構造の質。永続知識の構造化度"),
  ("taskDesignEfficiency", "v7-tasks.jsonl: completed + unique_subjects + teamwork_percent",
   "V7 タスク設計効率。完成率/リソース比")
]

/-- Registry に登録されている opaque 名一覧。 -/
def registeredOpaqueNames : List String :=
  opaqueOriginRegistry.map (·.1)

/-- 32 entry (Day 172: Ontology 全 opaque 完全 cover)。 -/
theorem registry_complete : opaqueOriginRegistry.length = 32 := by decide

end AgentSpec.Tooling

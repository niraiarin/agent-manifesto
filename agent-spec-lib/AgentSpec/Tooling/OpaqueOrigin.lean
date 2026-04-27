/-! # OpaqueOrigin — opaque def semantic origin registry (PI-13、Day 160)

`AgentSpec.Manifest.Ontology` の `opaque` 宣言は型上「存在のみ」を主張するが、
semantic 意図 (どの benchmark / どの measure / どの操作的定義) は docstring 依存で
Lean 側で構造的に追跡されない (構文/意味 × 対象/メタ 評価 弱点 #3)。

本 file は registry pattern で各 opaque def の semantic origin を **Lean 値として** 持つ。
将来 cycle-check Check 25 で「Ontology の全 opaque def が registry に entry を持つ」を
構造的に強制可能 (PI-13 follow-up)。

## Registry schema

`(opaque_name : String) × (origin : String) × (description : String)`

- opaque_name: Lean 識別子 (例 "skillQuality")
- origin: 意味付けの源 (例 "benchmark.json GQM Q1", "observe.sh proxy", "T6 design judgment")
- description: 1 文の意味的説明
-/

namespace AgentSpec.Tooling

/-- Opaque def の semantic origin registry。
    PI-13 (Day 148 plan): Ontology の opaque 32 件に semantic intent を Lean 構造で付与。
    現状 Day 160 では V 系列 7 件 + 主要 metric 3 件 = 10 件を初期登録。
    残 22 件は incremental に追加予定 (cycle-check Check 25 で警告)。

    将来拡張: registry を SkillRegistry (Day 126) と統合、`#print axioms` 連動で
    opaque 由来の trust delegation を可視化。 -/
def opaqueOriginRegistry : List (String × String × String) := [
  -- V 系列 (V1-V7)
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
   "V7 タスク設計効率。完成率/リソース比"),
  -- 主要 metric (3 件)
  ("trustLevel", "design judgment T6 (P1b unprotected_expansion_destroys_trust)",
   "agent への信頼度。投資行動の変動から間接観測"),
  ("degradationLevel", "P4 設計 (P4b degradation_is_gradient)",
   "system 劣化レベル。V1-V7 時間変化から計算"),
  ("riskExposure", "design judgment (E2 capability_risk_coscaling)",
   "agent の risk 露出度。capability と co-scale")
]

/-- Registry に登録されている opaque 名一覧 (cycle-check Check 25 候補)。 -/
def registeredOpaqueNames : List String :=
  opaqueOriginRegistry.map (·.1)

end AgentSpec.Tooling

import AgentSpec.Tooling.MeasurableSemantic
import AgentSpec.Manifest.Ontology

/-! # V1-V7 MeasurableSemantic instances (PI-12 follow-up、Day 184)

PI-12 (Day 159) で導入した `MeasurableSemantic` typeclass を V1-V7 に適用。
各 V には named axiom として MeasurementProcedure を declare、`#print axioms` で
attestation 由来を追跡可能化 (PI-13 OpaqueOrigin registry と整合)。

これで Day 159 の design intent (syntactic Measurable vs semantic claim を typeclass で分離)
が、V1-V7 全件で realize される。

## attestation source mapping (OpaqueOrigin と一致)

| V | axiom name | attestation source |
|---|---|---|
| V1 | skillQuality_measurement_procedure | benchmark.json GQM Q1 |
| V2 | contextEfficiency_measurement_procedure | observe.sh proxy |
| V3 | outputQuality_measurement_procedure | benchmark.json GQM Q1 + test_pass_rate |
| V4 | gatePassRate_measurement_procedure | tool-usage.jsonl |
| V5 | proposalAccuracy_measurement_procedure | v5-approvals.jsonl |
| V6 | knowledgeStructureQuality_measurement_procedure | memory_entries 系 |
| V7 | taskDesignEfficiency_measurement_procedure | v7-tasks.jsonl |

各 axiom は operational layer の measurement procedure 存在を Lean レベルで commitment。
-/

namespace AgentSpec.Tooling

open AgentSpec.Manifest

/-- V1 (skillQuality) measurement procedure: benchmark.json GQM Q1 (with/without comparison)。 -/
axiom skillQuality_measurement_procedure : MeasurementProcedure skillQuality

instance : MeasurableSemantic skillQuality := ⟨skillQuality_measurement_procedure⟩

/-- V2 (contextEfficiency) measurement procedure: observe.sh proxy (recent_avg / cumulative_avg)。 -/
axiom contextEfficiency_measurement_procedure : MeasurementProcedure contextEfficiency

instance : MeasurableSemantic contextEfficiency := ⟨contextEfficiency_measurement_procedure⟩

/-- V3 (outputQuality) measurement procedure: benchmark.json GQM Q1 + observe.sh test_pass_rate。 -/
axiom outputQuality_measurement_procedure : MeasurementProcedure outputQuality

instance : MeasurableSemantic outputQuality := ⟨outputQuality_measurement_procedure⟩

/-- V4 (gatePassRate) measurement procedure: tool-usage.jsonl (Bash passed / passed+blocked)。 -/
axiom gatePassRate_measurement_procedure : MeasurementProcedure gatePassRate

instance : MeasurableSemantic gatePassRate := ⟨gatePassRate_measurement_procedure⟩

/-- V5 (proposalAccuracy) measurement procedure: v5-approvals.jsonl (approved / total)。 -/
axiom proposalAccuracy_measurement_procedure : MeasurementProcedure proposalAccuracy

instance : MeasurableSemantic proposalAccuracy := ⟨proposalAccuracy_measurement_procedure⟩

/-- V6 (knowledgeStructureQuality) measurement procedure: memory_entries + last_update + retired_count。 -/
axiom knowledgeStructureQuality_measurement_procedure : MeasurementProcedure knowledgeStructureQuality

instance : MeasurableSemantic knowledgeStructureQuality := ⟨knowledgeStructureQuality_measurement_procedure⟩

/-- V7 (taskDesignEfficiency) measurement procedure: v7-tasks.jsonl (completed + unique_subjects + teamwork)。 -/
axiom taskDesignEfficiency_measurement_procedure : MeasurementProcedure taskDesignEfficiency

instance : MeasurableSemantic taskDesignEfficiency := ⟨taskDesignEfficiency_measurement_procedure⟩

end AgentSpec.Tooling

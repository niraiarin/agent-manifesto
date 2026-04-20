# Domain Context: V1-V7 Metrics Interpretation

This document provides the domain knowledge needed to interpret agent-manifesto V1-V7 metrics.
Both Cloud and Local LLMs receive this identical context.

## V1-V7 Definitions

| V | Name | What it measures | Data source |
|---|------|-----------------|-------------|
| V1 | Skill Quality | Quality of structural improvements (theorems added, tests added, axiom changes) | evolve-history.jsonl |
| V2 | Context Efficiency | Tool calls per session (lower = more efficient) | tool-usage.jsonl |
| V3 | Output Quality | Test pass rate + hallucination proxy (judge rejection patterns) | git commits + evolve-history.jsonl |
| V4 | Gate Pass Rate | % of tool calls that pass safety/permission gates | tool-usage.jsonl hook exit codes |
| V5 | Proposal Accuracy | % of proposals approved by human | v5-approvals.jsonl |
| V6 | Knowledge Structure | Memory entries, staleness, type distribution, consistency | MEMORY.md filesystem |
| V7 | Task Design | Task completion count, unique subjects, teamwork % | v7-tasks.jsonl |

## V1 Non-Triviality Gate

V1 includes a "non_triviality" sub-metric that prevents trivial optimizations from counting as improvements.
It has 4 conditions (all must be > 0 for non-trivial):

- **C1 (theorem_growth)**: New theorems added in this evolve run
- **C2 (test_growth)**: New tests added in this evolve run
- **C3 (axiom_change)**: Axiom modifications (additions/removals)
- **C4 (multi_verification)**: Multiple independent verifications passed

score=0 with label="trivial" means the last evolve run made no structural improvements.
`saturation.consecutive_zero_delta` counts how many consecutive runs had zero growth.

## V1 Proxy Maturity

V1 and V3 have a "proxy_classification" field:
- **provisional**: Measurement method is still being validated
- **established**: Measurement method validated but not formally proven
- **formal**: Measurement method has Lean formal proofs (graduation achieved)

## V3 Hallucination Proxy

V3 tracks judge rejection patterns as a proxy for hallucination/error rates:

| Type | Meaning |
|------|---------|
| observation_error | Observer reported incorrect facts |
| hypothesis_error | Hypothesizer proposed invalid improvements |
| assumption_error | Incorrect assumptions in proposals |
| precondition_error | Missing prerequisites |

`_post_gate` variants count errors that survived the quality gate (more concerning).
Subtypes: `H_wrong_premise` (wrong starting assumption), `H_impl_specification` (misread implementation spec).

## Key Tradeoffs

- V1 (quality) ↔ V2 (efficiency): Higher quality requires more context = more tool calls
- V6 (knowledge) ↔ V2 (efficiency): More memory lookups cost tokens
- V5 (accuracy) ↔ V2 (efficiency): Careful proposals require more computation

## System Health Assessment

- **HEALTHY**: All V1-V7 meet minimum thresholds, no saturation detected
- **WARNING**: One or more V shows degradation or non_triviality=0 (trivial)
- **DEGRADED**: Multiple V failing thresholds or sustained saturation

## Key Project Terminology

- **P3 (Governed Learning)**: Knowledge integration lifecycle: Observe -> Hypothesize -> Verify -> Integrate -> Retire
- **P4 (Observability)**: System must be measurable; improvements must be backed by metrics
- **D4 (Phase Ordering)**: Safety (L1) -> Verification (P2) -> Observability (P4) -> Governance (P3) -> Dynamic adjustment
- **D13 (Impact Propagation)**: Changes propagate through dependency chains; downstream effects must be assessed
- **evolve**: The incremental improvement process that produces evolve-history.jsonl entries
- **judge**: Independent quality evaluator that scores improvements against GQM criteria
- **Goodhart vulnerability**: V4 and V7 are vulnerable to gaming (optimizing the metric without real improvement)
- **retired_count**: Number of obsolete memory entries removed (P3 retirement phase)

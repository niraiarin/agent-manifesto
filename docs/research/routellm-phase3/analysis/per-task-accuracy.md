# Per-task Accuracy Breakdown (#653 Phase 5)

Eval n=150. Tasks with coverage: 40.

## Per-task results

| Task | Label | n_eval | n_train | Accuracy | Routing acc | Mean conf |
|------|-------|--------|---------|----------|-------------|-----------|
| helpsteer3-code | hybrid | 40 | 110 | 1.000 | 1.000 | 0.997 |
| model-questioner | local_probable | 11 | 24 | 0.818 | 1.000 | 0.873 |
| paperize-writing | local_probable | 10 | 30 | 1.000 | 1.000 | 0.847 |
| trace-interp | local_probable | 9 | 41 | 1.000 | 1.000 | 0.941 |
| metrics-interp | local_probable | 7 | 33 | 1.000 | 1.000 | 0.972 |
| adjust-action-space | local_probable | 4 | 26 | 1.000 | 1.000 | 0.957 |
| formal-derivation | cloud_required | 4 | 16 | 1.000 | 1.000 | 0.916 |
| observer-v1v7 | local_probable | 4 | 31 | 1.000 | 1.000 | 0.744 |
| ood-riddle | unknown | 4 | 1 | 1.000 | 1.000 | 0.903 |
| evolve-orchestration | cloud_required | 3 | 7 | 1.000 | 1.000 | 0.570 |
| summarize | local_confident | 3 | 12 | 1.000 | 1.000 | 0.938 |
| verifier-review | cloud_required | 3 | 12 | 1.000 | 1.000 | 0.675 |
| code-generation | cloud_required | 3 | 12 | 1.000 | 1.000 | 0.794 |
| ood-sports | unknown | 3 | 2 | 1.000 | 1.000 | 0.943 |
| handoff | local_confident | 3 | 12 | 1.000 | 1.000 | 0.829 |
| research-workflow | cloud_required | 3 | 7 | 1.000 | 1.000 | 0.890 |
| paperize-litreview | local_confident | 2 | 13 | 1.000 | 1.000 | 1.000 |
| judge | hybrid | 2 | 13 | 1.000 | 1.000 | 0.574 |
| qa-free | hybrid | 2 | 23 | 1.000 | 1.000 | 0.916 |
| observer | local_probable | 2 | 3 | 1.000 | 1.000 | 0.971 |
| trace-interp-long | local_probable | 2 | 3 | 1.000 | 1.000 | 0.806 |
| schema-inference | local_confident | 2 | 13 | 1.000 | 1.000 | 0.918 |
| ood-finance | unknown | 2 | 3 | 1.000 | 1.000 | 0.840 |
| verify | cloud_required | 2 | 3 | 1.000 | 1.000 | 0.557 |
| integrator | cloud_required | 2 | 8 | 1.000 | 1.000 | 0.773 |
| ood-emoji | unknown | 2 | 3 | 1.000 | 1.000 | 0.928 |
| ood-pet | unknown | 2 | 3 | 1.000 | 1.000 | 1.000 |
| ood-gibberish | unknown | 2 | 3 | 0.000 | 1.000 | 0.746 |
| verifier-local | local_confident | 1 | 14 | 1.000 | 1.000 | 0.967 |
| qa | hybrid | 1 | 4 | 0.000 | 0.000 | 0.550 |
| ood-personal | unknown | 1 | 4 | 1.000 | 1.000 | 0.840 |
| ood-single-word | unknown | 1 | 4 | 1.000 | 1.000 | 0.731 |
| ood-health | unknown | 1 | 4 | 1.000 | 1.000 | 1.000 |
| ood-politics | unknown | 1 | 4 | 1.000 | 1.000 | 1.000 |
| ground-axiom | cloud_required | 1 | 9 | 1.000 | 1.000 | 0.967 |
| ood-fiction | unknown | 1 | 4 | 1.000 | 1.000 | 1.000 |
| ood-cooking | unknown | 1 | 4 | 1.000 | 1.000 | 0.898 |
| verify-skill | cloud_required | 1 | 9 | 1.000 | 1.000 | 0.798 |
| ood-weather | unknown | 1 | 4 | 1.000 | 1.000 | 0.684 |
| ood-music | unknown | 1 | 4 | 1.000 | 1.000 | 1.000 |

## Weak tasks (routing acc < 0.80)

なし。全 task で routing_acc ≥ 0.80.

## Coverage gap

- Train only (no eval coverage): 9 tasks
  - hypothesizer, ood-gardening, ood-math-basic, ood-philosophy, ood-random, ood-smalltalk, ood-travel, paperize-outline, tool-selection
- Eval only (no train coverage): 0 tasks

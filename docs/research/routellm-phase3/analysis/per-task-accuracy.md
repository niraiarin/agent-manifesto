# Per-task Accuracy Breakdown (#653 Phase 5)

Eval n=147. Tasks with coverage: 41.

## Per-task results

| Task | Label | n_eval | n_train | Accuracy | Routing acc | Mean conf |
|------|-------|--------|---------|----------|-------------|-----------|
| helpsteer3-code | hybrid | 37 | 109 | 1.000 | 1.000 | 0.990 |
| paperize-writing | local_probable | 9 | 31 | 1.000 | 1.000 | 0.896 |
| trace-interp | local_probable | 6 | 34 | 0.667 | 0.667 | 0.772 |
| verifier-review | cloud_required | 6 | 9 | 1.000 | 1.000 | 0.657 |
| metrics-interp | local_probable | 6 | 34 | 1.000 | 1.000 | 0.961 |
| research-workflow | cloud_required | 5 | 5 | 1.000 | 1.000 | 0.681 |
| paperize-outline | local_confident | 5 | 10 | 1.000 | 1.000 | 0.976 |
| code-generation | cloud_required | 5 | 10 | 1.000 | 1.000 | 0.740 |
| adjust-action-space | local_probable | 5 | 25 | 1.000 | 1.000 | 0.906 |
| qa-free | hybrid | 4 | 21 | 1.000 | 1.000 | 0.880 |
| verify-skill | cloud_required | 4 | 6 | 1.000 | 1.000 | 0.726 |
| model-questioner | local_probable | 4 | 31 | 1.000 | 1.000 | 0.944 |
| paperize-litreview | local_confident | 3 | 12 | 1.000 | 1.000 | 0.912 |
| summarize | local_confident | 3 | 12 | 1.000 | 1.000 | 0.812 |
| ground-axiom | cloud_required | 3 | 7 | 1.000 | 1.000 | 0.842 |
| observer-v1v7 | local_probable | 3 | 32 | 1.000 | 1.000 | 0.967 |
| formal-derivation | cloud_required | 3 | 17 | 1.000 | 1.000 | 0.984 |
| ood-sports | unknown | 2 | 3 | 1.000 | 1.000 | 0.974 |
| ood-gardening | unknown | 2 | 3 | 1.000 | 1.000 | 0.958 |
| observer | local_probable | 2 | 3 | 1.000 | 1.000 | 0.783 |
| hypothesizer | cloud_required | 2 | 8 | 1.000 | 1.000 | 0.802 |
| ood-pet | unknown | 2 | 3 | 1.000 | 1.000 | 0.988 |
| evolve-orchestration | cloud_required | 2 | 8 | 1.000 | 1.000 | 0.986 |
| ood-health | unknown | 2 | 3 | 1.000 | 1.000 | 1.000 |
| ood-emoji | unknown | 2 | 3 | 1.000 | 1.000 | 0.988 |
| verifier-local | local_confident | 2 | 13 | 1.000 | 1.000 | 0.989 |
| verify | cloud_required | 2 | 3 | 1.000 | 1.000 | 0.792 |
| ood-gibberish | unknown | 2 | 3 | 0.000 | 1.000 | 0.681 |
| ood-math-basic | unknown | 2 | 3 | 1.000 | 1.000 | 0.942 |
| tool-selection | cloud_required | 1 | 9 | 1.000 | 1.000 | 1.000 |
| ood-personal | unknown | 1 | 4 | 1.000 | 1.000 | 1.000 |
| ood-finance | unknown | 1 | 4 | 1.000 | 1.000 | 1.000 |
| judge | hybrid | 1 | 14 | 0.000 | 0.000 | 0.576 |
| ood-random | unknown | 1 | 4 | 1.000 | 1.000 | 1.000 |
| ood-smalltalk | unknown | 1 | 4 | 1.000 | 1.000 | 0.796 |
| schema-inference | local_confident | 1 | 14 | 1.000 | 1.000 | 0.989 |
| qa | hybrid | 1 | 4 | 1.000 | 1.000 | 0.405 |
| handoff | local_confident | 1 | 14 | 1.000 | 1.000 | 0.856 |
| ood-music | unknown | 1 | 4 | 1.000 | 1.000 | 1.000 |
| ood-cooking | unknown | 1 | 4 | 1.000 | 1.000 | 0.956 |
| ood-riddle | unknown | 1 | 4 | 1.000 | 1.000 | 0.988 |

## Weak tasks (routing acc < 0.80)

- **trace-interp**: routing_acc=0.667, n_eval=6, n_train=34 — may need more training variants

## Coverage gap

- Train only (no eval coverage): 7 tasks
  - integrator, ood-fiction, ood-philosophy, ood-politics, ood-single-word, ood-travel, ood-weather
- Eval only (no train coverage): 0 tasks

# GT Label Guide

This guide is the fallback taxonomy reference for GT labeling packets used in Issue #671.

## Labels

### `local_confident`

Choose this when the task is narrow, self-contained, and should complete reliably in the local environment without orchestration or deep external reasoning.

### `local_probable`

Choose this when the task is still likely local, but uncertainty remains because the prompt is moderately open-ended, context-heavy, or could require limited judgment.

### `cloud_required`

Choose this when the task needs deeper reasoning, multi-step orchestration, broader context synthesis, or stronger model capability than the local path should handle.

### `hybrid`

Choose this when the task mixes local execution with stronger remote reasoning, or when routing may depend on decomposition between local tool work and cloud reasoning.

### `unknown`

Choose this when the prompt is out-of-distribution, underspecified, unsafe to classify confidently, or does not map cleanly onto the known routing taxonomy.

## Decision Heuristics

1. Prefer the narrowest label that still preserves safety.
2. If a wrong local route would create material risk, bias toward `cloud_required` or `hybrid`.
3. Use `unknown` instead of forcing a weak fit.
4. Keep `annotator_notes` short and factual. Record the uncertainty source, not a long essay.
5. Do not use predicted labels as ground truth. They are hints only.

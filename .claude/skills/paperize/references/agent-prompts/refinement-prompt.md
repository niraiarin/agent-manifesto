# Refinement Prompt — Phase 4 (LLM + Verifier)

Source: [S2 §2.5] PaperOrchestra AgentReview + PR #637 logprob pairwise

## Loop

```
for iter in 1..max_iterations:
  A = current paper.tex
  B = llm_revise(A, critique_prompt)
  verdict = verifier.compare(A, B, criteria)   # scripts/verifier-refinement.py
  if verdict.winner == "A" and verdict.margin > 0:
    accept B → continue
  elif verdict.winner == "B":
    halt → record refinement-rejected.md, keep A
  else:  # margin <= 0
    halt → keep A (no net improvement)
```

## critique_prompt

Focus on (in decreasing priority):
1. Unsupported numeric claims (see `anti-hallucination-rules.md:R5`)
2. Missing `[UNVERIFIED]` tags where `evaluator_independent=null`
3. Internal citation hash presence
4. Page budget compliance (max_pages)
5. Section coherence

Do NOT:
- Introduce new experiments
- Speculate about future work in the body (use `todos.md:questions` instead)
- Inflate section count

## Verifier criteria (3 axes)

- **factual_grounding**: claims supported by `manifest.json` / `evidence/`
- **citation_integrity**: internal hashes present, external citations in config
- **narrative_coherence**: section ordering, logical flow

Verifier returns `{winner, margin, criterion_breakdown}`.

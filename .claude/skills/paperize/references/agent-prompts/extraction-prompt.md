# Extraction Prompt — Phase 2 (LLM)

Source: [S2 §3.4] PaperOrchestra Aggregator Phase 2

## Input

- `$OUT/manifest.json` (aggregate-jsonl.sh output)
- `$OUT/evidence/commits.md`
- `$OUT/evidence/sources.md`

## Output

- `$OUT/idea.md`
- `$OUT/experimental_log.md`

## Instructions

Read `manifest.json` and group verifications by `source` field. Each group is
a candidate "experimental thread".

For each thread, write a paragraph in `experimental_log.md` covering:
1. **What was verified** (derived from files + verdict)
2. **When** (timestamp range)
3. **Outcome** (verdict, margin if present)
4. **Supporting commits** (match by date to `manifest.json:commits`)

If `evaluator_independent` is null or false for a verification, tag the
corresponding narrative with `[UNVERIFIED]`. See `anti-hallucination-rules.md:R1`.

### idea.md

Synthesize threads into 1-3 "research ideas" at a higher abstraction level.
Each idea must:
- Reference at least one thread from `experimental_log.md`
- State the hypothesis being tested
- Cite internal commits with 8-char SHA (see `anti-hallucination-rules.md:R2`)

### Synthesis constraints (Phase 3)

- Merge redundant verifications (same files, same day, same verdict) into one record
- Split distinct projects (if file sets are disjoint across threads, treat as separate ideas)
- Preserve `[UNVERIFIED]` tags through merges

## Page budget hint

Extraction output (idea.md + experimental_log.md combined) should fit within
~3000 words. This bounds downstream writing agent.

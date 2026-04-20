# Outline Prompt — Phase 3 Outline Agent

Source: [S2 §2.1] PaperOrchestra Outline Agent

## Input

- `$OUT/idea.md`
- `$OUT/experimental_log.md`
- `paperize.yaml:paper.max_pages`

## Output

- `$OUT/outline.json` conforming to `references/schemas/outline.schema.json`

## Instructions

Produce an outline with:
- `title` (≤ 80 chars)
- `sections[]`: each with `heading`, `purpose` (1 sentence), `key_claims[]`, `supporting_evidence[]` (references to `experimental_log.md` / `manifest.json:verifications`)
- Budget ~= max_pages × 500 words/page

Prefer 5 sections (internal-report template):
1. Motivation
2. Method
3. Experiments
4. Findings
5. Limitations + follow-up

Do NOT introduce claims not grounded in `experimental_log.md`.

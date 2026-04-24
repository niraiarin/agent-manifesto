# Internal Research Report Guidelines

Source: [P] internal convention.

## Structure (5 sections)

1. **Motivation** — why the research was needed, what question it answers
2. **Method** — experimental setup, verifier model, K-rounds, criteria
3. **Experiments** — what was tested, with counts + evidence pointers
4. **Findings** — numeric results, claims (all supported by `manifest.json`)
5. **Limitations and Follow-up** — open questions → link to `todos.md`

## Length

- Default: ≤ 8 pages (paperize.yaml:paper.max_pages)
- Abstract: ≤ 200 words
- Each main section: ≤ 2 pages

## Citation style

### Internal (primary)

- Commit: `(commit \texttt{9159f62c})`
- PR: `(PR \#637)`
- Issue: `(issue \#642)`
- Verification token: `(p2-verified.jsonl:epoch=1776663606)`

### External (optional)

Pre-declare in `paperize.yaml:input.external_citations:`. The LLM must NOT
generate new URLs.

## Figures

- Numeric: matplotlib → `figures/*.pdf` (vector)
- Tables: LaTeX `booktabs`, no vertical lines
- Place figures near first reference, not at end

## Tone

- Internal report, not a conference submission
- First-person plural ("we observed") allowed
- Claim every numeric result with source reference (anti-hallucination R5)

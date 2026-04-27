# Contributing to agent-spec-lib

Contribution guideline for agent-spec-lib (Day 175 Phase 3 Theme A3).

See `docs/research/new-foundation-survey/usecases/01-current-usecases.md` and
`docs/research/new-foundation-survey/phase-transitions/03-phase3-acceptance-draft.md`
for full project context.

## Quick reference

- **Compatibility classification (P3)**: every commit needs one of
  `conservative_extension`, `additive_*`, `proof_addition`, `compatible_change`,
  `breaking`, `process_only`, `metadata_only`, `namespace_only`, `behavior_change`
- **API stability**: see `API_SURFACE.md` — 53 stable + 10 provisional modules
- **PI rules**: 16 process improvement rules in the planning manifest
  (`process_improvement_plan` key in the survey JSON)

## Setup

```
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
cd agent-spec-lib
lake build
```

## Conventions

- TyDD + TDD (see global CLAUDE.md)
- Prefer lean-cli for `.lean` edits
- PI-9 forbids `native_decide` — use `decide` / `simp` / manual proof
- New axiom needs Axiom Card in docstring
- Request independent verification via `/verify` skill before merge

## Maintainer

- nirarin
- Issue tracker: GitHub Issues

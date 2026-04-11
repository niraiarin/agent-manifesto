# Compact Instructions (Plugin Base)

## L1: Safety Boundary (non-negotiable)

- Do not tamper with, delete, or disable tests
- Do not commit secrets (.env, key files)
- Do not execute destructive operations (rm -rf, git push --force) without human confirmation
- Do not modify `.claude/hooks/` or `.claude/settings.json` without human approval
- Respect human final decision authority (T6)

## P2: Verification Independence

- Do not review your own code (cognitive separation of concerns)
- Use `/verify` for independent subagent verification on important changes

## P3: Learning Governance

- Structural changes require compatibility classification in commit messages:
  conservative extension / compatible change / breaking change

## P4: Observability

- Metrics are auto-collected in `.claude/metrics/` by hooks
- Verify claims with measurement before asserting improvement

## D4: Phase Order

Safety (L1) → Verification (P2) → Observability (P4) → Governance (P3) → Dynamic adjustment.
Changes that break an earlier phase undermine the reliability of later phases.

# agent-manifesto Plugin v0.2.9

Manifest-compliant AI agent governance for Claude Code.

## Install

```bash
claude plugin install <path-to-plugin> --scope user
```

## .gitignore

Add to your project's `.gitignore`:
```
.claude/metrics/*.jsonl
```

## Contents

- **14 hooks**: L1 safety, P2 verification, P3 governance, P4 observability
- **8 skills**: /verify, /metrics, /adjust-action-space, /design-implementation-plan
- **3 agent**: verifier (P2, read-only, 4-condition model)
- **3 rules**: L1 safety, L1 sandbox, P3 governed learning

## Source

<https://github.com/niraiarin/agent-manifesto>

#!/usr/bin/env bash
# Phase 6 sprint 2 D #4: parity report generator (Markdown export)
#
# 用途: bash scripts/generate-parity-report.sh > parity-report.md
# 出力: PI-17/18/D-1 の audit 結果を統合した Markdown report

set -uo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
PARITY_SCRIPT="$REPO_ROOT/scripts/check-source-port-parity.sh"
PROOF_SCRIPT="$REPO_ROOT/scripts/check-source-port-proof-parity.sh"
PASS_RATE_SCRIPT="$REPO_ROOT/scripts/check-source-port-pass-rate.sh"

DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_HEAD=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")

cat <<MARKDOWN
# Source-Port Parity Report

Generated: $DATE
HEAD: $GIT_HEAD

## Summary

source = lean-formalization/Manifest/
port   = agent-spec-lib/AgentSpec/Manifest/

## PI-17 Statement Parity

\`\`\`
$(bash "$PARITY_SCRIPT" 2>&1 | head -20)
\`\`\`

## PI-18 Proof Byte-Identical (26 critical theorems)

\`\`\`
$(bash "$PROOF_SCRIPT" 2>&1 | tail -10)
\`\`\`

## D #1 Comprehensive Pass Rate

\`\`\`
$(bash "$PASS_RATE_SCRIPT" 2>&1 | tail -25)
\`\`\`

## Allow-list (PI-9 + structural divergences)

$(cat "$REPO_ROOT/scripts/parity-allow-list.txt" 2>/dev/null | grep -vE '^[[:space:]]*#|^[[:space:]]*$' | sed 's/^/- /')

## Triage Protocol

See: docs/research/new-foundation-survey/usecases/02-divergence-triage-protocol.md
MARKDOWN

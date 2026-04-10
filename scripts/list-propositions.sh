#!/usr/bin/env bash
# list-propositions.sh — Ontology.lean から全 PropositionId を動的抽出
# Single Source of Truth: lean-formalization/Manifest/Ontology.lean
# 出力: スペース区切りの命題 ID リスト (例: T1 T2 ... V7)
set -uo pipefail

BASE="$(git rev-parse --show-toplevel 2>/dev/null || echo /Users/nirarin/work/agent-manifesto)"
ONTOLOGY="$BASE/lean-formalization/Manifest/Ontology.lean"

if [ ! -f "$ONTOLOGY" ]; then
  echo "ERROR: Ontology.lean not found" >&2
  exit 1
fi

# inductive PropositionId where から deriving までの構築子のみを抽出
# パターン: `| t1 | t2 ...` の行から `[teplvd][0-9]+` にマッチするものだけ
awk '/^inductive PropositionId where/,/deriving/' "$ONTOLOGY" \
  | grep -o '[teplvd][0-9]\{1,2\}' \
  | tr '[:lower:]' '[:upper:]' \
  | sort -u -V \
  | tr '\n' ' ' \
  | sed 's/ $//'
echo ""

#!/usr/bin/env bash
# generate-assumptions-lean.sh
#
# assumptions-only ModelSpec JSON から Lean Assumptions 定義を生成する専用スクリプト。
# generate-conditional-axiom-system.sh の補完スクリプト（g5-f3 解消）。
#
# 使用法:
#   bash generate-assumptions-lean.sh -f input.json -n Namespace -o output.lean
#   cat input.json | bash generate-assumptions-lean.sh -n Namespace -o output.lean
#
# 入力: assumptions-only ModelSpec JSON（layers/propositions/assignments 不要）
# {
#   "projectName": "MyProject",
#   "assumptions": [
#     {"id": "C1", "type": "C", "question": "q-id", "date": "2026-01-01",
#      "content": "説明テキスト", "sourceRef": "path/or/url", "reviewInterval": 90},
#     {"id": "H1", "type": "H", "basis": ["C1"], "refutation": "反証条件",
#      "content": "説明テキスト", "sourceRef": "path/or/url", "reviewInterval": 60}
#   ]
# }
#
# 引数:
#   -f input.json    入力ファイル（省略時は stdin）
#   -n Namespace     Lean namespace（省略時は projectName から PascalCase 変換）
#   -o output.lean   出力ファイル（省略時は stdout）
#
# 既存参照:
#   lean-formalization/Manifest/Models/Instances/ForgeCode/Assumptions.lean
#   lean-formalization/Manifest/Models/Instances/ClaudeCode/Assumptions.lean
#   lean-formalization/Manifest/Models/Assumptions/EpistemicLayer.lean
#
# @traces P3, T2, D9
#
# Traceability:
#   T2: 生成した Lean ファイルを永続構造（git 管理）に書き込むことで構造永続性を実現する
#   P3: assumptions-only JSON からの Lean 変換は観察→仮説化→検証サイクルの統合フェーズを支援する
#   D9: このスクリプト自身も /evolve による改善対象であり、自己適用可能な設計とする

set -euo pipefail

# --- 引数解析 ---
INPUT_FILE=""
NAMESPACE_ARG=""
OUTPUT_FILE=""

while getopts "f:n:o:" opt; do
  case "$opt" in
    f) INPUT_FILE="$OPTARG" ;;
    n) NAMESPACE_ARG="$OPTARG" ;;
    o) OUTPUT_FILE="$OPTARG" ;;
    *) echo "Usage: $0 [-f input.json] [-n Namespace] [-o output.lean]" >&2; exit 1 ;;
  esac
done

# --- 入力読み込み ---
if [ -n "$INPUT_FILE" ]; then
  if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: input file not found: $INPUT_FILE" >&2
    exit 1
  fi
  JSON=$(cat "$INPUT_FILE")
else
  JSON=$(cat)
fi

# --- JSON 検証: assumptions フィールドが存在し配列であること ---
ASSUMPTIONS_TYPE=$(echo "$JSON" | jq -r 'if .assumptions == null then "null" elif (.assumptions | type) != "array" then "non-array" else "array" end' 2>/dev/null || echo "parse-error")

if [ "$ASSUMPTIONS_TYPE" = "null" ]; then
  echo "Error: 'assumptions' field is null or missing" >&2
  exit 1
fi
if [ "$ASSUMPTIONS_TYPE" = "non-array" ]; then
  echo "Error: 'assumptions' field is not an array" >&2
  exit 1
fi
if [ "$ASSUMPTIONS_TYPE" = "parse-error" ]; then
  echo "Error: failed to parse JSON input" >&2
  exit 1
fi

ASSUMPTIONS_COUNT=$(echo "$JSON" | jq '.assumptions | length')
if [ "$ASSUMPTIONS_COUNT" -eq 0 ]; then
  echo "Error: 'assumptions' array is empty" >&2
  exit 1
fi

# --- Namespace 決定 ---
if [ -n "$NAMESPACE_ARG" ]; then
  NAMESPACE="$NAMESPACE_ARG"
else
  PROJECT_NAME=$(echo "$JSON" | jq -r '.projectName // "Unknown"')
  # PascalCase 変換: 単語境界でキャピタライズ、記号除去
  NAMESPACE=$(echo "$PROJECT_NAME" | awk '{
    n = split($0, words, /[-_ ]/);
    result = "";
    for (i=1; i<=n; i++) {
      w = words[i];
      if (length(w) > 0) {
        result = result toupper(substr(w,1,1)) substr(w,2);
      }
    }
    print result
  }')
fi

# --- Lean 識別子変換関数（bash 内で使用）---
# 入力: "CC-C1" → 出力: "cc_c1"
to_lean_id() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr '-' '_' | tr ' ' '_'
}

# --- Lean ファイル生成 ---
generate_lean() {
  local project_name
  project_name=$(echo "$JSON" | jq -r '.projectName // "Unknown"')

  cat <<LEAN_HEADER
import Manifest.Models.Assumptions.EpistemicLayer

/-!
# ${NAMESPACE} Conditional Design Foundation - Assumptions

条件付き公理系 S=(A,C,H,D) の ${NAMESPACE} インスタンスにおける仮定を定義する。

自動生成: generate-assumptions-lean.sh
ソース: ${INPUT_FILE:-stdin}
-/

namespace Manifest.Models.Instances.${NAMESPACE}

open Manifest
open Manifest.Models.Assumptions

-- ============================================================
-- C: 人間の設計判断
-- ============================================================
LEAN_HEADER

  # C 型仮定を出力
  C_IDS=$(echo "$JSON" | jq -r '.assumptions[] | select(.type == "C") | .id')
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    local_id=$(to_lean_id "$id")
    content=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .content')
    question=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .question // "question"')
    date=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .date // "2026-01-01"')
    source_ref=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .sourceRef // ""')
    review=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .reviewInterval // "null"')
    validity_interval=""
    if [ "$review" = "null" ]; then
      validity_interval="    reviewInterval := none"
    else
      validity_interval="    reviewInterval := some ${review}"
    fi

    cat <<LEAN_C_BLOCK

/-- ${id}: ${content} -/
def ${local_id} : Assumption := {
  id := "${id}"
  source := .humanDecision 1 "${question}" "${date}"
  content := "${content}"
  validity := some {
    sourceRef := "${source_ref}"
    lastVerified := "${date}"
${validity_interval}
  }
}
LEAN_C_BLOCK
  done <<< "$C_IDS"

  echo ""
  echo "-- ============================================================"
  echo "-- H: LLM 推論"
  echo "-- ============================================================"

  # H 型仮定を出力
  H_IDS=$(echo "$JSON" | jq -r '.assumptions[] | select(.type == "H") | .id')
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    local_id=$(to_lean_id "$id")
    content=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .content')
    basis=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .basis // [] | map("\"" + . + "\"") | join(", ")')
    refutation=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .refutation // ""')
    source_ref=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .sourceRef // ""')
    last_verified=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .date // "2026-01-01"')
    review=$(echo "$JSON" | jq -r --arg id "$id" '.assumptions[] | select(.id == $id) | .reviewInterval // "null"')
    validity_interval=""
    if [ "$review" = "null" ]; then
      validity_interval="    reviewInterval := none"
    else
      validity_interval="    reviewInterval := some ${review}"
    fi

    cat <<LEAN_H_BLOCK

/-- ${id}: ${content} -/
def ${local_id} : Assumption := {
  id := "${id}"
  source := .llmInference
    [${basis}]
    "${refutation}"
  content := "${content}"
  validity := some {
    sourceRef := "${source_ref}"
    lastVerified := "${last_verified}"
${validity_interval}
  }
}
LEAN_H_BLOCK
  done <<< "$H_IDS"

  echo ""
  echo "-- ============================================================"
  echo "-- 仮定の一覧"
  echo "-- ============================================================"
  echo ""

  # allAssumptions リスト生成
  ALL_IDS=$(echo "$JSON" | jq -r '.assumptions[].id')
  ALL_LOCAL_IDS=""
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    local_id=$(to_lean_id "$id")
    if [ -z "$ALL_LOCAL_IDS" ]; then
      ALL_LOCAL_IDS="  [${local_id}"
    else
      ALL_LOCAL_IDS="${ALL_LOCAL_IDS}, ${local_id}"
    fi
  done <<< "$ALL_IDS"
  ALL_LOCAL_IDS="${ALL_LOCAL_IDS}]"

  cat <<LEAN_FOOTER

/-- ${NAMESPACE} インスタンスの全仮定。 -/
def allAssumptions : List Assumption :=
${ALL_LOCAL_IDS}

end Manifest.Models.Instances.${NAMESPACE}
LEAN_FOOTER
}

# --- 出力 ---
if [ -n "$OUTPUT_FILE" ]; then
  generate_lean > "$OUTPUT_FILE"
  echo "Generated: $OUTPUT_FILE" >&2
else
  generate_lean
fi

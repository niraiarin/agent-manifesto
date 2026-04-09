#!/usr/bin/env bash
# d17-state.sh — D17 WorkflowState persistence manager
# Maps to DesignFoundation.lean L1612-1619 (WorkflowState)
# and L1622-1628 (currentStep computation)
#
# Usage:
#   d17-state.sh init <plugin-name>          — Create initial state
#   d17-state.sh current-step <plugin-name>  — Compute current step (like Lean's currentStep)
#   d17-state.sh transition <plugin-name> <step> <output-json>  — Apply transition
#   d17-state.sh show <plugin-name>          — Show current state
#   d17-state.sh list                        — List all plugin states
set -euo pipefail

STATE_DIR=".claude/metrics/d17-state"
mkdir -p "$STATE_DIR"

cmd="${1:?Usage: d17-state.sh <command> <args>}"
shift

case "$cmd" in
  init)
    NAME="${1:?Usage: d17-state.sh init <plugin-name>}"
    STATE_FILE="$STATE_DIR/$NAME.json"
    if [ -f "$STATE_FILE" ]; then
      echo "State already exists: $STATE_FILE" >&2
      exit 1
    fi
    jq -n \
      --arg name "$NAME" \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{
        schema_version: 1,
        plugin_name: $name,
        created: $ts,
        updated: $ts,
        iteration: 0,
        state: {
          investigation: null,
          assumptions: null,
          axiomSystem: null,
          derivation: null,
          validation: null
        },
        transition_log: []
      }' > "$STATE_FILE"
    echo "$STATE_FILE"
    ;;

  current-step)
    # Mirrors WorkflowState.currentStep (DesignFoundation.lean L1622-1628)
    NAME="${1:?Usage: d17-state.sh current-step <plugin-name>}"
    STATE_FILE="$STATE_DIR/$NAME.json"
    if [ ! -f "$STATE_FILE" ]; then
      echo "State not found: $STATE_FILE" >&2
      exit 1
    fi
    jq -r '
      if .state.investigation == null then "investigate"
      elif .state.assumptions == null then "extract"
      elif .state.axiomSystem == null then "construct"
      elif .state.derivation == null then "derive"
      elif .state.validation == null then "validate"
      else "feedback"
      end
    ' "$STATE_FILE"
    ;;

  transition)
    NAME="${1:?Usage: d17-state.sh transition <plugin-name> <step> <output-json>}"
    STEP="${2:?}"
    OUTPUT="${3:?}"
    STATE_FILE="$STATE_DIR/$NAME.json"
    if [ ! -f "$STATE_FILE" ]; then
      echo "State not found: $STATE_FILE" >&2
      exit 1
    fi

    # Verify transition is valid (current step must match)
    CURRENT=$(bash "$0" current-step "$NAME")
    if [ "$CURRENT" != "$STEP" ]; then
      echo "Invalid transition: current step is '$CURRENT', not '$STEP'" >&2
      exit 1
    fi

    # Map step to state field
    case "$STEP" in
      investigate) FIELD="investigation" ;;
      extract)     FIELD="assumptions" ;;
      construct)   FIELD="axiomSystem" ;;
      derive)      FIELD="derivation" ;;
      validate)    FIELD="validation" ;;
      feedback)
        # Feedback resets state based on action type
        ACTION_TYPE=$(echo "$OUTPUT" | jq -r '.action')
        TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        case "$ACTION_TYPE" in
          addAssumption)
            jq --argjson out "$OUTPUT" --arg ts "$TS" '
              .state.assumptions = null |
              .state.axiomSystem = null |
              .state.derivation = null |
              .state.validation = null |
              .iteration += 1 |
              .updated = $ts |
              .transition_log += [{from_step: "feedback", action: $out.action, timestamp: $ts, iteration: .iteration}]
            ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
            ;;
          extendCoreAxiom|improveWorkflow)
            jq --argjson out "$OUTPUT" --arg ts "$TS" '
              .state.investigation = null |
              .state.assumptions = null |
              .state.axiomSystem = null |
              .state.derivation = null |
              .state.validation = null |
              .iteration += 1 |
              .updated = $ts |
              .transition_log += [{from_step: "feedback", action: $out.action, timestamp: $ts, iteration: .iteration}]
            ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
            ;;
          markOutOfScope)
            jq --argjson out "$OUTPUT" --arg ts "$TS" '
              .state.validation = null |
              .iteration += 1 |
              .updated = $ts |
              .transition_log += [{from_step: "feedback", action: $out.action, timestamp: $ts, iteration: .iteration}]
            ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
            ;;
          *)
            echo "Unknown feedback action: $ACTION_TYPE" >&2
            exit 1
            ;;
        esac
        echo "$(bash "$0" current-step "$NAME")"
        exit 0
        ;;
      *)
        echo "Unknown step: $STEP" >&2
        exit 1
        ;;
    esac

    # Apply normal (non-feedback) transition
    TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    NEXT_STEP=""
    case "$STEP" in
      investigate) NEXT_STEP="extract" ;;
      extract)     NEXT_STEP="construct" ;;
      construct)   NEXT_STEP="derive" ;;
      derive)      NEXT_STEP="validate" ;;
      validate)    NEXT_STEP="feedback" ;;
    esac

    # Determine risk level (DesignFoundation.lean stepTransitionRisk)
    # PR #278: investigate is now high risk (was moderate)
    RISK="moderate"
    case "$STEP" in
      investigate|extract|construct) RISK="high" ;;
      feedback) RISK="low" ;;
    esac

    jq --argjson out "$OUTPUT" --arg field "$FIELD" --arg ts "$TS" \
       --arg from "$STEP" --arg to "$NEXT_STEP" --arg risk "$RISK" '
      .state[$field] = ($out + {completed_at: $ts}) |
      .updated = $ts |
      .transition_log += [{from_step: $from, to_step: $to, risk_level: $risk, timestamp: $ts}]
    ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    echo "$NEXT_STEP"
    ;;

  show)
    NAME="${1:?Usage: d17-state.sh show <plugin-name>}"
    STATE_FILE="$STATE_DIR/$NAME.json"
    if [ ! -f "$STATE_FILE" ]; then
      echo "State not found: $STATE_FILE" >&2
      exit 1
    fi
    STEP=$(bash "$0" current-step "$NAME")
    ITER=$(jq '.iteration' "$STATE_FILE")
    echo "Plugin: $NAME | Step: $STEP | Iteration: $ITER"
    jq '{state: .state | to_entries | map(select(.value != null) | .key), transitions: (.transition_log | length)}' "$STATE_FILE"
    ;;

  list)
    for f in "$STATE_DIR"/*.json; do
      [ -f "$f" ] || continue
      NAME=$(basename "$f" .json)
      STEP=$(bash "$0" current-step "$NAME")
      ITER=$(jq '.iteration' "$f")
      echo "$NAME: step=$STEP iteration=$ITER"
    done
    ;;

  *)
    echo "Unknown command: $cmd" >&2
    echo "Usage: d17-state.sh {init|current-step|transition|show|list} <args>" >&2
    exit 1
    ;;
esac

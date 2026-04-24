#!/usr/bin/env bash
# Start llama-server if not already running.
# Idempotent: if already healthy, exits immediately.
#
# Usage:
#   bash scripts/start-llama-server.sh          # start and wait
#   bash scripts/start-llama-server.sh --check   # health check only (no start)
#
# Environment variables (override defaults):
#   LLAMA_MODEL   — path to GGUF model
#   LLAMA_PORT    — server port (default: 8090)
#   LLAMA_NGL     — GPU layers (default: 99)
#   LLAMA_CTX     �� context size (default: 4096)

set -euo pipefail

PORT="${LLAMA_PORT:-8090}"
MODEL="${LLAMA_MODEL:-$HOME/models/Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf}"
NGL="${LLAMA_NGL:-99}"
CTX="${LLAMA_CTX:-8192}"
ALIAS="${LLAMA_ALIAS:-qwen3.6-35b-a3b}"
HEALTH_URL="http://localhost:${PORT}/health"
MAX_WAIT=120  # Qwen3.6-35B load time on M-series typically 30-90s

check_health() {
  curl -sf --max-time 3 "$HEALTH_URL" 2>/dev/null | grep -q '"ok"'
}

if [ "${1:-}" = "--check" ]; then
  if check_health; then
    echo '{"running": true, "port": '"$PORT"'}'
    exit 0
  else
    echo '{"running": false, "port": '"$PORT"'}'
    exit 1
  fi
fi

# Already running?
if check_health; then
  echo "llama-server already running on port $PORT" >&2
  exit 0
fi

# Model exists?
if [ ! -f "$MODEL" ]; then
  echo "ERROR: Model not found: $MODEL" >&2
  echo "Set LLAMA_MODEL to the correct path." >&2
  exit 1
fi

# Start in background
echo "Starting llama-server on port $PORT..." >&2
nohup llama-server \
  -m "$MODEL" \
  --host 127.0.0.1 \
  --port "$PORT" \
  -ngl "$NGL" \
  -c "$CTX" \
  --alias "$ALIAS" \
  --jinja \
  --threads 8 \
  > /tmp/llama-server.log 2>&1 &

LLAMA_PID=$!
echo "PID: $LLAMA_PID" >&2

# Wait for health
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
  if check_health; then
    echo "llama-server ready (${elapsed}s)" >&2
    exit 0
  fi
  # Check process still alive
  if ! kill -0 "$LLAMA_PID" 2>/dev/null; then
    echo "ERROR: llama-server exited. Check /tmp/llama-server.log" >&2
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done

echo "ERROR: llama-server did not become healthy within ${MAX_WAIT}s" >&2
echo "Check /tmp/llama-server.log for details" >&2
exit 1

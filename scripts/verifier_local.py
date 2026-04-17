#!/usr/bin/env python3
"""
LLM-as-a-Verifier: Local LLM logprob-based pairwise evaluation.

Adapted from research/verifier-poc/verifier_local.py (#593 PoC).
Uses llama-server's /completion API for logprob-based expected value scoring.

Usage:
  # Health check
  python3 scripts/verifier_local.py health

  # Pairwise comparison (JSON on stdin)
  echo '{"problem":"...","proposal_a":"...","proposal_b":"...","criteria":[...]}' \
    | python3 scripts/verifier_local.py pairwise

  # Tournament (JSON on stdin)
  echo '{"problem":"...","proposals":[...],"criteria":[...]}' \
    | python3 scripts/verifier_local.py tournament

References:
  - Paper: research/LLM-as-a-Verifier_ A General-Purpose Verification Framework.pdf
  - PoC: research/verifier-poc/verifier_local.py (#593)
  - Issue: #600
"""

import json
import math
import sys
import urllib.error
import urllib.request

LLAMA_URL = "http://localhost:8090"
COMPLETION_URL = f"{LLAMA_URL}/completion"
HEALTH_URL = f"{LLAMA_URL}/health"
GRANULARITY = 20
REQUEST_TIMEOUT = 30  # seconds

# A=20 (best), T=1 (worst) — same as paper
VALID_TOKENS = {}
for i in range(GRANULARITY):
    VALID_TOKENS[chr(65 + i)] = float(GRANULARITY - i)  # A-T uppercase
    VALID_TOKENS[chr(97 + i)] = float(GRANULARITY - i)  # a-t lowercase


def check_health() -> dict:
    """Check if llama-server is running and healthy.

    Returns: {"available": bool, "status": str, "error": str|None}
    """
    try:
        req = urllib.request.Request(HEALTH_URL, method="GET")
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
            status = data.get("status", "unknown")
            return {
                "available": status == "ok",
                "status": status,
                "error": None,
            }
    except urllib.error.URLError as e:
        return {"available": False, "status": "unreachable", "error": str(e)}
    except Exception as e:
        return {"available": False, "status": "error", "error": str(e)}


def call_llama(prompt: str, n_predict: int = 1, n_probs: int = 20) -> dict:
    """Call llama-server /completion with logprobs."""
    payload = json.dumps({
        "prompt": prompt,
        "n_predict": n_predict,
        "temperature": 1.0,
        "n_probs": n_probs,
        "stop": ["</score_A>", "</score_B>", "<|im_end|>"],
    }).encode()

    req = urllib.request.Request(
        COMPLETION_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
        return json.loads(resp.read())


def extract_score_from_logprobs(completion_probs: list) -> float:
    """Extract normalized [0,1] score from logprob distribution.

    Computes E[score] = sum(value * prob) / sum(prob) over valid tokens,
    then normalizes to [0,1]. This is the paper's core scoring mechanism.
    """
    if not completion_probs:
        return 0.5

    last_token = completion_probs[-1]
    top_logprobs = last_token.get("top_logprobs", [])

    probs = {}
    for entry in top_logprobs:
        tok = entry["token"].strip()
        if tok in VALID_TOKENS:
            val = VALID_TOKENS[tok]
            p = math.exp(entry["logprob"])
            probs[val] = max(probs.get(val, 0.0), p)

    if not probs:
        return 0.5

    total_p = sum(probs.values())
    expected = sum(v * p for v, p in probs.items()) / total_p
    min_val, max_val = 1.0, float(GRANULARITY)
    return (expected - min_val) / (max_val - min_val)


def extract_score_direct(prompt_with_tag: str) -> tuple:
    """Generate one score token and extract logprob-based expected value.

    Returns: (score: float, debug: dict)
    """
    result = call_llama(prompt_with_tag, n_predict=1, n_probs=20)

    comp_probs = result.get("completion_probabilities", [])
    score = extract_score_from_logprobs(comp_probs)

    debug = {
        "selected_token": result.get("content", "").strip(),
        "logprob_score": score,
        "distribution": {},
    }
    if comp_probs:
        for entry in comp_probs[-1].get("top_logprobs", []):
            tok = entry["token"].strip()
            if tok in VALID_TOKENS:
                debug["distribution"][tok] = {
                    "value": VALID_TOKENS[tok],
                    "prob": round(math.exp(entry["logprob"]), 6),
                }

    return score, debug


def create_pairwise_prompt(problem: str, trace_a: str, trace_b: str, criterion: dict) -> str:
    """Create pairwise scoring prompt (paper format).

    Args:
        problem: Context description
        trace_a: Description of proposal A
        trace_b: Description of proposal B
        criterion: {"id": str, "name": str, "description": str}
    """
    scale_desc = (
        "Rate on a 20-point scale using letters A through T:\n"
        "  A = clearly excellent (best)\n"
        "  E-G = above average\n"
        "  H-J = uncertain, leans toward success\n"
        "  K-M = uncertain, leans toward failure\n"
        "  N-P = below average\n"
        "  T = clearly failed (worst)"
    )

    return (
        f"<|im_start|>user\n"
        f"You are an expert evaluator. Evaluate two improvement proposals "
        f"on ONE criterion: **{criterion['name']}**.\n\n"
        f"**Context:**\n{problem}\n\n"
        f"**Proposal A:**\n{trace_a}\n\n"
        f"**Proposal B:**\n{trace_b}\n\n"
        f"**Criterion — {criterion['name']}:**\n"
        f"{criterion['description']}\n\n"
        f"**Rating Scale:**\n{scale_desc}\n\n"
        f"Output your final scores:\n"
        f"<score_A>LETTER_A_TO_T</score_A>\n"
        f"<score_B>LETTER_A_TO_T</score_B>\n"
        f"<|im_end|>\n"
        f"<|im_start|>assistant\n"
        f"<think>\n\n</think>\n"
    )


def score_pair(problem: str, trace_a: str, trace_b: str, criterion: dict) -> dict:
    """Score a pair of proposals on a single criterion.

    Returns: {"score_a": float, "score_b": float, "winner": "A"|"B", "debug": dict}
    """
    base_prompt = create_pairwise_prompt(problem, trace_a, trace_b, criterion)

    # Score A first
    prompt_a = base_prompt + "<score_A>"
    score_a, debug_a = extract_score_direct(prompt_a)

    # Score B conditioned on A's token (this is where K-round variance comes from)
    prompt_b = base_prompt + f"<score_A>{debug_a['selected_token']}</score_A>\n<score_B>"
    score_b, debug_b = extract_score_direct(prompt_b)

    winner = "A" if score_a > score_b else "B"

    return {
        "score_a": round(score_a, 6),
        "score_b": round(score_b, 6),
        "margin": round(score_a - score_b, 6),
        "winner": winner,
        "criterion": criterion["id"],
        "debug": {"a": debug_a, "b": debug_b},
    }


def pairwise_compare(problem: str, trace_a: str, trace_b: str,
                     criteria: list, k_rounds: int = 1) -> dict:
    """Full pairwise comparison across all criteria with optional K-rounds.

    Args:
        problem: Context description
        trace_a: Description of proposal A
        trace_b: Description of proposal B
        criteria: List of {"id", "name", "description"}
        k_rounds: Number of independent rounds (K>1 only meaningful for pairwise)

    Returns: {
        "winner": "A"|"B",
        "total_a": float, "total_b": float,
        "criteria_results": [...],
        "k_stats": {...} (if K>1)
    }
    """
    if k_rounds < 1:
        k_rounds = 1

    all_results = []

    for _k in range(k_rounds):
        round_results = []
        for crit in criteria:
            result = score_pair(problem, trace_a, trace_b, crit)
            round_results.append(result)
        all_results.append(round_results)

    # Aggregate across criteria and K-rounds
    total_a = 0.0
    total_b = 0.0
    criteria_results = []

    for ci, crit in enumerate(criteria):
        a_scores = [all_results[k][ci]["score_a"] for k in range(k_rounds)]
        b_scores = [all_results[k][ci]["score_b"] for k in range(k_rounds)]

        mean_a = sum(a_scores) / len(a_scores)
        mean_b = sum(b_scores) / len(b_scores)
        total_a += mean_a
        total_b += mean_b

        entry = {
            "criterion": crit["id"],
            "mean_a": round(mean_a, 6),
            "mean_b": round(mean_b, 6),
            "winner": "A" if mean_a > mean_b else "B",
        }

        if k_rounds > 1:
            margins = [a_scores[k] - b_scores[k] for k in range(k_rounds)]
            wins_a = sum(1 for m in margins if m > 0)
            wins_b = sum(1 for m in margins if m < 0)
            entry["k_stats"] = {
                "wins_a": wins_a,
                "wins_b": wins_b,
                "ties": k_rounds - wins_a - wins_b,
                "margin_sd": round(_std(margins), 6),
            }

        criteria_results.append(entry)

    return {
        "winner": "A" if total_a > total_b else "B",
        "total_a": round(total_a, 6),
        "total_b": round(total_b, 6),
        "margin": round(total_a - total_b, 6),
        "criteria_results": criteria_results,
        "k_rounds": k_rounds,
    }


def tournament(problem: str, proposals: list, criteria: list,
               k_rounds: int = 1) -> dict:
    """Round-robin tournament: C(N,2) pairwise comparisons.

    Args:
        problem: Context description
        proposals: List of {"id": str, "description": str}
        criteria: List of {"id", "name", "description"}
        k_rounds: K-rounds per comparison

    Returns: {
        "ranking": [{"id": str, "wins": int, "total_margin": float}],
        "matches": [...],
    }
    """
    n = len(proposals)
    if n < 2:
        return {
            "ranking": [{"id": proposals[0]["id"], "wins": 0, "total_margin": 0.0}] if proposals else [],
            "matches": [],
        }

    wins = {p["id"]: 0 for p in proposals}
    margins = {p["id"]: 0.0 for p in proposals}
    matches = []

    for i in range(n):
        for j in range(i + 1, n):
            result = pairwise_compare(
                problem,
                proposals[i]["description"],
                proposals[j]["description"],
                criteria,
                k_rounds,
            )

            winner_id = proposals[i]["id"] if result["winner"] == "A" else proposals[j]["id"]
            loser_id = proposals[j]["id"] if result["winner"] == "A" else proposals[i]["id"]
            wins[winner_id] += 1
            margins[winner_id] += abs(result["margin"])
            margins[loser_id] -= abs(result["margin"])

            matches.append({
                "a": proposals[i]["id"],
                "b": proposals[j]["id"],
                "winner": winner_id,
                "margin": result["margin"],
                "criteria_results": result["criteria_results"],
            })

    ranking = sorted(
        [{"id": pid, "wins": wins[pid], "total_margin": round(margins[pid], 6)}
         for pid in wins],
        key=lambda x: (-x["wins"], -x["total_margin"]),
    )

    return {"ranking": ranking, "matches": matches}


def _std(arr: list) -> float:
    if len(arr) < 2:
        return 0.0
    m = sum(arr) / len(arr)
    return math.sqrt(sum((x - m) ** 2 for x in arr) / len(arr))


# --- CLI interface ---

def ensure_server() -> bool:
    """Ensure llama-server is running. Start it if needed.

    Returns True if server is available, False if startup failed.
    """
    health = check_health()
    if health["available"]:
        return True

    # Try to start via start-llama-server.sh
    import os
    import subprocess

    script = os.path.join(os.path.dirname(__file__), "start-llama-server.sh")
    if not os.path.exists(script):
        print("llama-server not running and start script not found", file=sys.stderr)
        return False

    print("llama-server not running, starting...", file=sys.stderr)
    ret = subprocess.run(["bash", script], capture_output=False)
    if ret.returncode != 0:
        print("Failed to start llama-server", file=sys.stderr)
        return False

    # Verify after startup
    health = check_health()
    return health["available"]


def cmd_health():
    result = check_health()
    json.dump(result, sys.stdout, indent=2)
    print()
    sys.exit(0 if result["available"] else 1)


def cmd_ensure():
    """Health check + auto-start. Exit 0 if available after startup."""
    ok = ensure_server()
    result = check_health()
    json.dump(result, sys.stdout, indent=2)
    print()
    sys.exit(0 if ok else 1)


def cmd_pairwise():
    if not ensure_server():
        print('{"error": "llama-server unavailable"}', file=sys.stderr)
        sys.exit(1)
    data = json.load(sys.stdin)
    result = pairwise_compare(
        problem=data["problem"],
        trace_a=data["proposal_a"],
        trace_b=data["proposal_b"],
        criteria=data["criteria"],
        k_rounds=data.get("k_rounds", 1),
    )
    json.dump(result, sys.stdout, indent=2)
    print()


def cmd_tournament():
    if not ensure_server():
        print('{"error": "llama-server unavailable"}', file=sys.stderr)
        sys.exit(1)
    data = json.load(sys.stdin)
    result = tournament(
        problem=data["problem"],
        proposals=data["proposals"],
        criteria=data["criteria"],
        k_rounds=data.get("k_rounds", 1),
    )
    json.dump(result, sys.stdout, indent=2)
    print()


def main():
    if len(sys.argv) < 2:
        print("Usage: verifier_local.py <health|ensure|pairwise|tournament>", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "health":
        cmd_health()
    elif cmd == "ensure":
        cmd_ensure()
    elif cmd == "pairwise":
        cmd_pairwise()
    elif cmd == "tournament":
        cmd_tournament()
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

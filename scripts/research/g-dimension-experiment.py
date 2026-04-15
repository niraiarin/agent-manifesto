#\!/usr/bin/env python3
"""G-dimension discriminability experiment for #551.
Compares scoring granularity G={5, 10, 20} on boundary/tradeoff cases.
Uses local LM Studio (Anthropic-compatible API).
"""

import argparse
import json
import re
import statistics
import sys
import time
from pathlib import Path

import anthropic

LM_STUDIO_URL = "http://192.168.10.90:1234"
MODEL = "openai/gpt-oss-120b"

def make_system_prompt(granularity):
    """Generate judge system prompt for a given granularity level."""
    if granularity == 5:
        scale_desc = "an integer from 1 to 5"
        scale_example = "1, 2, 3, 4, or 5"
    elif granularity == 10:
        scale_desc = "an integer from 1 to 10"
        scale_example = "1, 2, 3, ..., 10"
    elif granularity == 20:
        scale_desc = "a number from 0.25 to 5.00 in increments of 0.25"
        scale_example = "0.25, 0.50, 0.75, 1.00, ..., 4.75, 5.00"
    else:
        raise ValueError(f"Unsupported granularity: {granularity}")

    return f"""You are an independent quality evaluator.
Evaluate the artifact against ONE specific criterion.
Return ONLY a JSON object: {{"criterion": "<ID>", "score": <{scale_desc}>, "reasoning": "<one sentence>"}}

The score must be {scale_desc} ({scale_example}).

Research criteria (G1-G4):
- G1 (Question): Does it answer the stated question? (lowest=not at all, highest=completely)
- G2 (Reproducibility): Can results be reproduced? (lowest=no info, highest=fully)
- G3 (Quantitative): Is the basis quantitative? (lowest=no data, highest=rigorous)
- G4 (Next action): Is next step clear? (lowest=no direction, highest=precise)

Evolve criteria (C1-C4):
- C1 (Non-triviality): Is this non-trivial? (lowest=cosmetic, highest=structural)
- C2 (Alignment): Grounded in axioms? (lowest=no refs, highest=precise derivation)
- C3 (Measurement): Quantitatively demonstrated? (lowest=no data, highest=before/after)
- C4 (Correctness): Does implementation work? (lowest=broken, highest=verified)

Return ONLY the JSON object. No markdown fences."""


def get_criteria(case_id):
    if any(x in case_id for x in ["tradeoff", "boundary-2", "clear"]):
        return ["C1", "C2", "C3", "C4"]
    return ["G1", "G2", "G3", "G4"]


def validate_score(score, granularity):
    """Check if score is valid for the given granularity."""
    if not isinstance(score, (int, float)):
        return False
    if granularity == 5:
        return 1 <= score <= 5 and score == int(score)
    elif granularity == 10:
        return 1 <= score <= 10 and score == int(score)
    elif granularity == 20:
        return 0.25 <= score <= 5.0 and (score * 4) == int(score * 4)
    return False


def evaluate_once(client, content, criterion, temperature, granularity):
    system = make_system_prompt(granularity)
    try:
        resp = client.messages.create(
            model=MODEL, max_tokens=200, temperature=temperature,
            system=system,
            messages=[{"role": "user", "content": f"Evaluate on {criterion} ONLY:\n\n{content}"}],
        )
        text = resp.content[0].text.strip() if resp.content else ""
        m = re.search(r'\{[^}]+\}', text)
        if m:
            result = json.loads(m.group())
            result["tokens"] = resp.usage.input_tokens + resp.usage.output_tokens
            return result
        return {"error": "no JSON", "raw": text[:100]}
    except Exception as e:
        return {"error": str(e)[:80]}


def run(cases, granularities, k, temperature, dry_run=False):
    client = anthropic.Anthropic(base_url=LM_STUDIO_URL, api_key="lm-studio")
    results = []

    total = sum(k * len(get_criteria(c["id"])) for c in cases for _ in granularities)
    print(f"Plan: {len(cases)} cases x {granularities} G x K={k} x temp={temperature} = {total} calls")
    print(f"Model: {MODEL} @ {LM_STUDIO_URL}")
    if dry_run:
        print("DRY RUN")
        return []

    # Connectivity test
    try:
        client.messages.create(model=MODEL, max_tokens=10, temperature=0.0,
            messages=[{"role": "user", "content": "OK"}])
        print("Server OK")
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

    n = 0
    for case in cases:
        criteria = get_criteria(case["id"])
        for g in granularities:
            print(f"\n--- {case['id']} | G={g} ---")
            for crit in criteria:
                scores = []
                for i in range(k):
                    n += 1
                    if n % 10 == 0:
                        print(f"  [{n}/{total}]")
                    r = evaluate_once(client, case["content"], crit, temperature, g)
                    if "error" in r:
                        print(f"  WARN {crit}#{i}: {r['error'][:60]}")
                        continue
                    s = r.get("score")
                    if isinstance(s, (int, float)):
                        # Normalize to 0-1 scale for cross-granularity comparison
                        if g == 5:
                            norm = (s - 1) / 4  # 1-5 -> 0-1
                        elif g == 10:
                            norm = (s - 1) / 9  # 1-10 -> 0-1
                        elif g == 20:
                            norm = (s - 0.25) / 4.75  # 0.25-5.0 -> 0-1
                        scores.append({"raw": s, "norm": round(norm, 4)})
                    else:
                        print(f"  WARN {crit}#{i}: invalid score {s}")
                    time.sleep(0.1)

                if len(scores) >= 2:
                    raw_scores = [s["raw"] for s in scores]
                    norm_scores = [s["norm"] for s in scores]
                    mn = statistics.mean(norm_scores)
                    sd = statistics.stdev(norm_scores)
                    cv = sd / mn if mn > 0 else 0
                    entry = {
                        "case": case["id"], "cat": case["category"],
                        "crit": crit, "granularity": g,
                        "n": len(scores),
                        "raw_mean": round(statistics.mean(raw_scores), 3),
                        "raw_stdev": round(statistics.stdev(raw_scores), 3),
                        "norm_mean": round(mn, 4),
                        "norm_stdev": round(sd, 4),
                        "norm_cv": round(cv, 4),
                        "raw_scores": raw_scores,
                    }
                    results.append(entry)
                    print(f"  {crit}: raw_mean={entry['raw_mean']} raw_sd={entry['raw_stdev']} norm_sd={sd:.4f}")

    return results


def summary(results):
    print("\n" + "=" * 80)
    print("DISCRIMINABILITY COMPARISON")
    print("=" * 80)

    # Compare normalized stdev across granularities
    for cat in ["boundary", "tradeoff"]:
        cr = [r for r in results if r["cat"] == cat]
        if not cr:
            continue
        print(f"\n### {cat.upper()} (normalized 0-1 scale)")
        print(f"{'Case':<18} {'Crit':<5} {'G':<4} {'NormMean':<10} {'NormSD':<10} {'RawMean':<10} {'RawSD':<8}")
        for r in sorted(cr, key=lambda x: (x["case"], x["crit"], x["granularity"])):
            print(f"{r['case']:<18} {r['crit']:<5} {r['granularity']:<4} {r['norm_mean']:<10} {r['norm_stdev']:<10} {r['raw_mean']:<10} {r['raw_stdev']:<8}")

    # Cohen's d comparison: G=5 vs G=20
    print("\n### COHEN'S d (G=5 vs G=20)")
    cases_seen = set()
    for r in results:
        key = (r["case"], r["crit"])
        if key in cases_seen:
            continue
        g5 = [x for x in results if x["case"] == r["case"] and x["crit"] == r["crit"] and x["granularity"] == 5]
        g20 = [x for x in results if x["case"] == r["case"] and x["crit"] == r["crit"] and x["granularity"] == 20]
        if g5 and g20:
            cases_seen.add(key)
            sd5 = g5[0]["norm_stdev"]
            sd20 = g20[0]["norm_stdev"]
            if sd5 > 0 and sd20 > 0:
                pooled = ((sd5**2 + sd20**2) / 2) ** 0.5
                d = abs(g20[0]["norm_mean"] - g5[0]["norm_mean"]) / pooled if pooled > 0 else 0
                print(f"  {r['case']} {r['crit']}: sd5={sd5:.4f} sd20={sd20:.4f} d={d:.3f}")
            elif sd20 > 0:
                print(f"  {r['case']} {r['crit']}: sd5=0 sd20={sd20:.4f} (G=20 resolves variance G=5 cannot)")
            else:
                print(f"  {r['case']} {r['crit']}: both sd=0 (no variance at any granularity)")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--k", type=int, default=10)
    p.add_argument("--temp", type=float, default=1.0)
    p.add_argument("--output", default="g-results.json")
    a = p.parse_args()

    tc = json.loads((Path(__file__).parent / "test-cases.json").read_text())
    # Use boundary + tradeoff cases only (TC3-TC6)
    cases = [c for c in tc["cases"] if c["category"] in ("boundary", "tradeoff")]

    results = run(cases, [5, 10, 20], a.k, a.temp, dry_run=a.dry_run)
    if results:
        out = Path(__file__).parent / a.output
        out.write_text(json.dumps(results, indent=2, ensure_ascii=False))
        print(f"\nSaved to {out}")
        summary(results)


if __name__ == "__main__":
    main()

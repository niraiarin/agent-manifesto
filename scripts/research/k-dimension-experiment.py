#\!/usr/bin/env python3
"""K-dimension variance measurement experiment for #550.
Uses local LM Studio server (Anthropic-compatible API) for temperature control.
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

JUDGE_SYSTEM = """You are an independent quality evaluator.
Evaluate the artifact against ONE specific criterion.
Return ONLY a JSON object: {"criterion": "<ID>", "score": <integer 1-5>, "reasoning": "<one sentence>"}

Research criteria (G1-G4):
- G1 (Question): Does it answer the stated question? (1=no, 5=completely)
- G2 (Reproducibility): Can results be reproduced? (1=no info, 5=fully)
- G3 (Quantitative): Is the basis quantitative? (1=no data, 5=rigorous)
- G4 (Next action): Is next step clear? (1=no direction, 5=precise)

Evolve criteria (C1-C4):
- C1 (Non-triviality): Is this non-trivial? (1=cosmetic, 5=structural)
- C2 (Alignment): Grounded in axioms? (1=no refs, 5=precise derivation)
- C3 (Measurement): Quantitatively demonstrated? (1=no data, 5=before/after)
- C4 (Correctness): Does implementation work? (1=broken, 5=verified)

Return ONLY the JSON object. No markdown fences."""


def get_criteria(case_id):
    if any(x in case_id for x in ["tradeoff", "boundary-2", "clear"]):
        return ["C1", "C2", "C3", "C4"]
    return ["G1", "G2", "G3", "G4"]


def evaluate_once(client, content, criterion, temperature):
    try:
        resp = client.messages.create(
            model=MODEL,
            max_tokens=200,
            temperature=temperature,
            system=JUDGE_SYSTEM,
            messages=[
                {"role": "user", "content": f"Evaluate on {criterion} ONLY:\n\n{content}"},
            ],
        )
        text = resp.content[0].text.strip()
        m = re.search(r'\{[^}]+\}', text)
        if m:
            result = json.loads(m.group())
            tokens = resp.usage.input_tokens + resp.usage.output_tokens
            result["tokens"] = tokens
            return result
        return {"error": "no JSON", "raw": text[:100]}
    except Exception as e:
        return {"error": str(e)[:80]}


def run(cases, k_values, temps, dry_run=False, fcase=None, fk=None, ftemp=None):
    client = anthropic.Anthropic(base_url=LM_STUDIO_URL, api_key="lm-studio")
    results = []
    ec = [c for c in cases if c["id"] == fcase] if fcase else cases
    ek = [fk] if fk else k_values
    et = [ftemp] if ftemp is not None else temps

    total = sum(k * len(get_criteria(c["id"])) for c in ec for k in ek for _ in et)
    print(f"Plan: {len(ec)} cases x {ek} K x {et} temps = {total} calls")
    print(f"Model: {MODEL} @ {LM_STUDIO_URL}")
    if dry_run:
        print("DRY RUN")
        return []

    # Quick connectivity test
    try:
        test = client.messages.create(
            model=MODEL, max_tokens=10, temperature=0.0,
            messages=[{"role": "user", "content": "Say OK"}],
        )
        txt = test.content[0].text.strip() if test.content else "(empty)"
        print(f"Server OK: {txt[:30]}")
    except Exception as e:
        print(f"ERROR: Cannot connect to {LM_STUDIO_URL}: {e}")
        sys.exit(1)

    n = 0
    for case in ec:
        criteria = get_criteria(case["id"])
        for temp in et:
            for k in ek:
                print(f"\n--- {case['id']} | temp={temp} | K={k} ---")
                for crit in criteria:
                    scores, toks = [], []
                    for i in range(k):
                        n += 1
                        if n % 10 == 0:
                            print(f"  [{n}/{total}]")
                        r = evaluate_once(client, case["content"], crit, temp)
                        if "error" in r:
                            print(f"  WARN {crit}#{i}: {r['error'][:60]}")
                            continue
                        s = r.get("score")
                        if isinstance(s, (int, float)) and 1 <= s <= 5:
                            scores.append(int(s))
                            toks.append(r.get("tokens", 0))
                        else:
                            print(f"  WARN {crit}#{i}: invalid score {s}")
                        time.sleep(0.1)

                    if len(scores) >= 2:
                        mn = statistics.mean(scores)
                        sd = statistics.stdev(scores)
                        cv = sd / mn if mn > 0 else 0
                        ss = sorted(scores)
                        q1, q3 = ss[len(ss) // 4], ss[3 * len(ss) // 4]
                        entry = {
                            "case": case["id"], "cat": case["category"],
                            "crit": crit, "temp": temp, "k": k,
                            "n": len(scores), "mean": round(mn, 3),
                            "stdev": round(sd, 3), "cv": round(cv, 4),
                            "iqr": q3 - q1, "min": min(scores), "max": max(scores),
                            "scores": scores,
                            "avg_tok": round(statistics.mean(toks)) if toks else 0,
                        }
                        results.append(entry)
                        print(f"  {crit}: mean={mn:.2f} s={sd:.3f} CV={cv:.4f} IQR={q3-q1} [{min(scores)},{max(scores)}]")
                    elif scores:
                        print(f"  {crit}: only {len(scores)} valid (need >=2)")
                    else:
                        print(f"  {crit}: no valid responses")
    return results


def summary(results):
    print("\n" + "=" * 70 + "\nSUMMARY\n" + "=" * 70)
    for cat in ["clear", "boundary", "tradeoff"]:
        cr = [r for r in results if r["cat"] == cat]
        if not cr:
            continue
        print(f"\n### {cat.upper()}")
        print(f"{'Case':<18} {'Crit':<5} {'T':<4} {'K':<4} {'Mean':<6} {'s':<6} {'CV':<7} {'IQR':<4} {'Range'}")
        for r in sorted(cr, key=lambda x: (x["case"], x["crit"], x["temp"], x["k"])):
            print(f"{r['case']:<18} {r['crit']:<5} {r['temp']:<4} {r['k']:<4} {r['mean']:<6} {r['stdev']:<6} {r['cv']:<7} {r['iqr']:<4} [{r['min']},{r['max']}]")

    print("\n### GATE CHECK")
    bht = [r for r in results if r["cat"] == "boundary" and r["temp"] == 1.0]
    if bht:
        mc = max(r["cv"] for r in bht)
        print(f"  Max CV at temp=1.0 boundary: {mc:.4f} (threshold >0.05)")
        if mc > 0.05:
            print("  -> PASS criterion 1")
        elif mc > 0.01:
            print("  -> CONDITIONAL")
        else:
            print("  -> FAIL")

    # K effect check
    for k_lo, k_hi in [(10, 30), (10, 50)]:
        lo = [r for r in results if r["k"] == k_lo and r["cat"] == "boundary"]
        hi = [r for r in results if r["k"] == k_hi and r["cat"] == "boundary"]
        if lo and hi:
            avg_lo = statistics.mean(r["stdev"] for r in lo)
            avg_hi = statistics.mean(r["stdev"] for r in hi)
            print(f"  Avg stdev K={k_lo}: {avg_lo:.3f} vs K={k_hi}: {avg_hi:.3f}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--k", type=int)
    p.add_argument("--temp", type=float)
    p.add_argument("--case", type=str)
    p.add_argument("--output", default="results.json")
    a = p.parse_args()

    tc = json.loads((Path(__file__).parent / "test-cases.json").read_text())
    results = run(
        tc["cases"], [10, 30, 50], [0.0, 0.5, 1.0],
        dry_run=a.dry_run, fcase=a.case, fk=a.k, ftemp=a.temp,
    )
    if results:
        out = Path(__file__).parent / a.output
        out.write_text(json.dumps(results, indent=2, ensure_ascii=False))
        print(f"\nSaved to {out}")
        summary(results)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
validate_real.py — 実運用 validation.

このセッションで実際に流れているプロンプト + agent-manifesto 内の実 prompt を
classifier にかけて、期待 routing と一致するか確認。

Classifier:9001 が serve 中であることが前提。
"""

from __future__ import annotations

import argparse
import json
import time
import urllib.request
from pathlib import Path


REAL_PROMPTS = [
    # (prompt, expected_label or None, source)
    # .claude/skills/ や .claude/agents/ から典型的な呼び出しを抜粋

    # metrics-interp / M-interp (local_probable)
    ("V1-V7 メトリクスを解釈して停滞シグナルを報告してください。valueless_change streak が 4 で halt_recommended が true です。",
     "local_probable", "skill/metrics"),
    ("現在の V6 knowledge_structure から orphan 命題を特定し、改善提案を 3 件。",
     "local_probable", "skill/metrics"),

    # trace-interp (local_probable)
    ("manifest-trace の coverage 90.6% は D15-D18, E2 未カバー。D13 影響波及を考慮して優先度付け。",
     "local_probable", "skill/trace"),

    # observer (local_probable)
    ("最新 evolve-history.jsonl から failure pattern を列挙。判断・提案はしない、観察のみ。",
     "local_probable", "agent/observer"),

    # paperize writing (local_probable)
    ("outline と evidence から Findings セクションを書いて。internal citation は 8-char SHA 付き。",
     "local_probable", "skill/paperize"),

    # summarize (local_confident)
    ("この長い会話履歴を 3 行で要約。",
     "local_confident", "built-in/compact"),
    ("/compact focus on #649 router design, drop HelpSteer3 details",
     "local_confident", "built-in/compact"),

    # handoff (local_confident)
    ("現在のセッション状態を resume.md に出力。intent / progress / next_steps を含む。",
     "local_confident", "skill/handoff"),

    # verify (cloud_required)
    ("このコード変更を独立検証してください。L1 safety 違反、マニフェスト逸脱をチェック。K=3 rounds。",
     "cloud_required", "skill/verify"),

    # formal-derivation (cloud_required)
    ("Γ ⊢ φ の導出手順を Lean 4 で構成。公理衛生とギャップ検証を含む。",
     "cloud_required", "skill/formal-derivation"),

    # evolve (cloud_required)
    ("/evolve Phase 2 Hypothesizer を呼び出して、Observer report から改善仮説を 5 件設計。",
     "cloud_required", "skill/evolve"),

    # code generation (cloud_required)
    ("この FastAPI ルーターに OAuth2 Bearer Token 認証を追加。",
     "cloud_required", "built-in/code-gen"),

    # research (cloud_required)
    ("/research Step 5 の実験実施。Gate 基準 ≥85% accuracy を満たすか多段推論で判定。",
     "cloud_required", "skill/research"),

    # hybrid (Q&A)
    ("Python の asyncio と threading の使い分けを説明してください。",
     "hybrid", "built-in/qa"),
    ("Transformer の attention 機構を一言で",
     "hybrid", "built-in/qa"),

    # unknown (OOD)
    ("今日の天気はどう？",
     "unknown", "ood"),
    ("パスタを美味しく茹でるコツを教えて",
     "unknown", "ood"),

    # edge: empty-ish
    ("はい",
     None, "edge/short"),
    ("ok",
     None, "edge/short"),

    # edge: very long prompt (truncation test)
    ("agent-manifesto の lean-formalization について、" + "詳細に説明してください。" * 50,
     None, "edge/long"),
]


def classify(prompt: str, url: str = "http://localhost:9001/classify", min_conf: float | None = None) -> dict:
    payload = {"prompt": prompt}
    if min_conf is not None:
        payload["min_confidence"] = min_conf
    body = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path("../analysis/validation-real.json"))
    parser.add_argument("--min-confidence", type=float, default=None,
                        help="override serve.py OOV threshold (default: use serve default 0.5)")
    args = parser.parse_args()

    # Mirror router.js safety nets
    FORCE_CLOUD_PREFIXES = ("/research", "/verify", "/formal-derivation", "/evolve",
                            "/ground-axiom", "/spec-driven-workflow", "/instantiate-model",
                            "/generate-plugin", "/brownfield", "/design-implementation-plan")
    CONSERVATIVE_THRESHOLD = 0.5

    def apply_safety_nets(prompt: str, resp: dict) -> tuple[str, str]:
        """Return (post_safety_label, reason)."""
        trimmed = prompt.lstrip()
        for prefix in FORCE_CLOUD_PREFIXES:
            if trimmed.startswith(prefix):
                return "cloud_required", f"force_cloud[{prefix}]"
        label = resp["label"]
        if label in ("local_confident", "local_probable") and resp["confidence"] < CONSERVATIVE_THRESHOLD:
            return "cloud_required", f"conservative(conf={resp['confidence']:.3f})"
        return label, "classifier"

    correct = 0
    incorrect = 0
    skipped = 0
    results = []

    for prompt, expected, source in REAL_PROMPTS:
        t0 = time.time()
        resp = classify(prompt, min_conf=args.min_confidence)
        client_latency_ms = (time.time() - t0) * 1000

        raw_label = resp["label"]
        actual, safety_reason = apply_safety_nets(prompt, resp)
        conf = resp["confidence"]
        fallback = resp["fallback"]

        if expected is None:
            match = None
            skipped += 1
            marker = "[edge]"
        elif actual == expected:
            match = True
            correct += 1
            marker = "✅"
        else:
            match = False
            incorrect += 1
            marker = "❌"

        results.append({
            "prompt": prompt[:100] + ("..." if len(prompt) > 100 else ""),
            "expected": expected,
            "raw_label": raw_label,
            "actual": actual,
            "safety_reason": safety_reason,
            "confidence": round(conf, 3),
            "fallback": fallback,
            "server_latency_ms": resp["latency_ms"],
            "client_latency_ms": round(client_latency_ms, 2),
            "match": match,
            "source": source,
        })

        print(f"{marker} src={source:<25} expected={str(expected):<18} raw={raw_label:<18} post-safety={actual:<18} via={safety_reason}")

    graded = correct + incorrect
    accuracy = correct / graded if graded else 0.0
    print(f"\n[validation] n={len(REAL_PROMPTS)} graded={graded} accuracy={accuracy:.1%} (correct={correct} incorrect={incorrect} edge={skipped})")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({
        "graded_n": graded,
        "accuracy": accuracy,
        "correct": correct,
        "incorrect": incorrect,
        "skipped": skipped,
        "results": results,
    }, indent=2, ensure_ascii=False))
    print(f"[validation] wrote {args.output}")


if __name__ == "__main__":
    main()

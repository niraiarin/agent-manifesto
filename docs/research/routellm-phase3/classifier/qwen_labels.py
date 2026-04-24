#!/usr/bin/env python3
"""
qwen_labels.py — Qwen LLM annotator via llama-server.

Reads candidates JSONL, calls llama-server /v1/chat/completions with thinking
disabled, writes enriched JSONL with gt_label + metadata. Checkpoints every N.
Resume-safe: existing output entries are skipped on re-run.
"""

from __future__ import annotations

import argparse
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


LABELS = ["local_confident", "local_probable", "cloud_required", "hybrid", "unknown"]
MAX_USER_CHARS = 1500


SYSTEM = """You are the agent-manifesto routing classifier. Label each user prompt with exactly one of the 5 labels below.

## Label definitions

- **local_confident**: narrow, low-domain, batch-style tasks (outline, summarise, handoff, simple file read)
- **local_probable**: medium-domain reasoning, structured interpretation (V1-V7 reading, trace analysis, paper drafting)
- **cloud_required**: safety-critical or deep reasoning (`/verify`, `/evolve`, `/research`, code generation, PR management, design decisions)
- **hybrid**: dynamic routing based on input (short ack, status check, Q&A, discussion)
- **unknown**: out-of-distribution, off-topic (chitchat, cooking, weather, anything unrelated to agent-manifesto project)

## Decision hints

- Any slash command like `/research`, `/verify`, `/evolve`, `/trace`, `/metrics`, `/paperize`, `/handoff` → usually cloud_required (unless handoff which may be local_confident)
- Code modification, PR work, file operations → cloud_required
- V1-V7 interpretation, manifest-trace output reading → local_probable
- Short confirmations, "ok", status questions → hybrid
- Off-project prompts → unknown

## Output

Respond with exactly one JSON object on a single line. No explanation, no preamble:
{"label": "<one of the 5 labels>"}"""


def validate_localhost_url(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError(f"unsupported url scheme: {url}")
    if parsed.hostname not in {"127.0.0.1", "localhost"}:
        raise ValueError(f"url must point to localhost: {url}")
    return url


def load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def append_jsonl(path: Path, entries: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as f:
        for entry in entries:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def extract_label(content: str) -> str:
    match = re.search(r'"label"\s*:\s*"([^"]+)"', content)
    if match:
        candidate = match.group(1).strip()
        if candidate in LABELS:
            return candidate
    for label in LABELS:
        if label in content:
            return label
    return "unknown"


def classify_via_llama_server(prompt: str, url: str, timeout: int = 120, model_alias: str = "qwen3.6-35b-a3b") -> tuple[str, float, str]:
    body = {
        "model": model_alias,
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": prompt[:MAX_USER_CHARS]},
        ],
        "max_tokens": 128,
        "temperature": 0.0,
        "top_p": 1.0,
        "chat_template_kwargs": {"enable_thinking": False},
    }
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    start = time.time()
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read().decode("utf-8"))
    latency_ms = (time.time() - start) * 1000.0
    content = payload.get("choices", [{}])[0].get("message", {}).get("content", "") or ""
    return extract_label(content), latency_ms, content


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--llama-url", default="http://localhost:8090/v1/chat/completions")
    parser.add_argument("--checkpoint-every", type=int, default=50)
    parser.add_argument("--limit", type=int, default=0, help="If >0, only process first N candidates (for smoke tests).")
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--annotator-label", default="qwen3.6-35b-a3b", help="Value written to each entry's annotator field.")
    parser.add_argument("--model-alias", default="qwen3.6-35b-a3b", help="Model name sent to /v1/chat/completions.")
    args = parser.parse_args()

    url = validate_localhost_url(args.llama_url)
    candidates = load_jsonl(args.input)
    if args.limit > 0:
        candidates = candidates[: args.limit]
    print(f"[qwen-labels] input={args.input} n={len(candidates)}")

    existing = load_jsonl(args.output)
    processed_ids = {entry.get("id") for entry in existing if entry.get("id")}
    if processed_ids:
        print(f"[qwen-labels] resume: {len(processed_ids)} already processed, skipping")

    pending_buffer: list[dict] = []
    label_counts: dict[str, int] = {label: 0 for label in LABELS}
    latencies: list[float] = []
    fallback_count = 0

    def flush() -> None:
        if pending_buffer:
            append_jsonl(args.output, pending_buffer)
            pending_buffer.clear()

    try:
        for index, candidate in enumerate(candidates, start=1):
            cid = candidate.get("id")
            if cid and cid in processed_ids:
                continue
            prompt_text = candidate.get("prompt", "")
            if not prompt_text:
                continue

            try:
                label, latency_ms, raw_content = classify_via_llama_server(prompt_text, url, args.timeout, args.model_alias)
            except (urllib.error.URLError, ValueError) as exc:
                print(f"[qwen-labels] classify failed for {cid}: {exc}; marking unknown")
                label, latency_ms, raw_content = "unknown", 0.0, ""
                fallback_count += 1

            if label not in LABELS:
                label = "unknown"
                fallback_count += 1

            label_counts[label] += 1
            latencies.append(latency_ms)

            enriched = dict(candidate)
            enriched["gt_label"] = label
            enriched["annotator"] = args.annotator_label
            enriched.setdefault("annotator_notes", None)
            enriched["latency_ms"] = round(latency_ms, 2)
            enriched["ts"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
            enriched["raw_preview"] = raw_content[:200]
            pending_buffer.append(enriched)

            if len(pending_buffer) >= max(1, args.checkpoint_every):
                flush()
                total = len(processed_ids) + label_counts_sum(label_counts)
                print(f"[qwen-labels] checkpoint {total}/{len(candidates)} dist={dict_nonzero(label_counts)}")
    finally:
        flush()

    total_labeled = label_counts_sum(label_counts)
    if latencies:
        mean_latency = sum(latencies) / len(latencies)
    else:
        mean_latency = 0.0
    print("\n=== Qwen labeling summary ===")
    print(f"  total labeled this run: {total_labeled}")
    print(f"  label distribution: {dict_nonzero(label_counts)}")
    print(f"  mean latency ms: {mean_latency:.1f}")
    print(f"  fallback (parse/classify failures): {fallback_count}")
    print(f"  output: {args.output}")


def dict_nonzero(counts: dict[str, int]) -> dict[str, int]:
    return {label: count for label, count in counts.items() if count > 0}


def label_counts_sum(counts: dict[str, int]) -> int:
    return sum(counts.values())


if __name__ == "__main__":
    main()

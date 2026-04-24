#!/usr/bin/env python3
"""
retrain_cli.py — 再学習 pipeline の CLI.

corrections.jsonl (運用中に人間がラベル訂正したエントリ) を train.jsonl に
merge してから train.py を呼ぶ。

corrections.jsonl のスキーマ:
  {"prompt": "...", "label": "local_probable", "corrected_from": "cloud_required", "ts": "..."}

Usage:
  uv run python3 retrain_cli.py \
    --base-train ../label-data/train.jsonl \
    --corrections ../label-data/corrections.jsonl \
    --model-dir ../model
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-train", type=Path, required=True)
    parser.add_argument("--base-eval", type=Path, required=True)
    parser.add_argument("--corrections", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--backup-dir", type=Path, default=Path("../model-backups"))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.corrections.exists() or args.corrections.stat().st_size == 0:
        print(f"[retrain] no corrections at {args.corrections}; skip")
        return

    corrections = [json.loads(l) for l in args.corrections.read_text().splitlines() if l.strip()]
    base = [json.loads(l) for l in args.base_train.read_text().splitlines() if l.strip()]

    # Merge: corrections は既存 entries を上書きしない（追記のみ）。prompt + label 重複は除外。
    seen = {(e.get("prompt", "")[:200], e.get("label", "")) for e in base}
    added = 0
    merged = list(base)
    for c in corrections:
        key = (c.get("prompt", "")[:200], c.get("label", ""))
        if key not in seen:
            seen.add(key)
            merged.append({
                "task": c.get("task", "correction"),
                "label": c["label"],
                "prompt": c["prompt"],
                "source": "correction",
            })
            added += 1

    print(f"[retrain] base={len(base)} corrections={len(corrections)} added={added} (duplicates filtered)")
    if added == 0:
        print("[retrain] no new corrections to merge; skip retrain")
        return

    if args.dry_run:
        print("[retrain] dry-run; would call train.py")
        return

    # Backup current model
    args.backup_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%SZ")
    backup_path = args.backup_dir / f"model-{ts}"
    if args.model_dir.exists():
        shutil.copytree(args.model_dir, backup_path)
        print(f"[retrain] backed up current model → {backup_path}")

    # Write merged train.jsonl
    augmented_train = args.base_train.parent / "train-augmented.jsonl"
    augmented_train.write_text("\n".join(json.dumps(e, ensure_ascii=False) for e in merged) + "\n")
    print(f"[retrain] wrote augmented train → {augmented_train}")

    # Call train.py
    result = subprocess.run(
        [sys.executable, "train.py",
         "--train", str(augmented_train),
         "--eval", str(args.base_eval),
         "--model-out", str(args.model_dir)],
        cwd=Path(__file__).parent,
        capture_output=True, text=True,
    )
    print(result.stdout)
    if result.returncode != 0:
        print(f"[retrain] FAILED (rc={result.returncode}): {result.stderr}", file=sys.stderr)
        if backup_path.exists():
            print(f"[retrain] rolling back from {backup_path}")
            shutil.rmtree(args.model_dir)
            shutil.copytree(backup_path, args.model_dir)
        sys.exit(result.returncode)
    print("[retrain] DONE")


if __name__ == "__main__":
    main()
